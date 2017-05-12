package Gapp::App::Widget::Traits::HasApp;
{
  $Gapp::App::Widget::Traits::HasApp::VERSION = '0.222';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

has 'app' => (
    is => 'rw',
    isa => 'Gapp::App',
    weak_ref => 1,
);


package Gapp::Meta::Widget::Custom::Trait::HasApp;
{
  $Gapp::Meta::Widget::Custom::Trait::HasApp::VERSION = '0.222';
}
sub register_implementation { 'Gapp::Meta::Widget::Native::Trait::HasApp' };

1;


__END__

=pod

=head1 NAME

Gapp::App::Widget::Trait::HasApp - Provides app attribute

=head1 DESCRIPTION

Apply this traits to widgets which should have a reference to the application.

=head1 SYNOPSIS

    use Gapp::App;

    $app = Gapp::App->new;

    $w = Gapp::Window->new( traits => [qw( HasApp )], app => $app );

    ...

    # or use it in a subclass

    package Foo::Window;

    use Moose;

    extends 'Gapp::Window';

    with 'Gapp::App::Widget::Trait::HasApp';

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




