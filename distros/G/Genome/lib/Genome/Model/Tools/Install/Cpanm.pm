package Genome::Model::Tools::Install::Cpanm;
use strict;
use warnings;
use Genome;

class Genome::Model::Tools::Install::Cpanm {
    is => 'Command',
    has => [
        name    => { is => 'Text', is_optional => 1, shell_args_position => 1, 
                    doc => 'tool name', },
    ],
    doc => 'install modules from CPAN'
};

sub execute {
    my $self = shift;

    my $name = $self->name;
    unless ($name) {
        $self->error_message("Please specify the name of a tool to install.");
        $self->status_message("Checking CPAN for genome modeling tools...");
        my $cmd = "curl --progress-bar -L 'http://search.cpan.org/search?query=Genome::Model::Tools&mode=all' | grep class=sr";
        my @rows = `$cmd`;
        chomp @rows;
        my @modules;
        for my $row (@rows) {
            if ( my ($module) = ($row =~ m{lib/(Genome/Model/Tools/.*\.pm)}) ) {
                push @modules, $module;
            }
        }
        if (@modules) {
            $self->status_message(join("\n",@modules));
        }
        else {
            $self->status_message("*** no uninstalled modules available ***");
        }
        return;
    }   
    
    my @words = map { ucfirst(lc($_)) } split("-", $name);
    my $module = 'Genome::Model::Tools::' . join('',@words);

    my $path = `which cpanm`;
    chomp $path;
    unless ($path) {
        unless (`which curl`) {
            $self->error_message("Your system does not have cpanm or curl installed.  Please install one of these to use the genome installer!");
            return;
        }
        $self->status_message("Installing cpanm...");
        my $cmd = "curl --progress-bar -L http://cpanmin.us | perl - --sudo App::cpanminus";
        system $cmd;
        $path = `which cpanm`;
        unless ($path) {
            $self->status_message("Failed to install cpanm!  Attempting direct stream from the Internet...");
           $path = "curl --progress-bar -L http://cpanmin.us | perl - --sudo ";
        }
    }

    $self->status_message("searching for $module...");
   
    my $cmd = "$path --info $module";
    my $info = `$cmd`;
    unless ($info) {
        $self->status_message("Failed to find module $module!");
        return;
    }
    
    my $rv = system "$path --progress-bar $module";
    $rv /= 256;

    if ($rv) {
        $self->error_message("Errors installing $module!");
        return;
    }

    return 1;
}

sub sub_command_sort_position { 9999 }

1;

