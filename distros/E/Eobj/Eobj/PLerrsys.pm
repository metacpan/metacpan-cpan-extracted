#
# This file is part of the Eobj project.
#
# Copyright (C) 2003, Eli Billauer
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# A copy of the license can be found in a file named "licence.txt", at the
# root directory of this project.
#

package Eobj::PLerror;

$CarpLevel = 0;		# How many extra package levels to skip on carp.
$MaxEvalLen = 0;	# How much eval '...text...' to show. 0 = all.
$MaxArgLen = 64;        # How much of each argument to print. 0 = all.
$MaxArgNums = 8;        # How many arguments to print. 0 = all.
$Verbose = 0;		# If true then make shortmess call longmess instead
$DumpLevel = 0;

sub oneplace {
  my $i = 1;
  my $errcr;
  my ($package, $filename, $line);
  while (1) {
    ($package, $filename, $line) = caller($i++);
    last unless ($package);
    $errcr = ${"$package"."::errorcrawl"} || "";
    next if ($errcr eq 'skip');
    next if ($errcr eq 'system');
    last;
  }
  return "at $filename line $line" if ($package);
  return "";
}

sub stackdump {
    return @_ if ref $_[0];
    my $error = join '', @_;
    my $mess;
    my @messlist = ();
    my $i = 1 + $DumpLevel;
    my ($pack,$file,$line,$sub,$hargs,$junk,$eval,$require);
    my (@a);
    my (@b);
    my ($xsub, $xpack, $name, $errcr);
    #
    # crawl up the stack....
    #
  CRAWL: while (do { { package DB; @a = caller($i++) } } ) {
        $mess= ""; 
	# get copies of the variables returned from caller()
	($pack,$file,$line,$sub,$hargs,$junk,$eval,$require) = @a;
	$errcr = ${"$pack"."::errorcrawl"} || "";
        next CRAWL if ($errcr eq 'skip');
        last CRAWL if ($errcr eq 'halt');
	@a=();
	@a = @DB::args if $hargs;	# must get local copy of args

	#
	# if the $error error string is newline terminated then it
	# is copied into $mess.  Otherwise, $mess gets set (at the end of
	# the 'else' section below) to one of two things.  The first time
	# through, it is set to the "$error at $file line $line" message.
	# $error is then set to 'called' which triggers subsequent loop
	# iterations to append $sub to $mess before appending the "$error
	# at $file line $line" which now actually reads "called at $file line
	# $line".  Thus, the stack trace message is constructed:
	#
	#        first time: $mess  = $error at $file line $line
	#  subsequent times: $mess .= $sub $error at $file line $line
	#                                  ^^^^^^
	#                                 "called"
	if ($error =~ m/\n$/) {
	  $mess .= $error;
	} else {
	  # Build a string, $sub, which names the sub-routine called.
	  # This may also be "require ...", "eval '...' or "eval {...}"
	  if (defined $eval) {
	    if ($require) {
	      $sub = "require $eval";
	    } else {
	      $eval =~ s/([\\\'])/\\$1/g;
	      if ($MaxEvalLen && length($eval) > $MaxEvalLen) {
		substr($eval,$MaxEvalLen) = '...';
	      }
	      $sub = "eval '$eval'";
	    }
	  } elsif ($sub eq '(eval)') {
	    $sub = 'eval {...}';
	  } else {

	    # Now we attempt to handle autoloads gracefully. The idea is to
	    # steal the subroutine name from the function that the autoloader
	    # calls, hence one step shallower in the call stack ($i-2 because
	    # $i was incremented before).

	    if ($sub eq 'UNIVERSAL::AUTOLOAD') {
	      do { { package DB; @b = caller($i-2) } };
	      ($sub) = $b[3] =~ /.*::(.*)/;
	    }

	    # Now we try to substitute the classic Foo::Bar with something
	    # more useful. Hopefully, we'll resolve the object's name.

	    ($xpack, $xsub) = ($sub =~ /(.*)::(.*)/);
	    if ((defined $xpack) && (exists $packhash{$xpack})) {  # Is the package autoloaded?
	      if (($Eobj::classes{ref($a[0])}) # Paranoid check before...
		  && ($name = $a[0]->who)) { # calling a method
		$sub = $name."->".$xsub;
		shift @a; # Don't show ugly object references
	      } else {
		$sub = "(".$packhash{$xpack}.")->".$xsub;
	      }
	    }
	    if	((defined $xsub) && ($xsub eq '__ANON__')) {
	      $sub = "CALLBACK ";
	    }
	  }
	  # if there are any arguments in the sub-routine call, format
	  # them according to the format variables defined earlier in
	  # this file and join them onto the $sub sub-routine string
	  if ($hargs) {
	    # we may trash some of the args so we take a copy
	    # don't print any more than $MaxArgNums
	    if ($MaxArgNums and @a > $MaxArgNums) {
	      # cap the length of $#a and set the last element to '...'
	      $#a = $MaxArgNums;
	      $a[$#a] = "...";
	    }
	    for (@a) {
	      # set args to the string "undef" if undefined
	      $_ = "undef", next unless defined $_;
	      if (ref $_) {
	        if ($Eobj::classes{ref($_)}) { # Is this a known object?
		  $_=$_->who;    # Get the object's pretty ID
		  next;
	        }
		# force reference to string representation
		$_ .= '';
		s/'/\\'/g;
	      }
	      else {
		s/'/\\'/g;
		# terminate the string early with '...' if too long
		substr($_,$MaxArgLen) = '...'
		  if $MaxArgLen and $MaxArgLen < length;
	      }
	      # 'quote' arg unless it looks like a number
	      $_ = "'$_'" unless /^-?[\d.]+$/;
	      # print high-end chars as 'M-<char>'
	      s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
	      # print remaining control chars as ^<char>
	      s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
	    }
	    # append ('all', 'the', 'arguments') to the $sub string
	    $sub .= '(' . join(', ', @a) . ')';
	  }
	  # here's where the error message, $mess, gets constructed

	  $mess .= "$sub " if $error eq "called";
  	  if ($errcr eq 'system') {
	    $mess .= "by System";
	  } else {
	    $mess .= "$error at $file line $line";
	  }
	  if (defined &Thread::tid) {
	    my $tid = Thread->self->tid;
	    $mess .= " thread $tid" if $tid;
	  }
	  $mess .= "\n";
	}
	# we don't need to print the actual error message again so we can
	# change this to "called" so that the string "$error at $file line
	# $line" makes sense as "called at $file line $line".
	$error = "called";
	push @messlist, $mess;
      }
    return ("", $error) unless @messlist;
    $mess="";

    $error = shift @messlist;
    $mess = "Calling chain:\n".join('',reverse @messlist)
      if (@messlist);
    return ($mess, $error);
  }

# constdump is a special error reporting subroutine to be used by const only.
# The aim: To clarify exactly what happened if a chain of magic callsbacks
# eventually cause an inconsistency in const values.

sub constdump {
    my $mess;
    my @messlist = ();
    my $i = 1 + $DumpLevel;
    my ($pack,$file,$line,$sub,$hargs,$junk,$eval,$require);
    my (@a);
    my (@b);
    my ($xsub, $xpack, $name, $xat);
    #
    # crawl up the stack....
    #
  CRAWL: while (do { { package DB; @a = caller($i++) } } ) {
	# get copies of the variables returned from caller()
	($pack,$file,$line,$sub,$hargs,$junk,$eval,$require) = @a;
	@a=();
	@a = @DB::args if $hargs;	# must get local copy of args

	# This call is only interesting if it was a call to const. If it was,
	# we want to know what object got it.

	($xpack, $xsub) = ($sub =~ /(.*)::(.*)/);
	next CRAWL unless ($xsub eq 'const');
	next CRAWL unless ((exists $packhash{$xpack}) && # Is this a "good" object?
			   ($Eobj::classes{ref($a[0])}));
	next CRAWL unless ($name = $a[0]->who); # It better have a name!
	$sub = $name."->".$xsub;
	$xat = "at $file line $line";
	shift @a; # Don't show ugly object references

	# Now we fetch the argument. There is only one, so we set $_ and go on.

	foreach (@a[0..1]) { 
	  $_ = "undef", next unless defined $_;
	  if (ref $_) {
	    if ($Eobj::classes{ref($_)}) { # Is this a known object?
	      $_=$_->who;    # Get the object's pretty ID
	      next;
	    }
	    # force reference to string representation
	    $_ .= '';
	    s/'/\\'/g;
	  }
	  else {
	    s/'/\\'/g;
	    # terminate the string early with '...' if too long
	    substr($_,$MaxArgLen) = '...'
	      if $MaxArgLen and $MaxArgLen < length;
	  }
	  # 'quote' arg unless it looks like a number
	  $_ = "'$_'" unless /^-?[\d.]+$/;
	  # print high-end chars as 'M-<char>'
	  s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
	  # print remaining control chars as ^<char>
	  s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
	}

	my ($prop, $val) = @a;
	$mess = "Property $prop = $val on $sub\n";
	push @messlist, $mess;
      }
    # If we only caught one const, there was no callback chain. No hints.
    return ($xat, "") if ($#messlist < 1);

    $mess = "\nHint: This is probably due to a chain of \"magic\" property settings\n";
    $mess .= "in the following sequence:\n";
    $mess .= join('',reverse @messlist)."\n";
    return ($xat, $mess);
  }


1;
