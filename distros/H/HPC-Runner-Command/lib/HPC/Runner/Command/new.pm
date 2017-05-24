use strict;
use warnings;
package HPC::Runner::Command::new;

use IPC::Cmd qw[can_run];
use File::Basename;
use Cwd;
use File::Path qw(make_path remove_tree);
use YAML::XS;

use MooseX::App::Command;
extends 'HPC::Runner::Command';
with 'MooseX::App::Role::Log4perl';

command_short_description 'Create a new project';
command_long_description 'This creates a new project, initializes git and direcotry structure.';

=head1 HPC::Runner::Command::new

Create a new project using
    hpcrunner.pl new

=head2 Command Line Options

parameter 'projectname' => (
    is                => 'rw',
    isa               => 'Str',
    documentation     => q[Your Project Name],
    required          => 1,
);

=head2 Subroutines

=head3 execute_command

Execute short commands

=cut

sub execute_command{
    my($self, $cmd, $info) = @_;
    my $buffer = "";

    if( scalar IPC::Cmd::run( command => $cmd,
            verbose => 0,
            buffer  => \$buffer )
    ) {
        $self->log->info("$info: $buffer\n") if $info;
    }
    else{
        $self->log->warn("Something went wrong with the cmd: $cmd!\n");
    }
}

sub execute{
    my $self = shift;

    my $project = $self->projectname;

    #$DB::single=2;
    make_path($self->projectname."/conf");
    make_path($self->projectname."/script");
    make_path($self->projectname."/data");
    make_path($self->projectname."/hpcrunner");

    chdir $self->projectname;
    $self->gen_project_yml;
    $self->gen_gitignore;

    $self->log->info("By default ./data and ./hpcrunner are added to your git ignore.");

    #$DB::single=2;

    $self->log->info("Setup complete!");
}

sub gen_project_yml {
    my($self)  = @_;

    open(my $p, ">.project.yml") or die print "Couldn't open a file for writing! $!\n";

    my $hash = {ProjectName => $self->projectname, TopDir => getcwd(), LogDir => getcwd()."/hpcrunner/logs", BlogDir => getcwd()."/hpcrunner/www/hexo/"};
    print $p Dump $hash;

    close $p;

    $self->log->info("$self->{projectname} Initialized...");
}

sub gen_gitignore {
    my $self = shift;

    $self->execute_command("git init", "Git repo successfully initialized : ");

    open(my $p, ">.gitignore") or die print "Couldn't open a file for writing! $!\n";

    print $p "data\n";
    print $p "hpcrunner\n";

    $self->execute_command("git add .gitignore", "Added .gitignore...");

    close $p;
}

1;
