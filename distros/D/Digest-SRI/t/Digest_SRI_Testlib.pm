#!perl
package Digest_SRI_Testlib;
use warnings;
use strict;
use Carp;

=head1 Synopsis

Test support library for the Perl module Digest::SRI.

=head1 Author, Copyright, and License

Copyright (c) 2018 Hauke Daempfling (haukex@zero-g.net)
at the Leibniz Institute of Freshwater Ecology and Inland Fisheries (IGB),
Berlin, Germany, L<http://www.igb-berlin.de/>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see L<http://www.gnu.org/licenses/>.

=cut

BEGIN {
	# "parent" pragma wasn't core until 5.10.1, so just do it ourselves instead of using "base".
	require Exporter;
	our @ISA = qw/ Exporter /;  ## no critic (ProhibitExplicitISA)
}
our @EXPORT = qw/ $AUTHOR_TESTS exception /;  ## no critic (ProhibitAutomaticExportation)

our $AUTHOR_TESTS = ! ! $ENV{DIGEST_SRI_AUTHOR_TESTS};

sub import {  ## no critic (RequireArgUnpacking)
	warnings->import(FATAL=>'all') if $AUTHOR_TESTS;
	require Carp::Always if $AUTHOR_TESTS;
	__PACKAGE__->export_to_level(1, @_);
	return;
}

sub exception (&) {  ## no critic (ProhibitSubroutinePrototypes)
	return eval { shift->(); 1 } ? undef : ($@ || confess "\$@ was false");
}

1;
