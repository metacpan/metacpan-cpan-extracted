package JQuery::TableSorter ; 

our $VERSION = '1.00';

use warnings;
use strict;

use HTML::Table ; 
use JQuery::CSS ; 

sub new { 
    my $this = shift;
    my $class = ref($this) || $this;
    my $my ;
    %{$my->{param}} = @_ ; 
    die "No id defined for TableSorter" unless $my->{param}{id} =~ /\S/ ; 
    die "No data defined for TableSorter" unless ref($my->{param}{data}) eq 'ARRAY' ; 

    bless $my, $class;

    my $jquery = $my->{param}{addToJQuery} ; 
    my $jqueryDir = $jquery->getJQueryDir ; 
    $my->{fileDir} = "$jqueryDir/plugins" ;

    if ($my->{param}{css}) { 
	push @{$my->{css}},$my->{param}{css} ; 
    } 

    $my->add_to_jquery ; 
    return $my ;
}

sub add_to_jquery { 
    my $my = shift ; 
    my $jquery = $my->{param}{addToJQuery} ; 
    if (defined $jquery) { 
	$jquery->add($my) ; 
    } 
} 

sub id {
    my $my = shift ;
    return $my->{param}{id} ; 
}


sub HTML { 
    my $my = shift ;
    my $data = $my->{param}{'data'} ;
    if (!defined $data) {
	die "TableSorter: No data field supplied\n" ; 
    } 
    my @data = @{$data} ; 
    my $head = shift @data ;
    my $tile = new HTML::Table(-spacing=>0,-head=>$head ,-data=>\@data) ;
    my $id = $my->{param}{'id'} ; 
    $tile =~ s!<table !<table id="$id" ! if defined $id ; 
    $tile =~ s!<tr>!<thead><tr>! ; 
    $tile =~ s!</tr>!</tr></thead><tbody>! ; 
    $tile =~ s!</table>!</tbody></table>! ; 
    
    return $tile ; 
}

sub packages_needed { 
    my $my = shift ;
    return ('tablesorter/jquery.tablesorter.js') ; 
} 

sub get_css { 
    my $my = shift ;
    my $id = $my->id ; 
    my $css =<<'EOD' ; 

#ID th {
	background-color: #e9e9da;
}
#ID td {
	
	padding:5px;
}	

.headerSimple {
		background: 
			#e9e9da
			url('PLUGIN_DIR/tablesorter/green_arrows.gif')
			no-repeat
			center left;
		color: #333;
		padding: 5px;
		padding-left: 25px;
		text-align: left;
		cursor: pointer;	
}

.headerSimpleSortUp {
	background:
		#e9e900 
		url('PLUGIN_DIR/tablesorter/green_descending.gif')		
		no-repeat
		center left;
}

.headerSimpleSortDown {
	background:
		#e9e900 
		url('PLUGIN_DIR/tablesorter/green_ascending.gif')
		no-repeat
		center left;
}

.even {  
  background-color: lightblue;
}

.odd {  
  background-color: #5AAFFF;
}

.highlight { 
  color: grey;
}

.header {
	background-image: url(PLUGIN_DIR/tablesorter/header-bg.png);
	background-repeat: no-repeat;
	border-left: 1px solid #FFF;
	border-right: 1px solid #000;
	border-top: 1px solid #FFF;
	padding-left: 30px;
	padding-top: 4px;
	padding-bottom: 4px;
	height: auto;
        cursor: pointer;	
}

.headerSortUp {
	background-image: url(PLUGIN_DIR/tablesorter/header-asc.png);
	background-repeat: no-repeat;
	border-left: 1px solid #FFF;
	border-right: 1px solid #000;
	border-top: 1px solid #FFF;
	padding-left: 30px;
	padding-top: 4px;
	padding-bottom: 4px;
	height: auto;
        cursor: pointer;	
}
.headerSortDown {
	background-image: url(PLUGIN_DIR/tablesorter/header-desc.png);
	background-repeat: no-repeat;
	border-left: 1px solid #FFF;
	border-right: 1px solid #000;
	border-top: 1px solid #FFF;
	padding-left: 30px;
	padding-top: 4px;
	padding-bottom: 4px;
	height: auto;
        cursor: pointer;	
}
EOD
    $css =~ s!#ID!#$id!g ; 
    $css =~ s!PLUGIN_DIR!$my->{fileDir}!g ; 
    return $css ; 



} 


sub get_jquery_code { 
    my $my = shift ; 

    # Construct the function for the table sorter
    # ????? disableHeader: ['ip'] This is an array
    # ????? columnParser: [[1,'url']] What is this????

    my @names = qw[sortClassAsc sortClassDesc headerClass disableHeader columnParser dateFormat stripe sortColumn stripingRowClass highlightClass stripRowsOnStartUp] ;
    
    my $param = $my->{param} ;

    my $tableName = $param->{id} ;
    my $function = qq[\$("#$tableName").tableSorter({] . "\n" ; 
    my @lines ; 
    for my $name (@names) {
	my $value = $param->{$name} ; 
	next unless defined $value ;
	if (ref($value) eq 'ARRAY') { 
	    my $values = join ',', map { "'" . $_ . "'" } @$value ;  
	    push @lines, "   $name: [$values]" ;
	    next ;
	} 
	push @lines,"   $name: '$param->{$name}'" ;
    }
    my $lines = join(",\n",@lines) ; 
    $function .= $lines ; 
    $function .= "});\n" ; 
    return $function ; 
}
1;



=head1 NAME

JQuery::TableSorter - The JQuery TableSorter

=head1 SYNOPSIS

    use JQuery ; 
    use JQuery::TableSorter ; 

    # define JQuery
    my $jquery = new JQuery ; 


    # Create data for the table
    my $data = [['Id','Total','Ip','Time','US Short Date','US Long Date'],
		['66672',  '$22.79','172.78.200.124','08:02','12-24-2000','Jul 6, 2006 8:14 AM'],
		['66672','$2482.79','172.78.200.124','15:10','12-12-2001','Jan 6, 2006 8:14 AM'],
		['66672',  '$22.79','172.78.200.124','08:02','12-24-2000','Jul 6, 2006 8:14 AM'],
		['66672','$2482.79','172.78.200.124','15:10','12-12-2001','Jan 6, 2006 8:14 AM']
	       ] ;

    $jquery->add_css(new JQuery::CSS( hash => {
				         '#table1' => {width => '900px', 'font-size' => '15px'}
					})) ; 

    # Create a TableSorter, add it to JQuery, and get the result as HTML
    my $tableHTML = JQuery::TableSorter->new(id => 'table1', 
                                             addToJQuery => $jquery,
                                             data => $data, 
                                             dateFormat=>'dd/mm/yyyy', 
					     sortColumn => 'Total', 
					     sortClassAsc => 'headerSortUp', 
					     sortClassDesc => 'headerSortDown',
					     headerClass => 'header',
					     stripingRowClass =>  ['even','odd'],
					     stripRowsOnStartUp => 'true',
					     #highlightClass => 'highlight', 
					     disableHeader => 'true'
					     ))->HTML ; 
    # Get the JQuery code
    my $code = $jquery->get_jquery_code ;

    # Get the CSS
    my $css = $jquery->get_css ;  

    # All that needs to be done is to place the html, jquery code and css in a template

=head1 DESCRIPTION

This module defines a table which is sorted when the user clicks the
header. There are two builtin styles, to use them you have to set:

    headerClass => 'header',
    sortClassAsc => 'headerSortUp', 
    sortClassDesc => 'headerSortDown',

or

    headerClass => 'headerSimple',
    sortClassAsc => 'headerSimpleSortUp', 
    sortClassDesc => 'headerSimpleSortDown',

To see them, run the jquery_tablesorter1.pl and jquery_tablesorter2.pl examples.

In any event, you can always add CSS afterwards to change the appearance.

This module is based on the JQuery TableSorter. Definitive information
for TableSorter can be found at L<http://motherrussia.polyester.se/jquery-plugins/tablesorter/>. Examples can be found at 
L<http://motherrussia.polyester.se/pub/jquery/tablesorter/1.0.3/docs/>.

=head1 PARAMETERS
These are the parameters that new can take.

=over 

=item id 
    id - css id - mandatory

=item data
    data - a double array containing the data - mandatory

=item headerClass
    headerClass - the name of the css class defining the header

=item dateFormat 
    dateFormat - format to display the date 'dd/mm/yyyy'

=item sortColumn
    sortColumn - String of the name of the column to sort by.

=item sortClassAsc
    sortClassAsc - headerSortUp - Class name for ascending sorting action to header

=item sortClassDesc
    sortClassDesc - headerSortDown - Class name for descending sorting action to header

=item headerClass 
    headerClass -header  Class name for headers (th's)

=item highlightClass
    highlightClass - highlight - class name for sort column highlighting.

=item headerClass 
    headerClass - header  Class name for headers (th's)=back

=item stripingRowClass 
    stripingRowClass - class

=item disableHeader
    disableHeader - true/false

=back

=head1 FUNCTIONS

=over 

=item HTML

Get the HTML text for the object

=item new

Instantiate the object

=back



=head1 AUTHOR

Peter Gordon, C<< <peter at pg-consultants.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-jquery-taconite at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JQuery>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JQuery

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JQuery>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/JQuery>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Gordon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of JQuery::TableSorter


