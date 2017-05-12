#################################################################
#
#   Log::Localized - Dispatch log messages depending on local verbosity
#
#   $Id: Localized.pm,v 1.13 2006/05/23 14:03:18 erwan Exp $
#
#   050909 erwan Created 
#   060523 erwan Adapt to api change in File::HomeDir
#

package Log::Localized;

use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Carp qw(confess carp);
use Config::Tiny;
use Log::Dispatch;
use Log::Dispatch::Config;
use Log::Dispatch::Screen;
use File::Spec;
use File::HomeDir;

# TODO: load all Dispatcher plugins? is it necessary?

our $VERSION = '0.05';

#----------------------------------------------------------------
#
#   configuration parameters. see BEGIN for default values.
#   may be replaced by the Log::Localized::* rules of the rules file.
#
#----------------------------------------------------------------

my @SEARCH_PATH;        # an array of paths at which to search for verbosity or dispatcher file
my $FILE_RULES;         # name of file containing verbosity rules
my $FILE_DISPATCHERS;   # name of file containing dispatcher config
my $ENV_VERBOSITY;      # name of the environment variable containing the global verbosity
my $PROGRAM;            # name of currently executing program
my $LOG_FORMAT;         # macro for preformatting log messages before dispatching them
my $LLOG_EXPORT_NAME;   # name under which llog should be exported

#----------------------------------------------------------------
#
#   other parameters
#
#----------------------------------------------------------------

# is logging on?
my $LOGGING_ON;

# local verbosity level
use vars qw($VERBOSITY);

# last message level
use vars qw($LEVEL);

# verbosity per namespace and function
my %VERBOSITY_RULES;

# the Log::Dispatch handling all logging
my $DISPATCHER;

#----------------------------------------------------------------
#
#   import - disable or export 'llog' function, eventually under a different name
#

sub import {
    shift;
    my %args = @_;
    my $pkg = caller(0);

    # switch logging on or off 
    if (defined $args{log}) {
	if ($args{log} =~ /^[01]$/) {
	    $LOGGING_ON = $args{log};
	} else {
	    confess "ERROR: log => ".$args{log}." is not a valid value. use 0 or 1.\n";
	}
    }

    # load rules file via 'use'
    if (defined $args{rules}) {
	# merge import rules with those from file (if any)
	my $config = Config::Tiny->read_string($args{rules});
	_load_verbosity_rules($config);
	_init_dispatchers();
    }

    # rename 
    my $export = $LLOG_EXPORT_NAME;
    if (exists $args{rename}) {
	$export = $args{rename};
    }

    # check ENV_VERBOSITY here too. people may use Log::Localized, then call import alone again later...
    if (exists $ENV{$ENV_VERBOSITY}) {
        $LOGGING_ON = 1;
    }

    # is logging turned on?
    if ($LOGGING_ON) {
	# export log function to calling module 
	no strict 'refs';
	*{"${pkg}::$export"} = \&llog;

    } else {
	# disable logging in calling module
	no strict 'refs';
	*{"${pkg}::$export"} = sub {};
    }
}

#################################################################
#
#
#   TEST UTILITIES - functions for testing purpose only
#
#
#################################################################

sub _test_verbosity_rules { return %VERBOSITY_RULES; };
sub _test_program { return $PROGRAM; };

#################################################################
#
#
#   RULES FILE PARSING AND INITIALISATION
#
#
#################################################################

#----------------------------------------------------------------
#
#   _get_rules - try to find a rules file in the search path
#

sub _get_rules {
    foreach my $path (@SEARCH_PATH) {
	my $file = File::Spec->catfile($path,$FILE_RULES);
	if (-f $file) {
	    my $config = Config::Tiny->read($file);
	    llog(1,"loaded verbosity rules from file [$file]");
	    return $config;
        }
    }
    llog(1,"found no verbosity rules file in search path [".join(",",@SEARCH_PATH)."]");
    return undef;
}

#----------------------------------------------------------------
#
#   _load_verbosity_rules - parse Log::Localized rules and configuration
#

sub _load_verbosity_rules {
    my $config = shift;

    if (defined $config) {

	# found rules file => logging is on
	$LOGGING_ON = 1;

	my $reload = 0;
	
	# be sure to load default rules first
	if (exists $config->{'_'}) {
	    $reload = _load_config_block($config->{'_'});
	}

	# then, rules specific to the running program, if any
	if (exists $config->{$PROGRAM}) {
	    $reload = _load_config_block($config->{$PROGRAM});
	}
	
        # reload rules if a Log::Localized::use_rules was set
        if ($reload) {
	    llog(1,"reloading rules");
	    %VERBOSITY_RULES = ();
	    _load_verbosity_rules(_get_rules());
        }
    }

    # is global logging on? (may have been redefined by rules options)
    if (defined $ENV{$ENV_VERBOSITY}) {
        $LOGGING_ON = 1;
    }
}

#----------------------------------------------------------------
#
#   _load_config_block - load rules from a block in the Tiny::Config object
#

sub _load_config_block {
    my $block = shift;

    # true if need to reload rules, ie if 'use_rules' option used
    my $reload = 0;

    # define how to parse Log::Localized options
    my $OPTIONS = {
	# option_name => closure loading option
	search_path      => sub { @SEARCH_PATH = _get_search_path($_[0]); },
	use_rules        => sub { $reload = 1; $FILE_RULES = shift; },
	rename           => sub { $LLOG_EXPORT_NAME = shift; },
	dispatchers      => sub { $FILE_DISPATCHERS = shift; },
	format           => sub { $LOG_FORMAT = shift; },
        global_verbosity => sub { $ENV_VERBOSITY = shift; },
    };
    
    if (ref $block eq 'HASH') {
	foreach my $path (keys %$block) {			
	    my $value = $block->{$path};			
	    
	    # Log::Localized's own configuration  
	    if ($path =~ /^log::localized::(.+)$/i) {
		my $option = $1;
		$option = lc $option;
		
		# is this a known option? otherwise assume it's a verbosity rule
		if (exists $OPTIONS->{$option}) {
		    llog(1,"setting option [$option]"); 
		    my $fnc = $OPTIONS->{$option};
		    &$fnc($value);
		    next;
		}
	    }

	    # verbosity rules
	    if ($value !~ /^\d+$/) {
		carp "WARNING: invalid verbosity rules for [$path]. [$value] should be an integer. Ignoring it.";
	    } else {
		if ($path !~ /::/) {
		    # assuming it's a function name in main::
		    $VERBOSITY_RULES{"main::${path}"} = $value;
                    llog(1,"loading rule [main::${path} = $value]");
		} else {
		    # rem: implies that 'A::B' will be mistaken for a method called 'B' in module 'A'
		    # while 'A::B::' will be rightly understood as *all methods* in A::B
		    $VERBOSITY_RULES{$path} = $value;
                    llog(1,"loading rule [${path} = $value]");
		}
	    }
	}
    }	

    return $reload;
}

#----------------------------------------------------------------
#
#   _init_dispatchers - create Log::Dispatch dispatchers for Log::Localized
#

sub _init_dispatchers {

    if (defined $FILE_DISPATCHERS) {
	foreach my $path (@SEARCH_PATH) {
	    my $file = File::Spec->catfile($path,$FILE_DISPATCHERS);
	    if (-f $file) {
		# TODO: eventually use configure_and_watch here...
		Log::Dispatch::Config->configure($file);	      
		$DISPATCHER = Log::Dispatch::Config->instance;	    
		llog(1,"loaded dispatchers from file [$file]");
	        return;
	    }
	}
	carp "WARNING: no dispatcher definition file [$FILE_DISPATCHERS] found in [".join(",",@SEARCH_PATH)."]. using defaults.";
    }

    # by default, dispatch to stdout and add a newline
    $DISPATCHER = Log::Dispatch->new;
    $DISPATCHER->add(Log::Dispatch::Screen->new(name => 'screen',
						min_level => 'debug',
						stderr => 1,
						callbacks => sub {
						    my %hash = @_;
						    return $hash{message}."\n";
						},
						));
    llog(1,"using default dispatcher to stdout");
}

#----------------------------------------------------------------
#
#   _get_search_path - do keyword substitutiob in search path
#

sub _get_search_path {
    my $strpath = shift; # path in usual unix style path1:path2:...
    my $home = home() or confess "ERROR: your system does not seem to support home directories";
    my @search_path = ();
    foreach my $path (split(":",$strpath)) {
	$path =~ s/\~/$home/g;

	# look for environment variables
	my %pathenv;
	while ($path =~ /\$([^\/\:]+)/gm) {
	    $pathenv{$1} = 1;
	}

	# and substitute them
	foreach my $env (keys %pathenv) {
	    if (exists $ENV{$env}) {
		my $value = $ENV{$env};
		$path =~ s/\$$env/$ENV{$env}/g;
	    }
	}

	push @search_path, $path;

    }

    return @search_path;
}

#################################################################
#
#
#   LOGGING FUNCTIONS
#
#
#################################################################

#----------------------------------------------------------------
#
#   _get_local_verbosity - find out the local verbosity in the code currently executed
#

sub _get_local_verbosity {
    my $pkg = (caller(1))[0];
    my $fnc = (caller(2))[3] || ""; 
    
    # _get_local_verbosity logs itself. $log is required to avoid infinite recursion, 
    my $log = 1;
    $log = 0 if ($fnc eq "Log::Localized::_get_local_verbosity");
    
    llog(5,"the function calling llog() is [$fnc] in package [$pkg]") if $log;

    #--------------------------------------------------------------
    #
    #   1. check ENV_LOG_VERBOSITY
    #

    if (defined $ENV{$ENV_VERBOSITY}) {
	my $v = $ENV{$ENV_VERBOSITY};
	if ($v !~ /^\d+$/) {
	    carp "WARNING: environment variable $ENV_VERBOSITY must be an integer. ignoring it.";
	} else {
	    llog(5,"local verbosity is [$v]. (set by $ENV_VERBOSITY)") if $log;
	    return $v;
	}
    }	
    
    #--------------------------------------------------------------
    #
    #   2. check verbosity rules
    #

    my $v;
    if (exists $VERBOSITY_RULES{$fnc}) {
	$v = $VERBOSITY_RULES{$fnc};
	llog(5,"local verbosity is [$v]. (set by verbosity rule file, rule [$fnc])") if $log;
    } elsif (exists $VERBOSITY_RULES{$pkg."::*"}) {
	$v = $VERBOSITY_RULES{$pkg."::*"};
	llog(5,"local verbosity is [$v]. (set by verbosity rule file, rule [$pkg\::*])") if $log;
    } else {
	# lookup parent packages to see if any in rules file
	my @names = split(/::/, $pkg);
	while (@names) {
	    my $subpkg = join("::",@names)."::";
	    if (exists $VERBOSITY_RULES{$subpkg}) {
		$v = $VERBOSITY_RULES{$subpkg};
		llog(5,"local verbosity is [$v]. (set by verbosity rule file, rule [".$subpkg."])") if $log;
		last;
	    }
	    pop @names;
	}
    }
    
    if (defined $v) {
	return $v;
    }
    
    #--------------------------------------------------------------
    #
    #   3. check local $VERBOSITY
    #

    if (defined $VERBOSITY) {
	if ($VERBOSITY !~ /^\d+$/) {
	    confess "BUG: some code has set VERBOSITY to a non integer value [$VERBOSITY].\n";
	}
	llog(5,"local verbosity is [$VERBOSITY]. (set locally in calling code)") if $log;
	return $VERBOSITY;
    }
    
    # do not log anything by default
    return -1;
}

#----------------------------------------------------------------
#
#   llog - display a debug message if local verbosity is high enough
#

# a buffer in which llog stores messages until dispatchers are defined
my @LOG_QUEUE;

sub llog {
    my($level,$msg) = @_;

    # check out arguments
    confess "BUG: llog() expects 2 arguments, but got [".Dumper(@_)."]" 
	unless (@_ == 2);
    
    confess "BUG: llog() expects either a string or a code reference as second argument, but got [".ref($msg)."] [".Dumper($msg)."]" 
	unless (defined $msg && (ref($msg) eq "" || ref($msg) eq "CODE"));

    # if dispatchers not yet available
    if (!defined $DISPATCHER) {
	push @LOG_QUEUE,$level,$msg;
	return;
    }

    # now dispatchers are defined. before proceeding, can we empty the queue?
    if (scalar @LOG_QUEUE && (caller(1))[3] ne 'llog') {
	while (scalar(@LOG_QUEUE)) {
	    my $lvl = shift @LOG_QUEUE;
	    my $msg = shift @LOG_QUEUE;
	    llog($lvl,$msg);
	}
    }

    # should we log this message according to current verbosity?
    if ($level <= _get_local_verbosity()) {

	$LEVEL = $level ;
	
	# did we get a message, or a reference to some code generating this message?
	if (ref($msg) eq "CODE") { 
	    # TODO: run $msg() in eval and die if crashed
	    my $txt = &$msg($level);
	    confess "BUG: llog() was passed a function reference that did not return a valid string [".Dumper($txt)."]"
		unless (defined $txt && ref($txt) eq "");
	    $msg = "$txt";
	}
	
	# format message to display
	my($pkg,$line) = (caller(0))[0,2];
	my $fnc = (caller(1))[3] || "main";
	$fnc =~ s/.+:://g;

	my $txt = $LOG_FORMAT;
	$txt =~ s/\%PKG/$pkg/g;
	$txt =~ s/\%FNC/$fnc/g;
	$txt =~ s/\%LIN/$line/g;
	$txt =~ s/\%LVL/$level/g;
	$txt =~ s/\%MSG/$msg/g;
	
	$DISPATCHER->log(level => 'info', message => $txt);
    }
}
    
#################################################################
#
#
#   BEGIN TIME
#
#
#################################################################

# This BEGIN block executes before import(). 
# Many globals have to be initialized here...

BEGIN {

    # default settings
    @SEARCH_PATH      = _get_search_path(".:~:/");
    $FILE_RULES       = 'verbosity.conf';
    $LOG_FORMAT       = '# [%PKG::%FNC() l.%LIN] [LEVEL %LVL]: %MSG';
    $LLOG_EXPORT_NAME = "llog";
    $VERBOSITY        = 0;
    $ENV_VERBOSITY    = 'LOG_LOCALIZED_VERBOSITY';

    # figure out running program's name
    $PROGRAM = $0;
    $PROGRAM =~ s/(.*\/)//g;
    
    if (!defined $PROGRAM) {
	confess "ERROR: failed to parse name of running program out of [$0]";
    }

    llog(2,"running program is [$PROGRAM]");

    # set up everything
    _load_verbosity_rules(_get_rules());
    _init_dispatchers();
}

1;

__END__

=head1 NAME

Log::Localized - Localize your logging

=head1 SYNOPSIS

What you most probably want to do is something like:

    package Foo;
    use Log::Localized; 
    
    sub bar {
        # this message will be displayed if method bar's verbosity is >= 1
        llog(1,"running bar()");
    }

    # this message will be displayed if package Foo's verbosity is >= 3
    llog(3,"loaded package Foo");

Then paste the following local verbosity rules in a file called 'verbosity.conf',
in the same directory as your program:

    # log everything from wherever inside Foo and its subclasses, up to level 3
    Foo:: = 3
    # except for function Foo::foo who shall have verbosity 0
    Foo::bar = 0

=head1 SYNOPSIS - ADVANCED

In a program accepting command line arguments, you may want to do:

    use Getopt::Long;
    use Log::Localized log => 1;

    GetOptions("verbose|v+" => sub { $Log::Localized::VERBOSITY++; } );

    llog(1,"you used -v");
    llog(2,"you used -v -v");

You may alter local verbosity from within the running code:

    package Foo;
    use Log::Localized log => 1;

    # verbosity level is 0 by default

    {
        # set verbosity locally in this block
        local $Log::Debug::VERBOSITY = 5;  
        llog(5,"this will be logged");
    }

    debug(5,"but this won't");

If you want to import 'llog' under another name in the calling module:

    package Foo;
    use Log::Localized rename => "my_log";
    
    # call Log::Localized::llog()
    my_log(1,"renamed llog()");

See the examples directory in the module distribution for more real life examples.

=head1 DESCRIPTION

Log::Localized provides you with an interface for defining dynamically
exactly which part of your code should log messages and with which verbosity.

Log::Localized addresses one issue of traditional logging: in very large
systems, a slight increase in logging verbosity usually generates
insane amounts of logs. Hence the need of being able
to turn on verbosity selectively in some areas of code only, 
in a I<localized> way.

Log::Localized is based on the concept of local verbosity. 
Each package and each function in a package has its own local verbosity, 
set to 0 by default. With Log::Localized you can change the local verbosity
in just a function, just a package or just a class hierarchy via a so called
verbosity rule. Verbosity rules are passed to Log::Localized either via
a configuration file or via an import parameter.
By changing verbosity rules according to the needs of the moment,
you can alter your program's logging flow in a very 
fine-grained way, and get logs from only the code areas you are interested in.

Log::Localized comes with default settings that make it 
usable 'out of the box', but its configuration options 
will let you redefine pretty much everything in its behavior.

The actual logging in Log::Localized is handled by Log::Dispatch.

=head1 DEFAULT SETTINGS

=over 4

=item B<DEFAULT VERBOSITY> The local verbosity is everywhere 0 by default.

=item B<DEFAULT DISPATCHER> Log::Localized dispatches its log to STDOUT by default and
with no Log::Dispatch preformatting of the log messages. You can change the default
dispatcher with the option I<Log::Localized::dispatchers>.

=item B<DEFAULT SEARCH PATH> The default search path in which Log::Localized will search
for verbosity rules files or dispatcher config files is (in this order) the local
directory, the user's home directory and the root directory (to enable the use
of absolute paths in options). The default search path can be overriden with
the I<Log::Localized::search_path> option.

=item B<DEFAULT VERBOSITY RULES FILE NAME> By default, the verbosity rules file 
should be called 'verbosity.conf'. This name can be changed with the option
I<Log::Localized::use_rules>.

=item B<DEFAULT LOG FUNCTION NAME> Log::Localized's logging function is by
default exported under the name I<llog>, but this can be changed with the
option I<Log::Localized::rename> or via the import parameter I<rename>.

=item B<DEFAULT GLOBAL VERBOSITY ENVIRONMENT VARIABLE NAME> The environment
variable setting the global verbosity level is by default 'LOG_LOCALIZED_VERBOSITY'.
This can be changed with the option I<Log::Localized::global_verbosity>.

=item B<DEFAULT FORMATTING> Log::Localized pre-formats log messages by default. 
The message 'whatever' coming from function I<test> in module I<Foo::Bar> and logged
at line 25 with level 2 will be logged as 
'# [Foo::Bar::test() l.25] [LEVEL 2]: whatever'. 
This default pre-formatting can be changed with the I<Log:Localized::format> option.

=back

=head1 CONFIGURATION

Log::Localized provides 4 mechanisms to affect local verbosity. They are, in
order of precedence:

=head2 ENVIRONMENT VARIABLE

If the environment variable LOG_LOCALIZED_VERBOSITY is set, logging is turned on and
Log::Localized will log everywhere in the code to the level of verbosity set in 
LOG_LOCALIZED_VERBOSITY. LOG_LOCALIZED_VERBOSITY's value must be a positive integer.
This overrides even the verbosity level eventually set vith verbosity rules. 
Note that the name of this environment variable can be changed vith the appropriate option.

=head2 VERBOSITY RULES VIA IMPORT PARAMETERS

Verbosity rules can be loaded at 'use' time via the import parameter 'rules'.
If Log::Localized is passed rules in that way, those rules will be merged 
with the rules eventually loaded from a rules file at compile time, 
and logging is turned on.

=head2 VERBOSITY RULES IN A FILE

If at compilation time there exists a file called 'verbosity.conf' in the search path, the rules
it contains are loaded and logging is turned on.
Note that you can modify both the default search path and rules file name with
the appropriate options.

=head2 LOCAL VERBOSITY

You can also set verbosity locally in the code, by locally setting the class 
variable $Log::Localized::VERBOSITY. See the examples in SYNOPSIS. Verbosity 
set in this way will be overriden by any verbosity defined via the environment 
variable or via rules.

=head1 VERBOSITY RULES

Verbosity rules follow the Tiny::Config syntax. Read its pod before continuing.

Below is an example of verbosity rules:

    # default block
    main:: = 4
    Foo::* = 3

    # additional rules specific to program 'test.pl'
    [test.pl]
    main:: = 0
    Foo::bar = 0

Those rules read like this: set local verbosity to 4 everywhere in package 'main'
and all subpackages of package 'main'. Set local verbosity everywhere in package
'Foo' to 3. But if the running program is 'test.pl', use the same rules, except that
local verbosity should be set to 0
everywhere in package 'main' and all its subpackages, and verbosity should be set to 0 for
function I<bar> in package 'Foo'.

=head2 CONFIG BLOCKS

See Config::Tiny. The default heading block contains default verbosity rules that
apply to all programs. Following configuration blocks are named with, in brackets,
the name of a program to which the block's rules apply. Rules in a named block
apply only to the program having the same name, and will override any default
rules with similar I<keys>. 

=head2 VERBOSITY RULES

A verbosity rule is a key-value pair of the form 'key = value', where
I<value> must be an integer. Those pairs can have one of the following syntaxes:

=over 4

=item B<namespace:: = value> where namespace is a Perl namespace, such as 'main' or 'Foo::Bar'. 
This rule reads 'set local verbosity to I<value> everywhere in package I<namespace> and all its sub-packages'.
Everywhere means in all functions, blocks, methods...

=item B<namespace::* = value> reads 'set local verbosity to I<value> everywhere in package I<namespace> (but 
not in its sub-packages)'.

=item B<namespace::function = value> reads 'set local verbosity to I<value> in function I<function>
from package I<namespace>'. 

=item B<function = value> is the same as 'main::function = value'.

=back

See 'LOGGING ALGORITHM' for details about rule precedence.

=head2 LOG::LOCALIZED OPTIONS

When feeding verbosity rules to Log::Localized via a rules file or
via the import parameter 'rules', you can alter the default settings 
of Log::Localized by declaring some of the following special rules:

=over 4

=item B<Log::Localized::rename = $name> instructs Log::Localized to export I<llog>
under the name I<$name>.

=item B<Log::Localized::dispatchers = $file> instructs Log::Localized to use the
dispatchers defined in the Log::Dispatch::Config file called I<$file> located in the
search path. Those dispatchers replace Log::Localized's default dispatcher (ie STDOUT).

=item B<Log::Localized::format = $format> instructs Log::Localized to pre-format
log messages according to the macro in I<$format>. The default format macro is
'# [%PKG::%FNC() l.%LIN] [LEVEL %LVL]: %MSG'. %MSG is replaced by the log message,
%FNC by the name of the function calling I<llog> and %PKG by the name of this function's package,
%LIN by the line code number where I<llog> is called and %LVL with the level of the
message passed to I<llog>. The I<$format> string can be any string containing some
of these 5 keywords.

=item B<Log::Localized::global_verbosity = $name> instructs Log::Localized to use I<$name>
as the name of the global verbosity environment variable.

=item B<Log::Localized::use_rules = $rules> indicates the name of a verbosity rules file
from which all rules should be reloaded. The I<use_rule> option makes that all rules
loaded so far are droped and that new rules are searched in a file called I<$rules>
located in the search path. This option allows you to change the default name for 
rules files ('verbosity.conf'). You may want to combine it with the I<search_path> option
to specify the directory in which the new rules file is located.

=item B<Log::Localized::search_path = $pathlist> specifies the search path in which 
to search for the I<use_rules> and I<dispatchers> files. I<$pathlist> is a 
traditional UNIX style search path made of a colon separated list of paths 
(ex: "~/config/:/opt/log/:$SYSTEM_ROOT/conf/"). Log::Localized will substitute any
occurence of '~' with the path of the current user's home directory (see File::HomeDir),
and any name starting with a dollar sign by the content of the environment variable
having the same name, if this variable exists. If the variable does not exist, the path
is left unchanged.

=back

=head1 LOGGING ALGORITHM

Upon calling 'llog($level,$message)', I<llog> does the following to find out the local
verbosity. 

If the global verbosity environment variable is set, its value is used as the local
verbosity.

Otherwise, I<llog> identifies the calling function and its module and checks whether
there exists a rule with the key 'module::function'. If not it searches for a rule with
the key 'module::*'. If not, it searches for a rule with the key 'module::', then
with keys corresponding to parent packages of 'module'. For example, if module is
'Foo::Bar::Naph', the following keys will be successively searched for: 
'Foo::Bar:Naph::', 'Foo::Bar::' then 'Foo::'. This explain the 'package and all subpackages'
mechanism named previously.

Finally, if no matching verbosity rule was found, I<llog> uses the value of the
class variable $Log::Localized::VERBOSITY, defaulting to 0.

If the message level is less or equal to the local verbosity, I<llog> will
log the message. 

In that case, if the message was a closure, I<llog> executes it and takes its 
result as the message. I<llog> pre-formats the message, then dispatch it to its Log::Dispatch object.

=head1 IMPORT PARAMETERS

=over 4

=item "B<rename> => $name" exports I<llog> into the calling module
under the name I<$name>. 

=item "B<rules> => $rules" lets you inject verbosity rules into Log::Localized.
The syntax of I<$rules> is the same as for the verbosity rules file. This is
particularly usefull for passing configuration options to Log::Localized. 
Note though that option changes will apply globally to all modules using Log::Localized,
and not only to the one calling Log::Localized with the import parameter 'rules'.
Example:
  
    use Log::Localized rules => "Log::Localized::search_path = / \n".
                                "Log::Localized::dispatchers = /opt/conf/dispatch.conf \n".
                                "Log::Localized::use_rules = /opt/conf/rules.conf \n";

=item "B<log> => [0|1]" turns logging on or off. I<llog> is exported into the calling module
only if logging is turned on. Logging is turned on if a rule verbosity
file was found at compilation time or passed via the 'rules' parameter, or if the global verbosity environment
variable is defined upon importing. If neither exists, but you still want to
log, you have to use the 'log' parameter with the value 0 (off) or 1 (on):

    use Log::Localized log => 1;

=back 
    
=head1 EXPORTED FUNCTIONS

=over 4

=item B<llog>($level,$message)

Where I<$level> is an integer, and I<$message> is either a string or 
a reference to a function that returns a string.

I<llog> dispatches the message I<$message> if I<$level> is inferior or equal to 
the local verbosity in the code where I<llog> is called. I<llog> has no 
return value.

See 'LOGGING ALGORITHM' for details on how I<llog> works.

By convention, messages with a I<$level> of 0 are always logged (if logging is on), since the
default local verbosity is 0 too.

If I<$message> is a function reference instead of a string, this function is 
executed and the string it returns is used as the log message. Note that
the function is executed only if the message level is <= to the local verbosity.
Indeed, a call like:

    llog(4,"content of this hugely complex object: ".Dumper($obj));

will slow things down in code where speed matters, 
since it executes I<Dumper> even when the local verbosity is lower than 4. 
If you want I<Dumper> to execute only when the message would actually be logged, wrap it in an
anonymous function:

    llog(4, sub { "content of this hugely complex object: ".Dumper($obj); } );

=back

=head1 CLASS VARIABLES

=over 4

=item B<$Log::Localized::VERBOSITY>

See 'LOGGING ALGORITHM' for details and 'SYNOPSIS' for examples.

=item B<$Log::Localized::LEVEL>

Contains the level of the message last received by I<llog>. This class variable
is made to be used by closures that are passed to I<llog>. See the example in the
'examples' directory.

=back

=head1 WARNING

=over 4

=item B<Forking, threading> Log::Localized is not designed to be used simultaneously 
by multiple threads or processes. 

=item B<Monitoring rule changes> Log::Localized loads the verbosity rules only once, 
at 'use' time, and will not
notice later changes of the rules file during runtime. This may be implemented 
in the future.

=back

=head1 SEE ALSO

See Log::Dispatch, Log::Log4perl.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-log-localized@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 FOR FUN

By the way, Log::Localized llogs itself :)
To get a glimpse of Log::Localized's internals, 'use Log::Localized;', then
dump the rule 'Log::Localized:: = 3' in a local file called 'verbosity.conf'...

=head1 AUTHOR

Written by Erwan Lemonnier C<< <erwan@cpan.org> >>
and co-designed by Claes Jacobsson C<< <claesjac@cpan.org> >>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Erwan Lemonnier C<< <erwan@cpan.org> >>

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

































