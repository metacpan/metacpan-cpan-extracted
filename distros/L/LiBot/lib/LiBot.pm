package LiBot;
use strict;
use warnings;
use utf8;

use 5.010000;

use version; our $VERSION = version->declare("v0.0.3");

use LiBot::Message;
use Log::Pony;

use Mouse;

has providers => (
    is => 'ro',
    default => sub { [] },
);

has handlers => (
    is => 'ro',
    default => sub { +[ ] },
);

has log_level => (
    is => 'ro',
    default => 'info',
);

has log => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        Log::Pony->new(log_level => $self->log_level)
    },
);

no Mouse;

use Module::Runtime;

sub register {
    my ($self, $re, $code) = @_;
    push @{$self->{handlers}}, [$re, $code];
}

sub load_provider {
    my ($self, $name, $args) = @_;
    push @{$self->{providers}}, $self->load_plugin('Provider', $name, $args);
}

sub load_plugin {
    my ($self, $prefix, $name, $args) = @_;

    my $klass = $name =~ s!^\+!! ? $name : "LiBot::${prefix}::$name";
    Module::Runtime::require_module($klass);
    $self->log->info("Loading $klass");
    my $obj = $klass->new($args || +{});
    $obj->init($self) if $obj->can('init');
    $obj;
}

sub handle_message {
    my ($self, $callback, $msg) = @_;

    for my $handler (@{$self->{handlers}}) {
        if (my @matched = ($msg->text =~ $handler->[0])) {
            $handler->[1]->($callback, $msg, @matched);
            # Handled well
            return 1;
        }
    }
    return 0; # Does not handled.
}

sub run {
    my $self = shift;

    for my $provider (@{$self->providers}) {
        $provider->run($self);
    }
}

1;
__END__

=head1 NAME

LiBot - The bot framework

=head1 DESCRIPTION

This is yet another bot framework. Please look L<libot.pl>

=head1 MOTIVATION

I need a bot framework supports Lingr and IRC.

=head1 AUTHOR

Tokuhiro Matsuno E<lt> tokuhirom @ gmail.com E<gt>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
