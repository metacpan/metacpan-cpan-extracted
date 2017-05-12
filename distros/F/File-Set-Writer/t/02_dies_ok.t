#!/usr/bin/perl
use warnings;
use strict;
# Disable extra testing for deficient development environments
BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0; }
use Test::More;
use File::Set::Writer;

sub dies_ok {
    my ( $code, $msg ) = @_;
    $msg ||= "";
    
    eval { $code->() };

    if ( ! $@ ) {
        ok( 0, "Failed dies_ok: $msg" );
    } else {
        ok( 1 );
    }
}

my $tests = [
    {
        args => {
            max_handles => "Hello World",
        },
        title => "Invalid max_handles",
    },
    {
        args => {
            max_files => "Hello World",
            max_handles => 100,
        },
        title => "Invalid max_files",
    },
    {
        args => {
            max_lines => "Hello World",
            max_handles => 100,
        },
        title => "Invalid max_lines",
    },
    {
        args => {
            expire_handles_batch_size => "Hello World",
            max_handles => 100,
        },
        title => "Invalid expire_handles_batch_size",
    },
    {
        args => {
            expire_files_batch_size => "Hello World",
            max_handles => 100,
        },
        title => "Invalid expire_files_batch_size",
    },
    {
        args => {
            max_files   => 500,
        },
        title => "Missing required max_handles",
    },

];

foreach my $test ( @$tests ) {
    dies_ok(sub { File::Set::Writer->new(%{$test->{args}}) }, $test->{title});
}

done_testing;
