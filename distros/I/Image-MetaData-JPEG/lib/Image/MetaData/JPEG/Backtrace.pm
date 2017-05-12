###########################################################
# A Perl package for showing/modifying JPEG (meta)data.   #
# Copyright (C) 2004,2005,2006 Stefano Bettelli           #
# See the COPYING and LICENSE files for license terms.    #
###########################################################
package Image::MetaData::JPEG::Backtrace;
use strict;
use warnings;

###########################################################
# The following variables belong to the JPEG package.     #  
# They are used as global switches for selecting          #
# backtrace verbosity in various situations:              #
#   $show_warnings --> if false, warnings should be muted #
###########################################################
{ package Image::MetaData::JPEG;
  our $show_warnings = 1; }

###########################################################
# This is a private customisable function for creating an #
# error (or warning) message with the current stack trace #
# attached. It uses additional information returned by    #
# the built-in Perl function 'caller' when it is called   #
# from within the 'DB' package (is this dangerous?).      #
# ------------------------------------------------------- #
# To be used by JPEG, JPEG::Segment, JPEG::Record ...     #
###########################################################
sub backtrace {
    my ($message, $preamble, $obj, $prefix) = @_;
    # a private function for formatting a line number and a file name
    my $format = sub { " [at line $_[0] in $_[1]]" };
    # get a textual representation of the object
    my $objstring = defined $obj ? "$obj" : '<no object>';
    # get the prefix in the package name (before the last ::);
    # this variable can be overridden by the caller
    ($prefix = $objstring) =~ s/^(.*)::[^:]*$/$1/ unless $prefix;
    # write the user preamble (e.g., 'Error' or 'Warning') as well as
    # the object's textual representation at the beginning of the output
    my @stacktrace = ("$preamble [obj $objstring]");
    # we assume that this function is called by a "warn" or "die"
    # method of some package, so it does not make sense to have
    # less than two stack frames here.
    die "Error in backtrace: cannot backtrace!" unless caller(1);
    # detect where this function was called from (the function name is
    # not important, maybe "warn" or "die"); use this info to format a
    # "0-th" frame with the error message instead of the subroutine name
    my (undef, $filename, $line) = caller(1);
    push @stacktrace, "0: --> \"$message\"" . &$format($line, $filename);
    # loop over all frames with depth larger than one
    for (my $depth = 2; caller($depth); ++$depth) {
	# get information about this stack frame from the built-in Perl
	# function 'caller'; we need to call it from within the DB package
	# to access the list of arguments later (in @DB::args).
	my @info = eval { package DB; caller(1+$depth) };
 	my @arguments = @DB::args;
	# create a string with a representation of the argument values;
	# undefined values are rendered as 'undef', non-numeric values
	# become strings, non-printable characters are translated.
	for (@arguments) { $_ = 'undef' unless defined;
			   s/[\000-\037\177-\377]/sprintf "\\%02x",ord($&)/eg;
			   s/^(.*)$/'$1'/ unless /^-?\d+\.?\d*$/ || /undef/; }
	my $args = join ', ', @arguments;
	# extract subroutine names, line numbers and file names
	my (undef, $filename, $line, $subroutine) = @info;
	# detect the case of an eval statement
	my $iseval = $subroutine eq '(eval)' ? 1 : undef;
	# create a line for this stack frame; this contains the subroutine
	# name and its argument values (exception made for eval statements,
	# where the arguments are meaningless) plus the call location.
	push @stacktrace, ($depth-1) . ": " . 
	    ($iseval ? '(eval statement)' : "$subroutine($args)") .
	    &$format($line, $filename); }
    # rework the object representation for inclusion in a regex
    $objstring =~ s/([\(\)])/\\$1/g;
    # replace $this with 'self' and take out the package prefix
    # (try not to touch the first line, though).
    for (@stacktrace) {	s/'$objstring'/self/g;
			s/$prefix:{2}//g unless /\[obj .*\]/; }
    # returne all lines joined into one "\n"-separated string + bars
    return join "\n", ('='x78, @stacktrace, '='x78, '');
}

# successful package load
1;
