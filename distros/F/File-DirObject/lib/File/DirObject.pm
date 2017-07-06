package File::DirObject;

use strict;
use warnings;

# ABSTRACT: traverse directories with methods

our $VERSION  = '0.0.3';

1;

=pod

=head1 NAME

File::DirObject

=head1 DESCRIPTION

Traverse directories with methods. This is a very simple module where you can traverse directories
and see their contents. None of the methods are destructive or actually manipulate anything
it's simply designed for reading directory trees, and using that data somewhere else.

=head1 SYNOPSIS

    use File::DirObject::Dir;
    # use File::DirObject::File;

    my $dir = File::DirObject::Dir->new('/home/ubuntu/');

    foreach ($dir->dirs) {
        # do stuff with child dir objects
    }

    foreach ($dir->files) {
        # do stuff with child file objects
    }

    # get parent dir
    my $parent = $dir->parent_dir;

=head1 LICENSE

MIT

=cut

