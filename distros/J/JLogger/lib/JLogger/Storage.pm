package JLogger::Storage;

use strict;
use warnings;

require Carp;

sub new {
    my ($class, %args) = @_;

    my $self = bless {%args}, $class;

    $self->init;

    $self;
}

sub init {
    my $self = shift;
}

sub save {
    my $self = shift;

    Carp::croak(qq(You didn't implemented "save" in @{[ ref $self ]}));
}

1;
__END__

=head1 NAME

JLogger::Storage - base class for storages;

=head1 SYNOPSIS

    use base 'JLogger::Storage';

    sub save {
        my ($self, $message) = @_;

        ...
    }

=head1 METHODS

=head2 C<init>

    $storage->init;

(Re)initialize storage. Called automatically after new.

=head2 C<save>

    $storage->store($message);

Save message to storage.

=cut    
