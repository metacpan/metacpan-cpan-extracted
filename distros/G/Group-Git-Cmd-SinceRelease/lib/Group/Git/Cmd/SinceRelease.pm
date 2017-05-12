package Group::Git::Cmd::SinceRelease;

# Created on: 2013-05-20 09:03:03
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Moose::Role;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use File::chdir;
use Getopt::Alt;

our $VERSION = version->new('0.0.10');

my $opt = Getopt::Alt->new(
    {
        helper  => 1,
        help    => __PACKAGE__,
        default => {
            min => 1,
        },
    },
    [
        'min|min-commits|m=i',
        'name|n',
        'no_release|no-release',
        'released|r',
        'verbose|v+',
        'quiet|q!',
    ]
);

sub _num_sort {
    my $A = $a;
    $A =~ s/((0+)\d+)/sprintf "%03d", $2 eq '00' ? $1 : $2 eq '0' ? $1 * 10 : $1 * 100/egxms;
    my $B = $b;
    $B =~ s/((0+)\d+)/sprintf "%03d", $2 eq '00' ? $1 : $2 eq '0' ? $1 * 10 : $1 * 100/egxms;
    $A cmp $B;
}

sub since_release_start {
    $opt->process;
    return;
}

sub since_release {
    my ($self, $name) = @_;

    return unless -d $name;

    local $CWD = $name;

    # find the newest tag and count newer commits
    my @tags = sort _num_sort map {/(.*)$/; $1} `git tag | sort -n`;
    if ($opt->opt->no_release) {
        return "Never released" if !@tags;
        return;
    }
    elsif (!@tags) {
        return;
    }

    my ($sha, $time) = split /\s+/, `git log -n 1 --format=format:'%H %at' $tags[-1]`;

    my $format = @ARGV ? join(' ', @ARGV) : '--format=format:"  %s"';
    my @logged = `git log -n 100 $format $sha..HEAD`;

    if ($opt->opt->released) {
        return "Released!" if !@logged;
        return;
    }

    return if @logged < $opt->opt->min;
    my $text = $opt->opt->quiet ? '' : "Commits since last release ($tags[-1])";
    $text .= $opt->opt->name ? " ($tags[-1]): " : ': ';

    return $text . ($opt->opt->verbose ? "\n" . join '', @logged : scalar @logged);
}

1;

__END__

=head1 NAME

Group::Git::Cmd::SinceRelease - Gets the number of commits each repository is ahead of the last release

=head1 VERSION

This documentation refers to Group::Git::Cmd::SinceRelease version 0.0.10

=head1 SYNOPSIS

   group-git since-release [(-m|--min-commits) n] [-n|--name]
   group-git since-release --no-release
   group-git since-release (-r|--released)
   group-git since-release [options]

   Options:
    -m --min-commits[=]int
                    Set the minimum number of commits to be found since the
                    last release (ie tag) before the results are shown.
                    (Default 1)
    -n --name       Show the last release's name (ignored if --quiet used)
        --no-release
                    Show only repositories that have never been released (no tags)
    -r --released   Show repositories that are currently released.
    -q --quiet      Just show the number of commits since the last release
    -v --verbose    Show all repository results.
       --help       Show this documentation
       --man        Show full documentation

=head1 DESCRIPTION

The C<since-release> command reports the statuses of repositories relative to
their last release. Usually reporting the number of releases since the last
release but with the C<--released> option shows only with no new commits since
the last release. Also with the C<--no-release> option only repositories with
no tagged releases are reported.

=head1 SUBROUTINES/METHODS

=head2 C<since_release_start ()>

Initializes command line parameters.

=head2 C<since_release ($name)>

Calculates the number of commits since the last release (via the newest tag)

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<tag ($name)>

Does the work of finding tags

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

Copyright (c) 2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
