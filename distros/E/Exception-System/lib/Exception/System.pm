#!/usr/bin/perl -c

package Exception::System;
use 5.006;
our $VERSION = 0.11;

=head1 NAME

Exception::System - The exception class for system or library calls

=head1 SYNOPSIS

  # The simplest usage
  use Exception::Base 'Exception::System';
  open my $file, "/notfound"
    or Exception::System->throw(message=>"Can not open file");

  # The Exception::System class can be a base class for others
  #
  # Loaded automatically if used as Exception::Base's argument
  use Exception::Base,
    'Exception::System',
    'Exception::File' => {
        isa => 'Exception::System',
        has => 'filename',
        string_attributes => [ 'message', 'errstr', 'filename' ],
    };

  eval {
    my $filename = "/notfound";
    open my $fh, $filename
        or Exception::File->throw(
               message=>"Can not open file",
               filename=>$filename,
           );
  };
  if ($@) {
    my $e = Exception::Base->catch;
    if ($e->isa('Exception::File')) { warn "File error:".$e->errstr; }
    if ($e->matches({errname=>'ENOENT'})) { warn "Caught not found error"; }
  }

=head1 DESCRIPTION

This class extends standard L<Exception::Base> with handling system or library
errors.  The additional attributes of the exception object are filled on throw
and contain the error message and error codes.

=for readme stop

=cut


use strict;
use warnings;


# Extend Exception::Base class
use Exception::Base 0.20
    'Exception::System' => {
        has       => { ro => [ 'errstr', 'errstros', 'errno', 'errname' ] },
        message   => 'Unknown system exception',
        verbosity => 3,
        string_attributes => [ 'message', 'errstr' ],
        numeric_attribute => 'errno',
    };


# Use ERRNO hash
use Errno ();


# Map for errno -> errname (choose the shortest errname string for the same errno number)
my %Errname = map { Errno->$_ => $_ }
              sort { length $b <=> length $a }
              sort
              keys (%!);


# Collect system data
sub _collect_system_data {
    my $self = shift;

    $self->{errstr}   = "$!";   # string context
    $self->{errstros} = $^E;
    $self->{errno}    = 0+$!;   # numeric context
    $self->{errname}  = $Errname{ $self->{errno} } || '';

    return $self->SUPER::_collect_system_data(@_);
};


1;


__END__

=begin umlwiki

= Class Diagram =

[                       <<exception>>
                      Exception::System
 -------------------------------------------------------------
 +message : Str = "Unknown system exception"             {new}
 +errstr : Str
 +errstros : Str
 +errno : Int
 +errname : Str
 #numeric_attribute : Str = "strno"
 #string_attributes : ArrayRef[Str] = ["message", "errstr"]
 -------------------------------------------------------------
 #_collect_system_data()
 <<constant>> +ATTRS() : HashRef                              ]

[Exception::System] ---|> [Exception::Base]

=end umlwiki

=head1 BASE CLASSES

=over

=item *

L<Exception::Base>

=back

=head1 CONSTANTS

=over

=item ATTRS

Declaration of class attributes as reference to hash.

See L<Exception::Base> for details.

=back

=head1 ATTRIBUTES

Class attributes are implemented as values of blessed hash.  The attributes of
base class are inherited.  See L<Exception::Base> to see theirs description.

=over

=item message (rw, default: 'Unknown system exception')

Contains the message of the exception.  This class overrides the default value
from L<Exception::Base> class.

=item errstr (ro)

Contains the system error string fetched at exception throw.  It is the part
of the string representing the exception object.  It is the same as C<$!>
variable in string context.

  eval { Exception::System->throw( message=>"Message" ) };
  my $e = Exception::Base->catch
    and print $e->errstr;

=item errstros (ro)

Contains the extended system error string fetched at exception throw.  It is
the same as C<$^E> variable.

  eval { Exception::System->throw( message=>"Message" ); };
  if ($@) {
    my $e = Exception::Base->catch;
    if ($e->errstros ne $e->errstr) {
      print $e->errstros;
    }
  }

=item errno (ro)

Contains the system error number fetched at exception throw.  It is the same
as C<$!> variable in numeric context.  This attribute represents numeric value
of the exception object in numeric context.

  use Errno ();
  eval { Exception::System->throw( message=>"Message" ); };
  if ($@) {
    my $e = Exception::Base->catch;
    if ($e->errno == &Errno::ENOENT) {  # explicity
      warn "Not found";
    }
    elsif ($e == &Errno::EPERM) {       # numeric context
      warn "Bad permissions";
    }
  }

=item errname (ro)

Contains the system error constant from the system F<error.h> include file.

  eval { Exception::System->throw( message=>"Message" ); };
  my $e = Exception::Base->catch
    and $e->errname eq 'ENOENT'
    and $e->throw;

=item string_attributes (default: ['message', 'errstr'])

Meta-attribute contains the format of string representation of exception
object.  This class overrides the default value from L<Exception::Base>
class.

=item numeric_attribute (default: 'errno')

Meta-attribute contains the name of the attribute which contains numeric
value of exception object.  This class overrides the default value from
L<Exception::Base> class.

=back

=head1 PRIVATE METHODS

=over

=item _collect_system_data

Collect system data and fill the attributes of exception object.  This
method is called automatically if exception if throwed.  This class
overrides the method from L<Exception::Base> class.

=back

=head1 SEE ALSO

L<Exception::Base>.

=head1 BUGS

If you find the bug, please report it.

=for readme continue

=head1 AUTHOR

Piotr Roszatycki E<lt>dexter@debian.orgE<gt>

=head1 LICENSE

Copyright (C) 2007, 2008 by Piotr Roszatycki E<lt>dexter@debian.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
