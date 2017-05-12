package Hubot::Brain;
$Hubot::Brain::VERSION = '0.2.8';
use Moose;
use namespace::autoclean;

extends 'Hubot::EventEmitter';

sub BUILD {
    my $self = shift;
    $self->{data}{users} = {};
}

sub save {
    my $self = shift;
    $self->emit( 'save', $self->{data} );
}

sub close {
    my $self = shift;
    $self->save;
    $self->emit('close');
}

sub mergeData {
    my ( $self, $data ) = @_;
    for my $key ( keys %$data ) {
        if ( $key eq 'users' ) {
            for my $k ( keys %{ $data->{$key} } ) {
                bless $data->{$key}{$k}, 'Hubot::User';
            }
        }

        $self->{data}{$key} = $data->{$key};
    }

    $self->emit( 'loaded', $self->{data} );
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Hubot::Brain - Represents somewhat persistent storage for the robot.

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

    $robot->brain->{data}{key} = ''; # scalar
    $robot->brain->{data}{key} = {}; # HashRef
    $robot->brain->{data}{key} = []; # ArrayRef

=head1 DESCRIPTION

Brain with external storage like a L<Hubot::Scrips::redisBrain>, C<value> must be a B<Scalar> or B<HashRef> or B<ArrayRef>.

C<$robot-E<gt>brain-E<gt>data> will convert to json string and stored to external storage.
so, if you trying to store perl object, it will fail.

without external storage, everything is fine to store to memory.

=head1 USE EXTERNAL STORAGE

=over

=item step 1

subscribe brain's C<save> and C<close> event.

=item step 2

robot boots time, C<save> will emitted.
robot shutdown time, C<close> will emitted.

=back

    my $externalStorage = Great::Big::White::World->new;
    $robot->brain->on(
        'save',
        sub {
            my ($e, $data) = @_;
            $externalStorage->save($data);
        }
    );

    $robot->brain->on(
        'close',
        sub {
            $externalStorage->quit;
        }
    );

=head1 SEE ALSO

L<Hubot::Scripts::redisBrain>

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
