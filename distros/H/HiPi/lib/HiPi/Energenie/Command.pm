#########################################################################################
# Package        HiPi::Energenie::Command
# Description  : Energenie Command Wrapper
# Copyright    : Copyright (c) 2017-2020 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.
#########################################################################################

package HiPi::Energenie::Command;

#########################################################################################

use strict;
use warnings;
use feature 'say';
use parent qw( HiPi::Class );
use HiPi qw( :openthings :energenie :rpi );
use HiPi::Energenie;
use HiPi::Utils::Config;
use Getopt::Long qw( GetOptionsFromArray );
use JSON;
use Try::Tiny;
use HiPi::RF::OpenThings::Message;

our $VERSION ='0.82';

__PACKAGE__->create_accessors( qw( config result mode display options pretty user
                                   console_display_message ) );

use constant {
    ERROR_SUCCESS     => 'ERROR_SUCCESS',
    ERROR_UNKNOWN     => 'ERROR_UNKNOWN',
    ERROR_MISSING_COMMAND => 'ERROR_MISSING_COMMAND',
    ERROR_BAD_COMMAND => 'ERROR_BAD_COMMAND',
    ERROR_BAD_OPTIONS => 'ERROR_BAD_OPTIONS',
    
    ERROR_SYSTEM => 'ERROR_SYSTEM',
    
    ERROR_CONFIG_INVALID_BOARD  => 'ERROR_CONFIG_INVALID_BOARD',
    ERROR_CONFIG_INVALID_DEVICE => 'ERROR_CONFIG_INVALID_DEVICE',
    ERROR_CONFIG_INVALID_GPIO  => 'ERROR_CONFIG_INVALID_GPIO',
    
    ERROR_GROUP_INVALID_OPTIONS => 'ERROR_GROUP_INVALID_OPTIONS',
    ERROR_GROUP_EXISTING_GROUP => 'ERROR_GROUP_EXISTING_GROUP',
    ERROR_GROUP_EXISTING_NAME => 'ERROR_GROUP_EXISTING_NAME',
    ERROR_GROUP_NAME_NOT_FOUND => 'ERROR_GROUP_NAME_NOT_FOUND',
    ERROR_GROUP_ID_NOT_FOUND => 'ERROR_GROUP_ID_NOT_FOUND',
    
    ERROR_PAIR_INVALID_OPTIONS => 'ERROR_PAIR_INVALID_OPTIONS',
    ERROR_PAIR_GROUP_NOT_FOUND => 'ERROR_PAIR_GROUP_NOT_FOUND',
    ERROR_PAIR_INVALID_SWITCH => 'ERROR_PAIR_INVALID_SWITCH',
    ERROR_PAIR_NAME_NOT_FOUND => 'ERROR_PAIR_NAME_NOT_FOUND',
    ERROR_PAIR_EXISTING_SWITCH => 'ERROR_PAIR_EXISTING_SWITCH',
    
    ERROR_SWITCH_INVALID_OPTIONS => 'ERROR_SWITCH_INVALID_OPTIONS',
    ERROR_SWITCH_GROUP_NOT_FOUND => 'ERROR_SWITCH_GROUP_NOT_FOUND',
    ERROR_SWITCH_INVALID_SWITCH => 'ERROR_SWITCH_INVALID_SWITCH',
    ERROR_SWITCH_NAME_NOT_FOUND => 'ERROR_SWITCH_NAME_NOT_FOUND',
    
    ERROR_ALIAS_INVALID_OPTIONS => 'ERROR_ALIAS_INVALID_OPTIONS',
    ERROR_ALIAS_GROUP_NOT_FOUND => 'ERROR_ALIAS_GROUP_NOT_FOUND',
    ERROR_ALIAS_INVALID_SWITCH => 'ERROR_ALIAS_INVALID_SWITCH',
    
    ERROR_USUPPORTED_RX_COMMAND  => 'ERROR_USUPPORTED_RX_COMMAND',
    
    ERROR_JOIN_INVALID_OPTIONS  => 'ERROR_JOIN_INVALID_OPTIONS',
    ERROR_JOIN_EXISTING_ADAPTER => 'ERROR_JOIN_EXISTING_ADAPTER',
    ERROR_JOIN_EXISTING_MONITOR => 'ERROR_JOIN_EXISTING_MONITOR',
    ERROR_JOIN_DEVICE_NOT_FOUND => 'ERROR_JOIN_DEVICE_NOT_FOUND',
    ERROR_JOIN_FAILED           => 'ERROR_JOIN_FAILED',
    
    ERROR_ADAPTER_INVALID_OPTIONS => 'ERROR_ADAPTER_INVALID_OPTIONS',
    ERROR_ADAPTER_NAME_NOT_FOUND  => 'ERROR_ADAPTER_NAME_NOT_FOUND',
    ERROR_ADAPTER_FAILED          => 'ERROR_ADAPTER_FAILED',
    
    ERROR_MONITOR_INVALID_OPTIONS => 'ERROR_MONITOR_INVALID_OPTIONS',
    ERROR_MONITOR_NAME_NOT_FOUND  => 'ERROR_MONITOR_NAME_NOT_FOUND',
    ERROR_MONITOR_FAILED          => 'ERROR_MONITOR_FAILED',
    
};

my $commandopts = {
    help     => {
        template => undef,
        defaults => {},
    },
    version  => {
        template => undef,
        defaults => {},
    },
    config  => {
        template => [ 'help|h!', 'list|l!', 'device|d:s', 'board|b:s', 'reset|r:s' ],
        defaults => { help => 0, list => 0, device => undef, board => undef, reset => undef },
    },
    group   => {
        template => [ 'help|h!', 'create|c:s', 'delete|d:s', 'rename|r:s', 'group|g:o', 'newname|n:s', 'list|l!',],
        defaults => { },
    },
    pair    => {
        template => [ 'help|h!', 'list|l', 'groupname|g:s', 'switch|s:i', 'name|n:s', ],
        defaults => { groupname => undef, switch => 0, },
    },
    switch  => {
        template => [ 'help|h!', 'list|l!', 'groupname|g:s', 'switch|s:i', 'name|n:s', 'on|1!', 'off|0!', 'all!' ],
        defaults => { help => 0, list => 0, groupname => undef, switch => undef, on => 0, off => 0, all => 0, } ,
    },
    alias  => {
        template => [ 'help|h!', 'list|l!', 'groupname|g:s', 'switch|s:i', 'name|n:s', ],
        defaults => { help => 0, list => 0, } ,
    },
    join    => {
        template => [ 'help|h!', 'list|l!', 'name|n:s', 'delete|d:s', 'rename|r:s', 'timeout|t:i' ],
        defaults => { help => 0, list => 0, name => '', delete  => '', rename => '', timeout => 60 },
    },
    adapter => {
        template => [ 'help|h!', 'list|l!', 'name|n:s', 'query|q!', 'on|1!', 'off|0!', 'timeout|t:i' ],
        defaults => { name => undef, query => 0, on => 0, off => 0, list => 0, help => 0, timeout => 60 },
    },
    monitor => {
        template => [ 'help|h!', 'list|l!', 'name|n:s', 'timeout|t:i' ],
        defaults => { name => undef, list => 0, help => 0,  timeout => 60 } ,
    },
};


sub new {
    my($class, %userparams ) = @_;
    
    my %params = (
        display => 'usage',
        mode    => 'console',
        pretty  => 0,
        user    => getpwuid($>),
        console_display_message => '',
        result  => {
            success   => 0,
            command   => 'unknown',
            option    => '',
            error     => 'unknown error',
            errorcode => ERROR_UNKNOWN,
            data      => {},
        },
    );
    
    foreach my $key (sort keys(%userparams)) {
        $params{$key} = $userparams{$key};
    }
    
    $params{config} = HiPi::Utils::Config->new(
        configclass => 'scripts/energenie',
        default     => {
            version    => $VERSION,
            board      => 'ENER314_RT',
            spi_device => '/dev/spidev0.1',
            reset_gpio => RPI_PIN_22,
            led_red_gpio => 0,
            led_green_gpio => 0,
            groups     => {},
            adapters   => {},
            monitors   => {},
            switches   => {},
        },
    );
    
    my $self = $class->SUPER::new( %params );
    return $self;
}

sub conf { $_[0]->config->config(); }

sub valid_command {
    my( $self, $command) = @_;
    return 0 if( length($command) > 40 || $command !~ /^[a-z]+$/ );
    return ( exists($commandopts->{$command}) ) ? 1 : 0;
}
    
sub handle_command {
    my $self = shift;
    my @commandargs = @ARGV;
    
    $self->handle_command_arguments( @commandargs );
}

sub handle_command_arguments {
    my ($self, @inputargs) = @_;
    
    my @commandargs = ();
    
    my $result = try {
    
        for my $arg ( @inputargs ) {
            if( lc($arg) eq '--json' ) {
                $self->mode('json');
            } elsif( lc($arg) eq '--pretty' ) {
                $self->mode('json');
                $self->pretty(1);
            } else {
                push @commandargs, $arg;
            }
        }
        
        $commandargs[0] = 'missing' unless @commandargs;
        
        my $command = shift @commandargs;
    
        if ( $self->valid_command($command) ) {
            $self->result->{command} = $command;
            my $opt = $commandopts->{$command}->{defaults};
            my $opttemplate = $commandopts->{$command}->{template};
            if( $opttemplate ) {
                GetOptionsFromArray(\@commandargs, $opt, @$opttemplate )
            }
            $self->options( $opt );
            my $commandsub = qq(command_$command);
            $self->$commandsub();
        } else {
            $self->result->{command} = $command;
            my $errorcode = ( $command eq 'missing' ) ? ERROR_MISSING_COMMAND : ERROR_BAD_COMMAND;
            $self->set_result_error( $errorcode, qq(bad or missing command provided : $command ))
        }
    
        $self->return_result();
    } catch {
        my $error = $_;
        $error =~ s/["\n]/ /g;
        return qq({"success":0,"errorcode":"ERROR_SYSTEM","error":"$error"});
    };
    
    return $result;
}

sub return_result {
    my $self = shift;
    
    if($self->mode eq 'json') {
        if( exists( $self->result->{data}) && ref($self->result->{data})->isa('HiPi::RF::OpenThings::Message') ) {
            $self->result->{data} = $self->result->{data}->value_hash;
        }
        my $j = JSON->new;
        my $output = ( $self->pretty ) ? $j->pretty->canonical->encode( $self->result ) : $j->encode( $self->result );
        return $output;
    }
    
    if( $self->display eq 'usage' ) {
        
        my $output = '';
        if( $self->result->{errorcode} ne 'ERROR_SUCCESS' ) {
            $output .= sprintf(qq(\nERROR : %s : %s\n), $self->result->{errorcode}, $self->result->{error});
        }
        $output .= $self->get_command_usage($self->result->{command});
        
        return $output;
    }
    
    # display the command result
    if( $self->result->{errorcode} ne 'ERROR_SUCCESS' || !$self->result->{success} ) {
        return sprintf(qq(Command : %s : ERROR : %s : %s), $self->result->{command}, $self->result->{errorcode}, $self->result->{error});
    
    # CONFIG
    
    } elsif( $self->result->{command} eq 'config') {
        
        my $output = qq(\nCONFIGURATION\n);
        $output .= qq(-----------------------------------------\n);
        
        if( my $data = $self->result->{data} ) {
            
            my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime( $data->{epoch} );
            my $timestamp = sprintf('%u-%02u-%02u %02u:%02u:%02u',
                $year + 1900, $mon + 1, $mday, $hour, $min, $sec      
            );
                
            $output .= qq(  Config Version   :  $data->{version}\n) if $data->{version};
            $output .= qq(  Energenie Board  :  $data->{board}\n) if $data->{board};
            $output .= qq(  Receiver         :  $data->{can_rx}\n) if $data->{can_rx};
            $output .= qq(  Uses SPI         :  $data->{uses_spi}\n) if $data->{uses_spi};
            $output .= qq(  SPI Device       :  $data->{spi_device}\n) if $data->{spi_device} && $data->{can_rx} eq 'YES';
            $output .= qq(  Reset GPIO       :  $data->{reset_gpio}\n) if $data->{spi_device} && $data->{can_rx} eq 'YES';
            $output .= qq(  Config Saved     :  $timestamp\n);
        }
        return $output;
        
    # VERSION
    
    } elsif( $self->result->{command} eq 'version') {
        return $self->result->{data}->{versiontext};
    
    # GROUP
    
    } elsif( $self->result->{command} eq 'group') {
        my $output = qq(\nGROUPS\n);
        $output .= qq(-----------------------------------------\n);
        # $output .= qq(NAME                           ID\n);
        for my $gname ( sort keys %{ $self->result->{data}->{groups} } ) {
            my $gid = $self->result->{data}->{groups}->{$gname};
            $output .= sprintf(qq(  %-30s %s\n), $gname, $gid);
        }
        return $output;
        
    # SWITCH LIST
    
    } elsif( $self->result->{command} =~ /^pair|alias$/
            || ( $self->result->{command} eq 'switch' && $self->result->{option} eq 'list') ) {
       
        my $output = qq(\nSWITCHES & SOCKETS\n);
        $output .= qq(------------------------------------------\n);
        $output .= qq(  NAME               GROUP          SWITCH\n);
        for my $switch( sort keys %{ $self->result->{data}->{switches} } ) {
            my $group = $self->result->{data}->{switches}->{$switch}->{group};
            my $sno = $self->result->{data}->{switches}->{$switch}->{switch};
            $output .= sprintf(qq(  %-18s %-18s  %s\n), $switch, $group, $sno);
        }
        return $output;    
    
    # SWITCH BROADCAST
    
    
    } elsif( $self->result->{command} eq 'switch' && $self->result->{option} ne 'list' ) {
    
       
        my $output = sprintf(qq(\nSWITCH BROADCAST STATUS - %s\n), $self->result->{data}->{status});
        $output .= qq(-------------------------------\n);
        
        my @snums = ( $self->result->{data}->{switch} ) ? ( $self->result->{data}->{switch} ) : (1,2,3,4);
        my $group = $self->result->{data}->{groupname};
        $output .= qq(  GROUP                  SWITCH\n);
        for my $switch( @snums ) {
            $output .= sprintf(qq(  %-25s %s\n), $group, $switch);
        }
        
        return $output;    
    
    } elsif( $self->result->{command} eq 'join' || ( $self->result->{command} =~ /^adapter|monitor$/  && $self->result->{option} eq 'list' ) ) {
    
        my $output = qq(\nMONITORS AND ADAPTERS\n);
        $output .= qq(---------------------------------------------------------------------\n);
        $output .= (qq(  NAME                 PRODUCT                      SENSORID   SWITCH\n));
        
        my $listname = ( $self->result->{command} eq 'adapter' ) ? 'adapters' : 'monitors';
        
        for my $monitor ( sort keys %{ $self->result->{data}->{$listname} } ) {
            my $data = $self->result->{data}->{$listname}->{$monitor};
            my $switch = HiPi::RF::OpenThings->product_can_switch( $data->{manufacturer_id}, $data->{product_id} ) ? 'YES' : ' NO';
            # my $switch = ( exists( $self->result->{data}->{adapters}->{$monitor}) ) ? 'YES' : ' NO';
            $output .= sprintf(qq(  %-20s %-28s 0x%06X      %s\n),
                $monitor, $data->{product_name}, $data->{sensor_id}, $switch
            );
        }
        
    
        return $output;
        
    } elsif( $self->result->{command} =~ /^adapter|monitor$/  && $self->result->{option} ne 'list' ) {
                
        my $data = $self->result->{data}->value_hash;
       
        my $output = sprintf(qq(\n%s STATUS REPORT FOR "%s"\n), uc($self->result->{command}), $data->{'configured_name'});
        $output .= qq(---------------------------------------------\n);
        $output .= qq(  Sensor Type           $data->{product_name}\n);
        $output .= qq(  Sensor Key            $data->{sensor_key}\n);
        $output .= qq(  Timestamp             $data->{timestamp}\n);
        $output .= qq(  -------------------------------------------\n);
        for my $record ( @{ $data->{records} } ) {
            my $value = $record->{value};
            if( $record->{id} == OPENTHINGS_PARAM_SWITCH_STATE ) {
                $value = ( $value ) ? 'ON' : 'OFF';
            }
            my $unitpart = ($record->{units}) ? qq( $record->{units}) : '';
            $output .= sprintf(qq(  %-20s  %s%s\n), $record->{name}, $value, $unitpart);
            
        }
        
        return $output;
    # other ?
    } else {
        if( exists( $self->result->{data}) && ref($self->result->{data})->isa('HiPi::RF::OpenThings::Message') ) {
            $self->result->{data} = $self->result->{data}->value_hash;
        }
        my $j = JSON->new;
        my $output = $j->pretty->canonical->encode( $self->result );
        return $output;
    }
}

sub set_result_success {
    my( $self, $data, $option ) = @_;
    if( $data ) {
        $self->display('data');
        $self->result->{data} = $data;
    } 
    $self->result->{success} = 1;
    $self->result->{error}   = '';
    $self->result->{errorcode} = ERROR_SUCCESS;
    $self->result->{option} = $option if $option;
    return;
}

sub set_result_error {
    my ($self, $errorcode, $error, $option) = @_;
    $error //= $errorcode;
    $self->display('error'); 
    $self->result->{success} = 0;
    $self->result->{error}   = $error;
    $self->result->{errorcode} = $errorcode;
    $self->result->{option} = $option if $option;
    return;
}

sub set_result_options_error {
    my ($self, $errorcode, $error, $option) = @_;
    $error //= $errorcode;
    $self->display('options'); 
    $self->result->{success} = 0;
    $self->result->{error}   = $error;
    $self->result->{errorcode} = $errorcode;
    $self->result->{option} = $option if $option;
    return;
}

sub command_help {
    my $self = shift;
    $self->set_result_success();
    return;
}

sub command_version {
    my $self = shift;
    $self->set_result_success(
        {
            version     => $VERSION,
            versiontext => qq(HiPi Energenie Version $VERSION),
        }
    );
    return;
}

sub command_config {
    my( $self ) = @_;
    
    if( $self->options->{help} ) {
        $self->set_result_success(undef, 'help');
        return;
    } elsif( $self->options->{list} ) {
        $self->list_configuration('list');
        return;
    } else {
        my( $newdevice, $newboard, $newreset );
    
        if ( $self->options->{device} ) {
            if( my ($devicename) = ( $self->options->{device} =~ /^(\/dev\/spidev\d\.\d)$/i ) ) {
                $newdevice = $devicename;
            } else {
                $self->set_result_error(
                    ERROR_CONFIG_INVALID_DEVICE,
                    sprintf(q(Invalid device %s specified), $self->options->{device}),
                    'update',
                );
                return;
            }
        }
    
        if( $self->options->{board} ) {
            if( my ($board) = ( $self->options->{board} =~ /^(ENER314|ENER314_RT|RF69HW)$/i ) ) {
                $newboard = uc($board);
            } else {
                $self->set_result_error(
                    ERROR_CONFIG_INVALID_BOARD,
                    sprintf(q(Invalid board %s specified), $self->options->{board}),
                    'update',
                );
                return;
            }
        }
        
        if( defined($self->options->{reset}) ) {
            # reset should be a number greater than 0
            if( $self->options->{reset} && $self->options->{reset} =~ /^\d+$/ ) {
                $newreset = $self->options->{reset};
            } else {
                $self->set_result_error(
                    ERROR_CONFIG_INVALID_GPIO,
                    sprintf(q(Invalid Reset GPIO %s specified), $self->options->{reset}),
                    'update',
                );
                return;
            }
        }
                
        my $coption = 'update';
        
        if( $newdevice ) {
            $self->conf->{spi_device} = $newdevice;
            $coption = 'refresh';
        }
        
        if( $newboard ) {
            $self->conf->{board} = $newboard;
            $coption = 'refresh';
        }
        
        if( $newreset ) {
            $self->conf->{reset_gpio} = $newreset;
            $coption = 'refresh';
        }
        
        # so put config info in data
        $self->list_configuration($coption);
    }
    return;
}

sub command_group {
    my $self = shift;
    
    my $create = $self->options->{create};
    my $delete = $self->options->{delete};
    my $rename = $self->options->{rename};
        
    
    if( $self->options->{help} ) {
        $self->set_result_success(undef, 'help');
        return;
    } elsif( $self->options->{list} ) {
        $self->list_groups('list');
        return;
    } elsif ( $create ) {
        
        if( $delete || $rename ) {
            $self->set_result_options_error(
                ERROR_GROUP_INVALID_OPTIONS,
                'You must specify only one of --create, --delete, --rename, --list, or --help',
                'missing',
            );
            return;
        }
        
        for my $existing( keys %{ $self->conf->{groups} } ) {
            if(lc($self->conf->{groups}->{$existing}) eq lc($create) ) {
                $self->set_result_error(
                    ERROR_GROUP_EXISTING_NAME,
                    sprintf('The name %s is already in use for group 0x%05x', $create, $existing),
                    'create'
                );
                return;
            }
        }
        
        my $group = $self->options->{group};
               
        if( $group ) {
            if(exists($self->conf->{groups}->{$group})) {
                $self->set_result_error(
                    ERROR_GROUP_EXISTING_GROUP,
                    sprintf('The group id 0x%05x already exists', $group),
                    'create'
                );
                return;
            }
        }
        
        my $newgroup = $group;
        
        while(! $newgroup ) {
            $group = $self->generate_switch_group();
            unless(exists($self->conf->{groups}->{$group})) {
                $newgroup = $group;
            }
        }
        
        $self->conf->{groups}->{$newgroup} = $create;
        $self->list_groups('create');
        return;
    } elsif ( $delete ) {

        if( $create || $rename ) {
            $self->set_result_options_error(
                ERROR_GROUP_INVALID_OPTIONS,
                'You must specify only one of --create, --delete, --rename, --list, or --help',
                'missing',
            );
            return;
        }
                   
        for my $group( keys %{ $self->conf->{groups} } ) {
            if(lc($self->conf->{groups}->{$group}) eq lc($delete) ) {
                # delete any grouped switches first
                for my $switchname ( keys %{ $self->conf->{switches} } ) {
                    if( $self->conf->{switches}->{$switchname}->{group} == $group ) {
                        delete($self->conf->{switches}->{$switchname});
                    }
                }
                delete($self->conf->{groups}->{$group});
                $self->list_groups('delete');
                return;
            }
        }
        
        $self->set_result_error(
            ERROR_GROUP_NAME_NOT_FOUND,
            qq(A group with name $delete was not found),
            'delete'
        );
        return;
        
    } elsif( $rename ) {
        
        if( $delete || $create ) {
            $self->set_result_options_error(
                ERROR_GROUP_INVALID_OPTIONS,
                'You must specify only one of --create, --delete, --rename, --list, or --help',
                'missing',
            );
            return;
        }            
        
        my $newname = $self->options->{newname};
        unless( $newname ) {
            $self->set_result_options_error(
                ERROR_GROUP_INVALID_OPTIONS,
                'You must provide both options --rename and --newname to rename an existing group',
                'rename'
            );
            return;
        }
        
        for my $existing( keys %{ $self->conf->{groups} } ) {
            if(lc($self->conf->{groups}->{$existing}) eq lc($newname) ) {
                $self->set_result_error(
                    ERROR_GROUP_EXISTING_NAME,
                    sprintf('The name %s is already in use for group 0x%05x', $newname, $existing),
                    'rename'
                );
                return;
            }
        }
                
        for my $existing( keys %{ $self->conf->{groups} } ) {
            if(lc($self->conf->{groups}->{$existing}) eq lc($rename) ) {
                $self->conf->{groups}->{$existing} = $newname;
                $self->list_groups('rename');
                return;
            }
        }
        
        $self->set_result_error(
            ERROR_GROUP_NAME_NOT_FOUND,
            qq(A group with name $rename was not found),
            'delete'
        );
        
        return;
    }
    
    $self->set_result_options_error(
        ERROR_GROUP_INVALID_OPTIONS,
        'You must specify one of --create --delete --rename --list --help',
        'missing',
    );
        return;
}

sub command_pair {
    my $self = shift;
    
    if( $self->options->{help} ) {
        $self->set_result_success(undef, 'help');
        return;
    }
    
    if( $self->options->{list} ) {
        $self->list_switches('list');
        return;
    }
    
    my $group     = 0;
    my $groupname = $self->options->{groupname};
    my $name      = $self->options->{name};
    
    if( $self->receiver ) {
        # we care about group name
        unless($groupname) {
            $self->set_result_options_error(
                ERROR_PAIR_INVALID_OPTIONS,
                'You must provide a --groupname to pair a socket or switch when using tx/rx board ENER314_RT or RF69HW',
                'pair'
            );
            return;
        }
        
        # get the group
        for my $checkgroup( keys %{ $self->conf->{groups} } ) {
            if(lc($self->conf->{groups}->{$checkgroup}) eq lc($groupname) ) {
                $group = $checkgroup;
                last;
            }
        }
        
        unless( $group ) {
             $self->set_result_error(
                ERROR_PAIR_GROUP_NOT_FOUND,
                qq(Could not find a configured group named $groupname),
                'pair'
            );
            return;
        }
    } else {
        $group = ENERGENIE_ENER314_DUMMY_GROUP;
        $groupname = 'energenie_single_group';
    }

    my $switch = $self->options->{switch};
    
    unless( $switch && $switch =~ /^1|2|3|4$/) {
         $self->set_result_error(
            ERROR_PAIR_INVALID_SWITCH,
            q(You must provide a valid switch number --switch 1|2|3|4),
            'pair'
        );
        return;
    }
        
    # pair the switch
    
    my $error =  try {
        my $handler = HiPi::Energenie->new(
            backend    => $self->conf->{board},
            devicename => $self->conf->{spi_device},
            reset_gpio => $self->conf->{reset_gpio},
        );
        
        $handler->pair_socket( $group, $switch, 5 );
        return '';
    } catch {
        my $err = $_;
        $err =~ s/\n/ /g;
        return $err;
    };
    
    if( $error ) {
        $self->set_result_error( ERROR_SYSTEM, $error, 'pair' );
        return;
    }
    
    $name ||= qq(${groupname}_switch_${switch});
    
    $self->conf->{switches}->{$name} = { group => $group, switch => $switch };
    
    $self->list_switches('pair');
}

sub command_switch {
    my $self = shift;
    
    if( $self->options->{help} ) {
        $self->set_result_success(undef, 'help');
        return;
    }
    
    if( $self->options->{list} ) {
        $self->list_switches('list');
        return;
    }
    
    my $group = 0;
    my $groupname = $self->options->{groupname};
    my $switch = ( $self->options->{all}  ) ? 0 : $self->options->{switch};
    
    my $name = $self->options->{name};
    
    if($name) {
        if(exists($self->conf->{switches}->{$name})) {
            $group  = $self->conf->{switches}->{$name}->{group};
            $switch = $self->conf->{switches}->{$name}->{switch};
            $groupname = $self->conf->{groups}->{$group};
        } else {
            $self->set_result_error(
                ERROR_SWITCH_NAME_NOT_FOUND,
                qq(Could not find a configured switch named $name),
                'switch'
            );
            return;
        }
    }
    
    
    if( $self->receiver && !$group ) {
        # we care about group name
        unless($groupname) {
            $self->set_result_options_error(
                ERROR_SWITCH_INVALID_OPTIONS,
                'You must provide a --groupname to turn on/off a socket or switch',
                'switch'
            );
            return;
        }
        
        # get the group
        for my $checkgroup( keys %{ $self->conf->{groups} } ) {
            if(lc($self->conf->{groups}->{$checkgroup}) eq lc($groupname) ) {
                $group = $checkgroup;
                last;
            }
        }
        
        unless( $group ) {
            $self->set_result_error(
                ERROR_SWITCH_GROUP_NOT_FOUND,
                qq(Could not find a configured group named $groupname),
                'switch'
            );
            return;
        }
    } elsif( !$self->receiver ) {
        $group = ENERGENIE_ENER314_DUMMY_GROUP;
        $groupname = 'energenie_single_group';
    }
    
    unless( defined($switch) && $switch =~ /^0|1|2|3|4$/) {
        $self->set_result_error(
            ERROR_SWITCH_INVALID_SWITCH,
            q(You must provide a valid switch number --switch 0|1|2|3|4 ( 0 switches all switches in the group )),
            'switch'
        );
        return;
    }
     
    if(!$self->options->{on} && !$self->options->{off}) {
        $self->set_result_options_error(
            ERROR_SWITCH_INVALID_OPTIONS,
            'You must specify either --on or --off',
            'switch'
        );
        return;
    }
    
    if($self->options->{on} && $self->options->{off}) {
        $self->set_result_options_error(
            ERROR_SWITCH_INVALID_OPTIONS,
            'You must specify either --on or --off - not both',
            'switch'
        );
        return;
    }
    
    my $state = ( $self->options->{on} ) ? 1 : 0;
    
    # Set the switch on / off
    
    my $error =  try {
        my $handler = HiPi::Energenie->new(
            backend    => $self->conf->{board},
            devicename => $self->conf->{spi_device},
            reset_gpio => $self->conf->{reset_gpio},
        );
        
        $handler->switch_socket( $group, $switch, $state );
        return '';
    } catch {
        my $err = $_;
        $err =~ s/\n/ /g;
        return $err;
    };
    
    if( $error ) {
        $self->set_result_error( ERROR_SYSTEM, $error, 'switch' );
        return;
    } 
    
    my $groupid = ( $self->receiver ) ? $self->format_group($group) : '';
    
    my $statename = ( $state ) ? 'ON' : 'OFF';
    
    my $resultdata = { switch => $switch, status => $statename };
    
    $resultdata->{group}     = $self->format_group($group);
    $resultdata->{groupname} = $groupname;
    
    $self->set_result_success( $resultdata, 'switch' );
    
}

sub command_alias {
    my $self = shift;
    
    if( $self->options->{help} ) {
        $self->set_result_success(undef, 'help');
        return;
    }
    
    if( $self->options->{list} ) {
        $self->list_switches('list');
        return;
    }
    
    my $groupname = $self->options->{groupname};
    my $switch    = $self->options->{switch};
    my $name      = $self->options->{name};
    my $group     = 0;
    
    unless( $switch && $switch =~ /^|1|2|3|4$/) {
        $self->set_result_error(
            ERROR_ALIAS_INVALID_SWITCH,
            q(You must provide a valid switch number --switch 0|1|2|3|4 ( 0 switches all switches in the group )),
            'alias'
        );
        return;
    }
    
    unless( $name ) {
        $self->set_result_error(
            ERROR_ALIAS_INVALID_OPTIONS,
            q(You must provide at least --switch and --name to alias a switch),
            'alias'
        );
        return;
    }
    
    if( $self->receiver ) {
        # we care about group name
        unless($groupname) {
            $self->set_result_options_error(
                ERROR_ALIAS_INVALID_OPTIONS,
                'You must provide --groupname, --switch and --name to alias a switch when using the txrx ENER314_RT or RF69HW boards',
                'alias'
            );
            return;
        }
        
        # get the group
        for my $checkgroup( keys %{ $self->conf->{groups} } ) {
            if(lc($self->conf->{groups}->{$checkgroup}) eq lc($groupname) ) {
                $group = $checkgroup;
                last;
            }
        }
        
        unless( $group ) {
            $self->set_result_error(
                ERROR_ALIAS_GROUP_NOT_FOUND,
                qq(Could not find a configured group named $groupname),
                'alias'
            );
            return;
        }
    } else {
        $group = ENERGENIE_ENER314_DUMMY_GROUP;
        $groupname = 'energenie_single_group';
    }
    
    # do we have an alias for this group already
    
    for my $switchname ( keys %{ $self->conf->{switches} } ) {
        if(   $self->conf->{switches}->{$switchname}->{switch} == $switch
           && $self->conf->{switches}->{$switchname}->{group} == $group )
        {
            delete($self->conf->{switches}->{$switchname});
        }
    }
    
    $self->conf->{switches}->{$name} = { group => $group, switch => $switch };
    $self->list_switches('alias');
    return;
}


sub command_join {
    my $self = shift;
    
    if( $self->options->{help} ) {
        $self->set_result_success(undef, 'help');
        return;
    }
    
    if( $self->options->{list} ) {
        $self->list_adapters_monitors('list', 'both');
        return;
    }
    
    unless( $self->receiver ) {
        $self->set_result_error(
            ERROR_USUPPORTED_RX_COMMAND,
            q(You must be using board ENER314_RT or RF69HW to use join command),
            'join'
        );
        return;
    }
    
    my $name   = $self->options->{name};
    my $delete = $self->options->{delete};
    my $rename = $self->options->{rename};
    
    if( $delete ) {
        my $deleted;
        if(exists($self->conf->{adapters}->{$delete})) {
            delete($self->conf->{adapters}->{$delete});
            $deleted = 1;
        }
        if(exists($self->conf->{monitors}->{$delete})) {
            delete($self->conf->{monitors}->{$delete});
            $deleted = 1;
        }
        if( $deleted ) {
            $self->list_adapters_monitors('delete', 'both' );
            return;
        } else {
            $self->set_result_error(
                ERROR_JOIN_DEVICE_NOT_FOUND,
                qq(The adaptor or monitor named $delete was not found in configuration),
                'delete'
            );
            return;
        }
    } elsif( $rename ) {
        unless( $name ) {
            $self->set_result_options_error(
                ERROR_JOIN_INVALID_OPTIONS,
                q(You must provide a --name option together with iption --rename),
                'rename'
            );
            return;
        }
        
        # does name already exist
        if(exists($self->conf->{monitors}->{$name})) {
            $self->set_result_error(
                ERROR_JOIN_EXISTING_ADAPTER,
                qq(An adapter or monitor named $name already exists in your configuration ),
                'rename'
            );
            return;
        }
        # does rename exist
                
        unless(exists($self->conf->{monitors}->{$rename})) {
            $self->set_result_error(
                ERROR_JOIN_DEVICE_NOT_FOUND,
                qq(The adaptor or monitor named $rename was not found in configuration),
                'rename'
            );
            return;
        }
        
        $self->conf->{monitors}->{$name} = $self->conf->{monitors}->{$rename};
        delete( $self->conf->{monitors}->{$rename} );
        
        if(exists($self->conf->{adapters}->{$rename})) {
            $self->conf->{adapters}->{$name} = $self->conf->{adapters}->{$rename};
            delete( $self->conf->{adapters}->{$rename} );
        }
        
        $self->list_adapters_monitors('rename', 'both');
        return;
    }
    
    # does name already exist
    if(exists($self->conf->{adapters}->{$name})) {
        $self->set_result_error(
            ERROR_JOIN_EXISTING_ADAPTER,
            qq(An adapter or monitor named $name already exists in your configuration),
            'rename'
        );
        return;
    }
    
    # only show on console
    print STDERR qq(\nListening for join messages from adapters and monitors. Set your device mode to join ....\n\n);
    
    my $timeout = $self->options->{timeout};
    unless( $timeout =~ /^[1-9][0-9]*$/) {
        $self->set_result_options_error(
            ERROR_JOIN_INVALID_OPTIONS,
            qq(Invalid value for timeout $timeout),
        );
        return;
    }
    
    my $result =  try {
        my $handler = HiPi::Energenie->new(
            backend    => $self->conf->{board},
            devicename => $self->conf->{spi_device},
            reset_gpio => $self->conf->{reset_gpio},
        );
        
        return $handler->process_request(
            command  => 'join',
            timeout  => $timeout,
        );
    } catch {
        return { success => 0, error => $_ , catch_errorcode => ERROR_SYSTEM };
    };
    
    if( $result->{success} ) {
        
        my $joinmsg = $result->{data};
        
        # check if we know this sensor key
        if(my $registered_name = $self->registered_sensor( $joinmsg->sensor_key ) ) {
            my $sensorkey = $joinmsg->sensor_key;
            $self->set_result_error( ERROR_JOIN_FAILED, qq(Device $sensorkey is already registered as $registered_name), 'join' );
            return;
        }
        
        $self->conf->{monitors}->{$name} = {
            manufacturer_id => $joinmsg->manufacturer_id,
            product_id      => $joinmsg->product_id,
            product_name    => $joinmsg->product_name,
            sensor_id       => $joinmsg->sensor_id,
            sensor_key      => $joinmsg->sensor_key,
        };
        
        if( HiPi::RF::OpenThings->product_can_switch( $joinmsg->manufacturer_id, $joinmsg->product_id ) ) {
            $self->conf->{adapters}->{$name} = {
                manufacturer_id => $joinmsg->manufacturer_id,
                product_id      => $joinmsg->product_id,
                product_name    => $joinmsg->product_name,
                sensor_id       => $joinmsg->sensor_id,
                sensor_key      => $joinmsg->sensor_key,
            };
        }
        
        $self->list_adapters_monitors('join', 'both' );
    } else {
        my $error = $result->{error};
        $error =~ s/\n/ /g;
        my $errorcode = $result->{catch_errorcode} || ERROR_JOIN_FAILED;
        $self->set_result_error( $errorcode, $error, 'join' );
    }
}

sub command_adapter {
    my $self = shift;
    
    if( $self->options->{help} ) {
        $self->set_result_success(undef, 'help');
        return;
    }
    
    if( $self->options->{list} ) {
        $self->list_adapters_monitors('list', 'adapters');
        return;
    }
    
    unless( $self->receiver ) {
        $self->set_result_error(
            ERROR_USUPPORTED_RX_COMMAND,
            q(You must be using board ENER314_RT or RF69HW to use the adapter command),
            'switch'
        );
        return;
    }
    
    my $name = $self->options->{name};
    
    unless($name) {
        $self->set_result_options_error(
            ERROR_ADAPTER_INVALID_OPTIONS,
            q(You must provide an adapter --name for the adapter command),

        );
        return;
    }
    
    my $nameconfig;
    
    # get the name
    for my $checkname( keys %{ $self->conf->{adapters} } ) {
        if(lc($checkname) eq lc($name) ) {
            $nameconfig = $self->conf->{adapters}->{$checkname};
            last;
        }
    }
    
    unless( $nameconfig ) {
        $self->set_result_error(
            ERROR_ADAPTER_NAME_NOT_FOUND,
            qq(Could not find a configured adapter named $name)
        );
        return;
    }
    
    my $timeout = $self->options->{timeout};

    if( $self->options->{query} ) {
        unless( $timeout =~ /^[1-9][0-9]*$/) {
            $self->set_result_options_error(
                ERROR_ADAPTER_INVALID_OPTIONS,
                qq(Invalid value for timeout $timeout),
                'query',
            );
            return;
        }
        $self->do_monitor_query( $nameconfig, 'adapter', $name, $timeout );
        return;
    }
    
    # in switch mode
    
    if(!$self->options->{on} && !$self->options->{off}) {
        $self->set_result_options_error(
            ERROR_ADAPTER_INVALID_OPTIONS,
            q(You must specify either --on or --off to switch an adapter),
            'switch',
        );
        return;
    }
    
    if($self->options->{on} && $self->options->{off}) {
        $self->set_result_options_error(
            ERROR_ADAPTER_INVALID_OPTIONS,
            q(You must specify either --on or --off - not both to switch an adapter),
            'switch',
        );
        return;
    }
    
    unless( $timeout =~ /^[1-9][0-9]*$/) {
        $self->set_result_options_error(
            ERROR_ADAPTER_INVALID_OPTIONS,
            qq(Invalid value for timeout $timeout),
            'switch',
        );
        return;
    }
    
    my $state = ( $self->options->{on} ) ? 1 : 0;
    
    # do switch
    
    my $result = try {
        my $handler = HiPi::Energenie->new(
            backend    => $self->conf->{board},
            devicename => $self->conf->{spi_device},
            reset_gpio => $self->conf->{reset_gpio},
        );
    
        my $val = $handler->process_request(
            command         => 'switch',
            sensor_key      => $nameconfig->{sensor_key},
            switch_state    => $state,
            timeout         => $timeout,
        );
        
        return $val;
    } catch {
        return { success => 0, error => $_ , catch_errorcode => ERROR_SYSTEM };
    };
    
    if( !$result->{success} ) {
        my $error = $result->{error};
        $error =~ s/\n/ /g;
        my $errorcode = $result->{catch_errorcode} || ERROR_ADAPTER_FAILED;
        $self->set_result_error( $errorcode, $error, 'switch' );
        return;
    }
    
    my $data = $result->{data};
    $data->configured_name( $name );
    
    $self->set_result_success($data, 'switch');
}

sub command_monitor {
    my $self = shift;
    
    if( $self->options->{help} ) {
        $self->set_result_success(undef, 'help');
        return;
    }
    
    if( $self->options->{list} ) {
        $self->list_adapters_monitors('list', 'monitors');
        return;
    }
    
    unless( $self->receiver ) {
        $self->set_result_error(
            ERROR_USUPPORTED_RX_COMMAND,
            q(You must be using board ENER314_RT or RF69HW to use the monitor command),
            'switch'
        );
        return;
    }
    
    my $name = $self->options->{name};
    
        unless($name) {
        $self->set_result_options_error(
            ERROR_MONITOR_INVALID_OPTIONS,
            q(You must provide a monitor --name for the monitor command),

        );
        return;
    }
    
    
    my $nameconfig;
    
    # get the name
    for my $checkname( keys %{ $self->conf->{monitors} } ) {
        if(lc($checkname) eq lc($name) ) {
            $nameconfig = $self->conf->{monitors}->{$checkname};
            last;
        }
    }
    
    unless( $nameconfig ) {
        $self->set_result_error(
            ERROR_MONITOR_NAME_NOT_FOUND,
            qq(Could not find a configured monitor named $name)
        );
        return;
    }
    
    my $timeout = $self->options->{timeout};
    unless( $timeout =~ /^[1-9][0-9]*$/) {
        $self->set_result_options_error(
            ERROR_MONITOR_INVALID_OPTIONS,
            qq(Invalid value for timeout $timeout),
        );
        return;
    }
    
    $self->do_monitor_query( $nameconfig, 'monitor', $name, $timeout );
}

sub do_monitor_query {
    my ( $self, $nameconfig, $type, $configname, $timeout ) = @_;
    
    my $result = try {
        my $handler = HiPi::Energenie->new(
            backend    => $self->conf->{board},
            devicename => $self->conf->{spi_device},
            reset_gpio => $self->conf->{reset_gpio},
        );
    
        my $val = $handler->process_request(
            command         => 'query',
            sensor_key      => $nameconfig->{sensor_key},
            timeout         => $timeout,
        );
        
        return $val;
    } catch {
        return { success => 0, error => $_ , catch_errorcode => ERROR_SYSTEM };
    };
    
    if( !$result->{success} ) {
        my $error = $result->{error};
        $error =~ s/\n/ /g;
        my $alterror = ( $type eq 'adapter ') ? ERROR_ADAPTER_FAILED : ERROR_MONITOR_FAILED;
        my $errorcode = $result->{catch_errorcode} || $alterror;
        $self->set_result_error( $errorcode, $error, 'query' );
        return;
    }
    
    my $data = $result->{data};
    
    $data->configured_name( $configname );
    
    $self->set_result_success($data, 'query');
    
    return;
}

sub list_configuration {
    my ($self, $option )  = @_;
    $self->config->write_config;
    $self->set_result_success( {
        'version'    => $self->conf->{version},
        'board'      => $self->conf->{board},
        'spi_device' => $self->conf->{spi_device},
        'reset_gpio' => $self->conf->{reset_gpio},
        'uses_spi'   => ( $self->receiver ) ? 'YES' : 'NO',
        'can_rx'     => ( $self->receiver ) ? 'YES' : 'NO',
        'epoch'      => $self->conf->{epoch} || 1,
    }, $option );
    return;
}

sub list_groups {
    my ($self, $option )  = @_;
    
    my $groups = {};
    
    for my $group ( keys %{ $self->conf->{groups} } ) {
        my $groupname = $self->conf->{groups}->{$group};
        $groups->{$groupname} = $self->format_group( $group );
    }
    
    $self->set_result_success( { groups => $groups }, $option );
    return;
}

sub list_adapters_monitors {
    my ($self, $option, $type) = @_;
    
    my @todolist = ( $type eq 'both' ) ? ( qw( adapters monitors )  ) : ( $type );
    
    my $resdata = {};
    
    for my $item ( @todolist ) {
        my $data = {};
        my $conf = $self->conf->{$item};
        for my $member ( keys %$conf ) {
            for my $element ( keys %{ $conf->{$member} } ) {
                $data->{$member}->{$element} = $conf->{$member}->{$element};
            }
        }
        $resdata->{$item} = $data;
    }
    
    $self->set_result_success( $resdata, $option );
    
    return;
}

sub list_switches {
    my ($self, $option) = @_;
        
    my $data = {};
    my $conf = $self->conf->{switches};
    for my $member ( keys %$conf ) {
        
        $data->{switches}->{$member}->{switch} = $conf->{$member}->{switch};
        $data->{switches}->{$member}->{group} = $self->conf->{groups}->{$conf->{$member}->{group}};
    }
    
    $self->set_result_success( $data, $option );
    
    return;
}

sub registered_sensor {
    my( $self, $sensorkey ) = @_;
    $sensorkey = lc($sensorkey);
    for my $item ( qw( adapters monitors ) ) {
        my $conf = $self->conf->{$item};
        for my $member ( keys %$conf ) {
            if( lc($conf->{$member}->{sensor_key})  eq  $sensorkey ) {
                return $member;
            }
        }
    }
    return undef;
}

sub generate_switch_group {
    my $self = shift;
    # a number between 0x1 and 0xFFFFF
    my $group = 1 + int(rand(0xFFFFE));
    return $group;
}

sub format_group {
    my ($self, $id) = @_;
    return sprintf('0x%06X', $id);
}

sub receiver {
    my $self = shift;
    return ( $self->conf->{board} =~ /^ENER314_RT|RF69HW$/ ) ? 1 : 0;
}

sub get_command_usage {
    my($self, $command) = @_;
    
    my $usagetext = {
        
    #### GENERAL USAGE ################################
    
        unknown => q(
  usage : hipi-energenie <command> [options]
  
  command :
    help        Print this message
    version     Print the version
    config      Configure the board type ( ENER314_RT, ENER314 or RF69HW )
    group       Manage groups for use with sockets
    pair        Pair a socket or switch
    alias       Rename or name a socket or switch
    switch      Switch a socket or switch on or off
    join        Configure a monitor or adaptor
    adapter     Switch an adapter device on or off
    monitor     Query a monitoring device for values

  For help on each command use:
    hipi-energenie <command> -h
),

    #### CONFIG USAGE ################################
    
       config => q(
  usage : hipi-energenie config <options>
  
  options :

    --help        -h  Display this message

    --list        -l  List the current config

    --board       -b  < ENER314 | ENER314_RT | RF69HW > Set the board type that
                      you have connected to the Raspberry Pi.
                      Default is 'ENER314_RT'

    --device      -d  < devicename > Set the SPI device used by the
                      ENER314_RT or RF69HW board. Default is '/dev/spidev0.1'
    
    --reset       -r  < gpio > Specify the GPIO pin connected to
                      the reset pin on the ENER314_RT or RF69HW board.
                      Default is 25 ( RPI_PIN_22 )
    
    --json            The command results will be output as a JSON
                      string. This can be used when you want to parse
                      the command output from external code.

    --pretty          The command results will be output as formatted JSON
                      with line breaks and indentation.

),
    #### GROUP USAGE ################################

        group => q(
  usage : hipi-energenie group <options>

  description: Set up groups for use with ENER314_RT or RF69HW board to
               control multiple sets of simple switches or sockets.

  options :

    --help        -h  Display this message

    --list        -l  List the currently configured groups

    --create      -c  <name> Create a new group. The system will create a new
                      unused group id and associate the supplied name with it.
                      e.g. hipi-energenie group -c newname
                      Provide option --groupid to name an existing group.                       
                      
    --delete      -d  <name> Delete an existing group.
                      e.g. hipi-energenie group -d 'my group 1'
                      
    --rename      -r  <name> Rename an existing group. Must be accompanied
                      by option for --newname.
                      e.g. hipi-energenie group -r oldname -n newname
    
    --newname     -n  <name> The new name for a group. (used with --rename)

    --groupid         <groupid> The group id identifier that is used
                      to control a group of four switches or sockets,
                      or one 4 way gang extension. This is a number
                      between 0x01 and 0xFFFFF. The parameter can be
                      passed in decimal, hexadecimal or binary
                      notation. It is parsed by the Perl 'oct'
                      function.

    --json            The command results will be output as a JSON
                      string. This can be used when you want to parse
                      the command output from external code.

    --pretty          The command results will be output as formatted JSON
                      with line breaks and indentation.

),

    #### PAIR USAGE ################################
    
        pair => q(
  usage : hipi-energenie pair <options>
  
  description: pair with a simple socket or switch such as an ENER002 switch
               socket; an ENER010 4 way extension; a Mi|Home MIHO002 adapter.
               Set the adapter to pairing mode and run this command.

  options :

    --help        -h  Display this message

    --list        -l  list paired switches
    
    --groupname   -g  <groupname> A groupname you have configured using the
                      group command. If you are using the transmit
                      only ENER314 board, this option is ignored.

    --switch      -s  < 1 | 2 | 3 | 4 > The number of the switch or socket
                      you want to pair. Each groupname can control a
                      maximum of 4 switches. If you are pairing an
                      ENER010 4 gang extension, use '1'
                      
    --name        -n  <switchname> A name for the paired switch
                      that you may use in the future to command the switch
                      rather than specifying both group and switch
                      number.

    --json            The command results will be output as a JSON
                      string. This can be used when you want to parse
                      the command output from external code.

    --pretty          The command results will be output as formatted JSON
                      with line breaks and indentation.
                      
    ( to rename a switch / group pair use the 'alias' command )

),        
    #### SWITCH USAGE ################################
    
        switch => q(
  usage : hipi-energenie switch <options>
  
  description: Turn a paired socket or switch on or off

  options :
    --help        -h  Display this message

    --list        -l  List the currently configured switches

    --name        -n  <switchname> An alias for the groupname / switch pair
    
    --groupname   -g  <groupname> If you don't provide a name you can specify
                      groupname and switch number instead. This is the
                      groupname you paired the switch with.
                      If you are using the transmit only ENER314 board,
                      this option is ignored.

    --switch      -s  < 0 | 1 | 2 | 3 | 4 > If you don't provide a name you can
                      specify groupname and switch number instead. This is the
                      number of the switch or socket you want to switch.
                      Specifying 0 switches all members of the group.
                      
    --on          -1  Switch the socket on

    --off         -0  Switch the socket off
    
    --all             Switch all sockets in the group. The same as specifying
                      --switch 0

    --json            The command results will be output as a JSON
                      string. This can be used when you want to parse
                      the command output from external code.

    --pretty          The command results will be output as formatted JSON
                      with line breaks and indentation.

),

#### ALAIS USAGE ################################
    
        alias => q(
  usage : hipi-energenie alias <options>
  
  description: Give a name to a groupname / switch number pair

  options :
    --help        -h  Display this message
    
    --list        -l  List configured aliases
    
    --name        -n  <switchname> The alias you want to use
    
    --groupname   -g  <groupname>  The group for the alias

    --switch      -s  < 1 | 2 | 3 | 4 > The switch number for the alias
                      
    --json            The command results will be output as a JSON
                      string. This can be used when you want to parse
                      the command output from external code.

    --pretty          The command results will be output as formatted JSON
                      with line breaks and indentation.

),        
    #### JOIN USAGE ################################
    
        join => q(
  usage : hipi-energenie join <options>
  
  description: Join a Mi|Home monitor or adapter. Run this command first and
               then switch your adapter or monitor to join mode.

  options :
  
    --help        -h  Display this message
    
    --list        -l  List the adapters and monitors already joined

    --name        -n  <name> A name for the adapter or monitor. This
                      is required.

    --rename      -r  <name> You can rename an adapter. If --rename is specified
                      then --rename contains the existing name and --name contains the
                      new name.
                      
    --delete      -d  <name> Remove the named monitor or adapter from configuration
    
    --timeout     -t <timeout> Timeout in seconds to wait for a join request.
                      The default is 60.

    --json            The command results will be output as a JSON
                      string. This can be used when you want to parse
                      the command output from external code.

    --pretty          The command results will be output as formatted JSON
                      with line breaks and indentation.

),
    #### ADAPTER USAGE ################################
      
        adapter => q(
  usage : hipi-energenie adapter <options>
  
  description: Switch a Mi|Home Adapter Plus on and off or query its switch state

  options :
  
    --help        -h  Display this message
    
    --list        -l  List all the adapters registered

    --name        -n  <name> The name registered for the adapter. This
                      is required.

    --query       -q  Get the switch state for the adapter
    
    --on          -1  Switch the adapter on
    
    --off         -0  Switch the adapter off
    
    --timeout     -t <timeout> Timeout in seconds to wait for a confirmation.
                      The default is 60.

    --json            The command results will be output as a JSON
                      string. This can be used when you want to parse
                      the command output from external code.

    --pretty          The command results will be output as formatted JSON
                      with line breaks and indentation.

),    
    #### MONITOR USAGE ################################
    
        monitor => q(
  usage : hipi-energenie monitor <options>
  
  description: Query status from a Mi|Home adapter or monitor

  options :
  
    --help        -h  Display this message
    
    --list        -l  List all the monitors registered

    --name        -n  <name> The name registered for the montitor. This
                      is required.
                      
    --timeout     -t <timeout> Timeout in seconds to wait for a response.
                      The default is 60.

    --json            The command results will be output as a JSON
                      string. This can be used when you want to parse
                      the command output from external code.

    --pretty          The command results will be output as formatted JSON
                      with line breaks and indentation.

),    
    };
    
    
    if(exists($usagetext->{$command})) {
        return $usagetext->{$command};
    } else {
        return $usagetext->{unknown};
    }
}

1;

__END__