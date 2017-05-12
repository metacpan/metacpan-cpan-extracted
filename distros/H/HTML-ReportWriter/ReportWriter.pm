package HTML::ReportWriter;

use strict;
use DBI;
use CGI;
use HTML::ReportWriter::PagingAndSorting;

our $VERSION = '1.5.1';

=head1 NAME

HTML::ReportWriter - Simple OO interface to generate pageable, sortable HTML tabular reports

=head1 SYNOPSIS

 #!/usr/bin/perl -w

 use strict;
 use HTML::ReportWriter;
 use CGI;
 use Template;
 use DBI;

 my $dbh = DBI->connect('DBI:mysql:foo', 'bar', 'baz');

 # The simplest possible method of calling RW...
 my $report = HTML::ReportWriter->new({
		DBH => $dbh,
		DEFAULT_SORT => 'name',
		SQL_FRAGMENT => 'FROM person AS p, addresses AS a WHERE a.person_id = p.id',
		COLUMNS => [ 'name', 'address1', 'address2', 'city', 'state', 'zip' ],
 });

 $report->draw();

=head1 DESCRIPTION

This module generates an HTML tabular report. The first row of the table is the header,
which will contain column names, and if the columns are sortable, the name will link back
to the cgi, and will allow for changing of the sort. Below the table of results is a paging
table, which shows the current page, along with I<n> other pages of the total result set, 
and includes links to the first, previous, next and last pages in the result set.

HTML::Reportwriter also supports column grouping, allowing for reports to display datasets like
the following:

 +------------+---------------+-------+
 |            |               |   1   |
 |            |    test       +-------+
 |   foo      |               |   2   |
 |            +---------------+-------+
 |            |    test2      |   3   |
 +------------+---------------+-------+

=head1 METHODS

=over

=item B<new($options)>

Accepts the same arguments as L<HTML::ReportWriter::PagingAndSorting>, plus the following:

=over

=item DBH
A database handle that has connected to the database that the report is to be run against.

=item SQL_FRAGMENT
An SQL fragment starting from the FROM clause, continued through the end of the where clause. In
the case of MySQL and/or other databases that support them, GROUP BY and HAVING clauses may also be
added to the SQL fragment.

=item COLUMNS
Column definitions for what is to be selected. A column definition consists of one of two formats, either
a simple one-element array reference or an array reference of hash references containing the following four
elements:

 get - the string used in the get variable to determine the sorted column
 sql - the sql statement that will select the data from the database
 display - What should be displayed in the column's table header
 sortable - whether or not a sorting link should be generated for the column
 order - (optional) sql that will be used to order by the specified column. If not present, then the value of sql is used
 group - (optional) true or false. If true, the column will be grouped after the results are retrieved.
 hide_column - (optional) true or false. If true, the column will not be drawn to the screen.  This is useful if you
                want to pull data for some other column's draw_func.
 draw_func - (optional) code ref, may not be used if group is true. code ref to a function which takes two parameters.
             param 1: the data from the column being rendered
             param 2: the hashref containing the data from the rest of the row
             returns: the string that should be displayed as the cell contents when that column is drawn

These definitions can be arbitrarily complex. For example:

 COLUMNS => [
     {
         get => 'username',
         sql => 'jp.username',
         display => 'Username',
         sortable => 1,
         group => 1,
     },
     {
         get => 'date',
         sql => 'DATE_FORMAT(l.created, \'%m/%e/%Y\') AS date',
         display => 'Date',
         sortable => 1,
         order => 'l.created',
     },
     {
         get => 'type',
         sql => "IF(l.deleted = 'yes', 'delete', 'add') AS type",
         display => 'Type',
         sortable => 1,
     },
     {
         sql => "l.id",
         hide_column => 1,
     },
     {
         get => 'successful',
         sql => "l.successful",
         display => 'Successful',
         sortable => 1,
         draw_func => sub { my ($data, $cols) = @_; my $lid = $cols->{'id'}; my $color = ($data eq 'no' ? 'red' : ($data eq 'yes' ? 'green' : 'black')); return "<a style=\"color: $color;\" href=\"#\" onClick=\"popup('/cgi-bin/reports/message.cgi?id=$lid'); return false;\">$data</a>"; },
     },
 ]

and

 COLUMNS => [ 'name', 'address', 'age' ]

are both valid definitions. Additionally, you can combine scalar and hashref-filled arrayrefs, like

 COLUMNS => [
     'name',
     'age',
     {
         get => 'birthday',
         sql => 'DATE_FORMAT(birthday, \'%m/%e/%Y\') AS birthday',
         display => 'Birthday',
         sortable => 1,
         order => 'birthday',
     },
 ]


If you are going to use complex sql structures in a column definiton (for example, the
DATE_FORMAT and IF statements above), it is STRONGLY recommended that you use a column alias (for example, the
'AS date' in the date column example) in order to ensure proper functionality. This module has not been tested
with unaliased complex sql column definitions.

NOTE: If you use formatting that would change a numeric-type column into a string-type column (for example the
date columns above), you should use the order attribute to ensure proper ordering. For example using DATE_FORMAT
as shown above results in the integer-style date column being treated as a string (20041010120000 becomes 
'10-10-2004'), which would cause '10-10-2004' to sort before '10-02-2004'. draw_func is intended to provide you
with a simple alternative to things like DATE_FORMAT -- you can now do the formatting outside the SQL.

=item DEBUG
Will cause useful debugging messages to be printed using the warn facility. default: 0

=item COLUMN_SORT_DEFAULT
If the simplified version of the COLUMNS definition is used (COLUMNS => [ 'foo', 'bar' ]), then this variable
determines whether the table header will allow sorting of any columns. It is global in scope; that is, either
every column is sortable, or every column is not. If the hashref method is used to define columns, this variable
will be ignored.

=item MYSQL_MAJOR_VERSION
Currently either 3, 4 or 5. Determines which method of determining num_results is used. In MySQL 4 a new method
was added which makes the process much more efficient. Defaults to 4 since it's been the stable release for well
over a year.

=item CGI_OBJECT
A handle to a CGI object. Since it is very unlikely that a report will ever be just a static report with no
user interaction, it is assumed that the coder will want to instantiate their own CGI object in order to allow
the user to interact with the report. Use of this argument will prevent needless creation of additional CGI objects.

=item PAGE_TITLE
The title of the current page. Defaults to "HTML::ReportWriter v${VERSION} generated report".

=item CSS
The CSS style applied to the page. Can be an external stylesheet reference or an inline style. Has a default inline
style that I won't waste space listing here.

=item HTML_HEADER
The first thing that will appear in the body of the HTML document. Unrestricted, can be anything at all. I recommend
placing self-referential forms here to allow the user to interact with the report (for example, setting date ranges).
See B<EXAMPLES> below for ideas.

=item HTML_FOOTER
Last thing that appears in the body of the page. Defaults to: '<center><div id="footer"><p align="center">This report
was generated using <a href="http://search.cpan.org/~opiate/">HTML::ReportWriter</a> version ' . $VERSION . '.</p></div>
</center>';

=item LANGUAGE_TOKENS
A list of language tokens that can be used to replace the default English text.

=item EXPORT_VARIABLE
Defaults to 'exportto'. This variable, if passed in via a GET or POST parameter, and set equal to a supported export method,
will cause the report to be exported. Set EXPORT_VARIABLE to '' to disable exporting. Currently supported formats:

=over

=item *
excel: Reports are exported without paging. Sorting is maintained. Grouping of results is disabled.

=back

=item REPORT_TABLE_WIDTH
Default: 800. The width of the table containing the report output.

=item DOCTYPE
Default: <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
Set to '' if you do not want to have a doctype declared.

=back

The return of this function is a reference to the object. Calling draw after the object's initialization will draw the page.

Note with regards to DEFAULT_SORT: the string used to specify the default sort must match the B<get> parameter of the COLUMNS
definition if you use a hashref COLUMN definition.

=cut

sub new
{
    my ($pkg, $args) = @_;

    my @paging_args = (
            'RESULTS_PER_PAGE',
            'PAGES_IN_LIST',
            'PAGE_VARIABLE',
            'SORT_VARIABLE',
            'DEFAULT_SORT',
            'PREV_HTML',
            'NEXT_HTML',
            'FIRST_HTML',
            'LAST_HTML',
            'ASC_HTML',
            'DESC_HTML',
            );
    my $paging_args = {};

    # check for required arguments
    if(!defined($args->{'DBH'}))
    {
        die 'Argument \'DBH\' is required';
    }
    elsif(!defined($args->{'SQL_FRAGMENT'}))
    {
        die 'Argument \'SQL_FRAGMENT\' is required';
    }
    elsif(!defined($args->{'COLUMNS'}) || ref($args->{'COLUMNS'}) ne 'ARRAY')
    {
        die 'Argument \'COLUMNS\' is required, and must be an array reference';
    }

    # define reasonable defaults for arguments if a value is not provided
    $args->{'COLUMN_SORT_DEFAULT'} = 1 if !defined $args->{'COLUMN_SORT_DEFAULT'};

    # this switch controls whether count(*) is used, or for MySQL the more efficient SQL_CALC_FOUND_ROWS
    # when getting the total number of results for pagination.
    $args->{'MYSQL_MAJOR_VERSION'} = 4 if !defined $args->{'MYSQL_MAJOR_VERSION'};
    if($args->{'DBH'}->{'Driver'}->{'Name'} ne 'mysql')
    {
        # we almost certainly cannot use SQL_CALC_FOUND_ROWS if the DBMS is not MySQL
        $args->{'MYSQL_MAJOR_VERSION'} = 3;
    }

    $args->{'DEBUG'} = 0 if !defined $args->{'DEBUG'};

    # html format specifiers
    $args->{'DOCTYPE'} = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">' if !defined $args->{'DOCTYPE'};
    $args->{'REPORT_TABLE_WIDTH'} = '800' if !defined $args->{'REPORT_TABLE_WIDTH'};

    $args->{'EXPORT_VARIABLE'} = 'exportto' if !defined $args->{'EXPORT_VARIABLE'};

    $args->{'LANGUAGE_TOKENS'} = {
                                    display_token => 'Displaying Results $1 to $2 of $3',
                                    export_data_to => 'Export this data to',
                                    export_report_data => 'Exported Report Data',
                                    export_value => 'Excel',
                                    no_results => 'There are no results to display.',
                                 } if !defined $args->{'LANGUAGE_TOKENS'};

    # check for simplified column definition, and make sure the COLUMNS array isn't empty
    # if the simplified definition is used, change it to the complex one.
    if(@{$args->{'COLUMNS'}})
    {
        $args->{'FIELDS'} = [];
        my $grouping_allowed = 1;
        my $size = @{$args->{'COLUMNS'}} - 1;

        foreach my $index (0..$size)
        {
            if(ref($args->{'COLUMNS'}->[$index]) eq 'SCALAR' || ref($args->{'COLUMNS'}->[$index]) eq '')
            {
                my $str = $args->{'COLUMNS'}->[$index];
                $args->{'COLUMNS'}->[$index] = {
                    'sql' => $str,
                    'get' => $str,
                    'display' => ucfirst($str),
                    'sortable' => ($args->{'COLUMN_SORT_DEFAULT'} ? 1 : 0),
                };
            }

            if(defined($args->{'COLUMNS'}->[$index]->{'group'}) && $args->{'COLUMNS'}->[$index]->{'group'} && defined($args->{'COLUMNS'}->[$index]->{'draw_func'}) && $args->{'COLUMNS'}->[$index]->{'draw_func'})
            {
                die 'You cannot define a draw_func for a grouped column';
            }

            # enforce the fact that grouping is only allowed at the beginning of a column list
            if(!defined($args->{'COLUMNS'}->[$index]->{'group'}) || !$args->{'COLUMNS'}->[$index]->{'group'})
            {
                # interesting efficiency question: is it faster to reassign in a safe situation,
                # or would it be more efficient if there were a check to prevent reassignment?
                $grouping_allowed = 0;
            }
            elsif(defined($args->{'COLUMNS'}->[$index]->{'group'}) && $args->{'COLUMNS'}->[$index]->{'group'})
            {
                if(!$grouping_allowed)
                {
                    die 'Grouped columns must be defined at the beginning of the column list';
                }
            }

            # construct a list of fields with group set if it is a grouped column
            my $col = $args->{'COLUMNS'}->[$index]->{'sql'};
            $col =~ s/^.+ AS (.+)$/$1/i;
            $col =~ s/^[a-zA-Z0-9]+\.//;
            push @{$args->{'FIELDS'}}, {
                'field' => $col,
                'group' => (defined($args->{'COLUMNS'}->[$index]->{'group'}) && $args->{'COLUMNS'}->[$index]->{'group'}),
                'draw_func' => (defined($args->{'COLUMNS'}->[$index]->{'draw_func'}) ? $args->{'COLUMNS'}->[$index]->{'draw_func'} : undef),
                'hide_column' => (defined($args->{'COLUMNS'}->[$index]->{'hide_column'}) && $args->{'COLUMNS'}->[$index]->{'hide_column'}),
            };
        }
    }
    else
    {
        die 'COLUMNS can not be a blank array ref';
    }

    # create a CGI object if we haven't been given one
    if(!defined($args->{'CGI_OBJECT'}) || !UNIVERSAL::isa($args->{'CGI_OBJECT'}, "CGI"))
    {
        $args->{'CGI_OBJECT'} = new CGI;
        warn "Creating new CGI object";
    }

    # I want to modularize this somehow... when that happens, this will need to be fixed.
    $args->{'EXPORT'} = $args->{'CGI_OBJECT'}->param($args->{'EXPORT_VARIABLE'});
    if(!defined($args->{'EXPORT'}) || $args->{'EXPORT'} ne 'excel')
    {
        $args->{'EXPORT'} = '';
    }

    # set up the arguments for the paging module, and delete them from the main arg list,
    # since we don't really care about them
    foreach my $key (@paging_args)
    {
        if(defined $args->{$key})
        {
            $paging_args->{$key} = $args->{$key};
            delete $args->{$key};
        }
    }

    # the paging module also gets a CGI_OBJECT, and a copy of the COLUMNS setup
    $paging_args->{'CGI_OBJECT'} = $args->{'CGI_OBJECT'};
    $paging_args->{'SORTABLE_COLUMNS'} = $args->{'COLUMNS'};
    $paging_args->{'LANGUAGE_TOKENS'} = $args->{'LANGUAGE_TOKENS'};

    # instantiate our paging object
    $args->{'PAGING_OBJECT'} = HTML::ReportWriter::PagingAndSorting->new($paging_args);

    # default HTML-related arguments
    if(!defined $args->{'PAGE_TITLE'})
    {
        $args->{'PAGE_TITLE'} = "HTML::ReportWriter v${VERSION} generated report";
    }
    if(!defined $args->{'HTML_HEADER'})
    {
        $args->{'HTML_HEADER'} = '';
    }
    if(!defined $args->{'HTML_FOOTER'})
    {
        $args->{'HTML_FOOTER'} = '<center><div id="footer"><p align="center">This report was generated using <a href="http://search.cpan.org/~opiate/">HTML::ReportWriter</a> version ' . $VERSION . '.</p></div></center>';
    }
    if(!defined $args->{'CSS'})
    {
        $args->{'CSS'} = "<style type=\"text/css\">\n\n#footer {\n    clear: both;\n    padding: 5px;\n    margin-top: 5px;\n    border: 1px solid gray;\n    background-color: rgb(213, 219, 225);\n    width: 600px;\n}\n\n.paging-table {\n    border: 0px solid black;\n}\n.paging-td {\n    padding: 4px;\n    font-weight: none;\n    color: #555555;\n}\n.paging-a {\n    color: black;\n    font-weight: bold;\n    text-decoration: none;\n}\n\n#idtable {\n        border: 1px solid #666;\n}\n\n#idtable tbody tr td {\n        padding: 3px 8px;\n        font-size: 8pt;\n        border: 0px solid black;\n        border-left: 1px solid #c9c9c9;\n        text-align: center;\n}\n\n#idtable tbody tr td.table_even {\n        background-color: #eee;\n}\n\n#idtable tbody tr td.table_odd {\n        background-color: #fff;\n}\n\n#idtable tbody tr.sortable-header-tr td {\n        background-color: #bbb;\n}\n</style>\n";
    }

    my $self = bless $args, $pkg;

    return $self;
}

=item B<draw()>

Renders the page.
This function takes one optional parameter, i<disable_output>. If the results are not being exported to a non-HTML format, and if
i<disable_output> evaluates to false then this function writes the HTTP header and the page text to STDOUT (the only behaviour prior
to version 1.5.0). If the parameter evaluates to true, the function does not print anything to STDOUT. In either of those cases, the
text of the HTML page is returned by B<draw()>.

If the results are being exported (to e.g. Excel), then the output will always be sent to STDOUT regardless of the value of
disable_output, and the function will return success or failure of the export.

=cut

sub draw
{
    eval
    {
        use Template;
    };

    if($@)
    {
        die "The draw function can not be utilized unless the module Template (template-toolkit.org) is installed";
    }

    my $self = shift;
    my( $disable_output ) = @_;
    my $to_return = '';

    my $results = $self->get_results();

    if($self->{'EXPORT'})
    {
        my $method = 'export_to_' . $self->{'EXPORT'};

        if(exists &$method)
        {
            return $self->$method($results);
        }
        else
        {
            die "export method $method does not exist";
        }
    }
    else
    {
        my $template = Template->new();
        my $url = $self->{'CGI_OBJECT'}->url( -absolute => 1, -query => 1 );

        my $vars = {
            'version'     => $VERSION,
            'css'         => $self->{'CSS'},
            'html_header' => $self->{'HTML_HEADER'},
            'html_footer' => $self->{'HTML_FOOTER'},
            'page_title'  => $self->{'PAGE_TITLE'},
            'sorting'     => $self->{'PAGING_OBJECT'}->get_sortable_table_header(),
            'fields'      => $self->{'FIELDS'},
            'draw_row'    => \&draw_row,
            'row_counter' => [], # this will be populated as draw_row runs
            'export_link' => ($self->{'EXPORT_VARIABLE'} ? $url . ($url =~ /\?/ ? "&" : "?") . "$self->{'EXPORT_VARIABLE'}=excel" : ''),
            'report_table_width' => $self->{'REPORT_TABLE_WIDTH'},
            'doctype' => $self->{'DOCTYPE'},
        };

        # grouping could be a costly operation, so only do it if necessary
        if(defined($self->{'FIELDS'}->[0]->{'group'}) && $self->{'FIELDS'}->[0]->{'group'})
        {
            $vars->{'results'} = $self->group_results($results);
        }
        else
        {
            $vars->{'results'} = $results;
        }

        # paging can only be drawn after we have the result set pulled
        $vars->{'paging'} = $self->{'PAGING_OBJECT'}->get_paging_table();

        $vars = { %{ $self->{'LANGUAGE_TOKENS'}}, %$vars };

        $template->process(\*DATA, $vars, \$to_return) || warn "Template processing failed: " . $template->error();

        if( !defined $disable_output || !$disable_output )
        {
            print $self->{'CGI_OBJECT'}->header;
            print "$to_return";
        }
    }

    return $to_return;
}

=item B<export_to_excel()>
=cut

sub export_to_excel
{
    eval
    {
        use Spreadsheet::SimpleExcel;
    };

    if($@)
    {
        die "You cannot use this feature unless SpreadSheet::SimpleExcel is installed";
    }

    my $self = shift;
    my ($results) = @_;

    my @header = map { $_->{'display'} } @{$self->{'COLUMNS'}};

    my $i = 0;
    foreach my $field ( @{$self->{'COLUMNS'}} )
    {
        if( "$field->{'hide_column'}" eq "1" )
        {
            map { splice( @$_, $i, 1) }  @$results;
        }
        $i++;
    }
    binmode(\*STDOUT);

    # create a new instance
    my $excel = Spreadsheet::SimpleExcel->new();

    # add worksheets
    $excel->add_worksheet('Exported Report Data',{-headers => \@header, -data => $results});

    # create the spreadsheet
    return $excel->output();
}

=item B<draw_row()>

This function is magical. One day, when I am feeling brave, I will comment it. What ever happened to the nice textbook
recursive functions they taught in CS class?

It is internal to HTML::ReportWriter, and shouldn't need to be overridden. If you want to customize the look and feel of the
report, you can use the draw_func option to the columns to override the appearance of a given element, and you can customize
the stylesheet at creation-time (see new()).

=cut

sub draw_row
{
    my($fields, $results, $row_counter, $print, $open, $depth) = @_;
    my $rowspan = 0;
    my $output = '';

    if(ref($results) ne 'ARRAY')
    {
        $results = [ $results ];
    }

    foreach my $res (@$results)
    {
        ++$row_counter->[$depth];

        # We're dealing with a simple result set right now
        if(!defined($res->{'HTML::ReportWriter group column'}))
        {
            ++$rowspan;

            if(!$open)
            {
                $output .= '<tr>';
            }

            foreach my $field (@$fields)
            {
                my $fname = $field->{'field'};

                if(exists($res->{$fname}) && !$field->{'hide_column'})
                {
                    $output .= '<td class="' . ($row_counter->[$depth] % 2 ? 'table_odd' : 'table_even') . "\">";
                    if(ref($field->{'draw_func'}) eq 'CODE')
                    {
                        $output .= $field->{'draw_func'}->($res->{$fname}, $res);
                    }
                    else
                    {
                        $output .= (defined($res->{$fname}) ? $res->{$fname} : '');
                    }
                    $output .= "</td>";
                }
            }
            $output .= "</tr>\n";

            if($open)
            {
                $open = 0;
            }

        }

        # now we're dealing with a grouped row
        else
        {
            my ($crowspan, $coutput) = draw_row($fields, $res->{'rows'}, $row_counter, 0, 1, $depth + 1);
            $rowspan += $crowspan;

            if(!$open)
            {
                $output .= '<tr>';
            }

            $output .= '<td class="' . ($row_counter->[$depth] % 2 ? 'table_odd' : 'table_even') . '" rowspan="' . $crowspan . '">'
                . $res->{'HTML::ReportWriter group column'} . '</td>' . $coutput;

            if($open)
            {
                $open = 0;
            }
        }
    }

    if($print)
    {
        return $output;
    }
    else
    {
        return ($rowspan, $output);
    }
}

=item B<group_results()>

Internal method -- groups a result set if necessary.

=cut

sub group_results
{
    my ($self, $data) = @_;

    my $results = [];

    # code below relies on the fact that having two refs $p and $q, setting $p = $q makes them refer to the same memory location.
    # thus, I am using $p as a pointer to my current depth in the results data structure.
    foreach my $href (@$data)
    {
        my $p = $results;
        my $current_element_number = -1;

        # process each field separately, and move the pointer as we go along
        # this will be a little slow; if anyone has an idea for improving its performance, please share.
        foreach my $f (@{$self->{'FIELDS'}})
        {
            if(defined($f->{'group'}) && $f->{'group'})
            {
                my $val = $href->{$f->{'field'}};

                my $found = -1;
                my $size = scalar @{$p};

                if($size)
                {
                    foreach my $index (0..($size-1))
                    {
                        if($p->[$index]->{'HTML::ReportWriter group column'} eq $val)
                        {
                            $found = $index;
                            last;
                        }
                    }
                }

                if($found != -1)
                {
                    $p = $p->[$found]->{'rows'};
                }
                else
                {
                    $p->[$size] = {
                        'HTML::ReportWriter group column' => $val,
                        'rows' => [],
                    };
                    $p = $p->[$size]->{'rows'};
                }
            }
            else
            {
                if($current_element_number == -1)
                {
                    my $size = @{$p};
                    $p->[$size] = {};
                    $current_element_number = $size;
                }

                $p->[$current_element_number]->{$f->{'field'}} = $href->{$f->{'field'}};
            }
        }
    }

    return $results;
}

=item B<get_results()>

Internal method -- generates the result set used by draw().

=cut

sub get_results
{
    my $self = shift;
    my $loop_counter = 0;
    my $results = [];

    # assume no paging if we are exporting the results
    if($self->{'EXPORT'})
    {
        my $sql = 'SELECT '
            . join(', ', map { $_->{'sql'} } @{$self->{'COLUMNS'}})
            . ' ' . $self->{'SQL_FRAGMENT'};
        my $sort = $self->{'PAGING_OBJECT'}->get_sort($self->{'DBH'}->{'Driver'}->{'Name'});

        if($self->{'DEBUG'})
        {
            warn "Executing SQL: $sql $sort";
        }

        my $sth = $self->{'DBH'}->prepare("$sql $sort");
        $sth->execute();
        $results = $sth->fetchall_arrayref;
        $sth->finish;
    }
    elsif($self->{'MYSQL_MAJOR_VERSION'} >= 4)
    {
        my $sql = 'SELECT SQL_CALC_FOUND_ROWS '
            . join(', ', map { $_->{'sql'} } @{$self->{'COLUMNS'}})
            . ' ' . $self->{'SQL_FRAGMENT'};
        my $sort = $self->{'PAGING_OBJECT'}->get_sort($self->{'DBH'}->{'Driver'}->{'Name'});
        my $limit = $self->{'PAGING_OBJECT'}->get_limit($self->{'DBH'}->{'Driver'}->{'Name'});

        if($self->{'DEBUG'})
        {
            warn "Executing SQL: $sql $sort $limit";
        }

        my $sth = $self->{'DBH'}->prepare("$sql $sort $limit");
        $sth->execute();
        my ($count) = $self->{'DBH'}->selectrow_array('SELECT FOUND_ROWS() AS num');

        my $status = $self->{'PAGING_OBJECT'}->num_results($count);

        # if $count is 0, then there are no results and the check should be skipped. Else, if there are rows and num_results
        # returns false, then we've somehow paged past the end of the result set. Get back on track here.
        while(!$status && $count)
        {
            $limit = $self->{'PAGING_OBJECT'}->get_limit($self->{'DBH'}->{'Driver'}->{'Name'});

            $sth->finish;

            if($self->{'DEBUG'})
            {
                warn "Executing SQL: $sql $sort $limit";
            }

            $sth = $self->{'DBH'}->prepare("$sql $sort $limit");
            $sth->execute();
            ($count) = $self->{'DBH'}->selectrow_array('SELECT FOUND_ROWS() AS num');

            $status = $self->{'PAGING_OBJECT'}->num_results($count);

            # if we aren't back on track in 3 loops, we've got a problem
            if(++$loop_counter == 3)
            {
                die "Unrecoverable error -- is the result set changing?";
            }
        }

        while(my $href = $sth->fetchrow_hashref)
        {
            push @$results, $href;
        }
    }
    elsif($self->{'MYSQL_MAJOR_VERSION'} < 4)
    {
        # MySQL 3.23 requires the use of a count query -- SQL_CALC_FOUND_ROWS had not yet been implemented
        my $countsql = 'SELECT count(*) ' . $self->{'SQL_FRAGMENT'};

        if($self->{'DEBUG'})
        {
            warn "Executing SQL: $countsql";
        }

        my $sth = $self->{'DBH'}->prepare("$countsql");
        $sth->execute();
        my ($count) = $sth->fetchrow_array;
        $sth->finish;

        # We won't bother checking the status, cause we're just now generating the limit clause, so it is not likely
        # the result set could have changed.
        $self->{'PAGING_OBJECT'}->num_results($count);

        my $sql = 'SELECT ' . join(', ', map { $_->{'sql'} } @{$self->{'COLUMNS'}}) . ' ' . $self->{'SQL_FRAGMENT'};
        my $sort = $self->{'PAGING_OBJECT'}->get_sort($self->{'DBH'}->{'Driver'}->{'Name'});
        my $limit = $self->{'PAGING_OBJECT'}->get_limit($self->{'DBH'}->{'Driver'}->{'Name'});

        if($self->{'DEBUG'})
        {
            warn "Executing SQL: $sql $sort $limit";
        }

        $sth = $self->{'DBH'}->prepare("$sql $sort $limit");
        $sth->execute();

        while(my $href = $sth->fetchrow_hashref)
        {
            push @{$results}, $href;
        }
    }
    else
    {
        die "this should never happen";
    }

    return $results;
}

=back

=head1 A NOTE ABOUT GROUPING

Grouping is done in code after the database returns its dataset. Grouping breaks sortability
(or vice-versa depending on your point of view) to a small degree, and for large datasets grouping
can produce unexpected results across pages.

In particular, if a group of 6 rows of data spans two pages (say 3 results on page 1 and 3 results
on page 2), then only three results will show on page 1. For this reason, it is recommended on pages
that have highly-constrained result sets (1 page of results), or where paging is disabled.

Additionally, it is strongly recommended that authors using this module consider which columns really
need to be sortable when using grouping. Based on limited testing and experience, if sorting is
necessary, I recommend only allowing sorting on the grouped columns. I also recommend making the
default sort == the first grouped column.

When you sort by an ungrouped column, the grouped columns are still grouped, despite the fact that
they may appear adjacent. Order of the rows is preserved. For example, assume the following dataset
was sorted by the third column and grouped by the first:

 test       foo      5
 test2      quux     4
 test       bar      3
 test2      bat      2
 test       baz      1

Output would be:

 +-------+------+---+
 |       | foo  | 5 |
 |       +------+---+
 | test  | bar  | 3 |
 |       +------+---+
 |       | baz  | 1 |
 +-------+------+---+
 |       | quux | 4 |
 | test2 +------+---+
 |       | bat  | 2 |
 +-------+------+---+

One restriction on grouped columns is that they must appear at the beginning of the column list:

 COLUMNS => [
     {
         get => 'username',
         sql => 'jp.username',
         display => 'Username',
         sortable => 1,
         group => 1,
     },
     {
         get => 'date',
         sql => 'DATE_FORMAT(l.created, \'%m/%e/%Y\') AS date',
         display => 'Date',
         sortable => 1,
         order => 'l.created',
     },
 ]

is correct, whereas:

 COLUMNS => [
     {
         get => 'username',
         sql => 'jp.username',
         display => 'Username',
         sortable => 1,
     },
     {
         get => 'date',
         sql => 'DATE_FORMAT(l.created, \'%m/%e/%Y\') AS date',
         display => 'Date',
         sortable => 1,
         order => 'l.created',
         group => 1,
     },
 ]

will result in die() being called.

=head1 USING HTML::ReportWriter WITH OTHER DATASOURCES

While it is my hope that I will eventually be able to add any datasource that someone
could want to this package, I know that in the meantime, some people are left hanging. As
a result of the recent separation of data retrieval into the get_results() method, you can
now add support for any data retrieval method you wish: either subclass HTML::ReportWriter
and override get_results, or modify your created object like

 $report->{'get_results'} = \&data_retrieval_func();

If you override the function, your new function should take no parameters, rely on $self to
provide necessary paging and sorting information, and return an arrayref consisting of
hashrefs containing { column => value } pairs for each column that is passed in to new using
COLUMNS. I haven't tested this, but see no reason why it should not work.

Please do not rely on this as anything more than a temporary fix -- I expect that the internals
of the module will change somewhat dramatically when I finally decide on a method of abstracting
data retrieval. Suggestions welcome on how to abstract data retrieval.

Update: overriding this function will cause breakage unless either (1) Your function is modified to
take exports into account, or (2) You disable export functionality in your report.

=head1 TODO

=over

=item *
write tests for the module

=item *
support for other databases (help greatly appreciated)

=item *
implement export feature supporting export to PDF for the results

=item *
overrides for shading behaviour and line drawing between cells.

=item *
I am debating the addition of support for query prefixes, like DISTINCT (which should appear before
the list of data to be selected). This could also be used for extensions like MySQL's SQL_NO_CACHE
directives. Feedback welcome.

=back

=head1 EXAMPLES

Data: the following statements can be reloaded into a mysql database and the resulting tables
can be used in conjunction with the scripts below to demo the features of the reportwriter.
The data should be imported into a DB named testing, and have a root user with a blank password,
or else you need to edit the DBI->connect statements below. I'd recommend never having a blank root
password, personally.

 CREATE TABLE log (
       userid int(10) default NULL,
       activity char(24) default NULL,
       created timestamp(14) NOT NULL
     ) TYPE=MyISAM;

 INSERT INTO log VALUES (1,'test',20050124064258);
 INSERT INTO log VALUES (1,'test2',20050124064301);
 INSERT INTO log VALUES (1,'test3',20050124064303);
 INSERT INTO log VALUES (1,'test4',20050124064305);
 INSERT INTO log VALUES (2,'test4',20050124064308);
 INSERT INTO log VALUES (3,'test5',20050124064313);
 INSERT INTO log VALUES (2,'test6',20050124064317);
 INSERT INTO log VALUES (2,'test7',20050124064319);

 CREATE TABLE people (
           name char(25) default NULL,
           age int(2) default NULL,
           birthday timestamp(14) NOT NULL,
           phone_number char(10) default NULL,
           active int(1) default '1'
     ) TYPE=MyISAM;

 INSERT INTO people VALUES ('Barney Rubble',20,19700101000000,'9724443456',1);
 INSERT INTO people VALUES ('Fred Flintstone',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('wilma',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('dino',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('bambam',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('george',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('elroy',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('judy',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('jane',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('disco',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('tango',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('foxtrot',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('waltz',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('swing',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('i',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('am',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('not',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('feeling',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('creative',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('right',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('now',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('so',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('the',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('sample',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('data',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('sucks.',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('sorry',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('about',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES ('that!',25,19700401000000,'9725551212',1);
 INSERT INTO people VALUES (':)',25,19700401000000,'9725551212',1);

 CREATE TABLE user (
           id int(10) default NULL,
           name char(15) default NULL,
           groupid int(1) default NULL
     ) TYPE=MyISAM;

 INSERT INTO user VALUES (1,'zeus',3);
 INSERT INTO user VALUES (2,'apollo',2);
 INSERT INTO user VALUES (3,'mercury',3);

Example 1, a simple non-interactive report, like one that might be used to show phonebook
entries:

 #!/usr/bin/perl -w

 use strict;
 use HTML::ReportWriter;
 use DBI;

 my $dbh = DBI->connect('DBI:mysql:host=localhost:database=testing', 'root', '');

 my $sql_fragment = 'FROM people WHERE active = 1';

 my $report = HTML::ReportWriter->new({
         DBH => $dbh,
         SQL_FRAGMENT => $sql_fragment,
         DEFAULT_SORT => 'birthday',
         COLUMNS => [
            'name',
            'age',
            'birthday',
            {
                get => 'phone',
                sql => 'phone_number',
                display => 'Phone Number',
                sortable => 0,
            },
         ],
 });

 $report->draw();

Example 2, an interactive report allowing the user to select data within a date range.

 #!/usr/bin/perl -w

 use strict;
 use CGI;
 use HTML::ReportWriter;
 use DBI;

 my $dbh = DBI->connect('DBI:mysql:host=localhost:database=testing', 'root', '');
 my $co = CGI->new();

 # set defaults if there is not a setting for date1 or date2
 my $date1 = $co->param('date1') || '20050101000000';
 my $date2 = $co->param('date2') || '20050201000000';

 my $sql_fragment = 'FROM log AS l, user AS u WHERE l.userid = u.id AND u.groupid = '
                  . $dbh->quote(3) . ' AND l.created BETWEEN '
                  . $dbh->quote($date1) . ' AND ' . $dbh->quote($date2);

 my $report = HTML::ReportWriter->new({
         DBH => $dbh,
         CGI_OBJECT => $co,
         SQL_FRAGMENT => $sql_fragment,
         DEFAULT_SORT => 'date',
         HTML_HEADER => '<form method="get"><table><tr><td colspan="3">Show results from:</td></tr><tr>
                         <td><input type="text" name="date1" value="' . $date1 . '" /></td>
                         <td>&nbsp;&nbsp;to&nbsp;&nbsp;</td>
                         <td><input type="text" name="date2" value="' . $date2 . '" /></td></tr>
                         <tr><td colspan="3" align="center"><input type="submit" /></td></tr></table></form>',
         PAGE_TITLE => 'Log Activity for Group ' . 'foo',
         COLUMNS => [
             'name',
             'activity',
             {
                 get => 'date',
                 sql => 'DATE_FORMAT(l.created, \'%m/%e/%Y\') AS date',
                 display => 'Date',
                 sortable => 1,
             },
         ],
 });

 $report->draw();

Caveats for Example 2:

=over

=item *
By using the short form of the column definitions, you are asserting that there is only
one column named 'name' and one column named 'activity' in both the log and user tables combined. You'd get an
SQL error otherwise for having an ambiguous column reference.

=item *
Assumption is that the user enters the date in as a MySQL timestamp in the form. I got lazy as I was writing this
example. Also, the form would probably not look great, because the table is not formatted, nor does it have an
alignment on the page -- the report would be centered and the form left-justified. Making things pretty is left
as an exercise for the reader.

=back

=head1 BUGS

None are known about at this time.

Please report any additional bugs discovered to the author.

=head1 SEE ALSO

This module relies on L<DBI>, L<Template> and L<CGI>.
The paging/sorting module also relies on L<POSIX> and L<List::MoreUtils>.
Exporting to Excel uses L<Spreadsheet::SimpleExcel>.

=head1 AUTHOR

Shane Allen E<lt>opiate@gmail.comE<gt>

=head1 ACKNOWLEDGEMENTS

=over

=item *
PagingAndSorting was developed during my employ at HRsmart, Inc. L<http://www.hrsmart.com> and its
public release was graciously approved.

=item *
Robert Egert was an early adopter, and made signifigant contributions in the form of suggestions and
bug reports.

=item *
Mark Stosberg made several contributions including documentation corrections and PostgreSQL support.

=item *
Steven Mackenzie contributed a patch to add support for SQLite.

=back

=head1 COPYRIGHT

Copyright 2004, Shane Allen. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__DATA__
[% IF doctype -%]
[% doctype %]
[% END -%]
<html>
<head>
<title>[% page_title %]</title>
[% css %]
</head>
<body>
[% html_header %]
<center>
<table border="0" width="[% report_table_width %]">
<tr><td>
<table id="idtable" border="0" cellspacing="0" cellpadding="4" width="100%">
[% sorting %]
[%- IF results.size < 1 %]
<tr><td colspan="[% fields.size %]" align="center">[% no_results %]</td></tr>
[%- ELSE %]
    [%- FOREACH x = results %]
        [% draw_row(fields, x, row_counter, 1, 0, 0) %]
    [%- END %]
[%- END %]
</table>
</td></tr>
<tr><td>
<table border="0" width="100%">
<tr>
<td width="75%"></td><td width="25%">[% paging %]</td>
</tr>
</table>
</td></tr>
</table>
</center>
[%- IF(export_link) %]
<script language="JavaScript">
function export_popup(url)
{
            window.open (url,'filedl','toolbar=yes,location=no,directories=no,status=no,menubar=yes,scrollbars=yes,resizable=yes,copyhistory=no,width=300,height=400,screenX=0,screenY=0,top=0,left=0');
}
</script>
<p align="center">[% export_data_to %]: [ <a href="#" onClick="javascript:export_popup('[% export_link %]'); return false;">[% export_value %]</a> ]</p>
[%- END %]
<br /><br />
[% html_footer %]
</body>
</html>
