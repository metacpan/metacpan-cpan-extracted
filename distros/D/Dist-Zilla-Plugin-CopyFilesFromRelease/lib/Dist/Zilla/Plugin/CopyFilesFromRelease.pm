use strict;
use warnings;
package Dist::Zilla::Plugin::CopyFilesFromRelease; # git description: v0.006-14-g6b0a6f6
# ABSTRACT: Copy files from a release (for SCM inclusion, etc.)
# KEYWORDS: plugin copy files repository distribution release

our $VERSION = '0.007';

use Moose;
with qw/ Dist::Zilla::Role::AfterRelease /;

use Path::Tiny 0.070;
use namespace::autoclean;

sub mvp_multivalue_args { qw{ filename match } }

has $_ => (
    lazy => 1,
    isa        => 'ArrayRef[Str]',
    default    => sub { [] },
    traits => ['Array'],
    handles => { $_ => 'sort' },
) foreach qw(filename match);

around dump_config => sub {
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        map { $_ => [ $self->$_ ] } qw(filename match),
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    return $config;
};

sub after_release {
    my $self = shift;

    my $build_dir = $self->zilla->built_in;
    my $root = $self->zilla->root;

    my $file_match = join '|', map quotemeta, $self->filename;
    $file_match = join '|', '^(?:' . $file_match . ')$', $self->match;
    $file_match = qr/$file_match/;

    my $iterator = path($build_dir)->iterator({ recurse => 1 });
    while (my $file = $iterator->()) {
        next if -d $file;

        my $rel_path = $file->relative($build_dir);
        next
            unless $rel_path =~ $file_match;
        my $dest = path($root, $rel_path);
        $file->copy($dest)
            or $self->log_fatal("Unable to copy $file to $dest: $!");
        $self->log("Copied $file to $dest");
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=for stopwords SCM

=head1 NAME

Dist::Zilla::Plugin::CopyFilesFromRelease - Copy files from a release (for SCM inclusion, etc.)

=head1 VERSION

version 0.007

=head1 SYNOPSIS

In your dist.ini:

    [CopyFilesFromRelease]
    filename = README
    match = ^MANIFEST*

=head1 DESCRIPTION

This plugin will automatically copy the files that you specify in
dist.ini from the build directory into the distribution directory.
This is so you can commit them to version control.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::CopyFilesFromBuild> - The basis for this module

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-CopyFilesFromRelease>
(or L<bug-Dist-Zilla-Plugin-CopyFilesFromRelease@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-CopyFilesFromRelease@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Graham Knop <haarg@haarg.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Jonas B. Nielsen

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Jonas B. Nielsen <jonasbn@users.noreply.github.com>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Graham Knop.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
