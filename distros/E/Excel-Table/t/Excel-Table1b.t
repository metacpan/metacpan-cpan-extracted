#!/usr/bin/perl
#
# Excel-Table1b.t - test harness for Excel::Table object.
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

Excel-Table1b.t - test harness for Excel::Table object

=head1 SYNOPSIS

perl Excel-Table1b.t
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
my $s_sheet = 'Sheet1';
my $s_garbage = '::::';


# ---- tests begin here ----
use Test::More tests => 77;
my $cycle = 0;

BEGIN { use_ok('Excel::Table') };

for my $s_book (@s_books) {

	my $xt1 = Excel::Table->new(rowid => 0);
	isa_ok( $xt1, $c_this,		"new rowid off");
	isa_ok( $xt1->open($s_book), $c_wbook,	"open off $cycle");

	my $xt2 = Excel::Table->new(rowid => 1);
	isa_ok( $xt2, $c_this,		"new rowid on");
	isa_ok( $xt2->open($s_book), $c_wbook,	"open on $cycle");

	# ---- extraction default ----
	my @data = $xt1->extract($s_sheet);
	my $c_exp = 10;
	my $l_exp = 13;
	my $t_exp = "title_0_9";

	$log->debug(sprintf '$xt1->titles [%s]', Dumper($xt1->titles));
	$log->debug(sprintf '$xt1->widths [%s]', Dumper($xt1->widths));

	is( scalar(@data), 10,		"rows fetched cycle $cycle");

	is( $xt1->columns, 10,		"columns");
	is( $xt1->rows, 10,		"rows recorded");

	is( $data[0]->[0], 'row_0_0',		"value norowid 1");
	is( $data[0]->[1], 'row_0_1',		"value norowid 2");
	is( $data[1]->[0], 'row_1_0',		"value norowid 3");

	is( $xt1->sheet_name, $s_sheet,		"sheet_name");
	is( $xt1->title_row, 0,			"title_row");

$log->debug("columns [%s]", Dumper($xt1->columns));

	is( $xt1->titles->[9], $t_exp,	"titles norowid");

	# ---- column title identification ----

	is( $xt1->colid2title(9), $t_exp,		"colid2title");
	is( $xt1->colid2title(100), undef,		"colid2title invalid");

	is( $xt1->title2colid($t_exp), 9,		"title2colid");
	is( $xt1->title2colid('invalid'), undef,	"title2colid invalid");

	# ---- extraction rowid ----
	@data = $xt2->extract($s_sheet);

	is( $data[0]->[0], '000000001',		"value rowid 0");
	is( $data[0]->[1], 'row_0_0',		"value rowid 1");
	is( $data[1]->[0], '000000002',		"value rowid 2");
	is( $data[1]->[1], 'row_1_0',		"value rowid 3");

	is( $xt1->titles->[0], "title_0_0",	"titles off rowid");
	is( $xt2->titles->[0], "rowid",		"titles on rowid");

	is( $xt1->titles->[1], "title_0_1",	"titles off 1 rowid");
	is( $xt2->titles->[1], "title_0_0",	"titles on 1 rowid");

	# ---- column widths ----
	$log->debug(sprintf '@data [%s]', Dumper(\@data));

	is( $xt1->widths->[9], $l_exp,	"widths cycle $cycle");

	is( $xt1->widths->[1], 13,	"widths off 1");
	is( $xt1->widths->[2], 14,	"widths off 2");
	is( $xt1->widths->[3], 15,	"widths off 3");
	is( $xt1->widths->[4], 16,	"widths off 4");
	is( $xt1->widths->[5], 13,	"widths off 5");
	is( $xt1->widths->[10], undef,	"widths off 6");

	is( $xt2->widths->[2], 13,	"widths on 1");
	is( $xt2->widths->[3], 14,	"widths on 2");
	is( $xt2->widths->[4], 15,	"widths on 3");
	is( $xt2->widths->[5], 16,	"widths on 4");
	is( $xt2->widths->[6], 13,	"widths on 5");
	is( $xt2->widths->[10], 13,	"widths on 6");

	$xt1 = ();
	$cycle++;
}

__END__

=head1 DESCRIPTION

Test harness for the B<Excel::Table.pm> class.
Sheet extraction, intension, and statistics.

=head1 VERSION

Build V1.022

=head1 AUTHOR

Copyright (C) 2012  B<Tom McMeekin> tmcmeeki@cpan.org

This code is distributed under the same terms as Perl.

=head1 SEE ALSO

L<perl>.

=cut

