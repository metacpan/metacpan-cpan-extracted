#!/usr/bin/perl
#
# Excel-Table5.t - test harness for Excel::Table object.
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

Excel-Table5.t - test harness for Excel::Table object.

=head1 SYNOPSIS

perl Excel-Table5.t
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

# ---- logging ---- 
use Log::Log4perl qw/ :easy /;
Log::Log4perl->easy_init($ERROR);

my $log = get_logger(__FILE__);

# ---- globals ---- 
my $c_this = 'Excel::Table';
my $c_wbook = 'Spreadsheet::ParseExcel::Workbook';
my @s_books = qw/ Excel-Table0.xls Excel-Table1.xlsx /;
my $s_sheet = 'Sheet1';


# ---- tests begin here ----
use Test::More tests => 167;
my $cycle = 0;
my $xt;

BEGIN { use_ok('Excel::Table') };

for my $s_book (@s_books) {

	my $xt = Excel::Table->new('trim' => 1);

	isa_ok( $xt, $c_this,			"new cycle $cycle");
	isa_ok( $xt->open($s_book), $c_wbook,	"open cycle $cycle");

	my @d_hash1 = $xt->extract_hash($s_sheet);

	is( scalar(@d_hash1), 10,	"x hash rowcount");

	ok( exists($d_hash1[0]->{'title_0_0'}),	"x hash first title");
	ok( exists($d_hash1[0]->{'title_0_9'}),	"x hash last title");
	ok( exists($d_hash1[0]->{'dup_title0'}),	"x hash dup title");

	is( $d_hash1[0]->{'title_0_1'}, 'row_0_1',	"x value check a");
	is( $d_hash1[0]->{'dup_title'}, 'row_0_5',	"x value check b");
	is( $d_hash1[0]->{'dup_title0'}, 'row_0_6',	"x value check c");
	is( $d_hash1[1]->{'dup_title0'}, 'row_1_6',	"x value check d");
	is( $d_hash1[9]->{'dup_title0'}, 'lastrow_09_06',	"x value check e");

	$log->debug(sprintf '@d_hash1 [%s]', Dumper(\@d_hash1));

	my @d_hash2 = $xt->select_hash("title_0_2,dup_title,title_0_7", $s_sheet);

	is( scalar(@d_hash2), 10,	"s hash rowcount");

	ok( exists($d_hash2[0]->{'title_0_2'}),	"s hash first title");
	ok( exists($d_hash2[0]->{'dup_title'}),	"s hash second title");

	# cannot retrieve a duplicate title via a select; only one match
	ok( ! exists($d_hash2[0]->{'dup_title0'}),	"s no dup title");

	is( $d_hash2[0]->{'title_0_2'}, 'row_0_2',	"s value check a");
	is( $d_hash2[0]->{'dup_title'}, 'row_0_5',	"s value check b");
	is( $d_hash2[1]->{'title_0_2'}, 'row_1_2',	"s value check c");
	is( $d_hash2[1]->{'dup_title'}, 'row_1_5',	"s value check d");
	is( $d_hash2[9]->{'title_0_2'}, 'lastrow_09_02a',	"s value check e");
	is( $d_hash2[9]->{'title_0_7'}, 'lastrow_09_07',	"s value check f");
	is( $d_hash2[9]->{'dup_title'}, 'lastrow_09_05',	"s value check g");

	$log->debug(sprintf '@d_hash2 [%s]', Dumper(\@d_hash2));

	is( @d_hash1, @d_hash2,		"matching rows");

	for (my $sub = 0; $sub < @d_hash1; $sub++) {
		is( $d_hash1[$sub]->{'title_0_2'}, $d_hash2[$sub]->{'title_0_2'}, 	"matching values a $sub");
		is( $d_hash1[$sub]->{'title_0_7'}, $d_hash2[$sub]->{'title_0_7'}, 	"matching values b $sub");

		is( scalar( keys( %{ $d_hash1[$sub] })), 10, 	"key count a $sub");
		is( scalar( values( %{ $d_hash1[$sub] })), 10, "value count a $sub");
		is( scalar( keys( %{ $d_hash2[$sub] })), 3, 	"key count b $sub");
		is( scalar( values( %{ $d_hash2[$sub] })), 3, 	"value count b $sub");
	}

	$xt = ();
	$cycle++;
}

__END__

=head1 DESCRIPTION

Test harness for the B<Excel::Table.pm> class.
Hash extraction and select.

=head1 VERSION

Build V1.022

=head1 AUTHOR

Copyright (C) 2012  B<Tom McMeekin> tmcmeeki@cpan.org

This code is distributed under the same terms as Perl.

=head1 SEE ALSO

L<perl>.

=cut

