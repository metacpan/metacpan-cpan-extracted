#!/usr/bin/perl
#
# Excel-Table4a.t - test harness for Excel::Table object.
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

Excel-Table4a.t - test harness for Excel::Table object.

=head1 SYNOPSIS

perl Excel-Table4a.t
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


# ---- tests begin here ----
use Test::More tests => 59;
my $cycle = 0;
my $xt;

BEGIN { use_ok('Excel::Table') };

for my $s_book (@s_books) {

	my $xt = Excel::Table->new('trim' => 1);

	isa_ok( $xt, $c_this,			"new cycle $cycle");
	isa_ok( $xt->open($s_book), $c_wbook,	"open cycle $cycle");

	my @d_select = $xt->select("title_0_0,title_0_4,title_0_8", $s_sheet);

	is( scalar(@d_select), 10,	'select rowcount');
	is( $d_select[0]->[0], 'row_0_0',	'select first cell');
	is( $d_select[0]->[1], 'row_0_4',	'select second cell');
	is( $d_select[0]->[2], 'row_0_8',	'select third cell');
	is( $d_select[9]->[2], 'lastrow_09_08',	'select last cell');
	is( $d_select[0]->[3], undef,	'select cell oob');

	is( $xt->titles->[0], 'title_0_0',	'select first title');
	is( $xt->titles->[1], 'title_0_4',	'select second title');
	is( $xt->titles->[2], 'title_0_8',	'select third title');
	is( $xt->titles->[3], undef,	'select title oob');

	is( $xt->widths->[0], 13,	'select first widths');
	is( $xt->widths->[1], 16,	'select second widths');
	is( $xt->widths->[2], 13,	'select third widths');
	is( $xt->widths->[3], undef,	'select widths oob');

	my @d_all = $xt->extract($s_sheet);

	is ( scalar(@d_all), scalar(@d_select),	'cross check returned rows');
	is( $d_all[0]->[0], $d_select[0]->[0],	'cross check first cell');
	is( $d_all[0]->[4], $d_select[0]->[1],	'cross check second cell');
	is( $d_all[0]->[8], $d_select[0]->[2],	'cross check third cell');
	is( $d_all[9]->[8], $d_select[9]->[2],	'cross check last cell');

	@d_select = $xt->select("invalid,title_0_4", $s_sheet);

	is ( scalar(@d_select), 10,	'invalid column returned rows');
	is ( scalar(@{$xt->widths}), 1,	'invalid column total widths');
	is ( $xt->widths->[0], 16,	'invalid column widths');
	is ( scalar(@{$xt->titles}), 1,	'invalid column total titles');
	is ( $xt->titles->[0], 'title_0_4',	'invalid column title');

	@d_select = $xt->select("invalid1,invalid2", $s_sheet);

	is ( scalar(@d_select), 0,	'no column returned rows');
	is ( scalar(@{$xt->widths}), 0,	'no column total widths');
	is ( scalar(@{$xt->titles}), 0,	'no column total titles');

	#$log->debug(sprintf '@d_select [%s]', Dumper(\@d_select));

	$xt = ();
	$cycle++;
}

__END__

=head1 DESCRIPTION

Test harness for the B<Excel::Table.pm> class.
Select clause.

=head1 VERSION

Build V1.022

=head1 AUTHOR

Copyright (C) 2012  B<Tom McMeekin> tmcmeeki@cpan.org

This code is distributed under the same terms as Perl.

=head1 SEE ALSO

L<perl>.

=cut

