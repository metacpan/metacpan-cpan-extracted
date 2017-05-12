package Draft::Protozoa::Yml;

=head1 NAME

Draft::Protozoa::Yml - CAD drawing-object base class

=head1 SYNOPSIS

A CAD drawing object that consists of a single file with an internal
L<YAML> format.

=head1 DESCRIPTION

=cut

use strict;
use warnings;

use YAML;
use File::Atomism::utils qw /TempFilename Journal/;

=pod

=head1 USAGE

Create an object by supplying the 'new' method with a file-path:

    use Draft::Drawing::Yml;
    my $foo = Draft::Drawing::Yml->new ('/path/to/file.yml');

=cut

sub new
{
    my $class = shift;
    $class = ref $class || $class;
    my $self = bless {}, $class;
    $self->{_path} = shift;
    return $self;
}

=pod

Read/Parse an existing file with the Read method:

    $foo->Read;

=cut

sub Read
{
    my $self = shift;

    my $data = YAML::LoadFile ($self->{_path});

    my $newclass = "Draft::Protozoa::Yml::". $self->Type ($data) ."::". $self->Version ($data);

    eval "use $newclass";
    $@ and return 0;

    bless $self, $newclass;

    $self->_parse ($data);
}

=pod

Objects can be moved in the world-space:

    $foo->Move ([10, 5, 0]);

This edits the file on the filesystem in one atomic operation.  This
is a permanent operation - If you find that you didn't want to move
the object, you might want to investigate using cvs for your data.

=cut

sub Move
{
    my $self = shift;
    my $vec = shift;

    my $data = YAML::LoadFile ($self->{_path});

    # element could have any number of points
    for my $point (0 .. @{$data->{points}} - 1)
    {
        # vector could have any number of dimensions
        for my $axis (0 .. @{$vec} -1)
        {
            $data->{points}->[$point]->[$axis] += $vec->[$axis];
        }
    }

    my $temp = TempFilename ($self->{_path});
    YAML::DumpFile ($temp, $data);

    Journal ([[$self->{_path}, $temp]]);
    rename $temp, $self->{_path};
}

sub _capitalise
{
    my $self = shift;
    my $word = shift;
    my $first = substr ($word, 0, 1, '');
    return uc ($first) . lc ($word);
}

=pod

Query the type and version of the object like so:

    my $type = $self->Type ($foo);
    my $version = $self->Version ($foo);

=cut

sub Type
{
    my $self = shift;
    my $data = shift;
    my $type = $data->{type} || 'unknown';
    $type =~ s/ .*//;
    $type =~ s/[^a-z0-9_]//gi;
    $self->_capitalise ($type);
}

sub Version
{
    my $self = shift;
    my $data = shift;
    my $version = $data->{version} || 'draft1';
    $version =~ s/ .*//;
    $version =~ s/[^a-z0-9_]//gi;
    $self->_capitalise ($version);
}

sub Process {}

sub Draw {}

1;
