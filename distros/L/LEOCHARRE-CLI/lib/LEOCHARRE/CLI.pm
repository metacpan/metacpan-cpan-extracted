package LEOCHARRE::CLI;
use strict;
use Carp;
use Cwd;
use vars qw($VERSION);
$VERSION = sprintf "%d.%02d", q$Revision: 1.19 $ =~ /(\d+)/g;

$main::DEBUG = 0;
$main::USAGE = 0;

sub main::DEBUG : lvalue {
   $main::DEBUG;   
}

sub main::debug {
   $main::DEBUG or return 1;
   my $msg = shift;   
   print STDERR " $0, $msg\n";
   return 1;
}











# BEGIN USER

sub main::whoami {	
	unless (defined $::WHOAMI){
      require File::Which;
		if (my $wb = File::Which::which('whoami')){
			my $whoami = `$wb`;
			chomp $whoami;
			$::WHOAMI = $whoami;	
		}
		else {
         warn("whoami bin path not found.");
			$::WHOAMI = 0;
			return;	
		}
	}
	$::WHOAMI or return;

	return $::WHOAMI;	
}

sub main::force_root {
	main::running_as_root() or print "$0, only root can use this." and exit;
	return 1;
}

sub main::running_as_root {
   my $whoami = main::whoami() or return 0;
   $whoami eq 'root' or return 0;
   return 1;
}

sub main::get_uid {
  my $name = shift;
  main::user_exists($name) or return;
  
  require Linux::usermod;
  my $user = Linux::usermod->new($name);
  my $id = $user->get('uid');
  $id=~/^\d+$/ or return;
  return $id;
}

sub main::user_exists {
   my $name = shift;
   require Linux::usermod;
   my %u = Linux::usermod->users;
   $u{$name} or return 0;
   return 1;
}

sub main::get_gid {
  my $name = shift;   
  main::user_exists($name) or return;
  require Linux::usermod;  
  my $g = Linux::usermod->new($name,1);
  my $id = $g->get('gid');
  $id=~/^\d+$/ or return;
  return $id;
}

# END USER






sub main::get_mode {
   my $abs = shift;
   require File::chmod;
   my $mod = File::chmod::getmod($abs) or return;
   return $mod;
}










# BEGIN GOPTS AND ARGS
sub main::gopts {
	my $opts = shift;
	$opts||='';

	if($opts=~s/v\:?|h\:?|d\:?//sg){
		print STDERR("$0, options changed") if ::DEBUG;
	}

	$opts.='vhd';
	
	my $o = {};	
   
   require Getopt::Std;
	Getopt::Std::getopts($opts, $o); 
	
	if($o->{v}){
		if (defined $::VERSION){
			print $::VERSION;
			exit;
		}		
		print STDERR "$0 has no version\n";
		exit;					
	}

	if ($o->{d}){
		$main::DEBUG = 1;
	}


	if($o->{h}){
		main::man()
	}	
	
	return $o;
}




sub main::argv_aspaths {
	my @argv;
	scalar @ARGV or return;

	for(@ARGV){
		my $abs = Cwd::abs_path($_) or warn("$0, Does not resolve: $_, skipped.") and next;
		-e $abs or  warn("$0, Does not exist: $_, skipped.") and next;
		push @argv, $abs;
	}

	scalar @argv or return;

	return \@argv;
}

sub main::argv_aspaths_strict {
	my @argv;
	scalar @ARGV or return;

	for(@ARGV){
		my $abs = Cwd::abs_path($_) or warn("Does not resolve: $_.") and return;
		-e $abs or  warn("Is not on disk: $_.") and return;
		push @argv, $abs;
	}
	scalar @argv or return;
	return \@argv;
}

sub main::argv_aspaths_loose {
	my @argv;
	scalar @ARGV or return;

	for(@ARGV){
		my $abs = Cwd::abs_path($_) or warn("$0, Does not resolve: $_, skipped.") and next;
		push @argv, $abs;
	}
	scalar @argv or return;
	return \@argv;
}

sub main::yn {
        my $question = shift; $question ||='Your answer? ';
        my $val = undef;
        until (defined $val){
                print "$question (y/n): ";
                $val = <STDIN>;
                chomp $val;
                if ($val eq 'y'){ $val = 1; }
                elsif ($val eq 'n'){ $val = 0;}
                else { $val = undef; }
        }
        return $val;
}

# END GOPTS AND ARGS



















# BEIGN HELP , USAGE, MAN ETC

sub main::man {

   if( defined $main::usage ){
      my $output = $main::usage;
      print STDERR "$output\n";
   }

   elsif( defined &main::usage ){
      my $output = main::usage();
      print STDERR "$output\n";
   }

   else {
   	my $name = main::_scriptname();
      print `man $name`; 
   }

   exit;
}

# END HELP








sub main::_scriptname{
	my $name = $0 or return;
	$name=~s/^.+\///;
	return $name;
}

sub main::_scriptname_only{
	my $name = $0 or return;
	$name=~s/^.+\///;
   $name=~s/\.\w{1,}$//;
	return $name;
}

sub main::config {
	my $abs_conf = shift;

   $abs_conf ||= main::suggest_abs_conf();

   $abs_conf 
      or warn("Cannot determine abs_conf automatically and no arg passed")
      and return;

	-f $abs_conf 
      or warn("$0, [$abs_conf] does not exist.") 
      and return;

	require YAML;
	return (YAML::LoadFile($abs_conf));
}

sub main::suggest_abs_conf {
   $ENV{HOME} or warn("ENV HOME not set") and return;
   return ( $ENV{HOME}.'/'. main::_scriptname_only().'.conf');
}

sub main::suggest_abs_log {
   $ENV{HOME} or warn("ENV HOME not set") and return;
   return ( $ENV{HOME}.'/'. main::_scriptname_only().'.log');
}

sub main::mktmpdir {
   my $d = '/tmp/tmp_'.time().( int rand(2000000) );
   return undef and warn("$0, $d exists") if -d $d;
   mkdir $d or die("$0, cannot make $d, $!");
   return $d;
}






# BEGIN OPERATING SYSTEM AND WITCH

sub main::os_is_win {
   for(qw(dos os2 mswin32)){
      $^O=~/^$_/i or next;
      return 1;
   }
   return 0;   
}

sub witch {
   my $bin = shift;
   require File::Which;
   my $binpath = File::Which::which($bin) 
      or dye("Can't find $bin, is it installed?");      
   return $binpath;
}



sub say { print STDERR (+shift)."\n" and return 1; }
sub dye { say("$0, ".(+shift)) and exit 1; }

*::witch = \&witch;
*::say   = \&say;
*::dye   = \&dye;

# END OPERATING SYSTEM AND WITCH






1;

__END__

=pod

=head1 NAME

LEOCHARRE::CLI - useful subs for coding cli scripts

=head1 DESCRIPTION

I use this module as base for my CLI scripts.
It standardizes some things.



=head1 PROMPT

=head2 yn()

prompt user for y/n confirmation
will loop until it returs true or false
argument is the question for the user

	yn('are you sure you want to destroy something?') or exit;

=cut







=head1 FEEDBACK DEBUG ETC

=head2 DEBUG()

returns boolean
if script has -d flag, this is on.

=head2 debug()

Use to print to STDERR if DEBUG is on.

   debug('reached that part in our program..');


=head2 say()

Prints to stderr returns true, similar to warn.

=head2 dye()

Similar to dye, implies there is no error with script, but with a param, etc.


=cut





=head1 SYSTEM AND ENVIRONMENT

All my scripts are meant to be run on POSIX systems. Specifically gnu linux.

=head2 _scriptname()

Returns name of script, just the name.

=head2 os_is_win()

attempts to match $^O to a windows type os

=head2 force_root()

Will force program to exit if whoami() is not root.

=head2 running_as_root()

Returns boolean, checks if we are running as root.

=head2 whoami()

Returns who you are running as, name. 
If which('whoami') does not return, returns undef

=head2 get_uid()

Argument is username.
Returns user id number.
Returns nothing if not a user on this system.
This is a way to test if user exists on system.

=head2 get_gid()

Argument is group name.
Returns gid of group.
If the argument is not a group on the system, returns undef.
With this you can test for the user on system.

=head2 user_exists()

Argument is username.
Returns boolean.

=head2 witch()

Arg is binary name (like find, man, etc), returns abs path to binary or dies with error.

   my $bin = witch('tesseract');

Will exit and say that tesseract is not installed etc.

=cut








=head1 FILE SUBS

=head2 get_mode()

argument is path to file on disk
returns mode in the form 755
if not on disk returns undef

=cut












=head1 COMMAND LINE ARGUMENTS

Arguments to command line interface.

CLI options:

	-d is always debug
	-h is always print help and exit
	-v is always print version and exit
	


=head2 PATH ARGUMENTS

You MUST call gopts() BEFORE you call these, if you expect both filename
arguments AND command arguments. Otherwise you will get garble- because
you'll interpret things like -f and -d as file instead of options.

=head3 argv_aspaths()

returns array ref of argument variables treated as paths, they are resolved with Cwd::abs_path()
Any arguments that do not resolve, are skipped with a warning.
if no abs paths are present after checking, returns undef
files are checked for existence
returns undef if no @ARGVS or none of the args are on disk
skips over files not on disk with warnings


=head3 argv_aspaths_strict()

Same as argv_aspaths(), but returns false if 
any of the file arguments are no longer on disk

=head3 argv_aspaths_loose()

Same as argv_aspaths(), but does not check for existence, 
only resolved to abs paths

=cut








=head2 OPTIONS AND PARAMETERS

=head3 gopts()

returns hash of options
uses Getopt::Std, forces v for version, h for help d for debug

To get standard with v and h:

	my $o = gopts(); 

To add options

	my $o = gopts('af:');

Adds a (bool) and f(value), v and h are still enforced.

See Getopt::Std

=head2 config()

argument is abs paht to YAML conf file
returns conf hash
warns and returns undef if file is not there

If no argument if provided, will attempt to use heuristics to guess.
Will use HOME environment variable.

=head2 suggest_abs_conf()

=head2 suggest_abs_log()

=cut






=head1 HELP

Whenever a script is calledwith -h it should output help.

Example script:

   use base 'LEOCHARRE::CLI';

   sub usage {
      return qq{
      $0

      OPTIONS

         -h help
      };
   }

And then..

   script -h


=head2 usage()

You should define this sub in your script.
It should return OPTION and PARAMETER flags etc.

=head2 man()

will print manual and exit.

This first seeks your script for a global variable $usage,  
then a subroutine named usage()
prints to screen and exits.
otherwise it calls man ./pathtoscript

when you invoke -h via the commandline, this is called automatically.

=head2 mktmpdir()

will make a temp dir in /tmp/tmp_$rand
returns abs path to dir
returns undef and warns if it cant
will not overrite an existing dir, returns undef if already exists (unlikely).

=cut









=head1 SEE ALSO

File::Which
Linux::usermod
Cwd
Getopt::Std

=head1 CAVEATS

This module is for gnu linux. It will not even install on non POSIX systems.
Don't even try it, the installer checks for that.

There are no plans to port any of my code to other "systems".

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 BUGS

I make fixes and updates as quickly as I can. Please contact me for any suggestions, etc.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same 
terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 COPYRIGHT

Copyright (c) 2008 Leo Charre. All rights reserved.

=cut
