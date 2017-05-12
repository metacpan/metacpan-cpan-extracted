=head1 NAME

Gtk2::CV::Progress - a simple progress widget

=head1 SYNOPSIS

  use Gtk2::CV::ImageWindow;

=head1 DESCRIPTION

=head2 METHODS

=over 4

=cut

package Gtk2::CV::Progress;

use common::sense;
use Gtk2;
use Gtk2::CV;

use Time::HiRes 'time';

sub INITIAL   (){ 0.15 } # initial popup delay
sub INTERVAL1 (){ 0.01 } # minimum update interval
sub INTERVAL2 (){ 0.10 } # minimum update interval

=item new Gtk2::CV::Progress ...

 title => the progress widget title (mandatory)
 work  => amount of work (default 1)

=cut

sub new {
   my $class = shift;

   my $self = bless {
      @_,
   }, $class;

   $self->{work} = 1 unless defined $self->{work};
   $self->{next} = time + INITIAL;
   $self->update ($self->{cur});

   $self
}

=item $progress->update ($work)

The amount of work already done.

=cut

sub update {
   my ($self, $progress) = @_;

   my $now = time;

   if ($now > $self->{next}) {
      remove Glib::Source delete $self->{timeout}
         if $self->{timeout};

      Gtk2::CV::disable_aio;

      if (!$self->{window}) {
         $self->{window} = new Gtk2::Window 'toplevel';
         $self->{window}->set (
            role            => "progress",
            window_position => "mouse",
            accept_focus    => 0,
            focus_on_map    => 0,
            decorated       => 0,
            default_width   => 200,
            default_height  => 30,
         );
         $self->{window}->add (my $vbox = new Gtk2::VBox);
         $vbox->add ($self->{label} = new Gtk2::Label $self->{title}) if exists $self->{title};
         $vbox->add ($self->{bar} = new Gtk2::ProgressBar);

         $self->{window}->signal_connect (delete_event => sub { $_[0]->hide; 1 });

         $self->{window}->show_all;
         $self->{window}->show_now;

         $self->{next} = $now + INTERVAL1;
      } else {
         $self->{next} = $now + INTERVAL2;
      }

      $self->{bar}->set_fraction ($progress / ($self->{work} || 1));

      if ($self->{work} > 1) {
         $self->{bar}->set_text ("$progress / $self->{work}");
      } else {
         $self->{bar}->set_text (sprintf "%2d%%", 100 * $progress / ($self->{work} || 1));
      }

      Gtk2->main_iteration while Gtk2->events_pending;

      Gtk2::CV::enable_aio;
   } else {
      $self->{timeout} ||= add Glib::Timeout 1000 * ($self->{next} - $now), sub {
         $self->{next} = 0;
         $self->update ($self->{cur});
         0
      };
   }
}

=item $progress->increment

Increment the progress value by the given amount (default: 1).

=cut

sub increment {
   my ($self, $inc) = @_;

   if (($self->{cur} += $inc || 1) >= $self->{work}) {
      delete $self->{next};
   }

   $self->update ($self->{cur});
}

=item $progress->set_title ($title)

Change the title to the given string.

=cut

sub set_title {
   my ($self, $title) = @_;

   $self->{title} = $title;

   if ($self->{window}) {
      $self->{label}->set_text ($title);
      Gtk2->main_iteration while Gtk2->events_pending;
   }
}

=item $progress->inprogress

Return true as long as the current progress is less than the work value.

=cut

sub inprogress {
   my ($self) = @_;

   $self->{cur} < $self->{work}
}

sub DESTROY {
   my ($self) = @_;

   $self->{window}->destroy if $self->{window};
}

=back

=head1 AUTHOR

Marc Lehmann <schmorp@schmorp.de>

=cut

1

