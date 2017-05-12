#!/usr/bin/perl
#
# Excel-Table2.t - test harness for Excel::Table object.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2 of the License,
# or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
=head1 NAME

Excel-Table2.t - test harness for Excel::Table object.

=head1 SYNOPSIS

perl Excel-Table2.t
[-h, --help]
[-m, --manual]

=head1 OPTIONS

=over 8

=item B<--help>

Prints a brief help message and exits.

=item B<--manual>

Prints the manual page and exits.

=back

=cut

use strict;

use Data::Dumper;
use Log::Log4perl qw/ :easy /;
Log::Log4perl->easy_init($ERROR);


# ---- globals ----
my $log = get_logger(__FILE__);

my $c_this = 'Excel::Table';
my $c_wbook = 'Spreadsheet::ParseExcel::Workbook';
my @s_books = qw/ Excel-Table0.xls Excel-Table1.xlsx /;


# ---- tests here ----
use Test::More tests => 55;

BEGIN { use_ok('Excel::Table') };

my $xt;
my $cycle = 0;

for my $s_book (@s_books) {

	$xt = Excel::Table->new();

	isa_ok( $xt, $c_this,			"new cycle $cycle");
	isa_ok( $xt->open($s_book), $c_wbook,	"open cycle $cycle");

	# --- first sheet ---
	my $s_sheet = 'Sheet1';
	my @data = $xt->extract($s_sheet);

	is ($xt->sheet_name, $s_sheet,	"sheet_name $s_sheet");
	is ($xt->rows, 10,		"rows $s_sheet");
	is ($xt->columns, 10,		"columns $s_sheet");
	is ($xt->title_row, 0,		"title_row $s_sheet");

	is ($xt->titles->[0], 'title_0_0',	"titles $s_sheet");

	is( $data[0]->[0], 'row_0_0', 		"first row $s_sheet");
	is( $data[9]->[9], 'lastrow_09_09', 	"last row $s_sheet");

	# --- second sheet ---
	$s_sheet = 'Sheet2';
	@data = $xt->extract($s_sheet);

	is ($xt->sheet_name, $s_sheet,	"sheet_name $s_sheet");
	is ($xt->rows, 4,		"rows property $s_sheet");
	is (scalar(@data), 3,		"rows retrieved $s_sheet");
	is ($xt->columns, 5,		"columns $s_sheet");
	is ($xt->title_row, 1,		"title_row $s_sheet");

	is ($xt->titles->[0], 'title_1_1',	"titles $s_sheet");

	is( $data[0]->[1], 'row_2_2', 	"first row $s_sheet");
	is( $data[2]->[3], 'row_4_4', 	"last row $s_sheet");
	is( $data[3]->[0], undef, 	"exceed row $s_sheet");

	# --- third sheet ---
	$s_sheet = 'Sheet3';
	@data = $xt->extract($s_sheet);

	is ($xt->sheet_name, $s_sheet,	"sheet_name $s_sheet");
	is ($xt->rows, 5,		"rows property $s_sheet");
	is (scalar(@data), 3,		"rows retrieved $s_sheet");
	is ($xt->columns, 6,		"columns $s_sheet");
	is ($xt->title_row, 2,		"title_row $s_sheet");

	is ($xt->titles->[0], 'title_2_2',	"titles $s_sheet");

	is( $data[0]->[0], 'row_3_2', 	"first row $s_sheet");
	is( $data[2]->[3], 'row_5_5', 	"last row $s_sheet");
	is( $data[3]->[0], undef, 	"exceed row $s_sheet");

	$xt = ();
	$cycle++;
}


__END__

=head1 DESCRIPTION

Test harness for the B<Excel::Table.pm> class.
Multi-sheet handling.

=head1 VERSION

Build V1.022

=head1 AUTHOR

Copyright (C) 2012  B<Tom McMeekin> tmcmeeki@cpan.org

This code is distributed under the same terms as Perl.

=head1 SEE ALSO

L<perl>.

=cut

