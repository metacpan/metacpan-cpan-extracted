#!/usr/bin/perl

# Created on: 2013-09-18 20:53:18
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Getopt::Alt qw/get_options/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use FindBin qw/$Bin/;
use Path::Tiny;

our $VERSION = version->new('0.0.1');
my ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;

main();
exit 0;

sub main {

    my ($opt) = get_options(
        {
            helper        => 1,
            auto_complete => \&auto,
        },
        [
            'out|o=s',
            'dir|d=s',
        ],
    );

    # do stuff here


    return;
}

sub auto {
    my ($option, $auto, $errors ) = @_;
}

__DATA__

=head1 NAME

eg/auto-complete.pl - Example auto-completion script run . eg/auto-complete.sh
first for bash auto completion

=head1 VERSION

This documentation refers to eg/auto-complete.pl version 0.0.1

=head1 SYNOPSIS

   eg/auto-complete.pl [option]

 OPTIONS:
  -o --out[=]str    Output string
  -d --dir[=]dir    A directory

  -v --verbose      Show more detailed option
     --version      Prints the version information
     --help         Prints this help information
     --man          Prints the full documentation for eg/auto-complete.pl

=head1 DESCRIPTION

This example script (along with the bash script eg/auto-complete.sh) show
how to add auto completion to a program using L<Getopt::Alt> and BASH.

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
