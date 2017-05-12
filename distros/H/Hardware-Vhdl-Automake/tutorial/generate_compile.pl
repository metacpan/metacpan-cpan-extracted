use strict;
use warnings;
use Hardware::Vhdl::Automake::Project;
use Hardware::Vhdl::Automake::Compiler::ModelSim;
use YAML;

sub output_status;

my $project_dir = 'C:/hva_tutorial';
my $modelsim_path = 'C:\ProgramFiles\Modeltech\win32pe';

# create a new project
my $project = Hardware::Vhdl::Automake::Project->new();

# load the project
$project->load($project_dir . '/tutorial.hdlproj');

# Tell the project how to report status
$project->set_status_callback( \&output_status );

# Generate the HDL files
$project->generate_all;

# create a ModelSim compiler instance, and tell it where to put its compilation data
my $compiler = Hardware::Vhdl::Automake::Compiler::ModelSim->new({basedir => $project_dir."/sim"});

# Tell the compiler object where to find the compiler binaries
$compiler->set_modelsim_path($modelsim_path);

# Tell the compiler how to report status
$compiler->set_status_callback( \&output_status );

# Compile the HDL files
$project->compile($compiler);

# save the project, using the last save filename
$project->save;

sub output_status {
    my $report = shift;
    local $| = 1;
    my $type = $report->{type};
    my $stdout = \*STDOUT;
    if ($type eq 'error' || $type eq 'warning') {
        print {$stdout} uc($type).": ".$report->{text}."\n";
        print $stdout "    line: ".$report->{sourceline}."\n" if defined $report->{sourceline};
        for my $st (qw/ src gen /) {
            if (defined $report->{$st.'file'}) {
                print $stdout "    $st: at ";
                my $fn = $report->{$st.'file'};
                $fn =~ s!/!\\!g;
                print $stdout $fn.' line '.$report->{$st.'linenum'};
                print $stdout "\n";
            }
        }
    } elsif ($type eq 'assert_fail') {
        print $stdout "ASSERTION FAIL: ".$report->{text}."\n";
        print $stdout "    expected: ".$report->{expected}."\n";
        print $stdout "    got: ".$report->{got}."\n";
    } elsif ($type eq 'generate1') {
        print $stdout "Generating HDL from source file ".$report->{file}."\n";
    } elsif ($type eq 'generated') {
        print $stdout "  generated ".$report->{duname}->short_string."\n";
    } elsif ($type eq 'generate2') {
        print $stdout "Generating (pass 2) ".$report->{duname}->short_string."\n";
    } elsif ($type eq 'hdl_copy') {
        print $stdout "copying new HDL for ".$report->{duname}->short_string." at ".$report->{file}." line 1\n";
    } elsif ($type eq 'compile_start') {
        print $stdout "\n".$report->{text}."\n";
    } elsif ($type =~ m/^(mklib|config|compile_finish|compile_abort)$/) {
        print $stdout $report->{text}."\n";
        #~ $self->{compiled_ok}=1 if $type eq 'compile_finish';
    } elsif ($type eq 'compile') {
        print $stdout "  compiling ".$report->{duname}->short_string."\t(because $report->{reason})\n";
    } elsif ($type eq 'compile_skip') {
        #print $stdout "  not compiling ".$report->{duname}->short_string."\n";
    } elsif ($type =~ m/^(generate1poss|generate2poss)$/) {
        # suppress output
    } else {
        print $stdout "\n".Dump($report);
    }
}