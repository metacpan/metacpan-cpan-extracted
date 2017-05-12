package Lim::RPC::Call;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);
use URI::Split ();

use Lim ();
use Lim::Error ();
use Lim::Util ();
use Lim::RPC ();
use Lim::RPC::Protocols ();
use Lim::RPC::Transport::Clients ();

use HTTP::Request ();
use HTTP::Response ();
use HTTP::Status ();

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=over 4

=item OK

=item ERROR

=back

=cut

our $VERSION = $Lim::VERSION;

sub OK (){ 1 }
sub ERROR (){ -1 }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {
        logger => Log::Log4perl->get_logger($class),
        status => 0
    };
    bless $self, $class;
    weaken($self->{logger});
    my $real_self = $self;
    weaken($self);

    $self->{plugin} = shift;
    $self->{call} = shift;
    $self->{call_def} = shift;
    $self->{component} = shift;
    my ($data, $cb, $args, $method, $uri);

    $args = {};
    if (scalar @_ == 1) {
        unless (ref($_[0]) eq 'CODE') {
            confess __PACKAGE__, ': Given one argument but its not a CODE callback';
        }

        $cb = $_[0];
    }
    elsif (scalar @_ == 2) {
        if (ref($_[0]) eq 'CODE') {
            $cb = $_[0];
            $args = $_[1];
        }
        elsif (ref($_[1]) eq 'CODE') {
            $data = $_[0];
            $cb = $_[1];
        }
        else {
            confess __PACKAGE__, ': Given two arguments but non are CODE callback';
        }
    }
    elsif (scalar @_ == 3) {
        unless (ref($_[1]) eq 'CODE') {
            confess __PACKAGE__, ': Given three argument but second its not a CODE callback';
        }

        $data = $_[0];
        $cb = $_[1];
        $args = $_[2];
    }
    elsif (scalar @_ > 3) {
        unless (ref($_[1]) eq 'CODE') {
            confess __PACKAGE__, ': Given three argument but second its not a CODE callback';
        }

        $data = shift;
        $cb = shift;
        $args = { @_ };
    }
    else {
        confess __PACKAGE__, ': Too many arguments';
    }

    unless (ref($args) eq 'HASH') {
        confess __PACKAGE__, ': Given an arguments argument but its not an hash';
    }

    unless (defined $self->{call}) {
        confess __PACKAGE__, ': No call specified';
    }
    unless (defined $self->{call_def} and ref($self->{call_def}) eq 'HASH') {
        confess __PACKAGE__, ': No call definition specified or invalid';
    }
    unless (blessed $self->{component} and $self->{component}->isa('Lim::Component::Client')) {
        confess __PACKAGE__, ': No component specified or not a Lim::Component::Client';
    }
    unless (defined $cb) {
        confess __PACKAGE__, ': No cb specified';
    }

    if (defined $args->{uri}) {
        my ($scheme, $auth, $path) = URI::Split::uri_split(delete $args->{uri});
        my ($transport, $protocol);

        if ($scheme =~ /^([a-z0-9_\-\.]+)\+([a-z0-9_\-\.\+]+)/o) {
            ($transport, $protocol) = ($1, $2);
        }
        else {
            confess __PACKAGE__, ': Invalid schema in uri '.$uri;
        }

        $uri = URI->new('', 'http');
        $uri->path($path);
        $uri->authority($auth);
        my ($user, $pass) = split(/:/o, $uri->userinfo);

        $self->{host} = $uri->host;
        $self->{port} = $uri->_port;
        $self->{user} = $user;
        $self->{pass} = $pass;
        $self->{path} = $uri->path;
        $self->{transport} = $transport;
        $self->{protocol} = $protocol;
    }
    else {
        foreach (qw(host port user pass path transport protocol)) {
            $self->{$_} = defined $args->{$_} ? delete $args->{$_} : Lim::Config->{cli}->{$_};
        }
    }
    $self->{cb} = $cb;

    foreach (qw(host transport protocol)) {
        unless (defined $self->{$_}) {
            confess __PACKAGE__, ': No '.$_.' specified';
        }
    }

    unless (defined ($self->{protocol_obj} = Lim::RPC::Protocols->instance->protocol($self->{protocol}))) {
        confess __PACKAGE__, ': Unsupported protocol '.$self->{protocol};
    }
    unless (defined ($self->{transport_obj} = Lim::RPC::Transport::Clients->instance->transport($self->{transport}))) {
        confess __PACKAGE__, ': Unsupported transport '.$self->{transport};
    }

    if (defined $data and ref($data) ne 'HASH') {
        confess __PACKAGE__, ': Data is not a hash';
    }
    if (exists $self->{call_def}->{in}) {
        undef $@;
        eval {
            Lim::RPC::V(defined $data ? $data : {}, $self->{call_def}->{in});
        };
        if ($@) {
            undef $@;
            eval {
                eval 'use Data::Dumper;';
                confess __PACKAGE__, ': Unable to verify data ', "\n",
                    Dumper(defined $data ? $data : {}), "\n",
                    Dumper($self->{call_def}->{in}), "\n",
                    $@;
            };
            if ($@) {
                confess __PACKAGE__, ': Unable to verify data';
            }
        }
    }
    elsif (defined $data and %$data) {
        confess __PACKAGE__, ': Data given without in parameter definition';
    }

    my $request;
    eval {
        $request = $self->{protocol_obj}->request(
            (map { $_ => $self->{$_} } qw(plugin call path)),
            data => $data
        );
    };
    if ($@ or !defined $request) {
        confess __PACKAGE__, ': Protocol request creation failed: '.(($@) ? $@ : 'Unknown');
    }

    $self->{component}->_addCall($self);
    $self->{transport_obj}->request(
        %$args,
        (map { $_ => $self->{$_} } qw(plugin call host port user pass)),
        request => $request,
        cb => sub {
            my (undef, $response) = @_;
            my $data;

            unless (defined $self) {
                return;
            }

            unless (blessed $response) {
                $self->{error} = Lim::Error->new(
                    message => 'Transport returned invalid response',
                    module => $self
                );
                $self->{status} = ERROR;
            }
            elsif ($response->isa('Lim::Error')) {
                $self->{error} = $response;
                $self->{status} = ERROR;
            }
            elsif ($response->isa('HTTP::Response')) {
                eval {
                    $data = $self->{protocol_obj}->response($response);
                };

                if ($@) {
                    $self->{error} = Lim::Error->new(
                        message => 'Protocol response failure: '.$@,
                        module => $self
                    );
                    $self->{status} = ERROR;
                    $data = undef;
                }
                elsif (blessed $data and $data->isa('Lim::Error')) {
                    $self->{error} = $data;
                    $self->{status} = ERROR;
                    $data = undef;
                }
                elsif (ref($data) ne 'HASH') {
                    $self->{error} = Lim::Error->new(
                        message => 'Protocol returned invalid data from response',
                        module => $self
                    );
                    $self->{status} = ERROR;
                    $data = undef;
                }
                else {
                    if (exists $self->{call_def}->{out}) {
                        eval {
                            Lim::RPC::V($data, $self->{call_def}->{out});
                        };
                        if ($@) {
                            $self->{error} = Lim::Error->new(
                                message => $@,
                                module => $self
                            );
                            $self->{status} = ERROR;
                            $data = undef;
                        }
                        else {
                            $self->{status} = OK;
                        }
                    }
                    elsif (%$data) {
                        $self->{error} = Lim::Error->new(
                            message => 'Invalid data return, does not match definition',
                            module => $self
                        );
                        $self->{status} = ERROR;
                        $data = undef;
                    }
                    else {
                        $self->{status} = OK;
                    }
                }
            }
            else {
                $self->{error} = Lim::Error->new(
                    message => 'Transport returned invalid response',
                    module => $self
                );
                $self->{status} = ERROR;
            }

            $self->{cb}->($self, $data);
            $self->{component}->_deleteCall($self);
        }
    );

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
}

=head2 Successful

=cut

sub Successful {
    $_[0]->{status} == OK;
}

=head2 Error

=cut

sub Error {
    $_[0]->{error};
}

=head2 ResetTimeout

=cut

sub ResetTimeout {
    if (exists $_[0]->{client}) {
        $_[0]->{client}->reset_timeout;
    }
}

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

1; # End of Lim::RPC::Call
