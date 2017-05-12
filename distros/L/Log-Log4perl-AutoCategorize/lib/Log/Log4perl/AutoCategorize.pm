
package Log::Log4perl::AutoCategorize;
use strict;
our $VERSION = "0.03";

use Carp;
use IO::File;

use Log::Log4perl;
use Log::Dispatch::Screen;
use Log::Dispatch::File;
use Log::Log4perl::Appender;

#use YAML;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse = 1;

###################
my $MyPkg = __PACKAGE__;
my $Alias = $MyPkg; # this is changed if you use aliasing feature

use vars qw($AUTOLOAD);
our( # my complicates debug
     %SeenCat,	# collect categories seen
     %UnSeenCat,# filled at compile by optimizer, cleared at END
     %cat2data,	# category => [ logger-handle, level, munged-name, enablement ]
     %fn2cat,	# munged-name => category.  used for init-and-watch handling
     @usrPkgs,	# collect list of user packages.
);

my $dumper;	# bound to Data::Dumper() or YAML::Dump by first call of AUTOLOAD
my $defConf;	# default logger config.

# silence redefine errs (no warnings wont do it, cuz theyre const);
#BEGIN { local $SIG{__WARN__} = sub { return if /redefined/; carp(@_) }};

my $opt; # hashref of debug option flags, initialized in begin
BEGIN {
    # cuz Logger is used at import time (ie early) by many other
    # modules, it must load its own config at compile-time.
    # use Logger ($conffile) might be possible with import routine.

    # allow notify, do before init();
  Log::Log4perl::Logger::create_custom_level("NOTIFY", "WARN");
  Log::Log4perl::Logger::create_custom_level("NOTICE", "WARN");

    $opt = {
	# flags checked in optimization phase
	v => 0,		# generic verbosity
	f => 0,		# found op-chains (starting with pushmark)
	#F => 0,		# found op-chains op-dump
	m => 0,		# matched op-chains (found & end with method-named)
	M => 0,		# matched op-chains op-dump
	j => 0,		# junk op-chains (subset of found)
	J => 0,		# junk op-chains op-dump
	d => 0,		# $op->dump() while examining opcodes
	s => 0,		# print opstack while scanning for ending method_named op
	x => 0,		# extreme debug
	r => 0,		# function renaming (munging)
	#z => 0,		# $op->dump when done optimizing
	w => 0,		# log wrong ops in chain that matched
	D => 0,		# break in optimizer if debugging

	# flags checked in AUTOLOAD, at runtime
	i => 0,		# AUTOLOAD invoked
	A => 0,		# AUTOLOAD args
	a => 0,		# AUTOLOAD use of caller() 
	b => 0,		# anon-sub build
	c => 0,		# logging category creation
	n => 0,		# no optimize (dont stash the method)
	y => 0,		# use YAML::Dump (default is Data::Dumper, TBD)

	e => 0,		# print END results to stdout
	z => 0,		# print size of stuff at END
	Z => 0,		# print more size stuff at END

	# these 2 are 'inverted', so that default is 'on'
	l => 0,		# dont add level to category, ie: pkg.sub.level.line
	C => 0,		# dont add 'log4perl.category.' prefix to END results
    };

    # default Log4per config writes to stdout, and creates a coverage log
    $defConf = q{
	 log4perl.rootLogger = DEBUG, A1
	 log4perl.appender.A1 = Log::Dispatch::Screen
	 log4perl.appender.A1.layout = PatternLayout
	 log4perl.appender.A1.layout.ConversionPattern = %d %c: %m%n
	 # create COVERAGE log
	 log4perl.appender.COVERAGE = Log::Dispatch::File
	 log4perl.appender.COVERAGE.filename = sub { \
		my $n = $0;		\
		$n =~ s|.*/||;		\
		$n =~ s/(\.(t|pl))?$//;	\
		return "./out.$n.cover";\
	 }
         log4perl.appender.COVERAGE.mode = write
	 log4perl.appender.COVERAGE.layout = org.apache.log4j.PatternLayout
	 log4perl.appender.COVERAGE.layout.ConversionPattern = \
	     (%d{HH:mm:ss.SSS}) %c: %m%n
	 # now that Coverage file has been set up, 
	 # send the END-block output there
	 log4perl.logger.Log.Log4perl.AutoCategorize.END = INFO, COVERAGE
    };
}

########

sub import {
    my $pkg = shift;
    my (%args) = @_;

    my ($cpkg) = (caller(0))[0];
    push @usrPkgs, $cpkg;

    local $" = ",";
    set_debug($args{debug}) if $args{debug};
    print "importing: $pkg into $cpkg, users: @usrPkgs\n";# if $opt->{v};

    if ($args{alias}) {
	if ($opt->{v}) {
	    print "aliasing $pkg as $args{alias}\n";
	    my @caller = (caller(0))[0..2];
	    print "importer is: @caller\n"; 
	}
	no strict 'refs';
	*{$args{alias}} = *{$pkg};
	*{$args{alias}.'::AUTOLOAD'} = *{$pkg.'::AUTOLOAD'};
	# *{$cpkg.'::'.$args{alias}} = *{$pkg};
	# *{$cpkg.'::'.$args{alias}.'::AUTOLOAD'} = *{$pkg.'::AUTOLOAD'};

	$Alias = delete $args{alias};
    }

    # Logger initialization: init*-directives may override default,
    # but not vice-versa.  Interface is subject to change, esp wrt
    # additional configuration items (currently just replaces previous)

    if ($args{initfile}) {
	print "initialize with file: $args{initfile}\n" if $opt->{v};
        Log::Log4perl->init_and_watch($args{initfile}, 10);
	delete $args{initfile};
    }
    # someday, doing both might work.  right now, now its either or.
    elsif ($args{initstr}) {
	print "initialize with string\n" if $opt->{v};
        Log::Log4perl->init(\$args{initstr});
	delete $args{initstr};
    }
    else {
	return if $opt->{initd};
	print "initializing Logger with default\n" if $opt->{v};
        Log::Log4perl->init(\$defConf);
    }
    $opt->{initd} = 1;
}

sub set_debug {
    my ($arg) = pop @_;
    my $allowed = join '', sort keys %$opt;
    my $bad;
    foreach my $letter (split //, $arg) {
	if (defined $opt->{$letter}) {
	    $opt->{$letter} = 1;
	} else {
	    $bad .= $letter;
	}
    }
    die "illegal debug option(s): $bad - allowed: $allowed\n" if $bad;

    if ($opt->{z}) {
	eval {
	    require Devel::Size;
	    Devel::Size->import qw(size total_size);
	};
	die "$@: -z option requires Devel::Size\n" if $@;
    }
}

sub get_loglevel {
    # returns the level-string, should really query base for complete set
    return $1 if $_[0] =~ m/^(?:log_)?(debug|info|warn|error|fatal|notice)/;
    return 0;
}

###################
sub AUTOLOAD {
    print "args: ", Dumper \@_ if $opt->{A};
    my $cpkg = $_[0];

    (my $meth = $AUTOLOAD) =~ s/.*:://;
    return if $meth eq 'DESTROY';
    print "\ncalled_as = $cpkg.$meth\n" if $opt->{i};

    # test if meth is a legitimate logging level
    my $level = get_loglevel($meth);
    unless ($level) {
	# delegate if possible (this is why u subclass)
	if (Log::Log4perl->can($meth)) {
	    print "delegating to Log::Log4perl->$meth()\n" if $opt->{v};
	    shift @_;
	    Log::Log4perl->$meth(@_);
	}
	elsif (Log::Log4perl::AutoCategorize->can($meth)) {
	    print "delegating to Log::Log4perl::AutoCategorize->$meth()\n"
		if $opt->{v};
	    shift @_;
	    Log::Log4perl::AutoCategorize->$meth(@_);
	}
	else { carp "$meth is not a legitimate log-level\n" }
	return;
    }
    # $meth = $level;
    print "meth: $meth\n" if $opt->{i};

    # use FQ name as category
    my ($pkg,$file,$ln0,$ln1,$sub0,$sub1);

    if (($pkg,$file,$ln1,$sub1) = caller(1)) {
	print "1: $pkg,$file,$ln1,$sub1\n" if $opt->{a};
    }
    ($pkg,$file,$ln0,$sub0) = caller(0);
    print "0: $pkg,$file,$ln0,$sub0\n" if $opt->{a};

    # construct category, avoid AUTOLOAD sub-name
    my $cat = $sub1 || 'main.main';
    $cat .= ".$level" unless $opt->{l};
    $cat .= ".$ln0";
    $cat =~ s/::/./g;

    if ($cat2data{$cat}) {
	my $catinc = 'a';
	$catinc++ while $cat2data{$cat.$catinc};
	$cat .= $catinc;
    } 
    print "cat: $cat\n" if $opt->{c};
    delete $UnSeenCat{$meth};

    my $log = Log::Log4perl->get_logger($cat);
    my $predicate = "is_$level";
    
    # is it runnable ?
    my $runnable;
    eval { $runnable = $log->$predicate() };
    if ($@) {
	die("logger: cant $predicate on $cat: $@");
	return;
    }
    # record everything we might need in delegate
    $cat2data{$cat} = [ $log, $level, $meth, $runnable ];
    # $fn2cat{$meth} = $cat; # needed to expire stale routines.

    unless ($dumper) {
	$dumper = \&Data::Dumper::Dump;
	#$dumper = \&YAML::Dump if $opt->{y};
    }
    # make the right anonymous sub, depending on runability
    # avoid closure on $cat; make it string literal ??
    my $code;
    if (not $runnable) {
	print "building disabled sub: $cpkg.$meth\n" if $opt->{b};
	$code = sub { $SeenCat{"$cat"}-- };
    }
    else {
	print "building enabled sub: $cpkg.$meth\n" if $opt->{b};
	$code = sub { logitDumper ("$cat", @_) };
	#$code = sub { logitYAML   ("$cat", @_) } if $opt->{y};
    }
    # stash it
    unless ($opt->{n}) {
	no strict 'refs';
	#*{__PACKAGE__.'::'.$meth} = $code; 
	#*{$Alias.'::'.$meth} = $code;
	*{$cpkg.'::'.$meth} = $code;
    }
    #printf "code size for $meth: %d\n", total_size($code) if $opt->{z};
    goto &$code;
}

sub logitDumper {
    # log the message to base logger, using Data::Dumper to handle refs
    my ($cat, $cls, @args) = @_;
    my @scalars;

    $SeenCat{"$cat"}++;
    my ($logger, $level) = @{$cat2data{$cat}};

    eval {
	# pull leading scalars from @args to @scalars
	push @scalars, shift @args while @args and not ref $args[0];

	# stringify @scalars, and Dump refs
	$logger->$level( !@scalars ? () : "@scalars, ",
			 !@args    ? () : Dumper((@args==1) ? @args : [@args]));
    };
    if ($@) { carp("logger dump problem on $cat: $@") }
    return "logged";
}

sub logitYAML {}

#######

sub myDump {
    print "# observed logging categories:\n", Dumper(\%SeenCat);
}

END {
    my %cat2munged;
    $cat2munged{$_} = $cat2data{$_}[2] foreach keys %cat2data;

    unless ($opt->{C}) {
	# add prefix so its easy to edit coverage report into a config-file
	$SeenCat{"log4perl.category.$_"} = delete $SeenCat{$_} foreach keys %SeenCat;
    }

    # I eat my own dog-food.  Note: this doesnt get munged, cuz the
    # optimizer munge criteria are 'tight'.  This is fine, cuz
    # mycaller() reports it well.

    $Alias->info("Seen Log Events:", \%SeenCat);
    $Alias->info("UnSeen Log Events:", \%UnSeenCat);
    $Alias->info("cat2data:", \%cat2munged);

    if ($opt->{e}) {
	print "Seen Log Events:"	=> Dumper \%SeenCat;
	print "un-Seen methods:"	=> Dumper \%UnSeenCat;
	print "cat2info:"		=> Dumper \%cat2munged;
    }
    if ($opt->{y}) {
	print "Seen Log Events:"	=> Dump(%SeenCat);
	print "un-Seen methods:"	=> Dump(%UnSeenCat);
	print "cat2data:"		=> Dump(%cat2munged);
    }
    if ($opt->{z}) {
	eval {
	    require Devel::Size;
	    Devel::Size->import qw(size total_size);
	    {
		# attempt to control msg: 'CV not complete'
		package Devel::Size;
		use warnings::register;
	    }
	};
	die "-z option requires Devel::Size\n" if $@;

	# print size info.  Devel::Size does an incomplete job on CVs,
	# so theres insufficient value to these numbers to base
	# decisions upon.

	my (%fnsizes, %hashsizes, %stashsizes, $total);

	foreach my $fn (values %cat2munged) {
	    $total += $fnsizes{$fn}
		= total_size(\&{"Log::Log4perl::AutoCategorize::".$fn});
	}
	printf "total size of stashed subs: %d\n", $total;
	print "function size breakdown: ", Dumper \%fnsizes;

	no strict 'refs';
	$total = 0;
	foreach my $hashname (qw(SeenCat UnSeenCat cat2data)) {
	    $total += $hashsizes{$hashname} = total_size(\%{$hashname});
	}
	printf "total size of my hashs: %d\n", $total;
	print "my hash size breakdown: ", Dumper \%hashsizes;

	if ($opt->{Z}) {
	    $total = 0;
	    foreach my $stashitem (values %Log::Log4perl::AutoCategorize::) {
		$total += $stashsizes{$stashitem} = total_size($stashitem);
	    }
	    printf "total size of stash items: %d\n", $total;
	    printf "total size, all at once: %d\n"
		, total_size(\%Log::Log4perl::AutoCategorize::);

	}
	print "stash size breakdown: ", Dumper \%stashsizes;
    }
}

###################
# optimizer stuff, only for 5.8
# __END__ # uncomment __END__ to use in 5.6.x, and accept slowdown

# silence 'Subroutine redefined' warnings due to B::Generate
local $SIG{__WARN__};	# localize outside BEGIN block
BEGIN {
    $SIG{__WARN__} = sub { 
	return if $_[0] =~ /Subroutine B(::\w+)+ redefined/;
	warn $_[0];
    };
}

my $munged = '00000';
#INIT { $munged = '00000' };


# sub method_munger
use optimizer 'extend-c' => sub {
    my $opp = shift;

    # look for op-chains which start with pushmark & const == __PACKAGE__
    # Scan until method_named is reached, while keeping track of inner
    # stack manipulations (iow monitor balance of push, pop on @opstack)
    
    my $n1 = $opp->name();
    $opp = $opp->next();
    return if ref $opp eq 'B::NULL';

    my $n2 = $opp->name();
    # by Policy, use Class method invocation only, hence const
    return unless $n1 eq "pushmark" and $n2 eq "const";

    # Class method allows code to expect the const opcodes value to be
    # Log::Log4perl::AutoCategorize or $Alias.  All others end the chain.

    my $class = '';
    eval { $class = $opp->sv->PV };	# sets $class unless $@
    return unless $class and $Alias and $MyPkg;

    return unless $class eq $Alias or $class =~/^$MyPkg/;

    $DB::single = 1 if $opt->{D};
    $opp->dump if $opt->{d};

    # OK: weve seen 2 required ops; pushmark, const='Logger'.  Now we
    # track stack activity, so that nested meth_named ops dont
    # prematurely end the scan which guards the munge.

    my (@opchain, @opstack, $name);

    while (@opstack or $opp->name ne 'method_named') {

	return if ref $opp eq 'B::NULL';
	$opp = $opp->next();
	return if ref $opp eq 'B::NULL';
	
	push @opchain, $opp;
	$name = $opp->name;
	
	if ($name eq 'pushmark') {
	    push @opstack, $opp;
	    printf "pushed: %s\n", opNames(\@opchain) if $opt->{s};
	}
	if ($name =~ /refgen|entersub/) {
	    printf "popping: %s\n", opNames(\@opchain) if $opt->{s};
	    pop @opstack;
	}
    }
    printf "found op-chain: $class => %s\n", opNames(\@opchain) if $opt->{f};

    # this should be proper end of chain
    my ($meth) = $opchain[-1];

    unless ($meth->name eq 'method_named') {
	# this is a sign of problems.
	printf "junk op-chain: $class => %s\n", opNames(\@opchain) if $opt->{j};
	dumpchain(\@opchain) if $opt->{J};
	return;
    }

    printf "matched op-chain: $class => %s\n", opNames(\@opchain) if $opt->{m};
    dumpchain(\@opchain) if $opt->{M};

    my $fnname = $meth->sv->PV;
    unless (get_loglevel($fnname)) {
	print "$fnname is ineligible for munging\n" if $opt->{v};
	return;
    }
    # now do the munge
    #print "func: $fnname\n" if $opt->{r};
    $munged++;
    $meth->sv->PV("${fnname}_$munged");

    # record munged fnname, and where its called (to aid test-coverage review)
    my $cllr = join(',', (caller(0))[0..2]);
    $UnSeenCat{"${fnname}_$munged"} = $cllr;

    print "munged func name: ${fnname}_$munged, caller: $cllr\n"
	if $opt->{r};
    
    #$meth->dump if $opt->{z};
};

sub opNames {
    # given ref to opchain, prints names
    my ($opchain, $extra) = @_;
    return join ' ', map $_->name(), @$opchain unless $extra;
    return join ' ', map {$_->name(), $_->$extra()} @$opchain;
}

sub dumpchain {
    # annotates $op->dump with stuff, to stdout
    my ($opchain, @msg) = @_;
    foreach (@$opchain) {
	printf STDERR @msg;
	$_->dump;
    }
}

1;
__END__
################### ###################

=head1 NAME

Log::Log4perl::AutoCategorize - extended Log::Log4perl logging

=head1 ABSTRACT

Log::Log4perl::AutoCategorize extends Log::Log4perls (l4p) easy mode,
adding 2 main features;

  1. extended, automatic, transparent categorization capabilities
    a. logging category <- package.subroutine.loglevel.linenumber
  2. runtime information useful for:
    a. test-coverage assessment
    b. managing your logging config.
  3. Minor convenience enhancements
    a. config-load in use statement
    b. Data::Dumper of ref args

There are several more mature alternatives which you should check out
for comparison;

  #1. search for Stealth Loggers in base POD
  use Log::Log4perl qw(:easy);

  #2. new functionality, developed at approx same time as AutoCategorize
  use Log::Log4perl::Filter;

=head1 SYNOPSIS

  use Log::Log4perl::AutoCategorize
    (
     alias => 'Logger', # shorthand class-name alias
     # you can initialize in use statement
     #  1st way gives separation of code from config
     #  2nd way is good for demonstration and early development
     initfile => $filename,
     initstr => q{
         # see Log4perl docs to understand these directives
	 log4perl.rootLogger=DEBUG, A1
	 # log4perl.appender.A1=Log::Dispatch::Screen
	 log4perl.appender.A1 = Log::Dispatch::File
	 log4perl.appender.A1.filename = ./mylog
	 log4perl.appender.A1.mode = write
	 log4perl.appender.A1.layout = PatternLayout
	 log4perl.appender.A1.layout.ConversionPattern=%d %c %m%n
	 # create TEST-COVERAGE log
	 log4perl.appender.COVERAGE = Log::Dispatch::File
         log4perl.appender.COVERAGE.mode = write
	 log4perl.appender.COVERAGE.layout = org.apache.log4j.PatternLayout
	 log4perl.appender.COVERAGE.layout.ConversionPattern = (%d{HH:mm:ss.SSS}) %c: %m%n
	 # save timestamped versions, 1 per process
	 log4perl.appender.COVERAGE.filename = sub {"./test-coverage.txt.". scalar localtime}

	 # now, add the value: send the stuff written at END to it
	 log4perl.logger.Log.Log4perl.Autocategorize.END = INFO, COVERAGE
	 },
     );

  foreach (1..500) {
    Logger->warn($_);
    foo();
    A->bar();
    A::bar();
  }

  sub foo {
    foreach (1..20) {
	Logger->warn($_);
    }
  }

  package A;

  sub bar {
    my @d;
    foreach (reverse 1..10) {
	push @d, $_;
	Logger->warn("t-minus:", $_,\@d);
    }
  }


=head1 DESCRIPTION

Before diving in, a few notes:

This is not intended to document Log4perl (also l4p, abbrev for
Log::Log4perl); that documentation is a good tutorial, and is quite
thorough and complete.

In this document, I use B<Logger> as the I<official> shorthand for
Log::Log4perl::AutoCategorize, as it gets tedious and verbose to
repeat the full name.  There is module support for you to do this too;
note that its used in the example above, ie: 'alias => Logger'.  You
can alias it as you prefer: myLogger, ourLogger, or you can subclass
it.

I try to use I<call> for the act of calling a method at runtime, and
I<invocation> to refer to the source-code (ie: package,sub,line-number)
that is called.  I hope that the distinction will help to bend the
brick into a more hat-like shape.

This module requires perl 5.8, as the optimizer is unsupported in 5.6.
You can use this module IFF you uncomment the __END__ before the
optimization stuff is done (at bottom of file), but runtime costs are
considerable (40% overhead), so Im reluctant to add this as an option.
That said, l4p install scripts adjust the code to the perl version
(ex, they revert from 'our $var' syntax for 5.5.3, since its a 5.6
feature).  I would accept a patch to do similar..

=head1 AutoCategorization

The primary feature of this module is to extend Log4perls flexibility
by automatically and transparently creating logging categories for each
invocation in your application code.

use Log::Log4perl ':easy' offers a comparable, but less capable
feature; it automatically infers that $logCat = "$caller_package", and
uses that category to properly handle the message at runtime.

  package Foo;
  use Log::Log4perl(':easy');

  package Foo::Bar;
  use Log::Log4perl(':easy');


This module extends the $logCat with info thats obtained at runtime,
leveraging L4Ps filtering mechanisms by giving more detail upon which
to filter.

    $logcat = "$package.$subname.$loglevel.$linenum";

L4Ps bubble-up behavior is still in effect; if your log-config never
specifies anything beyond $package, the $logCat of each call bubbles
up thru the log-config, until it matches with your package-level
config item.

In other words: since $logCat contains more information than that
provided by :easy, your logging configuration can exersize more
control over what gets logged.

Note that you could have always used whatever categories you wanted,
see L<Log::Log4perl/"Configuration files">, you just didnt get the
help that made it easy to do so.


=head1 Test Coverage Results of your Application

When your code uses this module, the logging calls are categorized and
counted; this is reported when the program terminates.  The info is
returned in 3 chunks.

=head2 Seen: How many times each invocation was called

The %Seen hash stores and counts all invocations of all functions,
keyed by the category.  This is variously called a usage report, a
test-coverage report, a seen-report, etc.

 (15:24:24.772) Logger.END.info.106: $Seen Log Events: = [
  {
    '#log4perl.category.A.bar.debug.55' => '-400',
    '#log4perl.category.A.bar.warn.54' => 400,
    '#log4perl.category.Log.Log4perl.AutoCategorize.END.info.201' => 1,
    '#log4perl.category.main.foo.warn.44' => 200,
    '#log4perl.category.main.info.32' => 10,
    '#log4perl.category.main.warn.31' => 10
  }
 ];

Note that A.bar.debug.55 above has a negative count. This indicates
that the logging activity was suppressed by the configuration, but the
code was still reached 400 times.

Also, the keys are prefixed with '#log4perl.category.', which
simplifies cut-paste of this output into your log-config.

=head2 UnSeen: What invocations were never called

This report identifies the Logging invocations which were never called
during this run of your program.  This can be used systematically to assess 
how thoroughly you are testing your application.

 (15:24:24.772) Logger.END.info.106: $un-Seen Log Events: = [
  {
    'debug_00011' => 'main,probe.pl,52',
    'info_00010' => 'main,probe.pl,51',
  }
 ];

=head2 Category to Munged-Name

This hash identifies the map between the categories and the unique
function-name.  It is provided primarily for completeness, it may
prove useful for debugging and/or other things.

 (19:44:06.210) Log.Log4perl.AutoCategorize.END.info.308: cat2data:, {
  'A.truck.debug.63' => 'debug_00005',
  'A.truck.debug.65' => 'debug_00006',
  'A.truck.debug.66' => 'debug_1_00007',
  'A.truck.warn.62' => 'warn_00004',
  ...
  }

=head2 Assessing Test Coverage

One way to use the test coverage facility is by running your test
suite and collecting the individual coverage reports.  Since the
config-items are sorted in the report, its easy to compare 2 of them;
you can tell what parts of the system are tested by each part of the
test suite.

Log4perl can write log-files with configurable names (ex: a
timestamped name, see the L<SYNOPSIS> example above).  You can use
this facility to write separate files for each sub-test, and then
merge them (ex: `cat *.coverage-log|sort -u`), and quickly assess the
total coverage provided by the entire test suite.

=head2 Keeping your Logging Config current

Log4perl documentation speaks of the hazards/limitations of
categories; this is more critical here, because categories are highly
leveraged.  See L<Log::Log4perl/"Pitfalls with Categories"> for more
info.

This package is indisputably more vulnerable to such problems; it
exposes line numbers, which change regularly during development.  If
you use numbers, be aware that adding comments to your code will
change the category reported, rendering those log-config items
ineffective for controlling output. 

Moreover, you should recognize that as the numbers become more stable,
theyre also less valuable; by then, youve reassesed and refined your
choices wrt log-levels. (you have, yes?)

However, you can also be more disiplined (TMTOWTDI), using
config-lines with a mix of specificity: package, package.method, and
package.method.logginglevel.  Here the coverage report helps, since it
lists all executed logger-invocations, it serves as a pretty good
roadmap to your application, letting you see the entire forest through
the trees.

Also, the coverage report is formatted to be easily edited into a
informative and useful logging configuration, ie:

    1. comments/documents the 'existence' of a log-config entry
    2. doesnt create the hierarchy in the logger-config, efficient
    3. identifies all the code instrumentation available
    4. serves as cut-paste fodder for your log-configs

Bottom line: I recommend that you start your log-config file by
copying and editing the coverage report.  Just remove the quotes put
in by Data::Dumper, change '=>' to '=', remove '#' to activate lines,
and change the count to DEBUG, WARN, etc.

=head2 What %Seen cannot tell you

Because the %Seen coverage only includes the categories it sees at (a
single) runtime, it cant 'remember' the aggregate coverage from
previous runs.

The sort technique given above to assess aggregate test-coverage is
not as useful here; it sorts commented lines away from their
uncommented counterparts, but its a start. 

I may add an option to support a separate 'remembering' aggregate via
a tied variable thats initialized in a BEGIN block.  This is a distant
feature; I will spend some time with Devel::Cover to gain insight.

=head1 Filtering with Log::Log4perl::AutoCategorize

Restating in different words (at risk of redundancy), filtering with
this package uses the base behavior of bubbling up a logging event
through the config, and using generic config-items which are not
overridden by more specific items.

Using part or all of the hierarchy of categories in your config-file,
you can enable or disable logging on a class, a method in that class,
particular logging levels with that method, or line by line.

    log4perl.category.Frob = DEBUG			# 1
    log4perl.category.Frob.nicate.debug = INFO		# 2
    log4perl.category.Frob.nicate.debug.118 = DEBUG	# 3
    #log4perl.category.Frob.Vernier.twiddle.debug = DEBUG	# 4

(1) enables debug logging accross the Frob class, but then (2)
overrides that class-wide setting within the method nicate(),
suppressing debug logging (by setting the threshold to INFO).  (3)
further overrides that setting by enabling the debug statement on line
118.

=head2 Tweaking your log config

If you look carefully at the example above, (2) may be confusing; it
has 'debug = INFO', which looks like nonsense.  The 'debug' is the
log-level that the programmer wrote, it reflects his judgement as to
the nature of the message.

The '= INFO' part tells you that the config user decided to suppress
debug messages from nicate(), which were enabled class-wide by (1).
(3) restores normal behavior of debug logging, but only for 1
invocation.

Note also that (4), even if it was uncommented, would have no effect
on the logging, because its just saying that all debug() calls done by
Frob::Vernier::twiddle() are issued at their default level.  Keeping
such lines commented is good for documentation, and more efficient; it
saves Log::Log4perl both cpu and memory by not loading config-items
that arent meaningful.


=head1 Other Features

Automatic categorization, logging coverage, and fine-grained control
of logging are the primary value-added features of this wrapper
package.  Other secondary features are;

=head2 Configuration Loading

If use Log::Log4perl::AutoCategorize is given an import list which
includes initstr => q{} or initfile => $filename, the string or file
is used to initialize Log::Log4perl.  You can still use the old way,
ie $base->init().

=head2 Classname Aliasing

Because it would be inconvenient to type the full classname for every
statement, ex: Log::Log4perl::AutoCategorize->debug(), the package has
the ability to alias itself into a classname of your choice, ex:

    use Log::Log4perl::AutoCategorize ( alias => myLogger );
    myLogger->debug("ok doing it");

Because aliasing is used in optimization phase, it must be imported
via use, it cannot be deferred as in require, import.

=head2 Easy Initialization

You can initialize the base logger by any of the following;

  # as use parameters, least typing
  a. use Log::Log4perl::Autocategorize ( initstr  => $string );
  b. use Log::Log4perl::Autocategorize ( initfile => $filename );

  # assuming youve already used the package
  c. Log::Log4perl::AutoCategorize->init( $filename );
  d. Log::Log4perl::AutoCategorize->init( \$string );

  # you can cheat, and use the base class name
  e. Log::Log4perl->init( $filename );
  f. Log::Log4perl->init( \$string );

  # assuming youve aliased
  g. Logger->init( $filename );
  h. Logger->init( \$string );

  i. # no explicit initialization at all (theres a default config)

The default config writes to stdout, and includes a test-coverage
setup.  This config is used at import() time, unless a or b is
provided by you.  If you explicitly call init(), the base is
re-initialized, and relys on base behavior to work correctly.

I hope at some point to provide init_modify(), which will overlay new
configuration on existing, rather than a full reinitialization.  This
will be implemented using Log4perls (currently nonexistent)
configuration include mechanism.

=head2 Automatic Dump of structured data

If you pass in a data-ref, its rendered using Data::Dumper, making it
easy to examine the details of the runtime context.  Since the Dump is
embedded inside the logging-method, its only called when needed,
avoiding work to produce output that will just be thrown away.

=head2 SubClassing

As sayeth L<perltoot/Planning for the Future: Better Constructors>,
you make you package suitable for deriving new ones.  test
04_subclass.t verifies this, though it wasnt the 1st thing I got
working.


=head1 Module Architecture

The previous section hopefully provides sufficient motivation for why
you should use this module, this section describes how the module
works.

2 phase strategy to achieve both greater filtering capability, and
similar or better efficiency.

=head2 Original AUTOLOAD functionality

In v0.001, AUTOLOAD did the entire job itself, primarily cuz it seemed
better to write the code once, rather than 5 times (for debug, info,
warn, error, fatal).  Every time a call like Logger->warn() was
reached, AUTOLOAD would get control, and do the following:

    0. determine log-level which was called ($AUTOLOAD)
    1. used caller() to construct a category string, $logcat, dynamically.
    2. fetched the $logger singleton {$logger = get_logger($logcat)}
    3. tested if $logcat was a loggable event {$logger->is_$loglevel()}
    4. logged the message, or not, as appropriate.

Doing this repeatedly using caller() for every call is computationally
expensive for a logging subsystem. If the module is to be usable
application wide, it must be efficient.

=head2 Gaining efficiency

The canonical way to get speed from AUTOLOAD is to not call it; or
more helpfully, to create the desired subroutine so that it gets
called for all future calls to that method.  But in this case, the
decision reached in step 4 is different for every invocation, so it
cannot be reduced to a single subroutine unless that routine calls
caller(), which defeats the purpose.

The only way to get custom behavior for each invocation is to make
them each invoke a unique method name; ie to munge the method names
where they are invoked.  Once this is done, AUTOLOAD can then vivify
subroutines which 'remember' results of caller(), and the log/nolog
decision reachedd for that invocation.  Thereafter AUTOLOAD wont be
called again (for that unique method), avoiding steps 0-4 completely.

=head2 Using optimizer.pm

I use Simon Cozen''s optimizer.pm to convert the source code:

    FROM: {
	Logger->debug ("msg A");
	Logger->debug ("msg B");
    }
    TO:	{
	Logger->debug_001 ("msg A");
	Logger->debug_002 ("msg B");
	# etc...
    }

The function-munging produces a unique function name for each point in
your code where you invoke a logging method.  This allows AUTOLOAD
(which handles all these calls) to distinguish each invocation, make a
custom handler routine for it.  Once the custom handler is added into
the symbol table, it is called later without any overhead.

=head2 How optimizer munges

Your code, 'use optimizer => sub yourfunc;' operates at compile time,
letting you search the opcodes for specific op-chains.  Once youve got
the right opchain, you can do the opcode surgery.

For example, we must recognize this opcode chain;

`perl -MO=Concise,-exec -e 'Logger->info_00010(2,"args")`;
  t76     <0> pushmark s
  t77     <$> const(PV "Logger") sM/BARE
  t78     <$> const(IV 2) sM
  t79     <$> const(PV "args") sM
  t7a     <$> method_named(PVIV "info_00010") 
  t7b     <1> entersub[t23] vKS/TARG

Our criteria is (pushmark, const with PV="Logger", ..., method_named
with PVIV=~$namePatt).  We also recognize the opcodes that build
arguments on the stack, so we can find the balanced method_named
opcode.  Finally, we insure that the method name being invoked is one
of the allowed ones.

=head2 Caveat: you must use a specific coding style

To match the above criteria, your code must use *ONLY the 1st* of
these 3 different coding styles;

  IE: Logger->debug("foo");
  NOT: $logger->debug("foo");
  NOR: Logger::debug("foo");

This form provides the package name as a bareword (t77), which allows
a rather strict (safe?) test; we dont want to stomp in others\' 
namespaces (except for the explicit takeover of the $Alias package)

The 2nd form is not safely detectable at compile time, since $logger
type cannot be absolutely known, and we try not to do risky surgery.
For example

    # never inadvertently do this -
    $logger->warn if ref $logger eq 'FlareGun';

The 3rd form is doable, but clutters the code which does $Alias
recognition, for little syntactic gain.  Currently, you wont even get
a warning you if you use this construct.

=head2 lightweight customized subroutines

Given that all the customized anonymous subroutines are instantiated
as either sub{} or sub{ logit("$cat") }; they all invoke a common
logit() routine that does the real work.

The asubs are trivial wrappers, with the category value stringified
and held in code, and passed into logit() when called.  This doesnt
shrink the number of symbol table entries, but it minimizes the size
of the CVs hanging there.

To save more space, a common do_nothing() function could be used
instead of the current invocation counting do-nothing, at the cost of
losing test-coverage info.

=head2 AUTOLOAD revisited

Once method munging was in place, $AUTOLOAD would contain, for
example; not "debug", but "debug_00011".  Now that each invocation is
unique, the distinctions can be computed once and remembered; ie they
can be reduced to a dynamically created sub, and added to the symbol
table.

IOW, these changes were made to AUTOLOAD:

    4. computes the category using caller()
    5. determines whether the base logger would send the message.
    6. instantiates an anonymous subroutine reflecting 5.
    7. adds the sub to the symbol table, with the munged method name.

At runtime, invocations like Logger->warn_$UIID() are called, and
dispatched to AUTOLOAD.  Once the munged function is in the symbol table,
AUTOLOAD is never called again for this invocation.

=head1 Benchmarking

Ive done one Benchmark.pm based test (tshort.pl) which doesnt seem
quite right.  The simpler approach of using 2 similar test-scripts
shows more convincing results.

    $jimc@harpo logger]$ time t1.pl -n > /dev/null

    real	1m30.860s
    user	1m28.246s
    sys	0m2.002s

    $jimc@harpo logger]$ time t2.pl

    ... debug output snipped ...

    real	0m52.229s
    user	0m49.363s
    sys	0m1.625s

This last benchmark implements above test in pure Log::Log4perl code.
As you can see, this package is competetive with Log::Log4perl itself,
at least when analogous features are used (that use is a bit forced,
you wouldnt NEED to do so all the time).

Nonetheless, its conceivable to get better than native performance if
internal short-circuits can be taken.

Please run perftests/timeit.sh and send me email, particularly if you
get wildly different results.

=head1 CAVEAT (restated)

This package expects you to use Logger->warn() style of coding,
$logger->warn() will not work, unless 'my Dog $spot' syntax can make
real guarantees.  This is because the type of $logger cannot be known
at compile time, and its too risky to munge everything that looks like
$flaregun->warn().

Even if it were possible, it would probably be bad to mix lexical code
customization with objects and their attributes.  

=head1 BUGS

The category extension can be abused; you can independently suppress
warn() while elevating debug(), leading to surprises in what output
goes where.  But this can be used sanely, so I dont consider worth
disabling.  I could be convinced to optionally report it; as ever, a
patch is a compelling argument.

The %Seen report can never contain the categories of unexecuted
functions, since the catalog entry is created by AUTOLOAD, which is
never run if the function isnt executed.  Ive thought of a few
"solutions", but theyre all insane ..

    1. remember functions during munging, call them once in CHECK{}.
       Wont work; would get useless caller() info.

    2. Tie %Total_Invocations to a DBM file, update in the END.  This
       is seductive; but it will have trouble forgetting invocations
       that have been removed from the code, or in the case of
       line-numbered log-specs, been moved by a mere comment. Note
       though that reset control could be added to API.

Debugging your code can be problematic; it seems to undo emacs
keybindings; a ctrl-P (previous command) will send it into a
cpu-sucking vortex.  This is the reason for the many debugging flags.

=head1 TODO

=head2 better interoperation with l4p easy_init()

Test t/09_coexist_easy.t demonstrates use of both l4p :easy, and l4pa,
but it writes 2 separate logfiles.  Ive not tried recently to write to
a single logfile.

=head2 devise good way to limit the deep logging of ref-data

AutoCategorize uses Data::Dumper to render the structure of complex
data arguments.  It would be nice to selectively suppress or modify
the Dumper output, and/or print just the strings.

But to do this via the log-config, the config-item syntax must be
extended; either by adding new attributes, or by allowing new values.
Either approach compromises interoperability with log4java config
files. These possible config-schemes should therefore be considered
speculative;

    # using extra param
    log4perl.category.TestUtils.testcase_applies = DEBUG, 0

The 2nd parameter would control whether Data::Dumper was invoked, in
this case they would not be.  This scheme has advantage of having a
wide API; hashrefs etc can (in principle - and subject to reality
check by Gurus) be given as parameters.

Other schemes are also possible;

    # an additional '.detail' attribute
    log4perl.category.A.foo.debug.detail = 0

    # new .*.detail attribute, with (needed) wild-card
    log4perl.category.A.foo.debug.*.detail = 0
    # limit the depth of dumper (one way, others possible)
    log4perl.category.A.foo.debug.*.detail = -20
    # alternative values
    log4perl.category.A.foo.debug.*.detail = YAML
    log4perl.category.A.foo.debug.*.detail = sub { YAML->dump }

    # alternate (currently unused) directives
    log4perl.autocat.A.foo.debug.*.detail = sub { YAML->dump }

=head2 allow use of alternates to Data::Dumper

YAML comes to mind, as does Data::Dumper::Sortkeys = sub {...}; I took
a quick swipe at using YAML::Dump (-dy debug option to
perftests/tdebug.pl), but its not yielding expected results.

Its also possible to get various object and context sensitive
serializations, esp if combined with extra params above.

=head2 devise extended method-name space

This package is hardcoded to only munge invocations to one of (debug,
info, notice, warn, error), non matching are left unaltered, because
some calls should delegate thru to Log::Log4perl, and we should be
conservative about what gets munged.

But the point is this: A whole panoply of method suffixes are
possible; (ex: /(info|debug)_.*/), a careful use of this method
namespace could be used to specify many subtle (or not so subtle)
variations in behavior (ex: debug_dump, warn_nodump, error_iftrue,
info_iffalse).

=head2 short-circuit internal checks

Its likely that several checks and/or dereferences internal to
Log::Log4perl can be eliminated once its determined (at 1st
invocation) that a log event should actually do something.  
This is however risky; too much deep coupling.

=head2 init and watch

Log4perl has ability to watch the logfile for changes, and change its
operation accordingly.  This package must hook into that notification,
and use it to undefine the appropriate symbol-table entry, thus
allowing the AUTOLOAD mechanism to re-vivify it according to the new
configuration.  Obviously it would be nice to do this only to the
parts of the config that are different.

This feature will use the %cat2data mapping built at 1st invocation
to allow config changes to be mapped back to the munged method-name
that resolved to that category in the 1st place.


=head2 context sensitive logging

NDC and MDC are tantalizing features, they appear to hold some promise
for conditional logging; ie once an application error is detected, a
full dump of the NDC or MDC is logged.  Alternatively, once an all-ok
is determined, a stack of NDC logs can be discarded, and a summary
message issued.

=head2 Remembering the AutoCat-alog

See also L</BUGS/Seen.2>.  While it borders on the baroque, its
possible to tie %TotalInvocations to a DBM or Storable file, whose
name is controlled by your log-config.  Then you could use Log4perl''s
logitem = sub{} to syncronize the filename to your VERSION; either
$package::VERSION, a complete CVS Revision, or to your application
Version.  Interestingly, this could give some insight into longer-term
code evolution.

=head2 Improve the documentation

In an effort to provide adequate motivation and explanation, Ive
gotten long-winded, repeating ideas several times.  Im now too close
to this to judge their clarity adequately, I welcome feedback and
suggestions wrt what is tedious or unclear.

To this end, Im including 2 versions of a lightning (5 min) talk I
gave on this module at YAPC::NA in Boca.  The longer version I tested
on several willing victims (thx guys), and the short version I
actually gave based upon their valuable comments.  If these are
helpful, please let me know how they could be folded into this
document to improve clarity and/or remove redundancy.

=head2 Provide patches to optimizer, B-Generate

To use this package on perl 5.8.1+ you need to patch both optimizer,
B-Generate for updated internals.  I have patches that worked for me
on both 5.8.0 and 5.8.1, but Arthur hasnt commented on them.

I recently discovered that B::Generate is supposed to work as far back
as 5.5.62, and I cant build it against 5.6.2-pre.  I will probably put
the patches on CPAN, but email me directly if you dont find them, or
if they dont work for you.

=head1 More TODO

    find and kill bugs..
    write more test cases..
    optimize more
    integrate more fully with Log::Log4perl
    revisit perftests
    help/feedback is welcome.

=head1 CREDITS

Mike Schilli and Kevin Goess for L<Log::Log4perl>, and for reviewing
my docs and code, and pointing out features I had not fully
understood.

Simon Cozens, Arthur Bergman for L<optimizer>, L<B::Generate>.  The
extra features this module provides would not be practical w/o the
deep magic in those packages; Im just repeating incantations.

=head1 AUTHOR

    Jim Cromie <jcromie@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 Jim Cromie

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

(I always wanted to write that ;-)

=cut

###################################
