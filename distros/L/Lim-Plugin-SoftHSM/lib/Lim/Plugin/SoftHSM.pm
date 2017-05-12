package Lim::Plugin::SoftHSM;

use common::sense;
use Carp;

use base qw(Lim::Component);

=encoding utf8

=head1 NAME

Lim::Plugin::SoftHSM - SoftHSM management plugin for Lim

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

  use Lim::Plugin::SoftHSM;

  # Create a Server object
  $server = Lim::Plugin::SoftHSM->Server;

  # Create a Client object
  $client = Lim::Plugin::SoftHSM->Client;

  # Create a CLI object
  $cli = Lim::Plugin::SoftHSM->CLI;

=head1 DESCRIPTION

This plugin lets you manage a SoftHSM installation via Lim.

=head1 METHODS

=over 4

=item $plugin_name = Lim::Plugin::SoftHSM->Name

Returns the plugin's name.

=cut

sub Name {
    'SoftHSM';
}

=item $plugin_description = Lim::Plugin::SoftHSM->Description

Returns the plugin's description.

=cut

sub Description {
    'This plugin lets you manage a SoftHSM installation via Lim.';
}

=item $call_hash_ref = Lim::Plugin::SoftHSM->Calls

Returns a hash reference to the calls that can be made to this plugin, used both
in Server and Client to verify input and output arguments.

See CALLS for list of calls and arguments.

=cut

sub Calls {
    {
        ReadVersion => {
            out => {
                version => 'string',
                program => {
                    name => 'string',
                    version => 'string'
                }
            }
        },
        #
        # Calls for config files
        #
        ReadConfigs => {
            out => {
                file => {
                    name => 'string',
                    write => 'bool',
                    read => 'bool'
                }
            }
        },
        CreateConfig => {
            in => {
                file => {
                    '' => 'required',
                    name => 'string',
                    content => 'string'
                }
            }
        },
        ReadConfig => {
            in => {
                file => {
                    '' => 'required',
                    name => 'string'
                }
            },
            out => {
                file => {
                    name => 'string',
                    content => 'string'
                }
            }
        },
        UpdateConfig => {
            in => {
                file => {
                    '' => 'required',
                    name => 'string',
                    content => 'string'
                }
            }
        },
        DeleteConfig => {
            in => {
                file => {
                    '' => 'required',
                    name => 'string'
                }
            }
        },
        #
        # Calls for softhsm executable tool
        #
        ReadShowSlots => {
            out => {
                slot => {
                    id => 'integer',
                    token_label => 'string',
                    token_present => 'bool',
                    token_initialized => 'bool',
                    user_pin_initialized => 'bool',
                }
            }
        },
        CreateInitToken => {
            in => {
                token => {
                    '' => 'required',
                    slot => 'integer',
                    label => 'string',
                    so_pin => 'string',
                    pin => 'string'
                }
            }
        },
        CreateImport => {
            in => {
                key_pair => {
                    '' => 'required',
                    content => 'string',
                    file_pin => 'string optional',
                    slot => 'integer',
                    pin => 'string',
                    label => 'string',
                    id => 'string'
                }
            }
        },
        ReadExport => {
            in => {
                key_pair => {
                    '' => 'required',
                    file_pin => 'string optional',
                    slot => 'integer',
                    pin => 'string',
                    id => 'string'
                }
            },
            out => {
                key_pair => {
                    id => 'string',
                    content => 'string'
                }
            }
        },
        UpdateOptimize => {
            in => {
                slot => {
                    '' => 'required',
                    id => 'integer',
                    pin => 'string'
                }
            }
        },
        UpdateTrusted => {
            in => {
                key_pair => {
                    '' => 'required',
                    trusted => 'bool',
                    slot => 'integer',
                    so_pin => 'string',
                    type => 'string',
                    label => 'string optional',
                    id => 'string optional'
                }
            }
        }
    };
}

=item $command_hash_ref = Lim::Plugin::SoftHSM->Commands

Returns a hash reference to the CLI commands that can be made by this plugin.

See COMMANDS for list of commands and arguments.

=cut

sub Commands {
    {
        version => [ 'Show version of the plugin and SoftHSM' ],
        configs => [ 'List configuration files' ],
        config => {
            view => [ '<file>', 'Display the content of a configuration file' ],
            edit => [ '<file>', 'Edit a configuration file' ]
        },
        show => {
            slots => [ 'List information about SoftHSM slots' ]
        },
        init => {
            token => [ '<slot> <label> <SO pin> <pin>', 'Initialize a slot' ]
        },
        import => [ '[--slot <slot>] [--pin <pin>] [--id <id>] [--label <label>] [--file-pin <file pin>] <file>', 'Import a key into SoftHSM from a local file' ],
        export => [ '[--slot <slot>] [--pin <pin>] [--id <id>] [--file-pin <file pin>] <file>', 'Export a key from SoftHSM into a local file' ],
        optimize => [ '[--pin <pin>] <slots ... >', 'Optimize slot(s)' ],
        trust => [ '[--slot <slot>] [--so-pin <SO pin>] [--type <type>] < --id <id> | --label <label> >', 'Mark a key as trusted' ],
        untrust => [ '[--slot <slot>] [--so-pin <SO pin>] [--type <type>] < --id <id> | --label <label> >', 'Remove the trusted marking on a key' ]
    };
}

=back

=head1 CALLS

See L<Lim::Component::Client> on how calls and callback functions should be
used.

=over 4

=item $client->ReadVersion(sub { my ($call) = @_; })

Get the version of the plugin and version of SoftHSM found.

  $response = {
    version => string, # Version of the plugin
    program => # Single hash or an array of hashes as below:
    {
      name => string,    # Program name
      version => string, # Program version
    }
  };

=item $client->ReadConfigs(sub { my ($call) = @_; })

Get a list of all config files that can be managed by this plugin.

  $response = {
    file => # Single hash or an array of hashes as below:
    {
      name => string, # Full path file name
      read => bool,   # True if readable
      write => bool,  # True if writable
    }
  };

=item $client->CreateConfig($input, sub { my ($call) = @_; })

Create a new config file, returns an error if it failed to create the config
file otherwise there is no response.

  $input = {
    file => # Single hash or an array of hashes as below:
    {
      name => string,    # Full path file name
      content => string, # Configuration content
    }
  };

=item $client->ReadConfig($input, sub { my ($call) = @_; })

Returns a config file as a content.

  $input = {
    file => # Single hash or an array of hashes as below:
    {
      name => string, # Full path file name
    }
  };

  $response = {
    file => # Single hash or an array of hashes as below:
    {
      name => string,    # Full path file name
      content => string, # Configuration content
    }
  };

=item $client->UpdateConfig($input, sub { my ($call) = @_; })

Update a config file, this will overwrite the file. Returns an error if it
failed to update the config file otherwise there is no reponse.

  $input = {
    file => # Single hash or an array of hashes as below:
    {
      name => string,    # Full path file name
      content => string, # Configuration content
    }
  };

=item $client->DeleteConfig($input, sub { my ($call) = @_; })

Delete a config file, returns an error if it failed to delete the config file
otherwise there is no reponse.

  $input = {
    file => # Single hash or an array of hashes as below:
    {
      name => string, # Full path file name
    }
  };

=item $client->ReadShowSlots(sub { my ($call) = @_; })

Get a list of all SoftHSM slots that are available.

  $response = {
    slot => # Single hash or an array of hashes as below:
    {
      id => integer,                # Slot id
      token_initialized => bool,    # True if the token has been initialized
      token_label => string,        # Token label
      token_present => bool,        # True if there is a token present
      user_pin_initialized => bool, # True if the user pin for the token has
                                    # been initialized
    }
  };

=item $client->CreateInitToken($input, sub { my ($call) = @_; })

Initialize a slot, returns an error if it failed to initialize the slot
otherwise there is no response.

  $input = {
    token => # Single hash or an array of hashes as below:
    {
      slot => integer,  # Slot id
      label => string,  # Label
      pin => string,    # User pin
      so_pin => string, # Security Officer pin
    }
  };

=item $client->CreateImport($input, sub { my ($call) = @_; })

Import a key into a slot, returns an error if it failed to import the key
otherwise there is no response.

  $input = {
    key_pair => # Single hash or an array of hashes as below:
    {
      slot => integer,    # Slot to import to
      id => string,       # Key id
      label => string,    # Key label
      pin => string,      # User pin
      content => string,  # Key in PKCS#8 format
      file_pin => string, # File pin if encrypted (optional)
    }
  };

=item $client->ReadExport($input, sub { my ($call) = @_; })

Export a key from a slot, returns an error if it failed to export the key.

  $input = {
    key_pair => # Single hash or an array of hashes as below:
    {
      slot => integer,    # Slot to export from
      id => string,       # Key id
      pin => string,      # User pin
      file_pin => string, # File pin to use for encryption (optional)
    }
  };

  $response = {
    key_pair => # Single hash or an array of hashes as below:
    {
      id => string,      # Key id
      content => string, # Key in PKCS#8 format
    }
  };

=item $client->UpdateOptimize($input, sub { my ($call) = @_; })

Optimize the SoftHSM database, returns an error if it failed to optimize the
database otherwise there is no response.

WARNING: Make sure that no application is currently using SoftHSM and session
objects.

  $input = {
    slot => # Single hash or an array of hashes as below:
    {
      id => integer, # Slot id
      pin => string, # User pin
    }
  };

=item $client->UpdateTrusted($input, sub { my ($call) = @_; })

Update the trusted status of a key, returns an error if it failed to update the
key otherwise there is no response. Must have either key id or key label.

  $input = {
    key_pair => # Single hash or an array of hashes as below:
    {
      slot => integer,  # Slot where the key is
      id => string,     # Key id (optional)
      label => string,  # Key label (optional)
      type => string,   # Key type
      so_pin => string, # Security Officer pin
      trusted => bool,  # True if the key should be trusted
    }
  };

=back

=head1 COMMANDS

=over 4

=item version

Show version of the plugin and SoftHSM.

=item configs

List configuration files.

=item config view <file>

Display the content of a configuration file.

=item config edit <file>

Edit a configuration file.

=item show slots

List information about SoftHSM slots.

=item init token <slot> <label> <SO pin> <pin>

Initialize a slot.

=item import [--slot <slot>] [--pin <pin>] [--id <id>] [--label <label>] [--file-pin <file pin>] <file>

Import a key into SoftHSM from a local file.

=item export [--slot <slot>] [--pin <pin>] [--id <id>] [--file-pin <file pin>] <file>

Export a key from SoftHSM into a local file.

=item optimize [--pin <pin>] <slots ... >

Optimize slot(s).

=item trust [--slot <slot>] [--so-pin <SO pin>] [--type <type>] < --id <id> | --label <label> >

Mark a key as trusted.

=item untrust [--slot <slot>] [--so-pin <SO pin>] [--type <type>] < --id <id> | --label <label> >

Remove the trusted marking on a key.

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-softhsm/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::SoftHSM

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-softhsm/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Plugin::SoftHSM
