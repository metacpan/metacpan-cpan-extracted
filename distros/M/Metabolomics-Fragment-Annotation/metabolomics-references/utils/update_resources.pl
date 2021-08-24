#!c:\Perl\bin\perl.exe -w

=head1 NAME

update_resources.pl - Utility to update all databases referenced in metabolomics-references project.

=head1 USAGE


=head1 SYNOPSIS

=head1 DESCRIPTION

=over 4

=item B<function01>

=item B<function02>

=back

=head1 AUTHOR

Prenom Nom E<lt>franck.giacomoni@inrae.frE<gt>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc update_resources.pl

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 VERSION

version 1 : 2020/04/24

version 2 : ??

=cut
#=============================================================================
#                              Included modules and versions
#=============================================================================
## Perl modules
use strict ;
use warnings ;
use diagnostics ;
use Carp qw (cluck croak carp) ;

use Data::Dumper ;
use Getopt::Long ;
use File::Basename ;
use FindBin ; ## Allows you to locate the directory of original perl script

use Text::CSV ;
use LWP::UserAgent ;

## Specific Perl Modules (PFEM)
use lib $FindBin::Bin ;

## Dedicate Perl Modules (Home made...)

## Initialized values
my $ProgramName = basename($0) ;
my $OptionHelp = undef ;
my $VerboseLevel = undef ;

## Config var
my $Database = 'MTHFRAG' ; # DB: KNAPSACK, MTHFRAG
my $Input = '../MS_fragments-adducts-isotopes__V1.1.txt' ;
my $databaseFile = '../Knapsack__V1_1.csv' ;
my $databaseNewFile = './tmp/Knapsack.new' ;
my $databaseUrl = 'http://www.knapsackfamily.com/knapsack_core/info.php?sname=C_ID&word=' ;


#=============================================================================
#                                Manage EXCEPTIONS
#=============================================================================
&GetOptions ( 	"h|help" 		=> \$OptionHelp,       	# HELP
				"v|verbose=i" 	=> \$VerboseLevel,		# Level of verbose (0 to 2)
				"database=s" 	=> \$Database,			# DB: knapsack, ...
				"input|i=s" 	=> \$Input,			# DB: KNAPSACK, MTHFRAG
            ) ;
         
## if you put the option -help or -h function help is started
if ( defined($OptionHelp) ){ &help ; }

#=============================================================================
#                                MAIN SCRIPT
#=============================================================================

if ( (defined $Database) and ($Database eq 'KNAPSACK') ) {
	&updateKnapsack($databaseFile) ;
}
elsif ( (defined $Database) and ($Database eq 'MTHFRAG') ) {
	&validateMTHFragmentList($Input) ;
	
}

=head2 METHOD validateMTHFragmentList

	## Description : validate a new released fragments list file by parsing content and counting lines
	## Input : $dbFile
	## Output : 0
	## Usage : &validateMTHFragmentList ( $dbFile ) ;
	
=cut
## START of SUB
sub validateMTHFragmentList {
    ## Retrieve Values
    
    my ( $source  ) = @_;
    
    my %fragment = (
    	_TYPE_ => 'type',
    	_DELTA_MASS_ => 'delta_mass',
    	_LOSSES_OR_GAINS_ => 'losses_or_gains',
    	_ANNOTATION_IN_POS_MODE_ => 'annotation_in_pos_mode',
    	_ANNOTATION_IN_NEG_MODE_ => 'annotation_in_neg_mode',
    ) ;
    
    my $entriesNb = 0 ;
    my $checker = 0 ;
    my @fragments = () ;
    
    print "##\n## * * * VALIDATION OF $source * * * ##\n##\n" ;
    
    my $csv = Text::CSV->new ( { 'sep_char' => "\t", binary => 1, auto_diag => 1, eol => "\n" } )  # should set binary attribute.
    		or die "Cannot use CSV: ".Text::CSV->error_diag ();
    	
    open my $fh, "<", $source or die "$source: $!";
    

    	
	## Checking header of the source file   	
    $csv->header ($fh, { munge_column_names => sub {
	    s/\s+$//;
	    s/^\s+//;
	    my $uc_col = '_'.uc$_.'_' ;
	    if ($_ ne 'example_valine' ) {
	    	
	    	$fragment{$uc_col} or die "Unknown column '$_' in $source";
	    }
	}});
		
    	while (my $row = $csv->getline_hr ($fh)) {
    		
    		my %currentFrag =  %fragment ;
    		
    		print "[INFO] START checking line $entriesNb...\t\t" ;

    		## Check and control TYPE
    		if ( ($row->{'type'} ) and ( ($row->{'type'} eq 'adduct') or ($row->{'type'} eq 'isotope') or ($row->{'type'} eq 'fragment') or ($row->{'type'} eq 'pseudomolecular ion') ) ) {
    			$currentFrag{_TYPE_} = $row->{'type'} ;
    			$checker++ ;
    		}
    		else {
    			warn "\t[WARN] The type for line $entriesNb is undef or unknown ($row->{'type'}) \n" ;
    			$currentFrag{_TYPE_} = undef ;
    		}
    		
    		## Check and control DELTA_MASS
    		if ( ($row->{'delta_mass'} ) and ($row->{'delta_mass'} > 0 or $row->{'delta_mass'} < 0) ) {
    			$currentFrag{_DELTA_MASS_} = $row->{'delta_mass'} ;
    			$checker++ ;
    		}
    		else {
    			warn "\t[WARN] The delta_mass for line $entriesNb is undef or equal to 0\n" ;
    			$currentFrag{_DELTA_MASS_} = undef ;
    		}
    		
    		## Check and control LOSSES OR GAINS
    		if ( ($row->{'losses_or_gains'} ) and ($row->{'losses_or_gains'} ne '' ) ) {
    			$currentFrag{_LOSSES_OR_GAINS_} = $row->{'losses_or_gains'} ;
    			$checker++ ;
    		}
    		else {
    			warn "\t[WARN] The losses or gains for line $entriesNb is undef or void\n" ;
    			$currentFrag{_LOSSES_OR_GAINS_} = undef ;
    		}
    		
    		
    		$currentFrag{_ANNOTATION_IN_POS_MODE_} = $row->{'annotation_in_pos_mode'} ;
    		$currentFrag{_ANNOTATION_IN_NEG_MODE_} = $row->{'annotation_in_neg_mode'} ;
    		
    		my %tmp = %currentFrag ;
    		push(@fragments, \%tmp ) ;
     		
     		## Checker control 
     		if ($checker == 3 ) {	print " line is OK\n" ;		} # end of the message
     		if ($checker < 3 ) {	print "\n" ;		}
     		$checker = 0 ;
     		
     		$entriesNb ++ ;
    	}
    
    print Dumper @fragments ;
    
    return (0) ;
}
### END of SUB





=head2 METHOD updateKnapsack

	## Description : update Knapsack database on its web portal by crawling
	## Input : $var3
	## Output : $var4
	## Usage : my ( $var4 ) = updateKnapsack ( $var3 ) ;
	
=cut
## START of SUB
sub updateKnapsack {
    ## Retrieve Values
    
    my ( $dbFile,  ) = @_;
    my ( $lastID, $nbEntries ) = ( 0, 0 ) ;
    
    ## based on http://www.knapsackfamily.com/knapsack_core/information.php?sname=C_ID&word=C00000001
    
    ## Get Last id in last CSV file version
    
    print "[INFO] Parsing Knapsack current version...\n" ;
    
    my $csv = Text::CSV->new ( {'sep_char' => ",", binary => 1 } )  # should set binary attribute.
    	or die "Cannot use CSV: ".Text::CSV->error_diag ();
    
     
	open my $fh, "<:encoding(utf8)", $dbFile or die "Can't open csv file $dbFile: $!";
	
	while ( my $row = $csv->getline( $fh ) ) {
		
		if ($row->[0] eq 'knapsackid') {
			next ;
		}
		
#		print Dumper $row ;
		if ( $row->[0] =~ /^C([0-9]*)/ ) {
			$nbEntries++ ;
			
			my $id = $1 ;
			
			if ( (defined $id ) and ($id > $lastID) ) {
				$lastID = $id ;
			}
			else {
				next ;
			}
		}
	}
	$csv->eof or $csv->error_diag();
	close $fh;
	
    print "[INFO] Knapsack db parsed with: $nbEntries entries\n" ;
    print "[INFO] Last Knapsack id in exported db is: $lastID\n" ;
    
    
    ## test if new ids exists on knapsack online db
    # Knapsack ID format is 00051737
    
    my $tryAgain = 'TRUE' ;
    my ($runNbTrue, $runNbFalse) = (0, 0) ;
    my $thresholdFalse = 10 ;
    my $thresholdTrue = 1000 ;
    my %NewKnapSackDump = () ;
    my $newId = $lastID ; 
    
    
    while ($tryAgain eq 'TRUE') {
    
	    $newId = $newId+1 ;
	#    my $newId = 53000 ;
	    my $newFormattedId =  'C'.sprintf '%08s', $newId ; 
	    
	    print "[INFO] Trying to find new data with Knapsack id: $newFormattedId\n" ;
	    
	    if (defined $newFormattedId) {
	    	
	    	my $url = 'http://www.knapsackfamily.com/knapsack_core/information.php?sname=C_ID&word='.$newFormattedId ;
	    	my $ua = LWP::UserAgent->new;
			my $results = $ua->get("$url");
			
			if ($results->content =~/<font class=er>Input key word error!! <br>/) {
				# Error msg with http://www.knapsackfamily.com/knapsack_core/information.php?sname=C_ID&word=C00053000
				
				print "[WARN] This ID ($newFormattedId) doesn't exist in knapsack db today\n" ;
				$runNbFalse ++ ;
				
				if ($runNbFalse >= $thresholdFalse) {
					$tryAgain = 'FALSE' ;
				}
			}
			else {
				$runNbTrue ++ ;
				$runNbFalse = 0 ;
				my $id = undef ;
				
				## Parsing data
				if ($results->content =~/<title>KNApSAcK Metabolite Information - (.*)<\/title>/) {
					$NewKnapSackDump{$1}{'knapsackid'} = $1 ;
					$id = $1 ;
				}
				if ($results->content =~/<th class="inf">Name<\/th>\n\s+<td colspan="4" class="inf">(.*)<\/td>/) {
					my $tempname = $1 ;
					if ($tempname =~/<br>/) {
						my @names = split (/<br>/,$tempname ) ;
						$NewKnapSackDump{$id}{'name'} = $names[0] ;
					}
					else {
						$NewKnapSackDump{$id}{'name'} = $tempname ;
					}
					
					
					
					
					
				}
				if ($results->content =~/<th class="inf">Formula<\/th>\n\s+<td colspan="4">(.*)<\/td>/) {
					$NewKnapSackDump{$id}{'formula'} = $1 ;
				}
				if ($results->content =~/<th class="inf">Mw<\/th>\n\s+<td colspan="4">(.*)<\/td>/) {
					$NewKnapSackDump{$id}{'mw'} = $1 ;
				}
				if ($results->content =~/<th class="inf">CAS RN<\/th>\n\s+<td colspan="4">(.*)<\/td>/) {
					$NewKnapSackDump{$id}{'cas'} = $1 ;
				}
				if ($results->content =~/<th class="inf">InChIKey<\/th>\n\s+<td colspan="4">(.*)<\/td>/) {
					$NewKnapSackDump{$id}{'inchikey'} = $1 ;
				}
				if ($results->content =~/<th class="inf">InChICode<\/th>\n\s+<td colspan="4">(.*)<\/td>/) {
					$NewKnapSackDump{$id}{'inchi'} = $1 ;
				}
				
				## Cutoff !
				if ($runNbTrue >= $thresholdTrue) {
					$tryAgain = 'FALSE' ;
				}
			}
#			print Dumper $results->content ;
	    } 
    }
    
#    print Dumper %NewKnapSackDump ;

    ## print into file
    
    open(CSV, '>:utf8', $databaseNewFile) or die "Cant' create the file $databaseNewFile\n" ;
    
    foreach my $id (sort keys %NewKnapSackDump) {
    	
    	## Generate missing inchikey based on inchi
    	# TODO...
    	
    	#knapsackid,name,formula,mw,cas,inchikey
    	
    	# Avoid compound without cpd_name and exact_mass...
    	if ( ( $NewKnapSackDump{$id}{'name'} ) and ( $NewKnapSackDump{$id}{'name'} ne '' ) and ( $NewKnapSackDump{$id}{'mw'} ) and ( $NewKnapSackDump{$id}{'mw'} > 0 ) ) {
    		print "$id,\"$NewKnapSackDump{$id}{'name'}\",$NewKnapSackDump{$id}{'formula'},$NewKnapSackDump{$id}{'mw'},$NewKnapSackDump{$id}{'cas'},$NewKnapSackDump{$id}{'inchikey'}\n" ;
    		print CSV "$id,\"$NewKnapSackDump{$id}{'name'}\",$NewKnapSackDump{$id}{'formula'},$NewKnapSackDump{$id}{'mw'},$NewKnapSackDump{$id}{'cas'},$NewKnapSackDump{$id}{'inchikey'}\n" ;	
    	}
    	
    	
    }
    
    close(CSV) ;
    
    
    return () ;
}
### END of SUB









#====================================================================================
# Help subroutine called with -h option
# number of arguments : 0
# Argument(s)        :
# Return           : 1
#====================================================================================
sub help {


print STDERR <<EOF ;
### $ProgramName ###
#
# AUTHOR:     Franck Giacomoni
# VERSION:    1.0
# CREATED:    2020/04/24
# LAST MODIF: 
# PURPOSE:
# USAGE: $ProgramName or $ProgramName -o options 
EOF
exit(1) ;
}

## END of script - F Giacomoni 

__END__