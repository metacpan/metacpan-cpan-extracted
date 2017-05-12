package Gapp::Meta::Widget::Native::Role::HasMnemonic;
{
  $Gapp::Meta::Widget::Native::Role::HasMnemonic::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

use Gapp::Actions::Util qw( parse_action );
use Gapp::Types qw( GappAction );

has 'mnemonic' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'use_mnemonic' => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

before _build_gobject => sub {
    my ( $self ) = @_;
    
    # fetch mnemonic from action
    if ( $self->can('action') ) {
        my ( $action, @args ) = parse_action ( $self->action );
        if ( is_GappAction ( $action ) && $action->mnemonic ) {
            if ( ! $self->label && ! $self->mnemonic ) {
                $self->set_mnemonic( $action->mnemonic );
            }
        }  
    }
    
   # if mnemonic and use_mnemonic, set the constructor args
   if ( $self->mnemonic and $self->use_mnemonic ) {
        $self->set_constructor( 'new_with_mnemonic' );
        $self->set_args( [ $self->mnemonic] );
   }
    

};


1;


__END__

=pod

=head1 NAME

Gapp::Meta::Widget::Native::Role::HasMnemonic - mnemonic attribute for widgets

=head1 SYNOPSIS

    Gapp::Button->new( mnemonic => 'E_xit' );
    
=head1 PROVIDED ATTRIBUTES

=over 4

=item B<mnemonic>

=over 4

=item is rw

=item isa Str|Undef

=item default Undef

=back

The mnemonic to apply to the widget.

=item B<use_mnemonic>

=over 4

=item is rw

=item isa Str|Undef

=item 

=back

The mnemonic to apply to the widget.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut