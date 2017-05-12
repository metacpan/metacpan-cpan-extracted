package Gapp::App::Widget::Role::HasApp;
{
  $Gapp::App::Widget::Role::HasApp::VERSION = '0.222';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

has 'app' => (
    is => 'rw',
    isa => 'Gapp::App',
    weak_ref => 1,
);


1;


__END__

=pod

=head1 NAME

Gapp::App::Widget::Role::HasApp - Provides app attribute

=head1 DESCRIPTION

Apply this role to widgets which should have a reference to the application.

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<app>

A weak reference to the application object.

=over 8

=item is rw

=item isa Gapp::App

=item default Undef

=item weak_ref

=back

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2012 Jeffrey Ray Hallock.
    
    This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=cut




