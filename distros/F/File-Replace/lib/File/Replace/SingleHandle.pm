#!perl
package # hide from pause
	File::Replace::SingleHandle;
use warnings;
use strict;
use Carp;
use warnings::register;
use Scalar::Util qw/blessed weaken/;

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

## no critic (RequireFinalReturn, RequireArgUnpacking)

BEGIN {
	require Tie::Handle::Base;
	our @ISA = qw/ Tie::Handle::Base /;  ## no critic (ProhibitExplicitISA)
}

sub TIEHANDLE {
	@_==3 or croak __PACKAGE__."->TIEHANDLE: bad number of args";
	my ($class,$repl,$mode) = @_;
	croak "$class->TIEHANDLE: argument must be a File::Replace object"
		unless blessed($repl) && $repl->isa('File::Replace');
	my ($innerhandle,$other);
	if ($mode eq 'in') {
		$innerhandle = $repl->in_fh;
		$other   = $repl->out_fh; }
	elsif ($mode eq 'out') {
		$innerhandle = $repl->out_fh;
		$other   = $repl->in_fh; }
	elsif ($mode eq 'onlyout') {
		$innerhandle = $repl->out_fh; }
	else { croak "bad mode" }
	my $self = $class->SUPER::TIEHANDLE($innerhandle);
	$self->{repl}  = $repl;
	$self->{other} = $other;
	weaken( $self->{other} );
	return $self;
}

sub replace { return shift->{repl} }
sub in_fh   { return shift->{repl}->in_fh }
sub out_fh  { return shift->{repl}->out_fh }

sub OPEN { croak "Can't reopen a ".ref($_[0])." handle" }

sub CLOSE {
	my $self = shift;
	if ( defined($self->{other}) && defined(fileno($self->{other})) ) {
		# the other file is still open, so just close this one
		my $rv = $self->SUPER::CLOSE()
			or croak "couldn't close handle: $!";
		return $rv;
	}
	else { # the other file is closed, trigger the replacement now
		return !!$self->{repl}->finish }
}

sub UNTIE {
	my $self = shift;
	warnings::warnif("Please don't untie ".ref($self)." handles");
	$self->{other} = undef;
	$self->{repl}  = undef;
	$self->SUPER::UNTIE(@_);
}

sub DESTROY {
	my $self = shift;
	# File::Replace destructor will warn on unclosed file
	$self->{other} = undef;
	$self->{repl}  = undef;
	$self->SUPER::DESTROY(@_);
}

1;
__END__

=head1 Synopsis

This class implements the tied handles which are returned by
C<File::Replace::replace2>, please see L<File::Replace> for details.

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

