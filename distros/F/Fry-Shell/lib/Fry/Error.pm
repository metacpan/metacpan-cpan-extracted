package Fry::Error;
use strict;
#use Data::Dumper;

my $error_class = __PACKAGE__;
my @stack = ();
my $id = 0;

our $Called = 0;
#indicates if a diesub or warnsub was called
our $MinDieLevel = 7; 
#minium level for a diesub to be called
#our $defaultWarnLevel = 3; 
our $CallError = 1;
#a nonzero value doesn't call any error subroutine
our $MinLevel = 3;
#Minimum Level for a warning or die to be thrown
our $DefaultDie = 0;
#A nonzero value calls &CORE::die
our $DefaultWarn = 0;
#A nonzero value calls &CORE::warn

	#class methods
	sub setup {
		#w: has to be able to handle anything after &initCoreClass
		my $cls = shift;
		#no strict 'refs';
		#die ("&setup should be called by Fry::Error or a subclass of it: $@")
		#if  (grep(/Fry::Error/,@{"$cls\::ISA"}) == 0 && $cls ne "Fry::Error");

		$error_class = $cls;
	}
	#die/warn subs
	*CORE::GLOBAL::die = sub {
		$Called = 0;
		$error_class->setDefaultDie;

		if ($DefaultDie) { CORE::die(@_) }
		else {
			my %attr = $error_class->parseDieArgs(@_);
			$error_class->sigHandler(from=>'die',%attr);
		}
	};
	*CORE::GLOBAL::warn = sub {
		$Called = 0;
		$error_class->setDefaultWarn;
		if ($DefaultWarn) { CORE::warn(@_) }
		else {
			my %attr = $error_class->parseWarnArgs(@_);
			$error_class->sigHandler(from=>'warn',%attr);
		}
	};
	sub _newwarn($@) {
		my ($cls,@arg) = @_;
		$Called =1; 
		$cls->warnsub(@arg);
	}
	sub _newdie ($@) {
		my ($cls,@arg) = @_;
		$Called =1; 
		$cls->diesub(@arg);
	}

	#main class methods
	sub sigHandler($%) {
		my ($cls,%attr) = @_;

		my $err = $cls->new(%attr);

		#push(@stack,$err) unless ($$err{stack} == 0);

		#early exit for 2 cases
		return 0 if ($CallError != 1 or $MinLevel > $$err{level});

		$err->takeAction;
	}
	sub new {
		my ($cls,%attr) = @_;
		my %fromlevels = qw/die 7 warn 3/;
		my $err = {%attr};
		$id++;
		$err->{id} = $id;
		#$err->{stack} = 1;

		#set caller,time
		$err->{caller} = [caller(2)] ;

		#print Dumper $err;
		bless $err, $cls;

		#set levels
		$err->{level} = $fromlevels{$attr{from}} if (! exists $err->{level});
		$err->setLevel;

		return $err;
	}

	#subclassable $err methods
	sub takeAction {
		my $err = shift;
		my $cls = ref $err;

		my @arg = (ref ($$err{arg}) eq "ARRAY") ? @{$$err{arg}} : $$err{arg};
		#die in eval takes priority over levels
		$cls->_newdie(@arg) if ($$err{from} eq "die" && $^S == 1);


		if ($$err{level} >= $MinDieLevel) {
			$cls->_newdie(@arg)
		}
		#elsif ($$err{level} >= $defaultWarnLevel) 
		else { $cls->_newwarn(@arg) }
	}

	sub setLevel {}

	##subclassable class methods
	sub setDefaultDie {}
	sub setDefaultWarn {}
	sub parseDieArgs {
		shift; 
		my %attr;
		if (ref $_[-1] eq "HASH") {
			%attr = %{pop()}
		}
		$attr{arg} = [@_];

		return %attr
	}
	sub parseWarnArgs {
		my $cls = shift;
		my %attr;
		#my @arg = (@_ > 1) ? {map { (shift(@attr),$_) } @_ } : @_;

		if (ref $_[-1] eq "HASH") {
			%attr = %{pop()}
		}

		if (@_ > 1) {
			my @attr = qw/arg level tags/;
			my %quick = map { (shift(@attr),$_) } splice(@_,0,3) ;
			%attr = (%attr,%quick);
		}
		else { $attr{arg} = [@_] }
		return %attr;
	}
	sub diesub { shift; CORE::die(@_) }
	sub warnsub { shift; CORE::warn(@_) }
1;
__END__	

#OLD CODE
	sub stack {@stack }
	sub flush { 
		my $cls = shift;
		if (my $number = shift) {
			return splice(@stack,0,$number)
		}
		else { my @deleted = @stack ; @stack = () ; return @deleted }
	}
	sub stringify_stack {
		my ($cls,%arg) = @_;
		my @keys = (exists $arg{keys}) ? @{$arg{keys}} : (qw/arg level/);
		my $num = $arg{stack} || scalar(@stack);
		my $body;

		for (0 .. $num -1) {
			$body .= ($_+1) . ".\n";
			for my $k (@keys) {
				my $item = $stack[$_]->{$k};
				$item = "@$item" if (ref $item eq "ARRAY");
				$body .= "\t$k\: ". $item ."\n";
			}
		}
		return $body;
	}
	sub cleanArgs {
		no strict 'refs';
		my ($cls,$err) = @_;
		my $caller = caller;
		my %valid = map { ($_=>1) }  @{"$caller\::param"};

		for (keys %$err) {
			if (! exists $valid{$_}) {
				delete $err->{$_};
				#warn
			}
		}	
	}

=head1 NAME

Fry::Error - Redefines warn and die to trigger actions by error levels and tags.

=head1 DESCRIPTION 

This is an error-handling module. independent of Fry::*, which offers the following:

	- Redefining die or warn to call die-like or warn-like subs ie Carp::croak and Carp::carp.
	- Errors are assigned levels, generally indicating severity of error.
	- Errors can have actions, the most obvious being logging an error, throwing a warning or
		dying. This means that logging can be done simply with &warn.
	- Errors can have tags associated with them which can affect actions or level settings.

Since this class overrides perl's die and warn, it affects all module in an application when used
by any one module ie Fry::Shell. To fallback on perl's warn and die, set the global variables
$DefaultDie or $DefaultWarn to 1. To provide logic for when and when not to fallback you can
subclass this module and set the variables within &setDefaultDie or &setDefaultWarn.

A Fry::Error has the following attributes:

	Attributes with a '*' next to them are always defined.
	*id($): Unique id indicating order among other errors
	*caller(\@): Contains all of caller()'s data for the error's origin.
	*from($): Has value of either 'die' or 'warn' indicating from what error subroutine it was called.
	*level($): Number indicating error level. By default the values should go from 0-7 similar
		to the syslog command.
	*arg($): Contains arguments to be passed to a warn or die subroutine.
	tags(\@): Keywords or tags associated with error.

=head1 PUBLIC METHODS

	Class methods
		sigHandler(%attr): Passes its arguments directly to &new. This subroutine first defines an
			error object, provides an early exit via global variables and then performs
			actions for the error.
		new(%attributes): Creates an error object.
		parseDieArgs(@args): Parses arguments given to die() and returns attributes to construct an
			error object via &new. By default, if the last argument is a hashref, it is
			interpreted as parameters for the object

			ie: die('really strange',{tags=>[qw/bizarre/]})

		parseWarnArgs(@args): Parses arguments given to warn() and returns attributes to construct an
			error object via &new. Same default as parseDieArgs. In addition, multiple
			arguments (up to three) are implicitly matched with the attributes: arg, level,tags.

			ie: warn('yo',4,'interjection'); would create the following attribute hash
			{qw/arg yo level 4 tags interjection/}

		setDefaultDie(@args): Set $DefaultDie for desired cases ie only certain modules.
		setDefaultWarn(@args): Set $DefaultWarn for desired cases.
		diesub(@arg): Calls a die-like sub with given arguments ie Carp::croak
		warnsub(@arg): Calls a warn-like sub with given arguments ie Carp::carp.

	Object methods
		setLevel(): Sets an object's level via more complex requirements ie other object
			attributes such as tags or caller.
		takeAction(): Can take action on an error based on any attribute, the most likely
			being 'level'. Aside from the obvious actions of calling a diesub or warnsub,
			another action could be logging via logging modules such as Log::Dispatch or
			Log::Log4perl or simplyt to a file. When subclassing this method, don't
			forget calls to &warnsub and &diesub.

=head1 TODO

Implement more thorough logging capabilities.

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
