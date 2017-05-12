package Gapp::ActionGroup;
{
  $Gapp::ActionGroup::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::Types::Moose qw( ArrayRef ClassName HashRef Object );

extends 'Gapp::Object';

use Gapp::Actions::Util;

has '+gclass' => (
    default => 'Gtk2::ActionGroup',
);

has 'name' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'actions' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
);

has 'action_args' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ ] },
);

{
    my $anon = 1;

    around BUILDARGS => sub {
        my ( $orig, $class, %opts ) = @_;
        $opts{name} ||= 'ActionGroup::__ANON__::' . $anon++;
        $opts{args} = [$opts{name}];
        $class->$orig( %opts );
    };
}

after _construct_gobject => sub {
    my ( $self ) = @_;
    my $gobject = $self->gobject;
    
    my @actions;
    for my $a ( @{ $self->actions } ) {
        
        # if it is an array-ref/hash-ref, coerce
        if ( is_ArrayRef( $a ) || is_HashRef( $a ) ) {
            push @actions, to_GappAction( $a );
        }
        
        # if it is a Gapp::Action, apply it to the action group
        elsif ( is_Object( $a ) ) {
            push @actions, $a;
        }
        
        # if it is a class, apply all the actions to the group
        elsif ( is_ClassName ( $a ) ) {
            push @actions, ACTION_REGISTRY( $a )->actions;
        }
    }
    
    # create the gtk action widgets and add them
    # the the action group gtk widget
    map { $gobject->add_action( $_->create_gtk_action( args => $self->action_args ) ) } @actions;
};

1;




__END__

=pod

=head1 NAME

Gapp::ActionGroup - ActionGroup Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::ActionGroup>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


