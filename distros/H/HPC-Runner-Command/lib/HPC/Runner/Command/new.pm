package HPC::Runner::Command::new;

use MooseX::App::Command;
use namespace::autoclean;

use IPC::Cmd qw[can_run];
use File::Basename;
use Cwd;
use File::Path qw(make_path remove_tree);
use YAML::XS;
use File::Spec;
use File::Slurp;

extends 'HPC::Runner::Command';
with 'MooseX::App::Role::Log4perl';

command_short_description 'Create a new project';
command_long_description
  'This creates a new project, initializes git and directory structure.';

=head1 HPC::Runner::Command::new

Create a new project using
    hpcrunner.pl new

=head2 Command Line Options

=cut

option 'project' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Project name for your analysis project.',
    required  => 1,
    predicate => 'has_project',
    cmd_aliases => ['p'],
);

=head2 Subroutines

=head3 execute_command

Execute short commands

=cut

sub execute_command {
    my ( $self, $cmd, $info ) = @_;
    my $buffer = "";

    if (
        scalar IPC::Cmd::run(
            command => $cmd,
            verbose => 0,
            buffer  => \$buffer
        )
      )
    {
        $self->log->info("$info: $buffer\n") if $info;
    }
    else {
        $self->log->warn("Something went wrong with the cmd: $cmd!\n");
    }
}

sub execute {
    my $self = shift;

    my $project = $self->project;

    ###$DB::single=2;
    make_path( File::Spec->catdir($self->project , "conf") );
    make_path( File::Spec->catdir($self->project , "script") );
    make_path( File::Spec->catdir($self->project , "data") );
    make_path( File::Spec->catdir($self->project , "hpc-runner") );

    chdir $self->project;
    $self->gen_project_yml;
    $self->gen_gitignore;

    $self->log->info(
        "By default ./data and ./hpcrunner are added to your git ignore.");

    $self->log->info("Setup complete!");
}

sub gen_project_yml {
    my ($self) = @_;

    my $hash = {
        ProjectName => $self->project,
        TopDir      => getcwd(),
        LogDir      => File::Spec->catdir(cwd() , "hpc-runner", "logs"),
        BlogDir     => File::Spec->catdir(cwd() , "hpc-runner", "www", "hexo")
    };

    write_file('.project.yml', Dump $hash);

    $self->log->info("Project: ".$self->project." Initialized...");
}

sub gen_gitignore {
    my $self = shift;

    $self->execute_command( "git init",
        "Git repo successfully initialized : " );

    write_file('.gitignore', "data\nhpc-runner");

    $self->execute_command( "git add .gitignore", "Added .gitignore..." );
}

__PACKAGE__->meta()->make_immutable();

1;
