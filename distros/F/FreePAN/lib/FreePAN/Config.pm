package FreePAN::Config;
use Spoon::Config -Base;
use mixin 'FreePAN::Installer';

const class_id => 'config';
const class_title => 'Configuration Module';
const config_file => "config.yaml";
field path => [];
field plugins_file => '';
field base => -init => '$self->base_init';
field default_path => -init => '[ $self->base . "/config" ]';

sub base_init {
    $ENV{FREEPAN_BASE} || $ENV{HOME}
        ? "$ENV{HOME}/.freepan" : die "Can't determine FreePAN base directory";
}

sub init {
    $self->add_path(@{$self->default_path});
    $self->add_file($self->config_file);
}

sub paired_arguments { qw(-plugins) }
sub new {
    my ($args, @configs) = $self->parse_arguments(@_);
    $self = super(@configs);
    if (my $plugins_file = $args->{-plugins}) {
        $self->add_plugins_file($plugins_file);
        $self->plugins_file($plugins_file);
    }
    return $self;
}

sub add_plugins_file {
    my $plugins_file = shift;
    return unless -f $plugins_file;
    $self->add_config(
        {
            plugin_classes => [ $self->read_plugins($plugins_file) ],
        }
    );
}

sub read_plugins {
    my $plugins_file = io(shift);
    my @plugins = grep {
        s/^([\+\-]?[\w\:]+)\s*$/$1/;
    } $plugins_file->slurp;
    return @plugins unless grep /^[\+\-]/, @plugins or not @plugins;
    my $filename = $plugins_file->filename;
    die "Can't create plugins list"
      unless -e "../$filename";
    my $updir = io->updir->chdir;
    my @parent_plugins = $self->read_plugins($filename);
    for (@plugins) {
        my $remove = $_;
        $remove =~ s/^\-// or next;
        @parent_plugins = grep {$_ ne $remove} @parent_plugins;
    }
    my %have;
    @have{@parent_plugins} = ('1') x @parent_plugins;
    return @parent_plugins, grep {
        not /^\-/ and do {
            s/^\+//;
            not $have{$_};
        }
    } @plugins;
}

sub default_classes {
    (
        command_class => 'FreePAN::Command',
        config_class => 'FreePAN::Config',
        hub_class => 'Spoon::Hub',
        registry_class => 'FreePAN::Registry',
        template_class => 'FreePAN::Template',
    )
}

sub add_file {
    my $file = shift
      or return;
    my $file_path = '';
    for (@{$self->path}) {
        $file_path = "$_/$file", last
          if -f "$_/$file";
    }
    return unless $file_path;
    my $hash = $self->hash_from_file($file_path);
    for my $key (keys %$hash) {
        next if defined $self->{$key};
        field $key;
        $self->{$key} = $hash->{$key};
    }
}

sub add_path {
    splice @{$self->path}, 0, 0, @_;
}

__DATA__

=head1 NAME 

FreePAN::Config - FreePAN Configuration Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__!config.yaml__
# FreePAN Configuration Overrides
__config/config.yaml__
repos_base: /var/freepan/repos
svn_domain_name: http://tpe.freepan.org/repos/
site_maintainer: ingy@cpan.org
__!plugins__
FreePAN::SVKMirror
