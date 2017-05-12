package Draft::Drawing;

=head1 NAME

Draft::Drawing - CAD drawing type

=head1 SYNOPSIS

A directory that contains multiple drawing elements

=head1 DESCRIPTION

A simple file-system directory/folder that contains any number of
drawing objects, represented by files; and optionally, any number of
further drawings represented by subdirectories.

Note that this is not completely analogous to a traditional
monolithic CAD file format, as blocks/symbols associated with a
drawing are complete drawings in their own right.

=cut

use strict;
use warnings;

use Draft;
use Draft::TkGui::Drawing;
use File::Atomism;
use File::Atomism::utils qw /Extension/;

# FIXME shouldn't depend on Tk
use vars qw /@ISA/;
@ISA = qw /Draft::TkGui::Drawing File::Atomism/;

=pod

=head1 USAGE

Read a drawing into memory, or simply update an already-loaded
drawing by using the Read method:

    $drawing->Read;

Note that this method will only access the filesystem if files have
actually changed or are new - Feel free to call this method as often
as you like as it has very little performance overhead.

=cut

# FIXME sometimes doesn't delete objects when files are removed

sub Read
{
    my $self = shift;

    my ($freshfiles, $stalefiles) = $self->Scan;

    for my $file (@{$stalefiles})
    {
        my $key = $self->{_path} . $file;
        delete $self->{$key} if ($self->{$key});
    }

    for my $file (@{$freshfiles})
    {
        my $key = $self->{_path} . $file;

        my $type = Extension ($file);
        $type = $self->Capitalise ($type);
        eval "use Draft::Protozoa::$type";
        $@ and next;

        $self->{$key} = eval "Draft::Protozoa::$type->new (\"$key\")"
            unless exists $self->{$key};
                                                                                                                      
        $self->{$key}->Read;
        $self->{$key}->Process;
    }
}

1;
