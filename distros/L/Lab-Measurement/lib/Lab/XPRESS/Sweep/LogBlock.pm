package Lab::XPRESS::Sweep::LogBlock;

use Role::Tiny;
requires qw/LOG write_LOG/;

use 5.010;

use Carp;

use Data::Dumper;

our $VERSION = '3.543';

=pod

=head1 NAME

Lab::XPRESS::Sweep::LogBlock -- Sweep add-on for matrix logging.

=head1 SYNOPSIS

   # define your columns

   # parameters controlled by the XPRESS sweeps
   $DataFile->add_column('gate');
   $DataFile->add_column('bias');

   # parameters in the block, here we have a block with 2 columns.
   $DataFile->add_column('frequency');
   $DataFile->add_column('transmission');

   # Define your sweeps ... 

   # In your measurement subroutine: Get block and log
   $matrix = $instrument->get_block(...)   
   $sweep->LogBlock(
	prefix => [$gate, $bias],
	block => $matrix);

=head1 DESCRIPTION
    
This role exports the single method C<LogBlock>. The valid parameters are:

=over

=item block (mandatory)

List of rows (e.g. C<[[1, 2, 3], [2, 3, 4]]>), which shell be written
 to the data file.

=item prefix

List of parameters which shell be prefixed to each row of the block.

=item file

Index of the target data file (default: 0).

=back
    
=cut

sub LogBlock {
    my $sweep = shift;

    if ( @_ % 2 != 0 ) {
        croak "expected hash";
    }

    my %args = @_;

    my $block = $args{block};
    if ( not defined $block ) {
        croak "missing mandatory parameter 'block'";
    }

    my $prefix = $args{prefix};
    if ( not defined $prefix ) {
        $prefix = [];
    }

    my $prefix_len = @$prefix;

    my $file = $args{datafile};
    if ( not defined $file ) {
        $file = 0;
    }

    my $num_rows = @$block;
    my $row_len  = @{ $block->[0] };

    # Extract column header from the DataFile
    my $datafile    = $sweep->{DataFiles}[$file];
    my $columns     = $datafile->add_column();
    my $columns_len = @$columns;

    if ( $row_len + $prefix_len != $columns_len ) {
        croak "The datafile expects $columns_len columns.\n"
            . "You only supplied $prefix_len + $row_len columns.";
    }

    # Write external parameters and block to datafile

    while ( my ( $i, $row ) = each(@$block) ) {
        my %log;
        unshift @$row, @$prefix;

        while ( my ( $j, $key ) = each(@$columns) ) {
            $log{$key} = $row->[$j];
        }

        $sweep->LOG( {%log}, $file );

        if ( $i != $num_rows - 1 ) {

            # the last writeLOG is called in Sweep.pm
            $sweep->write_LOG();
        }

    }

}

1;

