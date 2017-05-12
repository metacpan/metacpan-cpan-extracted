package Dist::Zilla::Plugin::Mercurial::Tag;
$Dist::Zilla::Plugin::Mercurial::Tag::VERSION = '0.08';
use strict;
use warnings;
use autodie qw( :all );

use File::Slurp qw( read_file );

use Moose;

with 'Dist::Zilla::Role::BeforeRelease';
with 'Dist::Zilla::Role::AfterRelease';

sub before_release {
    my $self = shift;

    return 0 unless -f '.hgtags';

    my %tags = map { ( split /\s+/ )[1, 0] } read_file('.hgtags');

    my $ver = $self->zilla()->version();

    return unless $tags{$ver} && $tags{$ver} !~ /^0+$/;

    $self->log_fatal("Tag $ver already exists");
}

sub after_release {
    my $self = shift;

    my $ver = $self->zilla()->version();

    system( 'hg', 'tag', $ver );

    $self->log("Tagged $ver");
}

1;

# ABSTRACT: Tag the new version

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Mercurial::Tag - Tag the new version

=head1 VERSION

version 0.08

=head1 SYNOPSIS

In your F<dist.ini>:

  [Mercurial::Tag]

=head1 DESCRIPTION

This plugin acts both before and after a release.

Before the release, it checks to see that a tag matching the release version
does not already exist. If such a tag already exists, that is a fatal error.

After the release, it adds a tag with the released version.

=for Pod::Coverage after_release
    before_release

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
