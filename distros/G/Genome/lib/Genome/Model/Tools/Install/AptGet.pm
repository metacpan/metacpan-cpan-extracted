package Genome::Model::Tools::Install::AptGet;
use strict;
use warnings;
use Genome;
use IPC::Cmd qw/can_run/;

class Genome::Model::Tools::Install::AptGet {
    is => 'Command',
    has => [
        name => { is => 'Text', is_optional => 1, shell_args_position => 1, doc => 'tool name', },
    ],
    doc => 'install modules via APT'
};

sub execute {
    my $self = shift;

    my $module = $self->name;

    unless ($module) {
        $self->error_message("Please specify the name of a tool to install.");
        return;
    }

    my $path = can_run('apt-get');
    chomp $path;
    unless ($path) {
        unless (can_run('apt-get')) {
            $self->error_message("Your system does not have apt-get installed!");
            return;
        }
    }

    $self->status_message("searching for $module...");

    my $cmd = "$path -q update && $path search \'^$module\$\'";
    my $info = `$cmd`;
    unless ($info) {
        $self->status_message("Failed to find module $module!");
        return;
    }

    my $rv = system "$path install $module";
    $rv /= 256;

    if ($rv) {
        $self->error_message("Errors installing $module!");
        return;
    }

    return 1;
}

sub sub_command_sort_position { 9999 }

1;

