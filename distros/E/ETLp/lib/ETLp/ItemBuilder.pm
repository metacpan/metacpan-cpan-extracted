package ETLp::ItemBuilder;

use MooseX::Declare;

=head1 NAME

ETLp::ItemBuilder - Builds the pipeline of items to execute

=head1 DESCRIPTION

The pipeline is effectivey an array of anonymous methods that will be
called when the pipline execution begins

=head1 METHODS

=head2 new

=head3 parameters

    * plugins:  Required. A hashref of item types types and the name of
                the plugin that executes that type
    * pipeline_type: Required. Either "iteration" or "serial"
    * include_env: Optional. Whether the environment variables should be
                substituted into the configuration. Defaults to false (0)
    * env_config: Optional The environment variables (a hashref)
    * app_root: Required. The application root directory
    
=head3 returns

an ETLp::ItemBuilder object

=cut

class ETLp::ItemBuilder with ETLp::Role::Config {
    use ETLp::Exception;
    use Data::Dumper;
    use UNIVERSAL::require;
    use Try::Tiny;
    use Clone qw(clone);
    use File::Basename;

    has 'plugins'       => (is => 'ro', isa => 'HashRef', required => 1);
    has 'pipeline_type' => (is => 'ro', isa => 'Str',     required => 1);
    has 'allow_env_vars' =>
      (is => 'ro', isa => 'Bool', required => 0, default => 0);
    has 'env_conf' =>
      (is => 'ro', isa => 'HashRef', required => 0, default => sub { {} });
    has 'app_root' => (is => 'ro', isa => 'Maybe[Str]', required => 1);
    has 'config'   => (is => 'ro', isa => 'HashRef',    required => 1);

    # Recursively navigate the items, replacing the placeholders
    # with their values
    
    method _parse_item(HashRef $config, $item, Maybe [Str] $filename) {
        my $app_root = $self->app_root;
        my %master_config = (%{$self->env_conf}, %{$config->{config}});
        $self->logger->debug("Master config: " . Dumper(\%master_config));
        if (ref $item eq 'HASH') {
            foreach my $item_key (keys %$item) {
                if (!ref $item->{$item_key}) {
                    if ($item->{$item_key} =~ /%app_root%/) {
                        $item->{$item_key} =~ s/%app_root%/$app_root/g;
                    }
                    
                    if ($filename) {
                        if ($item->{$item_key} =~ /%filename%/) {
                            $item->{$item_key} =~ s/%filename%/$filename/g;
                        }
                        
                        if ($item->{$item_key} =~ /%basename\(filename\)%/) {
                            my $base_filename = basename($filename);
                            $item->{$item_key} =~
                                s/%basename\(filename\)%/$base_filename/g;
                        }
                    }
                    foreach my $config_key (keys %master_config) {
                        if ($item->{$item_key} =~ /%$config_key%/) {
                            my $env_value = $master_config{$config_key};
                            $item->{$item_key} =~ s/%$config_key%/$env_value/g;
                        }
                    }
                } else {
                    $self->_parse_item($config, $item->{$item_key}, $filename);
                }
            }
        } elsif (ref $item eq 'ARRAY') {
            for (my $j = 0 ; $j < @$item ; $j++) {
                $self->_parse_item($config, $item->[$j], $filename);
            }
        }
    
        return $item;
    }

    # Go through the config section and the items, replacing the placeholders
    # with their values
    method _parse_config(HashRef $config, Maybe [Str] $filename){
        my $app_root = $self->app_root;

        # Firstly, replace app_root and filename throughout the config section
        foreach my $config_key (keys %{$config->{config}}) {

            # replace the app_root placeholder
            if ($config->{config}->{$config_key} =~ /%app_root%/) {
                $config->{config}->{$config_key} =~ s/%app_root%/$app_root/g;
            }

            # replace the environment placeholders if we are allowed to
            foreach my $env_config_key (keys %{$self->env_conf}) {
                if ($config->{config}->{$config_key} =~ /%$env_config_key%/)
                {
                    my $env_value = $self->env_conf->{$env_config_key};
                    $config->{config}->{$config_key} =~
                      s/%$env_config_key%/$env_value/g;
                }
            }
        }
        
        return $config;
    }

=head2 build_pipeline

Build an array of the pipeline items

=head3 parameters

    * void
    
=head3 returns

An arrayref of Item hashrefs. Each hashref consists of the following keys:

    * name. The name of the item
    * type. The type of the item
    * plugin. The plugin that will execute the pipeline item
    * sub. An anonymous subroutine that executes the pipeline item
    * item. The original item hash (minus the name and type)
    * parsed_item. The item hash with the placeholders

=cut

    method build_pipeline {
        my $app_config = clone($self->config);
        my @items;
        foreach my $phase (qw/pre_process process post_process/) {
            if (exists($app_config->{$phase}->{item})) {
                foreach my $item (@{$app_config->{$phase}->{item}}) {
                    my $name = delete $item->{name}
                      || ETLpException->throw(error => "Item has no name: " .
                            Dumper($item));
                    my $type = delete $item->{type}
                      || ETLpException->throw(error => "Item has no type: " .
                            Dumper($item));
                    my $plugin = $self->plugins->{$type}
                      || ETLpException->throw(error =>
                        "No such plugin for type $type: " .
                            Dumper($item));

                    my $sub = sub {
                        my $filename = shift;

                        my $parsed_config =
                            $self->_parse_config(clone($app_config), $filename);
                          
                        my $parsed_item = $self->_parse_item(
                            $parsed_config, clone($item), $filename
                        );

                        #if ($self->allow_env_vars) {
                        #    # We don't want to log any sensitive information
                        #    # from the environment file
                        #    $self->logger->debug("$name item:" . Dumper($item));
                        #    $self->logger->debug(
                        #        "$name config:" . Dumper($app_config));
                        #} else {
                        #    # If there is any senstive information in the
                        #    # application config, then it will appear in the
                        #    # log if the threshold <= debug. Users should
                        #    # not put sensitive info there.
                        #    $self->logger->debug(
                        #        "$name item:" . Dumper($parsed_item));
                        #    $self->logger->debug(
                        #        "$name config:" . Dumper($parsed_config));
                        #}
                        
                        $self->logger->debug("$name item:" . Dumper($item));
                        $self->logger->debug("$name config:" . Dumper($app_config));
                        
                        $self->logger->debug(
                            "Parsed $name item:" . Dumper($parsed_item));
                        $self->logger->debug(
                            "Parsed $name config:" . Dumper($parsed_config));

                        $plugin->require;
                        my $etlp_obj = $plugin->new(
                            item          => $parsed_item,
                            config        => $parsed_config,
                            original_item => $item,
                            env_conf      => $self->env_conf,
                        );

                        if ($filename) {
                            my $file_proc =
                              $self->audit->item->create_file_process(
                                basename($filename));
                              
                            try {
                                $filename = $etlp_obj->run($filename);
                            }
                            catch {
                                my $error = $_;
                                $file_proc->update_message(''.$error);
                                $file_proc->update_status('failed');
                                $error->rethrow if (ref $error);
                                ETLpException->throw(error =>
                                    "Processing of file: $filename failed: $_");
                            };
                            
                            # A warning won't raise an exception, so don't
                            # overwrite a warning with a success
                            unless ($file_proc->details->status->status_name eq
                                    'warning') {
                                $file_proc->update_status('succeeded');
                            }
                            return $filename;
                        } else {
                            $etlp_obj->run;
                        }
                    };

                    push @items,
                      {
                        'name'   => $name,
                        'type'   => $type,
                        'plugin' => $plugin,
                        'runner' => $sub,
                        'item'   => $item,
                        'phase'  => $phase
                      };
                }
            }
        }
        return \@items;
    }
}

=head1 ROLES CONSUMED

 * ETLp::Role::Config
 
=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

