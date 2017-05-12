#!/usr/bin/perl
#
# Excel-Table1a.t - test harness for Excel::Table object.
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

Excel-Table1a.t - test harness for Excel::Table object.

=head1 SYNOPSIS

perl Excel-Table1a.t
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
use File::Spec;

Log::Log4perl->easy_init($ERROR);


# ---- globals ----
my $log = get_logger(__FILE__);
my $c_this = 'Excel::Table';
my $c_wbook = 'Spreadsheet::ParseExcel::Workbook';
my @s_books = qw/ Excel-Table0.xls Excel-Table1.xlsx /;
my @s_vers = qw/ xl2003 xl2007 /;
my $s_sheet = 'Sheet1';
my $s_garbage = '::::';


# ---- tests begin here ----
use Test::More tests => 65;
my $cycle = 0;

BEGIN { use_ok('Excel::Table') };

my $xt1 = Excel::Table->new();
isa_ok( $xt1, $c_this,		"new no parm");

my $dummy1 = Excel::Table->new('trim' => 1);
isa_ok( $dummy1, $c_this,	"new one parm");

my $dummy2 = Excel::Table->new('force_null' => 1, 'trim' => 1);
isa_ok( $dummy2, $c_this,	"new two parm");
	
$dummy1 = $dummy2 = ();

ok( !defined($xt1->open_re($s_garbage)),     "open_re no match");

for my $s_book (@s_books) {

	# ---- opens ----

	my $s_prefix = 'Excel-Table' . $cycle;
	$log->debug("s_prefix [$s_prefix]");

	my $book = $xt1->open_re($s_prefix);

	isa_ok( $book, $c_wbook,		"openre match $cycle");
	is( $xt1->regexp, $s_prefix,		"regexp $cycle");

	isa_ok( $xt1->open($s_book), $c_wbook,	"open $cycle");
	is( $xt1->pathname, File::Spec->catfile($xt1->dir, $s_book),		"pathname $cycle");

	# ---- simple attributes ----

	for my $opint (qw/ force_null rowid title_row trim /) {

		isnt($xt1->$opint, -1,		"default $opint $cycle");
		my $default = $xt1->$opint;
		my $assign = !$default;

		is($xt1->$opint($assign), $assign, "assign $opint $cycle");
		isnt($xt1->$opint, $default,	"check $opint $cycle");
		$log->debug(sprintf "opint [$opint]=%d", $xt1->$opint);
		ok($xt1->$opint >= 0,		"integer $opint $cycle");

	}
	for my $opstr (qw/ dir null /) {

		isnt($xt1->$opstr, $s_garbage,	"default $opstr $cycle");
		my $default = $xt1->$opstr;

		is($xt1->$opstr($s_garbage), $s_garbage, "assign $opstr $cycle");
		isnt($xt1->$opstr, $default,	"check $opstr $cycle");

		$xt1->$opstr($default);
	}

	is( $xt1->_xl_vers, $s_vers[$cycle],	"version $cycle");

	ok( scalar($xt1->list_workbooks) >= 2,	"list_workbooks $cycle");
	ok( scalar($book->worksheets) == 3,	"worksheets $cycle");
	ok( $xt1->pathname =~ $xt1->regexp,		"pathname $cycle");

	$cycle++;
}

__END__

=head1 DESCRIPTION

Test harness for the B<Excel::Table.pm> class.
Basic attributes, opens, and listing functions.

=head1 VERSION

Build V1.022

=head1 AUTHOR

Copyright (C) 2012  B<Tom McMeekin> tmcmeeki@cpan.org

This code is distributed under the same terms as Perl.

=head1 SEE ALSO

L<perl>.

=cut

