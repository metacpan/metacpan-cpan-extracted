# -*- mode: perl -*-

package MRTG::Config;

# Copyright (c) 2007 Stephen R. Scaffidi <sscaffidi@cpan.org>
# All rights reserved.

# This program is free software; you may redistribute it and/or modify it
# under the same terms as Perl itself.

use 5.008008;
use strict;
use warnings;

#---------------------------------------------------------#
# Version
#---------------------------------------------------------#

our $VERSION = '0.04';


#---------------------------------------------------------#
# Exporter stuff - I don't think I need this tho.
#---------------------------------------------------------#

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MRTG::Config ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();


#---------------------------------------------------------#
# Dependencies
#---------------------------------------------------------#

use File::Spec;
use File::Basename;
use DBM::Deep;


#---------------------------------------------------------#
# Declarations for methods with checked-args
# (sometimes I like those)
#---------------------------------------------------------#

sub loadparse($);
sub target($);
sub targets();


#---------------------------------------------------------#
# Constructor et. al.
#---------------------------------------------------------#

# If you specify a filename as an argument, you don't have 
# to call loadparse separately.
sub new 
{
	my $class = shift;
	my $self  = {};
	
	$self->{DEBUG}       = 0;   # Debugging output level.
	
	# These hold the parsed data.
	$self->{GLOBALCFG}   = {};  # MRTG global config options
	$self->{TGTDEFAULTS} = {};  # Config options for the _ target are 
                                #  treated as if they were defined for all
                                #  targets unless explicitly overridden.
	$self->{TARGETS}     = {};  # Per-target config options.
	
	$self->{CONFIGLINES} = [];  # A list of arrays with info about each 
	                            # 'useful' line in the config file(s)
	                            # NOT persisted yet. See 
								# comments in _persist_on()
								
	$self->{FIRST_FILE} = ""; # The first config file loaded.
	                          # May be useful. (it is for me!)
	
	$self->{TGTCFG_MAP} = {}; # A hash that maps target names to
	                          # the config file they came from.
							  # I'm using this to keep the 
							  # TARGETS hash 'pure'

	# These are used if we turn on persistience:
	$self->{PERSIST_DB}   = undef; # Handle to the DBM DB.
	$self->{PERSIST_FILE} = "";    # File to store the DBM DB.							  
	
	bless ($self, $class);
	
	# If an argument is specified, try to load and parse it as an MRTG config file.
	if (@_) { $self->loadparse(shift) };
	
	return $self;
}


#---------------------------------------------------------#
# Public methods
#---------------------------------------------------------#

#Loads and parses the given MRTG config file.
sub loadparse($)
{
    my $self = shift;
	$self->{FIRST_FILE} = shift;
    return $self->_parse_cfg_file($self->{FIRST_FILE});
}

#---------------------------------------------------------#

# Just for debugging for now - returns a list of references
# to the hashes that make up the parsed data, et. al.
sub rawdata
{
	my $self = shift;
	return (
		$self->{GLOBALCFG}, 
		$self->{TGTDEFAULTS}, 
		$self->{TARGETS},
		$self->{CONFIGLINES},
		$self->{FIRST_FILE},
		$self->{TGTCFG_MAP},	
		);
}

#---------------------------------------------------------#

# Toggles persistience - 
# Using a true value turns persistience on 
#   - return value is boolean for success.
# Using a false value turns it off
#   - return value is boolean for success.
# Using no argument returns boolean for status.
sub persist
{
	my $self = shift;
	return $self->{PERSIST_DB} ? 1 : 0 unless @_;
	if (shift) 
	{
		return $self->_persist_on();
	}
	else
	{
		return $self->_persist_off();
	}
	die 'WTF? This should *never* happen!';
}

#---------------------------------------------------------#

# Returns a reference to the specified target's config hash,
# undef if it does not exist. I may change it to {} though,
# depending on how a loop might best be written.
sub target($) 
{
	my $self = shift;
	my $tgtId = shift;
	return exists $self->{TARGETS}{$tgtId} ? \$self->{TARGETS}{$tgtId} : undef ;
}

#---------------------------------------------------------#

# Returns a list of ALL available target names. (NOT their hashes)
sub targets() 
{
	my $self = shift;
	return (keys %{$self->{TARGETS}});
}

#---------------------------------------------------------#

# Returns the name of the config file containing the 
# directives for the specified target. If no target is
# specified, returns the 'original' file, the one specified
# to new() or loadparse(). Returns undef if the specified 
# target does not exist;
sub cfg_file 
{
	my $self = shift;
	return $self->{FIRST_FILE} unless @_;
	return $self->{TGTCFG_MAP}{+shift};
}

#---------------------------------------------------------#

# Returns a reference to a hash of the global MRTG directives
# from the specified file. If no file specified, returns the 
# globals from the first file. Returns undef if the specified 
# file is not found;
sub globals 
{
	my $self = shift;
	return $self->{GLOBALCFG}{$self->{FIRST_FILE}} unless @_;
	return $self->{GLOBALCFG}{+shift};
}

#---------------------------------------------------------#

# Sets or gets the file to be used for the persistience DBM DB.
# If setting, returns the previous value. If there was no 
# previous value, returns "".
sub persist_file
{
	my $self = shift;
	my $file = $self->{PERSIST_FILE};
	$self->{PERSIST_FILE} = shift if @_;
	return $file; 
}


#---------------------------------------------------------#
# Private methods
#---------------------------------------------------------#

# Initialize the DBM DB and store the MRTG data in it.
# Make the Class member hashes point to the apropriate
# locations in the DB. Return true on success, undef on failure.
# I thought about calling die on failure, but I've repented
# and decided to simply return undef. Failure can be handled
# somewhere higher up in the code, since it's not fatal to
# the usage of this module!
sub _persist_on
{
	my $self = shift;
	#use DBM::Deep;
	$self->{PERSIST_DB} = 
		new DBM::Deep($self->{PERSIST_FILE})
		|| return undef;
		
	my $persist_db = $self->{PERSIST_DB};
	
	# We really shouldn't persist $self->{CONFIGLINES} -- 
	# especially before loading the MRTG config. I do some
	# nasty stuff to that array and DBM::Deep doesn't like
	# it very much at all. ;)
	# Also, there's really no need to persist 
	# $self->{TGTDEFAULTS}, AFAICS.

        $self->_link_db_hash($persist_db, $_) 
           for qw(GLOBALCFG TARGETS TGTCFG_MAP);

        $persist_db->{FIRST_FILE} = "" unless exists $persist_db->{FIRST_FILE};
        $persist_db->{FIRST_FILE} = $self->{FIRST_FILE} if $self->{FIRST_FILE};
        $self->{FIRST_FILE} = $persist_db->{FIRST_FILE};

	return 1;
}

sub _link_db_hash
{
    my $self = shift;
    my $persist_db = shift;
    my $hashName = shift;
    
    my $selfHashRef = $self->{$hashName};
    
    # Bless our humble hash - exists line just added... needs to be tested.
	$persist_db->{$hashName} = {} unless exists $persist_db->{$hashName};
	
	# Import the data... DBM::Deep will call die() if something goes wrong.
	$persist_db->{$hashName} = $self->{$hashName}  if %$selfHashRef;
	
	# Now, swap our pointers!
	$self->{$hashName} = $persist_db->{$hashName};
	
    return 1;    
}


#---------------------------------------------------------#

# Turns off persistience, at least it would if I wrote the 
# code to do it... dies right now.
sub _persist_off
{
	die "Feature not implemented (Yet!)\n";
}

#---------------------------------------------------------#

# Parses the directives from the MRTG config file, 
# loading and parsing any Included files along the way.
# Populates the Class hash vars GLOBALCFG, 
# TGTDEFAULTS, and TARGETS. Returns 1. Dies if 
# anything goes wrong.
sub _parse_cfg_file
{
    my $self = shift;
    my $mainCfgFileName = shift;

    # Grab the directives from the first config file
    my $directiveLines = $self->_read_cfg_file($mainCfgFileName);
    push @{$self->{CONFIGLINES}}, @$directiveLines;
	$directiveLines = $self->{CONFIGLINES};
	
	# We want to keep track of the current file, as well as the first one, in case we have to deal with Includes.
	my $curCfgFileName = $mainCfgFileName;
    
    # These references may change depending on which file we're in.
    $self->{GLOBALCFG}{$curCfgFileName} = {};
    my $Global = $self->{GLOBALCFG}{$curCfgFileName};        
    my $TgtDefaults = $self->{TGTDEFAULTS}{$curCfgFileName};        

    
    # Using a for-loop to force the condition check on each 
    # iteration -- If we encounter an Include directive additional 
    # lines could be inserted into @$directiveLines, changing it's
    # size! 
    for (my $idx = 0; $idx <= $#$directiveLines; $idx++)
    {
        my $line = $directiveLines->[$idx];
        my $lineText = $line->[0];
        my $lineNum  = $line->[1];
        my $lineFile = $line->[2];
    
		
        # Parse the basic directive and value from the line
        $lineText =~ /\s*(.*?)\s*:\s*(.*)\s*/s;
        my $directive = $1;
        my $value = $2;
    
    
        # If the regex didn't match both, something's wrong.
        unless (defined $directive and defined $value)
        {
            warn "Error parsing line $lineNum:\n";
            warn "$lineText\n";
            die "LOLDEAD\n";
        }
             
        # If the directive is an Include directive, we've got 
        # some _special_ work to do...
        if (lc($directive) =~ /^include$/) 
        {
            my $incFileName = $value;
            print "Include directive found: $incFileName\n" if $self->{DEBUG} > 1;
            unless (File::Spec->file_name_is_absolute($incFileName))
            {
				# Try to find the included file using the same logic
				# that MRTG_lib uses (according to the docs)
                my (undef,$mainCfgFileBaseDir,undef) = fileparse($mainCfgFileName);
                my $baseDirPath = File::Spec->catfile($mainCfgFileBaseDir, $incFileName);
                my $curDirPath = File::Spec->catfile(File::Spec->curdir(), $incFileName);
                print "Possible include locations:\n" if $self->{DEBUG} > 2;
                print "  $baseDirPath\n" if $self->{DEBUG} > 2;
                print "  $curDirPath\n" if $self->{DEBUG} > 2;
                print "  $incFileName\n" if $self->{DEBUG} > 2;
                if (-e $baseDirPath) { $incFileName = $baseDirPath }
                elsif (-e $curDirPath) { $incFileName = $curDirPath } 
            }
			# Did we find it? Load it up and insert the included lines into the queue!
            my $includeLines = $self->_read_cfg_file($incFileName);
            splice @$directiveLines, $idx+1,0, @$includeLines;

			# Update the current file, and our data references.
			$curCfgFileName = $value;
			$self->{GLOBALCFG}{$curCfgFileName} = {};
			$Global = $self->{GLOBALCFG}{$curCfgFileName};
			$self->{TGTDEFAULTS}{$curCfgFileName} = {};        
			$TgtDefaults = $self->{TGTDEFAULTS}{$curCfgFileName}; 
            next;
        }
        
        
        
        # Determine the type of directive: Global, Target, or TgtDefaults
        # Then store it and it's value in the proper place.
        if ($directive =~ /\[_\]$/)  # TgtDefaults directive
        {
            $directive =~ s/\[_\]//;
            $TgtDefaults->{lc($directive)} = $value;
        }    
        elsif ($directive =~ /\[.*\]$/) # Target directive
        {
            # Target-specific directives contain the directive name ($dname)
            # and the target name ($tname). The code for parsing this is a 
            # little longer than I like to put in an if-block.
            my ($dname, $tname) = $self->_parse_directive_name($directive);
            
            # Just to get them out of the way, and hopefully better simulate
    	    # The 'Official' MRTG code, let's apply any known TgtDefaults
			# directives to the current Target
    	    while (my ($tdDname, $tdValue) = each %$TgtDefaults)
    	    {
    	        # Don't clobber directives that were already set.
    	        $self->{TARGETS}{$tname}{$tdDname} = $tdValue unless 
    	           exists $self->{TARGETS}{$tname}{$tdDname};
    	    }
            
            # If we want to have any special handling of the data in $value
    	    # based on the Directive name or any other accessible criterion,
			# here's where it would be done. (by calling another subroutine,
			# of course. Keep the code clean... as much as possible...)
			$value = $self->_process_td_value($value, $dname, $tname, $line);
    	    
    	    $self->{TARGETS}{$tname}{$dname} = $value;
			
			# If the same target is listed in more than one file, that's just tough.
			$self->{TGTCFG_MAP}{$tname} = $curCfgFileName 
				unless exists $self->{TGTCFG_MAP}{$tname};
        }
        elsif ($directive !~ /\[/) # Global directive
        {
            $Global->{lc $directive} = $value;
        }
        elsif ($directive =~ /\[\^\$\]$/) # pre and post - see MRTG docs.
        {
            # I don't know what to do with these so I'll just do nothing.
        }
        else  # Something else? That's not right.
        {
            warn "Invalid directive name at line $lineNum: $directive\n";
            die "LOLDEAD\n";
        }
    }
    return 1;
}

#---------------------------------------------------------#

# If we need to sanity-check or otherwise validate or process
# directives, and it can be done on the first pass through the
# config files, this is where it's done.
sub _process_td_value
{   
	my $self = shift;
	my ($value, $dname, $tname, $line) = @_;
	#use Data::Dumper;
	#print Dumper($value, $dname, $tname, $line); exit;
	return $value;
}

#---------------------------------------------------------#

# Opens the specified file and returns a reference to an
# array of MRTG config directives from it's contents.
# The returned data structure will be a two-level array...
# Each sub-array is two elements, the first being the line 
# number of the beginning of the directive in the file, 
# and the second being the directive and data as a string.
sub _read_cfg_file 
{
    my $self = shift;

    # Open the specified file.
    my $cfgFileName = shift ||
        die "You need to specify the path to an MRTG cfg file.\n"; 
    
    
    
    my $cfgFh;
    open $cfgFh, "<$cfgFileName" ||
        die "Couldn't open $cfgFileName for read access.\n";
    # TODO This doesn't die on win32... is it broke on Linux, too? ...yep.
        
        
    my $lineCount = 0;           # How many lines in the file
    my $directiveLineCount = 0;  # How many lines used by directives
    my @directiveLines = ();     # Each element in this array is a 
                                 #  directive, which may span more 
                                 #  than one line (separated by \n)
	
	
    # Read in the file, parsing out all the MRTG directives
    # irregardles of validity... we're assuming that they're 
    # valid since these are the same config files MRTG is 
    # already using for polling. 
    while (<$cfgFh>)
    {
    	$lineCount++;
    
    	# Ignore blank and comment lines.
    	next if /^\s*$/;
    	next if /^\s*#/;
    	
    	my $line = $_;
    	
    	# If this line begins with whitespace append it to the previous line.
    	# I'm not sure how perl will handle it if there are no previous lines!
    	if ($line =~ /^\s+/)
    	{
    	   $directiveLines[-1][0] .= $line;
    	} 
    	else
    	{
    	    push @directiveLines, [$line,$lineCount,$cfgFileName];
			
    	}
    	$directiveLineCount++;
    }
    
    close $cfgFh;
    
    # Clean up those messy trailing new-lines.
    chomp $_->[0] for @directiveLines;
    
    print "Loaded file: $cfgFileName\n" if $self->{DEBUG} > 1;
    print "  Total lines: $lineCount\n" if $self->{DEBUG} > 1;
    print "  Directives found: $#directiveLines\n" if $self->{DEBUG} > 1;
    print "  Directive lines: $directiveLineCount\n" if $self->{DEBUG} > 1;
    print "  Ignored lines: " . ($lineCount - $directiveLineCount) . "\n" if $self->{DEBUG} > 1;
    
    return \@directiveLines;
}

#---------------------------------------------------------#

# Parse the directive name and the target name out of a 
# 'raw' Target-specific directive string. Returns the 
# directive and target names as a two-element list.
sub _parse_directive_name 
{
    my $self = shift; 
    my $directive = shift;
    
    # Parse the Target and Directive names from $directive
    $directive =~ /(.*)\[(.*)\]/;
    my $dname = lc $1;
    my $tname = lc $2;
    
    # If the regex didn't match both, something's wrong.
    unless ($dname and $tname)
    {
        warn "Error parsing Target and Directive names from:\n";
        warn "$directive\n";
        die "LOLDEAD\n";
    }
    
    return ($dname, $tname);
}

#---------------------------------------------------------#



1;
__END__


=head1 NAME

MRTG::Config - Perl module for parsing MRTG configuration files

=head1 WARNING

This module, while reliable right now, is still in ALPHA stages
of development... The API/methods may change. Behaviors of 
methods will almost certainly change. The internal structure of
data will change, as will many other things.

I will try to always release 'working' versions, but anyone who expects
their code that uses this module to continue working shouldn't... until
I remove this warning.

=head1 SYNOPSIS

Ever have the need to parse an MRTG config file? I have. I needed
to parse lots and lots of them. Using the functions built-in to 
C<MRTG_lib> was too slow, too complex, and used too much RAM and CPU 
time for my poor web server to handle - and the data structures
C<MRTG_lib> built were I<way> more complex than I needed.

MRTG::Config can load and parse MRTG and MRTG-style confiuguration 
files very quickly, and the parsed directives, targets and values
can be located, extracted, and manipulated through an OO interface.

This module is intended to focus on correctly parsing the I<format>
of an MRTG configuration, regardless of whether or not the directives
and values, etc. are I<valid> for MRTG. I am using both the parsing
behavior of C<MRTG_lib>'s C<readcfg()> function and the description of the
format on the MRTG website as my guidelines on how to correctly parse
these configuration files. I am still a short way off that goal, but
this module is currently being used in a production environment with
great success!

=head1 PLEA FOR MERCY

I plan on adding to this documentation and making it better 
organized soon, but I'm willing to answer questions directly 
in the mean time. Also, this is my first module, written in 
a hurry to appease some disgruntled engineers. I I<do> plan on
continuing to improve it, so any input, positive I<or> negative
is certainly welcome!

=head1 USAGE EXAMPLE

  use MRTG::Config;

  my $cfgFile = 'mrtg.cfg';
  my $persist_file = 'mrtg.cfg.db'; 
  
  my $mrtgCfg = new MRTG::Config;
  
  $mrtgCfg->loadparse($cfgFile);
  
  # Want to store the parsed data for use later or by
  # another program?
  $mrtgCfg->persist_file($persist_file);
  $mrtgCfg->persist(1);
  
  foreach my $tgtName (@{$mrtgCfg->targets()}) {
    my $tgtCfg = $mrtgCfg->target($tgtName);
    # Let's assume every target has a Title.
	print $tgtCfg->{title} . "\n"; 
  }
  
  # globals() has some, um, interesting things you
  # should know. Please read about it below... 
  my $globalCfg = $mrtgCfg->globals();

  # Let's assume WorkDir is set.
  print $globalCfg->{workdir} . "\n"; 


=head1 DETAILED DESCRIPTION -or- LOTS OF WORDS ABOUT A LITTLE MODULE

I couldn't find any modules on CPAN that would parse MRTG config files,
and Tobi's code in C<MRTG_lib> is too slow and too complicated for my needs.

This module will load a given MRTG configuration file, following Include
statements, and build a set of hashes representing the confiration 
keywords, targets, and values.

It's _much_ faster than Tobi's code, but it also does not build a data
structure I<nearly> as deep and complex.

It B<does>, however, properly handle a number of facilities of the MRTG 
configuration file format that are specified in the MRTG documentation.

=head2 Multi-Line Values

The parsing code correctly handles directives where the value spans 
multiple lines (sucessive lines after the first begin with whitespace).
Each line of the value is contatenated together, including newlines.

=head2 Include Directives

Include directives are also handled. When an Include is encountered, the
value is used as the name of another MRTG configuration file to parse.
Like in C<MRTG_lib>, if the path is not absolute (beginning with / or C:\
or whatever your system uses) this file is looked for first in the same
directory as the original configuration file, and then in the current
working directory.

When an Included file is loaded, it's lines are inserted into the current 
position in the parsing buffer and then parsing continues, as if the 
contents of the included file were simply copied into that position in 
the original file.

While I have not yet tested it, I believe 'nested' includes are followed,
and the same search and loading rules apply. The path of the I<first>
config file is I<always> used when looking for included files.

B<WARNING:> There is B<no> loop-checking code. If File A includes File B and
File B includes File A, the parser will run until your system goes B<p00f>,
eating up memory the whole way.

=head2 The [_] Target

This module understands directives for the [_] (default) target and will
interpolate these directives into all the targets that follow the 
definition of a [_] directive and do not explicitly define the given 
directive.

From what I can tell, in Tobi's implementation, [_] directives are only 
applied to targets that follow the definition of that particular directive.
This module does likewise. Also, if a [_] directive is redefined later in
the configuration, it's new value is used for all future targets. Targets
that have already had that directive interpolated are B<not> updated.

For configs that use includes to span multiple files, definitions for the
[_] target go 'out of scope' when parsing new files. This is buggy behavior
that will soon be fixed, or become adjustable.

=head2 Duplicate Directives and Targets

WARNING: I don't remember if this is the behavior C<MRTG_lib> applies. I need 
to revisit the code and docs.

If a particular target has a directive or directives defined more 
than once, the last definition in the file 'wins'. The same applies to 
the [_] target, and also to global directives. HOWEVER: globals and [_]
definitions go 'out of scope' when another cfg file is included. Again,
this is buggy behavior that will soon be fixed, or become adjustable.

=head2 Persistience

This module is capable of some degree of persistience, by way of L<DBM::Deep|DBM::Deep>.
Using persistience will allow you to do all sorts of interesting things, 
which I will not get into right now, but if you're creative I'll bet you've
already thought of some! Right now, only Global and target-specific 
directives are persisted.

=head3 Performance

Please note - I've found that performance with DBM::Deep varies WIDELY 
depending on what version of DBM::Deep you are using, and whether or 
not you allow cpan to upgrade it's dependencies - When I allowed cpan
to update everything, performance dropped by AN ORDER OF MAGNITUDE.

For best performance, I suggest using L<DBM::Deep|DBM::Deep> .94 and whatever 
versions of various core modules that come with Perl 5.8.8.

=head2 Testing (or lack thereof)

Most of my testing has been done on a stock Ubuntu 7.04. Some 
testing has been done on Windows XP SP2 with ActiveState Perl 5.8.8.

I'll try to write some more about my tests when I do some better testing.

=head1 METHODS

=head2 targets()

Returns a list of the names of MRTG targets in the parsed config.

  my @targetNames = $mrtgCfg->targets();

=head2 target()

Returns a reference to a hash of config directives for a specific Target,
given it's name in lower-case.

  my $tgtCfg = $mrtgCfg->target($tgtName);
  print $tgtCfg->{maxbytes};

=head2 cfg_file()

Returns the name of the loaded config file. In the case of Configs using
Includes, returns the name of the B<first> config file.

  my $cfgFile = $mrtgCfg->cfg_file();
  print $cfgFile;

If you are using Includes... you may want to know in which file a specific
target was defined. You do that by passing in the name of the target, in
lower-case.

  my $tgtCfgFile = $mrtgCfg->cfg_file($tgtName);
  print $tgtCfgFile;

NOTE: If directives for a target were specified in more than one file, the 
one that the target was specified in FIRST is the one returned.

=head2 globals()

Returns a reference to a hash of Global config directives

  my $cfgGlobals = $mrtgCfg->globals();
  print $cfgGlobals->{workdir};

If there were included files, the above code currently returns the globals
found ONLY in the first, original file. If you want the globals found in an
Included file, pass the name of that file (the value used in the Include 
directive that caused it to be loaded) as an argument:

  my $incFileGlobals = $mrtgCfg->globals($fileName);
  print $incFileGlobals->{workdir};
 
I'm fairly certain this behavior is NOT true to how MRTG operates, but it's
what currently best serves my needs... I do plan on making alterations to
support the correct behavior in a future update.


=head1 SUPPORT

Please email me if you have B<any> questions, complaints, comments, 
compliments, suggestions, requests, patches, or alcoholic beverages 
you'd like to share. The more feedback I can get, the better I can
make this module!

Please make note, though - I can not be held responsible for any 
problems that bugs in this module or it's dependencies may cause.
That being said, I'll do my best to prevent that possibility.

=head1 EXPORT

Nothing by default.

=head1 TO-DO

1. Fix bugs
2. Fix bugs.
3. Eat a sandwich.
4. Clean up code (stupid editor breaks my indentation)
5. Clean up code (stupid me writes some sloppy perl)
6. goto 1

Also - I need to start writing tests. This release (0.03) is currently un-tested.

=head1 SEE ALSO

http://oss.oetiker.ch/mrtg/ or http://www.mrtg.org/

L<DBM::Deep|DBM::Deep>

=head1 AUTHOR

Stephen R. Scaffidi (sscaffidi@cpan.org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Stephen R. Scaffidi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
