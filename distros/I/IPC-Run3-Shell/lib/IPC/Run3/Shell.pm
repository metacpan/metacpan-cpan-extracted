#!perl
package IPC::Run3::Shell;
use warnings;
use strict;

# ##### This is the Perl module IPC::Run3::Shell #####
# 
# Documentation can be found in the file Shell.pod (or via the perldoc command).
# 
# Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl 5 itself.
# 
# For more information see the "Perl Artistic License",
# which should have been distributed with your copy of Perl.
# Try the command "perldoc perlartistic" or see
# http://perldoc.perl.org/perlartistic.html .

our $VERSION = '0.56';

use Carp;
use warnings::register;
use Scalar::Util qw/ blessed looks_like_number /;
use Data::Dumper ();
use overload ();

# debugging stuff
# either set env var or set this var externally (may set to a fh / glob ref)
our $DEBUG;
BEGIN { $DEBUG = ! ! $ENV{IPC_RUN3_SHELL_DEBUG} unless $DEBUG }
sub debug {  ## no critic (RequireArgUnpacking)
	return unless $DEBUG;
	return print { ref $DEBUG eq 'GLOB' ? $DEBUG : \*STDERR } "# ", __PACKAGE__, " Debug: ", @_, "\n";
}

my $dumper = Data::Dumper->new([])->Terse(1)->Purity(1)
	->Useqq(1)->Quotekeys(0)->Sortkeys(1)->Indent(0)->Pair('=>');
sub pp { return $dumper->Values(\@_)->Reset->Dump }  ## no critic (RequireArgUnpacking)

use IPC::Run3 ();

my @RUN3_OPTS = qw/ binmode_stdin binmode_stdout binmode_stderr append_stdout append_stderr return_if_system_error /;
my %KNOWN_OPTS = map { $_=>1 } @RUN3_OPTS,
	qw/ show_cmd allow_exit irs chomp stdin stdout stderr fail_on_stderr both /;

our $OBJECT_PACKAGE;
{
	package  ## no critic (ProhibitMultiplePackages)
		IPC::Run3::Shell::Autoload; # hide from PAUSE by splitting onto two lines
	BEGIN { $IPC::Run3::Shell::OBJECT_PACKAGE = __PACKAGE__ }
	our $AUTOLOAD;
	sub AUTOLOAD {  ## no critic (ProhibitAutoloading)
		my $cmd = $AUTOLOAD;
		IPC::Run3::Shell::debug "Autoloading '$cmd'" if $IPC::Run3::Shell::DEBUG;
		$cmd =~ s/^.*:://;
		no strict 'refs';  ## no critic (ProhibitNoStrict)
		*$AUTOLOAD = IPC::Run3::Shell::make_cmd($cmd);
		goto &$AUTOLOAD;
	}
	sub DESTROY {} # so AUTOLOAD isn't called on destruction
}

sub new {
	my ($class, %opt) = @_;
	return bless \%opt, $OBJECT_PACKAGE;
}

my %EXPORTABLE = map {$_=>1} qw/ make_cmd /; # "run" gets special handling

# this run() is for calling via IPC::Run3::Shell::run(), note that we don't export this below
*run = make_cmd();

sub import {
	my ($class, @export) = @_;
	my ($callpack) = caller;
	return import_into($class, $callpack, @export);
}

sub import_into {
	my ($class, $callpack, @export) = @_;
	my %opt;
	%opt = ( %opt, %{shift @export} ) while ref $export[0] eq 'HASH';
	for my $exp (@export) {
		if (!defined $exp) {
			warnings::warnif('uninitialized','Use of uninitialized value in import');
			next;
		}
		elsif ( !ref($exp) && $exp && ( my ($sym) = $exp=~/^:(\w+)$/ ) ) {
			if ($sym eq 'run') {
				# instead of exporting 'run', we actually export a make_cmd closure (with default options but *no* arguments)
				debug "Exporting '${callpack}::$sym' => make_cmd("._cmd2str(\%opt).")" if $DEBUG;
				no strict 'refs';  ## no critic (ProhibitNoStrict)
				*{"${callpack}::$sym"} = make_cmd(\%opt);
			}
			elsif ($sym eq 'AUTOLOAD') {
				debug "Exporting '${callpack}::$sym'" if $DEBUG;
				no strict 'refs';  ## no critic (ProhibitNoStrict)
				*{"${callpack}::AUTOLOAD"} = \&{"${OBJECT_PACKAGE}::AUTOLOAD"};
			}
			elsif ($sym eq 'FATAL') {
				debug "Enabling fatal warnings";
				warnings->import(FATAL=>'IPC::Run3::Shell');
			}
			else {
				croak "$class can't export \"$sym\"" unless $EXPORTABLE{$sym};
				my $target = __PACKAGE__."::$sym";
				debug "Exporting '${callpack}::$sym' => '$target'" if $DEBUG;
				no strict 'refs';  ## no critic (ProhibitNoStrict)
				*{"${callpack}::$sym"} = \&{$target};
			}
		}
		else {
			my ($sym, @cmd) = ref $exp eq 'ARRAY' ? @$exp : ($exp, $exp);
			croak "$class: no function name specified" unless $sym;
			$sym = _strify($sym); # warn on refs
			croak "$class: empty command for function \"$sym\"" unless @cmd;
			debug "Exporting '${callpack}::$sym' => make_cmd("._cmd2str(\%opt, @cmd).")" if $DEBUG;
			no strict 'refs';  ## no critic (ProhibitNoStrict)
			*{"${callpack}::$sym"} = make_cmd(\%opt, @cmd);
		}
	}
	return;
}

sub make_cmd {  ## no critic (ProhibitExcessComplexity)
	my @omcmd = @_;
	warnings::warnif(__PACKAGE__."::make_cmd() may have been called as a method")
		if $omcmd[0] && $omcmd[0] eq __PACKAGE__ ;
	return sub {
		my @acmd = @_;     # args to this function call
		my @mcmd = @omcmd; # copy of args to make_cmd
		# if we are a method, get default options from the object
		my %opt = blessed($acmd[0]) && $acmd[0]->isa($OBJECT_PACKAGE) ? %{shift @acmd} : ();
		# hashrefs as the first argument of make_cmd and this method override current options
		%opt = ( %opt, %{shift @mcmd} ) while ref $mcmd[0] eq 'HASH';
		%opt = ( %opt, %{shift @acmd} ) while ref $acmd[0] eq 'HASH';
		# now look at the back of @acmd
		my @tmp_opts;
		push @tmp_opts, pop @acmd while ref $acmd[-1] eq 'HASH';
		%opt = ( %opt, %{pop @tmp_opts} ) while @tmp_opts;
		# this is for the tests that test the option inheritance mechanism
		if (exists $opt{__TEST_OPT_A} || exists $opt{__TEST_OPT_B}) {
			return join ',', (
				exists $opt{__TEST_OPT_A} ? 'A='.(defined $opt{__TEST_OPT_A} ? $opt{__TEST_OPT_A} : 'undef') : (),
				exists $opt{__TEST_OPT_B} ? 'B='.(defined $opt{__TEST_OPT_B} ? $opt{__TEST_OPT_B} : 'undef') : () );
		}
		# check options for validity
		for (keys %opt) {
			warnings::warnif(__PACKAGE__.": unknown option \"$_\"")
				unless $KNOWN_OPTS{$_};
		}
		my $allow_exit = defined $opt{allow_exit} ? $opt{allow_exit} : [0];
		if ($allow_exit ne 'ANY') {
			$allow_exit = [$allow_exit] unless ref $allow_exit eq 'ARRAY';
			warnings::warnif(__PACKAGE__.": allow_exit is empty") unless @$allow_exit;
			for (@$allow_exit) {
				# We throw our own custom warning instead of Perl's regular warning because Perl's warning
				# would be reported in this module instead of the calling code.
				warnings::warnif('numeric','Argument "'.(defined($_)?$_:"(undef)").'" isn\'t numeric in allow_exit')
					unless defined && looks_like_number($_);
				no warnings 'numeric', 'uninitialized';  ## no critic (ProhibitNoWarnings)
				$_ = 0+$_; # so later usage as a number isn't a warning
			}
		}
		# Possible To-Do for Later: Define priorities for incompatible options so we can carp instead of croaking?
		# Also maybe look at some other places where we croak at runtime to see if there is any way to carp there instead.
		croak __PACKAGE__.": can't use options stderr and fail_on_stderr at the same time"
			if exists $opt{stderr} && $opt{fail_on_stderr};
		croak __PACKAGE__.": can't use options both and stdout at the same time"
			if $opt{both} && exists $opt{stdout};
		croak __PACKAGE__.": can't use options both and stderr at the same time"
			if $opt{both} && exists $opt{stderr};
		croak __PACKAGE__.": can't use options both and fail_on_stderr at the same time"
			if $opt{both} && $opt{fail_on_stderr};
		# assemble command (after having processed any option hashes etc.)
		my @fcmd = (@mcmd, @acmd);
		croak __PACKAGE__.": empty command" unless @fcmd;
		# stringify the stringifiable things, handle undef, and warn on refs
		@fcmd = map {_strify($_)} @fcmd;
		
		# prepare STDOUT redirection
		my ($out, $stdout) = ('');
		if (exists $opt{stdout})  ## no critic (ProhibitCascadingIfElse)
			{ $stdout = $opt{stdout} }
		elsif ($opt{both})
			{ $stdout = defined(wantarray) ? \$out : undef }
		elsif (wantarray)
			{ $stdout = $out = [] }
		elsif (defined(wantarray))
			{ $stdout = \$out }
		else
			{ $stdout = undef }
		# prepare STDERR redirection
		my ($err, $stderr) = ('');
		if (exists $opt{stderr})
			{ $stderr = $opt{stderr} }
		elsif ($opt{fail_on_stderr})
			{ $stderr = \$err }
		elsif ($opt{both})
			{ $stderr = wantarray ? \$err : ( defined(wantarray) ? \$out : undef ) }
		else
			{ $stderr = undef }
		# prepare options hash
		my %r3o = ( return_if_system_error=>1 );
		for (@RUN3_OPTS) { $r3o{$_} = $opt{$_} if exists $opt{$_} }
		# execute and process
		debug "run3("._cmd2str(@fcmd).") ".pp(\%opt) if $DEBUG;
		print { ref $opt{show_cmd} eq 'GLOB' ? $opt{show_cmd} : \*STDERR } '$ '._cmd2str(@fcmd)."\n" if $opt{show_cmd};
		local $/ = exists $opt{irs} ? $opt{irs} : $/;
		# NOTE that we've documented that the user can rely on $?, so don't mess with it
		IPC::Run3::run3( \@fcmd, $opt{stdin}, $stdout, $stderr, \%r3o )
			or croak __PACKAGE__." (internal): run3 \"$fcmd[0]\" failed";
		my $exitcode = $?>>8;
		croak "Command \"$fcmd[0]\" failed: process wrote to STDERR: \"$err\""
			if $opt{fail_on_stderr} && $err ne '' && $err ne $/;
		if ($? == -1) {
			warnings::warnif("Command \"$fcmd[0]\" failed: $!");
			return
		}
		elsif ($?&127) {
			warnings::warnif(sprintf("Command \"%s\" failed: signal %d, %s coredump",
				$fcmd[0], ($?&127), ($?&128)?'with':'without' ))
		}
		else {
			# allow_exit is checked for validity above
			warnings::warnif("Command \"$fcmd[0]\" failed: exit status $exitcode")
				unless $allow_exit eq 'ANY' || grep {$_==$exitcode} @$allow_exit;
		}
		return unless defined wantarray;
		if (exists $opt{stdout})
			{ return $exitcode }
		elsif ($opt{both}) {
			chomp($out,$err) if $opt{chomp};
			return wantarray ? ($out, $err, $exitcode) : $out
		}
		elsif (wantarray) {
			chomp(@$out) if $opt{chomp};
			return @$out
		}
		else {
			chomp($out) if $opt{chomp};
			return $out
		}
	}
}

# This function attempts to behave like normal Perl stringification, but it adds two things:
# 1. Warnings on undef, in Perl's normal "uninitialized" category, the difference being that
#    with "warnif", they will appear to originate in the calling code, and not in this function.
# 2. Warn if we are passed a reference that is not an object with overloaded stringification,
#    since that is much more likely to be a mistake on the part of the user instead of intentional.
sub _strify {
	my ($x) = @_;
	if (!defined $x) {
		warnings::warnif('uninitialized','Use of uninitialized value in argument list');
		return "" }
	elsif (blessed($x) && overload::Overloaded($x)) { # an object with overloading
		if (overload::Method($x,'""')) # stringification explicitly defined, it'll work
			{ return "$x" }
		# Else, stringification is not explicitly defined - stringification *may* work through autogeneration, but it may also die.
		# There doesn't seem to be a way to ask Perl if stringification will die or not other than trying it out with eval.
		# See also: http://www.perlmonks.org/?node_id=1121710
		# Reminder to self: "$x" will always be defined; even if overloaded stringify returns undef;
		# undef interpolated into the string will cause warning, but the resulting empty string is still defined.
		elsif (defined(my $rv = eval { "$x" }))
			{ return $rv }
		elsif ($@=~/\bno method found\b/) { # overloading failed, throw custom error
			# Note: as far as I can tell the message "no method found"
			# hasn't changed since its intoduction in Perl 5.000
			# (e.g. git log -p -S 'no method found' gv.c )
			# Perl bug #31793, which relates to overload::StrVal, apparently also caused problems with Carp
			if (!$overload::VERSION || $overload::VERSION<1.04)
				{ die "Package ".ref($x)." doesn't overload stringification: $@" }  ## no critic (RequireCarping)
			else
				{ croak "Package ".ref($x)." doesn't overload stringification: $@" }
		}
		# something other than overloading failed, just re-throw
		else { die $@ }  ## no critic (RequireCarping)
		# Remember that Perl's normal behavior should stringification not be
		# available is to die; we're just propagating that behavior outward.
	}
	else {
		# Note that objects without any overloading will stringify using Perl's default mechanism
		ref($x) and warnings::warnif(__PACKAGE__.": argument list contains references/objects");
		return "$x" }
}

# function for sorta-pretty-printing commands
sub _cmd2str {
	my @c = @_;
	my $o = '';
	for my $c (@c) {
		$o .= ' ' if $o;
		if (ref $c eq 'HASH') { # options
			# note we don't pay attention to where in the argument list we are
			# (I don't expect hashrefs to appear as arguments, the user is even warned about them)
			$o .= pp($c);
		}
		else {
			my $s = defined $c ? "$c" : '';
			$s = pp($s) if $s=~/[^\w\-\=\/\.]/;
			$o .= $s;
		}
	}
	return $o;
}


1;
