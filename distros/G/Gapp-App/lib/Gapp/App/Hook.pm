package Gapp::App::Hook;
{
  $Gapp::App::Hook::VERSION = '0.222';
}

use Moose;
use MooseX::StrictConstructor;
use MooseX::SemiAffordanceAccessor;

#with 'Gapp::App::Role::HasApp';

has 'action' => (
    is => 'rw',
    isa => 'Str',
    default => 'aggregate',
);

has '_callbacks' => (
    is => 'rw',
    isa => 'ArrayRef',
    traits => [qw( Array )],
    handles => {
        pop => 'pop',
        callbacks => 'elements',
    },
    default => sub { [ ] },
);

has 'closure' => (
    is => 'rw',
    isa => 'Maybe[CodeRef]',
    default => undef,
);

has 'name' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);




sub call {
    my ( $self, $app, @params ) = @_;
    
    my @results;
    for my $cb ( $self->callbacks ) {
        my ( $code, $data ) = @$cb;
        
        push @results, $code->($app, \@params, $data );
    }
    
    if ( $self->closure ) {
        @results = $self->closure->( $self, $app, \@params, \@results );
    }
    
    return @results;
}

sub push {
    my ( $self, $code, $data ) = @_;
    push @{$self->_callbacks}, [ $code, $data ];
}

1;


__END__

=pod

=head1 NAME

Gapp::App::Hook - Application callback
  
=head1 DESCRIPTION

A hook object holds callbacks which are executed upon request.

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<action>

Possible values are C<aggregate> and C<halt>.
An C<Aggregate> hook will accumlate the return values of all callbacks.
A C<halt> hook will stop execution of all callbacks when any callback returns true.

=over 4

=item is rw

=item isa L<GappAppHookAction>

=item default C<aggregate>

=back

=item B<name>

The name of the hook.

=over 4

=item is rw

=item isa Str

=back

=item B<closure \&callback>

A C<CodeRef> to be executed after all callbacks.

=over 4

=item is rw

=item isa CodeRef|Undef

=item default Undef

=back

=head1 PROVIDED METHODS

=over 4

=item B<call @params>

Executes the associated callbacks, passing in C<@params>.

=item B<push \&callback, $data>

Add a callback to the hook. Callbacks will be executed in the order
they are pushed on to the stack.

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2012 Jeffrey Ray Hallock.
    
    This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
    
=cut

