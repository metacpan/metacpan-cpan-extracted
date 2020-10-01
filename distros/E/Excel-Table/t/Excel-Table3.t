#!/usr/bin/perl
#
# Excel-Table3.t - test harness for Excel::Table object.
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

Excel-Table3.t - test harness for Excel::Table object.

=head1 SYNOPSIS

perl Excel-Table3.t
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

my $g_dbg = ($ENV{'DEBUG'} eq '') ? $ERROR : $TRACE;
Log::Log4perl->easy_init($g_dbg);


# ---- globals ---- 
my $log = get_logger(__FILE__);

my $c_this = 'Excel::Table';
my $c_wbook = 'Spreadsheet::ParseExcel::Workbook';
my @s_books = qw/ Excel-Table0.xls Excel-Table1.xlsx /;
my $s_sheet = 'Sheet1';
my $s_null = "zzz_null_zzz";


# ---- tests begin here ----
use Test::More tests => 49;
my $c_cycle = 0;
my ($xt_dfl, $xt_off, $xt_mod);

BEGIN { use_ok('Excel::Table') };

for my $s_book (@s_books) {

	$xt_off = Excel::Table->new('rowid' => 0, 'trim' => 0, 'force_null' => 0);
	$xt_dfl = Excel::Table->new('rowid' => 0, 'trim' => 1, 'force_null' => 1);
	$xt_mod = Excel::Table->new('rowid' => 0, 'force_null' => 1, 'null' => $s_null);

	my $s_cycle = "cycle $c_cycle ($s_book)";

	isa_ok( $xt_off, $c_this,	"new off $s_cycle");
	isa_ok( $xt_dfl, $c_this,	"new default $s_cycle");
	isa_ok( $xt_mod, $c_this,	"new mod $s_cycle");

	isa_ok( $xt_off->open($s_book), $c_wbook,	"open off $s_cycle");
	isa_ok( $xt_dfl->open($s_book), $c_wbook,	"open default $s_cycle");
	isa_ok( $xt_mod->open($s_book), $c_wbook,	"open mod $s_cycle");

	isnt( $xt_off->null, undef,	"null off value $s_cycle");
	isnt( $xt_dfl->null, undef,	"null default $s_cycle");
	is( $xt_mod->null, $s_null,	"null override $s_cycle");

	# ---- off behaviour ----
	my @data = $xt_off->extract($s_sheet);

	is( $data[7]->[6], "  ltrim",	"trim off 1 $s_cycle");
	is( $data[7]->[7], "rtrim  ",	"trim off 2 $s_cycle");
	is( $data[7]->[8], " trim ",	"trim off 3 $s_cycle");

	SKIP: {
		# seeing inconsistent behaviour between ParseExcel and ParseXLSX
		# for empty cells, i.e. undef versus whitespace

		skip "whitespace on empty cell", 1;
		is( $data[3]->[4], undef,	"null off cell $s_cycle");
	}

	is( $data[5]->[2], "   ",	"trim null off $s_cycle");

	is( $data[4]->[4], "row_4_4",	"unchanged off $s_cycle");

	# ---- on behaviour ----
	@data = $xt_dfl->extract($s_sheet);

	is( $data[7]->[6], "ltrim",	"trim on 1 $s_cycle");
	is( $data[7]->[7], "rtrim",	"trim on 2 $s_cycle");
	is( $data[7]->[8], "trim",	"trim on 3 $s_cycle");

	is( $data[3]->[4], $xt_dfl->null,	"null on $s_cycle");

	is( $data[5]->[2], $xt_dfl->null,	"trim null on $s_cycle");

	is( $data[4]->[4], "row_4_4",	"unchanged on $s_cycle");

	# ---- override behaviour ----
	@data = $xt_mod->extract($s_sheet);

	is( $data[3]->[4], $s_null,	"null override $s_cycle");

	is( $data[5]->[2], "   ",	"no trim override $s_cycle");

	is( $data[4]->[4], "row_4_4",	"unchanged override $s_cycle");

	$c_cycle++;

	$xt_off = $xt_mod = $xt_dfl = ();
}

__END__

=head1 DESCRIPTION

Test harness for the B<Excel::Table.pm> class.
Null and Trim handling.

=head1 VERSION

Build V1.023

=head1 AUTHOR

Copyright (C) 2012  B<Tom McMeekin> tmcmeeki@cpan.org

This code is distributed under the same terms as Perl.

=head1 SEE ALSO

L<perl>.

=cut

