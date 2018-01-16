package Group::Git::Cmd::Stats;

# Created on: 2013-05-10 07:05:17
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use version;
use Moose::Role;
use Carp;
use List::Util qw/max/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use File::chdir;
use Path::Tiny;
use Getopt::Alt;
use YAML::Syck;

our $VERSION = version->new('0.0.3');

my $opt = Getopt::Alt->new(
    {
        helper  => 1,
        help    => __PACKAGE__,
        default => {
            by => 'name',
            of => 'commits',
        },
    },
    [
        'by|b=s',
        'of|o=s',
        'verbose|v+',
        'quiet|q!',
    ]
);

sub stats_start {
    $opt->process;

    return;
}

my $collected = {};
sub stats {
    my ($self, $name) = @_;

    return unless -d $name;

    $opt->process if !%{ $opt->opt || {} };

    my $dir      = path($CWD);
    my $stats    = $dir->path('.stats');
    my $log_file = $stats->path('error.log');

    local $CWD = $name;

    my $cache = $dir->path('.stats', $name . '.yml');
    $cache->parent->mkpath;
    my %stats;

    if ( -f $cache ) {
        %stats = %{ LoadFile($cache) };
    }

    open my $pipe, '-|', q{git log --format=format:"%H';'%ai';'%an';'%ae"};

    while (my $log = <$pipe>) {
        chomp $log;
        my ($id, $date, $name, $email) = split q{';'}, $log, 4;

        last if $stats{$id};

        # dodgy date handling but hay
        $date =~ s/\s.+$//;

        unlink $log_file if -f $log_file;
        open my $show, '-|', qq{git show '$id' 2> $log | grep -Pv '^[+][+][+]|^[-][-][-]' | grep -Pv '^[^-+]'};
        my ($added, $removed, $total, $lines) = (0, 0, 0, 0);
        while (my $change = <$show>) {
            $total = $change =~ /^[+]/ ? $added++ : $removed++;
            $lines++;
        }
        if ( -s $log_file ) {
            warn qq{git show $id 2> $log_file | grep -v '^[+][+][+]|^[-][-][-]' | grep -v '^[^-+]'\n};
            return;
        }

        $stats{$id} = {
            name    => $name,
            email   => $email,
            date    => $date,
            added   => $added,
            removed => $removed,
            lines   => $lines,
        };
    }

    DumpFile($cache, \%stats);

    $collected->{$name} = \%stats;

    return;
}

sub stats_end {
    if ( -d '.stats' ) {
        DumpFile('.stats/collated.yml', $collected);

        my $type = $opt->opt->by eq 'email' ? 'email'
            : $opt->opt->by eq 'name'       ? 'name'
            : $opt->opt->by eq 'date'       ? 'date'
            : $opt->opt->by eq 'total'      ? 'total'
            : $opt->opt->by eq 'repo'       ? ''
            :                                 die "Unknown --by '" . $opt->opt->by . "'! (must be one of email, name or date)\n";

        my $of = $opt->opt->of eq 'commits' ? 'commits'
            : $opt->opt->of eq 'additions'  ? 'added'
            : $opt->opt->of eq 'removals'   ? 'removed'
            :                                 die "Unknown --of '" . $opt->opt->of . "'! (must be one of commits, additions or removals)\n";

        my %stats;
        for my $repo (keys %{ $collected }) {
            for my $id (keys %{ $collected->{$repo} }) {
                $stats{ $collected->{$repo}{$id}{$type} // $repo } += $collected->{$repo}{$id}{$of} // 1;
            }
        }

        my @items = sort { $stats{$a} <=> $stats{$b} } keys %stats;
        my $max   = max map {length $_} @items;
        for my $item (@items) {
            printf "%-${max}s %d\n", $item, $stats{$item};
        }
    }

    return;
}

1;

__END__

=head1 NAME

Group::Git::Cmd::Stats - Group-Git tools to show statistics across many repositories

=head1 VERSION

This documentation refers to Group::Git::Cmd::Stats version 0.0.3

=head1 SYNOPSIS

   use Group::Git::Cmd::Stats;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Adds the stats command to L<Group::Git> which allows you to collect statistics
across many repositories.

=head1 SUBROUTINES/METHODS

=head2 C<stats ($name)>

Collects the stats for each repository.

=head2 C<stats_start ()>

Initializes stats

=head2 C<stats_end ()>

Outputs the stats results.

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
