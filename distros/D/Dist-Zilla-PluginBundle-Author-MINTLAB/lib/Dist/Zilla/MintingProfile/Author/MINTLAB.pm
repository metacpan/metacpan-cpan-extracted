package Dist::Zilla::MintingProfile::Author::MINTLAB;
our $VERSION = '0.02';
use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';
use namespace::clean;

# ABSTRACT: A minting profile for MINTLAB employees

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::Author::MINTLAB - A minting profile for MINTLAB employees

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 dzil new -P Author::MINTLAB Foo::Bar

=head1 DESCRIPTION

This is the minting profile that MINTLAB uses. It creates a git
repository with a module skeleton in C<lib> and the following additional
files:

=over

=item *

C<Changes>

=item *

C<Dockerfile>

=item *

C<cpanfile>

=item *

C<dev-bin/cpanm>

=item *

C<dist.ini>

=item *

C<LICENSE>

=item *

C<t/01-basic.t>

=item *

C<.dockerignore>

=item *

C<.gitignore>

=item *

C<.gitlab-ci.yml>

=item *

C<.editorconfig>

=back

The created C<dist.ini> will use the EUPL v1.1 software license and set
the copyright owner to Mintlab B.V. / Zaaksysteem.nl. It will
additionally add the plugin bundle
L<Dist::Zilla::PluginBundle::Author::MINTLAB>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 SEE ALSO

L<Dist::Zilla>, L<cpanfile>, L<Dist::Zilla::PluginBundle::Author::MINTLAB>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Mintlab B.V / Zaaksysteem.nl.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
