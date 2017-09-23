#!perl
package File_Replace_Testlib;
use warnings;
use strict;
use Carp;

=head1 Synopsis

Test support library for the Perl module File::Replace.

=head1 Author, Copyright, and License

Copyright (c) 2017 Hauke Daempfling (haukex@zero-g.net)
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

use Test::Fatal 'exception';

BEGIN {
	# "parent" pragma wasn't core until 5.10.1, so just do it ourselves
	# instead of using "base".
	require Exporter;
	our @ISA = qw/ Exporter /;  ## no critic (ProhibitExplicitISA)
}
our @EXPORT = qw/ $AUTHOR_TESTS newtempfn slurp spew warns exception /;  ## no critic (ProhibitAutomaticExportation)

our $AUTHOR_TESTS = ! ! $ENV{FILE_REPLACE_AUTHOR_TESTS};

sub import {  ## no critic (RequireArgUnpacking)
	warnings->import(FATAL=>'all') if $AUTHOR_TESTS;
	require Carp::Always if $AUTHOR_TESTS;
	__PACKAGE__->export_to_level(1, @_);
	$File::Replace::DISABLE_CHMOD = 1 unless chmod(oct('640'), spew(newtempfn(),""));
	return;
}

use File::Temp qw/tempfile/;
my @tempfiles;
sub newtempfn {
	my (undef,$fn) = tempfile(OPEN=>0);
	# File::Temp doesn't support (OPEN=>0,UNLINK=>1), so do it ourselves
	push @tempfiles, $fn;
	return $fn;
}
END { unlink @tempfiles }

sub slurp {
	my ($fn,$layers) = @_;
	$layers = '' unless defined $layers;
	open my $fh, "<$layers", $fn or croak $!;
	my $x = do { local $/=undef; <$fh> };
	close $fh;
	return $x;
}

sub spew {
	my ($fn,$content,$layers) = @_;
	$layers = '' unless defined $layers;
	open my $fh, ">$layers", $fn or croak $!;
	print $fh $content;
	close $fh;
	return $fn;
}

sub warns (&) {  ## no critic (ProhibitSubroutinePrototypes)
	my $sub = shift;
	my @warns;
	#TODO Later: can we (lexically) disable warning fatality in this block?
	{ local $SIG{__WARN__} = sub { push @warns, shift };
		$sub->() }
	return wantarray ? @warns : scalar @warns;
}

1;
