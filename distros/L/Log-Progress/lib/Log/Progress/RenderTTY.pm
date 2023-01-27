package Log::Progress::RenderTTY;
$Log::Progress::RenderTTY::VERSION = '0.13';
use Moo 2;
use Carp;
use Try::Tiny;
use IO::Handle;
use Log::Progress::Parser;
use Term::Cap;
use Scalar::Util;

# ABSTRACT: Render progress state on a terminal


has listen_resize  => ( is => 'ro' );
has tty_metrics    => ( is => 'lazy', clearer => 1 );
has termcap        => ( is => 'lazy' );
has parser         => ( is => 'rw' );
has out            => ( is => 'rw' );
has _prev_output   => ( is => 'rw' );
has _winch_handler => ( is => 'rw' );

sub _build_tty_metrics {
	my $self= shift;
	my $stty= `stty -a` or warn "unable to run 'stty -a' to fetch terminal size\n";
	my ($speed)= ($stty =~ /speed[ =]+(\d+)/);
	my ($cols)=  ($stty =~ /columns[ =]+(\d+)/);
	my ($rows)=  ($stty =~ /rows[ =]+(\d+)/);
	$self->_init_window_change_watch() if $self->listen_resize and $cols;
	return { speed => $speed || 9600, cols => $cols || 80, rows => $rows || 25 };
}

sub _build_termcap {
	my $self= shift;
	my $speed= $self->tty_metrics->{speed} || 9600;
	return Tgetent Term::Cap { TERM => '', OSPEED => $speed };
}

sub _init_window_change_watch {
	my $self= shift;
	return if defined $self->_winch_handler;
	try {
		my $existing= $SIG{WINCH};
		Scalar::Util::weaken($self);
		my $handler= sub {
			$self->clear_tty_metrics if defined $self;
			goto $existing if defined $existing;
		};
		$self->_winch_handler([ $handler, $existing ]);
		$SIG{WINCH}= $handler;
	}
	catch {
		warn "Can't install SIGWINCH handler\n";
	};
}


sub format {
	my ($self, $state, $dims)= @_;
	
	# Build the new string of progress ascii art, but without terminal escapes
	my $str= '';
	$dims->{message_margin}= $dims->{cols} * .5;
	if ($state->{step}) {
		$dims->{title_width}= 10;
		for (values %{ $state->{step} }) {
			$dims->{title_width}= length($_->{title})
				if length($_->{title} || '') > $dims->{title_width};
		}
		for (sort { $a->{idx} <=> $b->{idx} } values %{ $state->{step} }) {
			$str .= $self->_format_step_progress_line($_, $dims);
		}
		$str .= "\n";
	}
	$str .= $self->_format_main_progress_line($state, $dims);
	return $str;
}


sub render {
	my $self= shift;
	my ($cols, $rows)= @{ $self->tty_metrics }{'cols','rows'};
	my $output= $self->format($self->parser->parse, {
		cols => $cols,
		rows => $rows
	});
	
	# Now the fun part.  Diff vs. previous output to figure out which lines (if any)
	# have changed, then move the cursor to those lines and repaint.
	# To make things extra interesting, the old output might have scrolled off the
	# screen, and if the new output also scrolls off the screen then we want to
	# let it happen naturally so that the scroll-back buffer is consistent.
	my @prev= defined $self->_prev_output? (split /\n/, $self->_prev_output, -1) : ();
	my @next= split /\n/, $output, -1;
	# we leave last line blank, so all calculations are rows-1
	my $first_vis_line= @prev > ($rows-1)? @prev - ($rows-1) : 0;
	my $starting_row= @prev > ($rows-1)? 0 : ($rows-1) - @prev;
	my $up= $self->termcap->Tputs('up');
	my $down= $self->termcap->Tputs('do');
	my $clear_eol= $self->termcap->Tputs('ce');
	my $str= '';
	my $cursor_row= $rows-1;
	my $cursor_seek= sub {
		my $dest_row= shift;
		if ($cursor_row > $dest_row) {
			$str .= $up x ($cursor_row - $dest_row);
		} elsif ($dest_row > $cursor_row) {
			$str .= $down x ($dest_row - $cursor_row);
		}
		$cursor_row= $dest_row;
	};
	my $i;
	for ($i= $first_vis_line; $i < @prev; $i++) {
		if ($prev[$i] ne $next[$i]) {
			# Seek to row
			$cursor_seek->($i - $first_vis_line + $starting_row);
			# clear line and replace
			$str .= $clear_eol . $next[$i] . "\n";
			$cursor_row++;
		}
	}
	$cursor_seek->($rows-1);
	# Now, print any new rows in @next, letting them scroll the screen as needed
	while ($i < @next) {
		$str .= $next[$i++] . "\n";
	}
	$self->_prev_output($output);
	
	($self->out || \*STDOUT)->print($str);
}

sub _format_main_progress_line {
	my ($self, $state, $dims)= @_;
	
	my $message= $state->{message};
	$message= '' unless defined $message;
	$message= sprintf("(%d/%d) %s", $state->{current}, $state->{total}, $message)
		if defined $state->{total} and defined $state->{current};
	
	my $max_chars= $dims->{cols} - 8;
	return sprintf "[%-*s] %3d%%\n  %.*s",
		$max_chars, '=' x int( ($state->{progress}||0) * $max_chars + .000001 ),
		int( ($state->{progress}||0) * 100 + .0000001 ),
		$dims->{cols}, $message;
}

sub _format_step_progress_line {
	my ($self, $state, $dims)= @_;
	
	my $message= $state->{message};
	$message= '' unless defined $message;
	$message= sprintf("(%d/%d) %s", $state->{current}, $state->{total}, $message)
		if defined $state->{total} and defined $state->{current};
	
	my $max_chars= $dims->{cols} - $dims->{message_margin} - $dims->{title_width} - 11;
	return sprintf "  %-*.*s [%-*s] %3d%% %.*s\n",
		$dims->{title_width}, $dims->{title_width}, $_->{title},
		$max_chars, '=' x int( ($state->{progress}||0) * $max_chars + .000001 ),
		int( ($state->{progress}||0) * 100 + .000001 ),
		$dims->{message_margin}, $message;
}

sub DESTROY {
	my $self= shift;
	if ($self->_winch_handler) {
		if ($SIG{WINCH} eq $self->_winch_handler->[0]) {
			$SIG{WINCH}= $self->_winch_handler->[1];
		} else {
			warn "Can't uninstall SIGWINCH handler\n";
		}
		$self->_winch_handler(undef);
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Progress::RenderTTY - Render progress state on a terminal

=head1 SYNOPSIS

  use Log::Progress::Parser;
  use Log::Progress::RenderTTY;
  my $p= Log::Progress::Parser->new( ... );
  my $r= Log::Progress::RenderTTY->new( parser => $p );
  while (sleep .5) {
    $r->render;  # calls $p->parse and renders result
  }

=head1 DESCRIPTION

This module takes the state data parsed by L<Log::Progress::Parser> and
renders it to a terminal as a progress bar, or multiple progress bars if
sub-steps are found.

Your terminal must be supported by L<Term::Cap>, and you must have a C<stty>
command on your system for the progress bar to display correctly.

=head1 ATTRIBUTES

=head2 parser

Reference to a L<Log::Progress::Parser>, whose L<state|Log::Progress::Parser/state> should
be rendered.

=head2 tty_metrics

Stores the dimensions and baud rate of the current terminal.  It fetched this
information by shelling out to C<stty -a>, which should work on most unix flavors.

=head2 termcap

Reference to a L<Term::Cap> object that is used for generating TTY escape sequences.

=head2 listen_resize

The way to listen to screen resizes on Linux is to trap SIGWINCH and re-load
the terminal dimensions.  The problem is that you can only have one C<$SIG{WINCH}>,
so things get messy when multiple objects try to watch for changes.

If you want this instance of RenderTTY to set a signal handler for SIGWINCH,
set this attribute to a true value I<during the constrctor>.  It is read-only
after the object is created.

Otherwise, you can set up the signal handler yourself, using whatever framework you
happen to be using:

  use AnyEvent;
  my $sig= AE::signal WINCH => sub { $renderer->clear_tty_metrics; };

=head2 out

File handle on which the progress bar will be rendered.

=head1 METHODS

=head2 format

  $text= $renderer->format( \%state, \%dimensions );

Format progress state (from L<Log::Progress::Parser>) as plain multi-line text.
The dimensions are used to size the text to the viewport, and also store additional
derived measurements.

Returns a plain-text string.  The lines of text are then re-parsed by the L</render>
method to apply the necessary terminal cursor escapes.

=head2 render

  $renderer->render

Call C<< ->parser->parse >>, format the parser's state as text, then print
terminal escape sequences to display the text with minimal overwriting.

This method goes to some additional effort to make sure the scrollback buffer
stays readable in the case where your sub-steps exceed the rows of the
terminal window.

Note that this method can trigger various terminal-related exceptions since
it might be the first thing that lazy-initializes the L</tty_metrics>
or L</termcap> attributes.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.13

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
