package EWS::Calendar::Viewer::Controller::Calendar;
BEGIN {
  $EWS::Calendar::Viewer::Controller::Calendar::VERSION = '1.111982';
}

use strict;
use warnings FATAL => 'all';

use base qw( Catalyst::Controller );

use DateTime;
use Calendar::Simple ();

__PACKAGE__->config->{namespace} = 'calendar';

sub index : Chained('/base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{calendar} = Calendar::Simple::calendar(
        $c->stash->{now}->month,
        $c->stash->{now}->year,
        $c->config->{start_of_week},
    );

    $c->forward('retrieve');
    $c->stash->{template} = 'month.tt';
}

sub get_year : Chained('/base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $year ) = @_;

    $c->detach('index') unless $year =~ /^\d{4}$/;
    
    $c->stash->{now}->set( year => $year );
}

sub custom_year : Chained('get_year') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->forward('index');
}

sub get_month : Chained('get_year') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $month ) = @_;

    $c->detach('index')
        unless $month =~ /^\d{2}$/ and (($month >= 1) and ($month <= 12));
    
    $c->stash->{now}->set( month => $month );
}

sub custom_month : Chained('get_month') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->forward('index');
}

sub retrieve : Private {
    my ($self, $c) = @_;

    $c->stash->{entries} = $c->model('EWSClient')->calendar->retrieve({
        start => $c->stash->{now},
        end   => $c->stash->{now}->clone->add( months => 1 ),
    })->items;

    $c->stash->{retrieved} = DateTime->now();
}

1;
