package Flower::Chronos;
use strict;
use warnings;
use Data::Printer;


use Flower::Chronos::Logger;
use Flower::Chronos::Tracker;
use Flower::Chronos::Application::Firefox;
use Flower::Chronos::Application::Chromium;
use Flower::Chronos::Application::Skype;
use Flower::Chronos::Application::Pidgin;
use Flower::Chronos::Application::Thunderbird;
use Flower::Chronos::Application::GnomeTerminal;
use Flower::Chronos::Application::GoogleChrome;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;
    $self->{last}  = {};
    $self->{t_end}  = 0;
    $self->{logger}  = Flower::Chronos::Logger->build($params{logger});
    $self->{tracker} = Flower::Chronos::Tracker->new(
        idle_timeout  => $params{idle_timeout},
        flush_timeout => $params{flush_timeout},
        applications  => [
            Flower::Chronos::Application::Firefox->new,
            Flower::Chronos::Application::GoogleChrome->new,
            Flower::Chronos::Application::Chromium->new,
            Flower::Chronos::Application::Skype->new,
            Flower::Chronos::Application::Pidgin->new,
            Flower::Chronos::Application::Thunderbird->new,
            Flower::Chronos::Application::GnomeTerminal->new,
        ],
        on_end => sub {
            my ($info) = @_;
            $self->{last} = $self->{logger}->log($info);
            p %params;

        }
    );

    return $self;
}

sub track {
    my $self = shift;

    $self->{tracker}->track;

    return $self;
}

1;
