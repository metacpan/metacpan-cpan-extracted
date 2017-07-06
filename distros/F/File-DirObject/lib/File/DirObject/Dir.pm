package File::DirObject::Dir;

use strict;
use warnings;

use File::stat;
use Cwd;
use File::DirObject::File;

sub new {
    my ($class, $dirname) = @_;
    $dirname = $dirname || cwd;
    chomp $dirname;
   
    my $first = substr $dirname, 0, 1;
    my $last = substr $dirname, -1, 1; 
    
    if ($first ne '/') {
        $dirname = cwd . '/' . $dirname;
    }

    if ($last eq '/') {
        $dirname = substr $dirname, 0, -1;
    }

    my $self = {'dirname', $dirname};
    bless $self, $class;
    return $self;
}

sub path {
    my $self = shift;
    return $self->name . '/';
}

sub parent_dir {
    my $self = shift;

    my @parts = split /\//, $self->full_path;
    return File::DirObject::Dir->new(join('/', @parts[0 .. $#parts - 1]) . '/');
}

sub name {
    my $self = shift;
    my @parts = split /\//, ${$self}{'dirname'};
    return $parts[-1];
}

sub full_path {
    my $self = shift;
    return ${$self}{'dirname'} . '/';
}

sub items {
    my $self = shift;
    my $dir;

    opendir $dir, ${$self}{'dirname'} or die "Error reading directory.";
    return sort {$a cmp $b} readdir $dir;
}

sub contains_file {
    my ($self, $name) = @_;
    my $r = 0;

    foreach ($self->files) {
        if ($_->name eq $name) {
            $r = 1;
            last;
        }
    }

    return $r;
}

sub contains_dir {
    my ($self, $name) = @_;
    my $r = 0;

    foreach ($self->dirs) {
        if ($_->name eq $name) {
            $r = 1;
            last;
        }
    }

    return $r;
}

sub files {
    my $self = shift;
    my @output = ();

    foreach ($self->items) {
        if ($_ eq "." or $_ eq "..") { next; }
        my $target = $self->full_path . $_;
        stat $target;

        if (!-d $target) {
            push @output, File::DirObject::File->new($self, $target);
        }
    }

    return @output;
}

sub dirs {
    my $self = shift;
    my @output = ();

    foreach ($self->items) {
        if ($_ eq "." or $_ eq "..") { next; }
        my $target = $self->full_path . $_;
        stat $target;

        if (-d $target) {
            push @output, File::DirObject::Dir->new($target);
        }
    }

    return @output;
}

sub is_cwd {
    my $self = shift;
    return (substr $self->full_path, 0, -1) eq cwd;
}

1;

