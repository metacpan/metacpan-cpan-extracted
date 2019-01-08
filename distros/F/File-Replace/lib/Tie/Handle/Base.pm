#!perl
package Tie::Handle::Base;
use warnings;
use strict;
use Carp;
use warnings::register;
use Scalar::Util qw/blessed/;

# For AUTHOR, COPYRIGHT, AND LICENSE see the bottom of this file

our $VERSION = '0.12';

## no critic (RequireFinalReturn, RequireArgUnpacking)

our @IO_METHODS = qw/ BINMODE CLOSE EOF FILENO GETC OPEN PRINT PRINTF
	READ READLINE SEEK TELL WRITE /;
our @ALL_METHODS = (qw/ TIEHANDLE UNTIE DESTROY /, @IO_METHODS);

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
	return bless { __innerhandle=>$innerhandle }, $class;
}
sub UNTIE    { delete shift->{__innerhandle}; return }
sub DESTROY  { delete shift->{__innerhandle}; return }

sub innerhandle { shift->{__innerhandle} }
sub set_inner_handle { $_[0]->{__innerhandle} = $_[1] }

sub BINMODE  {
	my $fh = shift->{__innerhandle};
	# note binmode is prototyped, so the conditional is needed here:
	if (@_) { return binmode($fh,$_[0]) }
	else    { return binmode($fh)       }
}
sub READ     { read($_[0]->{__innerhandle}, $_[1], $_[2], defined $_[3] ? $_[3] : 0 ) }
# The following would work in Perl >=5.16, when CORE:: was added
#sub BINMODE  { &CORE::binmode (shift->{__innerhandle}, @_) }
#sub READ     { &CORE::read    (shift->{__innerhandle}, \shift, @_) }

sub CLOSE    {    close  shift->{__innerhandle} }
sub EOF      {      eof  shift->{__innerhandle} }
sub FILENO   {   fileno  shift->{__innerhandle} }
sub GETC     {     getc  shift->{__innerhandle} }
sub READLINE { readline  shift->{__innerhandle} }
sub SEEK     {     seek  shift->{__innerhandle}, $_[0], $_[1] }
sub TELL     {     tell  shift->{__innerhandle} }

sub OPEN {
	my $self = shift;
	$self->CLOSE if defined $self->FILENO;
	# note open is prototyped, so the conditional is needed here:
	if (@_) { return open $self->{__innerhandle}, shift, @_ }
	else    { return open $self->{__innerhandle} }
}

# The following work too, but I chose to implement them in terms of
# WRITE so that overriding output behavior is easier.
#sub PRINT    {    print {shift->{__innerhandle}} @_ }
#sub PRINTF   {   printf {shift->{__innerhandle}} shift, @_ }

# tests show that print, printf, and syswrite always return undef on fail,
# even in list context, so we'll do an explicit "return undef"

sub PRINT {
	my $self = shift;
	my $str = join defined $, ? $, : '', @_;
	$str .= $\ if defined $\;
	return defined( $self->WRITE($str) ) ? 1 : undef;
}
sub PRINTF {
	my $self = shift;
	return defined( $self->WRITE(sprintf shift, @_) ) ? 1 : undef;
}
sub WRITE { inner_write(shift->{__innerhandle}, @_) }

# the docs tell us not to intermix syswrite with other calls like print,
# and since our tied sysread uses read internally, we should avoid the
# sysread/-write functions in general,
# so we emulate syswrite similarly to Tie::StdHandle, with substr+print
sub inner_write { # can be called as function or method
	shift if blessed($_[0]) && $_[0]->isa(__PACKAGE__);
	# WRITE this, scalar, length, offset
	# substr EXPR, OFFSET, LENGTH
	my $len = defined $_[2] ? $_[2] : length($_[1]);
	my $off = defined $_[3] ? $_[3] : 0;
	my $data = substr($_[1], $off, $len);
	local $\=undef;
	print {$_[0]} $data and return length($data);
	return undef;  ## no critic (ProhibitExplicitReturnUndef)
}

sub open_parse {
	croak "not enough arguments to open_parse" unless @_;
	my $fnwm = shift;
	carp "too many arguments to open_parse" if @_>1;
	return ($fnwm, shift) if @_;  # passthru
	if ( $fnwm =~ s{^\s* ( \| | \+? (?: < | >>? ) (?:&=?)? ) | ( \| ) \s*$}{}x ) {
		my ($x,$y) = ($1,$2);  $fnwm =~ s/^\s+|\s+$//g;
		if ( defined $y )      { return ('-|', $fnwm) }
		elsif ( $x eq '|' )    { return ('|-', $fnwm) }
		else                   { return ($x,   $fnwm) }
	} else
		{ $fnwm=~s/^\s+|\s+$//g; return ('<',  $fnwm) }
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

C<Tie::Handle::Base> is a base class for tied filehandles. It is similar to
L<Tie::StdHandle|Tie::StdHandle>, but provides a few more features, and is
compatible down to Perl 5.8.1. It tries to be as transparent as possible (one
limitation is that C<sysread> and C<syswrite> are only emulated, as described
in L</READ>).

A few limitations that exist in L<Tie::StdHandle|Tie::StdHandle> (at least
versions up to and including 4.4) have been lifted: C<BINMODE> accepts the
C<LAYER> argument, and C<WRITE> will return the length of the string written.

This documentation describes version 0.12 of this module.

B<See Also:> L<perltie>, L<perlfunc/tie>, L<Tie::Handle>, L<Tie::StdHandle>

=head1 Examples

=head2 Debugging

This is a slightly "fancier" version of the example presented in the
L</Synopsis>, this prints all calls on the tied handle using
L<Class::Method::Modifiers|Class::Method::Modifiers>'s C<before> and
L<Data::Dump|Data::Dump>.

 package Tie::Handle::Debug;
 use parent 'Tie::Handle::Base';
 use Class::Method::Modifiers 'before';
 use Data::Dump 'dd';
 for my $method (@Tie::Handle::Base::ALL_METHODS) {
     before $method => sub { dd $method, @_[1..$#_] };
 }

=head2 Tee

Here is a simple "tee" implementation - anything written to the tied handle via
C<print>, C<printf>, and C<syswrite> will end up being written to all handles
given to C<new> (the first handle being the "main" handle that all the other
I/O functions in this example, including C<close>, are performed on).

 package Tie::Handle::Tee;
 use parent 'Tie::Handle::Base';
 sub TIEHANDLE {
     my ($class,$main,@others) = @_;
     my $self = $class->SUPER::TIEHANDLE($main);
     $self->{others} = \@others;
     return $self;
 }
 sub WRITE {
     my $self = shift;
     $self->inner_write($_, @_) for @{$self->{others}};
     return $self->SUPER::WRITE(@_);
 }

Note that you may wrap one tied handle in another - for example,
C<< my $fh = Tie::Handle::Debug->new( Tie::Handle::Tee->new(@handles) ) >>.

=head1 Methods

This section documents the methods of this class. Those methods that
wrap/emulate Perl's functionality also attempt to emulate the return values of
the original Perl functions.

=head2 C<new>

C<new> will create a new lexical filehandle, C<tie> it to the class (thus
invoking L</TIEHANDLE>), and return that filehandle. Any arguments to C<new>
are passed through to C<TIEHANDLE>, including the (optional) inner handle as
the first argument.

It is recommended for subclasses to override C<TIEHANDLE> instead of C<new>, as
this will provide a more consistent interface for users wishing to use Perl's
C<tie> instead of C<new>.

=head2 C<TIEHANDLE>

This method takes a single optional argument, which is the inner handle which
is wrapped by the tied handle. If this inner handle is not given, the method
will create a new lexical filehandle that is otherwise uninitialized. The
method then creates a new hashref which will serve as the object of the
specified class, and which implements the tied interface based on this class.
This object is also what is returned by C<tied(*$handle)>.

Subclasses may store whatever they like in this hashref, I<except> that keys
beginning with two underscores (C<__>) are reserved for this base class.
Subclasses overriding this method should still call it via the usual
C<< $class->SUPER::TIEHANDLE(...) >>.

=head2 C<UNTIE> and C<DESTROY>

These methods discard the inner handle which this class wraps. Subclasses
overriding these methods should call the superclass methods.

=head2 C<innerhandle>

This method returns the inner handle which is wrapped by this class.

Subclasses wishing to change the inner handle may do so with the
C<set_inner_handle> method, which takes a single argument, the new inner
handle.

=head2 C<OPEN>

This implementation will first call the C<FILENO> method and check for
C<defined>ness to see if the inner handle is still open, and if it is, call the
C<CLOSE> method before calling Perl's C<open> to open the inner handle.

=head3 C<open_parse>

This is a simple utility method that tries to parse a two-argument C<open>
and return arguments corresponding to a three-argument C<open>. It currently
does I<not> do much validation, because it is assumed you will be implementing
the code to act on the returned mode yourself.

 sub OPEN {
 	my $self = shift;
 	croak "bad number of arguments to open" if @_<1||@_>2;
 	my ($mode,$filename) = Tie::Handle::Base::open_parse(@_);
 	...

Note that if you pass C<open_parse> two arguments instead of just one, they
will simply be passed through. An C<open> with no arguments or more than two
arguments is not (yet) supported by this function.

=head2 C<PRINT>, C<PRINTF>, and C<WRITE>

The methods C<PRINT> and C<PRINTF> emulate the Perl functions by the same name
by building the output strings and passing them to the C<WRITE> method. This
means that subclasses can modify output behavior by overriding only the
C<WRITE> method. C<WRITE> itself is simply a call to L</inner_write>.

=head2 C<inner_write>

This function, intended for use by subclasses, may be called as either a simple
function, or as a method on the object, so that subclasses may call
C<< $self->inner_write($handle, ...) >>. In either case, the argument list must
be the same as that of C<syswrite>, including the filehandle which to output on
as the first argument. This function emulates C<syswrite> behavior using
C<substr> and Perl's C<print>. It does not use C<syswrite> internally in order
to be analogous to the L</READ> implementation.

=head2 C<READ>

Perl's tied filehandle interface will call this method for both C<read> and
C<sysread> calls. This method calls Perl's C<read>, not C<sysread>, because the
latter would bypass buffered I/O and cause confusion with other buffered I/O
methods such as C<seek>, C<tell>, and C<eof>.

This means that one limitation of this base class is that, while users may call
C<sysread> and C<syswrite> on the tied handles, these calls will I<not> be
translated into C<sysread/write> calls on the inner, wrapped handle.
(See L</inner_write> regarding C<syswrite>.)

=head2 All Other Methods

The methods
B<< C<BINMODE>, C<CLOSE>, C<EOF>, C<FILENO>, C<GETC>, C<READLINE>, C<SEEK>, and C<TELL> >>
are implemented in this class by calling the Perl functions of the same name.

The full list of methods that tied handles can/should implement is as follows.
The list of names is provided as C<@Tie::Handle::Base::ALL_METHODS>, and the
list C<@Tie::Handle::Base::IO_METHODS> excludes C<TIEHANDLE>, C<UNTIE>, and
C<DESTROY>.

=begin comment

 perl -wMstrict -le 'for(qw/ binmode close eof fileno getc open print printf
   read sysread readline seek tell syswrite tie untie /) { my $p=
   prototype("CORE::$_"); printf "%-9s %s\n",$_,defined$p?"($p)":"undef"}'

=end comment

 -- Method of the "tie" Interface ------------+-- Perl Prototype* ----
  BINMODE this                                | binmode   (*;$)      
  CLOSE this                                  | close     (;*)       
  EOF this                                    | eof       (;*)       
  FILENO this                                 | fileno    (*)        
  GETC this                                   | getc      (;*)       
  OPEN this, filename / OPEN this, mode, LIST | open      (*;$@)     
  PRINT this, LIST                            | print     none*      
  PRINTF this, format, LIST                   | printf    none*      
  READ this, scalar, length, offset           | (sys)read (*\$$;$)   
  READLINE this                               | readline  (;*)       
  SEEK this, offset, whence                   | seek      (*$$)      
  TELL this                                   | tell      (;*)       
  WRITE this, scalar, length, offset          | syswrite  (*$;$$)    
  TIEHANDLE classname, LIST                   | tie       (\[$@%*]$@)
  UNTIE this                                  | untie     (\[$@%*])  
  DESTROY this                                | N/A

* L<Prototypes|perlsub/Prototypes> as reported by the
L<prototype|perlfunc/prototype> function as of Perl 5.26. Note that C<print>
and C<printf> get special handling by Perl and therefore do not report a
standard prototype.

=head1 See Also

L<Tie::Handle::Argv> (part of this distribution),
a base class for tying to Perl's magic C<ARGV> handle.

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

