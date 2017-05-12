#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: lib/Dist/Zilla/Plugin/Hook.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Hook.
#
#   perl-Dist-Zilla-Plugin-Hook is free software: you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Hook is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Hook. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#pod =for :this This is C<Dist::Zilla::Plugin::Hook> module documentation. Read this if you are going to hack or
#pod extend C<Dist-Zilla-Plugin-Hook>.
#pod
#pod =for :those If you want to write C<Dist::Zilla> plugin directly in F<dist.ini>, read the L<manual|Dist::Zilla::Plugin::Hook::Manual>. General
#pod topics like getting source, building, installing, bug reporting and some others are covered in the
#pod F<README>.
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin consumes C<Hooker> role like all other C<Hook> plugins. However, this plugin I<never>
#pod executes its Perl code. Instead, it just stores it for later use. As of today, only C<Hook> plugin
#pod with C<prologue> name is actually used:
#pod
#pod     [Hook/prologue]
#pod         . = use autodie ':all';
#pod
#pod Such code will be executed just before each hook. Note again: C<Hook> itself does not execute its
#pod code; if there are no other hooks in F<dist.ini>, this code will never execute.
#pod
#pod BTW, C<Dist::Zilla> and CPAN do not handle well distributions with no main module. This is also a
#pod "main" module of C<Dist-Zilla-Plugin-Hook> distribution, to make C<Dist::Zilla> and C<CPAN> indexer happy.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Dist::Zilla>
#pod = L<Dist::Zilla::Plugin::Hook::Manual>
#pod = L<Dist::Zilla::Role::Hooker>
#pod
#pod =cut

package Dist::Zilla::Plugin::Hook;

use Moose;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: Write C<Dist::Zilla> plugin directly in F<dist.ini>
our $VERSION = 'v0.8.3'; # VERSION

with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::ErrorLogger' => { -version => 0.005 };
with 'Dist::Zilla::Role::Hooker';

__PACKAGE__->meta->make_immutable();

1;

#pod =head1 COPYRIGHT AND LICENSE
#pod
#pod Copyright (C) 2015, 2016 Van de Bugger
#pod
#pod License GPLv3+: The GNU General Public License version 3 or later
#pod <http://www.gnu.org/licenses/gpl-3.0.txt>.
#pod
#pod This is free software: you are free to change and redistribute it. There is
#pod NO WARRANTY, to the extent permitted by law.
#pod
#pod
#pod =cut

#   ------------------------------------------------------------------------------------------------
#
#   file: doc/what.pod
#
#   This file is part of perl-Dist-Zilla-Plugin-Hook.
#
#   ------------------------------------------------------------------------------------------------

#pod =encoding UTF-8
#pod
#pod =head1 WHAT?
#pod
#pod C<Dist-Zilla-Plugin-Hook> (or just C<Hook>) is a set of C<Dist-Zilla> plugins. Every plugin executes Perl
#pod code inlined into F<dist.ini> at particular stage of build process.
#pod
#pod =cut

# end of file #


# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Hook - Write C<Dist::Zilla> plugin directly in F<dist.ini>

=head1 VERSION

Version v0.8.3, released on 2016-11-25 22:04 UTC.

=head1 WHAT?

C<Dist-Zilla-Plugin-Hook> (or just C<Hook>) is a set of C<Dist-Zilla> plugins. Every plugin executes Perl
code inlined into F<dist.ini> at particular stage of build process.

This is C<Dist::Zilla::Plugin::Hook> module documentation. Read this if you are going to hack or
extend C<Dist-Zilla-Plugin-Hook>.

If you want to write C<Dist::Zilla> plugin directly in F<dist.ini>, read the L<manual|Dist::Zilla::Plugin::Hook::Manual>. General
topics like getting source, building, installing, bug reporting and some others are covered in the
F<README>.

=head1 DESCRIPTION

This plugin consumes C<Hooker> role like all other C<Hook> plugins. However, this plugin I<never>
executes its Perl code. Instead, it just stores it for later use. As of today, only C<Hook> plugin
with C<prologue> name is actually used:

    [Hook/prologue]
        . = use autodie ':all';

Such code will be executed just before each hook. Note again: C<Hook> itself does not execute its
code; if there are no other hooks in F<dist.ini>, this code will never execute.

BTW, C<Dist::Zilla> and CPAN do not handle well distributions with no main module. This is also a
"main" module of C<Dist-Zilla-Plugin-Hook> distribution, to make C<Dist::Zilla> and C<CPAN> indexer happy.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla>

=item L<Dist::Zilla::Plugin::Hook::Manual>

=item L<Dist::Zilla::Role::Hooker>

=back

=head1 AUTHOR

Van de Bugger <van.de.bugger@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015, 2016 Van de Bugger

License GPLv3+: The GNU General Public License version 3 or later
<http://www.gnu.org/licenses/gpl-3.0.txt>.

This is free software: you are free to change and redistribute it. There is
NO WARRANTY, to the extent permitted by law.

=cut
