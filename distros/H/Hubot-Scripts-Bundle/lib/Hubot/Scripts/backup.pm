package Hubot::Scripts::backup;
$Hubot::Scripts::backup::VERSION = '0.1.10';
use strict;
use warnings;
use AnyEvent;

my $w;    # consider *WATCHER* lifetime

sub load {
    my ( $class, $robot ) = @_;

    $w = AnyEvent->timer(
        after    => 0,
        interval => $ENV{HUBOT_BACKUP_INTERVAL} || 60 * 60,
        cb       => sub { $robot->brain->save }
    );

    $robot->respond(
        qr/backup$/i,
        sub {
            $robot->brain->save;
            shift->send("OK, saved the robot's brain");
        }
    );
}

1;

=head1 NAME

Hubot::Scripts::backup

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    hubot backup - save robot's brain data to external storage immediately if used
    backup (this is *NOT COMMAND*) - save robot's brain data to external storage automatically if used; just work

=head1 CONFIGURATION

=over

=item * HUBOT_BACKUP_INTERVAL

C<3600>(1 hour) is default to use.

=back

=head1 SEE ALSO

=over

=item * L<Hubot::Scripts::redisBrain>

=back

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
