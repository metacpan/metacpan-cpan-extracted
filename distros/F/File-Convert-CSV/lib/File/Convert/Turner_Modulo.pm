package File::Convert::Turner_Modulo;

=head1

;version,4
PlateResults
,Read 1
,,1,2,3,4,5,6,7,8,9,10,11,12
,A,54.0001,62.0002,44.0001,44.0001,48.0001,52.0001,50.0001,64.0002,64.0002,52.0001,60.0002,72.0002
,B,3470.58,2638.33,2154.22,3388.55,3822.7,3228.5,922.041,1628.13,2866.39,3658.64,1962.19,812.032
,C,1530.11,2872.4,2246.24,2838.39,2510.3,3626.63,1906.17,1636.13,2750.36,2220.24,1772.15,2030.2
,D,1938.18,4470.96,4655.04,4510.98,2804.38,4156.83,1958.18,1468.1,3850.71,2510.3,2382.27,2304.25
,E,2574.32,5967.71,5013.21,5521.46,4360.91,4827.12,3022.44,3426.56,4811.11,2380.27,2004.19,2136.22
,F,1310.08,5007.2,3426.56,2900.4,2516.3,3682.65,1220.07,546.014,3182.49,2888.4,2584.32,2122.22
,G,1792.15,4815.11,3852.71,2446.29,2298.25,1872.17,974.046,858.035,1880.17,1420.1,1748.15,2030.2
,H,1510.11,1754.15,3044.44,3118.47,1836.16,1328.08,672.022,406.008,986.047,814.032,1446.1,1736.14

ProtocolHeader
,Version,,1.0
,Label,,mue.AandB.8Nov.25ul
,Locked,,False
,Creator,,User
,ReaderType,,1
,Category,,0
,FluoroFilter,,4
,DateRead,,11/8/2007 7:03:36 PM
,Filename,,beforeAcII_mue.AandB.8Nov.25ul_11-8-2007_7-03-36 PM
,InstrumentSN,,SN: 930000207060
,FluoOpticalKitID,,
,Result,,0
,Prefix,,beforeAcII
,WellMap,,FFFFFFFFFFFFFFFFFFFFFFFF
,RefWellMap,,000000000000000000000000
,RunCount,,1
,RunPeriod,,60
,PreRunDelay,,0
,Kinetics,,False
,KineticCount,,10
,KineticIntTime,,0.5

Steps
,Injector,,0,1
,Inject,,False,False
,Volume,,25,25
,Delay,,0.5,3
,Read,,True,False
,PostDelay,,0,0
,IntegrationTime,,0.5,0.5
,WavelengthCount,,1,1
,Wavelength1,,450,450
,Wavelength2,,450,450

Results
,Well,Read 1
,A1,54.0001

=cut

use strict;
use warnings;

use File::Convert::CSV;

use Data::Iter qw(:all);

use Data::Dump qw(dump);

Class::Maker::class
{
    isa => [qw( File::Convert::CSV )],

    public => 
    {
	hash => [qw( file_info )],
    },
    
    default =>
    {
	has_header => 1,
	
	separator => ",",
	
	skip_pattern => qr/^;/,
	
	skip_callback => sub { warn "Skipped line", @_ }
	
    },
};

sub is_kinetic : method
{
    my $this = shift;

    return join( '', @{ $this->data_file } ) =~ /PlateResults/mi;
}

sub preformat_data_file : method
{
    my $this = shift;
    
    
    my $result;

    $this->d_croak( "Results is a field expected in each Turner Modulo Results file. This was not found and format is putativly wrong." ) unless join( '', @{ $this->data_file } ) =~ /Results/mi;

    for( iter scalar $this->data_file )
    {
	if( VALUE() =~ /^,Well,/ )
	{
	    splice @{$this->data_file}, 0, COUNTER-1;

	    $this->d_warn( "FILE_INFO %s", Data::Dump::dump( { $this->file_info } ) );

	    return;
	}

	$this->d_warn( "omitting header line %s", VALUE() ); 

	my $line = VALUE();

	chomp $line;

	$line =~ s/\r$//gi;

	if( $line =~ /,,/ )
	{
	    my ($key, $value ) = split /\s?,,\s?/, $line;
	    
	    $this->file_info->{$key} = $value;
	}
    }
}

1;
