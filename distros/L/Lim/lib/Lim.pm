package Lim;

use common::sense;
use Carp;

use YAML::Any ();

=encoding utf8

=head1 NAME

Lim - Framework for RESTful JSON/XML, JSON-RPC, XML-RPC and SOAP

=head1 VERSION

Version 0.20

=cut

our $VERSION = '0.20';
our $CONFIG = {
    log => {
        obj_debug => 0,
        rpc_debug => 0,
        debug => 0,
        info => 1,
        warn => 1,
        err => 1
    },
    prefix => ['', '/usr', '/usr/local'],
    rpc => {
        srv_listen => 10,
        timeout => 30,
        call_timeout => 300,
        skip_dns => 0,
        transport => {
            http => {
                host => undef,
                port => 5353
            }
        },
        protocol => {
            http => {
                webroot => '/usr/share/lim/html'
            }
        },
        tls => {
            method => 'any',
            verify => 1,
            verify_require_client_cert => 1,
            ca_path => '/etc/lim/ssl/certs'
        },
        json => {
            pretty => 0
        }
    },
    agent => {
        config_file => '',
        uri => []
    },
    cli => {
        history_length => 1000,
        history_file => defined $ENV{HOME} ? $ENV{HOME}.($ENV{HOME} =~ /\/$/o ? '' : '/').'.lim_history' : '',
        config_file => defined $ENV{HOME} ? $ENV{HOME}.($ENV{HOME} =~ /\/$/o ? '' : '/').'.limrc' : '',
        editor => $ENV{EDITOR},
        host => 'localhost',
        port => 5353,
        transport => 'http',
        protocol => 'rest'
    },
    plugin => {
        load_all => 1,
        load => {}
    }
};

=head1 SYNOPSIS

=over 4

use Lim;

=back

=head1 DESCRIPTION

L<Lim> provides a framework for calling plugins over multiple protocols.

It uses AnyEvent for async operations and SOAP::Lite, XMLRPC::Lite and JSON::XS
for processing protocol messages.

There are 3 parts in Lim that can work independenly, a Server part, a Client
part and a CLI part.

All plugins are also divded into these 3 parts and use the base classes
L<Lim::Component::Server>, L<Lim::Component::Client> and L<Lim::Component::CLI>.

The built in Server part is called L<Lim::Agent> and can be started with
lim-agentd. It will use L<Lim::Plugins> to load all available plugins on
the system and serve their Server part to L<Lim::Server> if available.

The built in CLI part is called L<Lim::CLI> and can be started with lim-cli.
It will use L<Lim::Plugins> to load all available plugins on the system and
use their CLI part if available.

=head1 METHODS

=over 4

=item Lim::OBJ_DEBUG

Semi constant sub that controls if object debugging information should sent to
the log.

=cut

sub OBJ_DEBUG { 1 }

=item Lim::RPC_DEBUG

Semi constant sub that controls if RPC debugging information should sent to the
log.

=cut

sub RPC_DEBUG { 1 }

=item Lim::DEBUG

Semi constant sub that controls if debugging information should sent to the log.

Common usage:
Lim::DEBUG and $self->{logger}->debug(...);

=cut

sub DEBUG { 1 }

=item Lim::INFO

Semi constant sub that controls if informational logs should sent to the log.

Common usage:
Lim::INFO and $self->{logger}->info(...);

=cut

sub INFO { 1 }

=item Lim::WARN

Semi constant sub that controls if warnings should sent to the log.

Common usage:
Lim::WARN and $self->{logger}->warn(...);

=cut

sub WARN { 1 }

=item Lim::ERR

Semi constant sub that controls if errors should sent to the log.

Common usage:
Lim::ERR and $self->{logger}->error(...);

=cut

sub ERR { 1 }

=item Lim::Config ->{}

Return a hash reference to the configuration.

=cut

sub Config (){ $CONFIG }

=item Lim::MergeConfig($config)

Try and merge the given hash reference C<$config> into Lim's configuration.

=cut

sub MergeConfig {
    if (ref($_[0]) eq 'HASH') {
        my @merge = ([$_[0], $CONFIG]);

        while (defined (my $merge = shift(@merge))) {
            my ($from, $to) = @$merge;
            foreach my $key (keys %$from) {
                if (exists $to->{$key}) {
                    unless (ref($from->{$key}) eq ref($to->{$key})) {
                        # TODO display what entry is missmatching
                        confess __PACKAGE__, 'Can not merge config, entries type missmatch';
                    }
                    if (ref($from->{$key}) eq 'HASH') {
                        push(@merge, [$from->{$key}, $to->{$key}]);
                        next;
                    }
                }
                if (ref($to->{$key}) eq 'ARRAY') {
                    push(@{$to->{$key}}, @{$from->{$key}});
                }
                else {
                    $to->{$key} = $from->{$key};
                }
            }
        }
    }
    return;
}

=item Lim::LoadConfig($filename)

Load the given configuration C<$filename> in YAML format and merge it into Lim's
configuration.

=cut

sub LoadConfig {
    my ($filename) = @_;

    if (defined $filename and -r $filename) {
        my $yaml;

        Lim::DEBUG and Log::Log4perl->get_logger->debug('Loading config ', $filename);
        eval {
            $yaml = YAML::Any::LoadFile($filename);
        };
        if ($@) {
            confess __PACKAGE__, ': Unable to read configuration file ', $filename, ': ', $@, "\n";
        }
        Lim::MergeConfig($yaml);
        return 1;
    }
    return;
}

=item Lim::LoadConfigDirectory($directory)

Load the given configuration in directory C<$directory> and merge it into Lim's
configuration.

=cut

sub LoadConfigDirectory {
    my ($directory) = @_;

    if (defined $directory and -r $directory and -x $directory and -d $directory) {
        unless(opendir(CONFIGS, $directory)) {
            confess __PACKAGE__, ': Unable to read configurations in directory ', $directory, ': ', $!, "\n";
        }

        foreach my $entry (sort readdir(CONFIGS)) {
            my $yaml;

            unless(-r $directory.'/'.$entry and $entry =~ /\.yaml$/o) {
                next;
            }

            Lim::DEBUG and Log::Log4perl->get_logger->debug('Loading config ', $entry, ' from directory ', $directory);
            eval {
                $yaml = YAML::Any::LoadFile($directory.'/'.$entry);
            };
            if ($@) {
                confess __PACKAGE__, ': Unable to read configuration file ', $entry, ' from directory ', $directory, ': ', $@, "\n";
            }
            Lim::MergeConfig($yaml);
        }
        closedir(CONFIGS);
        return 1;
    }
    return;
}

=item Lim::ParseOptions(@options)

Parse options given at command line and add them into configuration. Option
subgroups are seperated by . (for example log.obj_debug=0).

=cut

sub ParseOptions {
    foreach my $option (@_) {
        my ($name, $value) = split(/=/o, $option, 2);
        unless ($name and defined $value) {
            confess __PACKAGE__, ': Invalid or unknown option: ', $option, "\n";
        }

        my @parts = split(/\./o, $name);
        my $ref = $CONFIG;
        while (defined(my $part = shift(@parts))) {
            unless (scalar @parts) {
                if ($part =~ /^(.+)\[\]$/o) {
                    $part = $1;

                    if (exists $ref->{$part}) {
                        if (ref($ref->{$part}) eq 'ARRAY') {
                            push(@{$ref->{$part}}, $value);
                        }
                        else {
                            $ref->{$part} = [ $ref->{$part}, $value ];
                        }
                    }
                    else {
                        $ref->{$part} = [ $value ];
                    }
                }
                else {
                    $ref->{$part} = $value;
                }
                last;
            }

            unless (exists $ref->{$part}) {
                $ref->{$part} = {};
            }
            $ref = $ref->{$part};
        }
    }
}

=item Lim::UpdateConfig

Used after L<LoadConfig> and/or L<LoadConfigDirectory> to update and do post
configuration tasks.

=cut

sub UpdateConfig {
    foreach my $key (keys %{$CONFIG->{log}}) {
        {
            no warnings;
            eval 'sub '.uc($key).' {'.($CONFIG->{log}->{$key} ? '1' : '0').'}';
        }
    }
}

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim
