package HPC::Runner::Command::stats::Logger::JSON::TableOutput;

use Moose::Role;
use namespace::autoclean;

use Text::ASCIITable;

## TODO This one is mostly the same
sub build_table {
    my $self = shift;
    my $res  = shift;

    my $start_time = $res->{submission_time} || '';
    my $project    = $res->{project}    || '';
    my $id         = $res->{uuid}       || '';
    my $header     = "Time: " . $start_time;
    $header .= " Project: " . $project;
    $header .= "\nSubmissionID: " . $id;
    my $table = Text::ASCIITable->new( { headingText => $header } );

    return $table;
}

1;
