package File::Find::Object::TreeCreate;

use strict;
use warnings;

use File::Spec;

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize
{
}

sub get_path
{
    my $self = shift;
    my $path = shift;

    my @components;

    if ($path =~ s{^\./}{})
    {
        push @components, File::Spec->curdir();
    }

    my $is_dir = ($path =~ s{/$}{});
    push @components, split(/\//, $path);
    if ($is_dir)
    {
        return File::Spec->catdir(@components);
    }
    else
    {
        return File::Spec->catfile(@components);
    }
}

sub exist
{
    my $self = shift;
    return (-e $self->get_path(@_));
}

sub is_file
{
    my $self = shift;
    return (-f $self->get_path(@_));
}

sub is_dir
{
    my $self = shift;
    return (-d $self->get_path(@_));
}

sub cat
{
    my $self = shift;
    open my $in, "<", $self->get_path(@_) or
        return 0;
    my $data;
    {
        local $/;
        $data = <$in>;
    }
    close($in);
    return $data;
}

sub ls
{
    my $self = shift;
    opendir my $dir, $self->get_path(@_) or
        return undef;
    my @files =
        sort { $a cmp $b }
        grep { !(($_ eq ".") || ($_ eq "..")) }
        readdir($dir);
    closedir($dir);
    return \@files;
}

sub create_tree
{
    my ($self, $unix_init_path, $tree) = @_;
    my $real_init_path = $self->get_path($unix_init_path);
    return $self->_real_create_tree($real_init_path, $tree);
}

sub _real_create_tree
{
    my ($self, $init_path, $tree) = @_;
    my $name = $tree->{'name'};
    if ($name =~ s{/$}{})
    {
        my $dir_name = File::Spec->catfile($init_path, $name);
        mkdir($dir_name);
        if (exists($tree->{'subs'}))
        {
            foreach my $sub (@{$tree->{'subs'}})
            {
                $self->_real_create_tree($dir_name, $sub);
            }
        }
    }
    else
    {
        open my $out, ">", File::Spec->catfile($init_path, $name);
        print {$out} +(exists($tree->{'contents'}) ? $tree->{'contents'} : "");
        close($out);
    }
    return 0;
}
1;

