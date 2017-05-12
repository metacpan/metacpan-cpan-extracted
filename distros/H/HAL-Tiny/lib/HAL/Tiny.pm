package HAL::Tiny;
use 5.008001;
use strict;
use warnings;

use JSON qw/encode_json/;

our $VERSION = "0.03";

sub new {
    my ($class, %args) = @_;

    my ($state, $links, $embedded)
        = @args{qw/state links embedded/};

    return bless +{
        state    => $state,
        links    => $links,
        embedded => $embedded,
    }, $class;
}

sub as_hash {
    my ($self) = @_;

    my %hash;

    if (my $state = $self->{state}) {
        %hash = %{ $self->{state} };
    }

    if (my $links = $self->{links}) {
        my $v = +{};
        for my $rel (keys %$links) {
            my $value = $links->{$rel};
            if (ref $value) {
                $v->{$rel} = $value;
            } else {
                $v->{$rel} = +{
                    href => $links->{$rel},
                }
            }
        }
        $hash{_links} = $v;
    }

    if (my $embedded = $self->{embedded}) {
        my $v = +{};
        for my $rel (keys %$embedded) {
            if (ref $embedded->{$rel} eq 'ARRAY') {
                my @hashed = map { $_->as_hashref } @{$embedded->{$rel}};
                $v->{$rel} = \@hashed;
            } else {
                $v->{$rel} = $embedded->{$rel}->as_hashref;
            }
        }
        $hash{_embedded} = $v;
    }

    return %hash;
}

sub as_hashref {
    +{ $_[0]->as_hash };
}

sub as_json {
    encode_json($_[0]->as_hashref);
}


1;
__END__

=encoding utf-8

=head1 NAME

HAL::Tiny - Hypertext Application Language Encoder

=head1 SYNOPSIS

    use HAL::Tiny;

    my $resource = HAL::Tiny->new(
        state => +{
            currentlyProcessing => 14,
            shippedToday => 20,
        },
        links => +{
            self => '/orders',
            next => '/orders?page=2',
            find => {
                href      => '/orders{?id}',
                templated => JSON::true,
            },
        },
        embedded => +{
            orders => [
                HAL::Tiny->new(
                    state => +{ id => 10 },
                    links => +{ self => '/orders/10' },
                ),
                HAL::Tiny->new(
                    state => +{ id => 11 },
                    links => +{ self => '/orders/11' },
                )
            ],
        },
    );

    $resource->as_json;

=head1 DESCRIPTION

HAL::Tiny is a minimum implementation of Hypertext Application Language(HAL).

=head1 METHODS

=over 4

=item B<new> - Create a resource instance.

    HAL::Tiny->new(%args);

%args are

=over 4

=item state

The hash of representing the current state.

=item links

The hash of links related to the current state.

=item embedded

The hash of embedded objects.
Each hash value must be an array of HAL::Tiny objects or a HAL::Tiny object.

=back

=item B<as_json> - Encode to json.

Encode to json string.

=back

=head1 LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yuuki Furuyama E<lt>addsict@gmail.comE<gt>

=cut

