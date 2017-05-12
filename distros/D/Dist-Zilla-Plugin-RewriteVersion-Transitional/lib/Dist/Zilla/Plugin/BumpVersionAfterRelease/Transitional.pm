use strict;
use warnings;
package Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional;
# ABSTRACT: Ease the transition to [BumpVersionAfterRelease] in your distribution
# KEYWORDS: plugin version rewrite munge module
# vim: set ts=8 sts=4 sw=4 tw=115 et :

our $VERSION = '0.007';

use Moose;
extends 'Dist::Zilla::Plugin::BumpVersionAfterRelease';
with 'Dist::Zilla::Role::InsertVersion';
use Path::Tiny;
use namespace::autoclean;

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        # TODO
    };

    return $config;
};

around rewrite_version => sub
{
    my $orig = shift;
    my $self = shift;
    my ($file, $version) = @_;

    # update existing our $VERSION = '...'; entry
    return 1 if $self->$orig($file, $version);

    # note that $file is the file in the distribution, whereas we want to
    # modify the file in the source repository.
    my $source_file = Dist::Zilla::File::OnDisk->new(
        name => path($file->_original_name)->stringify,
        encoding => $file->encoding,
    );

    if ($self->insert_version($source_file, $version))
    {
        # append+truncate to preserve file mode
        path($source_file->name)->append_raw({ truncate => 1 }, $source_file->encoded_content);
        return 1;
    }

    return;
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional - Ease the transition to [BumpVersionAfterRelease] in your distribution

=head1 VERSION

version 0.007

=head1 SYNOPSIS

In your F<dist.ini>:

    [BumpVersionAfterRelease::Transitional]

=head1 DESCRIPTION

=for stopwords BumpVersionAfterRelease OurPkgVersion PkgVersion

This is a L<Dist::Zilla> plugin that subclasses
L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>, to allow plugin
bundles to transition from L<[PkgVersion]|Dist::Zilla::Plugin::PkgVersion> or
L<[OurPkgVersion]|Dist::Zilla::Plugin::OurPkgVersion> to
L<[RewriteVersion]|Dist::Zilla::Plugin::RewriteVersion>
and L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>
without having to manually edit the F<dist.ini> or any F<.pm> files.

After releasing your distribution,
L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease> is
invoked to update the C<$VERSION> assignment in the module(s) in the
repository to the next version. If no such expression exists in the module,
one is added.

B<Note:> If there is more than one package in a single file, if there was
I<any> C<$VERSION> declaration in the file, no additional declarations are
added for the other packages, even if you are using the C<global> option.

=head1 CONFIGURATION OPTIONS

Configuration is the same as in
L<[BumpVersionAfterRelease]|Dist::Zilla::Plugin::BumpVersionAfterRelease>.

=head1 SUPPORT

=for stopwords irc

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-RewriteVersion-Transitional>
(or L<bug-Dist-Zilla-Plugin-RewriteVersion-Transitional@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-RewriteVersion-Transitional@rt.cpan.org>).
I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::RewriteVersion::Transitional>

=item *

L<Dist::Zilla::Plugin::PkgVersion>

=item *

L<Dist::Zilla::Plugin::RewriteVersion>

=item *

L<Dist::Zilla::Plugin::BumpVersionAfterRelease>

=back

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
