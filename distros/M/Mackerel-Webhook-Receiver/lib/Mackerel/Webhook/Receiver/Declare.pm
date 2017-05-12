package Mackerel::Webhook::Receiver::Declare;
use strict;
use warnings;

use Mackerel::Webhook::Receiver;
use parent 'Exporter';

our @EXPORT = qw/receiver on/;

our $_RECEIVER;
sub receiver(&) {
    my $code = shift;
    local $_RECEIVER = Mackerel::Webhook::Receiver->new;
    $code->();
    $_RECEIVER;
}

sub on($;$) {
    die 'not in receiver block' unless $_RECEIVER;
    $_RECEIVER->on(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Mackerel::Webhook::Receiver::Declare - DSL interface of Mackerel::Webhook::Receiver

=head1 SYNOPSIS

    use Mackerel::Webhook::Receiver::Declare;

    my $receiver = receiver {
        on alert => sub {
            my ($event, $req) = @_;
            warn $event->event;
            my $payload = $event->payload;
        };
    };
    $receiver->to_app;

=head1 DESCRIPTION

Mackerel::Webhook::Receiver::Declare provides DSL interface of L<Mackerel::Webhook::Receiver>.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

