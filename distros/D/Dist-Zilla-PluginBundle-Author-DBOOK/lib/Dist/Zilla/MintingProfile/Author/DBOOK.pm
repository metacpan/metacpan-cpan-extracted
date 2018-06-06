package Dist::Zilla::MintingProfile::Author::DBOOK;

use Moose;
with 'Dist::Zilla::Role::MintingProfile::ShareDir';
use namespace::clean;

our $VERSION = '0.036';

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

Dist::Zilla::MintingProfile::Author::DBOOK - A minting profile used by DBOOK

=head1 SYNOPSIS

 dzil new -P Author::DBOOK Foo::Bar

=head1 DESCRIPTION

This is the minting profile that DBOOK uses. It creates a git repository with a
module skeleton in C<lib> and the following additional files:

=over

=item *

C<Changes>

=item *

C<cpanfile>

=item *

C<dist.ini>

=item *

C<LICENSE>

=item *

C<.gitignore>

=item *

C<.travis.yml>

=back

The created C<dist.ini> will use the current dzil C<config.ini> to populate the
author, license, and copyright fields. It will additionally add the plugin
bundle L<Dist::Zilla::PluginBundle::Author::DBOOK>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Dist::Zilla>, L<cpanfile>, L<Dist::Zilla::PluginBundle::Author::DBOOK>
