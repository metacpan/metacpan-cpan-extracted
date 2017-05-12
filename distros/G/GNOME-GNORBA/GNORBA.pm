package GNOME::GNORBA;

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;
require Carp;

require GNOME::GOAD;

@ISA = qw(DynaLoader);


$VERSION = '0.1.0';

bootstrap GNOME::GNORBA $VERSION;

use Fcntl qw(LOCK_EX LOCK_UN O_CREAT O_EXCL O_WRONLY O_RDONLY);

my $COOKIE_LENGTH = 63;

sub get_cookie_reliably {
    my $setme = shift;

    # We assume that if we could get this far, then /tmp/orit-$username
    # is already secured (because of CORBA_ORB_init)
    
    my $pwname = getpwuid($<);
#    my $name = "/tmp/orbit-$pwname/cookie";
    my $name = "/tmp/orbit-cookie";
    
    if (defined $setme) {
	if (!sysopen COOKIEFILE, $name, O_CREAT | O_WRONLY, 0600) {
	    warn "GNOME::GNORBA: Could not create cookie file: $!\n";
	    return undef;
	}
	
	flock (COOKIEFILE, LOCK_EX);
	my $result = syswrite COOKIEFILE, $setme;
	flock (COOKIEFILE, LOCK_UN);
	
	if (!$result) {
	    warn "GNOME::GNORBA: Error writing to cookie file: $!\n";
	    close COOKIEFILE;
	    unlink $name;
	    return undef;
	}

	if (!close COOKIEFILE) {
	    warn "GNOME::GNORBA: Error writing to cookie file: $!\n";
	    close COOKIEFILE;
	    unlink $name;
	    return undef;
	}

	return $setme;
    } else {

	my $buf;
	
	# Create the file exclusively with permissions rw for the
	# user.  if this fails, it means the file already existed
	#
	if (sysopen COOKIEFILE, $name, O_CREAT|O_EXCL|O_WRONLY, 0600) {
	    
	    $buf = " " x $COOKIE_LENGTH;
	    for my $i (0..length($buf)-1) {
		substr($buf, $i, 1, chr(rand(126-33) + 33));
	    }
	    flock (COOKIEFILE, LOCK_EX);
	    my $result = syswrite COOKIEFILE, $buf;
	    flock (COOKIEFILE, LOCK_UN);

	    if (!$result) {
		warn "GNOME::GNORBA: Error writing to cookie file: $!\n";
		close COOKIEFILE;
		unlink $name;
		return undef;
	    }
	    if (!close COOKIEFILE) {
		warn "GNOME::GNORBA: Error writing to cookie file: $!\n";
		close COOKIEFILE;
		unlink $name;
		return undef;
	    }

	} else {
	    if (!sysopen COOKIEFILE, $name, O_RDONLY) {
		warn "GNOME::GNORBA: Could not open cookie file: $!\n";
		return undef;
	    }
	    my $count = sysread COOKIEFILE, $buf, $COOKIE_LENGTH;
	    if (!defined $count || $count < $COOKIE_LENGTH) {
		warn "GNOME::GNORBA: Error reading cookie file: $!\n";
		return undef;
	    };
	    close COOKIEFILE;
	}

	return $buf;
    }
}

sub init {
    my $cookie = check_x_cookie (sub {
				     $SIG{__WARN__} = sub {};
				     get_cookie_reliably;
				 });
    if (!defined $cookie) { # no X connection
	$cookie = get_cookie_reliably;
    }

    CORBA::ORBit::set_cookie ($cookie);
}

sub name_service_get {
    my $ior = get_x_ns_ior();
    if (!defined $ior) {
	Carp::carp ("X not running, can't get name service IOR\n");
	return undef;
    }
    if ($ior eq "") { # Should start name server here
	return undef;
    } else {
	my $orb = CORBA::ORB_init ("orbit-local-orb");
	return $orb->string_to_object ($ior);
    }
}
		      
1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

GNOME::GNORBA - Perl extension for using ORBit with GNOME

=head1 SYNOPSIS

  use GNOME::GNORBA;

=head1 DESCRIPTION

The GNOME::GNORBA module sets up cookies appropriately for
using ORBit in a GNOME environment, and also provides
an interface to GOAD. (The GNOME Object Activation Directory)

=head1 AUTHOR

Owen Taylor <otaylor@redhat.com>
Copyright Red Hat, Inc, 1999.

=head1 SEE ALSO

perl(1).

=cut
