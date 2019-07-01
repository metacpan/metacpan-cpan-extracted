#############################################################################
#
# Lemonldap::NG::Common::Apache::Session::Generate::SHA256
# Generates session identifier tokens using SHA-256
# Distribute under the Perl License
#
############################################################################

package Lemonldap::NG::Common::Apache::Session::Generate::SHA256;

use strict;
use Crypt::URandom;

our $VERSION = '2.0.2';

sub generate {
    my $session = shift;
    my $length  = 64;

    if ( exists $session->{args}->{IDLength} ) {
        $length = $session->{args}->{IDLength};
    }

    eval {
        $session->{data}->{_session_id} =
          unpack( 'H*', Crypt::URandom::urandom( int( $length / 2 ) ) );
    };
    if ($@) {
        print STDERR "Crypt::URandom::urandom failed: $@\n";
        require Digest::SHA;
        $session->{data}->{_session_id} =
          substr( Digest::SHA::sha256_hex( time() . {} . rand() . $$ ),
            0, $length );
    }
}

sub validate {

    #This routine checks to ensure that the session ID is in the form
    #we expect.  This must be called before we start diddling around
    #in the database or the disk.

    my $session = shift;

    if ( $session->{data}->{_session_id} =~ /^([a-fA-F0-9]+)$/ ) {
        $session->{data}->{_session_id} = $1;
    }
    else {
        die "Invalid session ID: " . $session->{data}->{_session_id};
    }
}

1;
