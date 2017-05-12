package Github::Hooks::Receiver::Declare;
use strict;
use warnings;

use Github::Hooks::Receiver;
use parent 'Exporter';

our @EXPORT = qw/receiver secret on/;

our $_RECEIVER;
sub receiver(&) {
    my $code = shift;
    local $_RECEIVER = Github::Hooks::Receiver->new;
    $code->();
    $_RECEIVER;
}

sub secret($) {
    die 'not in receiver block' unless $_RECEIVER;
    $_RECEIVER->{secret} = $_[0];
}

sub on($;$) {
    die 'not in receiver block' unless $_RECEIVER;
    $_RECEIVER->on(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Github::Hooks::Receiver::Declare - DSL interface of Github::Hooks::Receiver

=head1 SYNOPSIS

    use Github::Hooks::Receiver::Declare;

    my $receiver = receiver {
        secret 'secret1234'; # secret is optional, but strongly RECOMMENDED!
        on push => sub {
            my ($event, $req) = @_;
            warn $event->event;
            my $payload = $event->payload;
        };
    };
    $receiver->to_app;

=head1 DESCRIPTION

Github::Hooks::Receiver provides DSL interface of L<Github::Hooks::Receiver>.

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

