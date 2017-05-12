package NinetyNineBottlesOfBeer;

use strict;
use warnings;
use Modern::Perl "2012";

use Moose;
with 'MediaCloud::JobManager::Job';

use Time::HiRes qw(usleep nanosleep);
use Data::Dumper;
use Readonly;

# in microseconds
Readonly my $SLEEP_BETWEEN_BOTTLES => 100000;

# Run job
sub run($;$)
{
    my ( $self, $args ) = @_;

    my $how_many_bottles = $args->{ how_many_bottles };
    $how_many_bottles ||= 100;

    # http://www.99-bottles-of-beer.net/language-perl-539.html
    foreach ( reverse( 1 .. $how_many_bottles ) )
    {
        my $s          = ( $_ == 1 ) ? "" : "s";
        my $one_less_s = ( $_ == 2 ) ? "" : "s";
        say STDERR "";
        say STDERR "$_ bottle$s of beer on the wall,";
        say STDERR "$_ bottle$s of beer,";
        say STDERR "Take one down, pass it around,";
        say STDERR $_ - 1, " bottle${one_less_s} of beer on the wall";

        # $self->set_progress( ( $how_many_bottles - $_ + 1 ), $how_many_bottles );

        usleep( $SLEEP_BETWEEN_BOTTLES );
    }
    say STDERR "";
    say STDERR "*burp*";

    say STDOUT "I think I'm done here.";
}

# Return a number of retries (0 for no retries)
sub retries()
{
    # The job will be attempted 4 times in total
    return 3;
}

# Won't publish results back to the client
sub publish_results()
{
    return 0;
}

sub configuration()
{
    my $configuration = MediaCloud::JobManager::Configuration->new();
    $configuration->broker( MediaCloud::JobManager::Broker::RabbitMQ->new() );
    return $configuration;
}

no Moose;    # gets rid of scaffolding

# Return package name instead of 1 or otherwise worker.pl won't know the name of the package it's loading
__PACKAGE__;
