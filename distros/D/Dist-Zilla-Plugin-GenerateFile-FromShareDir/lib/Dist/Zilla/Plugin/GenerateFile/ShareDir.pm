use strict;
use warnings;
package Dist::Zilla::Plugin::GenerateFile::ShareDir;
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: (DEPRECATED) Create files in the repository or in the build, based on a template located in a dist sharedir

our $VERSION = '0.013';

use Moose;
extends 'Dist::Zilla::Plugin::GenerateFile::FromShareDir';
use namespace::autoclean;

before register_component => sub {
    warnings::warnif('deprecated',
        "!!! [GenerateFile::ShareDir] is deprecated and may be removed in a future release; replace it with [GenerateFile::FromShareDir]\n",
    );
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=for stopwords sharedir

=head1 NAME

Dist::Zilla::Plugin::GenerateFile::ShareDir - (DEPRECATED) Create files in the repository or in the build, based on a template located in a dist sharedir

=head1 VERSION

version 0.013

=head1 SYNOPSIS

In your F<dist.ini>:

    [GenerateFile::FromShareDir]
    ...

=head1 DESCRIPTION

THIS MODULE IS DEPRECATED. Please use
L<Dist::Zilla::Plugin::Generatefile::ShareDir> instead. it may be removed at a
later time (but not before April 2016).

In the meantime, it will continue working -- although with a warning.
Refer to the replacement for the full documentation.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-GenerateFile-FromShareDir>
(or L<bug-Dist-Zilla-Plugin-GenerateFile-FromShareDir@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-GenerateFile-FromShareDir@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
