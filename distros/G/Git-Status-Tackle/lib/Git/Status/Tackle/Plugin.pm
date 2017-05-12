package Git::Status::Tackle::Plugin;
use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub name {
    my $self = shift;
    my $class = ref($self) || $self;
    $class =~ s/Git::Status::Tackle:://;
    return $class;
}

sub header {
    my $self = shift;
    return $self->name . ":\n";
}

sub branches {
    my $self = shift;
    unless ($self->{branches}) {
        $self->{branches} = [ map { s/\s+$//; $_ } split /\n/, `git branch -l --color` ];
    }
    return @{ $self->{branches} };
}

1;

