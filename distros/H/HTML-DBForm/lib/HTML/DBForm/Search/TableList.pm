package HTML::DBForm::Search::TableList;

use strict;
use warnings;
no warnings 'uninitialized';


our $VERSION = '1.05';

=head1 NAME

HTML::DBForm::Search::TableList - Creates a web interface for searching database tables

=head1 SYNOPSIS

    $search = HTML::DBForm::Search->new('tablelist', { column => 'name' });
    
    $editor->run(search => $search);


=head1 INTRODUCTION

  HTML::DBForm::Search::TableList provides a web interface to search for rows
  in a database to be updated by HTML::DBForm. 

=cut

=head1 METHODS

=over 4

=cut


=head2 new 

Constructor inherited from HTML::DBForm::Search

takes a scalar indicating the type of search module
to create (in this case 'tablelist'), and a list of
hash refs designating which columns to display as HTML 
select form elements, and in which order.

Each hash should have one of the following keys: 
'column', 'columns', or 'sql'. 'column' should be the db 
column to search, 'columns' should be two db columns, the 
first of which will be the column to search, and the second of
which will be the values to display as option labels. 'sql' 
can be used to populate the select options with an arbitrary SQL 
statement. If one column is returned from the SQL statement, then 
it will be used as choice values and labels. If two columns are 
returned, then the first will be the specified column value, while 
the second will be used as option labels.


B<Example>

    $search = HTML::DBForm::Search->new('tablelist',
        { column => 'category' },
        { columns => ['id', ' CONCAT(fname, ' ', lname) '] }
    );

    

This would create a two step search, the first screen would be a 
selection of existing categories, and the next screen would be a 
selection of names within the chosen categories. When picking 
columns to display in the search, be aware that the final choice 
should result in the primary key being chosen.

 
B<Example>

    $search = HTML::DBForm::Search->new('tablelist',
        { sql => ['id','SELECT id, label FROM table ORDER BY label'] }
    );

This would create a simple one step search. 

You can use as many hashrefs as needed, each one will generate
a new search step, (e.g three hash references will create a three 
step search).  Just keep in mind that the last column chosen must be 
the column given to DBForm->new() as a primary key.

=cut


# implementation of this method is required
# constructor inherited from Class::Factory 
# via HTML::DBForm::Search


sub init {

    my $self = shift;
    $self->{params} = \@_;

    $self->{html_cols} = [];

    return $self;
}



# implementation of this method is required
# main subroutine called by HTML::DBForm

sub run {

    my ($self, $editor) = @_;

    my $tmpl_ref = $self->{'tmpl_file'} 
        ? do { open(FH, "< $self->{'tmpl_file'}"); local $/; <FH> } 
        : &TEMPLATE;


    $self->{template} = HTML::Template->new(
        scalarref => \$tmpl_ref, 
        die_on_bad_params => 0,
        loop_context_vars => 1,
    );


    $self->{editor} = $editor;
    
    # find out what step we are on
    $self->{step} = $self->{editor}->{query}->param('step') || 0;
    
    $self->{template}->param(STEP => $self->{step} + 1);
    
    $self->get_choices;

    return ($self->{editor}->{error}) ? 
        $self->{editor}->{template}->output :
        $self->{template}->output ;

}


=head2 set_stylesheet

Sets an optional css file

Takes a scalar holding the path to a stylesheet.


B<Example>

  $search->set_stylesheet('/styles/site_styles.css');

=cut

sub set_stylesheet {

    my $self = shift;
    $self->{css} = shift ; 
}



=head2 set_template

Sets an optional template file

Takes a scalar holding the path to an HTML::Template template.
To get a template file to start with, you can do this:
    perl -MHTML::DBForm::Search::DropDown -e 'print
    HTML::DBForm::Search::DropDown::TEMPLATE()' > sample.tmpl

B<Example>

  $search->set_template('/www/templates/my.tmpl');

=cut

sub set_template {

    my $self = shift;
    $self->{tmpl_file} = shift ; 
}




=head2 add_column  

Adds a new column to your search list table.
Only affects the last search screen.

Required parameters: 

I<column> the column that this form element represents

Optional parameters:

I<label> a label that will appear as the column header.
this will default to the name of the column.

I<callback> a subroutine reference that will be passed each
value for processing before display. 

B<Examples>
    
    $editor->add_column( column => 'date' );
    
    $editor->add_column( 
        column  => 'fname', 
        label   => 'First Name', 
        callback => sub { ucfirst(shift) }
    );

=cut

sub add_column {
    
    my $self = shift;

    $self->_err_msg("add_column() got an odd number of parameters!")
    unless ((@_ % 2) == 0);

    my %params = @_;
    
    push (@{$self->{td_cols}}, \%params);

}



# get choices to display 

sub get_choices {

    my $self = shift;

    if ($self->{params}->[$self->{step}]->{sql}){

        # use sql parameter
        $self->populate_search(
            $self->{params}->[$self->{step}]->{sql}->[1]
        );

    } else {

        # generate our own sql
        $self->populate_search(
            $self->get_select($self->parse_params($self->{step}))
        );
    }
}



# parse search parameters 
 
sub parse_params {

    my $self = shift;
    my $i = shift;

    my $c_param = $self->{params}->[$i];

    if ($c_param->{column}){
        return    ($c_param->{column}, $c_param->{column});
    } 

    if ($c_param->{columns})  {
        return    ($c_param->{columns}->[0], $c_param->{columns}->[1]);
    } 

    if ($c_param->{sql}) {
        return    ($c_param->{sql}->[0], $c_param->{sql}->[1]);
    } 
}



# build a select statement
 
sub get_select {

    my $self = shift;
    my ($col1, $col2) = @_;

    my $sql = qq(    SELECT    DISTINCT $col1, $col2 
                     FROM    $self->{editor}->{table}  
                    );    

    return $sql unless $self->{step};

    my (@values, $i);
    
    for my $step(0 .. $self->{step}-1){

        $sql .= ' WHERE ' unless $i++;
        $sql .= ($self->parse_params($step))[0] ." = ?"; 
        $sql .= ' AND ' unless $step >= $self->{step}-1;        

        push @values, 
            $self->{editor}->{query}->param(($self->parse_params($step))[0]);
    }

    $sql .= " ORDER BY $col2";

    # the sql is the first element
    # the rest of the array is 
    # filled with placeholder vals

    unshift @values, $sql;
    return @values;

}



# populate search choices 

sub populate_search {

    my $self = shift;
    my ($sql, @params) = @_;
    my (@tmpl_loop, @headers, $db_return);
    
    eval {
        $db_return = $self->{editor}->{dbh}->selectall_arrayref($sql,undef,@params);
        1 } or $self->{editor}->_err_msg($@, $sql);

    # is this the last step?
    my $last_step = (($self->{step}+1) >= scalar(@{$self->{params}})) ? 1 : 0;

    my $rm = 'display' if $last_step;

    # is it the first?
    my $cancel = ($self->{step} > 0) ? 1 : 0;



    # workaround for servers that lack
    # subqueries ( e.g mysql < 4.1 )

    if ($self->{params}->[$self->{step}]->{sql}){
        $db_return = $self->constrain_results($db_return);
    };


    for my $row_ref(@$db_return){
        my %row = (
            VALUE => $row_ref->[0],        
            LABEL => $row_ref->[1],
            RADIO_NAME => ($self->parse_params($self->{step}))[0],
        );

        # if final screen, list any 
        # additional columns specified
        
        if ($last_step){
            my @td_loop;
            
            for my $col_hash(@{$self->{td_cols}}){
                my $sql = qq(     SELECT    $col_hash->{column} 
                                FROM    $self->{editor}->{table}
                                WHERE    $self->{editor}->{pk} = ?
                            );

                my $ar;
                eval{
                    $ar = $self->{editor}->{dbh}->selectrow_arrayref(
                        $sql, undef, $row_ref->[0]
                        ); 1
                    } or $self->{editor}->_err_msg($@, $sql);
        
                $ar->[0] = $col_hash->{callback}->($ar->[0]) 
                    if $col_hash->{callback};
        
                my %td = (
                    VALUE => $ar->[0]    
                );
                push(@td_loop, \%td);
            }
            $row{TDS} = \@td_loop;
        }    
        
        push(@tmpl_loop, \%row);
    }

    # if final screen, list any 
    # additional headers specified
        
    if ($last_step){
        for my $col_hash(@{$self->{td_cols}}){

            my $label = $col_hash->{label};
    
            $label ||= join(' ', map {ucfirst($_)} 
                split(/_/, $col_hash->{column}));
        
            my %row = (
                HEADER => $label 
            );
        push(@headers, \%row);
        }
    }

    # keep track of old choices
    my @prev_vals; 
    for my $step(0 .. $self->{step}-1){
        my %row;
        $row{LABEL} = ($self->parse_params($step))[0];
        $row{VALUE} = $self->{editor}->{query}->param(($self->parse_params($step))[0]);    
        push @prev_vals, \%row;
    }




    $self->{template}->param(    SEARCH_LOOP    => \@tmpl_loop, 
                                FORM         => 1,
                                RUN_MODE    => $rm,
                                CANCEL        => $cancel,
                                PREV_VALS    => \@prev_vals,
                                HEADERS        => \@headers,
                                CUSTOM_CSS    => $self->{css},
                            );     
}



# discard extra sql returns 

sub constrain_results {
    
    # this would be much cleaner 
    # but less portable using subqueries 
    # instead of two seperate queries

    my ($self, $list) = @_;

    # get a list of all possible
    # results based on previous selections    

    my $sql = qq(    SELECT    DISTINCT 
                            T.$self->{params}->[$self->{step}]->{sql}->[0] 
                     FROM    $self->{editor}->{table} T 
                    );    

    my (@values, $i, @results);
    
    for my $step(0 .. $self->{step}-2){

        $sql .= ' WHERE ' unless $i++;
        $sql .= ($self->parse_params($step))[0] ." = ?"; 
        $sql .= ' AND ' unless $step >= $self->{step}-2;        

        push @values, 
            $self->{editor}->{query}->param(($self->parse_params($step))[0]);
    }

    my $selections = $self->{editor}->{dbh}->selectcol_arrayref($sql, undef, @values);

    for my $lr(@$list){
        push (@results, $lr) if grep{/^$lr->[0]$/} @$selections;
    }
    
    return \@results;
}



# create an HTML::Template

sub TEMPLATE {
qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" >
<html>
  <head>
    <!-- TMPL_IF CUSTOM_CSS -->
        <link rel="stylesheet" href="<!-- TMPL_VAR CUSTOM_CSS -->" type="text/css">
    <!-- TMPL_ELSE -->
     <style>
        body {
            margin:0 0 0 0;
            border:1px solid #fff;
        }

        .admin_area {
            padding-top: 15px;
            padding-bottom: 25px;
            padding-left:15px;
            float: left;
            width:585px;
            min-width: 585px;
            background-color: #ffffff;
        }
        
        table { 
            font-family: Verdana, sans-serif, Arial;
            font-weight: normal;
            font-size: 12px;
            color: #333333;
            background-color: white;
            text-align: left;
            width: 580px;
            border:1px solid #cccccc;
        }

        tr.odd {
            background-color: #EEF4FE;
        }

        td {
            padding-left: 23px; 
            padding-bottom: 4px; 
            padding-top: 4px; 
            padding-right: 23px; 
        } 

        td.odd {
            padding-left: 23px; 
            padding-bottom: 4px; 
            padding-top: 4px; 
            padding-right: 23px; 
        } 

        td.header {
            font-family: Verdana, sans-serif, Arial;
            font-weight: bold;
            font-color: #383272;
            padding-left: 23px; 
            padding-bottom: 4px; 
            padding-top: 4px; 
            padding-right: 23px; 
        }

        a:visited {
            color:#698A60;
        }
        a:active {
            color:#273B80;
        }
        a:hover {
            color:#A49580;
        }
        a:link {
            color:#383272;
        }

        INPUT, TEXTAREA, SELECT, OPTION, SUBMIT {
          font-family: Arial, Helvetica, Sans-Serif;
          font-size: 11px;
          padding:2px;
          color: #333;
          /*background-color: #fff;*/
          border: solid 1px #666;
          } 
    </style>
      <!-- /TMPL_IF -->

    <title></title>
  </head>
<body>
<form name="form1" method="post">

    <div class="admin_area">
    <table id="searchlist">
    <tbody>
        <tr>
            <td class="header">
                Select    
            </td>

            <!-- HEADER ROW -->
                
            <!-- TMPL_LOOP HEADERS -->
            <td class="header">
                <!-- TMPL_VAR HEADER -->    
            </td>
            <!-- /TMPL_LOOP -->
            
        </tr>
            
        <!-- TMPL_LOOP SEARCH_LOOP -->

        <tr <!-- TMPL_IF __ODD__ -->class="odd"<!-- /TMPL_IF -->>
            <td <!-- TMPL_IF __ODD__ -->class="odd"<!-- /TMPL_IF -->>
            <input type='radio' name='<!-- TMPL_VAR RADIO_NAME -->' 
                value='<!--TMPL_VAR VALUE -->' <TMPL_IF __FIRST__>checked</TMPL_IF>>
                <!-- TMPL_VAR LABEL -->
            </td>
            <!-- TMPL_LOOP TDS -->
            <td <!-- TMPL_IF __ODD__ -->class="odd"<!-- /TMPL_IF -->>
                <!-- TMPL_VAR VALUE -->    
            </td>
            <!-- /TMPL_LOOP -->
        </tr>

        <!-- /TMPL_LOOP -->
        </tbody>
        </table>

        <!-- HIDDEN HTML FORM ELEMENTS -->

        <input type="hidden" name="step" value="<!-- TMPL_VAR STEP -->">    
        <input type="hidden" name="rm" value="<!-- TMPL_VAR RUN_MODE -->">    
    
        <!-- TMPL_LOOP PREV_VALS -->
        <input type="hidden" name="<!-- TMPL_VAR LABEL -->" value="<!-- TMPL_VAR VALUE -->">
        <!-- /TMPL_LOOP -->

        <!-- END HIDDEN HTML ELEMENTS -->


        <input type="submit" value="Submit" style="width:80;">
        
        <!-- TMPL_IF CANCEL -->
        
        <input type='button' value='Cancel ' onclick='document.location="javascript:history.go(-1)"'
        style="width:80;">
            
        <!-- /TMPL_IF -->    
    
        <input type='button' value='Add New' 
        onclick='document.location="<!-- TMPL_VAR URL -->?rm=display"'
        style="width:80;">
        </div>

</form>
</body>
</html>);
};



1;
