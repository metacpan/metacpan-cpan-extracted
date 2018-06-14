package Dist::Zilla::MintingProfile::Author::WATERKIP;
our $VERSION = '2.0';
use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';
use namespace::clean;

# ABSTRACT: A minting profile with WATERKIP in mind

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::MintingProfile::Author::WATERKIP - A minting profile with WATERKIP in mind

=head1 VERSION

version 2.0

=head1 SYNOPSIS

 dzil new -P Author::WATERKIP Foo::Bar

=head1 DESCRIPTION

This is the minting profile that WATERKIP uses. It creates a git
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

The created C<dist.ini> will use the current dzil C<config.ini> to populate the
author, license, and copyright fields. It will additionally add the plugin
bundle L<Dist::Zilla::PluginBundle::Author::WATERKIP>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 SEE ALSO

L<Dist::Zilla>, L<cpanfile>, L<Dist::Zilla::PluginBundle::Author::WATERKIP>

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Wesley Schwengle.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
