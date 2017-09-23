#!perl
package Tie::Handle::Base;
use warnings;
use strict;
use Carp;
use warnings::register;

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our $VERSION = '0.04';

## no critic (RequireFinalReturn, RequireArgUnpacking)

sub new {
	my $class = shift;
	my $fh = \do{local*HANDLE;*HANDLE};  ## no critic (RequireInitializationForLocalVars)
	tie *$fh, $class, @_;
	return $fh;
}

sub TIEHANDLE {
	my $class = shift;
	my $innerhandle = shift;
	$innerhandle = \do{local*HANDLE;*HANDLE}  ## no critic (RequireInitializationForLocalVars)
		unless defined $innerhandle;
	@_ and warnings::warnif("too many arguments to $class->TIEHANDLE");
	return bless { _innerhandle=>$innerhandle }, $class;
}
sub UNTIE    { shift->{_innerhandle}=undef }
sub DESTROY  { shift->{_innerhandle}=undef }

sub innerhandle { shift->{_innerhandle} }

sub BINMODE  { my $fh=shift->{_innerhandle}; @_ ? binmode($fh,$_[0]) : binmode($fh) }
sub READ     { read($_[0]->{_innerhandle}, $_[1], $_[2], defined $_[3] ? $_[3] : 0 ) }
# The following would work in Perl >=5.16, when CORE:: was added
#sub BINMODE  { &CORE::binmode (shift->{_innerhandle}, @_) }
#sub READ     { &CORE::read    (shift->{_innerhandle}, \shift, @_) }

sub CLOSE    {    close  shift->{_innerhandle} }
sub EOF      {      eof  shift->{_innerhandle} }
sub FILENO   {   fileno  shift->{_innerhandle} }
sub GETC     {     getc  shift->{_innerhandle} }
sub READLINE { readline  shift->{_innerhandle} }
sub SEEK     {     seek  shift->{_innerhandle}, $_[0], $_[1] }
sub TELL     {     tell  shift->{_innerhandle} }

sub OPEN {
	my $self = shift;
	@_ or croak "not enough arguments to open";
	close $self->{_innerhandle} if defined fileno $self->{_innerhandle};
	open $self->{_innerhandle}, shift, @_;  ## no critic (RequireCheckedOpen)
}

# The following work too, but I chose to implement them in terms of
# WRITE so that overriding output behavior is easier.
#sub PRINT    {    print {shift->{_innerhandle}} @_ }
#sub PRINTF   {   printf {shift->{_innerhandle}} shift, @_ }

sub PRINT {
	my $self = shift;
	my $str = join defined $, ? $, : '', @_;
	$str .= $\ if defined $\;
	$self->WRITE($str);
}
sub PRINTF {
	my $self = shift;
	$self->WRITE(sprintf shift, @_);
}
sub WRITE { _WRITE(shift->{_innerhandle}, @_) }

# the docs tell us not to intermix syswrite with other calls like print,
# so we emulate syswrite similarly to Tie::StdHandle, with substr+print
sub _WRITE { # so we can be used more easily by other classes
	# WRITE this, scalar, length, offset
	# substr EXPR, OFFSET, LENGTH
	my $len = defined $_[2] ? $_[2] : length($_[1]);
	my $off = defined $_[3] ? $_[3] : 0;
	my $data = substr($_[1], $off, $len);
	local $\=undef;
	print {$_[0]} $data and return length($data);
	return;
}

1;
__END__

=head1 Name

Tie::Handle::Base - A base class for tied filehandles

=head1 Synopsis

=for comment
REMEMBER to keep these examples in sync with 91_author_pod.t

 package Tie::Handle::Mine;
 use parent 'Tie::Handle::Base';
 sub WRITE {
     my $self = shift;
     print STDERR "Debug: Output '$_[0]'\n";
     return $self->SUPER::WRITE(@_);
 }

Then use your custom tied handle:

 open my $fh, '>', $filename or die $!;
 $fh = Tie::Handle::Mine->new($fh);  # replace orig. handle with tied
 print $fh "Hello, World";           # debug message will be printed
 close $fh;

=head1 Description

A base class for tied filehandles similar to L<Tie::StdHandle|Tie::StdHandle>,
but with a few important differences.

=over

=item *

The C<tied> object is a hashref, so that subclasses have an easier time storing
information in the object hash. The inner handle which is wrapped by this tied
handle should be passed to its C<TIEHANDLE> and is stored with the hash key
C<_innerhandle>. Subclasses should consider all fields with an underscore as
reserved. If no handle is passed to C<TIEHANDLE>, it will create a new
anonymous one as the inner handle.

=item *

It provides a constructor C<new> which will create a new lexical filehandle,
C<tie> it to the class, and return that filehandle. Any arguments to C<new> are
passed through to C<TIEHANDLE>, including the (optional) inner handle as the
first argument. Subclasses may choose to override C<new> and/or C<TIEHANDLE> to
modify this behavior.

=item *

A few limitations that exist in L<Tie::StdHandle|Tie::StdHandle> (at least
versions up to and including 4.4) have been lifted: C<BINMODE> accepts the
C<LAYER> argument, and C<WRITE> will return the length of the string written
(similar caveats in regards to Unicode/UTF-8 data as documented in
L<syswrite|perlfunc/syswrite> apply).

=item *

Although the functions C<PRINT> and C<PRINTF> are implemented in terms of
C<WRITE>, so that you can modify the output behavior by only overriding
C<WRITE>, C<WRITE> itself is implemented in terms of a function C<_WRITE> which
takes a filehandle and emulates C<syswrite> behavior using the core C<print>.
This might be an important detail to you if you are overriding any of these
functions; see the code for details.

=back

This documentation describes version 0.04 of this module.

=head2 Notes

B<See Also:> L<perltie>, L<perlfunc/tie>, L<Tie::Handle>, L<Tie::StdHandle>

The full list of functions that tied handles can/should implement is:

 BINMODE, CLOSE, DESTROY,  EOF,  FILENO, GETC,      OPEN,  PRINT,
 PRINTF,  READ,  READLINE, SEEK, TELL,   TIEHANDLE, UNTIE, WRITE

=begin comment

 perl -wMstrict -le 'for(qw/ binmode read sysread close eof fileno getc print
   printf readline seek tell open syswrite /) { my $p=prototype("CORE::$_");
   printf "%-9s %s\n", $_, defined$p?"($p)":"undef" }'

 TIEHANDLE classname, LIST
 UNTIE this
 DESTROY this
 BINMODE this                                  binmode   (*;$)
 READ this, scalar, length, offset             (sys)read (*\$$;$)
 CLOSE this                                    close     (;*)
 EOF this                                      eof       (;*)
 FILENO this                                   fileno    (*)
 GETC this                                     getc      (;*)
 READLINE this                                 readline  (;*)
 SEEK this, offset, whence                     seek      (*$$)
 TELL this                                     tell      (;*)
 OPEN this, filename / OPEN this, mode, LIST   open      (*;$@)
 PRINT this, LIST                              print     undef
 PRINTF this, format, LIST                     printf    undef
 WRITE this, scalar, length, offset            syswrite  (*$;$$)

=end comment

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

