package Group::Git::Cmd::Grep;

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

our $VERSION = version->new('0.7.7');

requires 'repos';
requires 'verbose';
requires 'shell_quote';

my $opt = Getopt::Alt->new(
    { help_package => __PACKAGE__, },
    [
        'text|a',
        'I',
        'textconv',
        'ignore-case|i',
        'word-regexp|w',
        'invert-match|v',
        'h',
        'H',
        'full-name',
        'extended-regexp|E',
        'basic-regexp|G',
        'perl-regexp|P',
        'fixed-strings|F',
        'line-number|n',
        'files-with-matches|l',
        'files-without-match|L',
        'open-files-in-pager|O=s',
        'null|z',
        'count|c',
        'all-match',
        'quiet|q',
        'max-depth=i',
        'color=s?',
        'no-color',
        'break',
        'heading',
        'show-function|p',
        'A=s',
        'B=s',
        'C=s',
        'function-context|W',
        'threads=s',
        'f=s',
        'e=s',
        'and',
        'or',
        'not',
        'exclude-standard!',
        'cached',
        'no-index',
        'untracked',
        'branches|b',
        'verbose',
    ]
);

sub grep_start {
    $opt->process;
    if ( ! @ARGV ) {
        $opt->_show_help(1, "Nothing to search!");
    }

    return;
}

sub grep {
    my ($self, $name) = @_;
    return unless -d $name;

    my $repo = $self->repos->{$name};

    local $CWD = $name;

    my $cmd = 'git grep';
    for my $arg ( keys %{ $opt->opt } ) {
        next if grep { $_ eq $arg } qw/verbose branches/;
        $cmd .= ( length $arg == 1 ? " -$arg" : " --$arg" ) . ( $arg eq 'max-depth' || $opt->opt->{$arg} ne 1 ? '=' . $opt->opt->{$arg} : '' );
    }

    my @argv = @ARGV;
    if ( @argv ) {
        $cmd .= ' -- ' . join ' ', map { $self->shell_quote($_) } @argv;
    }

    warn "$cmd\n" if $opt->opt->{verbose};
    return scalar `$cmd`;
}

1;

__END__

=head1 NAME

Group::Git::Cmd::Grep - Quick state of each repository (branch name and changes)

=head1 VERSION

This documentation refers to Group::Git::Cmd::Grep version 0.7.7.

=head1 SYNOPSIS

   group-git grep

=head1 DESCRIPTION

This command allows the quick finding out of state (i.e. the branch name and
weather there are uncommitted changes) for each repository.

=head1 SUBROUTINES/METHODS

=over 4

=item C<grep_start ()>

Initializes the command

=item C<grep ($name)>

Shows the repository branch and weather there are changes in it.

=item C<grep_start ()>

Process the command line arguments for grep

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
