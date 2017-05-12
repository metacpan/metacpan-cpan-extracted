use strict;
use Test::More tests => 1;
use Data::Dumper ;

use lib './plib' ;
use Makeutils ;

	my $clib = "./clib" ;

	# Set up info for this module
	my $modinfo_href = init('Linux-DVB-DVBT-TS') ;

	## Check for current settings
	get_config() ;
	diag_config() ;
	
	#print STDERR Data::Dumper->Dump(["Info", \%Makeutils::ModuleInfo]) ;
	
#	diag_ctry('lrintf') ;
#	diag_ctry('inline') ;
#	diag_ctry('always_inline') ;

	diag("######################################################") ;
	pass('all ok') ;

	exit 0 ;


#-----------------------------------------------------------------------------------------------------------------------
sub diag_ctry 
{
	my ($info_tag) = @_ ;
	
	if (exists($Makeutils::ModuleInfo{'C_TRY'}{$info_tag}))
	{
		diag("######################################################") ;
		diag("----[ $info_tag ]----") ;
		foreach my $line (@{$Makeutils::ModuleInfo{'C_TRY'}{$info_tag}})
		{
			diag("$line") ;
		}
		diag("") ;
	}
}

#-----------------------------------------------------------------------------------------------------------------------
sub diag_config 
{
	diag("") ;
	diag("######################################################") ;
	diag("(Makeutils.pm version $Makeutils::VERSION)") ;

	foreach my $var (sort keys %{$Makeutils::ModuleInfo{'config'}})
	{
		my $padded = sprintf "%-24s", "$var:" ;
		my $val = $Makeutils::ModuleInfo{'config'}{$var} ;
		
		## Special cases
		
		# ENDIAN is multi-line
		if ($var eq 'ENDIAN')
		{
			if ($val =~ m/#define (\w+)/)
			{
				$val = "#define $1 1" ;
			}
			else
			{
				$val = "" ;
			}
		}
		
		# Check for comment
		if (exists($Makeutils::ModuleInfo{'COMMENTS'}{$var}))
		{
			$val .= "  ($Makeutils::ModuleInfo{'COMMENTS'}{$var})" ;
		}
		diag("$padded $val\n") ;
	}
	diag("") ;
}

