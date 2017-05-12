#!/usr/bin/perl -w

use strict;
use warnings;
use List::Util qw/sum/;
use Test::More;
use Test::Warnings qw/warning/;
use Getopt::Alt qw/get_options/;

our $VERSION = 0.123;
my @data = data();

for my $data (@data) {
    for my $test ( @{ $data->{tests} } ) {
        local @ARGV = @{ $test->{argv} };

        if ( $test->{error} ) {
            my $error;
            my $warning = warning { eval { get_options( @{ $data->{args} } ) }; $error = $@; };
            $warning = '' if ref $warning eq 'ARRAY' && @$warning == 0;

            # error in windows where something is getting a permissions denied error
            $error = $error->[0] if ref $error eq 'ARRAY' && $error->[1] =~ /Permission denied/;

            like "$error", $test->{error}, "'$test->{name}': Fails as expected"
                or diag explain {
                    args => $data->{args},
                    ARGV => $test->{argv},
                    error => $error,
                    ERROR => "$error",
                    test => $test->{error}
                } and exit;
            like $warning, $test->{warning}, "'$test->{name}': Warns as expected"
                or diag explain {
                    args => $data->{args},
                    ARGV => $test->{argv},
                    warning => $warning,
                    WARNING => "$warning",
                    test => $test->{error}
                } and exit;
        }
        else {
            my $files = eval { get_options( @{ $data->{args} } ) };
            my $error = $@;
            ok !$error, "'$test->{name}': No errors" or diag "'$test->{name}' failed with: $error";
            is_deeply \@ARGV, $test->{results}, "'$test->{name}': Files returned correctly"
                or diag explain $files;
        }
    }
}

done_testing;

sub data {
    return (
        {
            args => [
                'test|t!',
            ],
            tests => [
                {
                    name    => 'Empty',
                    argv    => [],
                    results => [],
                },
                {
                    name    => 'with test',
                    argv    => [qw/-t -t/],
                    results => [],
                },
                {
                    name    => 'with file',
                    argv    => [qw/file/],
                    results => [qw/file/],
                },
                {
                    name    => 'with test and file',
                    argv    => [qw/-t file/],
                    results => [qw/file/],
                },
                {
                    name    => 'unknown option',
                    argv    => [qw/--unknown/],
                    warning => qr/Unknown option '--unknown'/,
                    error   => qr/ get_options [.][.][.]/,
                },
            ]
        },
        {
            args => [
                { data => [] },
                'test|t',
                'data|d=s@',
            ],
            tests => [
                {
                    name    => 'No args',
                    argv    => [],
                    results => [],
                },
                {
                    name    => 'with data',
                    argv    => [qw/-d data1 -d data2/],
                    results => [],
                },
                {
                    name    => 'Unknown arg -a',
                    argv    => [qw/-a/],
                    error   => qr/ get_options [.][.][.]/,
                    warning => qr/Unknown option '-a'/,
                },
            ]
        },
        {
            args => [
                {}, ['test|t', 'man', 'help', 'version']
            ],
            tests => [
                {
                    name    => '--help (will die)',
                    argv    => [qw/--help/],
                    error   => qr/ get_options [.][.][.]/,
                    warning => qr/^$/,
                },
                {
                    name    => '--man (will die)',
                    argv    => [qw/--man/],
                    error   => qr/ get_options [.][.][.]/,
                    warning => qr/^$/,
                },
                {
                    name    => '--version (will die)',
                    argv    => [qw/--version/],
                    error   => qr/Version = 0.123/,
                    warning => qr/^$/,
                },
                {
                    name    => 'no -h',
                    argv    => [qw/-h/],
                    error   => qr/ get_options [.][.][.]/,
                    warning => qr/Unknown option '-h'/,
                },
            ]
        },
    );
}

=head1 NAME

get_options.t - tests for get_options

=head1 SYNOPSIS

 get_options ...

=cut

