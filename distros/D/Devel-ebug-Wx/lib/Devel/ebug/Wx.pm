package Devel::ebug::Wx;

use Wx;

use strict;
use base qw(Wx::Frame Devel::ebug::Wx::Service::Base Class::Accessor::Fast);

our $VERSION = '0.09';

use Wx qw(:aui wxOK);
use Wx::Event qw(EVT_CLOSE);

use Devel::ebug::Wx::ServiceManager;
use Devel::ebug::Wx::ServiceManager::Holder;
use Devel::ebug::Wx::Publisher;

__PACKAGE__->mk_ro_accessors( qw(ebug) );

sub service_name { 'ebug_wx' }
sub initialized  { 1 }

sub new {
    my( $class, $args ) = @_;
    my $self = $class->SUPER::new( undef, -1, 'wxebug', [-1, -1], [-1, 500] );

    EVT_CLOSE( $self, \&_on_close );

    $self->service_manager( Devel::ebug::Wx::ServiceManager->new );
    $self->service_manager->add_service( Devel::ebug::Wx::Publisher->new ); # FIXME
    $self->service_manager->add_service( $self );
    $self->{ebug} = $self->ebug_publisher_service;

    $self->service_manager->initialize;
    $self->service_manager->load_configuration;

    $self->ebug->add_subscriber( 'load_program', $self, '_pgm_load' );
    $self->ebug->add_subscriber( 'finished', $self, '_pgm_stop' );

    $self->SetMenuBar( $self->command_manager_service->get_menu_bar );

    $self->ebug->load_program( $args->{argv} );

    return $self;
}

sub _on_close {
    my( $self ) = @_;

    $self->service_manager->finalize( $self );
    $self->Destroy;
}

sub _pgm_load {
    my( $self, $ebug, $event, %params ) = @_;

    $self->SetTitle( $params{filename} );
}

sub _pgm_stop {
    my( $self, $ebug, $event, %params ) = @_;

    Wx::MessageBox( "Program terminated", "wxebug", wxOK, $self );
}

1;

__END__

=head1 NAME

Devel::ebug::Wx - GUI interface for your (d)ebugging needs

=head1 SYNOPSIS

  # it's easier to use the 'ebug_wx' script
  my $app = Wx::SimpleApp->new;
  my $wx = Devel::ebug::Wx->new( { argv => \@ARGV } );
  $wx->Show;
  $app->MainLoop;

=head1 DESCRIPTION

L<Devel::ebug::Wx> is a GUI front end to L<Devel::ebug>.

The core is a publisher/subscriber wrapper around L<Devel::ebug>
(L<Devel::ebug::Wx::Publisher>) plus a plugin system for defining menu
commands and keyboard bindings (L<Devel::ebug::Wx::Command::*>) and
views (L<Devel::ebug::Wx::View::*>).

The wxWidgets Advanced User Interface (AUI) is used, so it is possible
to dock/undock and arrange views.

=head1 TODO

=over 4

=item * make a saner interface for plugins

command is just an action (coderef) with a string id
command description ties commands to the CommandManager to create menus

=item * define a service interface

for example for code-viewing, gui management, view management
allow enabling/disabling services, commands, views
auto-disable commands/views/services with clashing identifiers

=item * configuration interface

allow a configuration view to configure multiple
  objects (by explicit registration)

=item * notebooks

better editing interface
better debugging; edge cases still present, esp. at load time
rethink container view interface and the whole concept of multiviews

=item * better handling for program termination

visual feedback in the main window
disable commands/etc when they do not make sense

=item * the command manager must allow dynamic menus

command returns a (subscribable) handle that can be used to
  poll/listen to changes
explict use of update_ui is an hack!

=item * break on subroutine, undo, watchpoints

=item * show pad, show package variables, show packages

=item * see the FIXMEs

=back

=head1 SEE ALSO

L<Devel::ebug>, L<ebug_wx>, L<Wx>, L<ebug>

=head1 AUTHOR

Mattia Barbon, C<< <mbarbon@cpan.org> >>

=head1 COPYRIGHT

Copyright (C) 2007, Mattia Barbon

This program is free software; you can redistribute it or modify it
under the same terms as Perl itself.
