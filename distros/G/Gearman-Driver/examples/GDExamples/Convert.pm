package    # hide from PAUSE
  GDExamples::Convert;

use base qw(Gearman::Driver::Worker);
use Moose;
use Imager;

sub process_name {
    my ( $self, $orig, $job_name ) = @_;
    return "$orig ($job_name)";
}

sub convert_to_jpeg : Job : MinProcesses(0) : MaxProcesses(5) {
    my ( $self, $job, $workload ) = @_;
    return _convert( $workload, 'jpeg' );
}

sub convert_to_gif : Job : MinProcesses(0) : MaxProcesses(5) {
    my ( $self, $job, $workload ) = @_;
    return _convert( $workload, 'gif' );
}

sub _convert {
    my ( $in_data, $format ) = @_;
    my $img = Imager->new();
    my $out_data;
    $img->read( data => $in_data ) or die;
    $img->write( data => \$out_data, type => $format ) or die;
    return $out_data;
}

1;
