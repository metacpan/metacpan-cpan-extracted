package Log::Any::Adapter::Daemontools;
use 5.008; # need weak reference support
our @ISA; BEGIN { require Log::Any::Adapter::Base; @ISA= 'Log::Any::Adapter::Base' };
use strict;
use warnings;
use Log::Any::Adapter::Util 'numeric_level';
use Log::Any 1.03;
use Log::Any::Adapter::Daemontools::Config;

our $VERSION= '0.101';

# ABSTRACT: Logging adapter suitable for use in a Daemontools-style logging chain


our $global_config;
sub global_config {
	$global_config ||= shift->new_config;
}

sub new_config {
	my $class= shift;
	$class= ref($class) || $class;
	my $cfg= "${class}::Config"->new(@_);
	return $cfg;
}


sub category { shift->{category} }
sub config   { shift->{config} }


# Special carp/croak that ignore Log::Any infrastructure
sub carp { Log::Any::Adapter::Daemontools::Config::carp(@_) }
sub croak { Log::Any::Adapter::Daemontools::Config::croak(@_) }

# Log::Any::Adapter constructor, also named 'init'
sub init {
	my $self= shift;
	
	$self->{config} ||= $self->global_config;
	
	# Warn about unsupported/deprecated features from 0.002
	carp "filter is deprecated.  Use config->log_level" if exists $self->{filter};
	carp "dumper is unsupported. See Log::Any::Proxy" if exists $self->{dumper};
	
	
	# This constructor gets called for each Adapter instance, so we need
	# to track whether we applied the -init to the config yet.
	if ($self->{'-init'} && !$self->{config}{_adapter_init_applied}) {
		++$self->{config}{_adapter_init_applied};
		$self->{config}->init( $self->{'-init'} );
	}

	# Set up our lazy caching system (re-blesses current object)
	$self->_uncache_config;
}


sub _squelch_base_class { ref($_[0]) || $_[0] }

# Create per-squelch-level subclasses of a given package
# This is an optimization for minimizing overhead when using disabled levels
sub _build_squelch_subclasses {
	my $class= shift;
	my %numeric_levels= ( map { $_ => 1 } -1, map { numeric_level($_) } Log::Any->logging_methods() );
	my %subclass;
	foreach my $level_num (keys %numeric_levels) {
		my $package= $class.'::Squelch'.($level_num+1);
		$subclass{$package}{_squelch_base_class}= sub { $class };
		foreach my $method (Log::Any->logging_methods(), 'fatal') {
			if ($level_num < numeric_level($method)) {
				$subclass{$package}{$method}= sub {};
				$subclass{$package}{"is_$method"}= sub { 0 };
			}
		}
	}
	$subclass{"${class}::Lazy"}{_squelch_base_class}= sub { $class };
	foreach my $method (Log::Any->logging_and_detection_methods(), 'fatal', 'is_fatal') {
		# Trampoline code that lazily re-caches an adaptor the first time it is used
		$subclass{"${class}::Lazy"}{$method}= sub {
			$_[0]->_cache_config;
			goto $_[0]->can($method)
		};
	}
	
	# Create subclasses and install methods
	for my $pkg (keys %subclass) {
		no strict 'refs';
		@{$pkg.'::ISA'}= ( $class );
		for my $method (keys %{ $subclass{$pkg} }) {
			*{$pkg.'::'.$method}= $subclass{$pkg}{$method};
		}
	}
	1;
}

# The set of adapters which have been "squelch-cached"
# (i.e. blessed into a subclass)
our %_squelch_cached_adapters;

BEGIN {
	foreach my $method ( Log::Any->logging_methods() ) {
		my $m= sub { my $self= shift; $self->{_writer}->($self, $method, @_); };
		no strict 'refs';
		*{__PACKAGE__ . "::$method"}= $m;
		*{__PACKAGE__ . "::is_$method"}= sub { 1 };
	}
	__PACKAGE__->_build_squelch_subclasses();
}

# Cache the ->config settings into this adapter, which also
# re-blesses it based on the current log level.
sub _cache_config {
	my $self= shift;
	$self->{_writer}= $self->config->compiled_writer;
	my $lev= $self->config->log_level_num;
	# Backward compatibility with version 0.002
	if (exists $self->{filter}) {
		$lev= Log::Any::Adapter::Util::NOTICE - _coerce_filter_level($self->{filter});
	}
	bless $self, $self->_squelch_base_class.'::Squelch'.($lev+1);
	$self->config->_register_cached_adapter($self);
}

# Re-bless adapter back to its "Lazy" config cacher class
sub _uncache_config {
	bless $_[0], $_[0]->_squelch_base_class . '::Lazy';
}

#-------------------------------------------------------------------
# Backward compatibility with version 0.002.  Do not use in new code.

sub write_msg {
	my ($self, $level, $message)= @_;
	# Don't bother optimizing and caching
	$self->config->compiled_writer->($self, $level, $message);
}

sub _default_dumper {
	require Data::Dumper;
	my $val= shift;
	local $@;
	my $dump= eval { Data::Dumper->new([$val])->Indent(0)->Terse(1)->Useqq(1)->Quotekeys(0)->Maxdepth(4)->Sortkeys(1)->Dump };
	if (!defined $dump) {
		my $x= "$@";
		$x =~ s/\n//;
		substr($x, 50)= '...' if length $x >= 50;
		$dump= "<exception $x>";
	};
	return $dump;
}

sub _coerce_filter_level {
	my $val= shift;
	my %level_map= (
		trace    => -2,
		debug    => -1,
		info     =>  0,
		notice   =>  1,
		warning  =>  2,
		error    =>  3,
		critical =>  4,
		fatal    =>  4,
	);
	return (!defined $val || $val eq 'none')? $level_map{trace}-1
		: Scalar::Util::looks_like_number($val)? $val
		: exists $level_map{$val}? $level_map{$val}
		: ($val =~ /^debug-(\d+)$/)? $level_map{debug} - $1
		: croak "unknown log level '$val'";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Daemontools - Logging adapter suitable for use in a Daemontools-style logging chain

=head1 VERSION

version 0.101

=head1 SYNOPSIS

Default: log to C<STDOUT>, log level C<info>, prefix each line with level name unless it is C<info>:

  use Log::Any::Adapter 'Daemontools';

Default to log level C<notice>, and write to C<STDERR>:

  use Log::Any::Adapter 'Daemontools', -init => { level => 'notice', out => \*STDERR };

Process C<@ARGV> C<-v>/C<-q> and C<$ENV{DEBUG}> to adjust the log level

  use Log::Any::Adapter 'Daemontools', -init => { argv => 1, env => 1 };

Custom output formatting:

  use Log::Any::Adapter 'Daemontools', -init => { format => '"$level: $_ (at $file on line $line)"' };

Change log level on the fly:

  my $cfg= Log::Any::Adapter::Daemontools->global_config;
  $SIG{USR1}= sub { $cfg->log_level_adjust(1); };
  $SIG{USR2}= sub { $cfg->log_level_adjust(-1); };
  
  # Those signal handlers can also be installed by the config:
  use Log::Any::Adapter 'Daemontools', -init => { signals => ['USR1','USR2'] };

Create alternate configurations separate from the global config: 

  my $cfg2= Log::Any::Adapter::Daemontools->new_config(log_level => 'notice');
  Log::Any::Adapter->set(
    { category => qr/^Noisy::Package::Hierarchy.*/ },
    config => $cfg2
  );

See L<Log::Any::Adapter::Daemontools::Config> for most of the usage details.

=head1 DESCRIPTION

The measure of good software is low learning curve, low complexity, few
dependencies, high efficiency, and high flexibility.  (choose two.  haha)

In the daemontools way of thinking, a daemon writes all its logging output
to C<STDOUT> (or C<STDERR>), which is a pipe to a logger process.
Doing this instead of other logging alternatives keeps your program simple
and allows you to capture errors generated by deeper libraries (like libc)
which aren't aware of your logging API.  If you want complicated logging you
can keep those details in the logging process and not bloat each daemon you
write.

This module aims to be the easiest, simplest, most efficent way to get
L<Log::Any> messages to a file handle while still being flexible enough for the
needs of the typical unix daemon or utility script.

Problems solved by this module are:

=over

=item Preserve log level

The downside of logging to a pipe is you don't get the log-level that you
could have had with syslog or Log4perl.  An simple way to preserve this
information is to prefix each line with "error:" or etc, which can be
re-parsed later (or by the logger process). See L<format|Log::Any::Adapter::Daemontools::Config/format>.

=item Efficiently squelch log levels

Trace logging is a great thing, but the methods can get a bit "hot" and you
don't want it to impact performance.  Log::Any provides the syntax

  $log->trace(...) if $log->is_trace

which is great as long as "is_trace" is super-efficient.  This module does
subclassing/caching tricks so that suppressed log levels are effectively
C<sub is_trace { 0 }>
(although as of Log::Any 1.03 there is still another layer of method call
from the Log::Any::Proxy, which is unfortunate)

=item Dynamically adjust log levels

L<Log::Any::Adapter> allows you to replace the current adapters with new ones
with a different configuration, which you can use to adjust C<log_level>,
but it isn't terribly efficient, and if you are also using the regex feature
(where different categories get different loggers) it's even worse.

This module uses shared configurations on the back-end so you can alter the
configuration in many ways without having to re-attach the adapters.
(there is a small re-caching penalty, but it's done lazily)

=item C<--verbose> / C<--quiet> / C<$ENV{DEBUG}>

My scripts usually end up with a chunk of boilerplate in the option processing
to raise or lower the log level.  This module provides an option to get you
common UNIX behavior in as little as 7 characters :-)
It's flexible enough to give you many other common varieties, or you can ignore
it because it isn't enabled by default.

=item Display C<caller> or C<category>, or custom formatting

And of course, you often want to see additional details about the message or
perform some of your own tweaks.  This module provides a C<format> option to
easily add C<caller> info and/or C<category> where the message originated,
and allows full customization with coderefs.

=item Enable autoflush on output handle

I often forget to C< $|= 1 >, and then wonder why my log messages don't match
what the program is currently doing.  This module turns on autoflush if
'output' is a file handle.  (but if output is a coderef or other object, it's
still up to you)

=back

=head1 VERSION NOTICE

NOTE: Version 0.1 lost some of the features of version 0.002 when the
internals of Log::Any changed in a way that made them impossible.
I don't know if anyone was using them anyway, but pay close attention
if you are upgrading.  This new version adheres more closely to the
specification for a logging adapter.

=head1 PACKAGE METHODS

=head2 global_config

  my $cfg= Log::Any::Adapter::Daemontools->global_config;

Returns the default config instance used by any adapter where you didn't
specify one.

=head2 new_config

  my $cfg= Log::Any::Adapter::Daemontools->new_config( %attributes )

Returns a new instance of a config object appropriate for use with this
adapter, but currently always an instance of L<Log::Any::Adapter::Daemontools::Config>.
See that package for available attributes.

  Log::Any::Adapter->set( 'Daemontools', config => $cfg );

This method is preferred over calling ->new on the L<Log::Any::Adapter::Daemontools::Config>
package directly, in case some day I decide to play subclassing tricks with the
Config objects.

=head1 ATTRIBUTES

=head2 category

The category of the L<Log::Any> logger attached to this adapter.  Read-only.

=head2 config

The L<Log::Any::Adapter::Daemontools::Config> object which this adapter is
tracking.  Read-only reference ( but the config can be altered ).

=head2 -init

  Log::Any::Adapter 'Daemontools', -init => { ... };

Not actually an attribute!  If you pass this to the Daemontools adapter,
the first time an instance of the Adapter is created it will call ->init on
the adapter's configuration.  This allows you to squeeze things onto one line.

The more proper way to write the above example is:

  use Log::Any::Adapter 'Daemontools';
  Log::Any::Adapter::Daemontools->global_config->init( ... );

The implied init() call will happen exactly once per config object.
(but you can call the init() method yourself as much as you like)

See L<Log::Any::Adapter::Daemontools::Config/init> for the complete list
of initialization options.

DO NOT pass un-sanitized user input to -init, because the 'format' attribute
is processed as perl code.

=head1 METHODS

Adapter instances support all the standard logging methods of Log::Any::Adapter

See L<Log::Any::Adapter>

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
