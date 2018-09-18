package Group::Git::Cmd::Todo;

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
use Path::Tiny;
use Getopt::Alt;

our $VERSION = version->new('0.0.4');

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
        'verbose|v+',
        'quiet|q!',
    ]
);

my $todo = '';
sub todo {
    my ($self, $name) = @_;

    return unless -d $name;

    $opt->process if !%{ $opt->opt || {} };

    local $CWD = $name;

    return if !-f 'TODO.md';

    $todo .= "\n# $name\n\n" . path('TODO.md')->slurp;

    return;
}

sub todo_end {
    print $todo;

    return;
}

1;

__END__

=head1 NAME

Group::Git::Cmd::Todo - Group-Git tools to show combined markdown TODOs

=head1 VERSION

This documentation refers to Group::Git::Cmd::Todo version 0.0.4

=head1 SYNOPSIS

   use Group::Git::Cmd::Todo;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Adds the sub-command C<todo> to C<group-git>, it concatenates all the
C<TODO.md> files so you can view a summary of things to do.

=head1 SUBROUTINES/METHODS

=head2 C<todo ($name)>

Reads the TODO.md file from the repository C<$name>.

=head2 C<todo_end ()>

Returns the concatenated TODO.md contents for presentation.

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
