package JS::jQuery::Loader::Source::File;

use Moose;
extends qw/JS::jQuery::Loader::Source/;
use JS::jQuery::Loader::Carp;

use JS::jQuery::Loader::Location;
use JS::jQuery::Loader::Template;

has location => qw/is ro/, handles => [qw/recalculate file/];
has template => qw/is ro required 1 lazy 1 isa JS::jQuery::Loader::Template/, default => sub { return JS::jQuery::Loader::Template->new };

sub BUILD {
    my $self = shift;
    my $given = shift;

    my $location = $given->{location};
    $self->{location} = do {

        croak "Wasn't given a file" unless $given->{file};

        JS::jQuery::Loader::Location->new(template => $self->template, file => $given->{file}, location => $location);

    }
    unless blessed $location;
}

1;
