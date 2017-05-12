package Hubot::Scripts::storable;
$Hubot::Scripts::storable::VERSION = '0.1.10';
use strict;
use warnings;
use Storable;

sub load {
    my ( $class, $robot ) = @_;
    my $store = $ENV{HUBOT_STORABLE_PATH} || './hubot.dat';

    my $data = -f $store ? retrieve($store) : {};
    $robot->brain->mergeData($data);
    $robot->brain->on(
        'save',
        sub {
            my ( $e, $data ) = @_;
            store $data, $store;
        }
    );
}

1;

=head1 NAME

Hubot::Scripts::storable

=head1 VERSION

version 0.1.10

=head1 SYNOPSIS

    storable: THIS IS NOT COMMAND
    storable: retrieve robot's brain at boot up time and save it at shutdown time

=head1 CONFIGURATION

=over

=item HUBOT_STORABLE_PATH

F<./hubot.dat> is default to use.

=back

=head1 SEE ALSO

L<Storable>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=cut
