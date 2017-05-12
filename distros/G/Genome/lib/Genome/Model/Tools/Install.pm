package Genome::Model::Tools::Install;
use strict;
use warnings;
use Genome;
use IPC::Cmd qw/can_run/;

class Genome::Model::Tools::Install {
    is => 'Command',
    has => [
        name    => { is => 'Text', is_optional => 1, shell_args_position => 1, 
                    doc => 'tool name', },
    ],
    doc => 'install more modules'
};

sub is_sub_command_delegator { 0 };

sub help_synopsis {
    return <<EOS;
 genome install music
 genome music ...

 genome install annotate
 genome annotate ...
EOS
}

sub help_detail {
    return <<EOS
Install new geomics software.

When run with no parameters, the available tools will be listed by name.
EOS
}

# our @STRATEGIES = ('apt-get', 'yum', 'homebrew', 'port', 'cpanm', 'curl');
our @STRATEGIES = ('apt-get', 'cpanm', 'curl');

sub execute {
    my $self = shift;

    # TODO:
    my $strategy;
    my $delegate;
    for my $executable (@STRATEGIES) {
        if (can_run($executable)) {
            $strategy = $executable;
            my @words = map { ucfirst(lc($_)) } split(/-/,$strategy);
            $delegate = __PACKAGE__ . '::' . join('',@words);
            eval "use $delegate";
            if ($@) {
                $self->warning_message("$executable is installed on your system, but no $delegate module was found!");
                $strategy = undef;
                $delegate = undef;
                next;
            }
            else {
                $self->status_message("install via $strategy...");
                last;
            }
        }
        else {
            # print "no $executable installed\n";
        }
    }

    unless ($strategy) {
        $self->error_message("No installation tools available!  Failed to find any of these: @STRATEGIES.  Your system is in need of help. :(");
        return;
    }

    return $delegate->execute(name => $self->name);
}

sub sub_command_sort_position { 9999 }

1;

