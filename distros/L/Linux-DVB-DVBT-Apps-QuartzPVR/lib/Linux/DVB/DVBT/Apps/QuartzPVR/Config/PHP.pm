package Linux::DVB::DVBT::Apps::QuartzPVR::Config::PHP ;
	
=head1 NAME

PHP - PHP include file reader

=head1 SYNOPSIS

use PHP ;

=head1 DESCRIPTION

This module makes simple PHP modules accessible as Perl modules.

NOTE: For Windows testings, just add the PHP library path(s) to PERL5LIB

=head1 AUTHOR

Steve Price 

=head1 BUGS

None that I know of!

=head1 INTERFACE

=over 4

=cut


use strict ;




#============================================================================================
require Exporter ;
our @ISA = qw(Exporter);
our @EXPORT =qw(

	require_php

	debug 
	verbose
);

our @EXPORT_OK	=qw(
	$DEBUG 
	$VERBOSE

	@PHP_INC
	%PHP_INC
);



#============================================================================================
# USES
#============================================================================================
use Carp ;
use File::Basename ;

use Linux::DVB::DVBT::Apps::QuartzPVR::Config::PHP::Install ;

#============================================================================================
# GLOBALS
#============================================================================================
our $VERSION = '2.003' ;


our $DEBUG = 0 ;
our $VERBOSE = 0 ;

our $PHP_INCLUDE_EXISTING = '%PHP_SEARCH%' ;

our @PHP_INC ;
our %PHP_INC ;



#============================================================================================
# EXPORTED 
#============================================================================================

#---------------------------------------------------------------------------------------------------

=item C<PHP::debug($level)>

Set debug print options to B<$level>. 

 0 = No debug
 1 = standard debug information
 2 = verbose debug information

=cut

sub debug
{
	my ($flag) = @_ ;

	my $old = $DEBUG ;

	if (defined($flag)) 
	{
		# set this module debug flag & sub-modules
		$DEBUG = $flag ; 
	}
	return $old ;
}

#---------------------------------------------------------------------------------------------------

=item C<PHP::verbose($level)>

Set vebose print options to B<$level>. 

 0 = Non verbose
 1 = verbose print

=cut

sub verbose
{
	my ($flag) = @_ ;

	my $old = $VERBOSE ;

	if (defined($flag)) 
	{
		# set this module verbose flag & sub-modules
		$VERBOSE = $flag ; 
	}
	return $old ;
}



#---------------------------------------------------------------------

=item C<PHP::require_php($module [, $namespace])>

Loads in the PHP module named B<$module>. Searches the directories listed in
@PHP_INC and loads the first PHP module found. Looks for php with the module name
and extension '.php' or '.inc'.

Optionally the namespace that the variables will be loaded into can be specified
via B<$namespace>. The default is to load into the namespace I<$module>.

If a PHP module is sucessfully loaded, it is logged in the hash %PHP_INC and not re-loaded.

=cut

#
sub require_php
{
	my ($module, $namespace) = @_ ;

	print "require_php($module [ $namespace ])\n" if $DEBUG ;

	$namespace ||= $module ;

	print " + namspace $namespace, module $module\n" if $DEBUG ;

	my $loaded = '' ;

	my $VARNAME = "(?:[a-zA-Z_][0-9a-zA-Z_]*)" ;
	my $STRING = "(?:\".*?\")|(?:\'.*?\')" ;
	my $NUMBER = "(?:-?[0-9.]+)" ;
	my $SCALAR = "(?:$STRING|$NUMBER)" ;

	# Skip if already loaded
	if (exists($PHP_INC{"$module $namespace"}))
	{
		print "ALREADY LOADED - $module $namespace\n" if $DEBUG ;
		$loaded = $PHP_INC{"$module $namespace"} ;
	}
	else 
	{
		# Convert module name to a path
		my ($filename) = $module ;
		$filename =~ s/:/\//g ;

		# Try to find module
		my $realfilename;
		foreach my $prefix (@PHP_INC) 
		{
			my $php_realfilename = "$prefix/$filename";
			for my $ext (qw/.php .inc/)
			{
				if (-f "$php_realfilename$ext") 
				{
					## Found module
					$realfilename = $php_realfilename;
					open my $fh, "<$php_realfilename$ext" or die "Error: Unable to read $php_realfilename$ext $!" ;

					## Create 'use' command

					my $cmd = "package $namespace;\n" ;
					my $line ;
					my $multiline = '' ;
					while (defined($line = <$fh>))
					{
						# Remove whitespace & comments
						chomp $line ;
						$line =~ s/\#.*// ;
						$line =~ s%//.*%% ;
						$line =~ s/^\s+// ;
						$line =~ s/\s+$// ;

						# Strip out php
						$line =~ s/\<\?php// ;
						$line =~ s/\?\>// ;
						next unless $line ;

						# collate lines
						$multiline .= " $line" ;

						# process if collated lines end with ';'
						if ($multiline =~ /;$/) 
						{
							$line = $multiline ;
							$multiline = '' ;
							$line =~ s/^\s+// ;
							print "<<$line>>\n" if $DEBUG>=2 ;

							# Make vars global
							if ($line =~ /^\$($VARNAME)\s*=\s*(.*)/) 
							{
								my ($var, $val) = ($1, $2) ;

								print " + var=val : $var=$val\n" if $DEBUG>=2 ;

								# scalar
								if ($val =~ /^($SCALAR)/) 
								{
									print " + + scalar\n" if $DEBUG>=2 ;
									$val = $1 ;
									$line = "our \$$var = $val ;" ;
								}
								# hash
								elsif ($val =~ /^array\((.*=>.*)\)/) 
								{
									print " + + hash\n" if $DEBUG>=2 ;
									$val = $1 ;
									$line = "our \%$var = (\n" ;
									while ($val =~ /\s*($VARNAME|$STRING)\s*=>\s*($SCALAR)\s*,*/g) 
									{
										$line .= "\t$1 => $2,\n" ;
									}
									$line .= ") ;" ;
								}
								# array
								elsif ($val =~ /^array\((.*)\)/) 
								{
									print " + + array\n" if $DEBUG>=2 ;
									$val = $1 ;
									$line = "our \@$var = (" ;
									while ($val =~ /\s*($SCALAR)\s*,*/g) 
									{
										$line .= "$1, " ;
									}
									$line .= ") ;" ;
								}
								else 
								{
									# Unknown
									print "UNKNOWN\n" if $DEBUG>=2 ;
									next ;
								}
							}

							# defines
							elsif ($line =~ /^define\s*\(\s*($STRING|$VARNAME)\s*,\s*($SCALAR)\s*\)/) 
							{
								my $var = $1 ;
								my $val = process_scalar($2) ;

								$line = "use constant $var => $val ;" ;
								print " + define $var = $val\n" if $DEBUG>=2 ;

							}

							# includes
							elsif ($line =~ /^(?:include|require|require_once|include_once)\s*\(?\s*($STRING)\s*\)?/) 
							{
								print " + include $1 = $2\n" if $DEBUG>=2 ;
								my ($php) = ($1) ;
								
								# Convert to module name
								$php =~ s%[\\/]%::%g ;
								$php =~ s%\..*$%% ;
								$php =~ s%[\'\"]%%g ;

#								# Include settings into this namespace
#								$line = "use PHP;\n" ;
#								$line .= "require_php('$php', $namespace);" ;
								##$line = '' ;
								$line = require_php($php, $namespace);

							}


							else 
							{
								# Unknown
								print "UNKNOWN\n" if $DEBUG>=2 ;
								next ;
							}


							$cmd .= "$line\n" ;
						}
					}

					$PHP_INC{"$module $namespace"} = $cmd ;

					print "cmd <$cmd>\n" if $DEBUG ;
					eval $cmd ;
					if ($@)
					{
						print $@ ;
					}
					else 
					{
						# loaded ok
						$loaded = $cmd ;

						dumpvar($namespace) if $DEBUG ;
					}

					close $fh ;
					last ;
		       }
			}

			last if $realfilename ;
	   }


	   unless ($realfilename)
	   {
		   print "Can't find $filename in \@PHP_INC\n" ;
		   print "\@PHP_INC is:\n" ;
		   print "  $_\n" foreach (@PHP_INC) ;
		   die ;
	   }

	}


	return ($loaded) ;
}


# ============================================================================================
# UNEXPORTED BY DEFAULT
# ============================================================================================

#---------------------------------------------------------------------
#
sub process_scalar
{
    my ($val) = @_;

	# Convert string concatenation
	$val =~ s/([\"\']\s*)\./$1+/g ;
	$val =~ s/\.(\s*[\"\'])/+$1/g ;
		
	return $val ;
}

#---------------------------------------------------------------------
# Copied from Advanced Perl Programming book
#
sub dumpvar 
{
    my ($packageName) = @_;
    local (*alias);             # a local typeglob

    print "Dumping variables for module $packageName\n";

no strict ;

    # We want to get access to the stash corresponding to the package
    # name
    *stash = *{"${packageName}::"};  # Now %stash is the symbol table
    $, = " ";                        # Output separator for print
    # Iterate through the symbol table, which contains glob values
    # indexed by symbol names.
    while (($varName, $globValue) = each %stash) {
        print "$varName ============================= \n";
        *alias = $globValue;
        if (defined ($alias)) {
            print "\t \$$varName $alias \n";
        } 
        if (defined (@alias)) {
            print "\t \@$varName @alias \n";
        } 
        if (%alias) {
            print "\t \%$varName ",%alias," \n";
        }
     }
use strict ;

}

# ============================================================================================
# BEGIN
# ============================================================================================
BEGIN
{
	## Create include path for PHP files ##
	my @PHP_INI_LIST = () ;
	if ($PHP_INCLUDE_EXISTING)
	{
		# Allow the inclusion of other existing PHP libraries (NOTE: This may cause name clashes)
		@PHP_INI_LIST = qw(/etc/php5/apache2/php.ini /etc/php5/php.ini /etc/php.ini) ;
	}
	
	if ($^O =~ /mswin/i)
	{
		# Special debug variant when running XAMP on Windows (default location)
		push @PHP_INI_LIST, "C:/xampp/php/php.ini" ;
	}
	
	
	## Look for the php.ini file to use ##
	my $PHP_INI ;
	while (!$PHP_INI && @PHP_INI_LIST)
	{
		my $f = shift @PHP_INI_LIST ;
		if (-f $f)
		{
			$PHP_INI = $f ;
		}
	}
#
	my %php_paths ;

	## Start with parsing the php.ini file (if found) ##
	if ($PHP_INI)
	{
		if (open my $phpini, "<$PHP_INI") 
		{
			# Looking for:
			# include_path = "<path1>:<path2>.."
			my $line ;
			while (defined($line=<$phpini>)) 
			{
				chomp $line ;
	
				# strip out comments & space
				$line =~ s/;.*$// ;
				$line =~ s/^\s+// ;
				$line =~ s/\s+$// ;
	
				# skip empty
				next unless $line ;
	
				# Check for include path
				if ($line =~ /include_path\s*=\s*[\"]{0,1}([^\s\"]+)[\"]{0,1}/) 
				{
					my @paths = split(/:/, $1) ;
					
					# map to paths
					foreach (@paths)
					{
						push @PHP_INC, $_ ;
						$php_paths{$_} = 1 ;
					}
	
					last ;
				}
			}
			close $phpini ;
		}
	}


	## Assume php is under the installed application directory	
	my $local_php = "$PHP_APP_PATH/php" ;
	push @PHP_INC, $local_php ;
	$php_paths{$local_php} = 1 ;
	
	# Use env var if set
	if (exists($ENV{'PHPLIB'})) 
	{
		my @paths = split(/:/, $ENV{'PHPLIB'}) ;
		
		# map to paths - removes duplicates
		foreach (@paths)
		{
			push @PHP_INC, $_ unless exists($php_paths{$_}) ;
			$php_paths{$_} = 1 ;
		}
	}

	# Add perl libs
	foreach (@INC)
	{
		push @PHP_INC, $_ unless exists($php_paths{$_}) ;
		$php_paths{$_} = 1 ;
	}

	print "PHP_INC: @PHP_INC\n" if $DEBUG ;

}


# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

__END__



