use strict;
use warnings;

package Footprintless::Plugin::Ldap::Ldap;
$Footprintless::Plugin::Ldap::Ldap::VERSION = '1.00';
# ABSTRACT: The ldap client implementation
# PODNAME: Footprintless::Plugin::Ldap::Ldap;

use parent qw(Footprintless::MixableBase);

use overload q{""} => 'to_string', fallback => 1;

use Carp;
use Footprintless::Mixins qw(
    _entity
);
use Log::Any;
use Net::LDAP;
use Net::LDAP::Constant qw(LDAP_NO_SUCH_OBJECT);
use Net::LDAP::LDIF;
use Net::LDAP::Util;
use Time::HiRes qw(gettimeofday tv_interval);

my $logger = Log::Any->get_logger();

# https://tools.ietf.org/html/rfc2251#section-4.5.1
# If the client does not want any attributes returned, it can specify
# a list containing only the attribute with OID "1.1"
use constant NO_ATTRIBUTES => ['1.1'];

sub add {
    my ( $self, $entry ) = @_;
    croak('not connected') unless ( $self->{connection} );

    $logger->tracef( 'adding %s', $entry->dn() );
    my $message = $self->{connection}->add($entry);
    $message->code() && croak( $message->error() );

    return $self;
}

sub add_or_update {
    my ( $self, $entry ) = @_;

    eval { $self->add($entry); };
    if ($@) {
        $self->update($entry);
    }

    return $self;
}

sub base_dn {
    my ( $self, @rdns ) = @_;
    my $dn = $self->{default_base};
    foreach my $rdn (@rdns) {
        $dn = "$rdn,$dn";
    }
    return $dn;
}

sub bind {
    my ( $self, $dn, %options ) = @_;
    croak('not connected') unless ( $self->{connection} );

    if ( !$dn ) {

        # binding with instance credentials
        $dn      = $self->{bind_dn};
        %options = %{ $self->{bind_options} };
    }

    if ($dn) {
        my $result = $self->{connection}->bind( $dn, %options );
        $result->code() && croak( "unable to authenticate to $self:\n\t" . $result->error() );
    }
    else {
        my $result = $self->{connection}->bind();
        $result->code() && croak( "unable to bind anonymously:\n\t" . $result->error() );
    }

    return $self;
}

sub connect {
    my ( $self, %connect_options ) = @_;

    return if ( $self->{connection} );

    my ( $hostname, $port );
    if ( $self->{tunnel_hostname} ) {
        $self->{tunnel} = $self->{factory}->tunnel(
            $self->{coordinate},
            destination_hostname => $self->{tunnel_destination_hostname} || $self->{hostname},
            destination_port => $self->{port}
        );
        $self->{tunnel}->open();
        $hostname = $self->{tunnel}->get_local_hostname() || 'localhost';
        $port = $self->{tunnel}->get_local_port();
    }
    else {
        $hostname = $self->{hostname};
        $port     = $self->{port};
    }

    $logger->debugf( 'connecting to [%s:%s]', $hostname, $port );
    $self->{connection} = (
        $self->{secure}
        ? Net::LDAPS->new( $hostname, port => $port, %connect_options )
        : Net::LDAP->new( $hostname, port => $port, %connect_options )
        )
        || croak("unable to connect");

    if ( $self->{tunnel_hostname} ) {

        # Since tunnels give the illusion of a successful connection
        # we will attempt a bind to see if we are really connected.
        my $result = $self->{connection}->bind();
        if ( $result->code() == 1 ) {
            $self->disconnect();
            croak( "unable to connect through tunnel:\n\t" . $result->error() );
        }

        # We do not unbind since some ldap servers do not allow subsequent
        # bind operations (https://metacpan.org/pod/Net::LDAP#unbind)
    }

    return $self;
}

sub canonical_dn {
    my ( $self, $dn, @options ) = @_;
    return _canonical_dn( $dn, @options );
}

sub _canonical_dn {
    return Net::LDAP::Util::canonical_dn( shift, @_ );
}

sub delete {
    my ( $self, $base, %options ) = @_;
    croak('not connected') unless ( $self->{connection} );

    if ( !%options ) {
        $logger->tracef( 'deleting %s', $base );
        my $message = $self->{connection}->delete($base);
        $message->code() && $message->code() != LDAP_NO_SUCH_OBJECT && croak( $message->error() );
    }
    else {
        my $filter = $options{filter} || '(objectClass=*)';
        my $scope  = $options{scope}  || 'base';

        my @dns;
        if ( $scope eq 'base' ) {
            @dns = ($base);
        }
        else {
            @dns = $self->search_for_list(
                {   base   => $base,
                    filter => $filter,
                    scope  => $scope,
                    attrs  => ['1.1']
                },
                sub {
                    return $_[0]->dn();
                }
            );
            if ( $scope eq 'sub' ) {

                # needs reverse sort to make sure children come first
                @dns = map { scalar reverse($_) }
                    reverse sort
                    map { scalar reverse($_) } @dns;
            }
        }

        if ( scalar(@dns) ) {
            if ( $logger->is_debug() ) {
                my $count          = 0;
                my $total          = scalar(@dns);
                my $start          = [gettimeofday];
                my $interval_start = $start;
                my ( $interval_time, $full_time, $instant, $remaining );
                foreach my $dn (@dns) {
                    if ( $count++ % 100 == 0 ) {
                        my $instant = [gettimeofday];
                        $interval_time = tv_interval( $interval_start, $instant );
                        $full_time     = tv_interval( $start,          $instant );
                        $remaining = ( ( $total - $count ) / $count ) * $full_time;
                        $logger->debugf( 'deleting %d/%d (interval:%d,full:%d,remaining:%d)',
                            $count, $total, $interval_time, $full_time, $remaining );
                        $interval_start = $instant;
                    }
                    $self->delete($dn);
                }
            }
            else {
                $self->delete($_) foreach (@dns);
            }
        }
    }

    return $self;
}

sub DESTROY {
    my ($self) = @_;
    $self->disconnect();
}

sub disconnect {
    my ($self) = @_;

    # cant use logger during DESTRUCT
    my $phase_destruct = ( ${^GLOBAL_PHASE} eq 'DESTRUCT' );
    if ( $self->{connection} ) {
        eval { $self->unbind(); };
        if ($@) {
            $logger->debugf( 'unbind failed: %s', $@ ) unless ($phase_destruct);
        }

        $logger->debug('disconnecting') unless ($phase_destruct);
        delete( $self->{connection} );
    }
    else {
        $logger->debug('not connected') unless ($phase_destruct);
    }

    if ( $self->{tunnel} ) {
        $logger->debug('closing tunnel') unless ($phase_destruct);
        $self->{tunnel}->close();
        delete( $self->{tunnel} );
    }
    else {
        $logger->debug('tunnel not open') unless ($phase_destruct);
    }

    return $self;
}

sub _each_ldif_entry {
    my ( $self, $from, $callback ) = @_;

    my ( $ldif, $string_fh );
    eval {
        my $ref = ref($from);
        if ( $ref eq 'GLOB' ) {
            $logger->trace('ldif is glob');
            $ldif = Net::LDAP::LDIF->new( $from, 'r', onerror => 'die' );
        }
        elsif ( $ref eq 'SCALAR' ) {
            $logger->trace('ldif is stringref');
            open( $string_fh, '<', $from ) || croak('failed to open ldif string $?');
            $ldif = Net::LDAP::LDIF->new( $string_fh, 'r', onerror => 'die' );
        }
        else {
            $logger->trace('ldif is filename');
            $ldif = Net::LDAP::LDIF->new( $from, 'r', onerror => 'die' );
        }

        $logger->trace('begin reading ldif');
        while ( !$ldif->eof() ) {
            my $entry = $ldif->read_entry();
            &$callback($entry);
        }
        $logger->trace('end reading ldif');

        $ldif->done();
    };
    my $error = $@;

    if ( defined($string_fh) ) {
        close($string_fh);
    }

    if ($error) {
        $logger->errorf( 'ldif processing failure: %s', $@ );
        croak($@);
    }
}

sub exploded_dn {
    my ( $self, $dn, @options ) = @_;
    return _exploded_dn( $dn, @options );
}

sub _exploded_dn {
    return Net::LDAP::Util::ldap_explode_dn( shift, @_ );
}

sub export_ldif {
    my ( $self, $to, %options ) = @_;
    croak('not connected') unless ( $self->{connection} );

    $options{base}   = $self->{default_base} unless ( $options{base} );
    $options{scope}  = 'sub'                 unless ( $options{scope} );
    $options{filter} = '(objectClass=*)'     unless ( $options{filter} );
    $options{attrs}  = ['*']                 unless ( $options{attrs} );

    $logger->debugf( 'exporting for critieria: %s', \%options );

    my $dn    = $options{base};
    my $scope = $options{scope};

    my $count = 0;
    my ( $ldif, $string_fh );
    eval {
        if ( ref($to) eq 'SCALAR' ) {
            open( $string_fh, '>', $to ) || croak("failed to open ldif string $?");
            $ldif = Net::LDAP::LDIF->new( $string_fh, 'w', onerror => 'die' );
        }
        else {
            $ldif = Net::LDAP::LDIF->new( $to, 'w', onerror => 'die' );
        }

        if ( $scope eq 'base' || $scope eq 'sub' ) {
            $options{scope} = 'base';
            $self->search(
                \%options,
                sub {
                    _write_ldif_entry( $ldif, $_[0], \%options );
                    $count++;
                }
            );
        }
        if ( $scope eq 'sub' || $scope eq 'one' ) {
            $options{scope} = 'one';
            my @containers = ($dn);
            if ( $scope eq 'sub' ) {
                push( @containers, $self->search_for_containers($dn) );
            }

            foreach my $container (@containers) {
                $logger->tracef( 'searching with container %s', $container );
                $options{base} = $container;
                $self->search(
                    \%options,
                    sub {
                        _write_ldif_entry( $ldif, $_[0], \%options );
                        $count++;
                    }
                );
            }
        }

        $logger->trace('closing out the ldif');
        $ldif->done();
    };
    my $error = $@;

    close($string_fh) if ($string_fh);

    if ($error) {
        $logger->errorf( 'ldif processing failure: %s', $@ );
        croak($@);
    }

    $logger->tracef( 'added %d entries to the ldif', $count );
    return $count;
}

sub import_ldif {
    my ( $self, $from, %options ) = @_;
    croak('not connected') unless ( $self->{connection} );

    if ( $logger->is_debug() ) {
        my $total = 0;
        my $start = [gettimeofday];
        $self->_each_ldif_entry(
            $from,
            sub {
                $total++;
            }
        );
        $logger->debugf( 'fetching count took: %s', tv_interval( $start, [gettimeofday] ) );

        $start = [gettimeofday];
        my $count          = 0;
        my $interval_start = $start;
        my ( $interval_time, $full_time, $instant, $remaining );
        $self->_each_ldif_entry(
            $from,
            sub {
                if ( $count++ % 100 == 0 ) {
                    my $instant = [gettimeofday];
                    $interval_time = tv_interval( $interval_start, $instant );
                    $full_time     = tv_interval( $start,          $instant );
                    $remaining = ( ( $total - $count ) * ( $full_time / $count ) );
                    $logger->debugf( 'importing %d/%d (interval:%d,full:%d,remaining:%d)',
                        $count, $total, $interval_time, $full_time, $remaining );
                    $interval_start = $instant;
                }

                if ( $options{each_entry} ) {
                    &{ $options{each_entry} }( $_[0] );
                }
                else {
                    $self->add_or_update( $_[0] );
                }
            }
        );
    }
    else {
        $self->_each_ldif_entry( $from,
            $options{each_entry} || sub { $self->add_or_update( $_[0] ) } );
    }

    return $self;
}

sub _init {
    my ( $self, %options ) = @_;

    my $entity = $self->_entity( $self->{coordinate}, 1 );
    $self->{hostname} = $entity->{hostname} || 'localhost';
    $self->{port}     = $entity->{port}     || 389;
    $self->{secure}   = $entity->{secure}   || 0;
    $self->{default_base} = $entity->{default_base};
    $self->{bind_dn}      = $entity->{bind_dn} || $entity->{username};
    $self->{bind_options} = $entity->{bind_options}
        || { password => $entity->{password} };
    $self->{tunnel_hostname}             = $entity->{tunnel_hostname};
    $self->{tunnel_destination_hostname} = $entity->{tunnel_destination_hostname};
    $self->{tunnel_username}             = $entity->{tunnel_username};

    return $self;
}

sub is_connected {
    return $_[0]->{connection} ? 1 : 0;
}

sub modify {
    my ( $self, $dn, @options ) = @_;
    croak('not connected') unless ( $self->{connection} );

    my $message = $self->{connection}->modify( $dn, @options );
    $message->code() && croak( $message->error() );

    return $self;
}

sub search {
    my ( $self, $search_args, $each_entry_callback ) = @_;
    croak('not connected') unless ( $self->{connection} );

    $search_args->{base}   = $self->{default_base} unless ( $search_args->{base} );
    $search_args->{scope}  = 'base'                unless ( $search_args->{scope} );
    $search_args->{filter} = '(objectClass=*)'     unless ( $search_args->{filter} );

    $logger->tracef( 'searching %s for %s', $self->{hostname}, $search_args );
    my $message = $self->{connection}->search( %{$search_args} );

    return if ( $message->code() == LDAP_NO_SUCH_OBJECT );
    croak( $message->error() ) if ( $message->code() );

    while ( my $entry = $message->shift_entry() ) {
        &$each_entry_callback($entry);
    }
}

sub search_for_containers {
    my ( $self, $base ) = @_;

    $logger->tracef( 'searching for containers under %s', $base );
    my %containers;
    $self->search(
        {   base      => $base,
            scope     => 'sub',
            filter    => '(objectClass=*)',
            attrs     => NO_ATTRIBUTES,
            sizelimit => 0,
        },
        sub {
            my @exploded = @{ _exploded_dn( $_[0]->dn() ) };
            shift(@exploded);
            $containers{ _canonical_dn( \@exploded ) } = 1;
        }
    );

    my @containers = map { scalar reverse($_) }
        sort
        map { scalar reverse($_) } keys(%containers);

    if (@containers) {

        # pop off all the containers above and including base
        my $base_cononical_dn_length = length( _canonical_dn( _exploded_dn($base) ) );

        while ( my $container_cononical_dn = shift(@containers) ) {
            last if ( $base_cononical_dn_length == length($container_cononical_dn) );
        }
    }

    $logger->tracef( 'found containers %s', \@containers );
    return @containers;
}

sub search_for_list {
    my ( $self, $search_args, $entry_mapper ) = @_;

    my @entries;
    $self->search(
        $search_args,
        sub {
            my ($entry) = @_;

            push(
                  @entries, $entry_mapper
                ? &$entry_mapper($entry)
                : $entry
            );
        }
    );

    return wantarray ? @entries : \@entries;
}

sub search_for_map {
    my ( $self, $search_args, $entry_mapper ) = @_;

    my %entries = ();
    $self->search(
        $search_args,
        sub {
            my ($entry) = @_;
            my ( $key, $value );
            if ( defined($entry_mapper) ) {
                ( $key, $value ) = &{$entry_mapper}($entry);
            }
            else {
                ( $key, $value ) = [ $entry->dn(), $entry ];
            }
            $entries{$key} = $value;
        }
    );

    return \%entries;
}

sub search_for_scalar {
    my ( $self, $search_args, $entry_mapper ) = @_;

    # enforce single result
    $search_args->{sizelimit} = 1;

    my $result;
    $self->search(
        $search_args,
        sub {
            my ($entry) = @_;

            $result =
                $entry_mapper
                ? &{$entry_mapper}($entry)
                : $entry;
        }
    );

    return $result;
}

sub to_string {
    my ($self) = @_;

    my @string = ( ( $self->{secure} ? 'ldaps' : 'ldap' ), '://' );
    push( @string, $self->{hostname} );
    push( @string, ":$self->{port}" ) if ( $self->{port} );

    return join( '', @string );
}

sub unbind {
    my ($self) = @_;
    croak('not connected') unless ( $self->{connection} );

    $logger->trace('unbinding');
    my $message = $self->{connection}->unbind();
    $message->code() && croak( $message->error() );

    return $self;
}

sub update {
    my ( $self, $entry ) = @_;
    croak('not connected') unless ( $self->{connection} );

    $logger->tracef( 'updating %s', $entry->dn() );
    my $message = $entry->update( $self->{connection} );
    $message->code() && croak( $message->error() );

    return $self;
}

sub with_connection {
    my ( $self, $sub ) = @_;
    eval {
        $self->connect()->bind();
        &$sub();
    };
    my $error = $@;
    eval { $self->disconnect() };
    die($error) if ($error);
}

sub _write_ldif_entry {
    my ( $ldif, $entry, $options ) = @_;
    if ( $options->{around_write_ldif_entry} ) {
        $options->{around_write_ldif_entry}( $ldif, $entry, $options );
    }
    else {
        if ( $options->{set_password} && $entry->exists('userPassword') ) {
            $entry->replace( userPassword => $options->{set_password} );
        }
        $ldif->write_entry($entry);
    }
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Ldap::Ldap; - The ldap client implementation

=head1 VERSION

version 1.00

=head1 SYNOPSIS

Standard way of getting an ldap client:

    use Footprintless;
    my $ldap = Footprintless->new()->ldap('proj.env');

    # Export:
    $ldap->with_connection(sub { $ldap->export_ldif('/tmp/export.ldif') });

    # Import:
    $ldap->with_connection(sub { $ldap->import_ldif('/tmp/export.ldif') });

    # Search:
    eval {
        $ldap->connect()->bind();
        my @foo_users = $ldap->search_for_list({filter => '(mail=*@foo.com)'});

        # do other things...
    };
    my $error = $@;
    eval {$ldap->disconnect()};
    die($error) if ($error);

=head1 DESCRIPTION

This module is a convenience wrapper around C<Net::LDAP> that integrates with
L<Footprintless> and provides a bunch of useful LDAP manipulation functions.

=head1 ENTITIES

A simple LDAP entity:

    ldap => {
        # An admin user with permission to manipulate entries
        bind_dn => 'uid=admin,ou=system',

        # Password for bind_dn
        # password can also be specified directly at the top level...
        bind_options => { password => 'secret' },

        # Base dn to use for all operations when not explicitly specified
        # by the operation options
        default_base => 'dc=foo,dc=com'

        # The hostname of the server
        hostname => 'public-ldap.foo.com',

        # The port (default 389 if secure == 0, 636 otherwise)
        port => 389,

        # O for LDAP (default), 1 for LDAPS
        secure => 0,

        # Optional ssh tunnel configuration, uses Footprintless::Tunnel
        tunnel_destination_hostname => 'internal-ldap.foo.com',
        tunnel_hostname => 'bastion-gateway.foo.com',
        tunnel_username => 'automationuser',
    },

=head1 METHODS

=head2 add($entry)

Adds C<$entry>.

=head2 add_or_update($entry)

Adds C<$entry> if it does not exist, updates it otherwise.

=head2 base_dn(@rdns)

Returns a dn by combining all of the C<@rdns>.

=head2 bind($dn, %options)

Binds to C<$dn>.  If C<%options> are provided, they will be used in place to
the configured connection options.

=head2 connect(%connect_options)

Connects to the server (does not perfom a bind).  The C<%connect_options> are
passed through to the L<Net::LDAP> or L<Net::LDAPS> constructor.

=head2 canonical_dn($dn, %options)

Passes through to L<Net::LDAP::Util/canonical_dn>.

=head2 delete($base, %options)

If C<%options> are provided, the options C<filter> and C<scope> will be used
together with C<$base> to search for, and then delete entries.  Otherwise,
C<$base> will be deleted.

=head2 disconnect()

Disconnects from the server.

=head2 exploded_dn($dn, %options)

Passes through to L<Net::LDAP::Util/ldap_explode_dn>.

=head2 export_ldif($to, %options)

Exports the data to C<$to>, which must be one of:

=over 4

=item SCALARREF

A refrence to a scalar to hold the LDIF data.

=item string

The name of a file to write the LDIF data to.

=back

The supported options are, C<base>, C<scope>, C<filter>, and C<attrs>.  They
are used to search for the entries to export.

=head2 import_ldif($from, %options)

Imports the data from C<$from>, which must be one of:

=over 4

=item GLOBREF

A reference to a file handle to read LDIF data from.

=item SCALARREF

A refrence to a scalar to holding the LDIF data.

=item string

An LDIF filename.

=back

The supported options are:

=over 4

=item each_entry

A sub that gets run on each entry instead of 
L<add_or_update|/add_or_update($entry)>.

=back

=head2 is_connected()

Returns a I<truthy> value if currently connected.

=head2 modify($dn, %options)

Modifies the entry at C<$dn> according to C<%options>.  The C<%options> are 
specified by modify in L<Net::Ldap>

=head2 search($search_args, $each_entry_callback)

Searches for all entries matching C<$search_args> and calls C<$each_entry_callback>
for each result.

=head2 search_for_containers($base)

Returns an C<ARRAY> of C<dn>'s of all the I<containers> under C<$base>.

=head2 search_for_list($search_args, $entry_mapper)

Searches for all entries matching C<$search_args>.  If C<$entry_mapper> is supplied
it will be called for each entry.  Otherwise, the entry itself will be used.  All 
results will be aggregated into an C<ARRAY> or C<ARRAYREF> (depending on 
C<wantarray>) and returned.

=head2 search_for_map($search_args, $entry_mapper)

Searches for all entries matching C<$search_args>.  If C<$entry_mapper> is supplied
it will be called for each entry and will be expected to return a tuple (C<ARRAY> of
length 2), representing a key value pair.  Otherwise, the entry C<dn> and the entry
itself will be used as the key value pair.  All results will be aggregated into a
C<HASHREF> and returned.

=head2 search_for_scalar($search_args, $entry_mapper)

Searches for a single entry matching C<$search_args>.  If C<$entry_mapper> is 
supplied, it will be called with the entry, and the value returned will be returned.
Otherwise, the entry itself will be returned.

=head2 to_string()

Prints out a string containing connection information useful for debugging.

=head2 unbind()

Unbinds the connection to the server.

=head2 update($entry)

Updates C<$entry> on the server.

=head2 with_connection($sub)

Opens a connection, binds, calls C<$sub>, and disconnects.  If an error occurred
the disconnect will be executed and the error will be re-died.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Ldap|Footprintless::Plugin::Ldap>

=back

=for Pod::Coverage DESTROY

=cut
