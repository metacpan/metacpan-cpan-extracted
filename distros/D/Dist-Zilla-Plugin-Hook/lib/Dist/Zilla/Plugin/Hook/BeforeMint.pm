#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: lib/Dist/Zilla/Plugin/Hook/BeforeMint.pm
#
#   This file is part of perl-Dist-Zilla-Plugin-Hook.
#   This file was generated with =tools::GenerateHooks.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#pod =head1 DESCRIPTION
#pod
#pod This is C<Hook::BeforeMint> plugin implementation. Nothing interesting, just using few roles.
#pod
#pod If you want to write C<Dist::Zilla> plugin directly in F<dist.ini>, read the L<manual|Dist::Zilla::Plugin::Hook::Manual>. General topics like
#pod getting source, building, installing, bug reporting and some others are covered in the F<README>.
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod = L<Dist::Zilla::Plugin::Hook>
#pod = L<Dist::Zilla::Plugin::Hook:Manual>
#pod = L<Dist::Zilla>
#pod = L<Dist::Zilla::Role::BeforeMint>
#pod
#pod =cut

package Dist::Zilla::Plugin::Hook::BeforeMint;

use Moose;
use namespace::autoclean;
use version 0.77;

# ABSTRACT: C<Hook::BeforeMint> plugin implementation
our $VERSION = 'v0.8.3'; # VERSION

with 'Dist::Zilla::Role::Plugin';
with 'Dist::Zilla::Role::Hooker' => {
    -alias => { hook => 'before_mint' },
};
with 'Dist::Zilla::Role::BeforeMint';

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

# end of file #

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Hook::BeforeMint - C<Hook::BeforeMint> plugin implementation

=head1 VERSION

Version v0.8.3, released on 2016-11-25 22:04 UTC.

=head1 DESCRIPTION

This is C<Hook::BeforeMint> plugin implementation. Nothing interesting, just using few roles.

If you want to write C<Dist::Zilla> plugin directly in F<dist.ini>, read the L<manual|Dist::Zilla::Plugin::Hook::Manual>. General topics like
getting source, building, installing, bug reporting and some others are covered in the F<README>.

=head1 SEE ALSO

=over 4

=item L<Dist::Zilla::Plugin::Hook>

=item L<Dist::Zilla::Plugin::Hook:Manual>

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role::BeforeMint>

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
