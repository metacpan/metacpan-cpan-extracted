package Giovanni::Plugins::Hipchat;

use Mouse::Role;
use Data::Dumper;
use LWP::UserAgent;
use LWP::Protocol::https;

around 'send_notify' => sub {
    my ( $orig, $self, $ssh ) = @_;

    print "notify via HipChat\n";
    my @tos = split(/\s*,\s*/, $self->config->{hipchat_rooms});
    my $msg = $ENV{USER}
      . ' just ran a '
      . $self->config->{command} . ' for '
      . $self->config->{project} . ' on '
      . $ssh->get_host;
    my $ua = LWP::UserAgent->new();
    my $url = 'https://api.hipchat.com/v1/rooms/message?format=json&auth_token='.$self->config->{hipchat_token};
    foreach my $to (@tos){
        $ua->post($url, {
            room_id => $to,
            from => 'Giovanni',
            message => $msg,
            message_format => 'text',
            notify => 1,
            color => 'green',
        });
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Giovanni::Plugins::Hipchat

=head1 VERSION

version 1.12

=head1 AUTHOR

Lenz Gschwendtner <mail@norbu09.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by ideegeo Group Limited.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
