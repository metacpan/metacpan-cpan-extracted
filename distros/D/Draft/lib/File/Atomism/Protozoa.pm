package File::Atomism::Protozoa;

=head1 NAME

File::Atomism::Protozoa - CAD drawing as an atomised directory

=head1 SYNOPSIS

A directory that contains multiple drawing entities each represented
by a single file.

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
use SGI::FAM;

sub Scan
{
    my $self = shift;
    my @freshfiles;
    my @stalefiles;

    $self->_init;

    while ($self->{_fam}->pending)
    {
        my $event = $self->{_fam}->next_event;

        push (@freshfiles, $event->filename)
            if ($event->type =~ /^(create|change|exist)$/);

        push (@stalefiles, $event->filename)
            if ($event->type eq 'delete');

        # mark for canvas erase if file changed or removed
        $File::Atomism::EVENT->{_old}->{$self->{_path} . $event->filename} = 'TRUE'
            if ($event->type =~ /^(change|delete)$/);

        # mark for canvas draw if file new or changed
        $File::Atomism::EVENT->{_new}->{$self->{_path} . $event->filename} = 'TRUE'
            if ($event->type =~ /^(create|change|exist)$/);
    }

=pod

Files titled "F<DIRTYPE>" or beginning with "." or "_" are not considered part of
the data and are therefore ignored.

=cut

    @stalefiles = grep (!/^(DIRTYPE$|[._])/, @stalefiles);
    @freshfiles = grep (!/^(DIRTYPE$|[._])/, @freshfiles);

    return \@freshfiles, \@stalefiles;
}

=pod

L<SGI::FAM> (File Activation Monitor) is used to grapple the file list.

=cut

sub _init
{
    my $self = shift;
    unless ($self->{_fam})
    {
        $self->{_fam} = SGI::FAM->new;
        $self->{_fam}->monitor ($self->{_path});
    }
    return $self;
}

# FIXME: needs Clone(), Delete(), Journal() and Rename() methods for elements

}

1;
