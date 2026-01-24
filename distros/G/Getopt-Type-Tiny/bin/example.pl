#!/usr/bin/env perl

# PODNAME: example.pl - Example of Getopt::Type::Tiny

use v5.40.0;
use lib 'lib';
use Getopt::Type::Tiny qw(get_opts Str Int);
use Data::Printer;

unless (@ARGV) {
    local @ARGV = qw(--foo value_of_foo --bar 12 --verbose);
}

my %options = get_opts(
    foo => { isa => Str },
    bar => { isa => Int, default => 42 },
    'verbose|v',    # defaults to Bool
);
p %options;

__END__

=pod

=encoding UTF-8

=head1 NAME

example.pl - Example of Getopt::Type::Tiny

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Getopt::Type::Tiny qw(get_opts Str Int);
    my %opts = get_opts(
        foo => { isa => Str },
        bar => { isa => Int, default => 42 },
        'verbose|v', # defaults to Bool
    );
    
    # %opts now contains the parsed options:
    # (
    #    foo     => 'value of foo',
    #    bar     => 42,
    #    verbose => 1,
    # )

=head1 DESCRIPTION

This is a simple example of how to use Getopt::Type::Tiny to parse command line
options;

=head1 FUNCTIONS

No functions;

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
