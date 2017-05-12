package Log::Trace;
use Carp;

#Hires times if available
eval
{
	require Time::HiRes;
};

use vars qw($VERSION @EXPORT);
@EXPORT = qw(TRACE_HERE TRACEF); # TRACE, DUMP
use strict qw(subs vars);
use Fcntl ':flock';

$VERSION = sprintf"%d.%03d", q$Revision: 1.70 $ =~ /: (\d+)\.(\d+)/;

#################################################
# Importing
#################################################

*{"_debug"} = 0 ? sub { warn __PACKAGE__ . " @_\n" } : sub {};

#Import into calling packages
sub import
{
	my $pkg = shift;
	my $callpkg = caller(0);
	my @args = @_;
	if (ref $args[1] eq 'HASH')
	{
		# e.g. 'import (print => {Verbose => 1})
		@args = ($args[0], undef, @args[1..$#args])
	}
	$pkg->_import($callpkg, @args);
}

sub deep_import # deprecated. use 'import Log::Trace {Deep => 1, ...} ...'
{
	my $pkg = shift;
	my $callpkg = caller(0);
	my $params = ref $_[0] ? shift : {};
	$params->{Deep} = 1;
	push @_, undef if @_ == 1; # deep_import 'print';
	$pkg->_import($callpkg, @_, $params);
}


sub TRACEF
{
	my $callpkg = caller();
	my $trace = *{"$callpkg\::TRACE"};
	my $params = ref $_[0] ? shift : {};
	my $format = shift;
	$trace->($params, sprintf($format, @_));
}


sub TRACE_HERE
{
	my $callpkg = caller();
	my $params = ref $_[0] ? shift : {};
	# see 'perldoc -f caller'
	# calling caller() from the DB package stores subroutine args in @DB::args
	my @caller;
	do {
		package DB;
		@caller = caller(1);
		@caller = caller(0) unless $caller[0];
	};
	my $sub = $caller[3]; # the subroutine that called TRACE_HERE
	my ($file, $line) = (caller(0))[1,2]; # the location of the TRACE_HERE
	my $trace = *{"$callpkg\::TRACE"};
	shift @DB::args if @DB::args && "$DB::args[0]" eq "$params";
	$trace->($params, "In $sub(".join(",", @DB::args).") - line $line of $file");
}


#################################################
# Exporting
#################################################

sub _import
{
	my $pkg = shift;
	my (@packages) = shift;
	my ($target, $arg, $params) = @_;
	$target = '' unless defined $target;

	if ($params->{Deep}) {
		# extend the package list
		push @packages, _deep_import_packages($params->{Everywhere});
	}
	if ($params->{AutoImport}) {
		# override the default require() to catch new modules being loaded
		_install_require($pkg, $params, $target, $arg)
	}

	# lookup: valid target > TRACE sub.  These are also closures around '$arg'
	my %import_targets = (
		'print'          => sub {_log_to_fh($arg, _log_normal(@_))},
		'print-verbose'  => sub {_log_to_fh($arg, _log_verbose(@_))},
		'print-debug'    => sub {_log_to_fh($arg, _log_debug(@_))},
		'warn'           => sub {warn _log_normal(@_)},
		'warn-verbose'   => sub {warn _log_verbose(@_)},
		'warn-debug'     => sub {warn _log_debug(@_)},
		'buffer'         => sub {$$arg .= _log_normal(@_)},
		'buffer-verbose' => sub {$$arg .= _log_verbose(@_)},
		'buffer-debug'   => sub {$$arg .= _log_debug(@_)},
		'file'           => sub {_log_to_file($arg, _log_normal(@_))},
		'file-verbose'   => sub {_log_to_file($arg, _log_verbose(@_))},
		'file-debug'     => sub {_log_to_file($arg, _log_debug(@_))},
		'log'            => sub {_log_to_file($arg, _log_debug(@_))},
		'syslog'         => sub {_log_to_syslog($arg, _log_normal(@_))},
		'syslog-verbose' => sub {_log_to_syslog($arg, _log_verbose(@_))},
		'syslog-debug'   => sub {_log_to_syslog($arg, _log_debug(@_))},
		'custom'         => $arg,
	);

	my $suffix = '';
	$params->{Verbose} = 0 unless defined $params->{Verbose};
	if ($params->{Verbose} == 1)
	{
		$suffix = '-verbose';
	}
	elsif ($params->{Verbose} == 2)
	{
		$suffix = '-debug';
	}
	$target = $import_targets{$target.$suffix} ? $target.$suffix : $target;
	_debug("Initialising target: $target");

	foreach my $export_to (@packages) {
		# Check whether to export functions to the package
		my $match = defined $params->{Match} ? $params->{Match} : '.';
		next unless $export_to =~ /$match/;
		my %exclude;
		if (my $excl = $params->{Exclude}) {
			%exclude = map {$_ => 1} ref $excl eq 'ARRAY' ? @$excl : $excl;
		}
		$exclude{+__PACKAGE__} = 1; # exclude ourselves
		next if $exclude{$export_to};

		_debug("Exporting target:$target to $export_to");
		# set up the TRACE/DUMP functions
		my ($trace, $dump);
		if ($target && $import_targets{$target})
		{
			$trace = _trace_maker($export_to, $params, $import_targets{$target});
			$dump  = _dump_maker($export_to, $params, $trace);
		}
		else
		{
			# Just export stub functions
			$trace = $dump = sub {};
			carp "$pkg imported with unknown target $target" if $target;
		}

		# Now export ...
		__replace_subroutine($export_to, 'TRACE', $trace);
		__replace_subroutine($export_to, 'DUMP', $dump);
		__replace_subroutine($export_to, 'TRACEF', \&TRACEF);
		__replace_subroutine($export_to, 'TRACE_HERE', \&TRACE_HERE);

		if ($params->{AllSubs})
		{
			# wrap all functions in package with calls to TRACE
			_debug("wrapping all functions in $export_to");
			_wrap_functions($export_to, $trace);
		}
	}
}

sub __replace_subroutine
{
	my ($package, $sub, $coderef) = @_;
	if (defined \&{"${package}::$sub"})
	{
		# quietly remove existing stub function
		# This avoids unsightly "subroutine foo redefined" warnings
		# 'no warnings "redefine"' doesn't work pre perl 5.6
		eval "undef \$${package}::{'$sub'}";
	}
	*{"${package}::$sub"} = $coderef;
}

sub _trace_maker
{
	my ($package, $params, $trace_sub) = @_;
	my $trace_level = $params->{Level};
	return sub
	{
		local $@; # in-case TRACE is called from &DESTROY
		my $rv;
		eval
		{
			my $level = shift->{Level} if ($_[0] && ref $_[0] eq 'HASH');
			return unless _evaluate_level($package, $trace_level, $level);
			$rv = 1 && $trace_sub->(@_);
		};
		if ($@)
		{
			warn __PACKAGE__ . " : $@";
		}
		return $rv;
	}
}

sub _dump_maker
{
	my ($package, $params, $trace_sub) = @_;
	my $trace_level = $params->{Level};
	return sub
	{
		# always return the dumped data regardless of level unless called in
		# void context
		my $context = wantarray();
		local $@; # in-case DUMP is called from &DESTROY
		my $rv;
		eval
		{
			return $rv = _dump($params, @_) if defined $context;

			my $level = undef;
			if ($_[0] && ref $_[0] eq 'HASH' && defined $_[0]{Level})
			{
				$level = shift->{Level};
			}
			return unless _evaluate_level($package, $trace_level, $level);
			my $dumped = _dump($params, @_);
			$rv = 1 && $trace_sub->($dumped);
		};
		if ($@)
		{
			warn __PACKAGE__ . " : $@";
		}
		return $rv;
	}
};


# returns a list of packages to export trace functions to
sub _deep_import_packages
{
	my $all_packages = shift;

	# Build the list of packages
	my @packages;
	foreach my $module (@{_list_all_packages()})
	{
		next if $module eq __PACKAGE__;
		next unless $all_packages || defined (&{"$module\::TRACE"});
		push @packages, $module;
	}
	return @packages;
}


my %_autowrap;
sub _wrap_functions {
	my ($package, $trace) = @_;

	return if $_autowrap{$package};
	$_autowrap{$package} = {} unless defined $_autowrap{$package};

	my $symbols = \%{$package . '::'};
	# wrap coderefs in the caller's symbol table
	foreach my $typeglob (keys %$symbols) {

		# skip TRACE/DUMP and other potential deep recursions
		next if $typeglob =~ /^(?:TRACE(?:F|_HERE)?|DUMP|AUTOLOAD)$/;

		# only wrap code references
		my $sub = *{$symbols->{$typeglob}}{CODE};
		next unless (defined $sub and defined &$sub);

		# skip if sub is already wrapped
		next if $_autowrap{$package}{$typeglob}++;

		# define wrapped subroutine body
		my $sub_body = <<'WRAPPED';
			my ($name) = "${package}::$typeglob";
			my ($callpkg, $file, $line) = caller(1);
			my $arg = $_[0] && ref($_[0]) ? ref($_[0]) . ', ...' : "";
			$trace->( "${name}( $arg )" );
			goto &$sub
WRAPPED

		# wrap subroutine, preserving prototypes
		my $wrapped_sub;
		if(defined (my $proto = prototype($sub)))
		{
			$wrapped_sub = eval "sub ($proto) { $sub_body }";
		}
		else
		{
			$wrapped_sub = eval "sub { $sub_body }";
		}

		__replace_subroutine($package, $typeglob, $wrapped_sub);
	}
}


# return a list of all defined packages in the symbol table
# we could use %INC, but we'd miss packages that are defined in other modules
sub _list_all_packages {
	my ($package) = @_;
	$package = '' unless defined $package;
	my @packages;

	# this is a recursive look in the symbol table:
	# %main::
	#   CGI::
	#     Cookie::
	#   Data::
	#     Dumper::
	# ...

	my %symbols = %{$package . "::"};
	foreach my $module (keys %symbols)
	{
		next unless $module =~ s/::$//;
		# ignore 'main' (deep recursion) and all invalid package names
		next if !$package && ($module eq 'main' || $module !~ /^[a-zA-Z_]\w*$/);

		my $prefix = $package ? $package . '::' : '';
		# Add this module
		push @packages, $prefix . $module;
		# and recurse to sub-packages
		push @packages, @{_list_all_packages($prefix . $module)};
	}
	return \@packages;
}


# Override the built-in require()
# This is tricky because these are treated differently by perl:
# 1. require CGI
# 2. require "CGI"
# We have no way of distinguishing the two, so we make a best guess
#
# This only works since perl 5.6.1
#
# See 'perlsub' for more information about overriding built-ins
sub _install_require
{
	my ($pkg, $params, $target, @args) = @_;

	# CORE::require has prototype(;$), but we get "bareword foo not allowed"
	# errors if we use that. prototype(*) works though
	my $require = sub (*)
	{
		local $^W;
		my $what = shift;
		return 1 if $INC{$what};
		_debug("require $what");

		my $package;
		if ($what =~ /^v?[\d_.]+$/) {
			# take advantage of UNIVERSAL->VERSION($require) for a portable
			# version check
			local $_Log::Trace::PerlVersion::VERSION = $];
			eval {_Log::Trace::PerlVersion->VERSION($what)};
			if (my $error = $@) {
				$error =~ s/_Log::Trace::PerlVersion/Perl/;
				die $error; #rethrow exception
			}
			return 1;
		} elsif ($what =~ /(.*)\.pm$/) {
			# looks like a module name, get the main package from the filename
			# (perl 5.8 & ActivePerl 5.6.1)
			($package = $1) =~ s{/}{::}g;
		} elsif ($what =~ /^[a-zA-Z_]\w*(?:::\w+)*$/i) {
			# package name: vanilla perl 5.6.1, 5.6.2
			$package = $what;
			($what = "$what.pm") =~ s{::}{/}g;
		}

		my $rv = CORE::require $what;
		if ($rv && $package)
		{
			# import Log::Trace into package
			return unless $params->{Everywhere}
				|| defined (&{"$package\::TRACE"});
			$pkg->_import($package, $target, @args, $params);
		}
		return $rv;
	};

	# Override global require, silencing "... used only once" warnings
	*CORE::GLOBAL::require = *CORE::GLOBAL::require = $require;
}


# Returns caller info for exported functions
sub __caller
{
	# We need to look several frames back, so we keep going until we find
	# something from outside this package
	my @caller;
	for (1 .. 8) {
		my @c = caller($_);
		last unless defined $c[0];
		@caller = @c;
		last unless $caller[0] eq __PACKAGE__
			|| $caller[3] =~ /^@{[__PACKAGE__]}\::/o;
	}

	# because we don't seem to get a call frame for main::__ANON__
	$caller[0] = 'main' if ($caller[0] eq __PACKAGE__);
	$caller[3] =~ s/^@{[__PACKAGE__]}\::.*/main::__ANON__/;
	return @caller;
}

#################################################
# TRACE guts
#################################################

sub _evaluate_level
{
	my ($callpkg, $imported_level, $trace_level) = @_;

	return 1 if ! defined $imported_level;

	if (ref $imported_level eq 'CODE')
	{
		return $imported_level->($callpkg, $trace_level);
	}
	elsif (ref $imported_level eq 'ARRAY')
	{
		for (@$imported_level)
		{
			return 1 if (! defined($_) && ! defined($trace_level));
			next unless defined($trace_level) && defined($_);;
			return 1 if $_ == $trace_level;
		}
	}
	elsif (!ref $imported_level)
	{
		return unless defined $trace_level;
		return $imported_level >= $trace_level;
	}
}

sub _log_normal
{
	return join(",", @_)."\n";
}

sub _log_verbose
{
	my ($pack,$file,$line,$sub) = __caller();
	return "$sub ($line) :: " . join( ", ", @_ ) . "\n";
}

sub _log_debug
{
	my ($pack,$file,$line,$sub) = __caller();
	my $timestamp = _timestamp();
	return "$file: $sub ($line) [$timestamp] " . join( ", ", @_ ) . "\n";
}

sub _log_to_fh
{
	my ($fh, @output) = @_;
	$fh = \*STDOUT unless $fh;
	print $fh @output;
}

sub _log_to_file
{
	my $filename = shift;
	my ($pack,$file,$line,$sub) = __caller();

	local *LOG_FILE;
	if (open (LOG_FILE, ">> $filename"))
	{
		if (eval {flock LOG_FILE, LOCK_EX|LOCK_NB})
		{
			print LOG_FILE @_;
			flock LOG_FILE, LOCK_UN;
			close LOG_FILE;
		}
		else
		{
			die "couldn't get lock on $filename : $!";
		}
	}
	else
	{
		die "Cannot open $filename : $!";
	}
}

sub _log_to_syslog
{
	my ($priority) = shift || 'debug';

	return unless eval {require Sys::Syslog};
	Sys::Syslog::openlog(__PACKAGE__, 'pid');
	my $rv = Sys::Syslog::syslog($priority, join ",", @_);
	Sys::Syslog::closelog();
	return $rv;
}

sub _dump
{
	my ($params, @args) = @_;

	my $msg = ref $args[0] ? '' : shift @args;
	$msg .= ": " if($msg && @args);

	my $type;
	eval
	{
		if ($params->{Dumper})
		{
			$type = 'Data::Serializer';
			require Data::Serializer;
			my $params = ref $params->{Dumper} ?
				$params->{Dumper} : { serializer => $params->{Dumper} };
			my $serialiser = Data::Serializer->new(%$params);
			for (@args)
			{
				$msg .= $serialiser->raw_serialize($_) . "\n";
			}
		}
		else
		{
			$type = 'Data::Dumper';
			require	Data::Dumper;
			# avoid 'used $var only once' warning
			local $Data::Dumper::Indent;
			local $Data::Dumper::Sortkeys;
			local $Data::Dumper::Quotekeys;
			$Data::Dumper::Indent    = 1;
			$Data::Dumper::Sortkeys  = 1;
			$Data::Dumper::Quotekeys = 0;

			$msg .= Data::Dumper::Dumper(@args);
		}
	};
	die "$type not available: $@" if $@;
	return $msg;
}

sub _gettimeofday()
{
	return Time::HiRes::gettimeofday() if $INC{'Time/HiRes.pm'};
	return (time(), undef);
}

#Provide localtime-style timestamp with microsecond resolution if Time::HiRes
#is available
sub _timestamp
{
	my ($epoch, $usec) = _gettimeofday();
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($epoch);
	$year+=1900; $mon+=1;
	my $stamp = sprintf("%4d-%02d-%02d %02d:%02d:%02d",$year,$mon,$mday,$hour,$min,$sec);
	$stamp .= sprintf(".%.6d",$usec) if(defined $usec);
	return $stamp;
}

1;

=head1 NAME

Log::Trace - provides a unified approach to tracing

=head1 SYNOPSIS

	# The tracing targets
	use Log::Trace; # No output
	use Log::Trace 'print'; # print to STDOUT
	use Log::Trace log => '/var/log/foo.log'; # Output to log file
	use Log::Trace print => { Level => 3 };

	# Switch on/off logging with a constant
	use Log::Trace;
	import Log::Trace ('log' => LOGFILE) if TRACING;


	# Set up tracing for all packages that advertise TRACE
	use Foo;
	use Bar;
	use Log::Trace warn => { Deep => 1 };

	# Sets up tracing in all subpackages excluding Foo
	use Log::Trace warn => {Deep => 1, 'Exclude' => 'Foo'};


	# Exported functions
	TRACE("Record this...");
	TRACE({Level => 2}, "Only shown if tracing level is 2 or higher");
	TRACEF("A la printf: %d-%.2f", 1, 2.9999);
	TRACE_HERE();	        # Record where we are (file, line, sub, args)
	DUMP(\@loh, \%hoh);     # Trace out via Data::Dumper
	DUMP("Title", \@loh);   # Trace out via Data::Dumper
	my $dump = DUMP(@args); # Dump is returned without being traced

=head1 DESCRIPTION

A module to provide a unified approach to tracing. A script can C<use
Log::Trace qw( E<lt> mode E<gt> )> to set the behaviour of the TRACE function.

By default, the trace functions are exported to the calling package only. You
can export the trace functions to other packages with the C<Deep> option. See
L<"OPTIONS"> for more information.

All exports are in uppercase (to minimise collisions with "real" functions).

=head1 FUNCTIONS

=over 4

=item TRACE(@args)

Output a message. Where the message actually goes depends on how you imported
Log::Trace (See L<"Importing/enabling Log::Trace">)

The first argument is an optional hashref of options:

	TRACE('A simple message');

vs:

	TRACE({ Level => 2.1 }, 'A message at a specified trace level');

=item TRACEF($format, @args)

C<printf()> equivalent of TRACE. Also accepts an optional hashref:

	TRACEF('%d items', scalar @items);
	TRACEF({ Level => 5 }, '$%1.2d', $value);

=item DUMP([$message,] @args)

Serialises each of @args, optionally prepended with $message. If called in a
non-void context, DUMP will return the serialised data rather than TRACE
it. This is useful if you want to DUMP a datastructure at a specific tracing
level.

	DUMP('colours', [qw(red green blue)]);             # outputs via TRACE
	my $dump = DUMP('colours', [qw(red green blue)]);  # output returned

=item TRACE_HERE()

TRACEs the current position on the call stack (file, line number, subroutine
name, subroutine args).

	TRACE_HERE();
	TRACE_HERE({Level => 99});

=back

=head1 Importing/enabling Log::Trace

=over 4

=item import($target, [$arg], [\%params])

Controls where TRACE messages go. This method is called automatically when you
call C<'use Log::Trace;'>, but you may explicitly call this method at
runtime. Compare the following:

	use Log::Trace 'print';

which is the same as

	BEGIN {
		require Log::Trace;
		Log::Trace->import('print');
	}

Valid combinations of C<$target> and C<arg> are:

=over 4

=item print =E<gt> $filehandle

Prints trace messages to the supplied C<$filehandle>. Defaults to C<STDOUT>
if no file handle is specified.

=item warn

Prints trace messages via C<warn()>s to C<STDERR>.

=item buffer =E<gt> \$buffer

Appends trace messages to a string reference.

=item file =E<gt> $filename

Append trace messages to a file. If the file doesn't exist, it will be created.

=item log =E<gt> $filename

This is equivalent to:

	use Log::Trace file => $filename, {Verbose => 2};

=item syslog =E<gt> $priority

Logs trace messages to syslog via C<Sys::Syslog>, if available.

You should consult your syslog configuration before using this option.

The default C<$priority> is 'C<debug>', and the C<ident> is set to
C<Log::Trace>. You can configure the C<priority>, but beyond that, you can
implement your own syslogging via the C<custom> trace target.

=item custom => \&custom_trace_sub

Trace messages are processed by a custom subroutine. E.g.

	use Log::Trace custom => \&mylogger;

	sub mylogger {
		my @messages = @_;
		foreach (@messages) {
			# highly sensitive trace messages!
			tr/a-zA-Z/n-za-mN-ZA-M/;
			print;
		}
	}

=back

The import C<\%params> are optional. These two statements are functionally the
same:

	import Log::Trace print => {Level => undef};
	import Log::Trace 'print';

See L<"OPTIONS"> for more information.

B<Note:> If you use the C<custom> tracing option, you should be careful about
supplying a subroutine named C<TRACE>.

=back

=head1 OPTIONS

=over 4

=item AllSubs =E<gt> BOOL

Attaches a C<TRACE> statement to all subroutines in the package. This can be
used to track the execution path of your code. It is particularly useful when
used in conjunction with C<Deep> and C<Everywhere> options.

B<Note:> Anonymous subroutines and C<AUTOLOAD> are not C<TRACE>d.

=item AutoImport =E<gt> BOOL

By default, C<Log::Trace> will only set up C<TRACE> routines in modules that
have already been loaded. This option overrides C<require()> so that modules
loaded after C<Log::Trace> can automatically be set up for tracing.

B<Note>: This is an experimental feature. See the ENVIRONMENT NOTES
for information about behaviour under different versions of perl.

This option has no effect on perl E<lt> 5.6

=item Deep =E<gt> BOOL

Attaches C<Log::Trace> to all packages (that define a TRACE function). Any
TRACEF, DUMP and TRACE_HERE routines will also be overridden in these packages.

=item Dumper =E<gt> Data::Serializer backend

Specify a serialiser to be used for DUMPing data structures. 

This should either be a string naming a Data::Serializer backend (e.g. "YAML") 
or a hashref of parameters which will be passed to Data::Serializer, e.g.

	{
		serializer => 'XML::Dumper',
		options => {
			dtd => 'path/to/my.dtd'
		}
	}

Note that the raw_serialise() method of Data::Serializer is used.  See L<Data::Serializer>
for more information.
		
If you do not have C<Data::Serializer> installed, leave this option undefined to use the
C<Data::Dumper> natively.

Default: undef (use standalone Data::Dumper)

=item Everywhere =E<gt> BOOL

When used in conjunction with the C<Deep> option, it will override the
standard behaviour of only enabling tracing in packages that define C<TRACE>
stubs.

Default: false

=item Exclude =E<gt> STRING|ARRAY

Exclude a module or list of modules from tracing.

=item Level =E<gt> NUMBER|LIST|CODE

Specifies which trace levels to display.

If no C<Level> is defined, all TRACE statements will be output.

If the value is numeric, only TRACEs that are at the specified level or below
will be output.

If the value is a list of numbers, only TRACEs that match the specified levels
are output.

The level may also be a code reference which is passed the package name and the
TRACE level. It mst return a true value if the TRACE is to be output.

Default: undef

=item Match =E<gt> REGEX

Exports trace functions to packages that match the supplied regular
expression. Can be used in conjunction with  C<Exclude>. You can also use
C<Match> as an exclusion method if you give it a negative look-ahead.

For example:

	Match => qr/^(?!Acme::)/  # will exclude every module beginning with Acme::

and

	Match => qr/^Acme::/      # does the reverse

Default: '.' # everything

=item Verbose =E<gt> 0|1|2

You can use this option to prepend extra information to each trace message. The
levels represent increasing levels of verbosity:

	0: the default*, don't add anything
	1: adds subroutine name and line number to the trace output
	2: As [1], plus a filename and timestamp (in ISO 8601 : 2000 format)

This setting has no effect on the C<custom> or C<log> targets.

* I<the log target uses 'Verbose' level 2>

=back

=head1 ENVIRONMENT NOTES

The AutoImport feature overrides C<CORE::require()> which requires perl 5.6, but you may see unexpected errors if you aren't using at
least perl 5.8. The AutoImport option has no effect on perl E<lt> 5.6.

In mod_perl or other persistent interpreter environments, different applications could trample on each other's
C<TRACE> routines if they use Deep (or Everywhere) option.  For example application A could route all the trace output 
from Package::Foo into "appA.log" and then application B could import Log::Trace over the top, re-routing all the trace output from Package::Foo
to "appB.log" for evermore.  One way around this is to ensure you always import Log::Trace on every run in a persistent environment from all your 
applications that use the Deep option.  We may provide some more tools to work around this in a later version of C<Log::Trace>.

C<Log::Trace> has not been tested in a multi-threaded application.

=head1 DEPENDENCIES

	Carp
	Time::HiRes      (used if available)
	Data::Dumper     (used if available - necessary for meaningful DUMP output)
	Data::Serializer (optional - to customise DUMP output)
	Sys::Syslog      (loaded on demand)

=head1 RELATED MODULES

=over 4

=item Log::TraceMessages

C<Log::TraceMessages> is similar in design and purpose to C<Log::Trace>.
However, it only offers a subset of this module's functionality. Most notably,
it doesn't offer a mechanism to control the tracing output of an entire
application - tracing must be enabled on a module-by-module
basis. C<Log::Trace> also offers control over the output with the trace
levels and supports more output targets.

=item Log::Agent

C<Log::Agent> offers a procedural interface to logging. It strikes a good
balance between configurability and ease of use. It differs to C<Log::Trace> in
a number of ways. C<Log::Agent> has a concept of channels and priorities, while
C<Log::Trace> only offers levels. C<Log::Trace> also supports tracing code
execution path and the C<Deep> import option. C<Log::Trace> trades a certain
amount of configurability for increased ease-of use.

=item Log::Log4Perl

A feature rich perl port of the popular C<log4j> library for Java. It is
object-oriented and comprised of more than 30 modules. It has an impressive
feature set, but some people may be frightened of its complexity. In contrast,
to use C<Log::Trace> you need only remember up to 4 simple functions and a
handful of configuration options.

=back

=head1 SEE ALSO

L<Log::Trace::Manual> - A guide to using Log::Trace

=head1 VERSION

$Revision: 1.70 $ on $Date: 2005/11/01 11:32:59 $ by $Author: colinr $

=head1 AUTHOR

John Alden and Simon Flack with some additions by Piers Kent and Wayne Myers 
<cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
