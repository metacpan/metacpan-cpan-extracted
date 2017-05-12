package Linux::Shadow;

use 5.010001;
use strict;
use warnings;
use feature 'state';
use Carp;

require Exporter;
use AutoLoader;

use base qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [
        qw(
          SHADOW
          getspnam
          getspent
          setspent
          endspent
          )
    ],
    'getpw' => [
        qw(
          getpwnam
          getpwuid
          getpwent
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, @{ $EXPORT_TAGS{'getpw'} } );

our @EXPORT = qw(
  getspnam
  getspent
  setspent
  endspent
);

our $VERSION = '0.05';

sub AUTOLOAD {
    my $constname;
    our $AUTOLOAD;
    ( $constname = $AUTOLOAD ) =~ s/.*:://;
    croak '&Linux::Shadow::constant not defined' if $constname eq 'constant';
    my ( $error, $val ) = constant($constname);
    if ($error) { croak $error; }
    {
        no strict 'refs';
        *$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load( 'Linux::Shadow', $VERSION );

sub getpwnam {

    my ($name) = @_;
    my @pwent = CORE::getpwnam($name);
    return set_pwent_expire(@pwent);

}

sub getpwuid {

    my ($uid) = @_;
    my @pwent = CORE::getpwuid($uid);
    return set_pwent_expire(@pwent);

}

sub getpwent {

    my @pwent = CORE::getpwent();
    return set_pwent_expire(@pwent);

}

sub set_pwent_expire {

    my @pwent = @_;

    if ( @pwent && $pwent[0] && !defined $pwent[9] ) {

        my @shadow = getspnam( $pwent[0] );
        if ( @shadow && ( $shadow[0] eq $pwent[0] ) && defined $shadow[7] ) {
            $pwent[9] = $shadow[7];
        }

    }

    return @pwent;

}

1;
__END__

=head1 NAME

Linux::Shadow - Perl extension for accessing the shadow files using the
standard libc shadow routines.

=head1 SYNOPSIS

  use Linux::Shadow;
  ($name,$passwd,$lstchg,$min,$max,$warn,$inact,$expire,$flag) = getspnam('user');
  ($name,$passwd,$lstchg,$min,$max,$warn,$inact,$expire,$flag) = getspent();
  setspent();
  endspent();
  
  use Linux::Shadow qw(:getpw);
  ($name,$passwd,$uid,$gid, $quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam('user');
  ($name,$passwd,$uid,$gid, $quota,$comment,$gcos,$dir,$shell,$expire) = getpwuid(0);
  ($name,$passwd,$uid,$gid, $quota,$comment,$gcos,$dir,$shell,$expire) = getpwent();

=head1 DESCRIPTION
 
Perl gives access to the user's shadow password itself via getpw*, but the
rest of the shadow entry is not available (expire is theoretically available
if compiled that way, but it isn't universal).  This module provides a Perl
interface to the shadow routines getspnam, getspent, setspent and endspent,
allowing the full shadow password structure to be returned.  Like all access
to the shadow files, root privileges are required to return anything - non-
root users get nothing.

=head1 SUBROUTINES

=head2 Default Exports

These routines are exported by default, as they simply expose identically
named C library routines that are not a part of Perl's core.

=over

=item getspnam(NAME)

Return the shadow entry of the listed user as an array.  If the user doesn't
exist, or an error occurs, returns an empty array.

=item getspent()

Return the shadow entry of the next user in the shadow file starting with the
first entry the first time getspent() is called.  Returns and empty array once
the end of the shadow file is reached or an error occurs.

=item setspent()

Resets the pointer in the shadow file to the beginning.

=item endspent()

Releases the resources used to access the shadow file.

=back

=head2 Exportable constants

  SHADOW - the path of the system shadow file

This is not exported by default.  You can get both this constant and the
exported functions by using the ':all' tag.

=head2 Overloaded Core Routines

These routines overload the identically named Perl core routines, with the
purpose of populating the $expires field that is not typically compiled into
Perl itself.  These must be explicitly imported to access them.

=over

=item getpwnam(NAME)

=item getpwuid(UID)

=item getpwent

These functions work exactly like the identically named functions documented
in L<perlfunc/perlfunc>, except that if they return the userinfo and can
access the shadow info, the $expires field is guaranteed to be populated.
See L<perlfunc/getpwnam> for details.

=back

=head1 RETURN VALUES

=head2 Shadow Entry

The shadow entry returned by getspnam and getspent is an array of 9 items as
follows:

=over

=item name

The user login name.

=item passwd

The user's encrypted password.

=item lstchg

The number of days since Jan 1, 1970 password was last changed.

=item min

The number of days before which password may not be changed.

=item max

The number of days after which password must be changed.

=item warn

The number of days before password is to expire that user is warned of pending
password expiration.

=item inact

The number of days after password expires that account is considered inactive and disabled.

=item expire

The number of days since Jan 1, 1970 when account will be disabled.

=item flag

This field is reserved for future use.

=back

=head1 FILES

These functions rely on the system shadow file, which is usually /etc/shadow.

=head1 CAVEATS

Access to the shadow file requires root privileges, or possibly membership in
the shadow group if it exists (this is OS/distribution-specific).  Calling
getspnam or getspent without as a non- root user will return nothing.

=head1 SEE ALSO

L<shadow(3)>, L<getspnam(3)>, L<perlfunc/getpwnam>

=head1 AUTHOR

Joshua Megerman, E<lt>josh@honorablemenschen.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Joshua Megerman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
