package FSM::Tiny;

# http://www.crsr.net/Programming_Languages/PerlAutomata.html
use strict;
use warnings;

our $VERSION = '0.03';
our $DEBUG = 0;

use Class::Accessor::Lite;

my %Defaults = (
    current  => '',
    (map { $_ => {} } qw/rules context/),
    (map { $_ => sub {} } qw/on_enter on_exit on_transition/)
);

Class::Accessor::Lite->mk_accessors(keys %Defaults);

sub new {
    my $package = shift;
    my %args = $_[1] ? %{ @_ } : %{ $_[0] };
    my $self = bless +{ %Defaults, %args }, $package;

    for my $key (keys %{ $self->rules }) {
        my $s = $self->rules->{$key};
        if (my $r = ref $s) {
            if ($r eq 'ARRAY') {
                $self->register($key, @$s);
            }
            elsif ($r eq 'CODE') {
                $self->register($key, $s);
            }
        }
        else {
            delete $self->rules->{$key};
        }
    }

    return $self;
}

sub _log { warn "[FSM::Simele DEBUG] ".join(' ', @_) . "\n" if $DEBUG }

sub register {
    my $self = shift;
    my ($key, $code, $guards) = @_;
    $self->current($key) unless $self->current;
    $guards ||= [];
    _log("register: ${key}");
    $self->rules->{$key} = FSM::Tiny::State->new(
        code   => $code,
        guards => $guards
    );
}

sub unregister {
    my ($self, $key) = @_;
    _log("unregister: ${key}");
    delete $self->rules->{$key};
}

sub step {
    my $self = shift;
    my $st = $self->rules->{$self->current} or return;
    $st->run($self->context);
    my $next = $st->next($self->context) or return;
    $self->current($next);
    _log("next -> " . $self->current);
    return 1;
}

sub run {
    my $self = shift;
    $self->context(+{ %{ $self->context }, %{ $_[0] || {} } });
    local $_ = $self->context;
    $self->on_enter->($self->context);
    while (1) {
        if (!@{$self->rules->{$self->current}{guards}}) {
            $self->step;
            last;
        }
        $self->step or last;
        $self->on_transition->($self->context);
    }
    $self->on_exit->($self->context);
    $self;
}

package FSM::Tiny::State;

sub new {
    my $package = shift;
    my %args = @_;
    my @guards = @{ $args{guards} || [] };
    my @list;
    while (@guards) {
        my ($key, $code) = splice @guards, 0, 2;
        push @list, FSM::Tiny::Guard->new(
            key  => $key,
            code => (ref($code) || '') ne 'CODE' ? sub { $code } : $code
        );
    }
    $args{guards} = \@list;
    bless \%args, $package;
}

sub next {
    my ($self, $context) = @_;
    for my $guard (@{ $self->{guards} }) {
        return $guard->key if $guard->check($context);
    }
    return '';
}

sub run {
    my ($self, $context) = @_;
    local $_ = $context;
    $self->{code}->($context);
}

package FSM::Tiny::Guard;

sub key { shift->{key} }

sub code { shift->{code} }

sub new {
    my $package = shift;
    my %args = @_;
    bless +{ key  => '', code => sub { 1 }, %args }, $package;
}

sub check {
    my ($self, $context) = @_;
    return $self->code->($context);
}

1;
__END__

=head1 NAME

FSM::Tiny - tiny implementation of finite state machine

=head1 VERSION

This document describes FSM::Tiny version 0.03.

=head1 SYNOPSIS

    use FSM::Tiny;
    
    my $fsm = FSM::Tiny->new({
        on_enter => sub {
            $_->{count} = 0;
        }
    });
    
    $fsm->register(init => sub {}, [
        add => sub { $_->{count} < 20 },
        end => sub { $_->{count} >= 20 }
    ]);
    
    $fsm->register(add => sub { ++$_->{count} }, [
        init => 1
    ]);
    
    $fsm->register(end => sub { $_->{count} *= 5 });
    
    $fsm->run;

    print $fsm->context->{count}; # => 100


=head1 DESCRIPTION

This module is tiny implementation of finite state machine.
this provides more simpler interface and code than any cpan's FSM::* modules.

=head2 ATTRIBUTES

=head3 C<< current >>

define current state name for this machine.

=head3 C<< rules >>

same as register function.

=head3 C<< context >>

this is global variable of machine.
in state behavior(as function) and guard function, it is read as $_

=head3 C<< on_enter >>

it calls when machine transitions start.

=head3 C<< on_transition >>

it calls in between transitions.

=head3 C<< on_exit >>

it calls when machine transitions end.

=head2 METHODS

=head3 C<< new(%args) >>

you can define all rules and attributes in this initializer.

=head3 C<< register($state_name => $state_fn, [%conditions]) >>

registering state, state behavior(as function), and conditions for transition.
%conditions is defined follows:

    [
      destination1 => sub { !!it_should_move_to_destination1_or_not() },
      destination2 => sub { !!it_should_move_to_destination2_or_not() }
    ]

=head3 C<< step >>

it run one transition.

=head3 C<< run >>

it makes run until transitions end.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

<Taiyoh Tanaka> E<lt><sun.basix@gmail.com>E<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, <Taiyoh Tanaka>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
