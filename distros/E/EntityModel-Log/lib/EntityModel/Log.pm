package EntityModel::Log;
# ABSTRACT: Logging class used by EntityModel
use strict;
use warnings;
use parent qw{Exporter};

our $VERSION = '0.006';

=head1 NAME

EntityModel::Log - simple logging support for L<EntityModel>

=head1 VERSION

version 0.006

=head1 SYNOPSIS

 use EntityModel::Log ':all';
 # Log everything down to level 0 (debug)
 EntityModel::Log->instance->min_level(0);

 # STDERR by default, or Test::More::note if you have it loaded
 logDebug("Test something");
 logInfo("Object [%s] found", $obj->name);
 logError("Fatal problem");
 logInfo(sub { my $str = heavy_operation(); return 'Failed: %s', $str });

 logInfo("Stack trace - note that it must have at least one parameter (%s): %S", 'like this');
 logInfo("No stack trace without parameters despite %S");

 my $log = EntityModel::Log->instance;
 $log->debug("OO-style debug");
 $log->info("OO-style info");
 $log->warning("OO-style warning");
 $log->error("OO-style error");

=head1 DESCRIPTION

Yet another logging class. Provides a procedural and OO interface as usual - intended for use
with L<EntityModel> only, if you're looking for a general logging framework try one of the
other options in the L</SEE ALSO> section.

=cut

# Need to be able to switch off logging in UNITCHECK stages, since that segfaults perl5.10.1 and possibly other versions
our $DISABLE = 0;

use Time::HiRes qw{time};
use POSIX qw{strftime};
use Exporter;
use List::Util qw{min max};
use Scalar::Util qw{blessed};
use IO::Handle;
use File::Basename ();
use Data::Dump ();
use Data::Dump::Filtered ();

our %EXPORT_TAGS = ( 'all' => [qw/&logDebug &logInfo &logWarning &logError/] );
our @EXPORT_OK = ( @{$EXPORT_TAGS{'all'}} );

# Internal singleton instance
my $instance;

=head2 instance

Returns a handle to the main instance of L<EntityModel::Log>.

=cut

sub instance { my $class = shift; $instance ||= $class->new }

=head1 PROCEDURAL METHODS

=cut

my @LogType = (
	'Debug',
	'Info',
	'Warning',
	'Error',
	'Fatal',
);

=head2 _raise_error_on_global_instance

Raise the given (code, message, ...) log event on the L<EntityModel::Log> global instance.

=cut

sub _raise_error_on_global_instance { __PACKAGE__->instance->raise(@_); }

=head2 logDebug

Raise a debug message. Expect a high volume of these during normal operation
so a production server would typically have these disabled.

=cut

sub logDebug { unshift @_, 0; goto &_raise_error_on_global_instance; }

=head2 logInfo

Raise an informational message, which we'd like to track for stats
reasons - indicates normal operations rather than an error condition.

=cut

sub logInfo { unshift @_, 1; goto &_raise_error_on_global_instance; }

=head2 logWarning

Raise a warning message, for things like 'requested delete for object that does not exist'.
You might expect a few of these in regular operations due to concurrent access and timing issues,
so they may not necessarily indicate real system problems.

=cut

sub logWarning { unshift @_, 2; goto &_raise_error_on_global_instance; }

=head2 logError

Raise an error - this is likely to be a genuine system problem.

=cut

sub logError { unshift @_, 3; goto &_raise_error_on_global_instance; }

=head2 logStack

Raise an error with stack - this is likely to be a genuine system problem.

=cut

sub logStack {
	my $txt = __PACKAGE__->instance->parse_message(@_);

	$txt .= join("\n", map {
		sprintf("%s:%s %s", $_->{filename}, $_->{line}, $_->{subroutine})
	} _stack_trace());
	_raise_error_on_global_instance(3, $txt);
}

=head2 _stack_trace

Get a stack trace, as an array of hashref entries, skipping the top two levels.

=cut

sub _stack_trace {
	my $skip = shift || 0;
	my $dump = shift || 0;
	my $idx = 1;
	my @trace;
	my $pkg = __PACKAGE__;
	{
		package DB;
		while($idx < 99 && (my @stack = caller($idx))) {
			++$idx;
			next if $skip-- > 0;

			my %info;
			@info{qw/package filename line subroutine hasargs wantarray evaltext is_require hints bitmask hinthash/} = map $_ // '', @stack;
			$info{args} = [ @DB::args ];

			# TODO not happy with this. maybe switch to ->isa?
			push @trace, \%info unless $info{package} eq $pkg;
		}
	}

	foreach my $info (@trace) {
		$info->{file} = File::Basename::basename($info->{filename});
		$info->{code} = '';
		if($dump) { # could include source context using something like $info{filename} =~ m{^$basePath/(.*)$} || $info{filename} =~ m{^/perl-module-path/(.*)$}) {
			# I'm hoping this entire function can be replaced by a module from somewhere
			if(-r $info->{filename}) {
				# Start from five lines before the required line, but clamp to zero
				my $start = max(0, ($info->{line} // 0) - 5);

				# Probably not a safe thing to do, but most modules seem to be ascii or utf8
				open my $fh, '<:encoding(utf8)', $info->{filename} or die $! . ' when reading ' . $info->{filename} . ' which we expected to have loaded already';

				if($start) {
					<$fh> for 1..$start;
				}
				my $line = $start;
				$info->{code} .= sprintf("%5d %s", $line++, scalar(<$fh> // last)) for 0..10;
				close $fh;
			}
		}
	}
	return @trace;
}

=head2 _level_from_string

Returns the level matching the given string.

=cut

sub _level_from_string {
	my $str = lc(shift);
	my $idx = 0;
	foreach (@LogType) {
		return $idx if $str eq lc($_);
		++$idx;
	}
	die "Bad log level [$str]";
}

=head2 _timestamp

Generate a string in ISO8601-ish format representing the time of this log event.

=cut

sub _timestamp {
	my $now = Time::HiRes::time;
	return strftime("%Y-%m-%d %H:%M:%S", gmtime($now)) . sprintf(".%03d", int($now * 1000.0) % 1000.0);
}

=head2 OO METHODS

=cut

=head2 new

Constructor - currently doesn't do much.

=cut

sub new { bless { handle => undef, is_open => 1, pid => $$ }, shift }

=head2 debug

Display a debug message.

=cut

sub debug { shift->raise(0, @_) }

=head2 info

Display an info message.

=cut

sub info { shift->raise(1, @_) }

=head2 warning

Display a warning message.

=cut

sub warning { shift->raise(2, @_) }

=head2 error

Display an error message.

=cut

sub error { shift->raise(3, @_) }

=head2 path

Accessor for path setting, if given a new path will close existing file and direct all new output to the given path.

=cut

sub path {
	my $self = shift;
	if(@_) {
		$self->close if $self->is_open;
		$self->{path} = shift;
		$self->open;
		return $self;
	}
	return $self->{path};
}

=head2 pid

Current PID, used for fork tracking.

=cut

sub pid {
	my $self = shift;
	if(@_) {
		$self->{pid} = shift;
		return $self;
	}
	return $self->{pid};
}

=head2 is_open

Returns true if our log file is already open.

=cut

sub is_open {
	my $self = shift;
	if(@_) {
		$self->{is_open} = shift;
		return $self;
	}
	return $self->{is_open};
}

=head2 disabled

Returns true if we're running disabled.
=cut

sub disabled {
	my $self = shift;
	if(@_) {
		$self->{disabled} = shift;
		return $self;
	}
	return $self->{disabled};
}

=head2 close

Close the log file if it's currently open.

=cut

sub close : method {
	my $self = shift;
	return $self unless $self->is_open;

	if(my $h = delete $self->{handle}) {
		$h->close or die "Failed to close log file: $!\n";
	}
	$self->is_open(0);
	return $self;
}

=head2 close_after_fork

Close any active handle if we've forked. This method just does the closing, not the check for $$.

=cut

sub close_after_fork {
	my $self = shift;
	return unless $self->is_open;

# Don't close STDOUT/STDERR. Bit of a hack really, we should perhaps just close when we were given a path?
	return if $self->handle == \*STDERR || $self->handle == \*STDOUT;
	$self->close;
	return $self;
}

=head2 open

Open the logfile.

=cut

sub open : method {
	my $self = shift;
	return $self if $self->is_open;
	open my $fh, '>>', $self->path or die $! . " for " . $self->path;
	binmode $fh, ':encoding(utf-8)';
	$fh->autoflush(1);
	$self->{handle} = $fh;
	$self->is_open(1);
	$self->pid($$);
	return $self;
}

=head2 reopen

Helper method to close and reopen logfile.

=cut

sub reopen {
	my $self = shift;
	$self->close if $self->is_open;
	$self->open;
	return $self;
}

=head2 parse_message

Generate appropriate text based on whatever we get passed.

Each item in the parameter list is parsed first, then the resulting items are passed through L<sprintf>. If only a single item is in the list then the resulting string is returned directly.

Item parsing handles the following types:

=over 4

=item * Single string is passed through unchanged

=item * Arrayref or hashref is expanded via L<Data::Dump>

=item * Other references are stringified

=item * Undef items are replaced with the text 'undef'

=back

In addition, if the first parameter is a coderef then it is expanded in place (recursively - a coderef can return another coderef). Note that this only happens for the *first* parameter at each
level of recursion.

=cut

sub parse_message {
	my $self = shift;
	return '' unless @_;

	unshift @_, $_[0]->() while $_[0] && ref($_[0]) eq 'CODE';

# Decompose parameters into strings
	my @data;
	ITEM:
	while(@_) {
		my $entry = shift;

# Convert to string if we can
		if(my $ref = ref $entry) {
			if($ref =~ /^CODE/) {
				unshift @_, $entry->();
				next ITEM;
			} elsif($ref eq 'ARRAY' or $ref eq 'HASH') {
				$entry = Data::Dump::dump($entry);
			} else {
				$entry = "$entry";
			}
		}
		$entry //= 'undef';
		push @data, $entry;
	}

# Format appropriately
	my $fmt = shift(@data) // '';
	return $fmt unless @data;

	# Special-case the stack trace feature. A bit too special really :(
	$fmt =~ s/%S/join("\n", '', map {
		_stack_line($_)
	} _stack_trace(0, 1))/e;
	die "Format undef" unless defined $fmt;
	die "Undefined entry in data, others are " . join ', ', map { defined($_) } @data if grep { !defined($_) } @data;
	return sprintf($fmt, @data);
}

sub _stack_line {
	my $info = shift;
	my $txt = sprintf ' => %-32.32s %s(%s) args %s',
		$info->{package} . ':' . $info->{line},
		($info->{subroutine} =~ m{ ( [^:]+$ ) }x),
		  ($info->{package} eq 'EntityModel::Log')
		? ('')
		: (join ', ', map Data::Dump::Filtered::dump_filtered($info, sub {
			my ($ctx, $obj) = @_;
			return undef unless $ctx->is_blessed;
			return { dump => "$obj" };
		})), join ' ', map $_ // '<undef>', @{ $info->{args} };
	$txt =~ s{%}{%%}g;
	return $txt;
}

=head2 min_level

Accessor for the current minimum logging level. Values correspond to:

=over 4

=item * 0 - Debug

=item * 1 - Info

=item * 2 - Warning

=item * 3 - Error

=item * 4 - Fatal

=back

Returns $self when setting a value, otherwise the current value is returned.

=cut

sub min_level {
	my $self = shift;
	if(@_) {
		$self->{min_level} = shift;
		return $self;
	}
	return $self->{min_level};
}

=head2 raise

Raise a log message

=over 4

=item * $level - numeric log level

=item * @data - message data

=back

=cut

sub raise {
	return $_[0] if $_[0]->disabled;

	my $self = shift;
	my $level = shift;
	my ($pkg, $file, $line, $sub) = caller(1);

# caller(0) gives us the wrong sub for our purposes - we want whatever raised the logXX line
	(undef, undef, undef, $sub) = caller(2);

# Apply minimum log level based on method, then class, then default 'info'
	my $minLevel = ($sub ? $self->{mask}{$sub}{level} : undef)
		// $self->{mask}{$pkg}{level}
		// $self->{min_level}
		// 1;
	return $self if $minLevel > $level;

	my $txt = $self->parse_message(@_);

# Explicitly get time from Time::HiRes for ms accuracy
	my $ts = _timestamp();

	my $type = sprintf("%-8.8s", $LogType[$level]);
	$self->output("$ts $type $file:$line $txt");
	return $self;
}

=head2 output

Sends output to the current filehandle.

=cut

sub output {
	my $self = shift;
	my $msg = shift;
	if(my $handle = $self->get_handle) {
		$handle->print($msg . "\n");
		return $self;
	}

	Test::More::note($msg);
	return $self;
}

=head2 get_handle

Returns a handle if we have one, and 0 if we should fall back to L<Test::More>::note.

=cut

sub get_handle {
	my $self = shift;
	# Fall back to Test::More if available, unless we already have a handle
	if(!$self->{handle}) {
		return 0 if $ENV{HARNESS_ACTIVE};
		# Exists, but undef, means STDERR fallback
		return \*STDERR if exists $self->{handle};
	}

	$self->close_after_fork unless $$ == $self->pid;

	$self->open unless $self->is_open;
	return $self->handle;
}

=head2 handle

Direct(-ish) accessor for the file handle.

=cut

sub handle {
	my $self = shift;
	if(@_) {
		$self->close if $self->is_open;
		$self->{handle} = shift;
		$self->is_open(1);
		$self->pid($$);
		return $self;
	}
	$self->reopen unless $self->{handle};
	return $self->{handle};
}

END { $instance->close if $instance; }

1;

__END__

=head1 SEE ALSO

L<Log::Any>, L<Log::Log4perl> or just search for "log" on search.cpan.org, plenty of other options.

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2014. Licensed under the same terms as Perl itself.
