package Email::Fingerprint::Cache;
use Class::Std;

use warnings;
use strict;

use Carp qw( croak cluck );
use Scalar::Util qw( reftype blessed );

=head1 NAME

Email::Fingerprint::Cache - Cache observed email fingerprints

=head1 VERSION

Version 0.48

=cut

our $VERSION = '0.48';

=head1 SYNOPSIS

    use Email::Fingerprint::Cache;

    my %fingerprints;           # To access cache contents

    # Create a cache
    my $cache     =  new Email::Fingerprint::Cache(
        backend   => "AnyDBM",
        hash      => \%fingerprints,
        file      => $file,             # Created if doesn't exist
        ttl       => 3600 * 24 * 7,     # Purge records after one week
    );

    # Prepare it for use
    $cache->lock or die "Couldn't lock: $!";    # Waits for lock
    $cache->open or die "Couldn't open: $!";

    # Work with fingerprints
    for my (@message_fingerprints) {

        if ($fingerprints{$_}) {
            print "Fingerprint found: $_\n";
            next;
        }

        my $now = time;
        $fingerprints{$_} = $now;

        print "Fingerprint added: $_\n";
    }

    # Get rid of old records
    $cache->purge;

    # Print a listing of all fingerprints
    $cache->dump;

    # Finish up
    $cache->close;
    $cache->unlock;

=head1 ATTRIBUTES

=cut

my %hash    :ATTR( :get<hash> )                  = ();
my %ttl     :ATTR( :name<ttl> :default(604800) ) = ();
my %backend :ATTR( :init_arg<backend> :default('AnyDBM') ) = ();

=head1 METHODS

=head2 new

    my $fingerprint =  new Email::Fingerprint::Cache(
        file        => $file,   # Default: .maildups
        backend     => "AnyDBM",  # Default: "AnyDBM"
        ttl         => $sec,    # Default: 3600*24*7
        hash        => $ref,    # Optional
    );

Returns a new Email::Fingerprint::Cache. The cache must still be opened
before it can be used.

=head2 BUILD

Internal helper method; never called directly by users.

=cut

sub BUILD {
    my ( $self, $ident, $args ) = @_;

    # Default hash is a fresh-n-tasty anonymous hash
    $hash{$ident} = defined $args->{hash} ? $args->{hash} : {};

    # Backend will also need access to the hash
    $args->{hash} = $hash{$ident};

    # Default backend is AnyDBM
    my $backend = defined $args->{backend} ? $args->{backend} : 'AnyDBM';

    # Default cache file
    $args->{file} ||= '.maildups';

    # Try accessing package as a subclass of Email::Fingerprint::Cache
    my $package = __PACKAGE__ . "::" . $backend;
    eval "use $package";                                    ## no critic

    # Try accessing package using the given name exactly. If this fails,
    # we try constructing a backend anyway, in case the module is already
    # imported--or, e.g., defined in the script file itself.
    if ($@) {
        $package = $backend;
        eval "use $package";                                ## no critic
    }

    undef $backend;

    # Perhaps the correct module was loaded by our caller;
    # try instantiating the backend even if the above steps
    # all failed.
    eval {
        $backend =  $package->new({
            file => $args->{file},
            hash => $args->{hash},
        });
    };

    # It's a fatal error if the backend doesn't load
    croak "Can't load backend module" if $@ or not $backend;

    $backend{$ident} = $backend;
}

=head2 set_file

  $file = $cache->set_file( 'foo' ) or die "Failed to set filename";
  # now $file eq 'foo.db' or 'foo.dir', etc., depending on the backend;
  # it is almost certainly NOT 'foo'.

Sets the file to be used for the cache. Returns the actual filename
on success; false on failure.

The actual filename will probably differ from the 'foo', because
the backend will usually add an extension or otherwise munge it.

C<set_file> has I<no> effect while the cache file is locked or open!

=cut

sub set_file {
    my ($self, $file) = @_;

    # Validation
    return if $self->get_backend->is_locked;
    return if $self->get_backend->is_open;

    # OK, there's no harm in changing the file attribute
    $self->get_backend->set_file($file);

    1; 
}

=head2 get_backend

Returns the backend object for this cache.

=cut

sub get_backend :PRIVATE() {
    my $self = shift;
    return $backend{ident $self};
}

=head2 dump

    # Be a good citizen
    $cache->lock;
    $cache->open;

    $cache->dump;

    # Be a good neighbor
    $cache->close;
    $cache->unlock;

Dump a human-readable version of the contents of the cache. Data is
printed in timestamp order.

The cache I<must> first be opened, and I<should> first be locked.

=cut

sub dump {
    my $self = shift;
    my $hash = $self->get_hash;

    for my $key ( sort { $hash->{$a} <=> $hash->{$b} } keys %$hash )
    {
        my $value = $hash->{$key};
        print "$value\t", scalar gmtime $value, "\t$key\n";
    }
}

=head2 open

    $cache->open or die;

Open the cache file, and tie it to a hash. This is delegated to the
backend.

=cut

sub open {
    my $self = shift;

    return $self->_delegate( "open", @_ );
}

=head2 close

  $cache->close;

Close the cache file and untie the hash.

=cut

sub close {
    my $self = shift;

    return $self->_delegate( "close", @_ );
}

=head2 lock

  $cache->lock or die;                  # returns immediately
  $cache->lock( block => 1 ) or die;    # Waits for a lock
  $cache->lock( %opts ) or die;         # Backend-specific options

Lock the DB file to guarantee exclusive access.

=cut

sub lock {
    my $self = shift;

    return $self->_delegate( "lock", @_ );
}

=head2 unlock

  $cache->unlock or warn "Unlock failed";

Unlock the DB file.

=cut 

sub unlock {
    my $self = shift;
    return $self->_delegate( "unlock", @_ );
}

=head2 purge

    $cache->purge;                  # Use default TTL
    $cache->purge( ttl => 3600 );   # Everything older than 1 hour

Purge the cache of old entries. This reduces the risk of false positives
from things like reused message IDs, but increases the risk of false
negatives.

The C<ttl> option specifies the "time to live": cache entries older
than that will be purged. The default is one week. If the TTL is
zero, then (just as you'd expect) items one second or older will
be purged.  If you specify a negative TTL, then the cache will be
emptied completely.

=cut

sub purge {
    my $self = shift;
    my %opts = @_;

    my $hash = $self->get_hash;
    my $ttl  = defined $opts{ttl} ? $opts{ttl} : $self->get_ttl;
    my $now  = time;

    for my $key ( keys %$hash )
    {
        my $timestamp = $hash->{$key} || 0; # Also clobbers bad data like undef
        delete $hash->{$key} if ($now - $timestamp) > $ttl or $ttl < 0;
    }

    1;
}

=head2 DESTROY

Clean up the module. If the hash is still tied, we warn the user and call
C<close()> on C<$self>.

=head2 DEMOLISH

Internal helper method, never called directly by user.

=cut

sub DEMOLISH {
    my $self   = shift;

    my $backend = $self->get_backend;

    # Failing to close() the cache is bad: data won't be
    # committed to disk.
    if ( $backend and $backend->is_open )
    {
        cluck "Cache DESTROY()ed before it was close()ed";
        $self->close;
    }

    # Failure to unlock() is rude, but we don't say anything.
    $self->unlock;
}

=head2 _delegate

Delegate the specified method to the backend. Internal method.

=cut

sub _delegate :PRIVATE() {
    my ($self, $method, @args) = @_;

    my $backend = $self->get_backend;
    return unless $backend;

    return $backend->$method(@args);
}

=head1 AUTHOR

Len Budney, C<< <lbudney at pobox.com> >>

=head1 BUGS

The C<dump()> method assumes that Perl's C<time()> function returns
seconds since the UNIX epoch, 00:00:00 UTC, January 1, 1970. The
module will work on architectures with non-standard epochs, but the
automated tests will fail.

Please report any bugs or feature requests to
C<bug-email-fingerprint at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Fingerprint>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Fingerprint::Cache

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Fingerprint>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Fingerprint>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Fingerprint>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Fingerprint>

=back

=head1 ACKNOWLEDGEMENTS

Email::Fingerprint::Cache is based on caching code in the
C<eliminate_dups> script by Peter Samuel and available at
L<http://www.qmail.org/>.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2011 Len Budney, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
