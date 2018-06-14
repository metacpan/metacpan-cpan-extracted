package Group::Git::Cmd::List;

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

our $VERSION = version->new('0.6.10');

requires 'repos';
requires 'verbose';

has repo_count => (
    is      => 'rw',
    default => 0,
);

my $opt = Getopt::Alt->new(
    { help => __PACKAGE__, },
    [
        'quiet|q',
        'verbose|v',
    ]
);

sub list_start {
    $opt->process;

    return;
}

sub list {
    my ($self, $name) = @_;
    return unless -d $name;

    $self->repo_count($self->repo_count + 1);

    return ' ';
}

sub list_end {
    my ($self) = @_;

    if ($opt->opt->verbose) {
        return "\nSummary:\nFound " . $self->repo_count . " repositories\n";
    }

    return;
}

1;

__END__

=head1 NAME

Group::Git::Cmd::List - Runs git status on a git project

=head1 VERSION

This documentation refers to Group::Git::Cmd::List version 0.6.10.


=head1 SYNOPSIS

   use Group::Git::Cmd::List;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=over 4

=item C<list ($name)>

Just prints C<$name> to STDERR if such a directory exists.

=item C<list_start ()>

Processes command line options

=item C<list_end ()>

If summary is asked for this returns the count of repositories found

=item C<repo_count ([$count])>

Gets/sets the count of repositories found.

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
