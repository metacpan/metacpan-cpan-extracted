use strict;
package Event::MakeMaker;
use Config;
use base 'Exporter';
use vars qw(@EXPORT_OK $installsitearch);
@EXPORT_OK = qw(&event_args $installsitearch);

my %opt;
for my $opt (split /:+/, $ENV{PERL_MM_OPT}) {
    my ($k,$v) = split /=/, $opt;
    $opt{$k} = $v;
}

my $extra = $Config{sitearch};
$extra =~ s,$Config{prefix},$opt{PREFIX}, if
    exists $opt{PREFIX};

for my $d ($extra, @INC) {
    if (-e "$d/Event/EventAPI.h") {
	$installsitearch = $d;
	last
    }
}

sub event_args {
    my %arg = @_;
    $arg{INC} .= " -I$installsitearch/Event";
    %arg;
}

1;
__END__

=head1 NAME

Event::MakeMaker - MakeMaker glue for the C-level Event API

=head1 SYNOPSIS

This is an advanced feature of Event.

=head1 DESCRIPTION

For optimal performance, hook into Event at the C-level.  You'll need
to make changes to your C<Makefile.PL> and add code to your C<xs> /
C<c> file(s).

=head1 WARNING

When you hook in at the C-level you get a I<huge> performance gain,
but you also reduce the chances that your code will work unmodified
with newer versions of C<perl> or C<Event>.  This may or may not be a
problem.  Just be aware, and set your expectations accordingly.

=head1 HOW TO

=head2 Makefile.PL

  use Event::MakeMaker qw(event_args);

  # ... set up %args ...

  WriteMakefile(event_args(%args));

=head2 XS

  #include "EventAPI.h"

  BOOT:
    I_EVENT_API("YourModule");

=head2 API (v21)

 struct EventAPI {
    I32 Ver;

    /* EVENTS */
    void (*queue   )(pe_event *ev);
    void (*start   )(pe_watcher *ev, int repeat);
    void (*now     )(pe_watcher *ev);
    void (*stop    )(pe_watcher *ev, int cancel_events);
    void (*cancel  )(pe_watcher *ev);
    void (*suspend )(pe_watcher *ev);
    void (*resume  )(pe_watcher *ev);

    /* All constructors optionally take a stash and template.  Either
      or both can be NULL.  The template should not be a reference. */
    pe_idle     *(*new_idle  )(HV*, SV*);
    pe_timer    *(*new_timer )(HV*, SV*);
    pe_io       *(*new_io    )(HV*, SV*);
    pe_var      *(*new_var   )(HV*, SV*);
    pe_signal   *(*new_signal)(HV*, SV*);

    /* TIMEABLE */
    void (*tstart)(pe_timeable *);
    void (*tstop)(pe_timeable *);

    /* HOOKS */
    pe_qcallback *(*add_hook)(char *which, void *cb, void *ext_data);
    void (*cancel_hook)(pe_qcallback *qcb);

    /* STATS */
    void (*install_stats)(pe_event_stats_vtbl *esvtbl);
    void (*collect_stats)(int yes);
    pe_ring *AllWatchers;

    /* TYPEMAP */
    SV   *(*watcher_2sv)(pe_watcher *wa);
    void *(*sv_2watcher)(SV *sv);
    SV   *(*event_2sv)(pe_event *ev);
    void *(*sv_2event)(SV *sv);
 };

=head2 EXAMPLE

  static pe_io *X11_ev=0;

  static void x_server_dispatch(void *ext_data)
  { ... }

  if (!X11_ev) {
    X11_ev = GEventAPI->new_io(0,0);
    X11_ev->poll = PE_R;
    sv_setpv(X11_ev->base.desc, "X::Server");
    X11_ev->base.callback = (void*) x_server_dispatch;
    X11_ev->base.ext_data = <whatever>;
    X11_ev->base.prio = PE_PRIO_NORMAL;
  }
  X11_ev->fd = x_fd;
  GEventAPI->resume((pe_event*) X11_ev);
  GEventAPI->start((pe_event*) X11_ev, 0);

=head2 BUT I NEED A NEW TYPE OF WATCHER FOR MY INTERGALACTIC INFEROMETER

I'd prefer not to export the entire Event.h apparatus in favor of
minimizing interdependencies.  If you really, really need to create a
new type of watcher send your problem analysis to the mailing list!

=cut
