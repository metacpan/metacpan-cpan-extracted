package HTML::DataTable;

use 5.006;
use strict;
use warnings;

use HTML::FromArrayref;

use overload q{""} => \&list_HTML;

=head1 NAME

HTML::DataTable - Print HTML tables from Perl data

=head1 VERSION

Version 0.54

=cut

our $VERSION = 0.54;

=head1 SYNOPSIS

  use HTML::DataTable
  my $list = HTML::DataTable->new(
    data => $cgi_data,
    columns => [
      # hashrefs describing column formats
    ],
    rows => [
      # arrayrefs listing data to show in table
    ],
  );
  print $list;

=head1 METHODS

=head2 new()

Creates a new HTML::DataTable object.

=head3 ATTRIBUTES

=head3 header_bg

The HTML color code for the background of the first row of the list.

=head3 header_bar

If this is defined, there will be a 1px black line under the header.

=head3 shade_alternate_rows

If this is defined, then alternating rows will be colored differently.

=head3 light_bg, dark_bg

The HTML color codes for the alternating backgrounds of the list rows.

=head3 sections

If this evaluates to a reference to a subroutine, then that subroutine will be called with each row's values, and when the returned values changes, the table will be divided and the value printed as a section title. (Since there's no value initially, there will be a section title before the first row.)

=head3 section_headers

If this is defined, the table header will be reprinted after each section title.

=head3 alphabet

If this is defined, a linked alphabet index will be printed above the table header. Subclasses of this class are responsible for using the "letter" CGI parameter to show the appropriate rows.

=head3 search

If this is defined, then a field called "search" will be shown in the table header (after the alphabet, if that attribute is also defined). If it evaluates to a reference to a hash, then the keys of the hash will be shown in a SELECT control called "search_columns" after the field. Subclasses of this class are responsible for using these CGI parameters to show the appropriate rows.

=head3 data

Should be assigned a hashref representing the CGI parameters.

=head3 rows

One of:

* An arrayref listing one arrayref holding the values to appear in each row of the list.

* An arrayref listing one hashref holding the values to appear in each row of the list.

* A hashref mapping each row's ID to a hashref holding the values to appear in that row of the list, in which case the "sort" attribute should name the hash key by which to sort the hashref entries.

=head3 columns

An arrayref listing one hashref defining each column of the table. These hashrefs can have these attributes:

=head4 header

The text to print at the top of this column.

=head4 category

A second-level header to be printed above the column header; adjacent column's category headers will be merged if they are the same.

=head4 format

This can be either

* A scalar, which will be used as an index in the current row's data array

* An arrayref, which will list an index in the current row's data array and singular and plural nouns to append to the value found there

* A reference to a subroutine, which will be passed the current row's data array

* A hashref, which will map a predefined format name to an index in the current row's data array

=head4 none

A string to show if the value in that column is undefined. Defaults to "None".

=head4 style, class, align

If any of these attributes evaluate to a string, they will become the corresponding attributes of each table cell in the column.

=head4 action

The path or URL of a CGI program to which each entry will linked.

=head4 data

A reference to a hash listing the CGI parameters to be included in the "action" link. Each value is either a scalar or a reference, as for the "format" attribute.

=head4 link_empty

If defined, then if the value in the column is undefined the "None" shown will be linked to the "action" URL.

=head4 norepeat

If this is defined, then the column will be left blank if the value printed would be the same the that for the previous row.

=head4 nobr

If this is defined, then the column's content will be surrounded by <nobr> tags so it isn't formatted into multiple lines.

=cut

sub new {
	my $pkg = shift;

	my $attribs = ref $_[0] ? $_[0] : { @_ };
	return bless $attribs, $pkg;
}

=head3 list_HTML()

Returns the HTML that renders the list.

=cut

sub list_HTML {
	my $me = shift;

	my ($html, $title, @cols, $bgcolor);

	if ( ! $me->{columns} ) {
		print "<p>Invalid list definiton.</p>";
		return;
	}

	$me->{cellpadding} ||= 1;
	$me->{cellspacing} ||= 0;
	$me->{light_bg} ||= '#ffffff';
	$me->{_bg_color} = $me->{dark_bg} ||= '#eeeeee';
	$me->{header_bg} ||= $me->{dark_bg};
	$me->{none} ||= 'None';
	$me->{shade_alternate_rows} = 'no' if grep $_->{shade_alternate_vals}, @{$me->{columns}};

	$me->{columns}->[0]->{class} = 'first_col';

	if ( $me->{alphabet} and ! $me->{data}->{search} ) {
		$me->set_letter( $me->{data}->{letter} ||= 'a' );
	}

	if ( $me->{data}->{search} ) {
		$me->set_search();
	}

	# SET ORDER BY IF SORTING ##############

	delete $me->{data}->{sort} if defined $me->{data}->{sort} and $me->{data}->{sort} eq $me->{sort}->[0];
	unshift @{$me->{sort}}, $me->{data}->{sort} if defined $me->{data}->{sort};

	delete $me->{data}->{sort_dir} if defined $me->{data}->{sort_dir} and $me->{data}->{sort_dir} eq 'asc';
	$me->{sort_dir} = $me->{data}->{sort_dir} if defined $me->{data}->{sort_dir};
	if ( $me->{sort} ) { $me->set_sort_order }

	# PRINT LIST #############

	$me->{n_cols} = scalar( @{$me->{columns}} );

	$html .= qq(<p class="hed">$me->{hed}</p>) if $me->{hed};
	$me->{cellpadding} ||= 1;
	$me->{cellspacing} ||= 0;
	my $table_attribs = join ' ', map qq($_="$me->{$_}"), grep exists $me->{$_},
		qw( border width cellspacing cellpadding class id style );
	$html .= qq(<table $table_attribs>);
	$html .= qq(<form method="get">) if $me->{search};

	# List header ###########

	my $alphabet = $me->alphabet if $me->{alphabet};
	my $search = $me->search_form if $me->{search} and ! $me->{hide_search_form};

	# Alphabet
	$html .= qq(<tr><td align="center" colspan="$me->{n_cols}" class="first_col" id="alphabet">$alphabet$search</td></tr>)
		if $alphabet or $search;

	# Table header
	$html .= $me->header unless
		defined $me->{header} and $me->{header} eq 'no'
		or ( $me->{sections} and $me->{header} ne 'yes' );

	# Print rows ###################

	my $rows;
	while ( my $d = $me->next_row ) {
		$rows .= $me->table_row( $d );
	}

	if ( ! $rows and $me->{hide_if_empty} ) { return '' }

	$html .= $rows;

	$html .= qq(</form>) if $me->{search};
	$html .= '</table>';

	$html .= << "" if $me->{javascript};
		<script type="text/javascript" charset="utf-8">
			$me->{javascript}
		</script>

	return $html;
}

sub header {
	my $me = shift;

	my $html;

	if ( grep $_->{category}, @{$me->{columns}} ) {
		$html = qq(<tr bgcolor="$me->{header_bg}" valign="bottom">);
		my ($prev_col, $i_col, $colspan);
		for my $col ( @{$me->{columns}}, { category => '_END_OF_COLUMNS' } ) {
			$colspan++ if $i_col;
			if ( $i_col++ and $col->{category} ne $prev_col->{category} ) {
				$html .= HTML
					[ th => { colspan => $colspan, class => $col->{class}, style => 'text-align: center; font-weight: bold' },
						[ $col->{nobr} && 'nobr', $prev_col->{category} ]
					];
				$colspan = 0;
			}
			$prev_col = $col;
		}
		$html .= qq(</tr>);
	}

	$html .= qq(<tr bgcolor="$me->{header_bg}" valign="bottom" class="nodrag nodrop">);
	for my $col ( @{$me->{columns}} ) {
		$html .= $me->column_header( $col );
	}
	$html .= qq(</tr>);

	$html .= $me->header_bar if $me->{header_bar};

	return $html;
}

sub column_header {
	my ($me, $col) = @_;

	my $content;

	if ( $col->{sort} ) {
		if ( $col->{sort} eq $me->{sort}->[0] ) {
			my ($other_dir, $dir_link) = $me->{sort_dir} eq 'desc' ? ('asc', '/') : ('desc', '\\');
			$content = [ a => { href => $me->query_string( sort_dir => $other_dir ) }, [ b => $col->{header} ] ];
		} else {
			$content = [ a => { href => $me->query_string( sort => $col->{sort} ) }, $col->{header} ];
		}
	} else {
		$content = $col->{header};
	}

	return HTML [ th => { class => $col->{class}, style => $col->{header_style} || $col->{style} || undef },
		[ $col->{nobr} && 'nobr',
			$content,
			defined $col->{data} && $col->{add} && ( ' (', [[ $me->link( $col, 'Add' ) ]], ')' )
		]
	];
}

sub header_bar {
	my $me = shift;

	return HTML [ tr => { height => 1, valign => 'bottom', class => 'nodrag nodrop' },
		[ td => { height => 1, colspan => $me->{n_cols}, id => 'header_bar' },
			[ table => { cellspacing => 0, cellpadding => 0, height => 1, width => '100%' },
				[ tr => { height => 1, bgcolor => '#000000' }, [ 'td' ] ]
			]
		]
	];
}

sub set_letter { }

sub search_form {
	my $me = shift;

	return HTML
		[ input => { name => 'search', value => $me->{data}->{search} } ],
		ref $me->{search} eq 'HASH' && [ select => { name => 'search_columns' },
			map [ option => $_ ], keys %{$me->{search}}
		];
}

sub set_sort_order { }

sub next_row {
	my $me = shift;

	if ( ref $me->{rows} eq 'ARRAY' ) {
		return shift @{$me->{rows}};
	} elsif ( ref $me->{rows} eq 'HASH' ) {
		my $sorter = sub{ $me->{rows}->{ $_[0] }->{ $me->{sort} || 'name' } };
		return $me->{rows}->{
			shift @{ $me->{_row_hash_ids} ||= [ sort { $sorter->($a) cmp $sorter->($b) } keys %{$me->{rows}} ] }
		};
	}
}

sub table_row {
	my ($me, $d) = @_;

	my $html;

	# Start a new section if section has changed
	if ( $me->{sections} and $me->{_section} ne ( my $section = $me->{sections}->( @$d ) ) ) {
		$html .= qq(<tr valign="top"><td colspan="$me->{n_cols}" class="section_header first_col"><p class="hed">$section</p></td></tr>);
		$html .= $me->header if $me->{section_headers} ne 'no';
		$me->{_section} = $section;
		$me->{_bgcolor} = $me->{dark_bg};
	}

	my $cells;
	for my $col ( @{$me->{columns}} ) {
		$cells .= $me->table_cell( $col, $d );
	}

	# Change row bgcolor
	$me->switch_bgs unless defined $me->{shade_alternate_rows} and $me->{shade_alternate_rows} eq 'no';

	$html .= HTML [ tr =>
		{
			valign => 'top',
			bgcolor => $me->{_bgcolor},
			id => defined $me->{row_id_col} && join '-', 'row', $d->[$me->{row_id_col} ]
		},
		[[ $cells ]]
	];

	return $html;

}

sub switch_bgs {
	my $me = shift;

	$me->{_bgcolor} = ( defined $me->{_bgcolor} and $me->{_bgcolor} eq $me->{light_bg} ) ?
		$me->{dark_bg} : $me->{light_bg};
}

sub table_cell {
	my ($me, $col, $d) = @_;

	$col->{none} ||= $me->{none};

	my $content;

	$content = $me->format( $col, $d );

	return HTML [ td => { style => $col->{style}, class => $col->{class}, align => $col->{align} },
		[ $col->{nobr} && 'nobr',
			[[ $content ]]
		]
	];
}

sub format {
	my ($me, $col, $d) = @_;

	my @data;

	# Upgrade $col->{format} to a subroutine ref
	if ( ! ref $col->{format} ) {
		# the "format" attribute can be either an index into an array or a key into a hash
		if ( $col->{format} =~ /\D/ ) {
			$col->{formatter} ||= sub { my %d = @_; $d{ $col->{format} } };
			@data = ( %$d );
		} else {
			$col->{formatter} ||= sub { $_[ $col->{format} ] };
			@data = ( @$d );
		}
	} elsif ( ref $col->{format} eq 'ARRAY' ) {
		# or it can be a reference to an array mapping the index to a noun and optional plural
		$col->{formatter} ||= sub {
			my ($index, $noun, $plural) = @{$col->{format}};
			my $value = $_[ $index ];
			return 0 if $value == 0;
			$noun .= 's' if $value > 1;
			$noun = $plural if $value > 1 and $plural;
			return "$value $noun";
		};
		@data = ( @$d );
	} elsif ( ref $col->{format} eq 'HASH' ) {
		# or it can be a reference to a hash mapping a predefined format to an index into the data
		if ( ! $col->{formatter} ) {
			my ($format, $index) = each %{$col->{format}};
			$col->{formatter} = {
				date => sub { my @parts = split /\D/, $_[$index]; join '/', grep $_, @parts[1,2,0]; },
				datetime => sub {
					my @parts = split /\D/, $_[$index];
					join ' ', join( '/', grep $_, @parts[1,2,0] ), join( ':', grep $_, @parts[3,4,5] );
				},
			}->{$format} || sub { "UNKNOWN FORMAT NAME $format" };
		}
		@data = ( @$d );
	} else {
		# or it can already be a reference to a subroutine
		$col->{formatter} ||= $col->{format};
		@data = ( @$d );
	}

	my $test = $col->{test};

	my $formatted;

	if (
		! ( ref $test eq 'CODE' and ! $test->(@data) )
		and $formatted = $col->{formatter}->(
			map { $col->{contains_html} ? $_ : HTML $_ } @data
		)
	) {

		if ( $col->{norepeat} and $formatted eq $col->{_prev_value} ) {
			$formatted = '';
		} else {
			$me->switch_bgs if $col->{shade_alternate_vals};
			$col->{_prev_value} = $formatted;
			$formatted = $me->link( $col, $formatted, $d ) if $col->{action};
		}

	} elsif ( $col->{action} and $col->{link_empty} ) {

		$formatted = $me->link( $col, $col->{none}, $d );

	} elsif ( $col->{none_not_dimmed} ) {

		$formatted = $col->{none};

	} else {

		$formatted = qq(<span style="color: gray">$col->{none}</span>);

	}

	return $formatted;

}

sub link {
	my ($me, $col, $formatted, $d) = @_;

	my $action = $col->{action} || $me->{action};  # . ( $col->{action} =~ /\?/ ? '&' : '?' );
	if ( ref $action eq 'CODE' ) { $action = $action->(@$d) }
	return $formatted unless $action;

	my %query_data;

	while ( my ($q_key, $q_format) = each %{$col->{data}} ) {
		# The datum's 'format' attribute can be a reference to a subroutine,
		# in which case we execute it; the word 'format', in which case we use
		# the column's formatted value; or any other value, which we use unaltered.
		next unless $q_format;
		if ( ref $q_format eq 'CODE' ) {
			$query_data{$q_key} = $q_format->(@$d);
		} elsif ( $q_format eq 'format' ) {
			$query_data{$q_key} = $formatted;
		} else {
			$query_data{$q_key} = $q_format;
		}
		$query_data{$q_key} =~ s|(\W)|sprintf("%%%x", ord($1))|eg;
	}

	$me->{first_row_data} ||= \%query_data;

	my $query_string = join '&', ( map { join '=', $_, $query_data{$_} } grep defined $query_data{$_}, keys %query_data ) if %query_data;
	$action .= ( $action =~ /\?/ ? '&' : '?' ) if $query_string;
	return HTML [ a => { href => "$action$query_string" }, [[ $formatted ]] ];
}

sub alphabet {
	my $me = shift;

	my @alphabet;

	my $letter = $me->{data}->{letter} || 'a';
	undef $letter if $me->{data}->{search};
	for my $l ( 'A' .. 'Z' ) {
		push @alphabet,
			lc $l eq lc $letter ?
				"<b>$l</b> " :
				q(<a href=") . $me->query_string( letter => $l, search => undef ) . qq(">$l</a> );
	}
	return join ' ', @alphabet;
}

sub query_string {
	my $me = shift;
	my %replace = @_;

	my %data = %{$me->{data}};
	@data{ keys %replace } = values %replace;
	return ( %data ? '?' : '' ) . join '&', map "$_=$data{$_}", grep $data{$_}, keys %data;
}

=head3 xls

Returns the list as an Excel spreadsheet.

=cut

sub xls {
	my $me = shift;

	require Spreadsheet::WriteExcel;

	open my $fh, '>', \my $str or die "Failed to open filehandle: $!";
	my $workbook = Spreadsheet::WriteExcel->new( $fh );

	my $worksheet = $workbook->addworksheet("Data");
	$worksheet->set_column('A:AZ', 40);

	my $i_col = 0;
	for ( @{$me->{columns}} ) {
		$worksheet->write_string( 0, $i_col++, $_->{header} );
	}
	$worksheet->freeze_panes(1, 0);

	if ( $me->{sort} ) {
		$me->set_sort_order;
	}

	my $i_row = 1;
	while ( my $data = $me->next_row ) {
		$i_col = 0;
		for my $col ( @{$me->{columns}} ) {
			$col->{none_not_dimmed} = 'y';
			delete $col->{action};
			$col->{contains_html} = 'y';
			$worksheet->write_string( $i_row, $i_col++, $me->format( $col, $data ) );
		}
		$i_row++;
	}

	$workbook->close;

	$str;

}

1;

=head1 SEE ALSO

HTML::DataTable::DBI, HTML::FromArrayref

=head1 AUTHORS

Nic Wolff <nic@angel.net>
Jason Barden <jason@angel.net>

=cut
