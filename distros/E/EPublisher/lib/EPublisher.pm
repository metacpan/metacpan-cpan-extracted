package EPublisher;

# ABSTRACT: Publish documents in new format

use strict;
use warnings;
use Carp;

use EPublisher::Config;
use EPublisher::Source;
use EPublisher::Target;

our $VERSION = 1.27;

sub new{
    my ($class,%args) = @_;
    my $self = bless {}, $class;
    
    $self->config( $args{config} ) if exists $args{config};
    $self->_debug( $args{debug} );
    
    return $self;
}

sub config{
    my ($self,$data) = @_;
    
    my $ref = ref $data;
    if( defined $data and !$ref ){
        $self->{_configfile} = $data;
        $self->_config(1);
    }
    elsif ( $ref and $ref eq 'HASH' ) {
        $self->_config( 1, $data );
    }
    
    return $self->{_configfile};
}

sub projects {
    my ($self) = @_;
    
    my $config = $self->_config;
    
    return if !ref $config;
    return if ref $config ne 'HASH';
    
    return keys %{$config};
}

sub run{
    my ($self,$projects) = @_;

    PROJECT:    
    for my $project ( @$projects ) {
        my $config   = $self->_config->{$project};
        
        next PROJECT if !$config;
        
        # load the source
        next PROJECT if !exists $config->{source};

        my $sources = $config->{source};
        next PROJECT if !ref $sources;

        $sources = [ $sources ] if ref $sources ne 'ARRAY';

        next PROJECT if !exists $config->{target};
        next PROJECT if !$config->{target}->{type};
        
        my @pods;

        SOURCE:
        for my $source ( @{$sources} ) {
            die 'No type in source.' if !length $source->{type};

            $self->debug('100: ' . $source->{type} );

            my $source_obj = EPublisher::Source->new( $source );
            $source_obj->publisher( $self );
            
            my @pod_source = $source_obj->load_source;

            next SOURCE if !@pod_source;

            @pod_source = grep { $_->{pod} }@pod_source;
            
            $self->debug('101: ' . substr join( "", map{ $_->{pod} }@pod_source ), 0, 50 );
            
            push @pods, @pod_source;
        }

        next PROJECT if !@pods;
        
        $config->{target}->{source} = \@pods;
        
        # deploy the project
        $self->debug('200: ' . $config->{target}->{type} );
        my $target = EPublisher::Target->new( $config->{target} );
        $target->publisher( $self );
        $target->deploy;
    }

    return 1;
}

sub _debug{
   my ($self,$ref) = @_;
   
   if( @_ == 2 and ref($ref) eq 'CODE' ){
      $self->{__debug} = $ref;
      $self->{DEBUG}   = 1;
   }

   return $self->{__debug};
}

sub debug {
    my ($self,$message) = @_;
    
    return if !$self->{DEBUG};
    $self->{__debug}->($message);
}

sub _config{
    my ($self,$bool,$data) = @_;
    
    if ( $bool and $data ) {
        $self->{__config} = $data;
    }
    elsif( !$self->{__config} or $bool ){
        unless( $self->config ){
            croak "no config file given!";
        }
        $self->{__config} = EPublisher::Config->get_config( $self->config );
    }

    return $self->{__config};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

EPublisher - Publish documents in new format

=head1 VERSION

version 1.27

=head1 SYNOPSIS

  use EPublisher;
  
  my $yaml     = './test.yml';
  my @projects = qw(Test);
  
  my $deploy   = EPublisher->new;
  $deploy->config( $yaml );
  $deploy->run( \@projects );

The correspondend YAML file:

  ---
  Test:
    source:
      type: Module
      path: YAML::Tiny
    target:
      type: Text
      path: C:\anything\YAML_Tiny.txt

=head1 DESCRIPTION

This tool aims to simplify publishing of documents, mainly POD. To be extendable, it
uses a simple plugin system. It uses YAML files for configuration (see L<YAML::Tiny>)
and many CPAN modules for this task.

You can write your own plugins for your favourite source format
(see L<EPublisher::Source::Base>) and/or a plugin for your favourite output format.

=head2 Sources

"Sources" are input sources of the POD. In this base package there are three source
plugins:

=over 4

=item * Dir

Get all *.pm and *.pod files in the given directory and its subdirectories. See
L<EPublisher::Source::Plugin::Dir>.

=item * File

The Pod will be extracted from the given file.

=item * Module

This tool will try to get the POD off the module (without loading the module).

=back

L<EPublisher::Source::Base> describes how you can write your own Source-Plugin.

=head2 Targets

"Targets" are output formats. Currently there are two formats supported, but
other target plugins will follow.

=over 4

=item * Text

converts POD to plain text.

=back

L<EPublisher::Target::Base> describes how you can write your own Target-Plugin.

=head1 METHODS

All methods available for EPublisher are described in the subsequent sections

=head2 new

=head2 config

=head2 run

=head2 projects

=head2 deploy

=head2 debug

=head1 PSEUDO PROTOCOL

There is a small "pseudo" protocol for the debug messages:

  100 start running source
  101 stop running source (success)
  102 error
  
  200 start running target plugin
  201 stop running target plugin (success)
  202 error
  203 info from target plugin

=head1 PREREQUESITS

L<YAML::Tiny>, L<Carp>, L<File::Spec>, L<File::Glob>,

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
