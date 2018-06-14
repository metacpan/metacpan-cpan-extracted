package Group::Git::Cmd::Sh;

# Created on: 2013-05-06 21:57:07
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo::Role;
use strict;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use File::chdir;
use Getopt::Alt;
use Path::Tiny;

our $VERSION = version->new('0.6.10');

requires 'repos';
requires 'verbose';

my $opt = Getopt::Alt->new(
    { help => __PACKAGE__, },
    [
        'file|f=s',
        'quote|q!',
        'interactive|i',
    ]
);

sub sh_start {
    $opt->process;

    if ( $opt->opt->file && -x $opt->opt->file ) {
        $opt->opt->file( '' . path($opt->opt->file)->absolute);
    }

    return;
}

sub sh {
    my ($self, $name) = @_;
    return unless -d $name;

    my $repo = $self->repos->{$name};

    local $CWD = $name;
    my $cmd
        = $opt->opt->file  ? $opt->opt->file
        : $opt->opt->quote ? join ' ', map { $self->shell_quote } @ARGV
        :                    join ' ', @ARGV;

    local $ENV{GROUP_GIT_NAME} = $name;

    if ($opt->opt->interactive) {
        system $cmd;
        return;
    }

    my $out = `$cmd`;

    return $out if $self->verbose;

    return if !$out || $out =~ /\A\s*\Z/xms;

    return $out;
}

1;

__END__

=head1 NAME

Group::Git::Cmd::Sh - Runs shell script in each git project

=head1 VERSION

This documentation refers to Group::Git::Cmd::Sh version 0.6.10.

=head1 SYNOPSIS

   group-get sh program ...
   group-git sh [--quote|-q] program ...

  OPTIONS:
   -q --quote   Quote the program arguments before running saves you from
                having to work out the next level quoting but stops you from
                using other shell options eg piping (|).
   -i --interactive
                Stops capturing STDOUT so that interactive programs will
                work as expected eg if program is bash this will let you
                see the results of commands run

=head1 DESCRIPTION

Run the program in each checked out git repository.

=head1 SUBROUTINES/METHODS

=over 4

=item C<sh ($name)>

Runs all the reset of the command line in each directory as a shell script.

=item C<sh_start ()>

Process the command line arguments for sh

=back

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
