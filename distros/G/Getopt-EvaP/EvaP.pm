$Getopt::EvaP::VERSION |= '2.8';

package Getopt::EvaP; 

# EvaP.pm - Evaluate Parameters for Perl (the getopt et.al. replacement)
#
# Stephen.O.Lidie@Lehigh.EDU, 94/10/28
#
# Made to conform, as much as possible, to the C function evap. The C, Perl
# and Tcl versions of evap are patterned after the Control Data procedure
# CLP$EVALUATE_PARAMETERS for the NOS/VE operating system, although none
# approach the richness of CDC's implementation.
#
# Availability is via anonymous FTP from ftp.Lehigh.EDU in the directory
# pub/evap/evap-2.x.
#
# Stephen O. Lidie, Lehigh University Computing Center.
#
# Copyright (C) 1993 - 2014 by Stephen O. Lidie.  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
#
# For related information see the evap/C header file evap.h.  Complete
# help can be found in the man pages evap(2), evap.c(2), EvaP.pm(2), 
# evap.tcl(2) and evap_pac(2).

require 5.002;
use Text::ParseWords;
use subs qw/evap_fin evap_parse_command_line evap_parse_PDT evap_PDT_error
    evap_set_value/;
use strict qw/refs subs/;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/EvaP EvaP_PAC/;
@EXPORT_OK = qw/evap evap_pac/;

*EvaP = \&evap;			# new alias for good 'ol Evaluate Parameters
*EvaP_PAC = \&evap_pac;		# new alias for Process Application Commands

sub evap {			# Parameter Description Table, Message Module

    my($ref_PDT, $ref_MM, $ref_Opt) = @_;
    
    $evap_DOS = 0 unless defined $evap_DOS; # 1 iff MS-DOS, else Unix

    local($pdt_reg_exp1) = '^(.)(.)(.?)$';
    local($pdt_reg_exp2) = '^TRUE$|^YES$|^ON$|^1$';
    local($pdt_reg_exp3) = '^FALSE$|^NO$|^OFF$|^0$';
    local($pdt_reg_exp4) = '^\s*no_file_list\s*$';
    local($pdt_reg_exp5) = '^\s*optional_file_list\s*$';
    local($pdt_reg_exp6) = '^\s*required_file_list\s*$';
    local($full_help) = 0;
    local($usage_help) = 0;
    local($file_list) = 'optional_file_list';
    local($error) = 0;
    local($pkg) = (caller)[0];
    local($value, $rt, $type, $required, @P_PARAMETER, %P_INFO, %P_ALIAS,
	  @P_REQUIRED, %P_VALID_VALUES, %P_ENV, %P_SET);
    local($option, $default_value, $list, $parameter, $alias, @keys, 
	  $found, $length, %P_EVALUATE, %P_DEFAULT_VALUE);
    local(@local_pdt);
    local($lref_MM) = $ref_MM;	# maintain a local reference
    local($lref_Opt) = $ref_Opt;
    
    $evap_embed = 0 unless defined $evap_embed; # 1 iff embed evap
    if ($evap_embed) {		# initialize for a new call
	if (defined $lref_Opt) {
	    undef %$lref_Opt;
	} else {
	    no strict 'refs';
	    undef %{"${pkg}::Options"};
	    undef %{"${pkg}::options"};
	}
    }

    evap_parse_PDT $ref_PDT;
    return evap_parse_command_line;

} # end evap
 
sub evap_parse_PDT {
   
    # Verify correctness of the PDT.  Check for duplicate parameter names and
    # aliases.  Extract default values and possible keywords.  Decode the user
    # syntax and convert into a simpler form (ala NGetOpt) for internal use. 
    # Handle 'file list' too.

    my($ref_PDT) = @_;

    @local_pdt = @{$ref_PDT};   # private copy of the PDT
    unshift @local_pdt, 'help, h: switch'; # supply -help automatically
    @P_PARAMETER = ();		# no parameter names
    %P_INFO = ();		# no encoded parameter information
    %P_ALIAS = ();		# no aliases
    @P_REQUIRED = ();		# no required parameters
    %P_VALID_VALUES = ();	# no keywords
    %P_ENV = ();		# no default environment variables
    %P_EVALUATE = ();		# no PDT values evaluated yet
    %P_DEFAULT_VALUE = ();	# no default values yet
    %P_SET = ();        	# no sets yet

  OPTIONS:
    foreach $option (@local_pdt) {

	$option =~ s/\s*$//;	# trim trailing spaces
	next OPTIONS if $option =~ /^#.*|PDT\s+|pdt\s+|PDT$|pdt$/;
	$option =~ s/\s*PDTEND|\s*pdtend//;
	next OPTIONS if $option =~ /^ ?$/;
	
	if ($option =~ /$pdt_reg_exp4|$pdt_reg_exp5|$pdt_reg_exp6/) {
	    $file_list = $option; # remember user specified file_list
	    next OPTIONS;
	}
	
        ($parameter, $alias, $_) = 
	  ($option =~ /^\s*(\S*)\s*,\s*(\S*)\s*:\s*(.*)$/);
	evap_PDT_error "Error in an Evaluate Parameters 'parameter, alias: " .
	    "type' option specification:  \"$option\".\n"
	    unless defined $parameter and defined $alias and defined $_;
	evap_PDT_error "Duplicate parameter $parameter:  \"$option\".\n" 
            if defined( $P_INFO{$parameter});
	push @P_PARAMETER, $parameter; # update the ordered list of parameters

	if (/(\bswitch\b|\binteger\b|\bstring\b|\breal\b|\bfile\b|\bboolean\b|\bkey\b|\bname\b|\bapplication\b|\bintegers\b|\bstrings\b|\breals\b|\bfiles\b|\bbooleans\b|\bkeys\b|\bnames\b|\bapplications\b)/) {
	    ($list, $type, $_) = ($`, $1, $');
	} else {
	    evap_PDT_error "Parameter $parameter has an undefined type:  " .
                "\"$option\".\n";
	}
	evap_PDT_error "Expecting 'list of', found:  \"$list\".\n" 
            if $list ne '' and $list !~ /\s*list\s+of\s+/ and
		$list !~ /\d+\s+/;
	my($set) = $list =~ /(\d+)\s+/;
	$P_SET{$parameter} = $set;
	$list =~ s/\d+\s+//;
        $list = '1' if $list;	# list state = 1, possible default PDT values
        $type = 'w' if $type =~ /^switch$/;
	$type = substr $type, 0, 1;

        ($_, $default_value) = /\s*=\s*/ ? ($`, $') : 
            ('', ''); # get possible default value
	if ($default_value =~ /^([^\(]{1})(\w*)\s*,\s*(.*)/) { 
            # If environment variable AND not a list.
	    $default_value = $3;
	    $P_ENV{$parameter} = $1 . $2;
	}
        $required = ($default_value eq '$required') ? 'R' : 'O';
        $P_INFO{$parameter} = defined $type ? $required . $type . $list : "";
	push @P_REQUIRED, $parameter if $required =~ /^R$/;

        if ($type =~ /^k$/) {
	    $_ =~ s/,/ /g;
	    @keys = split ' ';
	    pop @keys;		# remove 'keyend'
	    $P_VALID_VALUES{$parameter} = join ' ', @keys;
        } # ifend keyword type
	
	foreach $value (keys %P_ALIAS) {
	    evap_PDT_error "Duplicate alias $alias:  \"$option\".\n" 
                if $alias eq $P_ALIAS{$value};
	}
	$P_ALIAS{$parameter} = $alias; # remember alias

	evap_PDT_error "Cannot have 'list of switch':  \"$option\".\n" 
            if $P_INFO{$parameter} =~ /^.w1$/;

        if ($default_value ne '' and $default_value ne '$required') {
	    $default_value = $ENV{$P_ENV{$parameter}} if $P_ENV{$parameter} 
                and $ENV{$P_ENV{$parameter}};
	    $P_DEFAULT_VALUE{$parameter} = $default_value;
            evap_set_value 0,  $type, $list, $default_value, $parameter;
	} elsif ($evap_embed) {
	    no strict 'refs';
	    undef ${"${pkg}::opt_${parameter}"} if not defined $lref_Opt;
        }
	
    } # forend OPTIONS

    if ($error) {
        print STDERR "Read the `man' page \"EvaP.pm\" for details on PDT syntax.\n";
        exit 1;
    }

} # end evap_parse_PDT

sub evap_parse_command_line {

    # Process arguments from the command line, stopping at the first parameter
    # without a leading dash, or a --.  Convert a parameter alias into its full
    # form, type-check parameter values and store the value into global 
    # variables for use by the caller.  When complete call evap_fin to 
    # perform final processing.
    
  ARGUMENTS:
    while ($#ARGV >= 0) {
	
	$option = shift @ARGV;	# get next command line parameter
	$value = undef;		# assume no value
	
	$full_help = 1 if $option =~ /^-(full-help|\Q???\E)$/;
	$usage_help = 1 if $option =~ /^-(usage-help|\Q??\E)$/;
	$option = '-help' if $full_help or $usage_help or
	    $option  =~ /^-(\Q?\E)$/;
	
	if ($option =~ /^(--|-)/) { # check for end of parameters
	    if ($option eq '--') {
		return evap_fin;
	    }
	    $option = $';	# option name without dash
	} else {		# not an option, push it back on the list
	    unshift @ARGV, $option;
	    return evap_fin;
	}
	
	foreach $alias (keys %P_ALIAS) { # replace alias with the full spelling
	    $option = $alias if $option eq $P_ALIAS{$alias};
	}
	
	if (not defined($rt = $P_INFO{$option})) {
	    $found = 0;
	    $length = length $option;
	    foreach $key (keys %P_INFO) { # try substring match
		if ($option eq substr $key, 0, $length) {
		    if ($found) {
			print STDERR "Ambiguous parameter: -$option.\n";
			$error++;
			last;
		    }
		    $found = $key; # remember full spelling
		}
	    } # forend
	    $option = $found ? $found : $option;
	    if (not defined($rt = $P_INFO{$option})) {
		print STDERR "Invalid parameter: -$option.\n";
		$error++;
		next ARGUMENTS;
	    }
	} # ifend non-substring match
	
	($required, $type, $list) = ($rt =~ /$pdt_reg_exp1/);
	
	if ($type !~ /^w$/) {
	    if ($#ARGV < 0) { # if argument list is exhausted
		print STDERR "Value required for parameter -$option.\n";
		$error++;
		next ARGUMENTS;
	    } else {
		$value = shift @ARGV;
	    }
	}
	
	if ($type =~ /^w$/) {	# switch
	    $value = 1;
	} elsif ($type =~ /^i$/) { # integer
	    if ($value !~ /^[+-]?[0-9]+$/)  {
		print STDERR "Expecting integer reference, found \"$value\" for parameter -$option.\n";
		$error++;
		undef $value;
	    }
	} elsif ($type =~ /^r$/) { # real number, int is also ok
	    if ($value !~ /^\s*[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?\s*$/) {
		print STDERR "Expecting real reference, found \"$value\" for parameter -$option.\n";
		$error++;
		undef $value;
	    }
	} elsif ($type =~ /^s$|^n$|^a$/) { # string or name or application
	} elsif ($type =~ /^f$/) { # file
	    if (length $value > 255) {
		print STDERR "Expecting file reference, found \"$value\" for parameter -$option.\n";
		$error++;
		undef $value;
	    }
	} elsif ($type =~ /^b$/) { # boolean
	    $value =~ tr/a-z/A-Z/;
	    if ($value !~ /$pdt_reg_exp2|$pdt_reg_exp3/i) {
		print STDERR "Expecting boolean reference, found \"$value\" for parameter -$option.\n";
		$error++;
		undef $value;
            }
	} elsif ($type =~ /^k$/) { # keyword

	    # First try exact match, then substring match.

	    undef $found;
	    @keys = split ' ', $P_VALID_VALUES{$option};
	    for ($i = 0; $i <= $#keys and not defined $found; $i++) {
		$found = 1 if $value eq $keys[$i];
	    }
	    if (not defined $found) { # try substring match
		$length = length $value;
		for ($i = 0; $i <= $#keys; $i++) {
		    if ($value eq substr $keys[$i], 0, $length) {
			if (defined $found) {
			    print STDERR "Ambiguous keyword for parameter -$option: $value.\n";
			    $error++;
			    last; # for
			}
			$found = $keys[$i]; # remember full spelling
		    }
		} # forend
		$value = defined( $found ) ? $found : $value;
	    } # ifend
	    if (not defined $found) {
		print STDERR "\"$value\" is not a valid value for the parameter -$option.\n";
		$error++;
		undef $value;
	    }
	} # ifend type-check
	
	next ARGUMENTS if not defined $value;
	    
    	$list = '2' if $list =~ /^1$/; # advance list state
	evap_set_value 1,  $type, $list, $value, $option if defined $value;
	# Remove from $required list if specified.
	@P_REQUIRED = grep $option ne $_, @P_REQUIRED;
	$P_INFO{$option} = $required . $type . '3' if $list;

    } # whilend ARGUMENTS
    
    return evap_fin;
    
} # end evap_parse_command_line

sub evap_fin {

    # Finish up Evaluate Parameters processing:
    #
    # If -usage-help, -help or -full-help was requested then do it and exit.
    # Else,
    #   
    #  . Store program name in `help' variables.
    #  . Perform deferred evaluations.
    #  . Ensure all $required parameters have been given a value.
    #  . Ensure the validity of the trailing file list.
    #  . Exit with a Unix return code of 1 if there were errors and 
    #    $evap_embed = 0, else return to the calling Perl program with a 
    #    proper return code.
    
    use File::Basename;
    
    my($m, $p, $required, $type, $list, $rt, $def, $element, $is_string,
       $pager, $do_page);

    # Define Help Hooks text as required.
    
    $evap_Help_Hooks{'P_HHURFL'} = " file(s)\n" 
        if not defined $evap_Help_Hooks{'P_HHURFL'};
    $evap_Help_Hooks{'P_HHUOFL'} = " [file(s)]\n"
        if not defined $evap_Help_Hooks{'P_HHUOFL'};
    $evap_Help_Hooks{'P_HHUNFL'} = "\n"
        if not defined $evap_Help_Hooks{'P_HHUNFL'};
    $evap_Help_Hooks{'P_HHBRFL'} = "\nfile(s) required by this command\n\n"
        if not defined $evap_Help_Hooks{'P_HHBRFL'};
    $evap_Help_Hooks{'P_HHBOFL'} = "\n[file(s)] optionally required by this command\n\n"
        if not defined $evap_Help_Hooks{'P_HHBOFL'};
    $evap_Help_Hooks{'P_HHBNFL'} = "\n"
        if not defined $evap_Help_Hooks{'P_HHBNFL'};
    $evap_Help_Hooks{'P_HHERFL'} = "Trailing file name(s) required.\n"
        if not defined $evap_Help_Hooks{'P_HHERFL'};
    $evap_Help_Hooks{'P_HHENFL'} = "Trailing file name(s) not permitted.\n"
        if not defined $evap_Help_Hooks{'P_HHENFL'};

    my $want_help = 0;
    if (defined $lref_Opt) {
	$want_help = $lref_Opt->{'help'};
    } else {
	no strict 'refs';
	$want_help = "${pkg}::opt_help";
	$want_help = $$want_help;
    }

    if ($want_help) {		# see if help was requested
	
	my($optional);
	my(%parameter_help) = ();
	my($parameter_help_in_progress) = 0;
	my(%type_list) = (
	    'w' => 'switch',
	    'i' => 'integer',
	    's' => 'string',
	    'r' => 'real',
	    'f' => 'file',
	    'b' => 'boolean',
	    'k' => 'key',
	    'n' => 'name',
	    'a' => 'application',
	);

	# Establish the pager and open the pipeline.  Do no paging if the 
	# boolean environment variable D_EVAP_DO_PAGE is FALSE.

	$pager = 'more';
	$pager = $ENV{'PAGER'} if defined $ENV{'PAGER'} and $ENV{'PAGER'};
	$pager = $ENV{'MANPAGER'} if defined $ENV{'MANPAGER'} and 
	    $ENV{'MANPAGER'};
	$pager = '|' . $pager;
	if (defined $ENV{'D_EVAP_DO_PAGE'} and 
	    (($do_page = $ENV{'D_EVAP_DO_PAGE'}) ne '')) {
	    $do_page =~ tr/a-z/A-Z/;
	    $pager = '>-' if $do_page =~ /$pdt_reg_exp3/;
	}
	$pager = '>-' if $^O eq 'MacOS';
	open(PAGER, "$pager") or warn "'$pager' open failed:  $!";
	
	print PAGER "Command Source:  $0\n\n" if $full_help;

	# Print the Message Module text and save any full help.  The key is the
	# parameter name and the value is a list of strings with the newline as
	# a separator.  If there is no Message Module or it's empty then 
	# display an abbreviated usage message.
	
        if ($usage_help or not @{$lref_MM} or $#{$lref_MM} < 0) {
	    
	    $basename = basename($0, "");
	    print PAGER "\nUsage: ", $basename;
	    $optional = '';
	    foreach $p (@P_PARAMETER) {
		if ($P_INFO{$p} =~ /^R..?$/) { # if $required
		    print PAGER " -$P_ALIAS{$p}";
		} else {
		    $optional .= " -$P_ALIAS{$p}";
		}
	    } # forend
	    print PAGER " [$optional]" if $optional;
	    if ($file_list =~ /$pdt_reg_exp5/) {
		print PAGER "$evap_Help_Hooks{'P_HHUOFL'}";
	    } elsif ($file_list =~ /$pdt_reg_exp6/) {
		print PAGER "$evap_Help_Hooks{'P_HHURFL'}";
	    } else {
		print PAGER "$evap_Help_Hooks{'P_HHUNFL'}";
	    }
	    
        } else {
	    
	  MESSAGE_LINE:
	    foreach $m (@{$lref_MM}) {
		
		if ($m =~ /^\.(.*)$/) { # look for 'dot' leadin character
		    $p = $1; # full spelling of parameter
		    $parameter_help_in_progress = 1;
		    $parameter_help{$p} = "\n";
		    next MESSAGE_LINE;
		} # ifend start of help text for a new parameter
		if ($parameter_help_in_progress) { 
		    $parameter_help{$p} .=  $m . "\n";
		} else {
		    print PAGER $m, "\n";
		}
		
	    } # forend MESSAGE_LINE
	    
	} # ifend usage_help

	# Pass through the PDT list printing a standard evap help summary.

        print PAGER "\nParameters:\n";
	if (not $full_help) {print PAGER "\n";}
	
      ALL_PARAMETERS:
        foreach $p (@P_PARAMETER) {

	    no strict 'refs';
	    if ($full_help) {print PAGER "\n";}
	    
	    if ($p =~ /^help$/) {
		print PAGER "-$p, $P_ALIAS{$p}, usage-help, full-help: Display Command Information\n";
                if ($full_help) {
         	    print PAGER <<"end_of_DISCI";
\n    Display information about this command, which includes a command description with examples, as well as a synopsis of the
    command line parameters. If you specify -full-help rather than -help complete parameter help is displayed if it's available.
end_of_DISCI
	        }
		next ALL_PARAMETERS;
	    }
	    
	    $rt = $P_INFO{$p};	# get encoded required/type information
	    ($required, $type, $list) = ($rt =~ /$pdt_reg_exp1/); # unpack
	    $type = $type_list{$type};
	    $is_string = ($type =~ /^string$/);
	    
            my $set = $P_SET{$p} ? "$P_SET{$p} " : '';
	    print PAGER "-$p, $P_ALIAS{$p}: ", $list ? "list of " : '', "$set$type"; 
            if (defined($P_SET{$p}) and $P_SET{$p} > 1) {print PAGER 's'}
	    
	    print PAGER " ", join(', ', split(' ', $P_VALID_VALUES{$p})), ", keyend" if $type =~ /^key$/;
	    
	    my($ref);
            if (defined $lref_Opt) {
                $ref = \$lref_Opt->{$p};
                $ref = \@{$lref_Opt->{$p}} if $list;
            } else {
                $ref = "${pkg}::opt_${p}";
            }
	    if ($list) {
                $def =  @{$ref} ? 1 : 0;
	    } else {
                $def = defined ${$ref} ? 1 : 0;
            }
    
	    if ($required =~ /^O$/ or $def == 1) { # if $optional or defined
		
                if ($def == 0) { # undefined and $optional
    		    print PAGER "\n";
                } else {	# defined (either $optional or $required), display the default value(s)
                    if ($list) {
			print PAGER $P_ENV{$p} ? " = $P_ENV{$p}, " : " = ";
			print PAGER $is_string ? "(\"" : "(", $is_string ? join('", "', @{$ref}) : join(', ', @{$ref}), $is_string ? "\")\n" : ")\n";
                    } else {	# not 'list of'
			print PAGER $P_ENV{$p} ? " = $P_ENV{$p}, " : " = ";
			print PAGER $is_string ? "\"" : "", ${$ref}, $is_string ? "\"\n" : "\n";
                    } # ifend 'list of'
                } # ifend
		
	    } elsif ($required =~ /R/) {
		print PAGER $P_ENV{$p} ? " = $P_ENV{$p}, " : " = ";
		print PAGER "\$required\n";
	    } else {
		print PAGER "\n";
	    } # ifend $optional or defined parameter
	    
            if ($full_help) {
		if (defined $parameter_help{$p}) {
		    print PAGER "$parameter_help{$p}";
		} else {
		    print PAGER "\n";
		}
	    }
	    
	} # forend ALL_PARAMETERS

	if ($file_list =~ /$pdt_reg_exp5/) {
	    print PAGER "$evap_Help_Hooks{'P_HHBOFL'}";
	} elsif ($file_list =~ /$pdt_reg_exp6/) {
	    print PAGER "$evap_Help_Hooks{'P_HHBRFL'}";
	} else {
	    print PAGER "$evap_Help_Hooks{'P_HHBNFL'}";
	}

	close PAGER;
	if ($evap_embed) {
	    return -1;
	} else {
	    exit 0;
	}
	
    } # ifend help requested

    # Evaluate remaining unspecified command line parameters.  This has been
    # deferred until now so that if -help was requested the user sees 
    # unevaluated boolean, file and backticked values.

    foreach $parameter (@P_PARAMETER) {
	if (not $P_EVALUATE{$parameter} and $P_DEFAULT_VALUE{$parameter}) {
	    ($required, $type, $list) = ($P_INFO{$parameter} =~ /$pdt_reg_exp1/);
	    if ($type ne 'w') {
		$list = 2 if $list; # force re-initialization of the list
		evap_set_value 1, $type, $list, $P_DEFAULT_VALUE{$parameter}, $parameter;
	    } # ifend non-switch
	} # ifend not specified
    } # forend all PDT parameters

    # Store program name for caller.

    evap_set_value 0,  'w', '', $0, 'help';
    
    # Ensure all $required parameters have been specified on the command line.

    foreach $p (@P_REQUIRED) {
	print STDERR "Parameter $p is required but was omitted.\n";
	$error++;
    } # forend
    
    # Ensure any required files follow, or none do if that is the case.

    if ($file_list =~ /$pdt_reg_exp4/ and $#ARGV > 0 - 1) {
        print STDERR "$evap_Help_Hooks{'P_HHENFL'}";
        $error++;
    } elsif ($file_list =~ /$pdt_reg_exp6/ and $#ARGV == 0 - 1) {
        print STDERR "$evap_Help_Hooks{'P_HHERFL'}";
        $error++;
    }
    
    print STDERR "Type $0 -h for command line parameter information.\n" if $error;

    exit 1 if $error and not $evap_embed;
    if (not $error) {
	return 1;
    } else {
	return 0;
    }
    
} # end evap_fin

sub evap_PDT_error {

    # Inform the application developer that they've screwed up!

    my($msg) = @_;

    print STDERR "$msg";
    $error++;
    next OPTIONS;

} # end evap_PDT_error

sub evap_set_value {
    
    # Store a parameter's value; some parameter types require special type 
    # conversion.  Store values the old way in scalar/list variables of the 
    # form $opt_parameter and @opt_parameter, as well as the new way in hashes
    # named %options and %Options.  'list of' parameters are returned as a 
    # reference in %options/%Options (a simple list in @opt_parameter).  Or,
    # just stuff them in a user hash, is specified.
    #
    # Evaluate items in grave accents (backticks), boolean and files if 
    # `evaluate' is TRUE.
    #
    # Handle list syntax (item1, item2, ...) for 'list of' types.
    #
    # Lists are a little weird as they may already have default values from the
    # PDT declaration. The first time a list parameter is specified on the 
    # command line we must first empty the list of its default values.  The 
    # P_INFO list flag thus can be in one of three states: 1 = the list has 
    # possible default values from the PDT, 2 = first time for this command 
    # line parameter so empty the list and THEN push the parameter's value, and
    # 3 = just keep pushing new command line values on the list.

    my($evaluate, $type, $list, $v, $hash_index) = @_;
    my($option, $hash1, $hash2) = ("${pkg}::opt_${hash_index}", 
				   "${pkg}::options", "${pkg}::Options");
    my($value, @values);

    if ($list =~ /^2$/) {	# empty list of default values
	if (defined $lref_Opt) {
	    $lref_Opt->{$hash_index} = [];
	} else {
	    no strict 'refs';
	    @{$option} = ();
	    $hash1->{$hash_index} = \@{$option};
	    $hash2->{$hash_index} = \@{$option};
	}
    }

    if ($list and $v =~ /^\(+.*\)+$/) { # check for list
	@values = eval "$v"; # let Perl do the walking
    } else {

# Original line
# $v =~ s/["|'](.*)["|']/$1/s; # remove any bounding superfluous quotes 

##########################################################################
# Avner Moshkovitz changed (on 29 Apr 2009):
# ^\s* to force the leading quotes to be in the beginning of the string
# \s$ to force the trailing quotes to be in the end of the string
# /s as a substitution option to match only at the end of the string
# rather then at the end of the line
#
# /s without /m will force ``^'' to match only at the beginning of the 
# string and ``$'' to match only at the end (or just before a newline at the end) 
# of the string
##########################################################################

# The need came when ingesting a string with multiple lines, such as the 
# -analyzers argument in the example below:
#
# /opt/cvi/SENSNET/lib/ExpLhlSensorActivityEvaluator.pl -v -minSensorActivityTime 4 -analyzers '<?xml version="1.0" encoding="UTF-8"?>
# <analyzers groups="normal">
#     <!-- The config for a set of analyzers. -->
#     <nbOfAnalyzers groups="normal">
#       2
#     </nbOfAnalyzers>
# </analyzers>'
#
# In this case the leading eand trailing quotes were already removed by perl before even calling the
# EvaP module, as shown below:
#
# Cmd line params: -v -minSensorActivityTime 4 -analyzers <?xml version="1.0" encoding="UTF-8"?>
# <analyzers groups="normal">
#     <!-- The config for a set of analyzers. -->
#     <nbOfAnalyzers groups="normal">
#       2
#     </nbOfAnalyzers>
# </analyzers>
#
# Before the change the first double quotes in the first line (i.e. the double quotes "1.0 ... -8" )
# where removed resulting in the next line:
# version="1.0" encoding="UTF-8"?
# After the change there is no change in the string and the quotes are not deleted


$v =~ s/^\s*["|'](.*)["|']\s*$/$1/s; # remove any bounding superfluous quotes


	@values = $v;		# a simple scalar	
    } # ifend initialize list of values

    foreach $value (@values) {

        if ($evaluate) {
            $P_EVALUATE{$hash_index} = 'evaluated';
            $value =~ /^(`*)([^`]*)(`*)$/; # check for backticks
	    chop($value = `$2`) if $1 eq '`' and $3 eq '`';
	    if (not $evap_DOS and $type =~ /^f$/) {
                my(@path) = split /\//, $value;
	        if ($value =~ /^stdin$/) {
                    $value = '-';
                } elsif ($value =~ /^stdout$/) {
                    $value = '>-';
                } elsif ($path[0] =~ /(^~$|^\$HOME$)/) {
		    $path[0] = $ENV{'HOME'};
                    $value = join '/', @path;
                }
            } # ifend file type

            if ($type =~ /^b$/) {
	        $value = '1' if $value =~ /$pdt_reg_exp2/i;
	        $value = '0' if $value =~ /$pdt_reg_exp3/i;
            } # ifend boolean type
        } # ifend evaluate

        if ($list) {		# extend list with new value
            if (defined $lref_Opt) {
                push @{$lref_Opt->{$hash_index}}, $value;
            } else {
                no strict 'refs';
	        push @{$option}, $value;
                $hash1->{$hash_index} = \@{$option};
                $hash2->{$hash_index} = \@{$option};
            }
        } else {		# store scalar value
            if (defined $lref_Opt) {
                $lref_Opt->{$hash_index} = $value;
            } else {
                no strict 'refs';
	        ${$option} = $value;
                $hash1->{$hash_index} = $value;
                $hash2->{$hash_index} = $value;
                # ${$hash2}{$hash_index} = $value; EQUIVALENT !
            }
        }

    } # forend
	
} # end evap_set_value

sub evap_isatty {

    my $in = shift;
    my $s = -t $in;
    return $s;

}

sub evap_pac {

    eval {
	require Term::ReadLine;
    };
    my $noReadLine = $@;

    # Process Application Commands - an application command can be envoked by entering either its full spelling or the alias.

    my($prompt, $I, %cmds) = @_;

    $noReadLine = 1 if not evap_isatty( $I );

    my($proc, $args, %long, %alias, $name, $long, $alias);
    my $pkg = (caller)[0];
    my $inp = ref($I) ? $I : "${pkg}::${I}";

    $evap_embed = 1;		# enable embedding
    $shell = (defined $ENV{'SHELL'} and $ENV{'SHELL'} ne '') ? 
        $ENV{'SHELL'} : '/bin/sh';
    foreach $name (keys %cmds) {
	$cmds{$name} = $pkg . '::' . $cmds{$name}; # qualify
    }
    $cmds{'display_application_commands|disac'} = 'evap_disac_proc(%cmds)';
    $cmds{'!'} = 'evap_bang_proc';

    # First, create new hash variables with full/alias names.

    foreach $name (keys %cmds) {
        if ($name =~ /\|/) {
            ($long, $alias) = ($name =~ /(.*)\|(.*)/);
	    $long{$long} = $cmds{$name};
	    $alias{$alias} = $cmds{$name};
        } else {
	    $long{$name} = $cmds{$name};
	}
    }

    my ( $term, $out );
    if ( $noReadLine ) {
	print STDOUT "$prompt";
    } else {
	$term = Term::ReadLine->new( $prompt );
	$OUT = $term->OUT || \*STDOUT;
    }
    my $eofCount = $ENV{IGNOREEOF};
    $eofCount = 0 unless defined $eofCount;

    no strict 'refs';
  GET_USER_INPUT:
    while ( 1 ) {
	if ( $noReadLine ) {
	    $_ = <$inp>;
	} else {
	    $_ = $term->readline( $prompt );
	}
	if ( not defined $_ ) {
	    $eofCount--;
	    last if $eofCount < 0;
	    print "\n";
	    next GET_USER_INPUT;
	}
	next GET_USER_INPUT if /^\s*$/;	# ignore empty input lines

	if (/^\s*!(.+)/) {
	    $_ = '! ' . $1;
	}

        ($0, $args) = /\s*(\S+)\s*(.*)/;
	if ( $0 =~ m/^help$|^h$/i ) {
	     $0 = 'disac';
	     $args = '-do f';
	}
	if (defined $long{$0}) {
	    $proc = $long{$0};
	} elsif (defined $alias{$0}) {
	    $proc = $alias{$0};
	} else  {
            print STDERR <<"end_of_ERROR";
Error - unknown command '$0'.  Type 'help' for a list of valid application commands.  You can then type 'xyzzy -h' for help on application command 'xyzzy'.
end_of_ERROR
	    next GET_USER_INPUT;
        }

	if ($0 eq '!') {
	    @ARGV = $args;
	} else {
	    @ARGV = Text::ParseWords::quotewords( '\s+', 0, $args );
	}

	if ( ($proc =~ m/^evap_(.*)_proc/) or exists &$proc ) {
	    eval "&$proc;";		# call the evap/user procedure
	    print STDERR $EVAL_ERROR if $EVAL_ERROR;
	} else {
	    print STDERR "Procedure '$proc' does not exist in your application and cannot be called.\n";
	}

	@ARGV = ();

    } # whilend GET_USER_INPUT
    continue { # while GET_USER_INPUT
        print STDOUT "$prompt" if $noReadLine;
    } # continuend
    print STDOUT "\n" unless $prompt eq "";

} # end evap_pac

sub evap_bang_proc {
    
    # Issue commands to the user's shell.  If the SHELL environment variable is
    # not defined or is empty, then /bin/sh is used.

    my $cmd = $ARGV[0];

    if ($cmd ne '') {
	$bang_proc_MM = <<"END";
!

    Bang! Issue one or more commands to the shell.  If the SHELL environment variable is not defined or is empty, then /bin/sh is used.

    Examples:

      !date
      !del *.o; ls -al
END
        $bang_proc_PDT = <<"END";
PDT !
PDTEND optional_file_list
END
	$evap_Help_Hooks{'P_HHUOFL'} = " Command(s)\n";
	$evap_Help_Hooks{'P_HHBOFL'} = "\nA list of shell Commands.\n\n";
	@bang_proc_MM = split /\n/, $bang_proc_MM;
	@bang_proc_PDT = split /\n/, $bang_proc_PDT;
	if (EvaP(\@bang_proc_PDT, \@bang_proc_MM) != 1) {return;}
	system "$shell -c '$cmd'";
    } else {
	print STDOUT "Starting a new `$shell' shell; use `exit' to return to this application.\n";
	system $shell;
    }

} # end evap_bang_proc

sub evap_disac_proc {
    
    # Display the list of legal application commands.

    my(%commands) = @_;
    my(@brief, @full, $name, $long, $alias);
	$disac_proc_MM = <<"END";
display_application_commands, display_application_command, disac

    Displays a list of legal commands for this application.

    Examples:

      disac              # the `brief' display
      disac -do f        # the `full' display
.display_option
    Specifies the level of output desired.
.output
    Specifies the name of the file to write information to.
END
        $disac_proc_PDT = <<"END";
PDT disac
  display_option, do: key brief, full, keyend = brief
  output, o: file = stdout
PDTEND no_file_list
END
    @disac_proc_MM = split /\n/, $disac_proc_MM;
    @disac_proc_PDT = split /\n/, $disac_proc_PDT;
    if (EvaP(\@disac_proc_PDT, \@disac_proc_MM) != 1) {return;}

    my $len = 1;
    foreach $name (keys %commands) {
        if ($name =~ /\|/) {
            ($long, $alias) = ($name =~ /(.*)\|(.*)/);
        } else {
	    $long = $name;
            $alias = '';
	}
	my $l = length $long;
	$len = $l if $l > $len;
    }
    foreach $name (keys %commands) {
        if ($name =~ /\|/) {
            ($long, $alias) = ($name =~ /(.*)\|(.*)/);
        } else {
	    $long = $name;
            $alias = '';
	}
        push @brief, $long;
        push @full, ($alias ne '') ? sprintf("%-${len}s, %s", $long, $alias) : "$long";
    }

    open H, ">$Options{'output'}";
    if ($Options{'display_option'} eq 'full') {
        print H "\nFor help on any application command (or command alias) use the -h switch.  For example, try 'disac -h' for help on 'display_application_commands'.\n";
        print H "\nCommand and alias list for this application:\n\n";
	print H "  ", join("\n  ", sort(@full)), "\n";
    } else {
        print H join("\n", sort(@brief)), "\n";
    }
    close H;

} # end evap_disac_proc

#sub evap_setup_for_evap {
#    
#    # Initialize evap_pac's builtin commands' PDT/MM variables.
#
#    my($command) = @_;
#
#    open IN, "ar p $message_modules ${command}_pdt|";
#    eval "\@${command}_proc_PDT = <IN>;";
#    close IN;
#
#    open IN, "ar p $message_modules ${command}.mm|";
#    eval "\@${command}_proc_MM = grep \$@ = s/\n\$//, <IN>;";
#    close IN;
#
#} # end evap_setup_for_evap

1;
__END__

=head1 NAME

Getopt::EvaP - evaluate Perl command line parameters.

=head1 SYNOPSIS

 use vars qw/@PDT @MM %OPT/;
 use Getopt::EvaP;

 EvaP \@PDT, \@MM, \%OPT;

=head1 EXPORT

C<use Getopt::EvaP> exports the subs C<EvaP> and C<EvaP_PAC> into your
name space.

=head1 DESCRIPTION

B<@PDT>
is the Parameter Description Table, which is a reference to a list of
strings describing the command line parameters, aliases,
types and default values.
B<@MM>
is the Message Module, which is also a reference to a list of strings
describing the command and it's parameters.
B<%OPT>
is an optional hash reference where Evaluate Parameters should place its
results.  If specified, the historical behaviour of modifying the calling
routines' namespace by storing option values in B<%Options>, B<%options> and
B<$opt*> is disabled.

=head2 Introduction

Function Evaluate Parameters parses a Perl command line in a simple and
consistent manner, performs type checking of parameter values, and provides
the user with first-level help.  Evaluate Parameters is also embeddable in
your application; refer to the B<evap_pac(2)> man page for complete details.
Evaluate Parameters handles command lines in the following format:

  command [-parameters] [file_list]

where parameters and file_list are all optional.  A typical example is the
C compiler:

  cc -O -o chunk chunk.c

In this case there are two parameters and a file_list consisting of a
single file name for the cc command.


=head2 Parameter Description Table (PDT) Syntax

Here is the PDT syntax.  Optional constructs are enclosed in [], and the
| character separates possible values in a list.

  PDT [program_name, alias]
    [parameter_name[, alias]: type [ = [default_variable,] default_value]]
  PDTEND [optional_file_list | required_file_list | no_file_list]

So, the simplest possible PDT would be:

  PDT
  PDTEND

This PDT would simply define a I<-help> switch for the command, but is rather
useless. 

A typical PDT would look more like this:

  PDT frog
    number, n: integer = 1
  PDTEND no_file_list

This PDT, for command frog, defines a
single parameter, number (or n), of type integer with a default value of 1.
The PDTEND I<no_file_list> indicator indicates that no trailing file_list
can appear on the command line.  Of course, the I<-help> switch is defined
automatically.

The
I<default_variable>
is an environment variable - see the section Usage Notes
for complete details.

=head2 Usage Notes

Usage is similar to getopt/getopts/newgetopt: define a Parameter
Description Table declaring a list of command line parameters, their
aliases, types and default values.  The command line parameter
I<-help> (alias I<-h>) is automatically included by Evaluate
Parameters.  After the evaluation the values of the command line
parameters are stored in variable names of the form B<$opt_parameter>,
except for lists which are returned as B<@opt_parameter>, where
I<parameter> is the full spelling of the command line parameter.
NOTE: values are also returned in the hashes B<%options> and
B<%Options>, with lists being passed as a reference to a list.

Of course, you can specify where you want Evaluate Parameters to return its
results, in which case this historical feature of writing into your namespace
is disabled.
 
An optional PDT line can be included that tells Evaluate Parameters whether
or not trailing file names can appear on the command line after all the
parameters.  It can read I<no_file_list>, I<optional_file_list> or
I<required_file_list> and, if not specified, defaults to optional.  Although
placement is not important, this line is by convention the last line of the
PDT declaration.

Additionally a Message Module is declared that describes the command
and provides examples.  Following the main help text an optional
series of help text messages can be specified for individual command
line parameters.  In the following sample program all the parameters
have this additional text which describes that parameter's type.  The
leadin character is a dot in column one followed by the full spelling
of the command line parameter.  Use I<-full-help> rather than I<-help>
to see this supplemental information.  This sample program illustrates
the various types and how to use B<EvaP()>.  The I<key> type is a
special type that enumerates valid values for the command line
parameter.  The I<boolean> type may be specified as TRUE/FALSE,
YES/NO, ON/OFF or 1/0.  Parameters of type I<file> have ~ and $HOME
expanded, and default values I<stdin> and I<stdout> converted to `-'
and `>-', respectively.  Of special note is the default value
I<$required>: when specified, Evaluate Parameters will ensure a value
is specified for that command line parameter.

All types except I<switch> may be I<list of>, like the I<tty> parameter below.
A list parameter can be specified multiple times on the command line.
NOTE: in general you should ALWAYS quote components of your lists, even if
they're not type string, since Evaluate Parameters uses eval to parse them.
Doing this prevents eval from evaluating expressions that it shouldn't, such
as file name shortcuts like $HOME, and backticked items like `hostname`.
Although the resulting PDT looks cluttered, Evaluate Parameters knows what
to do and eliminates superfluous quotes appropriately.
 
Finally, you can specify a default value via an environment variable.  If
a command line parameter is not specified and there is a corresponding
environment variable defined then Evaluate Parameters will use the value
of the environment variable.  Examine the I<command> parameter for the syntax.
With this feature users can easily customize command parameters to their
liking.   Although the name of the environment variable can be whatever you
choose,  the following scheme is suggested for consistency and to avoid
conflicts in names:  

=over 4

=item *

Use all uppercase characters.

=item *

Begin the variable name with D_, to suggest a default variable.

=item *

Continue with the name of the command or its alias followed by an underscore.

=item *

Complete the variable name with the name of the parameter or its alias.

=back

So, for example, D_DISCI_DO would name a default variable for the
display_option (do) parameter of the display_command_information
(disci) command.  Works for MS-DOS and Unix.

=head1 Example

 #!/usr/local/bin/perl
     
 use Getopt::EvaP;

 @PDT = split /\n/, <<'end-of-PDT';
 PDT sample
   verbose, v: switch
   command, c: string = D_SAMPLE_COMMAND, "ps -el"
   scale_factor, sf: real = 1.2340896e-1
   millisecond_update_interval, mui: integer = $required
   ignore_output_file_column_one, iofco: boolean = TRUE
   output, o: file = stdout
   queue, q: key plotter, postscript, text, printer, keyend = printer
   destination, d: application = `hostname`
   tty, t: list of name = ("/dev/console", "/dev/tty0", "/dev/tty1")
 PDTEND optional_file_list
 end-of-PDT

 @MM = split /\n/, <<'end-of-MM';
 sample

        A sample program demonstrating typical Evaluate Parameters
        usage.

        Examples:

          sample
          sample -usage-help
          sample -help
          sample -full-help
          sample -mui 1234
 .verbose
        A switch type parameter emulates a typical standalone
        switch. If the switch is specified Evaluate Parameters
        returns a '1'.
 .command
        A string type parameter is just a list of characters,
        which must be quoted if it contains whitespace. 
        NOTE:  for this parameter you can also create and
        initialize the environment variable D_SAMPLE_COMMAND to
        override the standard default value for this command
        line parameter.  All types except switch may have a
        default environment variable for easy user customization.
 .scale_factor
        A real type parameter must be a real number that may
        contain a leading sign, a decimal point and an exponent.
 .millisecond_update_interval
        An integer type parameter must consist of all digits
        with an optional leading sign.  NOTE: this parameter's
        default value is $required, meaning that
        Evaluate Parameters ensures that this parameter is
        specified and given a valid value.  All types except
        switch may have a default value of $required.
 .ignore_output_file_column_one
        A boolean type parameter may be TRUE/YES/ON/1 or
        FALSE/NO/OFF/0, either upper or lower case.  If TRUE,
        Evaluate Parameters returns a value of '1', else '0'.
 .output
        A file type parameter expects a filename.  For Unix
        $HOME and ~ are expanded.  For EvaP/Perl stdin and
        stdout are converted to '-' and '>-' so they can be
        used in a Perl open() function.
 .queue
        A key type parameter enumerates valid values.  Only the
        specified keywords can be entered on the command line.
 .destination
        An application type parameter is not type-checked in
        any - the treatment of this type of parameter is
        application specific.  NOTE:  this parameter' default
        value is enclosed in grave accents (or "backticks").
        Evaluate Parameters executes the command and uses it's
        standard output as the default value for the parameter.
 .tty
        A name type parameter is similar to a string except
        that embedded white-space is not allowed.  NOTE: this
        parameter is also a LIST, meaning that it can be
        specified multiple times and that each value is pushed
        onto a Perl LIST variable.  In general you should quote
        all list elements.  All types except switch may be
        'list of'.
 end-of-MM

 EvaP \@PDT, \@MM;		# evaluate parameters

 print "\nProgram name:\n  $Options{'help'}\n\n";

 if (defined $Options{'verbose'}) {print "\nverbose = $Options{'verbose'}\n";}
 print "command = \"$Options{'command'}\"\n";
 print "scale_factor  = $Options{'scale_factor'}\n";
 print "millisecond_update_interval = $Options{'millisecond_update_interval'}\n";
 print "ignore_output_file_column_one = $Options{'ignore_output_file_column_one'}\n";
 print "output = $Options{'output'}\n";
 print "queue = $Options{'queue'}\n";
 print "destination = $Options{'destination'}\n";
 print "'list of' tty = \"", join('", "', @{$Options{'tty'}}), "\"\n";

 print "\nFile names:\n  ", join ' ', @ARGV, "\n" if @ARGV;

Using the PDT as a guide, Evaluate Parameters parses a user's
command line, returning the results of the evaluation to global
variables of the form B<$opt_parameter>, B<@opt_parameter>,
B<%Options{'parameter'}> or B<%options{'parameter'}>, where I<parameter>
is the full spelling of the command line parameter.

Of course, you can specify where you want Evaluate Parameters to return its
results, in which case this historical feature of writing into your namespace
is disabled.

Every command using Evaluate Parameters automatically has a
I<-help> switch which displays parameter help; no special code is
required in your application.

=head2 Customization of EvaP's Help Output

There are several Help Hook strings that can be altered to customize
B<EvaP>'s help output.  Currently there is only one general area that can
be customized: usage and error text dealing with the trailing file_list.
For instance, if a command requires one or more trailing file names after
all the command line switches, the default I<-help> text is:

 file(s) required by this command

Some commands do not want trailing "file names", but rather some other
type of information.  An example is I<display_command_information> where
a single Program_Name is expected.  The following code snippet shows
how to do this:

  $Getopt::EvaP::evap_Help_Hooks{'P_HHURFL'} = " Program_Name\n";
  $Getopt::EvaP::evap_Help_Hooks{'P_HHBRFL'} =
        "\nA Program_Name is required by this command.\n\n";
  $Getopt::EvaP::evap_Help_Hooks{'P_HHERFL'} =
        "A trailing Program_Name is required by this command.\n";
  EvaP \@PDT, \@MM;

As you can see, the hash B<%evap_Help_Hooks> is indexed by a simple
ordinal.  The ordinals are shown below and are mostly self-explanatory.
In case you don't have access to the source
for Evaluate Parameters, here are the default values of the Help Hook
strings.

  $Getopt::EvaP:evap_Help_Hooks{'P_HHURFL'} = " file(s)\n";
  $Getopt::EvaP:evap_Help_Hooks{'P_HHUOFL'} = " [file(s)]\n";
  $Getopt::EvaP:evap_Help_Hooks{'P_HHUNFL'} = "\n";
  $Getopt::EvaP:evap_Help_Hooks{'P_HHBRFL'} =
         "\nfile(s) required by this command\n\n";
  $Getopt::EvaP:evap_Help_Hooks{'P_HHBOFL'} =
        "\n[file(s)] optionally required by this command\n\n";
  $Getopt::EvaP:evap_Help_Hooks{'P_HHBNFL'} = "\n";
  $Getopt::EvaP:evap_Help_Hooks{'P_HHERFL'} =
        "Trailing file name(s) required.\n";
  $Getopt::EvaP:evap_Help_Hooks{'P_HHENFL'} =
        "Trailing file name(s) not permitted.\n";

The Help Hooks naming convention is rather simple:

  P_HHtf

    where:

      P_HH  implies an Evaluate Parameters Help Hook
     t     type:
              U=Usage Help
              B=Brief and Full Help
              E=error message
      f     file_list:
              RFL=required_file_list
              OFL=optional_file_list
              NFL=no_file_list

Note to I<genPerlTk> and I<genTclTk> users:  using these Help Hooks may 
cause the "genTk programs" to generate an unuseable Tk script.  This 
happens because the "genTk programs" look for the strings "required by
this command" or "optionally required by this command" in order to 
generate the file_list Entry widget - if these string are missing the
widget is not created.  An easy solution is to ensure that your Help 
Hook text contains said string, just like the code snippet above;
otherwise you must manually add the required Tk code yourself.

=head2 Human Interface Guidelines

To make Evaluate Parameters successful, you, the application developer, must
follow certain conventions when choosing parameter names and aliases.

Parameter names consist of one or more words, separated by underscores, and
describe the parameter (for example, I<verbose> and I<spool_directory>).

You can abbreviate parameters:  use the first letter of each word in the
parameter name.  Do not use underscores.  For example, you can abbreviate
I<command> as I<c> and I<delay_period> as I<dp>.

There are exceptions to this standard:

=over 4

=item *

I<password> is abbreviated I<pw>.

=item *

The words I<minimum> and I<maximum> are abbreviated
I<min> and I<max>.  So, the abbreviation for the
parameter I<maximum_byte_count> is I<maxbc>.

=item *

There are no abbreviations for the parameters
I<usage-help> and I<full-help>; I do not want to
prevent I<uh> and I<fh> from being used as valid
command line parameters.

=back

=head2 Variables MANPAGER, PAGER and D_EVAP_DO_PAGE

The environment variable MANPAGER (or PAGER) is used to control the
display of help information generated by Evaluate Parameters.  If
defined and non-null, the value of the environment variable is taken as
the name of the program to pipe the help output through.  If no paging
program is defined then the program I<more> is used.

The boolean environment variable D_EVAP_DO_PAGE can be set to FALSE/NO/OFF/0,
any case, to disable this automatic paging feature (or you can set your
paging program to I<cat>).

=head2 Return Values

B<EvaP()> behaves differently depending upon whether it's called to parse an 
application's command line, or as an embedded command line parser
(for instance, when using B<evap_pac()>).

            Application      Embedded
            Command Line     Command Line 
 ----------------------------------------
 error      exit(1)          return(0)
 success    return(1)        return(1)
 help       exit(0)          return(-1)

=head1 SEE ALSO

 evap(2)
 evap.c(2)
 EvaP.pm(2)
 evap.tcl(2)
 evap_pac(2)
 addmm, add_message_modules(1)
 disci, display_command_information(1)
 genmp, generate_man_page(1)
 genpdt, generate_pdt(1)
 genPerlTk, generate_PerlTk_program(1)
 genTclTk, generate_TclTk_program(1)

 All available from directory F<ftp://ftp.Lehigh.EDU:/pub/evap/evap-2.x/>.

=head1 BUGS

The code is messy (written in Perl4-ese), and should be redone, but I
can't rationalize the time expenditure for code that still works so well.

=head1 AUTHOR

Stephen.O.Lidie@Lehigh.EDU

=head1 HISTORY

 lusol@Lehigh.EDU 94/10/28 (PDT version 2.0)  Version 2.2
   . Original release - derived from evap.pl version 2.1.
   . Undef option values for subsequent embedded calls.

 lusol@Lehigh.EDU 95/10/27 (PDT version 2.0)  Version 2.3.0
   . Be a strict as possible.
   . Revert to -h alias rather than -?.  (-? -?? -??? still available.)
   . Move into Getopt class.
   . Format for 80 columns (mostly).
   . Optional third argument on EvaP call can be a reference to your own
     %Options hash.  If specified, the variabes %Options, %options and 
     $opt* are not used.

 lusol@Lehigh.EDU 97/01/12 (PDT version 2.0)  Version 2.3.1
   . Fix Makefile.PL so it behaves properly.  Convert nroff man data to pod
     format.

 Stephen.O.Lidie@Lehigh.EDU 98/01/14 (PDT version 2.0)  Version 2.3.2
   . Incorporate Achim Bohnet's POD patch while updating for Win32.

 Stephen.O.Lidie@Lehigh.EDU 98/07/25 (PDT version 2.0)  Version 2.3.3
   . Update Makefile.PL so it works in the standard fashion.
   . Update for perl 5.005 and Tk 800.008.
   . Remove use of ENGLISH.
   . Add genpTk to generate a Perl/TK GUI wrapper around command line
     programs.  Primarily for users of EvaP(), can be used by other codes
     as well.

 Stephen.O.Lidie@Lehigh.EDU 99/04/03 (PDT version 2.0)  Version 2.3.5
   . Update Makefile.PL for ActiveState, fix a -w message found by 5.005_03.

 sol0@lehigh.edu 2010/01/19 (PDT version 2.0)  Version 2.3.6
   . Patch by Avner Moshkovitz to handle embedded quotes and spaces in string
     options.

 sol0@lehigh.edu 2013/04/06 (PDT version 2.0)  Version 2.5
   . Change -full_help and -usage_help to -full-help and -usage-help (change
     underscore to dash).
   . Evap_PAC obeys IGNOREEOF.
   . Embed the disac and ! MMs and PDTs in the code.
   . Messages now use a longer output line width.
   . Use fewer empty lines for -full-help output.
   . Allow "help" and "h" to stand for "disac -do f".
   . Evap_PAC now ensures that an application command exists.
   . disac now determines length of longest command for a tidy column display.

 sol0@lehigh.edu 2013/05/14 (PDT version 2.0)  Version 2.6
   . Add Term::ReadLine support in EvaP_PAC: uses readline() automatically if the 
     module is installed and input is coming from a terminal.

 sol0@lehigh.edu 2013/10/22 (PDT version 2.0)  Version 2.7
   . shellwords.pl is deprecated, use Text::ParseWords instead.

 sol0@lehigh.edu 2014/11/01 (PDT version 2.0)  Version 2.8
   . fix 2 defined() warnings.

=head1 COPYRIGHT

Copyright (C) 1993 - 2015 Stephen O. Lidie. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
