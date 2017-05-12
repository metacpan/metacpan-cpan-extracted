package Dist::Zilla::Plugin::CopyReadmeFromBuild;
BEGIN {
  $Dist::Zilla::Plugin::CopyReadmeFromBuild::VERSION = '0.0019';
}
# ABSTRACT: Copy README after building (for SCM inclusion, etc.)


use Moose;
with 'Dist::Zilla::Role::AfterBuild';

use File::Copy qw/ copy /;

sub after_build {
    my $self = shift;
    my $data = shift;

    if ( $ENV{ DZIL_RELEASING} || $ENV{ DZIL_CopyFromBuildAfterBuild } ) {}
    else { return }

    my $build_root = $data->{build_root};
    my $src;
    for(qw/ README README.md README.mkdn README.txt README.markdown /) {
        my $file = $build_root->file( $_ );
        $src = $file and last if -e $file;
    }

    die "Missing README file in ", $build_root unless $src;

    my $dest = $self->zilla->root->file( $src->basename );

    copy "$src", "$dest" or die "Unable to copy $src to $dest: $!";
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__
=pod

=head1 NAME

Dist::Zilla::Plugin::CopyReadmeFromBuild - Copy README after building (for SCM inclusion, etc.)

=head1 VERSION

version 0.0019

=head1 SYNOPSIS

In your L<Dist::Zilla> C<dist.ini>:

    [CopyReadmeFromBuild]

=head1 DESCRIPTION

CopyReadmeFromBuild will automatically copy the README from the build directory
into the distribution directory. This is so you can commit the README to version
control. GitHub, for example, likes to see a README

Dist::Zilla::Plugin::Readme will not like it if you already have a README, so
you'll have to disable that plugin, an example of which is:

    [@Filter]
    bundle = @Basic
    remove = Readme

=head1 AfterBuild/AfterRelease

With the release of 0.0016, this plugin changed to performing the copy during the AfterRelease stage instead of the AfterBuild stage.
To enable the old behavior, set the environment variable DZIL_CopyFromBuildAfterBuild to 1:

    $ DZIL_CopyFromBuildAfterBuild=1 dzil build 

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

