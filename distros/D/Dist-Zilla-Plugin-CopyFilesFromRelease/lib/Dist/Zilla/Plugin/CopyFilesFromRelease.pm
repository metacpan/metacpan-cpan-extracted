use strict;
use warnings;
package Dist::Zilla::Plugin::CopyFilesFromRelease; # git description: v0.005-14-gf4b6e90
# ABSTRACT: Copy files from a release (for SCM inclusion, etc.)
# KEYWORDS: plugin copy files repository distribution release

our $VERSION = '0.006';

use Moose;
with qw/ Dist::Zilla::Role::AfterRelease /;

use File::Copy ();
use Path::Tiny;

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
    };

    return $config;
};

sub after_release {
    my $self = shift;
    my $built_in = $self->zilla->ensure_built;
    my $root = $self->zilla->root;

    my $file_match = join '|', map quotemeta, $self->filename;
    $file_match = join '|', '^(?:' . $file_match . ')$', $self->match;
    $file_match = qr/$file_match/;

    my $iterator = path($built_in)->iterator({ recurse => 1 });
    while (my $file = $iterator->()) {
        next if -d $file;

        my $rel_path = $file->relative($built_in);
        next
            unless $rel_path =~ $file_match;
        my $dest = path($root, $rel_path);
        File::Copy::copy("$file", "$dest")
            or $self->log_fatal("Unable to copy $file to $dest: $!");
        $self->log("Copied $file to $dest");
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CopyFilesFromRelease - Copy files from a release (for SCM inclusion, etc.)

=head1 VERSION

version 0.006

=head1 SYNOPSIS

In your dist.ini:

    [CopyFilesFromRelease]
    filename = README
    match = ^MANIFEST*

=head1 DESCRIPTION

This plugin will automatically copy the files that you specify in
dist.ini from the build directory into the distribution directoory.
This is so you can commit them to version control.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::CopyFilesFromBuild> - The basis for this module

=back

=head1 AUTHOR

Graham Knop <haarg@haarg.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Knop.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
