package File::Convert::Taqman;

=head1

Document Name: dok
Plate Type: Absolute Quantification
User: 7300Anwender

Document Information

Operator: 7300Anwender
Run Date: Monday, January 08, 2007 20:21:13
Last Modified: Monday, January 08, 2007 23:43:38
Instrument Type: Applied Biosystems 7300 Real-Time PCR System

Comments:
SDS v1.2

Well,Sample Name,Detector,Task,Ct,StdDev Ct,Qty,Mean Qty,StdDev Qty,Filtered,Tm
....
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
	
	skip_pattern => qr/^#/,
	
	skip_callback => sub {}
	
    },
};

sub is_file_valid : method
{
    my $this = shift;

    my $file = shift;


    open( FILE, $file ) or return 0;

    #$this->d_croak( "Only file format 'SDS v1.2' from the 'Applied Biosystems 7300 Real-Time PCR System' supported" ) unless join( '', @{ $this->data_file } ) =~ /SDS v1\.2/mi;

    my $data_file = join( '', <FILE> );

    if( $data_file =~ /SDS v1\.2/mi )
    {
	return 1;
    }

return 0;
}

sub preformat_data_file : method
{
    my $this = shift;
    
    
    my $result;

    $this->d_croak( "Only file format 'SDS v1.2' from the 'Applied Biosystems 7300 Real-Time PCR System' supported" ) unless join( '', @{ $this->data_file } ) =~ /SDS v1\.2/mi;
    
    for( iter scalar $this->data_file )
    {
	if( VALUE() =~ /^Well/ )
	{
	    splice @{$this->data_file}, 0, COUNTER-1;

	    $this->d_warn( "FILE_INFO %s", Data::Dump::dump( { $this->file_info } ) );

	    return;
	}

	$this->d_warn( "omitting header line %s", VALUE() ); 

	my $line = VALUE();

	chomp $line;

	$line =~ s/\r$//gi;

	if( $line =~ /:/ )
	{
	    my ($key, $value ) = split /\s?:\s?/, $line;
	    
	    $this->file_info->{$key} = $value;
	}
    }
}

1;
