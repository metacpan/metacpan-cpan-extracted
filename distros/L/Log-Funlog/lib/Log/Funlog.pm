=head1 NAME

Log::Funlog - Log module with fun inside!

=head1 SYNOPSIS

 use Log::Funlog;
 *my_sub=Log::Funlog->new(
	parameter => value,
	...
 );

 [$string=]my_sub($priority [,$string | @array [,$string | @array [, ... ] ]] );

=head1 DESCRIPTION

This is a Perl module intended ton manage the logs you want to do from your Perl scripts.

It should be easy to use, and provide all the fonctionalities you want.

Just initialize the module, then use is as if it was an ordinary function!

When you want to log something, just write:

 your-sub-log(priority,"what"," I ","wanna log is: ",@an_array)

then the module will analyse if the priority if higher enough (seeing L<verbose> option). If yes, your log will be written with the format you decided on STDERR (default) or a file.

As more, the module can write funny things to your logs, if you want ;) It can be very verbose, or just ... shy :)

L<Log::Funlog|Log::Funlog> may export an 'error' function: it logs your message with a priority of 1 and with an specific (parametrable) string. You can use it when you want to highlight error messages in your logsi with a pattern.

Parameters are: L<header>, L<error_header>, L<cosmetic> ,L<verbose>, L<file>, L<daemon>, L<fun>, L<colors>, L<splash>, L<-n>, L<caller>, L<ltype>

L<verbose> is mandatory.

=head2 MANDATORY OPTION

=over

=item B<verbose>

In the form B<n>/B<m>, where B<n><B<m> or B<n>=max.

B<n> is the wanted verbosity of your script, B<m> if the maximum verbosity of your script.

B<n> can by superior to B<m>. It will just set B<n>=B<m>

Everything that is logged with a priority more than B<n> (in case B<n> is numeric) will not be logged.

0 if you do not want anything to be printed.

The common way to define B<n> is to take it from the command line with Getopt:

 use Getopt::Long;
 use Log::Funlog;
 &GetOptions("verbose=s",\$verbose);
 *Log=Log::Funlog->new(
	[...]
	verbose => "$verbose/5",
	[...]
	)

In this case, you can say --verbose=max so that it will log with the max verbosity level available (5, here)

This option is backward compatible with 0.7.x.x versions.

See L</EXAMPLE>

=back

=head2 NON MANDATORIES OPTIONS

=over

=item B<caller>

'all' if you want the stack of subs.

'last' if you want the last call.

If you specify a number B<n>, it will print the B<n> last calls (yes, if you specify '1', it is equivalent to 'last')

If this number is negative, it will print the B<n> first calls.

Of course, nothing will happen if no L<header> is specified, nor %ss in the L<header> ...

=item B<colors>

Put colors in the logs :)

If you just put '1', it will use default colors:

 colors => '1',

If you want to override default colors, specify a hash containing item => color

 colors => {'prog' => 'white', 'date' => 'yellow' },

Items are:

	caller: for the stack of calls,
	prog: for the name of the program,
	date: for the current date,
	level: for the log level,
	msg: for the log message

Colors are:
	black, red, green, yellow, blue, magenta, cyan, white and none

=item B<cosmetic>

An alphanumeric char to indicate the log level in your logs.

There will be as many as these chars as the log level of the string being logged. See L</EXAMPLE>

Should be something like 'x', or '*', or '!', or any printable single character.

=item B<daemon>

1 if the script should be a daemon. (default is 0: not a daemon)

When B<daemon>=1, L<Log::Funlog> write to L<file> instead of B<STDERR>

If you specify B<daemon>, you must specify L<file>

The common way to do is the same that with L<verbose>: with Getopt

=item B<error_header>

Header you want to see in the logs when you call the B<error> function (if you import it, of course)

Default is '## Oops! ##'.

=item B<file>

File to write logs to.

MUST be specified if you specify L<daemon>

File is opened when initializing, and never closed by the module. That is mainly to avoid open and close the file each time you log something and then increase speed.

Side effect is that if you tail -f the log file, you won't see them in real time.

=item B<fun>

Probability of fun in your logs.

Should be: 0<fun<=100

It use Log::Funlog::Lang

=item B<header>

Pattern specifying the header of your logs.

The fields are made like this: %<B<letter>><B<delimiters1>><B<delimiters2>><B<same_letter>>

The B<letter> is, for now:

	s: stack calls
	d: date
	p: name of the prog
	l: verbosity level

B<delimiters1> is something taken from +-=|!./\<{([ and B<delimiters2> is take from +-=|!./\>})] (replacement regexp is s/\%<letter>([<delimiters1>]*)([<delimiters2>*)<letter>/$1<field>$2/ ). B<delimiters1> will be put before the field once expanded, B<delimiters2> after.

Example:
 '%dd %p::p hey %l[]l %s{}s '

should produce something like:

 Wed Sep 22 18:50:34 2004 :gna.pl: hey [x    ] {sub48} Something happened
 ^------this is %dd-----^ ^%p::p^      ^%l[]l^ ^%s{}s^

If no header is specified, no header will be written, and you would have:

 Something happened

Although you can specify a pattern like that:
 ' -{(%d(<>)d)}%p-<>-p %l-<()>-l '

is not advisable because the code that whatch for the header is not that smart and will probably won't do what you expect.

Putting things in %?? is good only for %ss because stack won't be printed if there is nothing to print:
 ' {%ss} '

will print something like that if you log from elsewhere than a sub:
 {}

Although
 ' %s{}s '

won't print anything if you log from outside a sub. Both will have the same effect if you log from inside a sub.

You should probably always write things like:
 ' -{((<%dd>))}-<%pp>- -<(%ll)>- '

=item B<ltype>

Level printing type. Can be B<sequential> or B<numeric>.

B<sequential> will print level like that: [xx ]. This is the default.

B<numeric> will print level like that: [2]

=item B<splash>

1 if you want a 'splash log'

=item B<-n>

You can write stuff like that:

 Log(1,'-n',"plop");
 Log(1,"plop");

This will output something like:

 [x] plopplop

'-n' parameter allows you to use something else than '-n' to copy the behaviour of the '-n' parameter of L<echo(3)>

=back

=cut

package Log::Funlog;
use Carp;
use strict;
use File::Basename;

BEGIN {
	use Exporter;
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK );
	@ISA=qw(Exporter);
	@EXPORT=qw( );
	@EXPORT_OK=qw( &error $VERBOSE $LEVELMAX $VERSION );
	$VERSION='0.87';
	sub VERSION {
		(my $me, my $askedver)=@_;
		$VERSION=~s/(.*)_\d+/$1/;
		croak "Please update: $me is version $VERSION and you asked version $askedver" if ($VERSION < $askedver);
	}
}
my @fun;
our %args;
eval 'use Log::Funlog::Lang 0.3';
if ($@) {
	@fun=();
} else {
	@fun=@{ (Log::Funlog::Lang->new())[1] };
}
#use Sys::Syslog;
my $count=0;
use vars qw( %args $me $error_header $error $metaheader);

# Defined here, used later!
#####################################
my $rexpleft=q/<>{}()[]/;				#Regular expression that are supposed to be on the left of the thing to print
my $rexprite=$rexpleft;
$rexprite=~tr/><}{)(][/<>{}()[]/;		#tr same for right
my $rexpsym=q'+-=|!.\/';		#These can by anywhere (left or right)
$rexpleft=quotemeta $rexpleft;
$rexprite=quotemeta $rexprite;
$rexpsym=quotemeta $rexpsym;
my $level;
my $LOCK_SH=1;
my $LOCK_EX=2;
my $LOCK_NB=4;
my $LOCK_UN=8;
my $handleout;			#Handle of the output
my %whattoprint;
my %colortable=(
	'black' => "\e[30;1m",
	'red' => "\e[31;1m",
	'green' => "\e[32;1m",
	'yellow' => "\e[33;1m",
	'blue' => "\e[34;1m",
	'magenta' => "\e[35;1m",
	'cyan' => "\e[36;1m",
	'white' => "\e[37;1m",
	'none' => "\e[0m"
);
my %defaultcolors=(
	'level' => $colortable{'red'},
	'caller' => $colortable{'none'},
	'date' => $colortable{'none'},
	'prog' => $colortable{'magenta'},
	'msg' => $colortable{'yellow'}
);
my @authorized_level_types=('numeric','sequential');		#Level types
my %colors;		#will contain the printed colors. It is the same than %defaultcolors, but probably different :)
our $hadnocr=0;		#Remember if previous call had $nocr (to print header at first call with $nocr, but not further)

################################################################################################################################
sub replace {						#replace things like %l<-->l by things like <-** ->
	my $header=shift;
	my $what=shift;
	my $center=shift;
	if ($center) {
		$header=~s/\%$what$what/$center/;				# for cases like %dd
		#
		# Now, for complicated cases like %d<-->d or %d-<>-d
		# 
		$header=~s/\%$what(.*[$rexpleft]+)([$rexprite]+.*)$what/$1$center$2/;	#%d-<>-d   -> -<plop>-
											#%d<-->d   -> <-->
		$header=~s/\%$what(.*[$rexpsym]+)([$rexpsym]+.*)$what/$1$center$2/;	#-<plop>-  -> -<plop>-
											#<-->      -> <-plop->
	} else {
		$header=~s/\%$what.*$what//;
	}
	return $header;
}
################################################################################################################################
################################################################################################################################
sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	%args=@_;							#getting args to a hash


	# Okay, now sanity checking!
	# This is cool because we have time, so we can do all kind of checking, calculating, things like that
	#########################################
	if (defined $args{daemon} and $args{daemon}) {
		croak 'You want me to be a daemon, but you didn\'t specifie a file to log to...' unless (defined $args{file});
	}
	croak "'verbose' option is mandatory." if (! $args{'verbose'});
	croak "'verbose' should be of the form n/m or max/m" if (($args{'verbose'} !~ /^\d+\/\d+$/) and ($args{'verbose'} !~ /^[mM][aA][xX]\/\d+$/));

	# Parsing 'ltype' option
	#########################################
	if (defined $args{ltype}) {
		if (! grep(/$args{ltype}/,@authorized_level_types)) {
			croak "Unknow ltype '$args{ltype}'";
		}
	} else {
		$args{ltype}='sequential';
	}

	# Parsing 'verbose' option...
	#########################################
	my ($verbose,$levelmax)=split('/',$args{verbose});
	$levelmax=$levelmax ? $levelmax : "";						#in case it is not defined...
	$verbose=$levelmax if ($verbose =~ /^[mM][aA][xX]$/);
	if (($verbose !~ /\d+/) or ($levelmax !~ /\d+/)) {
		carp "Arguments in 'verbose' should be of the form n/m, where n and m are numerics.\nAs this is a new feature, I'll assume you didn't upgraded your script so I'll make it compatible...\nAnyhow, consider upgrading soon!\n";
		croak "No 'levelmax' provided" unless ($args{levelmax});
	} else {
		$args{verbose}=$verbose;
		$args{levelmax}=$levelmax;
	}
	if ($args{verbose} > $args{levelmax}) {
		carp "You ask verbose $args{verbose} and the max is $args{levelmax}. I set your verbose at $args{levelmax}.\n";
		$args{verbose}=$args{levelmax};
	}


	# Time for fun!
	#########################################
	if (defined $args{fun}) {
		croak "'fun' should only be a number (between 0 and 100, bounds excluded)." if ($args{fun} !~ /^\d+$/);
		croak "0<fun<=100" if ($args{fun}>100 or $args{fun}<=0);
		croak "You want fun but Log::Funlog::Lang is not available, or is too old." if ($#fun <= 0);
	}

	# Colors
	#########################################
	#We will build %colors here.
	#If color is wanted:
	#	if default is wanted, %colors = %defaultcolors
	#	if not, %colors = %defaultcolors, overriden by the parameters provided
	#If no colors is wanted, %colors will be filled with the 'none' colors.
	#
	#This way of doing should be quicker :)
	#
	if (exists $args{'colors'} and $args{'colors'} ) {							#If color is wanted
		use Config;
		if ($Config{'osname'} eq 'MSWin32') {				#Oh oh!
			carp 'Colors wanted, but MSwin detected. Colors deactivated (because not implemented yet)';
			delete $args{'colors'};
			$colortable{'none'}='';							#putting 'none' color to void
			foreach my $color (keys %defaultcolors) {
				$colors{$color}=$colortable{'none'};		#and propagating it
			}
#			no Config;
		} else {											#We are not in MSWin...
			if (ref(\$args{'colors'}) eq 'SCALAR') {		#default colors?	
				%colors=%defaultcolors if ($args{'colors'});
			} elsif(ref($args{'colors'}) eq 'HASH') {		#No... Overridden colors :)
				foreach my $item (keys %defaultcolors) {
					$colors{$item}=exists ${		#If the color is provided
						$args{'colors'}
					}{$item}?
					$colortable{
						${
							$args{'colors'}		#we take it
						}{$item}
					}:$defaultcolors{$item};		#if not, we take the default one
				}
			} else {
				croak("'colors' must be type of SCALAR or HASH, not ".ref($args{'colors'})."\n");
			}
		}
	} else {										#no colors? so the color table will contain the color 'none'
		$colortable{'none'}='';						#Avoid printing "\e[0m" :)
		foreach my $item (keys %defaultcolors) {
			$colors{$item}=$colortable{'none'};
		}
	}


# Error handler
#########################################
	$error_header=defined $args{error_header} ? $args{error_header} : '## Oops! ##';

# We define default cosmetic if no one was defined
#########################################
	if (not defined $args{cosmetic}) {
		$args{'cosmetic'}='x';
	} elsif ($args{'cosmetic'} !~ /^[[:^cntrl:]]$/) {
		croak("'cosmetic' must be one character long, and printable.");
	}

# Parsing header. Goal is to avoid work in the wr() function
#########################################
	if (defined $args{header}) {

		$metaheader=$args{header};

		# if %ll is present, we can be sure that it will always be, but it will vary so we replace by a variable
		if ($metaheader=~/\%l.*l/) {
			$whattoprint{'l'}=1;
			$metaheader=replace($metaheader,"l","\$level");
		}

		# same for %dd
		$whattoprint{'d'}=1 if ($metaheader=~/\%d.*d/);
		$metaheader=replace($metaheader,"d",$colors{'date'}."\$date".$colortable{'none'});

		# but %pp won't vary
		$me=basename("$0");
		chomp $me;
		$whattoprint{'p'}=1 if ($metaheader=~/\%p.*p/);
		$metaheader=replace($metaheader,"p",$colors{'prog'}.$me.$colortable{'none'});
		# and stack will be present or not, depending of the state of the stack
		$whattoprint{'s'}=1 if ($metaheader=~/\%s.*s/);

		if ((! defined $args{'caller'}) and ($metaheader=~/\%s.*s/)) {
			carp "\%ss is defined but 'caller' option is not specified.\nI assume 'caller => 1'";
			$args{'caller'}=1;
		}
	} else {
		$metaheader="";
	}

# Daemon. We calculate here the output handle to use
##########################################
	if ($args{'daemon'}) {
		open($handleout,">>$args{'file'}") or croak "$!";
	} else {
		$handleout=\*STDERR;
	}
# -n handling
##########################################
	$args{'-n'}='-n' unless $args{'-n'};

##########################################
# End of parsing
##########################################

	my $self = \&wr;
	bless $self, $class;			#The function's address is now a Log::Funlog object
#	return $self;				#Return the function's address, that is an object Log::Funlog
}

########################################################################################
########################################################################################
# This is the main function
########################################################################################
########################################################################################
sub wr {
	my $level=shift;						#log level wanted by the user
	return if ($level > $args{verbose} or $level == 0);	#and exit if it is greater than the verbosity

	my $prevhandle=select $handleout;

	my $return_code;
	my $nocr;

# Header building!!
#####################################
	if ($_[0] eq $args{'-n'}) {
		shift;
		$nocr=1;
	} else {
		$nocr=0;
	};
	if ($metaheader and not $hadnocr) {							#Hey hey! Won't calculate anything if there is nothing to print!
		my $header=$metaheader;
		if ($whattoprint{'s'}) {						#if the user want to print the call stack
			my $caller;
			if (($args{'caller'} =~ /^last$/) or ($args{'caller'} =~ /^1$/)) {
				$caller=(caller($error?2:1))[3];
			} else {						#okay... I will have to unstack all the calls to an array...
				my @stack;
				my $i=1;
				while (my $tmp=(caller($error?$i+1:$i))[3]) {	#turn as long as there is something on the stack
					push @stack,($tmp);
					$i++;
				};
				@stack=reverse @stack;
				if ($args{'caller'} eq "all") {;					#all the calls
					$caller=join(':',@stack);
				} else {
					if ($#stack >= 0) {
						my $num=$args{'caller'};
						$num=$#stack if ($num>=$#stack);		#in case the stack is greater that the number of call we want to print
						if ($args{'caller'} eq "all") {							#all the cals
							$caller=join(':',@stack);
						} elsif ($args{'caller'} =~ /^-\d+$/) {					#the n first calls
							$caller=join(':',splice(@stack,0,-$num));
						} elsif ($args{'caller'} =~ /^\d+$/) {					#just the n last calls
							$caller=join(':',splice(@stack,1+$#stack-$num));
						}
					}
				}
			}

			if ($caller) {							#if there were something on the stack (ie: we are not in 'main')
				$caller=~s/main\:\://g;				#wipe 'main'
				my @a=split(/\//,$caller);			#split..
				@a=reverse @a;						#reverse...
				$header=replace($header,"s",$colors{'caller'}.join(':',@a).$colortable{'none'});
			} else {
				$header=replace($header,"s");
			}
		} else {
			$header=replace($header,"s");
		}
		if ($whattoprint{'d'}) {
			my $tmp=scalar localtime;
			$header=~s/\$date/$tmp/;
		}
		if ($whattoprint{'l'}) {
			my $tmp;
			if ($args{ltype} eq 'numeric') {
				$tmp=$colors{'level'}.$level.$colortable{'none'};
			} elsif ($args{ltype} eq 'sequential') {
				$tmp=$colors{'level'}.$args{cosmetic} x $level. " " x ($args{levelmax} - $level).$colortable{'none'};	# [xx  ]
			}
			$header=~s/\$level/$tmp/;
		}

		#####################################
		#	End of header building
		#####################################
		print $header;						#print the header
	}
	print $colors{'msg'};
	while (my $tolog=shift) {			#and then print all the things the user wants me to print
		print $tolog;
		$return_code.=$tolog;
	}
	print $colortable{'none'};
	print "\n" unless $nocr;
	#Passe le fun autour de toi!
	print $fun[1+int(rand $#fun)],"\n" if ($args{fun} and (rand(100)<$args{fun}) and ($count>10));			#write a bit of fun, but not in the first 10 lines
	#print "nc:$nocr\n";
	$count++;
	if ($nocr) {
		$hadnocr=1;
	} else {
		$hadnocr=0;
	}
	#print "hnc:$hadnocr\n";

	select($prevhandle);
	return $return_code;
}
sub error {
	$error=1;
	my $ec=wr(1,$error_header," ",@_);
	$error=0;
	return $ec;
}
1;
=pod

=head1 EXAMPLE

Here is an example with almost all of the options enabled:

 $ vi gna.pl
 #!/usr/bin/perl -w
 use Log::Funlog qw( error );
 *Log=new Log::Funlog(
		file => "zou.log",		#name of the file
		verbose => "3/5",			#verbose 3 out of a maximum of 5
		daemon => 0,			#I am not a daemon
		cosmetic => 'x',		#crosses for the level
		fun => 10,			#10% of fun (que je passe autour de moi)
		error_header => 'Groumpf... ',  #Header for true errors
		header => '%dd %p[]p %l[]l %s{}s ',	#The header
		caller => 1);			#and I want the name of the last sub

 Log(1,"I'm logged...");
 Log(3,"Me too...");
 Log(4,"Me not!");          #because 4>verbose
 sub ze_sub {
	$hop=1;
	Log(1,"One","two",$hop,"C"."++");
	error("oups!");
 }
 ze_sub;
 error("Zut");

 :wq

 $ perl gna.pl
 Tue Jul 26 15:39:41 2005 [gna.pl] [x    ]  I'm logged...
 Tue Jul 26 15:39:41 2005 [gna.pl] [xxx  ]  Me too...
 Tue Jul 26 15:39:41 2005 [gna.pl] [x    ] {ze_sub} Onetwo1C++
 Tue Jul 26 15:39:41 2005 [gna.pl] [x    ] {ze_sub} Groumpf...  oups!
 Tue Jul 26 15:39:41 2005 [gna.pl] [x    ]  Groumpf...  Zut

=head1 BUGS

=over

=item 1-

This:

 header => '-(%dd)--( %p)><(p )-( %l)-<>-(l %s)<>(s '

won't do what you expect ( this is the ')><(' )

Workaround is:

 header => '-(%dd)--( )>%pp<( )-( %l)-<>-(l %s)<>(s '

And this kind of workaround work for everything but %ss, as it is not calculated during initialization.

=item 2-

 *Log=Log::Funlog->new(
  colors => 1,
  colors => {
	 date => 'white'
  }
 )

Is not the same as:

 *Log=Log::Funlog->new(
  colors => {
	 date => 'white'
  },
  colors => 1,
 )

First case will do what you expect, second case will put default colors.

To avoid that, specify EITHER colors => 1 OR colors => {<something>}

=back

=head1 DEPENDENCIES

Log::Funlog::Lang > 0.3 : provide the funny messages.

=head1 DISCUSSION

As you can see, the 'new' routine return a pointer to a sub. It's the easiest way I found to make this package as easy as possible to use.

I guess that calling the sub each time you want to log something (and even if it won't print anything due to the too low level of the priority given) is not really fast...

Especially if you look at the code, and you see all the stuffs the module do before printing something.

But in fact, I tried to make it rather fast, that mean that if the module try to know as fast as possible if it will write something, and what to write

If you want a I<really> fast routine of log, please propose me a way to do it, or do it yourself, or do not log :)

You can probably say:

 my Log::Funlog $log = new Log::Funlog;		# $log is now an Log::Funlog object. $log contain the address of the sub used to write.

Then:

 &{$log}(1,'plop');

But it is probably not convenient.

=head1 HISTORY

I'm doing quite a lot of Perl scripts, and I wanted the scripts talk to me. So I searched a log routine.

As I didn't found it on the web, and I wanted something more 'personnal' than syslog (I didn't want my script write to syslog), I started to write a very little routine, that I copied to all the scripts I made.

As I copied this routine, I added some stuff to match my needs; I wanted something rather fast, easy to use, easy to understand (even for me :P ), quite smart and ... a little bit funny :)

The I wrote this module, that I 'use Log::Funlog' in each of my scripts.

=head1 CHANGELOG

See Changelog

=head1 AUTHOR

Gabriel Guillon, from Cashew team

korsani-spam@caramail(spaaaaaammmm).com[spppam]

(remove you-know-what :)

=head1 LICENCE

As Perl itself.

Let me know if you have added some features, or removed some bugs ;)

=cut

