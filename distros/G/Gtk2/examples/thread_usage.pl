#!/usr/bin/perl

#
# $Id$
#
# -rm
#

use strict;
use warnings;
use Data::Dumper;

use Glib qw(TRUE FALSE);
use Gtk2 qw/-init -threads-init 1.050/;

die "Glib::Object thread safetly failed"
	unless Glib::Object->set_threadsafe (TRUE);

my $win = Gtk2::Window->new;
$win->signal_connect (destroy => sub { Gtk2->main_quit; });
$win->set_title ($0);
$win->set_border_width (6);
$win->set_default_size (640, 480);

my $hbox = Gtk2::HBox->new (FALSE, 6);
$win->add ($hbox);

my $vbox = Gtk2::VBox->new (FALSE, 6);
$hbox->pack_start ($vbox, FALSE, FALSE, 0);

my $worklog = Log->new;
$hbox->pack_start ($worklog, TRUE, TRUE, 0);

my @workers;
my $worker;
foreach (1..5)
{
	$worker = Worker->new ($worklog);
	$vbox->pack_start ($worker, FALSE, FALSE, 0);
	$worker->set_worker_label ('Worker '.$_);
	push @workers, $worker;
}

my $pending = Gtk2::Label->new ('0 jobs pending');
$vbox->pack_start ($pending, FALSE, FALSE, 0);
Glib::Timeout->add (500, sub {
		$pending->set_text (Worker->jobs_pending.' jobs pending');
		1;
	});

my $count = 0;

my $go = Gtk2::Button->new ('_Go');
$vbox->pack_start ($go, FALSE, FALSE, 0);
$go->signal_connect (clicked => sub {
		foreach (@workers)
		{
			Worker->do_job ($count + rand);
			$count++;
		}
	});

my $quit = Gtk2::Button->new_from_stock ('gtk-quit');
$vbox->pack_start ($quit, FALSE, FALSE, 0);
$quit->signal_connect (clicked => sub { 
		$go->set_sensitive (FALSE);
		$quit->set_sensitive (FALSE);
		Worker->all_fired;
		Gtk2->main_quit;
	});

$win->show_all;
Gtk2->main;

package Worker;

use strict;
use warnings;
use Data::Dumper;

use threads;
use threads::shared;
use Thread::Queue;

use Glib qw(TRUE FALSE);

use base 'Gtk2::HBox';

our $_nworkers : shared = 0;
my $_jobs;

BEGIN
{
	$_jobs = Thread::Queue->new;
}

sub do_job
{
	shift; # class

	$_jobs->enqueue (shift);
}

sub all_fired
{
	shift; # class

	# put on a quit command for each worker
	foreach (1..$_nworkers)
	{
		$_jobs->enqueue (undef);
	}
	while ($_nworkers)
	{
		Gtk2->main_iteration;
	}
}

sub jobs_pending
{
	return $_jobs->pending;
}

sub new
{
	my $class = shift;
	my $worklog = shift;

	my $self = Gtk2::HBox->new (FALSE, 6);

	# rebless to a worker
	bless $self, $class;

	# gui section
	
	my $label = Gtk2::Label->new ('Worker:');
	$self->pack_start ($label, FALSE, FALSE, 0);

	my $progress = Gtk2::ProgressBar->new;
	$self->pack_start ($progress, FALSE, FALSE, 0);
	$progress->set_text ('Idle');

	$self->{label} = $label;
	$self->{progress} = $progress;
	$self->{worklog} = $worklog;
	
	# thread section

	$self->{child} = threads->new (\&_worker_thread, $self);

	$_nworkers++;
	
	return $self;
}

sub set_worker_label
{
	my $self = shift;
	my $name = shift;

	$self->{label}->set_text ($name);
}

sub _worker_thread
{
	my $self = shift;

	my $progress = $self->{progress};
	my $worklog = $self->{worklog};

	my $i;
	my $job;
	my $sleep;
	# undef job means quit
	while (defined ($job = $_jobs->dequeue))
	{
		$worklog->insert_msg ($self->{label}->get_text
			              ." is doing job ($job)\n");
		if (rand > 0.5)
		{
			$sleep = 1 + rand;
		}
		else
		{
			$sleep = 1 - rand;
		}
		for ($i = 0; $i < 1.1; $i += 0.25)
		{
			Gtk2::Gdk::Threads->enter;
			$progress->set_fraction ($i);
			$progress->set_text ($i * 100 .'%');
			Gtk2::Gdk::Threads->leave;
			# we're state employee's, so let's do some 'work'...
			sleep $sleep;
		}
		$worklog->insert_msg ($self->{label}->get_text
				      ." done with job ($job)\n");
	}

	$_nworkers--;
}

package Log;

use strict;
use warnings;

use Glib qw(TRUE FALSE);

use base 'Gtk2::ScrolledWindow';

sub new
{
	my $class = shift;

	my $self = Gtk2::ScrolledWindow->new;
	
	my $buffer = Gtk2::TextBuffer->new;

	my $view = Gtk2::TextView->new_with_buffer ($buffer);
	$self->add ($view);
	$view->set (editable => FALSE, cursor_visible => FALSE);

	$self->{view} = $view;
	$self->{buffer} = $buffer;
	
	bless $self, $class;
	
	$self->insert_msg ("Start...\n-------------------------------------\n");
	
	return $self;
}
  
sub insert_msg
{
	my $self = shift;
	my $msg = shift;

	my $buffer = $self->{buffer};
	
	Gtk2::Gdk::Threads->enter;
	my $iter = $buffer->get_end_iter;
	$buffer->insert ($iter, $msg);
	$iter = $buffer->get_end_iter;
	$self->{view}->scroll_to_iter ($iter, 0.0, FALSE, 0.0, 0.0);
	Gtk2::Gdk::Threads->leave;
}
