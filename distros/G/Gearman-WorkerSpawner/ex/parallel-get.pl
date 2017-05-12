#!/usr/bin/env perl

# This example illustrates how to include worker code inline with the main
# script. See comments marked INLINE for necessary tricks to make that work.

### Worker code ###

# INLINE: since this file will be compiled as a module in the worker, the
# worker code must go first

package Getter;

use strict;
use warnings;

use LWP::UserAgent;

use base 'Gearman::WorkerSpawner::BaseWorker';
use fields 'ua';

sub new {
    my Getter $self = fields::new(shift);
    $self->SUPER::new(@_);
    $self->{ua} = LWP::UserAgent->new;
    $self->register_method(get_url => \&get_url);
    return $self;
}

sub get_url {
    my Getter $self = shift;
    my $url = shift;
    $self->{config}{verbose} && warn "Requesting $url\n";
    return $self->{ua}->get($url);
}

package main;

# INLINE: if there's a caller() at top scope than this file was "use"d by
# WorkerSpawner to load the above package source, therefore bail now
return 1 if caller;

### Invoker code ###

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

GetOptions(
    'workers=i' => \(my $workers = 10),
    'verbose!'  => \(my $verbose),
    'help!'     => \(my $help),
) || pod2usage(1);
pod2usage(1) if $help;
pod2usage('No URLS provided') unless @ARGV;

# INLINE: Gearman::WorkerSpawner needs to be loaded after the caller() check
# above or worker subprocesses get unhappy when $0 is modified by
# WorkerSpawner; therefore use require instead of use
require Gearman::WorkerSpawner;

# start up some GET workers
my $spawner = Gearman::WorkerSpawner->new;
$spawner->add_worker(
    class         => 'Getter',
    caller_source => 1, # INLINE: this is required
    num_workers   => $workers,
    config        => { verbose => $verbose },
);
$spawner->wait_until_all_ready;

my %urls; # results will come back asynchronously so keep track of which have finished
sub mark_done {
    my $url = shift;
    $urls{$url}--;
    delete $urls{$url} if $urls{$url} <= 0;
    if (!%urls) {
        $verbose && warn "Finished\n";
        exit;
    }
}

for my $url (@ARGV) {
    $urls{$url}++;
    $verbose && warn "Adding job for $url\n";
    $spawner->run_method(get_url => $url, {
        on_complete => sub {
            my $response = shift;
            if ($response->is_success) {
                printf "ok  %3d %s\n", $response->code, substr $url, 0, 100;
            }
            else {
                printf "err %3d\n", $response->code;
            }
            mark_done($url);
        },
        on_fail => sub {
            mark_done($url);
        },
    });
}

$verbose && warn "Starting loop\n";
Danga::Socket->EventLoop();

__END__

=head1 NAME

parallel-get.pl - fetches URLs in parallel

=head1 SYNOPSIS

  perl parallel-get.pl [--workers 100] <url1> <url2> ...

=head1 DESCRIPTION

This script reads URLs from the comand line and dispatches Gearman workers to
do parallel HTTP GET requests on them.

=head1 OPTIONS

=over 4

=item --workers <num>

Number of workers to start with.

=item --[no-]verbose

Show verbose output. Default off.

=item --help

Show this help.

=back

=cut
