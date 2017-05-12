use strict;
use warnings;
use Hardware::Vhdl::Automake::Project;
use Hardware::Vhdl::Automake::Compiler::ModelSim;

sub output_status;

my $project_dir = 'C:/hva_tutorial';
my $modelsim_path = 'C:\ProgramFiles\Modeltech\win32pe';

# create a new project
my $project = Hardware::Vhdl::Automake::Project->new();

# load the project
$project->load($project_dir . '/tutorial.hdlproj');

# create a ModelSim compiler instance, and tell it where to put its compilation data
my $compiler = Hardware::Vhdl::Automake::Compiler::ModelSim->new({basedir => $project_dir."/sim"});

# Tell the compiler object where to find the compiler binaries
$compiler->set_modelsim_path($modelsim_path);

# Tell the project and the compiler how to report status
$project->set_status_callback( \&output_status );
$compiler->set_status_callback( \&output_status );

# Compile the HDL files
$project->compile($compiler);

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
