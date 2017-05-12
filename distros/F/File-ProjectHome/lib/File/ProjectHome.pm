package File::ProjectHome;
use 5.008005;
use strict;
use warnings;
use File::Spec;
use Path::Class qw(dir);

our $VERSION = "0.02";

our @PROJECT_ROOT_FILES = qw(
    cpanfile
    .git
    .gitmodules
    Makefile.PL
    Build.PL
);

sub project_home {
    my $dir = dir((caller)[1]);
    while (my $parent = _parent($dir)) {
        for my $project_root_files (@PROJECT_ROOT_FILES) {
            if (-e File::Spec->catfile($dir, $project_root_files)) {
                return "$dir";
            }
        }
        $dir = $parent;
    }
}

sub _parent {
    my $dir = shift;
    my $parent = $dir->parent;
    return if $parent eq File::Spec->rootdir;
    return $parent;
}

1;
__END__

=encoding utf-8

=head1 NAME

File::ProjectHome - Find home dir of a project

=head1 SYNOPSIS

in /home/Cside/work/Some-Project/lib/Some/Module.pm

  use File::ProjectHome;
  print File::ProjectHome->project_home;  #=> /home/Cside/work/Some-Project

=head1 DESCRIPTION

This module finds a project's home dir: nearest ancestral directory that contains any of these file or directories:

  cpanfile
  .git/
  .gitmodules
  Makefile.PL
  Build.PL

=head1 SEE ALSAO

L<Project::Libs>

=head1 LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hiroki Honda E<lt>cside.story@gmail.comE<gt>

=cut

