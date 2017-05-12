package Gapp::Meta::Widget::Native::Role::HasAction;
{
  $Gapp::Meta::Widget::Native::Role::HasAction::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

use MooseX::Types::Moose qw( Undef );
use Gapp::Types qw( GappActionOrArrayRef );

has 'action' => (
    is => 'rw',
    isa => GappActionOrArrayRef|Undef,
);



1;


__END__

=pod

=head1 NAME

Gapp::Meta::Widget::Native::Role::HasAction - action attribute for widgets

=head1 SYNOPSIS

    use Gapp::Actions::Basic qw( Quit );

    Gapp::Button->new( action => Quit );
    
    Gapp::ImageMenuItem->new( action => Quit );
    
    Gapp::ToolButton->new( action => Quit );

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<action>

=over 4

=item is rw

=item isa L<Gapp::Action>|[L<Gapp::Action>, @args]|Undef

=back

Specifies an action for the widget is activated. The action defines a callback
to be executed and properties of the widget, such as C<icon>, C<label>, and
C<tooltip>. You spcify arguments to pass to the call-back by using an C<ArrayRef>
containing the action and the arguments:

 Gapp::Button->new( action => [Quit, @args ] );

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut