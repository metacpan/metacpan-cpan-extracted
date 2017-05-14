#!/usr/bin/perl
# KGlob2RE.pm	# Based on glob2re.pl 1.5 1992/12/09 23:31:01 Tye McQueen
# @(#)KGlob2RE.pm	1.2, 95/03/27 22:00:11
# Convert Unix file "glob" patterns to Perl regular expressions.

require 5.000;
package File::KGlob2RE;
require Exporter;
@ISA = (Exporter);
@EXPORT = qw( &kglob2re );

# The supported features are (where x is a single character and X and Y are
# strings):
#
# .	matches .
# \x	matches x
# [...]	matches a single character falling into the described character class
# ?	matches any single character except /
# *	matches zero or more characters not including /
# %	matches zero or more directories (see technical notes at bottom)
# {X,Y}	matches either pattern X or Y (can list any number of patterns)
#
#Examples:
# %s.*	    matches any file whose name starts with "s." in any directory
# %*.o	    matches any file whose name ends with ".o" in any directory
# %old/*    matches any file in a directory called "old"
# %new%*    matches any file in a directory called "new" or a subdirectory
#	    of a directory called "new"
# /%*	    matches any absolute path name
# {*,?*%*}  matches any relative path name (this would be very inefficient
#	    except that it is specifically optimized)
# %X  X%*   these are also specifically optimized

sub kglob2re {
  local( $glob )= @_;
  local( $re )= "^";
  local( $quote, $bracket, $brace, $slash );
    # Optimize special cases:
    return( "^[^/]?" )
       if  $glob =~ m-\{\?\*/?%/?\*,\*\}-	# {?*/%/*,*}	-> ^[^/]
       ||  $glob =~ m-\{\*,\?\*/?%/?\*\}-;	# {*,?*/%/*}	-> ^[^/]
    for(  split( //, $glob )  ) {   # Go through glob pattern 1 char at a time:
	$slash--   if  $slash;		# Was a / appended to $re last time?
	if(  $quote  ) {		# Was the last character \ ?
	    $re .= $_;				# Don't interpret this character
	    $quote= 0;				# Don't quote next char too
	} elsif(  '\\' eq $_  ) {	# Is this character a \ ?
	    $re .= $_;
	    $quote= 1;				# Quote next character
	} elsif(  $bracket  ) {		# Are we still inside a [...] ?
	    if(  1 == $bracket  &&  "^" eq $_  ) {
		$bracket= 2;
	    } else {
		if(  2 == $bracket  ) {
		    if(  "-" eq $_  ) {
			$re .= "-";		# [^-...]	-> [^-/...]
			$_= "/";		# (avoid [^-z] -> [^/-z])
		    } else {
			$re .= "/";		# [^...]	-> [^/...]
		    }
		}
		$bracket= 3;
	    }
	    $re .= $_;
	    $bracket= 0   if  "]" eq $_;	# Unquoted ] ends a [...]
	} elsif(  "[" eq $_  ) {	# Start a [...]:
	    $re .= $_;
	    $bracket= 1;
	} elsif(  "?" eq $_  ) {
	    $re .= ".";
	} elsif(  "{" eq $_  )	# }	# Start an {X,Y}:
	{			# ^ so % works in vi
	    $re .= "(";				# {X,Y} -> (X|Y)
	    $brace++;				# Remember how many started
	} elsif(  "," eq $_  ) {	# Inside a {X,Y}, comma -> | ...
	    $re .= $brace ? "|" : "\\,";	# else comma -> \, (to be safe)
	}	# {
	elsif(  "}" eq $_  ) {
	    if(  $brace  ) {		# Completed an {X,Y}
		$re .= ")";
		$brace--;
	    } else {	# { <- so % works in vi
		$re .= "\\}";	# { {
		warn "Unquoted, unmatched `}' will be treated as `\\}'\n";
	    }
	} elsif(  /\s/  ) {		# Quote white space to avoid warning
	    warn qq-Unquoted white space in file glob pattern: "$glob"\n-;
	    $re .= $_;			# else I assume it is an accident
	} elsif(  "*" eq $_  ) {	# * won't match /
	    $re .= "[^/]*";			# * -> [^/]*
	} elsif(  "/" eq $_  ) {
	    $re .= $_   unless  $slash;		# // -> /  and  %/ -> %
	    $slash= 2;				# So we know next time
	} elsif(  "%" eq $_  ) {
	    if(  $slash  ) {		# Check this because....
		$re .= "(|.*/)";	# (don't include another leading /)
	    } elsif(  "^" eq $re  ) {	# .../%X is different than %X
		$re= "(^|/)";		# %[/]X	-> ^(|.*/)X$ -> (^|/)X$
	    } else {
		$re .= "/(|.*/)";	# X[/]%[/]Y	     -> ^X/(|.*/)Y$
	    }
	    $slash= 2;			# Don't include an extra tailing slash
	} elsif(  /\w/  ) {		# Any letter, number, or _ :
	    $re .= $_;				# stays the same
	} else {			# Any other symbol, quote it:
	    $re .= "\\" . $_;		# Includes ' so m'...' works.
	}
    }
    if(  $quote  ||  $bracket  ||  $brace  ) {
	warn "Unexpected end of file glob pattern: $glob\n";
	return undef;
    }
    if(  $re !~ s-$NOQT/\(\|,\.\*/\)$-\1/-  ) {		# X/%*	-> ^X/
	$re .= '$';
    } elsif(  "" eq $re  ) {	# Since m// means something else:
	$re= "^";									# %/*	-> anything
    }
    $re;
}

package main;

require File::Basename;  import File::Basename qw(basename);

if(  &basename( $0 )  eq  &basename( __FILE__ )  ) {
    # Use `find ... -print | KGlob2RE.pm "pattern" [...]' to use as pipe or test
eval <<'EXAMPLE';
    import File::KGlob2RE qw(&kglob2re);
    sub quote {  local($*)= 1;  $_[1] =~ s/^$_[0]//g;  $_[1];  }
    if(  0 == @ARGV  ) {
	die &quote( "\t*:\t", <<"	;" ), "\n"; 
	:	Usage: KGlob2RE.pm [-e] { "pattern" | -f file } [...]
	:	Examples:
	:	    find . -print | KGlob2RE.pm "%*.c" | xargs grep -i "boogers"
	:	    \\ls | KGlob2RE.pm "*.dat *.idx" | xargs chmod ug=rw,o=r
	:	Note that if only one argument is given and it contains one or
	:	more spaces, then it is split into several patterns because
	:	just using one set of quotes (") for the whole list is usually
	:	much easier.  This splitting is *not* done if two or more
	:	arguments are given.  "-f file" reads patterns, one per line,
	:	from the specified file (trailing spaces, #-comments, and
	:	blank lines in the file are ignored).  Patterns begining with
	:	"!" exclude matching files.  "-e" causes exceptions (files
	:	neither explicitly matched nor excluded) to generate a message
	:	on STDERR noting this.
	;
    }
    if(  "-e" eq $ARGV[0]  ) {
	$Warn= 1;
	shift( @ARGV );
    }
    if(  1 == @ARGV  &&  index($ARGV[0],' ')  ) {
	@ARGV= split( ' ', $ARGV[0] );
    }
    if(  @ARGV < 2  ) {			# Simpler example using single pattern:
	$re= &kglob2re( $ARGV[0] );
	while(  <STDIN>  ) {		# For each file name read from stdin:
	    chop;			# Take off the trailing newline
	    $_ .= "/"   if  -d $_  &&  ! m-/$-;	# Put / on end of dir names
	    if(  m/$re/o  ) {
		print "$_\n";		# Only print names matching pattern
	    } elsif(  $Warn  ) {
		warn "File $_ unmatches by any pattern.\n";
	    }
	}
    } else {
	while(  @ARGV  ) {
	    $_= shift( @ARGV );
	    if(  /^-f/  ) {
		if(  "" eq ( $_= substr($_,2) )  ) {
		    @ARGV  ||  die "Required file name missing after -f.\n";
		    $_= shift( @ARGV );
		}
		open( PAT, "<$_" )
		  ||  die "Can't read patterns from $_: $!\n";
		push(  @pats,  grep( (chop,s=\s*#.*==,length), <PAT> )  );
		close( PAT );
	    } else {
		push( @pats, $_ );
	    }
	}
	for(  @pats  ) {
	    if(  /^!/  ) {
		$if .= "\treturn 0 if m'" . &kglob2re(substr($_,1)) . "'o;\n";
	    } else {
		$if .= "\treturn 1 if m'" . &kglob2re($_) . "'o;\n";
	    }
	}
	eval "sub matches {\n$if\t-1; }";
	while(  <STDIN>  ) {
	    chop;
	    $_ .= "/"   if  -d $_  &&  ! m-/$-;
	    $re= &matches;
	    if(  1 == $re  ) {
		print "$_\n";
	    } elsif(  $Warn  &&  -1 == $re  ) {
		warn "File $_ unmatched by any pattern.\n";
	    }
	}
    }
EXAMPLE
chop $@;   die $@   if $@;
}

#Technical notes:
# 
# Items were listed in order of precedence.  For example:  \[ matches [;  ?, *,
# %, and { have no special meaning within [...];  \x within [...] matches x so
# [\][] matches [ or ];  all, including {X,Y}, can be used within {X,Y}.
#
# % will match / or /.../.  If % is the first character of a pattern, it will
# also match the empty string.  For sanity, /%/, /%, and %/ are equivalent to %
# except that this will not cause % to be considered as the first character in
# a pattern.  So "/%/X" and "/%X" will match "/X" but not "X" (which is good).
#
# Note that {} and % interfere in the following ways:  A % inside {} is never
# considered as being the first character of a pattern, even when it probably
# should be;  If /'s or %'s (but not both) are nested in {} they will not be
# treated as adjacent and so the (possibly redundant) / will not be removed,
# even when it probably should be removed.
#
# Hint:  If you have "/" appended to all directory file names, patterns ending
# in "/" will only match directory names.  A % at the end of a pattern will
# never match unless you do this.
#
# You can use
#	m/$re/[o]
# or
#	eval "m'" . $re . "'"
# But other choices may not work.  For example,
#	eval "m/" . $re . "/"
# won't because I don't bother to quote /'s.  And
#	eval 'm"' . $re . '"'
# risks interpretation of $ in unexpected ways (I think).

1;
