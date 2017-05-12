package Log::Any::Adapter::TAP;
use strict;
use warnings;
use parent 'Log::Any::Adapter::Base';
use Log::Any ();
use Try::Tiny;
use Carp 'croak';
require Scalar::Util;
require Data::Dumper;

our $VERSION= '0.003003';

# ABSTRACT: Logging adapter suitable for use in TAP testcases


our %level_map;              # mapping from level name to numeric level
BEGIN {
	# Initialize globals, and use %ENV vars for defaults
	%level_map= (
        min       => -1,
		trace     => -1,
		debug     =>  0,
		info      =>  1,
		notice    =>  2,
		warning   =>  3,
		error     =>  4,
		critical  =>  5,
		alert     =>  6,
		emergency =>  7,
        max       =>  7,
	);
	# Make sure we have numeric levels for all the core logging methods
	for ( Log::Any->logging_methods() ) {
		if (!defined $level_map{$_}) {
			# This is an attempt at being future-proof to the degree that a new level
			# added to Log::Any won't kill a program using this logging adapter,
			# but will emit a warning so it can be fixed properly.
			warn __PACKAGE__." encountered unknown level '$_'";
			$level_map{$_}= 4;
		}
	}
	# Now add numeric values for all the aliases, too
	my %aliases= Log::Any->log_level_aliases;
	$level_map{$_} ||= $level_map{$aliases{$_}}
		for keys %aliases;
}

sub _log_level_value { $level_map{$_[1]} }

sub _coerce_filter_level {
	my $val= shift;
	return (!defined $val || $val eq 'none')? $level_map{trace}-1
		: ($val eq 'all')? $level_map{emergency}
		: exists $level_map{$val}? $level_map{$val}
		: ($val =~ /^([A-Za-z]+)([-+][0-9]+)$/) && defined $level_map{lc $1}? $level_map{lc $1} + $2
		: croak "unknown log level '$val'";
}

our $global_filter_level;    # default for level-filtering
our %category_filter_level;  # per-category filter levels
our $show_category;          # whether to show logging category on each message
our $show_file_line;         # Whether to show caller for each message
our $show_file_fullname;     # whether to use full path for caller info
our $show_usage;             # whether to print usage notes on initialization
BEGIN {
	# Suppress debug and trace by default
	$global_filter_level= 'debug';
	
	# Apply TAP_LOG_FILTER settings
	if ($ENV{TAP_LOG_FILTER}) {
		for (split /,/, $ENV{TAP_LOG_FILTER}) {
			if (index($_, '=') > -1) {
				my ($pkg, $level)= split /=/, $_;
				local $@;
				eval { _coerce_filter_level($level); $category_filter_level{$pkg}= $level; 1; }
					or warn "$@";
			}
			else {
				local $@;
				eval { _coerce_filter_level($_); $global_filter_level= $_; 1; }
					or warn "$@";
			}
		}
	}
	
	# Apply TAP_LOG_ORIGIN
	if ($ENV{TAP_LOG_ORIGIN}) {
		$show_category= $ENV{TAP_LOG_ORIGIN} & 1;
		$show_file_line= $ENV{TAP_LOG_ORIGIN} & 2;
		$show_file_fullname= $show_file_line;
	}
	
	# Will show usage on first instance created, but suppress if ENV var
	# is defined and false.
	$show_usage= 1 unless defined $ENV{TAP_LOG_SHOW_USAGE} && !$ENV{TAP_LOG_SHOW_USAGE};
}


sub filter { $_[0]{filter} }


sub dumper { $_[0]{dumper} ||= $_[0]->default_dumper }

sub category { $_[0]{category} }


our $_show_dumper_warning= 1;
sub init {
	my $self= shift;
	my $custom_dumper= $self->{dumper};
	# Apply default dumper if not set
	$self->{dumper} ||= $self->default_dumper;
	# Apply default filter if not set
	exists $self->{filter}
		or $self->{filter}= defined $category_filter_level{$self->{category}}?
			$category_filter_level{$self->{category}}
			: $global_filter_level;
	
	# Rebless to a "level filter" package, which is a subclass of this one
	# but with some methods replaced by empty subs.
	# If log level is negative (trace), we show all messages, so no need to rebless.
	my $level= _coerce_filter_level($self->filter);
	$level= $level_map{emergency} if $level > $level_map{emergency};
	my $pkg_id= $level+1;
	bless $self, ref($self)."::Lev$pkg_id"
		if $pkg_id >= 0;
	
	# As a courtesy to people running "prove -v", we show a quick usage for env
	# vars that affect logging output.  This can be suppressed by either
	# filtering the 'info' level, or setting env var TAP_LOG_SHOW_USAGE=0
	if ($show_usage) {
		$self->info("Logging via ".ref($self)."; set TAP_LOG_FILTER=none to see"
		           ." all log levels, and TAP_LOG_ORIGIN=3 to see caller info.");
		$show_usage= 0;
	}
	if ($custom_dumper && $_show_dumper_warning) {
		$self->notice("Custom 'dumper' will not work with Log::Any versions >= 0.9");
		$_show_dumper_warning= 0;
	}
	
	return $self;
}


my %_tap_method;
sub write_msg {
	my ($self, $level_name, $str)= @_;
	
	chomp $str;
	$str= "$level_name: $str" unless $level_name eq 'info';
	
	if ($show_category) {
		$str .= ' (' . $self->category . ')';
	}
	
	if ($show_file_line) {
		my $i= 0;
		++$i while caller($i) =~ /^Log::Any(:|$)/;
		my (undef, $file, $line)= caller($i);
		$file =~ s|.*/lib/||
			unless $show_file_fullname;
		$str .= ' (' . $file . ':' . $line . ')';
	}

	# Was going to cache more of this, but logger might load before Test::More,
	# so better to keep testing it each time.  At least cache which method name we're using.
	my $name= ($_tap_method{$level_name} ||=
		($self->_log_level_value($level_name) >= $self->_log_level_value('warning')?
			'diag':'note'));
	my $m;
	if ($m= main->can($name)) {
		$m->($str);
	}
	elsif (Test::Builder->can('new')) {
		Test::Builder->new->$name($str);
	}
	else {
		$str =~ s/\n/\n#   /sg;
		if ($name eq 'diag') {
			print STDERR "# $str\n";
		} else {
			print STDOUT "# $str\n";
		}
	}
}


sub default_dumper {
	return \&_default_dumper;
}

sub _default_dumper {
	my $val= shift;
	try {
		Data::Dumper->new([$val])->Indent(0)->Terse(1)->Useqq(1)->Quotekeys(0)->Maxdepth(4)->Sortkeys(1)->Dump;
	} catch {
		my $x= "$_";
		$x =~ s/\n//;
		substr($x, 50)= '...' if length $x >= 50;
		"<exception $x>";
	};
}


# Programmatically generate all the info, infof, is_info ... methods
sub _build_logging_methods {
	my $class= shift;
	my %seen;
	# We implement the stock methods, but also 'fatal' because in my mind, fatal is not
	# an alias for 'critical' and I want to see a prefix of "fatal" on messages.
	for my $method ( grep { !$seen{$_}++ } Log::Any->logging_methods(), 'fatal' ) {
		my ($impl, $printfn);
		if ($level_map{$method} >= $level_map{info}) {
			# Standard logging.  Concatenate everything as a string.
			$impl= sub {
				(shift)->write_msg($method, join('', map { !defined $_? '<undef>' : $_ } @_));
			};
			# Formatted logging.  We dump data structures (because Log::Any says to)
			$printfn= sub {
				my $self= shift;
				$self->write_msg($method, sprintf((shift), map { !defined $_? '<undef>' : !ref $_? $_ : $self->dumper->($_) } @_));
			};
		} else {
			# Debug and trace logging.  For these, we trap exceptions and dump data structures
			$impl= sub {
				my $self= shift;
				local $@;
				eval { $self->write_msg($method, join('', map { !defined $_? '<undef>' : !ref $_? $_ : $self->dumper->($_) } @_)); 1 }
					or $self->warn("$@");
			};
			$printfn= sub {
				my $self= shift;
				local $@;
				eval { $self->write_msg($method, sprintf((shift), map { !defined $_? '<undef>' : !ref $_? $_ : $self->dumper->($_) } @_)); 1; }
					or $self->warn("$@");
			};
		}
			
		# Install methods in base package
		no strict 'refs';
		*{"${class}::$method"}= $impl;
		*{"${class}::${method}f"}= $printfn;
		*{"${class}::is_$method"}= sub { 1 };
	}
	# Now create any alias that isn't handled
	my %aliases= Log::Any->log_level_aliases;
	for my $method (grep { !$seen{$_}++ } keys %aliases) {
		no strict 'refs';
		*{"${class}::$method"}=    *{"${class}::$aliases{$method}"};
		*{"${class}::${method}f"}= *{"${class}::$aliases{$method}f"};
		*{"${class}::is_$method"}= *{"${class}::is_$aliases{$method}"};
	}
}

# Create per-filter-level packages
# This is an optimization for minimizing overhead when using disabled levels
sub _build_filtered_subclasses {
	my $class= shift;
	my $max_level= 0;
	$_ > $max_level and $max_level= $_
		for values %level_map;
	
	# Create packages, inheriting from $class
	for (0..$max_level+1) {
		no strict 'refs';
		push @{"${class}::Lev${_}::ISA"}, $class;
	}
	# For each method, mask it in any package of a higher filtering level
	for my $method (keys %level_map) {
		my $level= $level_map{$method};
		# Suppress methods in all higher filtering level packages
		for ($level+1 .. $max_level+1) {
			no strict 'refs';
			*{"${class}::Lev${_}::$method"}= sub {};
			*{"${class}::Lev${_}::${method}f"}= sub {};
			*{"${class}::Lev${_}::is_$method"}= sub { 0 }
		}
	}
}

our $_called_as_fatal;
BEGIN {
	__PACKAGE__->_build_logging_methods;
	__PACKAGE__->_build_filtered_subclasses;
	
	if ($Log::Any::VERSION >= 0.9) {
		# Log::Any broke the adapter contract a bit during these releases.
		# This is an ugly hack to preserve the function of this module.
		require Log::Any::Proxy;
		no warnings 'redefine';
		my $fatal= Log::Any::Proxy->can('fatal');
		*Log::Any::Proxy::fatal= sub { local $_called_as_fatal= 1; $fatal->(@_) };
		my $crit= \&critical;
		*critical= sub { $_called_as_fatal? fatal(@_) : $crit->(@_) };
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::TAP - Logging adapter suitable for use in TAP testcases

=head1 VERSION

version 0.003003

=head1 DESCRIPTION

When running testcases, you probably want to see some of your logging
output.  One sensible approach is to have all C<warn> and more serious
messages emitted as C<diag> output on STDERR, and less serious messages
emitted as C<note> comments on STDOUT.

So, thats what this logging adapter does.  Simply say

  use Log::Any::Adapter 'TAP';

at the start of your testcase, and now you have your logging output as
part of your TAP stream.

By default, C<debug> and C<trace> are suppressed, but you can enable
them with L</TAP_LOG_FILTER> or the L</filter> attribute.  See below.

=head1 ENVIRONMENT

=head2 TAP_LOG_FILTER

Specify the default filter value.  See attribute L</filter> for details.

You may also specify defaults per-category, using this syntax:

  $default_level,$package_1=$level,...,$package_n=$level

So, for example:

  TAP_LOG_FILTER=trace,MyPackage=none,NoisyPackage=warn prove -lv

=head2 TAP_LOG_ORIGIN

Set this variable to 1 to show which category the message came from,
or 2 to see the file and line number it came from, or 3 to see both.

=head2 TAP_LOG_SHOW_USAGE

Defaults to true, which prints a TAP comment briefing the user about
these environment variables when Log::Any::Adapter::TAP is first loaded.

Set TAP_LOG_SHOW_USAGE=0 to suppress this message.

=head1 ATTRIBUTES

=head2 filter

  use Log::Any::Adapter 'TAP', filter => 'info';
  use Log::Any::Adapter 'TAP', filter => 'debug+3';

Messages with a log level equal to or less than the filter are suppressed.

Defaults to L</TAP_LOG_FILTER>, or C<debug> which
suppresses C<debug> and C<trace> messages.

Filter may be:

=over

=item *

Any of the log level names or level aliases defined in L<Log::Any>.

=item *

C<none> or C<undef>, to filter nothing (print all log levels).

=item *

A value of C<all>, to filter everything (print nothing).

=back

The filter level may end with a C<+N> or C<-N> indicating an offset from
the named level.  The numeric values increase with importance of the message,
so C<debug-1> is equivalent to C<trace> and C<debug+1> is equivalent to C<info>.
This differs from syslog, where increasing numbers are less important.
(why did they choose that??)

=head2 dumper (DEPRECATED, unusable in Log::Any >= 0.9)

  use Log::Any::Adapter 'TAP', dumper => sub { my $val=shift; ... };

This feature lets you use a custom dumper in the printf-style logging
functions.  However, these are no longer handled by the adapter in
new versions of Log::Any, so you need to use a custom Proxy class in
your log-producing module.

=head1 METHODS

=head2 new

See L<Log::Any::Adapter::Base/new>.  Accepts the above attributes.

=head2 write_msg

  $self->write_msg( $level_name, $message_string )

This is an internal method which all the other logging methods call.  You can
override it if you want to create a derived logger that handles line wrapping
differently, or write to different file handles.

=head2 default_dumper

  $dumper= $class->default_dumper;
  $string = $dumper->( $perl_data );

Default value for the 'dumper' attribute.

This returns a coderef which can dump a value in "some human readable format".
Currently it uses Data::Dumper with a max depth of 4.
Do not depend on this default; it is only for human consumption, and might
change to a more friendly format in the future.

=head1 LOGGING METHODS

This module has all the standard logging methods from L<Log::Any/LOG LEVELS>.

Note that the regular logging methods are only specified to take a single string.
This module in the past supported passing objects as additional parameters, and
having them stringified with a custom dumper, caatching exceptions thrown during
stringification.  With the new Log::Any design, these things are decided in the
producing module, so these features are no longer possible.

If this module does receive multiple arguments or have its printf-formatting
methods called, it does the following:

For regular logging functions (i.e. C<warn>, C<info>) the arguments are
stringified and concatenated.  Errors during stringify or printing are not
caught.

For printf-like logging functions (i.e. C<warnf>, C<infof>) reference
arguments are passed to C<$self-E<gt>dumper> before passing them to
sprintf.  Errors are not caught here either.

For any log level below C<info>, errors ARE caught with an C<eval> and printed
as a warning.
This is to prevent sloppy debugging code from ever crashing a production system.
Also, references are passed to C<$self-E<gt>dumper> even for the regular methods.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
