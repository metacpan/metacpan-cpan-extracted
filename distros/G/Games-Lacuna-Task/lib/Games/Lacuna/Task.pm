# ============================================================================
package Games::Lacuna::Task;
# ============================================================================

use 5.010;
our $AUTHORITY = 'cpan:MAROS';
our $VERSION = "2.05";

use Moose;

use Games::Lacuna::Task::Types;
use Games::Lacuna::Task::Meta::Class::Trait::NoAutomatic;
use Games::Lacuna::Task::Meta::Class::Trait::Deprecated;
use Games::Lacuna::Task::Constants;

with qw(Games::Lacuna::Task::Role::Client
    Games::Lacuna::Task::Role::Logger
    Games::Lacuna::Task::Role::Actions);

has 'lockfile' => (
    is              => 'rw',
    isa             => 'Path::Class::File',
    traits          => ['NoGetopt'],
    lazy_build      => 1,
);

sub _build_lockfile {
    my ($self) = @_;
    
    return $self->configdir->file('lacuna.pid');
}

sub BUILD {
    my ($self) = @_;
    
    my $lockcounter = 0;
    my $lockfile = $self->lockfile;
    
    # Check for configdir
    unless (-e $self->configdir) {
        $self->log('notice','Creating Games-Lacuna-Task config directory at %s',$self->configdir);
        $self->configdir->mkpath();
    }
    
    # Check for lockfile
    while (-e $lockfile) {
        my ($pid) = $lockfile->slurp(chomp => 1);
        
        if ($lockcounter > 10) {
            $self->abort('Could not aquire lock (%s)',$lockfile);
        } else {
            $self->log('warn','Another process is currently running. Waiting until it has finished');
        }
        $lockcounter++;
        sleep 15;
    }
    
    # Write lock file
    my $lockfh = $lockfile->openw();
    print $lockfh $$;
    $lockfh->close;
    
    return $self;
}

sub DEMOLISH {
    my ($self) = @_;
    
    $self->lockfile->remove
        if -e $self->lockfile;
    return;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

=encoding utf8

=head1 NAME

Games::Lacuna::Task - Automation framework for the Lacuna Expanse MMPOG

=head1 SYNOPSIS

    my $task   = Games::Lacuna::Task->new(
        task    => ['recycle','repair'],
        config  => {
            recycle => ...
        },
    );
    $task->run();

or via commandline (see L<bin/lacuna_task> and L<bin/lacuna_run>) 

=head1 DESCRIPTION

This module provides a framework for implementing various automation tasks for
the Lacuna Expanse MMPOG. It provides 

=over

=item * a way of customizing which tasks to run in which order

=item * a convinient command line interface

=item * a logging mechanism

=item * configuration handling

=item * cache for increasing speed and reducing rpc calls

=item * simple access to the Lacuna API (via Games::Lacuna::Client)

=item * many useful helper methods and roles

=item * implements several common tasks

=back

=head1 CONFIGURATION

Games::Lacuna::Task uses a yaml configuration file which is loaded from the
database directory (defaults to ~/.lacuna). The filename should be config.yml
or lacuna.yml.

If you run C<lacuna_task> for the first time the programm will guide you 
through the setup process and create a basic config file.

Example config.yml

 ---
 connect:
   name: "empire_name"          
   password: "empire_password"  
   uri: "http://..."            # optional
   api_key: "a1f9...."          # optional
 global:
   task: 
     - excavate
     - bleeder
     - repair
     - dispose
   dispose_percentage: 80
 excavate: 
   excavator_count: 3

The data of the configuration file must be a hash with hash keys corresponding
to the lowecase task names. The hash key 'global' should be used for
global settings.

global.task specifies which tasks should be run by default and is only used
if no tasks have been set explicitly (e.g. via command line).

global.exclude specifies which tasks should be skipped default and is only 
used if no tasks have been set explicitly or via config.

global.exclude_planet and *.exclude_planet can be used to exclude certain
bodies from being processed.

All other values in the global section are used as default values for tasks.
(e.g. the 'dispose_percentage' setting can be used by the WasteMonument and
the WasteDispose task)

Username, password, empire name, api key and server url must be stored under
the connect key in the config file.

=head1 AUTHOR

    Maroš Kollár
    CPAN ID: MAROS
    maros [at] k-1.com
    
    L<http://www.revdev.at>

=head1 COPYRIGHT

Games-Lacuna-Task is Copyright (c) 2012 Maroš Kollár 
- L<http://www.k-1.com>

=head1 LICENCE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
