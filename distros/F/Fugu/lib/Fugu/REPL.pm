# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Fugu::REPL;
our $VERSION = '0.3.0';

use IO::Select;
use POSIX qw(BRKINT ECHO EINTR ICANON ICRNL IEXTEN INPCK ISIG ISTRIP IXON
    TCSADRAIN TCSANOW VMIN VTIME);
use Scalar::Util qw(openhandle);

# Fugu::REPL - a line editor for an operator prompt.
#
# The module reads one operator command line from a terminal. It edits
# the line, completes a word, keeps a session history in memory, and
# filters untrusted bytes before it shows them.
#
# The module stands alone: core Perl only, no other Fugu module, and
# no log. Every failure is a return value. It operates inside the
# stdio tty promises of pledge(2): it opens no file, creates no
# process, and reaches no network. The escape sequences are the fixed
# ANSI set, because a terminfo read needs the rpath promise.
#
# The module reads with sysread and keeps its own input buffer. A
# buffered read can take more bytes than one call consumes, and then
# select(2) reports no more input. The buffer lives on the object, so
# type-ahead survives across calls.
#
# The editor holds raw mode only while it reads, and restore puts the
# terminal back on every exit path.

use constant {
	DEFAULT_PROMPT       => '> ',
	DEFAULT_HISTORY_SIZE => 500,

	# How long an escape sequence may stay incomplete before the
	# editor treats the escape as a lone key.
	ESCAPE_WAIT => 0.05,

	READ_SIZE => 4096,
};

# One valid UTF-8 sequence of two or more bytes, from RFC 3629: no
# overlong form, no surrogate, and nothing above U+10FFFF.
my $UTF8 = qr/
      [\xC2-\xDF][\x80-\xBF]
    | \xE0[\xA0-\xBF][\x80-\xBF]
    | [\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}
    | \xED[\x80-\x9F][\x80-\xBF]
    | \xF0[\x90-\xBF][\x80-\xBF]{2}
    | [\xF1-\xF3][\x80-\xBF]{3}
    | \xF4[\x80-\x8F][\x80-\xBF]{2}
/x;

# The escape sequences of the key subset. The CSI finals and the SS3
# finals share the single-letter entries.
my %SEQUENCE_KEY = (
	'A'  => 'up',
	'B'  => 'down',
	'C'  => 'forward',
	'D'  => 'back',
	'H'  => 'home',
	'F'  => 'end',
	'Z'  => 'backtab',
	'1~' => 'home',
	'7~' => 'home',
	'4~' => 'end',
	'8~' => 'end',
);

# The control bytes of the key subset.
my %CONTROL_KEY = (
	"\x01" => 'home',         # Ctrl-A
	"\x02" => 'back',         # Ctrl-B
	"\x03" => 'interrupt',    # Ctrl-C
	"\x04" => 'eot',          # Ctrl-D
	"\x05" => 'end',          # Ctrl-E
	"\x06" => 'forward',      # Ctrl-F
	"\x08" => 'backspace',    # Ctrl-H
	"\x09" => 'tab',
	"\x0A" => 'enter',
	"\x0B" => 'kill-end',     # Ctrl-K
	"\x0C" => 'redraw',       # Ctrl-L
	"\x0D" => 'enter',
	"\x0E" => 'down',         # Ctrl-N
	"\x10" => 'up',           # Ctrl-P
	"\x15" => 'kill-line',    # Ctrl-U
	"\x17" => 'kill-word',    # Ctrl-W
	"\x7F" => 'backspace',
);

# Fugu::REPL->new(%args):
#	in           => $fh	the input handle; default STDIN
#	out          => $fh	the output handle; default STDOUT
#	prompt       => $string	the prompt; default '> '
#	commands     => \%table	command name to summary
#	prefix       => $string	the command prefix; default ''
#	complete     => \&code	the word-completion callback
#	watch        => \@fhs	extra read handles that end a read
#	history_size => $count	lines the history keeps; default 500
#
#	The method opens nothing and changes no terminal setting. A
#	complete argument that is not a code reference and a watch
#	handle with no descriptor are programming errors, so new dies.
sub new ( $class, %args )
{
	my $complete = $args{complete};
	die "complete parameter must be a code reference\n"
	    if defined $complete && ref $complete ne 'CODE';

	my $watch = $args{watch} // [];
	_check_watch($watch);

	return bless {
		in           => $args{in}       // \*STDIN,
		out          => $args{out}      // \*STDOUT,
		prompt       => $args{prompt}   // DEFAULT_PROMPT,
		commands     => $args{commands} // {},
		prefix       => $args{prefix}   // '',
		complete     => $complete,
		watch        => $watch,
		history_size => $args{history_size} // DEFAULT_HISTORY_SIZE,
		history      => [],
		pending      => '',
		event        => undef,
		ready        => undef,
		termios      => undef,
	}, $class;
}

# $self->read_line:
#	Read one line and return it, without the terminator. Return
#	undef at an end of file, when a watched handle becomes
#	readable, and on an interrupt; event() names the outcome. The
#	line joins the history when it is not empty and not the
#	previous line.
sub read_line ($self)
{
	my $line = $self->_read( $self->{prompt} );
	return unless defined $line;

	my $history = $self->{history};
	$self->add_history($line)
	    if length $line && ( !@$history || $history->[-1] ne $line );

	return $line;
}

# $self->confirm($question):
#	Ask a yes-or-no question. Return 1 for yes and 0 for every
#	other answer. The default is no: an empty answer, an end of
#	file, and an interrupt all answer no. A gate that a stray
#	keystroke can open is not a gate. The answer stays out of the
#	history.
sub confirm ( $self, $question )
{
	my $prompt = "$question [y/N] ";

	# The editor draws the prompt itself. The plain mode draws
	# nothing, and a question that nobody sees gates nothing.
	$self->_write($prompt) unless $self->is_interactive;

	my $answer = $self->_read($prompt);
	return 0 unless defined $answer;
	return $answer =~ /^\s*(?:y|yes)\s*$/i ? 1 : 0;
}

# $self->event:
#	The outcome of the most recent read_line or confirm call:
#	'line', 'eof', 'watch', or 'interrupt'. Before the first call
#	the method returns undef.
sub event ($self)
{
	return $self->{event};
}

# $self->ready_handle:
#	The watched handle that ended the read, after an event of
#	'watch'. Return undef otherwise. A closed handle is readable at
#	an end of file, so a caller learns that its peer went away.
sub ready_handle ($self)
{
	return unless ( $self->{event} // '' ) eq 'watch';
	return $self->{ready};
}

# display_filter($bytes):
#	Return the bytes that are safe to show. The filter keeps
#	printable ASCII, the line feed, and the horizontal tab. It
#	removes DEL and the C1 range, as a raw byte and as a UTF-8
#	sequence alike. Every other valid UTF-8 sequence survives
#	whole, and every other byte becomes one question mark.
#
#	An escape sequence in tool output can rewrite what the operator
#	sees. This is a plain function, not a method, because a caller
#	filters bytes that no editor read.
sub display_filter ($bytes)
{
	my $safe = '';

	while (
		$bytes =~ /\G(?:
		      ([\x09\x0A\x20-\x7E]+)	# safe ASCII, kept
		    | [\x7F\x80-\x9F]		# DEL and raw C1, removed
		    | \xC2[\x80-\x9F]		# C1 as UTF-8, removed
		    | ($UTF8)			# valid UTF-8, kept whole
		    | (.)			# anything else: one mark
		)/gcsx
	    )
	{
		if    ( defined $1 ) { $safe .= $1 }
		elsif ( defined $2 ) { $safe .= $2 }
		elsif ( defined $3 ) { $safe .= '?' }
	}

	return $safe;
}

# $self->show($bytes):
#	Filter the bytes with display_filter and write them to the
#	output handle. Return the object.
sub show ( $self, $bytes )
{
	$self->_write( display_filter($bytes) );
	return $self;
}

# $self->help_text:
#	The help for the command table: one line for each command, with
#	the prefix, the name, and the summary, in sorted order. The
#	module generates the help, so the table and the help cannot
#	disagree.
sub help_text ($self)
{
	my $commands = $self->{commands};
	my $prefix   = $self->{prefix};

	my $width = 0;
	for my $name ( keys %$commands ) {
		my $length = length($prefix) + length($name);
		$width = $length if $length > $width;
	}

	my $text = '';
	for my $name ( sort keys %$commands ) {
		$text .= sprintf "%-*s  %s\n", $width, $prefix . $name,
		    $commands->{$name};
	}

	return $text;
}

# $self->history:
#	The session history, oldest first. The history lives in memory
#	only: the module never writes a history file, because a history
#	file leaks the words that an operator typed.
sub history ($self)
{
	return @{ $self->{history} };
}

# $self->add_history($line):
#	Append one line and drop the oldest line above history_size.
#	Return the object.
sub add_history ( $self, $line )
{
	my $history = $self->{history};
	push @$history, $line;
	shift @$history while @$history > $self->{history_size};
	return $self;
}

# $self->is_interactive:
#	Return 1 when the input handle is a terminal, 0 otherwise. With
#	0 the module reads plain lines: no editing, no history recall,
#	and no escape output.
sub is_interactive ($self)
{
	return 0 unless defined fileno $self->{in};
	return POSIX::isatty( $self->{in} ) ? 1 : 0;
}

# $self->prompt(...), $self->commands(...), $self->watch(...):
#	Set or read the prompt, the command table, and the watched
#	handles. A caller changes them when the session state changes,
#	for example when a completion set opens after an unlock.
sub prompt ( $self, @value )
{
	$self->{prompt} = $value[0] if @value;
	return $self->{prompt};
}

sub commands ( $self, @value )
{
	$self->{commands} = $value[0] if @value;
	return $self->{commands};
}

sub watch ( $self, @value )
{
	if (@value) {
		_check_watch( $value[0] );
		$self->{watch} = $value[0];
	}
	return $self->{watch};
}

# $self->restore:
#	Put the terminal settings back and return the object. The
#	method is idempotent: without saved settings it does nothing.
#	The destructor calls it, so no exit path leaves the terminal
#	raw.
sub restore ($self)
{
	my $termios = delete $self->{termios};
	return $self unless defined $termios;

	my $fd = fileno $self->{in};
	$termios->setattr( $fd, TCSADRAIN ) if defined $fd;
	return $self;
}

sub DESTROY ($self)
{
	$self->restore;
}

# _check_watch($handles):
#	Die when the watch list is not an array reference or holds a
#	handle with no descriptor. A handle that select(2) cannot watch
#	is a programming error.
sub _check_watch ($handles)
{
	die "watch parameter must be an array reference\n"
	    unless ref $handles eq 'ARRAY';

	for my $fh (@$handles) {
		my $open = openhandle($fh);
		my $fd   = defined $open ? fileno $open : undef;
		die "watch handle has no descriptor\n"
		    unless defined $fd && $fd >= 0;
	}
	return;
}

# $self->_read($prompt):
#	One read, in the mode that the input handle demands. Clear the
#	event state first, so a caller never reads a stale outcome.
sub _read ( $self, $prompt )
{
	$self->{event} = undef;
	$self->{ready} = undef;

	return $self->_read_editor($prompt) if $self->is_interactive;
	return $self->_read_plain;
}

# $self->_read_plain:
#	Read one plain line: no editing, no history recall, and no
#	escape output. A line that the end of file cuts short is still
#	a line; the end of file itself is the next call's event.
sub _read_plain ($self)
{
	while (1) {
		if ( $self->{pending} =~ s/\A([^\n]*)\n// ) {
			my $line = $1;
			$line =~ s/\r\z//;
			$self->{event} = 'line';
			return $line;
		}

		my $ready = $self->_wait_readable;
		return unless defined $ready && $ready == $self->{in};

		my $count = sysread $self->{in}, my $chunk, READ_SIZE;
		if ( !defined $count ) {
			next if $! == EINTR;
			$self->{event} = 'eof';
			return;
		}
		if ( $count == 0 ) {
			if ( length $self->{pending} ) {
				my $line = $self->{pending};
				$self->{pending} = '';
				$line =~ s/\r\z//;
				$self->{event} = 'line';
				return $line;
			}
			$self->{event} = 'eof';
			return;
		}
		$self->{pending} .= $chunk;
	}
}

# $self->_read_editor($prompt):
#	Read one line in raw mode with the key subset. The terminal is
#	raw only inside this call, and restore runs on every exit path,
#	a die from the completion callback included. Without a
#	terminal setting to change, fall back to the plain mode.
sub _read_editor ( $self, $prompt )
{
	$self->_raw_on or return $self->_read_plain;

	my $line  = eval { $self->_edit($prompt) };
	my $error = $@;
	$self->restore;
	die $error if $error;

	return $line;
}

# $self->_edit($prompt):
#	The editor loop. The line is an array of characters, where one
#	whole UTF-8 sequence counts as one character for the cursor.
sub _edit ( $self, $prompt )
{
	my @chars;
	my $pos     = 0;
	my $history = $self->{history};
	my $recall  = @$history;          # one past the newest line
	my $saved   = '';                 # the line under edit, during recall
	my $cycle;                        # the active completion cycle

	$self->_draw( $prompt, \@chars, $pos );

	while (1) {
		my $key = $self->_next_key;
		if ( !defined $key ) {

			# eof, watch or interrupt ended the wait
			$self->_write("\r\n");
			return;
		}

		$cycle = undef
		    unless !ref $key
		    && ( $key eq 'tab' || $key eq 'backtab' );

		if ( ref $key ) {
			splice @chars, $pos, 0, $key->[1];
			$pos++;
			$self->_draw( $prompt, \@chars, $pos );
		}
		elsif ( $key eq 'enter' ) {
			$self->_write("\r\n");
			$self->{event} = 'line';
			return join '', @chars;
		}
		elsif ( $key eq 'interrupt' ) {

			# An interrupt at the prompt clears the line. It
			# does not end the session; the caller decides.
			$self->_write("^C\r\n");
			$self->{event} = 'interrupt';
			return;
		}
		elsif ( $key eq 'eot' ) {
			if ( !@chars ) {
				$self->_write("\r\n");
				$self->{event} = 'eof';
				return;
			}
			if ( $pos < @chars ) {
				splice @chars, $pos, 1;
				$self->_draw( $prompt, \@chars, $pos );
			}
		}
		elsif ( $key eq 'tab' || $key eq 'backtab' ) {
			( $pos, $cycle ) =
			    $self->_complete( \@chars, $pos, $cycle,
				$key eq 'tab' ? 1 : -1, $prompt );
		}
		elsif ( $key eq 'backspace' ) {
			if ( $pos > 0 ) {
				splice @chars, --$pos, 1;
				$self->_draw( $prompt, \@chars, $pos );
			}
		}
		elsif ( $key eq 'home' ) {
			$pos = 0;
			$self->_draw( $prompt, \@chars, $pos );
		}
		elsif ( $key eq 'end' ) {
			$pos = @chars;
			$self->_draw( $prompt, \@chars, $pos );
		}
		elsif ( $key eq 'back' ) {
			if ( $pos > 0 ) {
				$pos--;
				$self->_draw( $prompt, \@chars, $pos );
			}
		}
		elsif ( $key eq 'forward' ) {
			if ( $pos < @chars ) {
				$pos++;
				$self->_draw( $prompt, \@chars, $pos );
			}
		}
		elsif ( $key eq 'up' ) {
			if ( $recall > 0 ) {
				$saved = join '', @chars
				    if $recall == @$history;
				$recall--;
				@chars = _split_chars( $history->[$recall] );
				$pos   = @chars;
				$self->_draw( $prompt, \@chars, $pos );
			}
		}
		elsif ( $key eq 'down' ) {
			if ( $recall < @$history ) {
				$recall++;
				my $text =
				      $recall == @$history
				    ? $saved
				    : $history->[$recall];
				@chars = _split_chars($text);
				$pos   = @chars;
				$self->_draw( $prompt, \@chars, $pos );
			}
		}
		elsif ( $key eq 'kill-end' ) {
			splice @chars, $pos;
			$self->_draw( $prompt, \@chars, $pos );
		}
		elsif ( $key eq 'kill-line' ) {
			@chars = ();
			$pos   = 0;
			$self->_draw( $prompt, \@chars, $pos );
		}
		elsif ( $key eq 'kill-word' ) {
			splice @chars, --$pos, 1
			    while $pos > 0 && $chars[ $pos - 1 ] =~ /\A\s/;
			splice @chars, --$pos, 1
			    while $pos > 0 && $chars[ $pos - 1 ] !~ /\A\s/;
			$self->_draw( $prompt, \@chars, $pos );
		}
		elsif ( $key eq 'redraw' ) {
			$self->_draw( $prompt, \@chars, $pos );
		}
	}
}

# $self->_complete($chars, $pos, $cycle, $step, $prompt):
#	Complete the word before the cursor and return the new cursor
#	and the cycle state. One candidate replaces the word. Several
#	candidates extend the word to the common prefix. With no
#	extension left, the tab shows the list once and starts a cycle:
#	each tab selects the next candidate, a back-tab the previous
#	one, the cycle wraps, and every other key ends it.
sub _complete ( $self, $chars, $pos, $cycle, $step, $prompt )
{
	if ($cycle) {
		my $candidates = $cycle->{candidates};
		$cycle->{index} = ( $cycle->{index} + $step ) % @$candidates;
		$pos = _replace_word( $chars, $cycle->{start}, $pos,
			$candidates->[ $cycle->{index} ] );
		$self->_draw( $prompt, $chars, $pos );
		return ( $pos, $cycle );
	}

	my $start = $pos;
	$start-- while $start > 0 && $chars->[ $start - 1 ] !~ /\A\s/;

	my $word = join '', @{$chars}[ $start .. $pos - 1 ];
	my $line = join '', @$chars;

	my @candidates = $self->_candidates( $word, $line, $start );
	return ( $pos, undef ) unless @candidates;

	if ( @candidates == 1 ) {
		$pos = _replace_word( $chars, $start, $pos, $candidates[0] );
		$self->_draw( $prompt, $chars, $pos );
		return ( $pos, undef );
	}

	my $prefix = _common_prefix(@candidates);
	if ( length $prefix > length $word ) {
		$pos = _replace_word( $chars, $start, $pos, $prefix );
		$self->_draw( $prompt, $chars, $pos );
		return ( $pos, undef );
	}

	# No extension is left: show the list once and start the cycle.
	$self->_write("\r\n");
	$self->_write("$_\r\n") for @candidates;

	$cycle = {
		start      => $start,
		candidates => \@candidates,
		index      => $step > 0 ? 0 : $#candidates,
	};
	$pos = _replace_word( $chars, $start, $pos,
		$candidates[ $cycle->{index} ] );
	$self->_draw( $prompt, $chars, $pos );
	return ( $pos, $cycle );
}

# _replace_word($chars, $start, $pos, $text):
#	Replace the characters from $start up to the cursor with the
#	text, and return the new cursor.
sub _replace_word ( $chars, $start, $pos, $text )
{
	my @new = _split_chars($text);
	splice @$chars, $start, $pos - $start, @new;
	return $start + @new;
}

# $self->_candidates($word, $line, $start):
#	The completion candidates for the word, sorted. The first word
#	of the command language completes from the command table, with
#	the prefix. Every other word goes to the callback, which runs
#	in the caller's process, at the prompt.
sub _candidates ( $self, $word, $line, $start )
{
	my $commands = $self->{commands};
	my $prefix   = $self->{prefix};

	if ( $start == 0 && %$commands && index( $word, $prefix ) == 0 ) {
		return grep { index( $_, $word ) == 0 }
		    map { $prefix . $_ } sort keys %$commands;
	}

	return unless defined $self->{complete};
	return grep { index( $_, $word ) == 0 }
	    sort $self->{complete}->( $word, $line );
}

# _common_prefix(@candidates):
#	The longest common prefix of the candidates.
sub _common_prefix (@candidates)
{
	my $prefix = shift @candidates;
	for my $candidate (@candidates) {
		chop $prefix
		    while length $prefix && index( $candidate, $prefix ) != 0;
	}
	return $prefix;
}

# $self->_next_key:
#	The next key: a name from the key subset, or an [insert, $bytes]
#	pair for one character. Return undef when the read ends, with
#	the event set. An unknown escape sequence and a stray byte do
#	nothing, so the loop takes the next byte instead.
sub _next_key ($self)
{
	while (1) {
		return unless $self->_fill(1);

		my $byte = substr $self->{pending}, 0, 1, '';
		my $ord  = ord $byte;

		if ( $byte eq "\e" ) {
			my $key = $self->_escape;
			return $key unless $key eq 'none';
			next;
		}
		if ( defined $CONTROL_KEY{$byte} ) {
			return $CONTROL_KEY{$byte};
		}
		if ( $ord >= 0x20 && $ord <= 0x7E ) {
			return [ 'insert', $byte ];
		}
		if ( $ord >= 0xC2 && $ord <= 0xF4 ) {
			my $length =
			      $ord <= 0xDF ? 2
			    : $ord <= 0xEF ? 3
			    :                4;
			next unless $self->_fill( $length - 1, ESCAPE_WAIT );

			my $sequence = $byte . substr $self->{pending}, 0,
			    $length - 1;
			next unless $sequence =~ /\A$UTF8\z/;

			substr $self->{pending}, 0, $length - 1, '';
			return [ 'insert', $sequence ];
		}

		# an other control byte or a stray byte does nothing
	}
}

# $self->_escape:
#	Parse one escape sequence from the buffer and return its key
#	name, or 'none' for a sequence outside the subset. The editor
#	never inserts the bytes of a sequence into the line.
sub _escape ($self)
{
	return 'none' unless $self->_fill( 1, ESCAPE_WAIT );

	my $kind = substr $self->{pending}, 0, 1, '';

	if ( $kind eq '[' ) {
		my $sequence = '';
		while (1) {
			return 'none' unless $self->_fill( 1, ESCAPE_WAIT );
			my $byte = substr $self->{pending}, 0, 1, '';
			$sequence .= $byte;
			last if $byte =~ /[\x40-\x7E]/;
		}
		return $SEQUENCE_KEY{$sequence} // 'none';
	}
	if ( $kind eq 'O' ) {
		return 'none' unless $self->_fill( 1, ESCAPE_WAIT );
		my $byte = substr $self->{pending}, 0, 1, '';
		return $SEQUENCE_KEY{$byte} // 'none';
	}
	return 'none';
}

# $self->_fill($count, $timeout = undef):
#	Block until the input buffer holds $count bytes. With a
#	timeout, give up quietly after that many seconds: an escape
#	sequence that stays incomplete is a lone key. Return true when
#	the bytes are there. Without a timeout, return undef with the
#	event set when the read ends first.
sub _fill ( $self, $count, $timeout = undef )
{
	while ( length $self->{pending} < $count ) {
		if ( defined $timeout ) {
			my $select = IO::Select->new( $self->{in} );
			return 0 unless $select->can_read($timeout);
		}
		else {
			my $ready = $self->_wait_readable;
			return
			    unless defined $ready && $ready == $self->{in};
		}

		my $bytes = sysread $self->{in}, my $chunk, READ_SIZE;
		if ( !defined $bytes ) {
			next if $! == EINTR;
			$self->{event} = 'eof';
			return;
		}
		if ( $bytes == 0 ) {
			$self->{event} = 'eof';
			return;
		}
		$self->{pending} .= $chunk;
	}
	return 1;
}

# $self->_wait_readable:
#	Block until the input handle or a watched handle is readable,
#	and return the ready handle. A watched handle outranks a
#	keystroke: a closed peer ends the session, whatever the
#	operator types. A signal that interrupts the wait sets the
#	event to 'interrupt' and returns undef, so the caller sees its
#	own signal flag at once.
sub _wait_readable ($self)
{
	my $select = IO::Select->new( $self->{in}, @{ $self->{watch} } );

	my @ready = $select->can_read;
	if ( !@ready ) {
		$self->{event} = $! == EINTR ? 'interrupt' : 'eof';
		return;
	}

	for my $fh ( @{ $self->{watch} } ) {
		next unless grep { $_ == $fh } @ready;
		$self->{event} = 'watch';
		$self->{ready} = $fh;
		return $fh;
	}
	return $self->{in};
}

# $self->_raw_on:
#	Put the terminal into raw mode and save the settings for
#	restore. Return undef when the input handle has no terminal.
#	ISIG turns off, so an interrupt arrives as a byte and clears
#	the line instead of ending the session.
sub _raw_on ($self)
{
	return $self if defined $self->{termios};

	my $fd = fileno $self->{in};
	return unless defined $fd;

	my $saved = POSIX::Termios->new;
	defined $saved->getattr($fd) or return;

	my $raw = POSIX::Termios->new;
	defined $raw->getattr($fd) or return;

	$raw->setlflag( $raw->getlflag & ~( ECHO | ICANON | IEXTEN | ISIG ) );
	$raw->setiflag(
		$raw->getiflag & ~( BRKINT | ICRNL | INPCK | ISTRIP | IXON ) );
	$raw->setcc( VMIN,  1 );
	$raw->setcc( VTIME, 0 );
	defined $raw->setattr( $fd, TCSANOW ) or return;

	$self->{termios} = $saved;
	return $self;
}

# $self->_draw($prompt, $chars, $pos):
#	Draw the prompt and the line, and put the cursor at $pos. The
#	sequences are fixed ANSI: carriage return, erase to the end of
#	the line, and cursor left.
sub _draw ( $self, $prompt, $chars, $pos )
{
	my $text = join '', @$chars;
	my $back = @$chars - $pos;

	$self->_write( "\r\e[K"
		    . $prompt
		    . $text
		    . ( $back > 0 ? "\e[${back}D" : '' ) );
	return;
}

# _split_chars($bytes):
#	Split a byte string into editor characters: one ASCII byte or
#	one whole UTF-8 sequence each. The cursor then counts a
#	sequence as one character.
sub _split_chars ($bytes)
{
	my @chars;
	while ( $bytes =~ /\G($UTF8|.)/gcs ) {
		push @chars, $1;
	}
	return @chars;
}

# $self->_write($bytes):
#	Write the bytes whole. syswrite can write a part, so the loop
#	continues with the rest. The module writes with syswrite only:
#	a mix with buffered writes reorders output.
sub _write ( $self, $bytes )
{
	my $out = $self->{out};
	while ( length $bytes ) {
		my $wrote = syswrite $out, $bytes;
		if ( !defined $wrote ) {
			next if $! == EINTR;
			return;
		}
		substr $bytes, 0, $wrote, '';
	}
	return $self;
}

1;
