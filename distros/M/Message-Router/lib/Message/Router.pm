package Message::Router;
$Message::Router::VERSION = '1.161240';
use strict;use warnings;
use Storable;
use Message::Match qw(mmatch);
use Message::Transform qw(mtransform);
require Exporter;
use vars qw(@ISA @EXPORT_OK $config);
@ISA = qw(Exporter);
@EXPORT_OK = qw(mroute mroute_config);

sub mroute_config {
    my $new_config;
    eval {
        $new_config = shift
            or die 'single argument must be a HASH reference';
        die 'single argument must be a HASH reference'
            if shift;
        die 'single argument must be a HASH reference'
            if not $new_config or not ref $new_config eq 'HASH';
        die "passed config must have an ARRAY or HASH 'routes' key"
            if not $new_config->{routes};
        if(     ref $new_config->{routes} ne 'ARRAY' and
                ref $new_config->{routes} ne 'HASH') {
            die "passed config must have an ARRAY or HASH 'routes' key"
        }
        if(ref $new_config->{routes} eq 'ARRAY') {
            foreach my $route (@{$new_config->{routes}}) {
                die "each route must be a HASH reference"
                    if not $route;
                die "each route must be a HASH reference"
                    if not ref $route eq 'HASH';
                die "each route has to have a HASH reference 'match' key"
                    if not $route->{match};
                die "each route has to have a HASH reference 'match' key"
                    if not ref $route->{match} eq 'HASH';
                if($route->{transform}) {
                    die "the optional 'transform' key must be a HASH reference"
                        if ref $route->{transform} ne 'HASH';
                }
                if($route->{forwards}) {
                    die "the optional 'forwards' key must be an ARRAY reference"
                        if ref $route->{forwards} ne 'ARRAY';
                    foreach my $forward (@{$route->{forwards}}) {
                        die 'each forward must be a HASH reference'
                            if not $forward;
                        die 'each forward must be a HASH reference'
                            if ref $forward ne 'HASH';
                        die "each forward must have a scalar 'handler' key"
                            if not $forward->{handler};
                        die "each forward must have a scalar 'handler' key"
                            if ref $forward->{handler};
                    }
                }
            }
        }
    };
    if($@) {
        die "Message::Router::mroute_config: $@\n";
    }
    $config = $new_config;
    return $config;
}

sub mroute {
    eval {
        my $message = shift or die 'single argument must be a HASH reference';
        die 'single argument must be a HASH reference'
            unless ref $message and ref $message eq 'HASH';
        die 'single argument must be a HASH reference'
            if shift;
        if(     $message->{static_forwards} and
                ref $message->{static_forwards} and
                ref $message->{static_forwards} eq 'ARRAY' and
                scalar @{$message->{static_forwards}}) {
            my $forward_recs = shift @{$message->{static_forwards}};
            delete $message->{static_forwards} unless scalar @{$message->{static_forwards}};
            die 'static_forwards: defined forward must be an ARRAY reference'
                if not ref $forward_recs or ref $forward_recs ne 'ARRAY';
            foreach my $forward_rec (@{$forward_recs}) {
                die 'static_forwards: defined forward must contain a forward that is a HASH reference'
                    if      not $forward_rec->{forward} or
                            not ref $forward_rec->{forward} or
                            ref $forward_rec->{forward} ne 'HASH';
                my $message = Storable::dclone $message;
                if($forward_rec->{log_history}) {
                    $forward_rec = Storable::dclone $forward_rec;
                    $message->{'.static_forwards_log'} = {
                        forward_history => []
                    } unless $message->{'.static_forwards_log'};
                    push @{$message->{'.static_forwards_log'}->{forward_history}}, $forward_rec;
                }
                if(     $forward_rec->{transform} and
                        ref $forward_rec->{transform} and
                        ref $forward_rec->{transform} eq 'HASH') {
                    mtransform($message, $forward_rec->{transform});
                }
                eval {
                    no strict 'refs';
                    $forward_rec->{forward}->{handler} = 'IPC::Transit::Router::handler'
                        unless $forward_rec->{forward}->{handler};
                    &{$forward_rec->{forward}->{handler}}(
                        message => $message,
                        forward => $forward_rec->{forward}
                    );
                };
                die "static_forwards: handler failed: $@" if $@;
            }
            return 1;
        }
        my @routes;
        if(ref $config->{routes} eq 'ARRAY') {
            @routes = @{$config->{routes}};
        } elsif(ref $config->{routes} eq 'HASH') {
            foreach my $order (sort { $a <=> $b } keys %{$config->{routes}}) {
                push @routes, $config->{routes}->{$order};
            }
        }
        ROUTE:
        foreach my $route (@routes) {
            my $did_short_circuit = eval {
                if(mmatch($message, $route->{match})) {
                    if($route->{transform}) {
                        mtransform($message, $route->{transform});
                    }
                    if($route->{forwards}) {
                        foreach my $forward (@{$route->{forwards}}) {
                            no strict 'refs';
                            &{$forward->{handler}}(
                                message => $message,
                                route => $route,
                                routes => $config->{routes},
                                forward => $forward
                            );
                        }
                    }
                    if(     $route->{'.router_control'} and
                            ref $route->{'.router_control'} eq 'HASH' and
                            $route->{'.router_control'}->{short_circuit}) {
                        return 1;
                    }
                }
                return 0;
            };
            if($@) {
                die "Message::Router::mroute: $@\n";
            }
            last if $did_short_circuit;
        }
    };
    if($@) {
        die "Message::Router::mmatch: $@\n";
    }
    return 1;
}
1;

__END__

=head1 NAME

Message::Router - Fast, simple message routing

=head1 SYNOPSIS

    use Message::Router qw(mroute mroute_config);

    sub main::handler1 {
        my %args = @_;
        #gets:
        # $args{message}
        # $args{route}
        # $args{routes}
        # $args{forward}
        print "$args{message}->{this}\n"; #from the transform
        print "$args{forward}->{x}\n";    #from the specific forward
    }

    mroute_config({
        routes => [
            {   match => {
                    a => 'b',
                },
                forwards => [
                    {   handler => 'main::handler1',
                        x => 'y',
                    },
                ],
                transform => {
                    this => 'that',
                },
            }
        ],
    });
    mroute({a => 'b'}); #prints 'that', and then 'y', per the handler1 sub

    mroute_config({
        routes => {
            10 => {
                match => {
                    a => 'b',
                },
                forwards => [
                    {   handler => 'main::handler1',
                        x => 'y',
                    },
                ],
                transform => {
                    this => 'that',
                },
            }
        ],
    });
    mroute({a => 'b'}); #prints 'that', and then 'y', per the handler1 sub
    #same as the ARRAY based, but it uses the HASH keys in numerical order

=head1 DESCRIPTION

This library allows fast, flexible and general message routing.

=head1 FUNCTIONS

=head2 mroute_config($config);

The config used by all mroute calls

=head2 mroute($message);

Pass $message through the config; this will emit zero or more callbacks.

=head1 TODO

A config validator.

Short-circuiting

More flexible match and transform configuration forms

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2012, 2013 Dana M. Diederich. All Rights Reserved.

=head1 AUTHOR

Dana M. Diederich <dana@realms.org>

=cut

