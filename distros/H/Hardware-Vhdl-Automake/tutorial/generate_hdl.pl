use strict;
use warnings;
use Hardware::Vhdl::Automake::Project;

sub output_status;

my $project_dir = 'C:/hva_tutorial';

# create a new project
my $project = Hardware::Vhdl::Automake::Project->new();

# load the project
$project->load($project_dir . '/tutorial.hdlproj');

# Tell the project how to report status
$project->set_status_callback( \&output_status );

# Generate the HDL files
$project->generate_all;

# save the project, using the last save filename
$project->save;

sub output_status {
    my $report = shift;
    local $|=1;
    #~ print Dump($report);
    print $report->{text};
    if (exists $report->{duname}) {
        print ': '.$report->{duname}->short_string;
    }
    if (exists $report->{file}) {
        print ': '.$report->{file};
    }
    print "\n";
}
