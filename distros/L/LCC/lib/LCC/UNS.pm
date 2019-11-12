package LCC::UNS;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::UNS::ISA = qw(LCC);
$LCC::UNS::VERSION = '0.02';

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 LCC object
#      2 server:port specification
#      3 ref to hash with method/value pairs

sub _new {

# Obtain the class of the object
# Attempt to create the base object
# Handle the serverport specification if there is any
# Handle any method calls

  my $class = shift;
  my $self = $class->SUPER::_new( shift );
  $self->serverport( shift ) if @_ and !ref($_[0]);
  $self->Set( shift ) if ref($_[0]);

# Return the object

  return $self;
} #_new

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: new server:port specification
# OUT: current/old server:port specification

sub serverport { shift->_class_variable( 'serverport',@_ ) } #serverport

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

sub DESTROY {

# Obtain the object
# Stop the daemon if so specified

  my $self = shift;
  $self->stop if $self->auto_shutdown;
} #DESTROY

#------------------------------------------------------------------------

__END__

=head1 NAME

LCC::UNS - connection to a Update Notification Server

=head1 SYNOPSIS

 use LCC;
 $LCC = LCC->new( | {method => value} );
 $uns = $LCC->UNS( server:port | server, | {method => value} );

=head1 DESCRIPTION

The UNS object of the Perl support for LCC.  Do not create
directly, but through the UNS method of the LCC object.

=head1 METHODS

These methods are available to the LCC::UNS object.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://lococa.sourceforge.net.org, the LCC.pm and the other LCC::xxx modules.

=cut
