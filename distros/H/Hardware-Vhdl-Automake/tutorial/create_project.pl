use strict;
use warnings;
use Hardware::Vhdl::Automake::Project;

my $project_dir = 'C:/hva_tutorial';

# create a new project
my $project = Hardware::Vhdl::Automake::Project->new();

# add some files to it
$project->add_sourcefiles(
    $project_dir . '/src/adder.vhd', 
    { 
        # explicitly specifying target library and source language
        file => $project_dir . '/src/count_up.vhd', 
        library => 'work', 
        language => 'vhdl-93',
    }, 
);

# save the project
$project->save($project_dir . '/tutorial.hdlproj');

# change the directory used for the generated hdl files (default would be ~/vhdl/uart/uart_hdlproj_files)
$project->hdl_dir($project_dir . '/hdl');

# save the project, using the last save filename
$project->save;
