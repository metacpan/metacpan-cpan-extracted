package Grimlock::Web::Controller::Root;
{
  $Grimlock::Web::Controller::Root::VERSION = '0.11';
}
use Moose;
use namespace::autoclean;

BEGIN { extends 'Grimlock::Web::Controller::API' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

Grimlock::Web::Controller::Root - Root Controller for Grimlock::Web

=head1 DESCRIPTION

A sensible blog system.

=head1 METHODS

=cut

sub base : Chained('/api/base') PathPart('') CaptureArgs(0) {}

=head2 index

The root page (/)

=cut

sub index :Chained('base') Path :Args(0) ActionClass('REST') {}

sub index_GET {
  my ( $self, $c ) = @_;
  return $self->status_ok($c, 
    entity => {
      entries => [ $c->model('Database::Entry')->front_page_entries ]
    }
  );
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Devin Austin

L<mailto:dhoss@cpan.org>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
