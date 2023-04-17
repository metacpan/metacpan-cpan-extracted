package JIP::Spy::Events;

use strict;
use warnings;
use version 0.77;

use Carp qw(croak);
use Scalar::Util qw(blessed reftype);
use English qw(-no_match_vars);

use JIP::Spy::Event;

our $VERSION = version->declare('v0.0.3');
our $AUTOLOAD;

sub new {
    my ( $class, %param ) = @ARG;

    my $state = {
        on_spy_event => {},
        events       => [],
        times        => {},
        skip_methods => {},
        want_array   => 0,
    };

    if ( $param{want_array} ) {
        $state->{want_array} = 1;
    }

    if ( my $skip_methods = $param{skip_methods} ) {
        foreach my $method_name ( @{$skip_methods} ) {
            $state->{skip_methods}->{$method_name} = undef;
        }
    }

    return bless $state, $class;
} ## end sub new

sub events {
    my ($self) = @ARG;

    return $self->{events};
}

sub times {
    my ($self) = @ARG;

    return $self->{times};
}

sub want_array {
    my ($self) = @ARG;

    return $self->{want_array};
}

sub skip_methods {
    my ($self) = @ARG;

    return $self->{skip_methods};
}

sub clear {
    my ($self) = @ARG;

    @{ $self->events() } = ();
    %{ $self->times() }  = ();

    return $self;
}

sub on_spy_event {
    my ( $self, %declarations ) = @ARG;

    if (%declarations) {
        $self->{on_spy_event} = \%declarations;
    }

    return $self->{on_spy_event};
}

sub AUTOLOAD {
    my ( $self, @arguments ) = @ARG;

    if ( !blessed $self ) {
        croak q{Can't call "AUTOLOAD" as a class method};
    }

    my ($method_name) = $AUTOLOAD =~ m{^ .+ :: ([^:]+) $}x;

    undef $AUTOLOAD;

    return $self->_handle_event(
        method_name => $method_name,
        arguments   => \@arguments,
        want_array  => wantarray,
    );
}

sub isa {
    no warnings 'misc';
    goto &UNIVERSAL::isa;
}

sub can {
    my ( $self, $method_name ) = @ARG;

    if ( blessed $self ) {
        no warnings 'misc';
        goto &UNIVERSAL::can;
    }
    else {
        my $code;
        no warnings 'misc';
        $code = UNIVERSAL::can( $self, $method_name );

        return $code;
    }
}

sub DOES {
    # DOES is equivalent to isa by default
    goto &isa;
}

sub VERSION {
    no warnings 'misc';
    goto &UNIVERSAL::VERSION;
}

sub DESTROY { }

sub _handle_event {
    my ( $self, %param ) = @ARG;

    return $self if exists $self->skip_methods()->{ $param{method_name} };

    {
        my %event = (
            method    => $param{method_name},
            arguments => $param{arguments},
        );

        if ( $self->want_array() ) {
            $event{want_array} = $param{want_array};
        }

        push @{ $self->events() }, \%event;
    }

    my $times = $self->times()->{ $param{method_name} } // 0;
    $times += 1;
    $self->times()->{ $param{method_name} } = $times;

    my $on_spy_event = $self->on_spy_event()->{ $param{method_name} };

    return $self if !$on_spy_event;

    if ( ( reftype($on_spy_event) || q{} ) ne 'CODE' ) {
        croak sprintf(
            q{"%s" is not a callback},
            $param{method_name},
        );
    }

    my $event = JIP::Spy::Event->new(
        method     => $param{method_name},
        arguments  => $param{arguments},
        want_array => $param{want_array},
        times      => $times,
    );

    return $on_spy_event->( $self, $event );
} ## end sub _handle_event

1;

__END__

=head1 NAME

JIP::Spy::Events - the most basic function spy ability

=head1 VERSION

This document describes L<JIP::Spy::Events> version C<v0.0.3>.

=head1 SYNOPSIS

Testing with L<Test::More>:

    use Test::More;

    use_ok 'JIP::Spy::Events';

    my $spy_events = JIP::Spy::Events->new();

    is_deeply $spy_events->events(), [];
    is_deeply $spy_events->times(), {};

    is $spy_events->foo(),   $spy_events;
    is $spy_events->foo(42), $spy_events;

    is_deeply $spy_events->events(), [
        { method => 'foo', arguments => [] },
        { method => 'foo', arguments => [42] },
    ];

    is_deeply $spy_events->times(), { foo => 2 };

    is $spy_events->clear(), $spy_events;

    is_deeply $spy_events->events(), [];
    is_deeply $spy_events->times(), {};

    done_testing();

Testing with L<Test::More>, and want_array is turning on:

    use Test::More;

    use_ok 'JIP::Spy::Events';

    my $spy_events = JIP::Spy::Events->new( want_array => 1 );

    $spy_events->foo();
    scalar $spy_events->foo();
    ( () = $spy_events->foo() );

    is_deeply $spy_events->events(), [
        { method => 'foo', arguments => [], want_array => undef },
        { method => 'foo', arguments => [], want_array => q{} },
        { method => 'foo', arguments => [], want_array => 1 },
    ];

    done_testing();

FizzBuzz example:

    use Test::More;

    use_ok 'JIP::Spy::Events';

    my $spy_events = JIP::Spy::Events->new();

    $spy_events->on_spy_event(
        just_do_it => sub {
            my ($spy, $event) = @_;

            my $attempt = $event->arguments()->[0];

            return (
                !($attempt % 3)  ? 'Fizz' :
                !($attempt % 5)  ? 'Buzz' :
                $attempt
            );
        },
    );

    my @results = map { $spy_events->just_do_it($_) } 1 .. 5;

    is_deeply \@results, [
        1,
        2,
        'Fizz',
        4,
        'Buzz',
    ];

    done_testing();

=head1 ATTRIBUTES

L<JIP::Spy::Events> implements the following attributes.

=head2 events

    $arrayref = $spy_events->events();

Returns an array of all the calls to the spied module.

=head2 times

    $hashref = $spy_events->times();

Returns a hash where keys are method names, and values are the number of times the method has been called.

=head2 want_array

    $bool = $spy_events->want_array(); # undef/1/q{}

Track (or not track) invocation context. Disabled by default.

=head2 on_spy_event

    $spy_events->on_spy_event( name => sub {...} );

Declare one or more subroutines in the spied module.

=head1 SUBROUTINES/METHODS

=head2 new

    my $spy_events = JIP::Spy::Events->new();

Build new L<JIP::Spy::Events> object.

=head2 clear

    $spy_events->clear();

=head1 DIAGNOSTICS

None.

=head1 DEPENDENCIES

Perl 5.10.1 or later.

=head1 CONFIGURATION AND ENVIRONMENT

L<JIP::Spy::Events> requires no configuration files or environment variables.

=head1 SEE ALSO

L<Sub:Spy>, L<Module::Spy>

=head1 AUTHOR

Volodymyr Zhavoronkov, C<< <flyweight at yandex dot ru> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019-2023 Volodymyr Zhavoronkov.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut


