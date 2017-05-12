package Gapp::Meta::Widget::Native::Trait::Form;
{
  $Gapp::Meta::Widget::Native::Trait::Form::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

use Gapp::Form::Stash;
use Gapp::Types qw( FormContext FormField FormStash );
with 'Gapp::Meta::Widget::Native::Role::FormElement';

use Gapp::Types qw(GappCallback);
use MooseX::Types::Moose qw(Undef CodeRef);

use Gapp::Actions::Util qw( parse_action );

# defines how to transfer values from form to object
has 'context' => (
    is => 'rw',
    isa => FormContext,
);

# a registry of fields and values
has 'stash' => (
    is => 'rw',
    isa => FormStash,
    lazy_build => 1,
);

# whether or not to sync the *context* - the stash is always synced
has 'sync' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);


has [qw( apply_action cancel_action ok_action ) ] => (
    is => 'rw',
    isa => GappCallback|Undef,
);

sub _build_stash {
    my $self = shift;
    
    my $stash = Gapp::Form::Stash->new;
    
    # traverse the form and get field names to populate the stash with
    # these field names must be in the stash in order to retrieve the 
    # starting values from the context
    for my $w ( $self->find_fields ) {
        next if ! $w->field;
        $stash->store( $w->field, undef ) if ! $stash->contains( $w->field );
    }
    
    # update the values in the stash via the context
    $stash->update( $self->context ) if $self->context;
    
    $stash->set_modified( 0 );
    return $stash;
}

# update the user variables
sub apply {
    my ( $self ) = @_;
    $self->sync_stash;
    
    $self->context->update( $self->stash ) if $self->context;
    $self->do_apply_action;
}

sub cancel {
    my ( $self ) = @_;
    return if $self->do_cancel_action;
    $self->close;
}

sub close {
    my ( $self ) = @_;
    $self->gobject->destroy;
}

sub ok {
    my ( $self ) = @_;
    $self->apply;
    $self->do_ok_action;
    $self->close;
}

sub do_apply_action {
    my ( $self ) = @_;
    return if ! $self->apply_action;
    
    my ( $action, @args ) = parse_action ( $self->apply_action );
    return if ! $action;
    
    if ( is_CodeRef ( $action ) ) {
        $action->( $self, \@args );
    }
    else {
        $action->perform( $self, \@args );
    }
}

sub do_cancel_action {
    my ( $self ) = @_;
    return if ! $self->cancel_action;
    
    my ( $action, @args ) = parse_action ( $self->cancel_action );
    
    if ( is_CodeRef ($action) ) {
        $action->( $self, \@args );
    }
    else {
        $action->perform( $self, \@args );
    }
}


sub do_ok_action {
    my ( $self ) = @_;
    return if ! $self->ok_action;
    
    my ( $action, @args ) = parse_action ( $self->ok_action );
    
    if ( is_CodeRef $action ) {
        $action->( $self, \@args );
    }
    else {
        $action->perform( $self, \@args );
    }
}





sub find_fields {
     my ( $self ) = ( @ _ );
    
    my @fields;
    for my $w ( $self->find_descendants ) {
        push @fields, $w if is_FormField( $w );
    }
    
    return @fields;
}

sub _initialize_stash {
    my ( $self ) = @_;
    
    my $stash = $self->stash;
    
    for my $w ( $self->find_fields ) {
        $stash->store( $w->field, undef ) if ! $stash->contains( $w->field );
    }
    
    $stash->set_modified( 0 );
}

# update the values in the form
sub update {
    my ( $self ) = ( @_ );
    
    # update the stash if we have a context
    $self->stash->update( $self->context ) if $self->context;
    
    # update the widgets from the stash
    $self->update_from_stash;
}

# update the values in the form (don't update the stash first)
sub update_from_stash {
    my ( $self ) = @_;
    
    # update the values in the form
    for my $w ( $self->find_fields ) {
        $w->set_is_updating( 1 );
        $w->stash_to_widget( $self->stash ) if $w->field;
        $w->set_is_updating( 0 );
    }
}




sub update_stash {
    my ( $self ) = shift;
    warn '$form->update_stash deprecated, use $form->sync_stash';
    $self->sync_stash( @_ );
}

sub sync_stash {
    my ( $self ) = @_;
    
    my $stash = $self->stash;
    
    for my $w ( $self->find_fields ) {
        $w->widget_to_stash( $stash ) if $w->field;
    }
    
    #$stash->set_modified( 1 );
}




package Gapp::Meta::Widget::Custom::Trait::Form;
{
  $Gapp::Meta::Widget::Custom::Trait::Form::VERSION = '0.60';
}
sub register_implementation { 'Gapp::Meta::Widget::Native::Trait::Form' };

1;


__END__

=pod

=head1 NAME

Gapp::Meta::Widget::Native::Trait::Form - Form trait for widgets

=head1 DESCRIPTION

Apply this traits to widgets that you want to use as forms.

=head1 SYNOPSIS

    use Gapp::Actions::Form qw( Ok );

    Gapp::Window->new(

        traits => [qw( Form )],

        content => [

            Gapp::HBox->new(

                Gapp::Entry->new( field => 'user.name' ),

                Gapp::Button->new( action => Ok ),

            )

        ],

    );
    
=head1 PROVIDED ATTRIBUTES

=over 4

=item B<context>

=over 4

=item is rw

=item isa L<Gapp::Form::Context>|Undef

=back

The context is used to sync data between your objects or data structures and
the form fields.

=item B<stash>

=over 4

=item is rw

=item isa L<Gapp::Form::Stash>|Undef

=back

The stash is used to store the values of the form fields. Calling C<apply> or C<ok>
on the form will update the values in the stash. Calling C<update> on the form will
update your field values with those in the stash.

=item B<sync>

=over 4

=item is rw

=item isa Bool

=item default 1

=back

If set to C<true> and the form has a C<context>, the objects in the context will
be updated as the user updates the form. If you make changes to the objects, you
will need to call C<update_from_context> to see your changes reflected in the form.

=back

=head1 PROVIDED METHODS

=over 4

=item B<apply>

Updates the stash and context with values from the form.

=item B<close>

Destroys the form.

=item B<cancel>

Calls C<close>

=item B<ok>

Calls C<apply> then C<close>.

=item B<find_fields>

Returns a list of all the fields within the form.

=item B<update>

Update the fields widgets with the values contained in the stash.

=item B<update_stash>

Update the stash with values in the field widgets.

=item B<update_from_context>

Updates the stash using the context, then calls C<update>.

=item B<update_stash>

Updates the stash using values in the form fields.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut




