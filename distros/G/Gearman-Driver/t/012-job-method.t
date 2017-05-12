package Job;

use Moose;

has 'workload' => (
    default => '',
    is      => 'rw',
    isa     => 'Str',
);

package main;

use strict;
use warnings;
use Test::More tests => 5;
use FindBin;
use lib "$FindBin::Bin/lib";
use Gearman::Driver::Job::Method;
use Gearman::Driver::Worker::Base;

{
    my $worker = Gearman::Driver::Worker::Base->new();
    my $m      = Gearman::Driver::Job::Method->new(
        name => 'test',
        body => sub {
            my ( $self, $job, $workload ) = @_;
            return $workload;
        },
        worker => $worker,
    );
    my $result = $m->wrapper->( Job->new( workload => '123' ) );
    is( $result, 123, 'Basic result without any magic' );
}

{
    my $worker = Gearman::Driver::Worker::Base->new();
    $worker->meta->make_mutable;
    $worker->meta->add_method( encode => sub { my ( $self, $input ) = @_; return "<ENCODE>$input</ENCODE>" } );
    my $m = Gearman::Driver::Job::Method->new(
        encode => 'encode',
        name   => 'test',
        body   => sub {
            my ( $self, $job, $workload ) = @_;
            return $workload;
        },
        worker => $worker,
    );
    my $result = $m->wrapper->( Job->new( workload => '123' ) );
    is( $result, '<ENCODE>123</ENCODE>', 'Encoded result' );
}

{
    my $worker = Gearman::Driver::Worker::Base->new();
    $worker->meta->make_mutable;
    $worker->meta->add_method( decode => sub { my ( $self, $input ) = @_; return "<DECODE>$input</DECODE>" } );
    my $m = Gearman::Driver::Job::Method->new(
        decode => 'decode',
        name   => 'test',
        body   => sub {
            my ( $self, $job, $workload ) = @_;
            $workload =~ s/DECODE/decode/g;
            return $workload;
        },
        worker => $worker,
    );
    my $result = $m->wrapper->( Job->new( workload => '123' ) );
    is( $result, '<decode>123</decode>', 'Decoded result' );
}

{
    my $begin  = 0;
    my $end    = 0;
    my $worker = Gearman::Driver::Worker::Base->new();
    $worker->meta->make_mutable;
    $worker->meta->add_method( begin => sub { $begin++ } );
    $worker->meta->add_method( end   => sub { $end++ } );
    my $m = Gearman::Driver::Job::Method->new(
        decode => 'decode',
        name   => 'test',
        body   => sub {
        },
        worker => $worker,
    );
    $m->wrapper->( Job->new );
    is( $begin, 1, 'Begin called' );
    is( $end,   1, 'End called even though job method died' );
}
