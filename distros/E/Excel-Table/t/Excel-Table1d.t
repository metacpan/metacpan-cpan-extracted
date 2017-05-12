#!/usr/bin/perl
#
# Excel-Table1d.t - test harness for Excel::Table object.
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

Excel-Table1d.t - test harness for Excel::Table object.

=head1 SYNOPSIS

perl Excel-Table1d.t
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

#use Logfer qw/ :all /;
use Log::Log4perl qw/ :easy /;
Log::Log4perl->easy_init($ERROR);


# ---- globals ----
my $log = get_logger(__FILE__);
my $c_this = 'Excel::Table';


# ---- sub-routines ----


# ---- tests begin here ----
use Test::More tests => 2;
my $cycle = 0;

BEGIN { use_ok('Excel::Table') };

my $xl = Excel::Table->new;

SKIP: {
	skip "syntax check", 1;	# comment this line for syntax checking
#	pass($xl->extract_hash);
	pass($xl->select_hash);
}

__END__

=head1 DESCRIPTION

Test harness for the B<Excel::Table.pm> class.
Manual syntax checking.

=head1 VERSION

Build V1.022

=head1 AUTHOR

Copyright (C) 2013  B<Tom McMeekin> tmcmeeki@cpan.org

This code is distributed under the same terms as Perl.

=head1 SEE ALSO

L<perl>.

=cut

