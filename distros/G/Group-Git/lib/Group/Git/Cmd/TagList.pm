package Group::Git::Cmd::TagList;

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

our $VERSION = version->new('0.7.5');

requires 'repos';
requires 'verbose';

my $opt = Getopt::Alt->new(
    { help => __PACKAGE__, },
    [
        'verbose|v+',
        'count|c',
    ]
);

sub tag_list_start {
    my ($self) = @_;
    my ($conf) = $self->conf;
    my $out = '';

    local $ARGV;
    $opt->process;

    return if $opt->opt->verbose;

    # repository server generated tags aren't available until repos is called
    # so we call it here.
    $self->repos;

    for my $tag (sort keys %{ $conf->{tags} }) {
        my $count = $opt->opt->count ? ' (' . @{ $conf->{tags}{$tag} } . ')' : '';
        $out .= "$tag$count\n";
        if ($opt->opt->verbose) {
            for my $repo (sort @{ $conf->{tags}{$tag} }) {
                $out .= "  $repo\n";
            }
        }
    }

    return $out;
}

sub tag_list {
    my ($self, $name) = @_;
    my ($conf) = $self->conf;
    return unless -d $name;

    return if ! $opt->opt->verbose;

    my $out = '';
    for my $tag (sort keys %{ $conf->{tags} }) {
        if ( grep {/^$name$/} @{ $conf->{tags}{$tag} } ) {
            $out .= "  $tag\n";
        }
    }

    return $out;
}

1;

__END__

=head1 NAME

Group::Git::Cmd::TagList - Runs git status on a git project

=head1 VERSION

This documentation refers to Group::Git::Cmd::TagList version 0.7.5.

=head1 SYNOPSIS

   grou-git tag-list [-v|--verbose] [-c|--count]
   grou-git tag-list --help
   grou-git tag-list --man
   grou-git tag-list --version

  Options:
   -c --count       Show a count of repositories in each tag
   -v --verbose     Show the repositories in each tag
      --help        Show the help information
      --man         Show full documentation
      --version     Show the version information

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=over 4

=item C<tag_list_start ()>

Returns the list of all defined tags and if in verbose mode the repositories
who have that tag.

=item C<tag_list ($name)>

Does nothing.

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
