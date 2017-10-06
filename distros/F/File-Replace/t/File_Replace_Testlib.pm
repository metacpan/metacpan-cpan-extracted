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
our @EXPORT = qw/ $AUTHOR_TESTS $TEMPDIR newtempfn slurp spew warns exception /;  ## no critic (ProhibitAutomaticExportation)

our $AUTHOR_TESTS = ! ! $ENV{FILE_REPLACE_AUTHOR_TESTS};

sub import {  ## no critic (RequireArgUnpacking)
	warnings->import(FATAL=>'all') if $AUTHOR_TESTS;
	require Carp::Always if $AUTHOR_TESTS;
	__PACKAGE__->export_to_level(1, @_);
	$File::Replace::DISABLE_CHMOD = 1 unless chmod(oct('640'), newtempfn(""));
	return;
}

use File::Temp qw/tempdir tempfile/;
# always returns a new temporary filename
# newtempfn() - return a nonexistent filename (small chance for a race condition)
# newtempfn("content") - writes that content to the file (file will exist)
# newtempfn("content","layers") - does binmode with those layers then writes the content
our $TEMPDIR = tempdir("FileReplaceTests_XXXXXXXXXX", TMPDIR=>1, CLEANUP=>1);
sub newtempfn {
	my ($fh,$fn) = tempfile(DIR=>$TEMPDIR,UNLINK=>1);
	if (@_) {
		my $content = shift;
		if (@_) {
			binmode $fh, shift or croak "binmode $fn: $!";
			@_ and carp "too many args to newtempfn";
		}
		print $fh $content or croak "print $fn: $!";
		close $fh or croak "close $fn: $!";
	}
	else {
		close $fh or croak "close $fn: $!";
		unlink $fn or croak "unlink $fn: $!";
	}
	return $fn;
}

sub slurp {
	my ($fn,$layers) = @_;
	$layers = '' unless defined $layers;
	open my $fh, "<$layers", $fn or croak "open $fn: $!";
	my $x = do { local $/=undef; <$fh> };
	close $fh or croak "close $fn: $!";
	return $x;
}

sub spew {
	my ($fn,$content,$layers) = @_;
	$layers = '' unless defined $layers;
	open my $fh, ">$layers", $fn or croak "open $fn: $!";
	print $fh $content or croak "print $fn: $!";
	close $fh or croak "close $fn: $!";
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

## no critic (ProhibitMultiplePackages, RequireCarping)

{
	package Tie::Handle::Unclosable;
	require Tie::Handle::Base;
	our @ISA = qw/ Tie::Handle::Base /;  ## no critic (ProhibitExplicitISA)
	# just force close to return a false value, since
	# apparently we can't mock close via "local *CORE::close = sub ...",
	# (and we didn't have CORE:: before 5.16 anyway)
	sub CLOSE { my $self=shift; $self->SUPER::CLOSE(@_); return }
	sub install {
		my ($class,$repl,$which) = @_;
		die $which unless $which eq 'ifh' || $which eq 'ofh';
		if (ref $repl eq 'GLOB' && tied(*$repl)) {
			   if (ref tied(*$repl) eq 'File::Replace::SingleHandle')
				{ tied(*$repl)->set_inner_handle( $class->new( tied(*$repl)->innerhandle ) ) }
			elsif (ref tied(*$repl) eq 'File::Replace::DualHandle' && $which eq 'ifh')
				{ tied(*$repl)->set_inner_handle( $class->new( tied(*$repl)->innerhandle ) ) }
			$repl = tied(*$repl)->replace;
		}
		$repl->isa('File::Replace') or die ref $repl;
		$repl->{$which} = $class->new($repl->{$which});
		return $repl;
	}
}
{
	package Tie::Handle::Unprintable;
	require Tie::Handle::Base;
	our @ISA = qw/ Tie::Handle::Base /;  ## no critic (ProhibitExplicitISA)
	# we can't mock CORE::print, but we can use a tied handle to cause it to return false
	sub WRITE { return undef }  ## no critic (ProhibitExplicitReturnUndef)
}
{
	package Tie::Handle::FakeFileno;
	require Tie::Handle::Base;
	our @ISA = qw/ Tie::Handle::Base /;  ## no critic (ProhibitExplicitISA)
	sub FILENO { return -1 }
	sub CLOSE { return 1 }
}
{
	package Tie::Handle::MockBinmode;
	require Tie::Handle::Base;
	our @ISA = qw/ Tie::Handle::Base /;  ## no critic (ProhibitExplicitISA)
	# we can't mock CORE::binmode in Perl <5.16, so use a tied handle instead
	sub new {  ## no critic (RequireArgUnpacking)
		my $class = shift;
		my $fh = $class->SUPER::new(shift);
		tied(*$fh)->{mocks} = [@_];
		return $fh;
	}
	sub BINMODE {
		my $self = shift;
		die "no more mocks left" unless @{ $self->{mocks} };
		return shift @{ $self->{mocks} };
	}
	sub endmock {
		my $self = shift;
		return if @{ $self->{mocks} };
		return 1;
	}
}

1;
