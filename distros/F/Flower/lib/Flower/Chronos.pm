package Flower::Chronos;
use strict;
use warnings;
use Data::Printer;
our $VERSION = "0.01";

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
__END__

=encoding utf-8

=head1 NAME

Flower::Chronos - automatic time tracking application

=head1 SYNOPSIS

  use Flower::Chronos;


=head1 DESCRIPTION

Flower::Chronos is a class used in C<Flower>.

Flower is a meshed P2P client running between trusted peers on a LAN
or WAN network.


=head1 STATUS

Flower is not yet operational.

=head1 SYNOPSIS

  git clone git://github.com/santex/Flower.git
  cd Flower
  perl Makefile.PL
  make
  script/flower <your-ip-address> 2222

Then visit L<http://127.0.0.1:2222> in your browser.

=head1 AUTHOR

Hagen Geissler, E<lt>santex@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



