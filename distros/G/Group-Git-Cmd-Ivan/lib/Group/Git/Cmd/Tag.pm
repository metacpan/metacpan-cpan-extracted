package Group::Git::Cmd::Tag;

# Created on: 2013-05-10 07:05:17
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use version;
use Moose::Role;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use File::chdir;
use Term::ANSIColor qw/colored/;
use Getopt::Alt;

our $VERSION = version->new('0.0.3');

my $opt = Getopt::Alt->new(
    {
        helper => 1,
        help   => __PACKAGE__,
    },
    [
        'min|m',
        'verbose|v+',
    ]
);

sub tag {
    my ($self, $name) = @_;
    return unless -d $name;

    $opt->process if !%{ $opt->opt || {} };

    my $tag = shift @ARGV;

    my $repo = $self->repos->{$name};

    local $CWD = $name;
    my %tags;
    for my $tag (`git tag`) {
        chomp $tag;
        $tags{$tag}++;
    }
    my %branches;
    for my $branch (`git branch`) {
        chomp $branch;
        $branch =~ s/^.*\s//;
        $branches{$branch}++;
    }

    my $count  = 0;
    my $tagged = 0;
    my $i = 0;
    my @logs = `git log --format=format:'%h %d'`;
    my %logs;
    for (@logs) {
        $i++;
        chomp;
        my ($hash, $branc_tag) = split /\s[(]/, $_;
        $branc_tag ||= '';
        chop $branc_tag;
        my $tag = join ', ', grep { $tags{$_} } map {/^(?:tag:\s+)?(.*)/; $1}  split /,\s+/, $branc_tag;
        $count++;
        my $min = !$tagged;
        $tagged++ if $tag;

        $logs{$hash} = $tag ? $tag . colored(" ($count)", $min ? 'green' : '' ) : '';
        last if $tag && $opt->opt->min;
    }

    %logs
        = map {
            ( $_ => $logs{$_} );
        }
        grep {
            $logs{$_} && ( $tag ? $logs{$_} =~ /$tag/ : 1 )
        }
        keys %logs;

    return unless %logs;

    return join '', map {
        "$_ $logs{$_}\n"
    }
    sort {
        my $A = $logs{$a};
        my $B = $logs{$b};
        $A =~ s/(\d+)/sprintf '%06d', $1/eg;
        $B =~ s/(\d+)/sprintf '%06d', $1/eg;
        $B cmp $A
    }
    keys %logs;
}

1;

__END__

=head1 NAME

Group::Git::Cmd::Tag - Finds tags in each repository

=head1 VERSION

This documentation refers to Group::Git::Cmd::Tag version 0.0.3

=head1 SYNOPSIS

   group-git tag [options]

 Options:
    -m --min        Show only tag with minimum number of commits
    -v --verbose    Show more details about tags

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

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
