package Group::Git::Cmd::State;

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

our $VERSION = version->new('0.7.3');

requires 'repos';
requires 'verbose';

my $opt = Getopt::Alt->new(
    { help => __PACKAGE__, },
    [
        'quiet|q',
    ]
);

sub state_start {
    $opt->process;

    return;
}

sub state {
    my ($self, $name) = @_;
    return unless -d $name;

    my $repo = $self->repos->{$name};
    my $cmd;

    local $CWD = $name;
    my $branch = `git rev-parse --abbrev-ref HEAD 2>&1`;
    chomp $branch;
    if ( $branch =~ /ambiguous argument 'HEAD'/ ) {
        $branch = 'initial commit';
    }
    my $status = `git status --porcelain 2>&1`;

    return $branch . ($status ? ' *' : '');
}

sub state_end {
    return "\n";
}

1;

__END__

=head1 NAME

Group::Git::Cmd::State - Quick state of each repository (branch name and changes)

=head1 VERSION

This documentation refers to Group::Git::Cmd::State version 0.7.3.

=head1 SYNOPSIS

   group-git state

=head1 DESCRIPTION

This command allows the quick finding out of state (i.e. the branch name and
weather there are uncommitted changes) for each repository.

=head1 SUBROUTINES/METHODS

=over 4

=item C<state ($name)>

Shows the repository branch and weather there are changes in it.

=item C<state_start ()>

Process the command line arguments for state

=item C<state_end ()>

For adding find new line

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
