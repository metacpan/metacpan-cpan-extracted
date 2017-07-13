use strict;
use warnings;

package Footprintless::Localhost;
$Footprintless::Localhost::VERSION = '1.25';
# ABSTRACT: A localhost alias resolver
# PODNAME: Footprintless::Localhost

use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init(@_);
}

sub _add_alias {
    my ( $self, $alias ) = @_;

    if ($alias) {
        $logger->debugf( 'adding alias [%s]', $alias );
        $self->{aliases}{ lc($alias) } = 1;
    }

    return $self;
}

sub _init {
    my ( $self, %options ) = @_;

    # what gets returned if is_alias( <falsey> );
    $self->{empty} = exists( $options{empty} ) ? $options{empty} : 1;

    $self->_add_alias('localhost')->_add_alias('127.0.0.1')
        unless ( $options{none} );

    if ( $options{aliases} ) {
        $self->_add_alias($_) foreach @{ $options{aliases} };
    }

    return $self;
}

sub is_alias {
    my ( $self, $hostname ) = @_;

    if ($hostname) {
        return $self->{aliases}{ lc($hostname) };
    }
    else {
        return $self->{empty};
    }
}

sub is_loaded {
    my ( $self, $extra ) = @_;
    return $self->{loaded} && $self->{loaded}{$extra};
}

sub load_all {
    shift->load_etc_hosts()->load_hostfqdn()->load_hostname();
}

sub load_etc_hosts {
    my ($self) = @_;

    if ( !$self->{loaded}{'/etc/hosts'} ) {

        # attempt to load aliases from hosts file
        $logger->debug('loading /etc/hosts');
        eval {
            require Config::Hosts;
            $logger->debug('have Config::Hosts');
            my $hosts = Config::Hosts->new();
            $hosts->read_hosts();
            my $one_two_seven = $hosts->query_host('127.0.0.1');
            if ($one_two_seven) {
                $self->_add_alias($_) foreach @{ $one_two_seven->{hosts} };
            }
        };
        $self->{loaded}{'/etc/hosts'} = 1;
    }

    return $self;
}

sub load_hostfqdn {
    my ($self) = @_;

    if ( !$self->{loaded}{hostfqdn} ) {

        # if fqdn is present, add it too...
        $logger->debug('loading hostfqdn');
        require Net::Domain;
        $self->_add_alias( Net::Domain::hostfqdn() );
        $self->{loaded}{hostfqdn} = 1;
    }

    return $self;
}

sub load_hostname {
    my ($self) = @_;

    if ( !$self->{loaded}{hostname} ) {

        # load alias from hostname
        $logger->debug('loading hostname');
        eval {
            # hostname() croaks on fail, so just ignore
            require Sys::Hostname;
            $self->_add_alias( Sys::Hostname::hostname() );
        };
        $self->{loaded}{hostname} = 1;
    }

    return $self;
}

1;

__END__

=pod

=head1 NAME

Footprintless::Localhost - A localhost alias resolver

=head1 VERSION

version 1.25

=head1 DESCRIPTION

Provides a I<fairly> thorough attempt to determine if a supplied hostname
is an alias for localhost (resolves to the same physical machine).  This
can be useful in determining if local commands can be used in place of
remote commands.  This is primarily used by the 
L<Footprintless::CommandOptionsFactory> to create appropriate command
options for configured entities.

=head1 CONSTRUCTORS

=head2 new(%options)

Constructs a new C<Footprintless::Localhost> preconfigured with the
default aliases (C<localhost>, C<127.0.0.1>). The available options are:

=over 4

=item aliases

An initial set of preconfigured aliases that should resolve to localhost.

=item empty

Sets the value that will be returned if C<is_alias> is called with a 
I<falsey> value.

=item none

Stops the constructor from initializing the default aliases: 
C<localhost>, C<127.0.0.1>.

=back

=head1 METHODS

=head2 is_alias($hostname)

Returns a I<truthy> value if C<$hostname> is an alias for localhost.

=head2 is_loaded($source)

Returns a I<truthy> value if C<$source> has already been loaded.  Each
source is loaded using the C<load_$source> method.

=head2 load_all()

Loads aliases from all sources.

=head2 load_etc_hosts()

Loads aliases from the C</etc/hosts> file.

=head2 load_hostfqdn()

Loads aliases from the C<hostfqdn> command.

=head2 load_hostname()

Loads aliases from the C<hostname> command.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless::CommandOptionsFactory|Footprintless::CommandOptionsFactory>

=back

=cut
