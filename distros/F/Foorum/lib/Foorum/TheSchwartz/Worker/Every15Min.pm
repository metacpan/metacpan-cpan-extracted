package Foorum::TheSchwartz::Worker::Every15Min;

use strict;
use warnings;
our $VERSION = '1.001000';
use base qw( TheSchwartz::Moosified::Worker );
use Data::Dump qw/dump/;
use Foorum::SUtils qw/schema/;
use Foorum::Logger qw/error_log/;

sub work {
    my $class = shift;
    my $job   = shift;

    my @args = $job->arg;

    my $schema = schema();

    # remove user_online data
    $schema->resultset('UserOnline')
        ->search( { last_time => { '<', time() - 1200 }, } )->delete;

    $job->completed();
}

1;
__END__

=pod

=head1 NAME

Foorum::TheSchwartz::Worker::Every15Min - For those cron jobs every 15 minutes

=head1 SYNOPSIS

  # check bin/cron/TheSchwartz_client.pl and bin/cron/TheSchwartz_worker.pl for usage

=head1 DESCRIPTION

=over 4

=item remove user_online with where last_time < time() - 1200

=back

=head1 SEE ALSO

L<TheSchwartz>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
