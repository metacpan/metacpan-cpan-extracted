# $Id: /mirror/gungho/lib/Gungho/Component/Setup.pm 41086 2008-02-01T16:49:41.285355Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::Setup;
use strict;
use warnings;
use base qw(Gungho::Component);
use Config::Any;

my @INTERNAL_PARAMS             = qw(bootstrap_finished setup_finished config);
my @CONFIGURABLE_PARAMS         = qw(user_agent);
my %CONFIGURABLE_PARAM_DEFAULTS = (
    map { ($_ => 0) } @CONFIGURABLE_PARAMS
);

__PACKAGE__->mk_classdata($_) for (
    qw(log provider handler engine is_running features observer),
    @INTERNAL_PARAMS,
    @CONFIGURABLE_PARAMS,
);

sub new
{
    warn "Gungho::new() has been deprecated in favor of Gungho->run()";
    my $class = shift;
    $class->bootstrap(@_);
    return $class;
}

sub run
{
    my $c = shift;
    $c->bootstrap(@_);
    $c->is_running(1);

    my $banner = sprintf(<<EOBANNER, eval('$Gungho' . '::VERSION'), join(', ', map { my $name = $_; $name =~ s/Gungho::Component:://; $name } @Gungho::ISA ) );
Starting $c 
Gungho Version: %s
Components: %s
EOBANNER
    $c->log->info($_) for split(/\n/, $banner);
    $c->engine->run($c);
}

sub bootstrap
{
    my $c = shift;

    return $c if $c->bootstrap_finished();

    my $config = $c->load_config($_[0]);
    if (exists $ENV{GUNGHO_DEBUG}) {
        $config->{debug} = $ENV{GUNGHO_DEBUG};
    }

    $c->config($config);

    for my $key (@CONFIGURABLE_PARAMS) {
        $c->$key( $config->{$key} || $CONFIGURABLE_PARAM_DEFAULTS{$key} );
    }

    if (! $config->{user_agent}) {
        warn "No user agent specified. You should specify one today!";
        $c->user_agent( "Gungho/$Gungho::VERSION (http://code.google.com/p/gungho-crawler/wiki/Index)");
    }
    $c->features({});

    my $components = $c->config->{components} || [];
    push @$components, 'Core';
    Gungho->load_components(@$components);
    $c->bootstrap_finished(1);
    $c->setup;

    return $c;
}

sub load_config
{
    my $c = shift;
    my $config = shift;

    if ($config && ! ref $config) {
        my $filename = $config;
        # In the future, we may support multiple configs, but for now
        # just load a single file via Config::Any
    
        my $list = Config::Any->load_files( {
            files => [ $filename ],
            use_ext => 1,
        } );
        ($config) = $list->[0]->{$filename};
    }

    if (! $config) {
        Carp::croak("Could not load config");
    }

    if (ref $config ne 'HASH') {
        Carp::croak("Gungho expectes config that can be decoded to a HASH");
    }

    return $config;
}


1;

__END__

=head1 NAME

Gungho::Component::Setup - Routines To Setup Gungho

=head2 SYNOPSIS

  # Internal Use only

=head1 METHODS

=head2 new

Only here to announce its deprecation. Don't use. Use run()

=head2 bootstrap

Bootstraps Gungho.

=head2 run

Sets up, configures, and starts Gungho

=head2 load_config

Loads the given config

=cut
