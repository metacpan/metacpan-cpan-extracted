#!/usr/bin/perl
# KGlob.pm	# Based on: glob.pl 1.1 1992/12/08 17:55:21 Tye McQueen
# @(#)KGlob.pm	1.2, 95/03/27 21:57:41
# Expand a Unix file glob (wildcard) into a list of matching file names.

require 5.001;
package File::KGlob;

require Exporter;
@ISA = (Exporter);
@EXPORT_OK = qw( &glob &kglob &pglob &fglob &unbrac );

require File::KGlob2RE;

# &glob( "pat" [, ...] ) - Expands Unix file glob(s) into the list of
# matching Unix files.  The following contructs are supported:
#   \x		matches x
#   [abc]	matches the single character "a", "b", or "c"
#   [a-c]	same as above
#   [^a-c]	matches any single character but "a", "b", "c", "/", or "\0"
#   ?		matches any single character except "/" and "\0"
#   *		matches zero or more characters not including "/" and "\0"
#   {X,Y,Z}	matches one of the patterns X, Y, or Z

%GlobContext= ();

sub glob {
  my( $pkg, $file, $line )= caller;
    if(  ! $GlobContext{$file,$line}  ) {
      my( @list )= &kglob( @_ );
	@list= sort( @list )   if  $Sort;
	$GlobContext{$file,$line}= \@list;
    }
    if(  wantarray  ) {
      my( @return )= @{$GlobContext{$file,$line}};
	delete $GlobContext{$file,$line};
	@return;
    } else {
      my( $return )= shift( @{$GlobContext{$file,$line}} );
	delete $GlobContext{$file,$line}   if ! defined($return);
	$return;
    }
}

# &kglob() always returns an array of matches; the complexity of the
# algorythm would require a great deal of saved context to allow each
# match to be returned separately like is possible with &fglob().
#   The array of values is not necessarilly sorted (that is easy enough
# to do if you want it so we won't waste the time to do it in case you
# don't want to).
#   kglob may suprise you in the following ways:
#	- {a,b} expands to ("a","b") even if files "a" and/or "b" do not exist
#	- [^a-z] is supported (any character except a through z, /, and \0)
#	- a leading dot (.) in any component of the path must be matched
#	  explicitly (with a dot, not with [^a-z], nor [.x], etc.)
#	- {.,x}* matches .* (as well as x*)
#	- setting $File::KGlob::Safe to a true value prevents "." and ".."
#	  in any component of the path from matching except exactly (by the
#	  pattern "." or "..")
#	- \x is supported (expands to just "x")
#	- % is not support (just matches "%") but File::KGlob2RE supports it
#	- ~user and ~/ are supported as is ~{user1,user2} etc.

sub kglob {
  my( @alts, @return, $user, $home );
    foreach(  @_  ) {
	# If unquoted "{" in string, generate all possible combinations: #}
	@alts=  m#(^|[^\\])(\\\\)*\{#  ?  &unbrac( $_ )  :  ( $_ );	 #}
	foreach(  @alts  ) {
	    if(  m#^~([^/]+)#  ) {	# Expand ~user to user's home directory:
		$user= $1 || getlogin();	# ~/ means "my" home directory
		$home= $1 ? ( (getpwnam($1))[7] || "~$user" )
			  : ( (getpwuid($<))[7] || $ENV{'HOME'} || "/" );
		s##$home#;
		# Replace "~user" with user's home directory (unless no such
		# user, then leave as is), unless is "~/" and getlogin()
		# failed, then try by current UID then $HOME then "/".
	    }
	    if(  m#(^|[^\\])(\\\\)*[\[\?\*]#  ) {   # Some kind of wildcard:
		push( @return, &pglob($_) );	    # Find matching files.
	    } else {		    # Just a string, perhaps with \-quoting:
		s/\\(.)/\1/g;	    # Remove the \'s used for quoting.
		push( @return, $_ );
	    }
	}
    }
    @return;
}

# &unbrac( $str ) - Expands a string containing "{a,b}" constructs.  Returns
# an array of strings.  "\" may be used to quote "{", ",", or "}" to suppress
# its special meaning (the "\"s are left in the returned strings).
#   This is a more efficient method than &glob() to expand these contructs
# where no file wildcards are involved.

sub unbrac {
  local( $glob )= @_;
  local( $pos, $bef, @bef, $temp, $mid, @mid, $aft, @aft, @return );
    $pos= rindex($glob,"{");	# Find the last "{"			    #}}
    while(  0 <= $pos  ) {	# Until there are no more "{"s to find:	    #}
	$bef= substr( $glob, 0, $pos );		# Part before "{"	    #}
	$temp= substr( $glob, 1 + $pos );	# Part after "{"	    #}
	if(  $bef =~ m#(^|[^\\])(\\\\)*$#  ) {	# The "{" is unquoted:	    #}{
	    $pos= index( $temp, "}" );		#{ Find the next nearest "}"
	    while(  0 <= $pos  ) {		#{ Until we run out of "}"s:
		$mid= substr( $temp, 0, $pos );	# Part between "{" and "}"  #{
		$aft= substr( $temp, 1 + $pos );	# Part after "}"
		if(  $mid =~ m#(^|[^\\])(\\\\)*$#  ) {	#{ The "}" is unquoted:
		    $mid =~ s/((^|[^\\])(\\\\))*,/\1\0/g; # Most unquoted ","s
		    $mid =~ s/((^|[^\\])(\\\\))*,/\1\0/g; # Remaining ones
		    return &mcat( $bef, $aft, split(/\0/,$mid) );	# Done!
		}	# &mcat builds all of the resulting strings.
	    }		# &mcat also "unbrac"s $bef and $aft.
	    if(  $Debug  ) {
		die "Unclosed `{' in pattern string: `",		#}
		  $bef, "' . `{' . `", $aft, "'\n";			#}
	    }
	}
	$pos= rindex( $glob, "{", $pos - 1 );				#}
    }
    ( $glob );	# No unquoted "{"s to be expanded			#}
}

# &File::KGlob::mcat( $bef, $aft, @mids ) - Used by &unbrac to make the code
# easier to follow.  Builds all of the strings  $bef . $mids[$i] . $aft  and
# then calls &unbrac on each of them.

sub mcat {
  local( $bef, $aft, @mid )= @_;
  local( @bef, @aft, $one, $two, $three, @return );
    foreach(  @mid  ) {
	push(  @return,  &unbrac( $bef . $_ . $aft )  );
    }
    @return;
}

# &pglob( $glob ) - Expand a Unix file glob except for "{a,b}" constructs.
# The name is short for "Path GLOB".

sub pglob {
  local( $glob )= @_;
  local( @dirs )= split( m-/+-, $glob, 9999 );	# (so trailing / isn't ignored)
  local( @paths, @build, $dir, $file, $path );
    for(  0 .. @dirs-2  ) {	# Tack "/" to all but last component so fglob
	$dirs[$_] .= "/";	# only returns directories for middle parts
    }
    pop( @dirs )   if  "" eq $dirs[@dirs-1]; # In case $glob had a trailing /
    if(  "/" eq $dirs[0]  ) {
	$path= "/";
	shift( @dirs );
    } else {
	$path= "";
    }
    @paths= grep(  $_= $path . $_,  &fglob( shift(@dirs), $path )  );
    foreach $dir (  @dirs  ) {
	@build= ();
	foreach $path ( @paths ) {
	    foreach $file (  &fglob( $dir, $path )  ) {
		push( @build, "$path/$file" );
	    }
	}
	return ()   unless  @build;
	@paths= @build
    }
    @paths;
}

# &fglob( $glob [, $dir] ) - Expands a file wildcard, $glob, (a glob with
# no /'s, ie. no directories) into the list of matching Unix files found
# in the directory $dir (or "." if $dir not specified).
#   In an array context, simply returns the list of matching files (not
# necessarilly sorted).  It returns the empty list if no matches or if
# $dir can't be read (if $dir can't be read, $! will have the reason).
#BUG: There is no way to tell between zero matches vs. an error!
#   In a scalar context, returns a context string (or undef if can't
# access the directory) that is used in subsequent calls to get each
# matching file one at a time (again, not necessarilly in sorted order).
# For example:
#	$context= &fglob( "*.dat" );
#	die "Can't read current directory: $!\n"   unless  defined($context);
#	while(  $_= &fglob( $context )  ) {
#	    if(  ! &do_something( $_ )  ) {
#		&fglob( $context, 1 );
#		last;
#	    }
#	}
# Note that you may use `&fglob($context,1)' to close the directory if
# you don't want to get *all* of the matching files ("1" can be anything
# but undef).  Also, calling fglob with a context string in an array
# context returns all of the *remaining* matching files.
#   fglob may suprise you in the following ways:
#	- / is not supported (nothing will match) except as last character
#	  of $glob, in which case only directory names are returned (without
#	  trailing /s)
#	- {a,b} will only return ("a","b") if the files "a" and "b" exist
#	- [^a-z] is supported (any character except a through z, /, and \0)
#	- \x is supported (expands to just "x" -- called "quoting")
#	- If no unquoted wildcards ("?", "[", "*", or "{") appear in $glob,
#	  just returns $glob minus the \-quoting and trailing / (if any)
#	  even if no such file exists.
#	- Files whose name begin with "." are not matched unless the first
#	  char of $glob is "." (neither "[^a-z]*" nor "[.x]*" match ".xyz").
#	- {.,x}* matches x* but not .* (a bug, but difficult to solve)
#	- If $File::KGlob::Safe is set to a true value, . and .. are not
#	  matched by any pattern (except "." and ".." themselves).

$Safe= 0;	# Whether to exclude "." and ".." from all matches.
$Sort= 1;	# Whether &glob() sorts the returned list.
$NextHndl= "File::KGlob::DIR0001";

sub fglob {	# Expland a file-only glob (no /'s in the pattern)
  local( $glob, $dir )= @_;
  local( $re, $hndl, $nodots, $onlydirs, $match, @matches );
    if(  "\0" eq substr($glob,0,1)  ) {      # A context from a previous call:
	( $hndl, $glob, $nodots, $onlydirs, $re )=
	  split( substr($glob,1), "\0" );
	if(  defined($dir)  ) {		# &fglob($context,0) means:
	    closedir( $hndl );		# prematurely end the search
	    return wantarray ? () : undef;
	}
	$dir= $glog;
    } elsif(  $glob !~ m/[\[\?\*\{\\]/  ) {	# Contains no special chars: #}
	chop $glob   if  "/" eq substr($glob,-1,1);
	return( $glob );
    } else {
	$hndl= $NextHndl;
	$NextHndl++   unless  wantarray;
	$nodots= "." ne substr($glob,0,1);	# Skip all .*'s unless explicit
	chop $glob   if  $onlydirs= "/" eq substr($glob,-1,1);
	# File::KGlob2RE uses "%" for "any subdir(s)" but we don't so...
	$glob =~ s#((^|[^\\])(\\\\)*)\%#\1\\%#g;    # quote any unquoted "%"s.
	$re= &File::KGlob2RE::kglob2re( $glob );    # Change glob to regexp.
	$dir= "."   if  "" eq $dir;
	if(  ! opendir( $hndl, $dir )  ) {
	    return wantarray ? () : undef;
	}
	if(  ! wantarray  ) {
	    return "\0$hndl\0$dir\0$nodots\0$onlydirs\0$re";
	}
    }
    while(  $_= readdir( $hndl )  ) {
	if(  m/$re/  ) {
	    if(  $nodots  &&  "." eq substr($_,0,1)	# 1-Don't match .*
	     ||  $Safe  &&  ( "." eq $_ || ".." eq $_ )	# 2-Don't match . or ..
	     ||  $onlydirs  &&  ! -d "$dir/$_"  ) {	# 3-Only match dirs
		next;	# 1-except explicitly (.*), 3-when $glob ends with /
	    }		# 2-except exactly (. or ..) (when $Safe set)
	    return $_   unless  wantarray;
	    push( @matches, $_ );
	}
    }
    closedir( $hndl );
    wantarray ? @matches : undef;
}

package main;

require File::Basename;  import File::Basename qw(basename);

if(  &basename( $0 )  eq  &basename( __FILE__ )  ) {
    # `KGlob.pm "pattern" [...]' to list matching files, one per line.
eval <<'EXAMPLE';
    import File::KGlob qw(&glob);
    sub quote {  local($*)= 1;  $_[1] =~ s/^$_[0]//g;  $_[1];  }
    if(  0 == @ARGV  ) {
	die &quote( "\t*:\t", <<"	;" ), "\n"; 
	:	Usage: KGlob.pm "pattern" [...]
	:	Examples:
	:	    KGlob.pm "*.c" | xargs grep boogers
	:	    KGlob.pm "*.dat *.idx" | xargs chmod ug=rw,o=r
	:	Note that if only one argument is given and it contains one or
	:	more spaces, then it is split into several patterns because
	:	just using one set of quotes (") for the whole list is usually
	:	much easier.  This splitting is *not* done if two or more
	:	arguments are given.
	;
    }
    if(  1 == @ARGV  &&  index($ARGV[0],' ')  ) {
	@ARGV= split( ' ', $ARGV[0] );
    }
    foreach(  @ARGV  ) {
	@matches{ &glob($_) }= ();
    }
    foreach(  sort keys %matches  ) {
	print "$_\n";
    }
EXAMPLE
chop $@;   die $@   if $@;
}

1;
