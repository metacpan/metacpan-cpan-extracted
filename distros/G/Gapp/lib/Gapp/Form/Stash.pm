package Gapp::Form::Stash;
{
  $Gapp::Form::Stash::VERSION = '0.60';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

use Try::Tiny;

has 'storage' => (
    is => 'bare',
    isa => 'HashRef',
    default => sub { { } },
    traits => [qw( Hash )],
    clearer => 'clear',
    handles => {
        store => 'set',
        fetch => 'get',
        contains => 'exists',
        delete => 'delete',
        elements => 'keys',
    },
    lazy => 1,
);

# if the stash has been modified via the form
has 'modified' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);



# if the context has updated the stash
after 'store'  => sub { $_[0]->set_modified(1) };
after 'delete' => sub { $_[0]->set_modified(1) };


sub update {
    my ( $self, $cx ) = @_;
    
    for my $field ( $self->elements ) {
        
        try {
            my $value = $cx->lookup( $field );
            $self->store( $field, $value );
        }
        
       
    }
    
    $self->set_modified( 0 );
}

sub update_from_context {
    my $self = shift;
    use Carp qw( cluck );
    cluck '$stash->update_from_context( $cx ) deprecated, use $stash->update( $cx ) instead';
    $self->update( @_ );
}




1;


__END__

=pod

=head1 NAME

Gapp::Form::Stash - Form stash object

=head1 SYNOPSIS

  $s = Gapp::Form::Stash->new;

  $s->store( 'object.attr', $value );

  $s->retrieve( 'object.attr' );


=head1 DESCRIPTION

The stash is registry that used to retrieve and update form data.

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Form::Stash>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<modified>

=over 4

=item is rw

=item isa Bool

=item default 0

=back

True if the data in the stash has been modified by the form.

=back

=head1 PROVIDED METHODS

=over 4

=item B<contains $key>

Returns C<true> if a C<$key> exists in the registry, C<false> otherwise.

=item B<delete $key>

Removes a key from the stash.

=item B<elements>

Returns a list of keys in the registry.

=item B<fetch $key>

Retrieve the value of key from the registry.

=item B<store $key, $value>

Stores a value to a key in the registry.

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut



