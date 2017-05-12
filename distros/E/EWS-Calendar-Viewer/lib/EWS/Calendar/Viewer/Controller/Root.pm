package EWS::Calendar::Viewer::Controller::Root;
BEGIN {
  $EWS::Calendar::Viewer::Controller::Root::VERSION = '1.111982';
}
use strict;
use warnings;

use base 'Catalyst::Controller';
use DateTime;

__PACKAGE__->config->{namespace} = '';

sub base : Chained('/') PathPart('') CaptureArgs(0) {
    my( $self, $c )  = @_;

    $c->stash->{now} = DateTime->now->set( day => 1 );
    $c->stash->{version} = $EWS::Calendar::Viewer::VERSION;
    $c->stash->{privacy_level} = ($c->config->{privacy_level} || 'public');

    my @days = (qw/ Sunday Monday Tuesday Wednesday Thursday Friday Saturday /);
    my $sow = $c->config->{start_of_week};
    $c->stash->{days} = [ @days[$sow .. 6], @days[0 .. ($sow - 1)] ];
}

sub end : ActionClass('RenderView') {}

1;
