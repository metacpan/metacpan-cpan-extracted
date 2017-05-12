# ABSTRACT: Tools for performing code review using Git as the backend
package Git::Code::Review;
use strict;
use warnings;

our $VERSION = '2.6'; # VERSION

use App::Cmd::Setup -app;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Code::Review - Tools for performing code review using Git as the backend

=head1 VERSION

version 2.6

=head1 SYNOPSIS

This module installs a new command to allow you to perform a tracked code review
using a git repository as the storage and communication medium for the audit.

This is intended to be used as a B<post-commit> code review tool.

=head1 INSTALL

Recommended install with L<CPAN Minus|http://cpanmin.us>:

    cpanm Git::Code::Review

You can also use CPAN:

    cpan Git::Code::Review

This will take care of ensuring all the dependencies are satisfied and will install the scripts into the same
directory as your Perl executable.

=head2 USAGE

The utility ships with documentation.

    git-code-review help
    git-code-review tutorial

And each command has a basic overview of it's own options and uses.

    git-code-review help init
    git-code-review help select
    git-code-review help profile
    git-code-review help list
    git-code-review help pick
    git-code-review help comment
    git-code-review help fixed

=head2 SEE ALSO

    perldoc Git::Code::Review::Tutorial

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 CONTRIBUTORS

=for stopwords Daniel Ostermeier Dennis Kaarsemaker Rafael Garcia-Suarez Samit Badle Sawyer X Tigin Kaptanoglu

=over 4

=item *

Daniel Ostermeier <daniel.ostermeier@gmail.com>

=item *

Dennis Kaarsemaker <dennis@kaarsemaker.net>

=item *

Rafael Garcia-Suarez <rgs@consttype.org>

=item *

Samit Badle <Samit.Badle@gmail.com>

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Tigin Kaptanoglu <tigin.kaptanoglu@booking.com>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Git-Code-Review>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Git-Code-Review>

=back

=head2 Source Code

This module's source code is available by visiting:
L<https://github.com/reyjrar/Git-Code-Review>

=cut
