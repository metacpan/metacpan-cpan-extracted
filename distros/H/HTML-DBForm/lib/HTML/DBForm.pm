package HTML::DBForm;

use strict;
use warnings;
no warnings 'uninitialized';

use Carp;
use CGI;
use HTML::Template; 
use HTML::SuperForm;
use DBI;

our $VERSION = '1.05';


=head1 NAME

HTML::DBForm - Creates a web interface for updating database tables

=head1 SYNOPSIS

    use HTML::DBForm;
    use HTML::DBForm::Search;

    my $editor = HTML::DBForm->new(
        table       => 'contacts',
        primary_key => 'id',
    );

    $editor->element(column => 'email');

    $editor->element(
        label  => 'First Name',
        column => 'fname',
    );

    $editor->element(
        column  => 'interest',
        type    => 'select',
        options => \@list_of_interests
    );
 
    $editor->element(
        label   => 'Reason for Contact',
        column  => 'reason',
        options => 'select reason from reasons'
    );

    $editor->connect(
        username   => 'webuser',
        password   => 'xxxxxxx',
        datasource => 'dbi:mysql:dbname'
    );

    $search = HTML::DBForm::Search->new('dropdown',
        { columns => ['id', 'lname'] }
    );
   
    $editor->run(search => $search);


=head1 INTRODUCTION

  HTML::DBForm provides a web interface to insert, update, and delete
  rows from a database. This can be used to easily create content editors
  for websites, content management systems, or anything that stores its
  data in a database.

  HTML::DBForm allows easy creation of simple admin screens, but is 
  flexable enough to use in many different situations.

=cut

=head1 METHODS

=over 4

=cut

=head2 new  

Creates a new editor object. 

Required parameters: 

I<table> the table we are creating a form to update

I<primary_key> the primary key of this table. Caveat Programmor: There is 
no checking done to enforce that the column provided as I<pk> is 
a primary key. 

Optional parameters:

I<stylesheet> the URL to a custom stylesheet file.  

I<template> the path to a custom template file. To get a 
template file to start with, you can do this:

perl -MHTML::DBForm -e 'print HTML::DBForm::TEMPLATE()' > sample.tmpl

I<verbose_errors> a boolean parameter that determines whether
or not the module displays verbose error messages to the 
browser, this is set to 0 by default for security reasons.

I<error_handler> a callback that is triggered any time an
exception occurs. The callback is passed a list of errors,
and the results of the callback are presented as an error 
message to the user. 


B<Examples>
    
    
    my $editor = HTML::DBForm->new(
            table          => 'table_to_update', 
            primary_key    => 'id',
    );
    
    
    my $editor = HTML::DBForm->new(
            table          => 'table_to_update', 
            primary_key    => 'id', 
            stylesheet     => '/styles/custom.css',
            verbose_errors => 1,
            error_handler  => sub { notify_admin(localtime); return @_ },
    );

    
=cut

sub new { 

    my $type = shift;
    my $self = {};
 
    $self->_err_msg("new() got an odd number of parameters!")
    unless ((@_ % 2) == 0);

    my %params = @_;

    my $tmpl_ref = $params{'template'} 
        ? do { open(FH, "< $params{'template'}"); local $/; <FH> } 
        : &TEMPLATE;


    $self->{template} = HTML::Template->new(
        scalarref => \$tmpl_ref, 
        die_on_bad_params => 0,
        loop_context_vars => 1,
    );

    $self->{params}        = ['type','label','value','column'];
    $self->{table}        = $params{'table'};
    $self->{pk}            = $params{'primary_key'};
    $self->{query}        = CGI->new;
    $self->{form}         = HTML::SuperForm->new;
    $self->{elements}     = [];
    $self->{verbose}    = $params{'verbose_errors'};
    $self->{err_handler}= $params{'error_handler'};
    $self->{css}        = $params{'stylesheet'};

    bless $self, $type;
}




=head2 element  

Adds a new element to your editor object. Elements are created 
as HTML::SuperForm objects

Required parameters: 

I<column> the column that this form element represents

Optional parameters:

I<label> a label that will appear next to the form element.
this will default to the name of the column.

I<type> the type of form element that will be displayed.
Currently, the available options are 'text', 'textarea', 'radio',
'select', 'checkbox', and 'date'. The default is 'text'.

I<options> this is required for elements of type 'radio',
'select', and 'checkbox'. This parameter should hold the values
used to create the choice options. This parameter can be one of
4 types of parameters:

scalar: this should be a SQL SELECT statement that returns 2 columns.
The first column will be the value, the next will be the label. This 
SQL statement can SELECT from any table(s).

array: a reference to an array of scalars that will be used as both 
values and labels

array of arrays: a reference to an array of two-element arrays that
will be used to populate the values and labels respectively.
    
hash: a reference to a hash who's keys will be the HTML element's values, 
and values will be the HTML element's labels.

Any other parameter pairs will be passed unchanged to the HTML::SuperForm
object that creates the actual form element HTML. Please see the 
HTML::SuperForm Documentation for details. Some common examples are:

disabled => 1, this creates a read-only field.

onclick => "alert('some javascript behavior goes here!'" 

size => 50

maxlength => 50




B<Example>
    
    $editor->element( column => 'Name' );
    
    $editor->element( 
        column  => 'sex', 
        type    => 'radio', 
        options => {M => 'Male', F => 'Female'}
    );
        
    $editor->element( 
        column  => 'color_id',
        label   => 'Product Color'
        type    => 'select', 
        options => 'SELECT id, color FROM colors ORDER BY color'
    );
    
=cut

sub element {

    my $self = shift;

    $self->_err_msg("element() got an odd number of parameters!")
    unless ((@_ % 2) == 0);

    my %params = @_;
    
    push (@{$self->{'elements'}}, \%params);
        
}




=head2 connect

connects to the database. 

Required parameters: 

I<dbh> a DBI database handle

I<or>

I<datasource>, I<username>, and I<password>


B<Example>
    
     $editor->connect( dbh => $dbh );
     
     $editor->connect(
         datasource => 'dbi:mysql:my_database',
         username   => 'krailey'
         password   => 'secret'
     );
    
=cut

sub connect {

    my $self = shift;

    $self->_err_msg("connect() got an odd number of parameters!")
    unless ((@_ % 2) == 0);

    my %params = @_;

    if ($params{dbh}){
        $self->{dbh} = $params{dbh};
    } else {
        $self->{dbh} = DBI->connect("$params{datasource}",
                                    "$params{username}",
                                    "$params{password}",
                                    {RaiseError => 1},
                                    ) 
                                    or $self->_err_msg($DBI::errstr); 
    }
}




=head2 run

runs the object 

Required parameters: 

I<search> a DBForm::Search object that will create
a search interface for the current table

I<or>

I<primary_key> the value of the primary key for one
row that can be updated through the form


B<Example>
    
     $search = HTML::DBForm::Search->new('dropdown',
         { columns  => ['id', 'name']},
     );
     $editor->run(search => $search);

     $editor->run(primary_key => '1234');
    
=cut

sub run {

    my ($self, %params) = @_;

    $self->{search} = $params{search};
    
    my $default = ($params{primary_key}) ? 'display':'search';
    
    # dispatch table
    my %mode = (
        search    => sub {$self->{search}->run($self)},
        display => sub {$self->_display_form($params{primary_key})},
        insert    => sub {$self->_insert_row},
        update    => sub {$self->_update_row},
        delete    => sub {$self->_delete_row},
    );
    
    my $rm = $mode{$self->{query}->param('rm') || $default};

    print $self->{query}->header;
    print $rm->();
}




# PRIVATE METHODS BELOW

# create an HTML form
# for adding or updating a record

sub _display_form {
  
    my $self = shift;

    my $pk_val = shift || $self->{query}->param($self->{pk});

    my (@form_loop, $db_row);

    if ($pk_val){
        my $SQL = "SELECT * FROM $self->{table} WHERE $self->{pk} = ?";
        $db_row = $self->{dbh}->selectrow_hashref($SQL, undef, $pk_val);

        $self->{template}->param(
            DELETE     => 1,
            PK         => $self->{pk},
            ID        => $pk_val,
            );
    }

    for my $element(@{$self->{elements}}){

        my %row;

        # set the defaults 
        $element->{type} ||= 'text';
        
        $element->{label} ||= join(' ', 
            map {ucfirst($_)} split(/_/,$element->{column}));
        
        $element->{value} = $db_row->{$element->{column}};

        $row{LABEL} = $element->{label};    
        $row{ELEMENT} = $self->_build_element($element);    

        push(@form_loop, \%row);
    }

    my $next_mode = ($pk_val) ? 'update' : 'insert';
    
    my $rm = { name => 'rm', default => $next_mode };
    my $id = { name => $self->{pk}, default => $pk_val };

    $self->{template}->param(    HIDDEN_LOOP => [
        {ELEMENT => $self->_build_hidden($rm)},
        {ELEMENT => $self->_build_hidden($id)},
    ]);

    $self->{template}->param(
        CUSTOM_CSS => "$self->{css}",
        FORM_LOOP => \@form_loop, 
        URL => $self->{query}->url,
    ) unless $self->{error};
    
    $self->{template}->output;
}




# create an HTML::SuperForm object
# for each form element 

sub _build_element {

    my ($self, $element) = @_;

    # avoid unlikely (but possible) recursion
    return if $element->{type} eq 'element';

    # simple dispatch table
    # for html builder methods
    my %methods = (
        checkbox    => sub{ $self->_select_builder('checkbox_group', $element) },
        radio        => sub{ $self->_select_builder('radio_group', $element) },
        select        => sub{ $self->_select_builder('select', $element) },
        text        => sub{ $self->_build_text($element) },
        textarea    => sub{ $self->_build_textarea($element) },
        hidden        => sub{ $self->_build_hidden($element) },
        date        => sub{ $self->_build_date($element) },
    );

    my $method = $methods{$element->{type}};    
    $self->$method;
}




# create a text field form element

sub _build_text {

    my ($self, $element) = @_;

    return $self->{form}->text(
        name         => $element->{column},
        default     => $element->{value},
        $self->_pass_through($element)
    );
        
}



# create a textarea form element

sub _build_textarea {

    my ($self, $element) = @_;

    return $self->{form}->textarea(
        name => $element->{column},
        default => $element->{value},
        $self->_pass_through($element)
    );
        
}



# create a hidden form element

sub _build_hidden {

    my ($self, $element) = @_;

    return $self->{form}->hidden($element);

}



# build a date form element
# (MM DD YYYY text fields)

sub _build_date {

    my ($self, $element) = @_;

    my ($YY,$MM,$DD) = ($element->{value} =~ /(\d{4})-(\d\d)-(\d\d)/);

    my $form ='Month ';
    $form .= $self->{form}->text(
        name    => $element->{column} .'_MM',
        default    => $MM,
        size    => 2,
        );
        
    $form .=' Day ';
    $form .= $self->{form}->text(
        name    => $element->{column} .'_DD',
        default    => $DD,
        size    => 2,
        );
        
    $form .=' Year ';
    $form .= $self->{form}->text(
        name    => $element->{column} .'_YY',
        default    => $YY,
        size    => 4,
        );

    return $form;

}



# build and populate multiple
# option form elements

sub _select_builder {

    my ($self, $type, $element) = @_;

    my (@values, %labels);

    my $o_type;

    eval{
        $o_type = ref $element->{options};
        $o_type = 'SQL' unless $o_type;
        $o_type = 'AOA' if $element->{options}->[0][1];
    };

    
    # load values from an array
    if ($o_type eq 'ARRAY'){
        
        my @labels;
        for my $item (@{$element->{options}}){
            push @values, $item;
            push @labels, $item;
        }
        @labels{@values} = @labels;

    }


    # load values from a hash
    if ($o_type eq 'HASH'){
        @values = keys %{$element->{options}};
        %labels = %{$element->{options}};
    }


    # load values from a AoA
    if ($o_type eq 'AOA'){
        
        my @labels;
        for my $lr (@{$element->{options}}){
            push @values, $lr->[0];
            push @labels, $lr->[1];
        }
        @labels{@values} = @labels;
    }

    # if param is not a reference
    # assume that it is SQL and
    # load values from a database
    if ($o_type eq 'SQL'){
        
        my $db_return;
        
        eval {
            $db_return = $self->{dbh}->selectall_arrayref($element->{options}); 1
            } or $self->_err_msg($@);
        
        my @labels;
        for my $lr (@{$db_return}){
            push @values, $lr->[0];
            push @labels, $lr->[1];
        }
        @labels{@values} = @labels;
    }

    return $self->{form}->$type(
        name    => $element->{column},
        values  => \@values,
        labels    => \%labels,
        default => $element->{value},
        $self->_pass_through($element)
    );
    
}



# pass any unwanted parameters
# through to HTML::SuperForm

sub _pass_through {
    my $self = shift;
    my $element = shift;

    my %params;
    for my $param (keys %$element){
        next if grep(/$param/, @{$self->{params}});
        $params{$param} = $element->{$param};
    }
    
    return %params;
}



# add a new row

sub _insert_row {

    my $self = shift;

    my $placeholder_count;
    my @values; 

    my $SQL = "INSERT into $self->{table} (";

    for my $element(@{$self->{elements}}){

        $SQL .= $element->{column} . ",";

        $placeholder_count++;

        if ($element->{type} eq 'date'){
            my $val = $self->{query}->param("$element->{column}_YY") .'-';
            $val .= $self->{query}->param("$element->{column}_MM") .'-';
            $val .= $self->{query}->param("$element->{column}_DD");
            
            push @values, $val;
            
        } else {
            push @values, $self->{query}->param($element->{column});
        }
    }
 
    chop ($SQL);
    
    $SQL .= ") VALUES (";

    for (1 .. $placeholder_count){
        $SQL .="?,";
    }   
    chop ($SQL);
        
    $SQL .= ")";
    
    eval{ $self->{dbh}->do($SQL, undef, @values); 1}
        or $self->_err_msg($@);
        
    my $id = $self->{dbh}->{mysql_insertid};

    $self->{primary_key} = $id;

    $self->{template}->param(
        MESSAGE => 'New Record Created.', 
        URL=> $self->{query}->url,
        ) unless $self->{error};

    $self->{template}->output;
}



# update an existing row

sub _update_row {
    
    my $self = shift;
    my $placeholder_count;
    my @values = (); 

    my $SQL = "UPDATE $self->{table} set ";
    my $q = $self->{query};

    for my $element(@{$self->{elements}}){

        $SQL .= $element->{column} . "=?,";

        $placeholder_count++;
    
        if ($element->{type} eq 'date'){
            my $val = $q->param("$element->{column}_YY") .'-';
            $val .= $q->param("$element->{column}_MM") .'-';
            $val .= $q->param("$element->{column}_DD");
            
            push @values, $val;
        } else {
            push @values, $q->param($element->{column});
        }
    }
    chop ($SQL);
    
    $SQL .= " WHERE $self->{pk}=?";
    
    push @values, $q->param($self->{pk});
 
    my $sth = $self->{dbh}->prepare($SQL);
        
    eval { $sth->execute(@values); 1 } or $self->_err_msg($@, $SQL);

    $self->{template}->param(
        MESSAGE => 'Record Updated.', 
        URL=> $self->{query}->url
        ) unless $self->{error};
    
    $self->{template}->output;
}



# delete an existing row

sub _delete_row {
    
    my $self = shift;

    my $SQL = "DELETE FROM $self->{table} WHERE $self->{pk}=?";

    my $sth = $self->{dbh}->prepare($SQL);
        
    eval { 
        $sth->execute($self->{query}->param($self->{pk})); 
        1 } or $self->_err_msg($@);

    $self->{template}->param(
        MESSAGE => 'Record Deleted.', 
        URL => $self->{query}->url
    ) unless $self->{error};
    
    $self->{template}->output;
}



# display an error message

sub _err_msg {

    my $self = shift;
    my @errs = @_;
    
    carp(@errs);

    $self->{error}++;
    $self->{err_msg} = 'Please try again.';

    # call optional error handler
    if ($self->{err_handler}){
        $self->{err_msg} = $self->{err_handler}->(@errs);
    } else {
        $self->{err_msg} = join('<br />', @errs) if $self->{verbose};
    }
    
    $self->{template}->param(
        ERROR_MSG => $self->{err_msg}, 
        URL       => $self->{query}->url
    );
}


=head1 SEE ALSO

HTML::SuperForm 
HTML::DBForm::Search
HTML::DBForm::Search::DropDown
HTML::DBForm::Search::TableList


=head1 AUTHOR

Ken Railey, E<lt>ken_railey@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Ken Railey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


sub TEMPLATE {

qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" >
<html>
  <head>
    <!-- TMPL_IF CUSTOM_CSS -->
        <link rel="stylesheet" href="<!-- TMPL_VAR CUSTOM_CSS -->" type="text/css">
    <!-- TMPL_ELSE -->
     <style>
        
        body {
            margin: 15 15 15 15;
        }

        .admin_area {
            padding-top: 25px;
            padding-bottom: 25px;
            padding-left: 20px;
            margin-bottom: 30;
            float: left;
            width: 540px;
            border: solid 1px #ccc;
            background-color: #fff;
        }
        
        .message_area {
            margin-top: 45px;
            margin-bottom: auto;
            margin-left: auto;
            margin-right: auto;
            font-family: Verdana, sans-serif, Arial;
            font-weight: normal;
            font-size: 12px;
            width: 340px;
            padding-left: 10px;
            padding-right: 10px;
            padding-top: 10px;
            padding-bottom: 10px;
            border-top: solid 2px #dedede;
            border-left: solid 2px #dedede;
            border-right: solid 2px #666;
            border-bottom: solid 2px #666;
            background-color: #ccc;
        }
            
        .error_area {
            margin-top: 45px;
            margin-bottom: auto;
            margin-left: auto;
            margin-right: auto;
            font-family: Verdana, sans-serif, Arial;
            font-weight: normal;
            font-size: 12px;
            width: 340px;
            color: #600;
            padding-left: 10px;
            padding-right: 10px;
            padding-top: 10px;
            padding-bottom: 10px;
            border-top: solid 2px #dedede;
            border-left: solid 2px #dedede;
            border-right: solid 2px #666;
            border-bottom: solid 2px #666;
            background-color: #ccc;
        }
        
        .error_message {
            padding-top: 10px;
            padding-bottom: 10px;
        }    
    
        table { 
            font-family: Verdana, sans-serif, Arial;
            font-weight: normal;
            font-size: 12px;
            font-color: #ccc;
            background-color: white;
        }

        td {
            padding-top: 4px;
            padding-bottom: 4px;
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

    <title><TMPL_VAR NAME=VALUE></title>
    <script> 
        function delete_record(){
        var confirmed = window.confirm("Are you sure? Deletions are permanent.");
        if(confirmed){
            document.location="<!-- TMPL_VAR URL -->?rm=delete&<!-- TMPL_VAR PK -->=<!-- TMPL_VAR ID -->";
        }else{
            return;
        }
    }
    </script>
     
  </head>

<body>


    <form name="form1" enctype="multipart/form-data" method="post">

    <!--             -->

    <!-- TMPL_LOOP HIDDEN_LOOP -->
    <!-- TMPL_VAR ELEMENT -->
    <!-- /TMPL_LOOP -->

    <!-- TMPL_IF FORM_LOOP -->
    
    <div class="admin_area">    
        <table>

        <!-- TMPL_LOOP NAME=FORM_LOOP -->
        <tr>
            <td>
                <!-- TMPL_VAR LABEL -->
            </td>
            <td>
                <!-- TMPL_VAR ELEMENT -->
            </td>
        </tr>
        <!-- /TMPL_LOOP -->

        <tr>
            <td colspan=2>
            <input type='submit' name='submit' value='Submit' style="width:80;">
            <input type='button' name='cancel' value='Cancel' style="width:80;"
             onclick='document.location="javascript:history.go(-1)"'>
    
            <!-- TMPL_IF DELETE -->

            <input type='button' name='delete' value='Delete' style="width:80;"
            onclick="javascript:delete_record();">
        
            <!-- /TMPL_IF -->
            </td>
        </tr>

        </table>
    </div>
    <!-- /TMPL_IF -->
    </form>


    
    <!--             -->
    <!-- ERROR AREA  -->
    <!--             -->

    <!-- TMPL_IF ERROR_MSG -->
    <div class='error_area'>
    I'm sorry, but there was an error processing your request.<br />
    <div class='error_message'>
    <!-- TMPL_VAR ERROR_MSG -->
    </div>
    Contact the administrator for more information.
    </div>        
    <!-- /TMPL_IF -->


    <!--             -->
    <!--  MSG AREA   -->
    <!--             -->

    <!--  TMPL_IF MESSAGE   -->
    <div class='message_area'>
    <div class='message'>
    <!-- TMPL_VAR MESSAGE -->
    </div>
    
    Your request was processed successfully.<p>
    <a href='<!-- TMPL_VAR URL -->' class='glink'>Click Here</a>
    to continue.
    </div>        
    <!-- /TMPL_IF -->


</body>
</html>);
}

1;

