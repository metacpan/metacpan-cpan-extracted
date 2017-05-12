package Lim::Plugin::Zonalizer::Collector;

use common::sense;

use Carp;
use Scalar::Util qw(blessed);
use Moose;
with 'MooseX::Getopt';

use Zonemaster;
use Zonemaster::Util ();
use Zonemaster::Logger::Entry;

use Net::LDNS;
use JSON::XS;

my $can_use_threads = eval 'use threads; use Thread::Queue; 1';

=encoding utf8

=head1 NAME

Lim::Plugin::Zonalizer::Collector - Collector that runs Zonemaster in multiple
threads.

=head1 VERSION

See L<Lim::Plugin::Zonalizer> for version.

=cut

our $VERSION = $Lim::Plugin::Zonalizer::VERSION;

our %numeric = Zonemaster::Logger::Entry->levels;

=head1 SYNOPSIS

  use Lim::Plugin::Zonalizer::Collector;

  Lim::Plugin::Zonalizer::Collector->new_with_options->run;

=head1 METHODS

=over 4

=item config

Name of configuration file to load.

=cut

has 'config' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    documentation => 'Name of configuration file to load.',
);

=item policy

Name of policy file to load.

=cut

has 'policy' => (
    is            => 'ro',
    isa           => 'Str',
    required      => 0,
    documentation => 'Name of policy file to load.',
);

=item sourceaddr

Local IP address that the test engine should try to send its requests from.

=cut

has 'sourceaddr' => (
    is            => 'ro',
    isa           => 'Maybe[Str]',
    required      => 0,
    default       => undef,
    documentation => 'Local IP address that the test engine should try to send its requests from.',
);

=item threads

Number of threads to start.

=cut

has 'threads' => (
    is            => 'ro',
    isa           => 'Num',
    required      => 0,
    default       => 5,
    documentation => 'Number of threads to start.',
);

=item debug

Send debug information to STDERR.

=cut

has 'debug' => (
    is            => 'ro',
    isa           => 'Bool',
    required      => 0,
    documentation => 'Send debug information to STDERR.'
);

=item run

Starts the collector, sets up the thread queues and creates all the threads
needed.

=cut

sub run {
    my ( $self ) = @_;

    $self->debug and say STDERR 'start';

    if ( $self->sourceaddr ) {
        Zonemaster->config->resolver_source( $self->sourceaddr );
    }

    if ( $self->policy ) {
        Zonemaster->config->load_policy_file( $self->policy );
    }

    if ( $self->config ) {
        Zonemaster->config->load_config_file( $self->config );
    }

    my ( $in_q, $out_q );

    if ( $can_use_threads ) {
        $in_q  = Thread::Queue->new;
        $out_q = Thread::Queue->new;

        my $threads = $self->threads;

        unless ( $threads > 0 ) {
            confess;
        }

        while ( $threads-- ) {
            $self->debug and say STDERR 'start thread';

            threads->create(
                sub {
                    my $json = JSON::XS->new->allow_blessed->convert_blessed->canonical;

                    $self->debug and say STDERR 'thread started';
                    while ( my $in = $in_q->dequeue ) {
                        $self->debug and say STDERR 'dequeued in';
                        $self->process( $json->decode( $in ), $out_q );
                    }
                }
            );
        }

        threads->create(
            sub {
                while ( my $out = $out_q->dequeue ) {
                    $self->debug and say STDERR 'dequeued out';
                    say $out;
                }
            }
        )->detach;
    }

    {
        my $json = JSON::XS->new->allow_blessed->convert_blessed->canonical;

        $self->debug and say STDERR 'waiting';
        while ( <STDIN> ) {
            $self->debug and say STDERR 'read: ', $_;
            my @in = $json->incr_parse( $_ );
            foreach my $in ( @in ) {
                unless ( $self->validate( $in ) ) {
                    $self->debug and say STDERR 'invalid in';
                    next;
                }

                $self->debug and say STDERR 'queued in';

                if ( $can_use_threads ) {
                    $in_q->enqueue( $json->encode( $in ) );
                }
                else {
                    $self->process( $in );
                }
            }
        }
    }

    $self->debug and say STDERR 'end';

    if ( $can_use_threads ) {
        $in_q->end;

        foreach ( threads->list ) {
            $_->join;
        }
    }

    return;
}

=item process

Process an analyze request.

=cut

sub process {
    my ( $self, $in, $out_q ) = @_;

    unless ( ref( $in ) eq 'HASH' ) {
        confess;
    }
    if ( $can_use_threads ) {
        unless ( blessed $out_q and $out_q->isa( 'Thread::Queue' ) ) {
            confess;
        }
    }

    my $json = JSON::XS->new->allow_blessed->convert_blessed->canonical;

    Zonemaster->reset;

    Zonemaster->config->ipv4_ok( $in->{ipv4} ? 1 : 0 );
    Zonemaster->config->ipv6_ok( $in->{ipv6} ? 1 : 0 );

    Zonemaster->logger->callback(
        sub {
            my ( $entry ) = @_;

            if ( $numeric{ uc $entry->level } >= $numeric{DEBUG} ) {
                $self->debug and say STDERR 'queued out';
                my $out = $json->encode(
                    {
                        _id       => $in->{id},
                        timestamp => $entry->timestamp,
                        module    => $entry->module,
                        tag       => $entry->tag,
                        level     => $entry->level,
                        $entry->args ? ( args => $entry->args ) : ()
                    }
                );

                if ( $can_use_threads ) {
                    $out_q->enqueue( $out );
                }
                else {
                    say $out;
                }
            }
        }
    );

    Zonemaster::Util::info(
        MODULE_VERSION => {
            module  => 'Zonemaster::Test::Basic',
            version => Zonemaster::Test::Basic->version
        }
    );
    foreach my $mod ( Zonemaster::Test->modules ) {
        $mod = 'Zonemaster::Test::' . $mod;
        Zonemaster::Util::info(
            MODULE_VERSION => {
                module  => $mod,
                version => $mod->version
            }
        );
    }

    my $domain = $self->to_idn( $in->{fqdn} );

    if ( exists $in->{ns} ) {
        my %ns;
        foreach ( @{ $in->{ns} } ) {
            my $idn = $self->to_idn( $_->{fqdn} );
            my @ips;

            if ( $_->{ip} ) {
                push @ips, $_->{ip};
            }
            else {
                push @ips, Net::LDNS->new->name2addr( $idn );
            }

            push @{ $ns{$idn} }, @ips;
        }
        if ( scalar %ns ) {
            Zonemaster->add_fake_delegation( $domain => \%ns );
        }
    }

    if ( exists $in->{ds} ) {
        Zonemaster->add_fake_ds( $domain => $in->{ds} );
    }

    if ( exists $in->{test} ) {
        foreach ( @{ $in->{test} } ) {
            if ( $_->{method} ) {
                Zonemaster->test_method( $_->{module}, $_->{method}, Zonemaster->zone( $domain ) );
            }
            else {
                Zonemaster->test_module( $_->{module}, $domain );
            }
        }
    }
    else {
        Zonemaster->test_zone( $domain );
    }

    Zonemaster::Util::info( MODULE_END => { module => 'Lim::Plugin::Zonalizer::Collector' } );

    return;
}

=back

=head1 PRIVATE METHODS

=over 4

=item to_idn

Converts input into an IDN string is its not ASCII and Net::LDNS has support for
IDN.

=cut

sub to_idn {
    my ( $self, $str ) = @_;

    if ( $str =~ m/^[[:ascii:]]+$/ ) {
        return $str;
    }

    if ( Net::LDNS::has_idn() ) {
        return Net::LDNS::to_idn( decode( $self->encoding, $str ) );
    }
    else {
        return $str;
    }
}

=item validate

Validates an input object.

=cut

sub validate {
    my ( $self, $in ) = @_;

    unless ( ref( $in ) eq 'HASH' ) {
        return;
    }
    foreach ( qw(id fqdn ipv4 ipv6) ) {
        unless ( defined $in->{$_} ) {
            return;
        }
    }
    if ( exists $in->{ns} ) {
        unless ( ref( $in->{ns} ) eq 'ARRAY' ) {
            return;
        }
        foreach my $ns ( @{ $in->{ns} } ) {
            unless ( ref( $ns ) eq 'HASH' ) {
                return;
            }
            foreach ( qw(fqdn) ) {
                unless ( defined $ns->{$_} ) {
                    return;
                }
            }
            foreach ( qw(ip) ) {
                if ( exists $ns->{$_} and !defined $ns->{$_} ) {
                    return;
                }
            }
        }
    }
    if ( exists $in->{ds} ) {
        unless ( ref( $in->{ds} ) eq 'ARRAY' ) {
            return;
        }
        foreach my $ds ( @{ $in->{ds} } ) {
            unless ( ref( $ds ) eq 'HASH' ) {
                return;
            }
            foreach ( qw(keytag algorithm type digest) ) {
                unless ( defined $ds->{$_} ) {
                    return;
                }
            }
        }
    }
    if ( exists $in->{test} ) {
        unless ( ref( $in->{test} ) eq 'ARRAY' ) {
            return;
        }
        foreach my $test ( @{ $in->{test} } ) {
            unless ( ref( $test ) eq 'HASH' ) {
                return;
            }
            foreach ( qw(module) ) {
                unless ( defined $test->{$_} ) {
                    return;
                }
            }
            foreach ( qw(method) ) {
                if ( exists $test->{$_} and !defined $test->{$_} ) {
                    return;
                }
            }
        }
    }
    return 1;
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry@gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-zonalizer/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::Zonalizer::Collector

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-zonalizer/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Jerry Lundström
Copyright 2015-2016 IIS (The Internet Foundation in Sweden)

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Lim::Plugin::Zonalizer::Collector
