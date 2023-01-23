#!perl
package # hide from pause
	File::Replace::DualHandle;
use warnings;
use strict;
use Carp;
use warnings::register;
use Scalar::Util qw/blessed/;

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our $VERSION = '0.18';

## no critic (RequireFinalReturn, RequireArgUnpacking)

BEGIN {
	require Tie::Handle::Base;
	our @ISA = qw/ Tie::Handle::Base /;  ## no critic (ProhibitExplicitISA)
}

sub TIEHANDLE {
	@_==2 or croak __PACKAGE__."->TIEHANDLE: bad number of args";
	my ($class,$repl) = @_;
	croak "$class->TIEHANDLE: argument must be a File::Replace object"
		unless blessed($repl) && $repl->isa('File::Replace');
	my $self = $class->SUPER::TIEHANDLE($repl->in_fh);
	$self->{repl} = $repl;
	return $self;
}

sub replace { return shift->{repl} }
sub in_fh   { return shift->{repl}->in_fh }
sub out_fh  { return shift->{repl}->out_fh }

sub OPEN {
	my $self = shift;
	croak "this handle only supports 2- or 3-arg open" unless @_==1||@_==2;
	croak "layers/filename may not contain an open mode (<, >, etc.)"
		if $_[0]=~/^\s*\+?[<>]/;
	my $opts = $self->{repl}->options; # old options to copy over
	$opts->{layers} = @_==2 ? shift : undef;
	my $filename = shift;
	# just let the previous $self->{repl} get destroyed here
	$self->{repl} = File::Replace->new($filename, %$opts);
	$self->set_inner_handle($self->{repl}->in_fh);
	return 1;
}

sub CLOSE {
	my $self = shift;
	return !!$self->{repl}->finish;
}

sub WRITE {
	my $self = shift;
	$self->inner_write($self->{repl}->out_fh, @_);
}

sub BINMODE {
	my $self = shift;
	if (@_)
		{ return binmode($self->{repl}->in_fh,  $_[0])
		      && binmode($self->{repl}->out_fh, $_[0]) }
	else
		{ return binmode($self->{repl}->in_fh)
		      && binmode($self->{repl}->out_fh) }
}
# fileno: "If there is no real file descriptor at the OS level, ... -1 is returned."
# since we have two underlying handles, which one the user wants is ambiguous, so just return -1,
# this way the check defined(fileno($fh)) for whether the file is open still works
sub FILENO { return shift->{repl}->is_open ? -1 : undef }

sub UNTIE {
	my $self = shift;
	warnings::warnif("Please don't untie ".ref($self)." handles");
	$self->{repl} = undef;
	$self->SUPER::UNTIE(@_);
}

sub DESTROY {
	my $self = shift;
	# File::Replace destructor will warn on unclosed file
	$self->{repl} = undef;
	$self->SUPER::DESTROY(@_);
}

1;
__END__

=head1 Synopsis

This class implements the tied handle which is returned by
C<File::Replace::replace>, please see L<File::Replace> for details.

=head1 Author, Copyright, and License

Copyright (c) 2017-2023 Hauke Daempfling (haukex@zero-g.net)
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

