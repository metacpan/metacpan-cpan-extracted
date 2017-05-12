#!/usr/bin/perl
#
# Excel-Table1c.t - test harness for Excel::Table object.
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

Excel-Table1c.t - test harness for Excel::Table object.

=head1 SYNOPSIS

perl Excel-Table1c.t
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

use Cwd;
use Data::Dumper;
use File::Spec;

#use Logfer qw/ :all /;
use Log::Log4perl qw/ :easy /;
Log::Log4perl->easy_init($ERROR);


# ---- globals ----
my $log = get_logger(__FILE__);
my $c_this = 'Excel::Table';
my @s_books = qw/ Excel-Table0.xls Excel-Table1.xlsx /;
my $g_cwd = cwd;
my $c_wb = 'Spreadsheet::ParseExcel::Workbook';


# ---- sub-routines ----
sub a2ars {
#	return an array reference of sorted strings
	my @out = sort(@_);

	$log->debug(sprintf 'in [%s] out [%s]', Dumper(\@_), Dumper(\@out));

	return \@out;
}


# ---- tests begin here ----
use Test::More tests => 17;
my $cycle = 0;
my $s_re = 'Table\d';
$log->debug("s_re [$s_re]");

BEGIN { use_ok('Excel::Table') };

for my $s_book (@s_books) {

	my $xt1 = Excel::Table->new();
	isa_ok( $xt1, $c_this,		"new cycle $cycle");

	# check current directory, using default directory

	is_deeply( a2ars($xt1->list_workbooks), a2ars(@s_books), "list_workbooks default");
	my $book = $xt1->open_re($s_re);
	isa_ok( $xt1->open($s_book), $c_wb,	"open");

	my $dn_dfl = $xt1->dir;
	ok( $g_cwd ne $xt1->dir,	"dir before");
	is( $xt1->dir($g_cwd), $g_cwd,	"dir set");
	ok( $g_cwd eq $xt1->dir,	"dir after");

	# check override directory (which is the absolute path)

	is_deeply( a2ars($xt1->list_workbooks), a2ars(@s_books), "list_workbooks override");

	$book = $xt1->open_re($s_re);
	isa_ok( $xt1->open($s_book), $c_wb,	"open");
	
	$cycle++;
}

__END__

=head1 DESCRIPTION

Test harness for the B<Excel::Table.pm> class.
More opening: open_re with list_workbooks.

=head1 VERSION

Build V1.022

=head1 AUTHOR

Copyright (C) 2013  B<Tom McMeekin> tmcmeeki@cpan.org

This code is distributed under the same terms as Perl.

=head1 SEE ALSO

L<perl>.

=cut

