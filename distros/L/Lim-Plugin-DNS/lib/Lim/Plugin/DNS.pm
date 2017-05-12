package Lim::Plugin::DNS;

use common::sense;

use base qw(Lim::Component);

=encoding utf8

=head1 NAME

Lim::Plugin::DNS - DNS Manager plugin for Lim

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

  use Lim::Plugin::DNS;

  # Create a Server object
  $server = Lim::Plugin::DNS->Server;

  # Create a Client object
  $client = Lim::Plugin::DNS->Client;

  # Create a CLI object
  $cli = Lim::Plugin::DNS->CLI;

=head1 DESCRIPTION

This plugin manage generic DNS related information like zone files via Lim. It
does not manage DNS software specific information.

=head1 METHODS

=over 4

=item $plugin_name = Lim::Plugin::DNS->Name

Returns the plugin's name.

=cut

sub Name {
    'DNS';
}

=item $plugin_description = Lim::Plugin::DNS->Description

Returns the plugin's description.

=cut

sub Description {
    'This plugin manage generic DNS related information like zone files via Lim. It does not manage DNS software specific information.';
}

=item $call_hash_ref = Lim::Plugin::DNS->Calls

Returns a hash reference to the calls that can be made to this plugin, used both
in Server and Client to verify input and output arguments.

See CALLS for list of calls and arguments.

=cut

sub Calls {
    {
        ReadZones => {
            out => {
                zone => {
                    file => 'string',
                    software => 'string optional',
                    read => 'bool',
                    write => 'bool'
                }
            }
        },
        #
        # Zone
        #
        CreateZone => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional',
                    option => {
                        name => 'string',
                        value => 'string'
                    },
                    rr => {
                        name => 'string',
                        ttl => 'string optional',
                        class => 'string optional',
                        type => 'string',
                        rdata => 'string',
                        rr => {
                            ttl => 'string optional',
                            class => 'string optional',
                            type => 'string',
                            rdata => 'string'
                        }
                    },
                    content => 'string optional'
                }
            },
        },
        ReadZone => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional',
                    as_content => 'bool optional'
                }
            },
            out => {
                zone => {
                    file => 'string',
                    software => 'string optional',
                    option => {
                        name => 'string',
                        value => 'string'
                    },
                    rr => {
                        name => 'string',
                        ttl => 'string optional',
                        class => 'string optional',
                        type => 'string',
                        rdata => 'string'
                    },
                    content => 'string optional'
                }
            }
        },
        UpdateZone => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional',
                    option => {
                        name => 'string',
                        value => 'string'
                    },
                    rr => {
                        name => 'string',
                        ttl => 'string optional',
                        class => 'string optional',
                        type => 'string',
                        rdata => 'string',
                        rr => {
                            ttl => 'string optional',
                            class => 'string optional',
                            type => 'string',
                            rdata => 'string'
                        }
                    },
                    content => 'string optional'
                }
            }
        },
        DeleteZone => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional'
                }
            }
        },
        #
        # Zone Option
        #
        CreateZoneOption => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional',
                    option => {
                        '' => 'required',
                        name => 'string',
                        value => 'string'
                    }
                }
            }
        },
        ReadZoneOption => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional',
                    option => {
                        name => 'string'
                    }
                }
            },
            out => {
                zone => {
                    file => 'string',
                    software => 'string optional',
                    option => {
                        name => 'string',
                        value => 'string'
                    }
                }
            }
        },
        UpdateZoneOption => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional',
                    option => {
                        '' => 'required',
                        name => 'string',
                        value => 'string'
                    }
                }
            }
        },
        DeleteZoneOption => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional',
                    option => {
                        '' => 'required',
                        name => 'string'
                    }
                }
            }
        },
        #
        # Zone Resource Record
        #
        CreateZoneRr => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional',
                    rr => {
                        '' => 'required',
                        name => 'string',
                        ttl => 'string optional',
                        class => 'string optional',
                        type => 'string',
                        rdata => 'string',
                        rr => {
                            ttl => 'string optional',
                            class => 'string optional',
                            type => 'string',
                            rdata => 'string'
                        }
                    }
                }
            }
        },
        ReadZoneRr => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional',
                    rr => {
                        name => 'string'
                    }
                }
            },
            out => {
                zone => {
                    file => 'string',
                    software => 'string optional',
                    rr => {
                        name => 'string',
                        ttl => 'string optional',
                        class => 'string optional',
                        type => 'string',
                        rdata => 'string'
                    }
                }
            }
        },
        UpdateZoneRr => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional',
                    rr => {
                        '' => 'required',
                        name => 'string',
                        ttl => 'string optional',
                        class => 'string optional',
                        type => 'string',
                        rdata => 'string',
                        rr => {
                            ttl => 'string optional',
                            class => 'string optional',
                            type => 'string',
                            rdata => 'string'
                        }
                    }
                }
            }
        },
        DeleteZoneRr => {
            in => {
                zone => {
                    '' => 'required',
                    file => 'string',
                    software => 'string optional',
                    rr => {
                        '' => 'required',
                        name => 'string'
                    }
                }
            }
        }
    };
}

=item $command_hash_ref = Lim::Plugin::DNS->Commands

Returns a hash reference to the CLI commands that can be made by this plugin.

See COMMANDS for list of commands and arguments.

=cut

sub Commands {
    {
        zones => [ 'List existing zones and related software' ],
        zone => {
            create => [ '[--software <software>] <zone name> <local zone file>', 'Create a new zone with the content of a local zone file' ],
            read => [ '[--software <software>] <zone names ... >', 'Read zones and display content' ],
            update => [ '[--software <software>] <zone name> <local zone file>', 'Update a existing zone with the content of a local zone file' ],
            delete => [ '[--software <software>] <zone name>', 'Delete the specified zone' ]
        },
        option => {
            create => [ '[--software <software>] <zone name> <option name> <option values ... >', 'Create a new zone option in the an existing zone' ],
            read => [ '[--software <software>] <zone name> [option name]', 'Read and display the specified option, or all if not given, from the zone' ],
            update => [ '[--software <software>] <zone name> <option name> <option values ... >', 'Update an existing option in a zone' ],
            delete => [ '[--software <software>] <zone name> <option name>', 'Delete the specified option from a zone' ]
        },
        rr => {
            create => [ '[--software <software>] [--ttl <ttl>] [--class <class>] <zone name> <rr name> <rr type> <rr data ... >', 'Create a new resource record in an existing zone' ],
            read => [ '[--software <software>] <zone name> [rr name]', 'Read and display the specified resource record, or all if not given, from the zone' ],
            update => [ '[--software <software>] [--ttl <ttl>] [--class <class>] <zone name> <rr name> <rr type> <rr data ... >', 'Update an existing resource record in a zone' ],
            delete => [ '[--software <software>] <zone name> <rr name>', 'Delete the specified resource record from a zone' ]
        }
    };
}

=back

=head1 CALLS

See L<Lim::Component::Client> on how calls and callback functions should be
used.

=over 4

=item $client->ReadZones(sub { my ($call, $response) = @_; })

Get a list of all zones that can be managed by the plugin.

  $response = {
    zone => # (optional) Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file
      software => 'string', # Software related to the zone file (optional)
      read => 'bool',       # True if file can be read, otherwise false
      write => 'bool',      # True if file can be written to, otherwise false
    }
  };

=item $client->CreateZone($input, sub { my ($call) = @_; })

Create a new zone file, returns an error if it failed to create the zone file
otherwise there is no response.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)

      # Zone file data is created by option and rr or by a single content

      option => # (optional) Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of option (without $)
        value => 'string'   # Value of option
      },
      rr => # (optional) Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of RR
        ttl => 'string',    # TTL of RR (optional)
        class => 'string',  # Class of RR (optional)
        type => 'string',   # Type of RR
        rdata => 'string',  # Rdata of RR

        # If you wish to add more RR to the same name you can specify more rr
        # inside the rr.
            
        rr => # (optional) Single hash or an array of hashes as below:
        {
          ttl => 'string',   # TTL of RR (optional)
          class => 'string', # Class of RR (optional)
          type => 'string',  # Type of RR
          rdata => 'string', # Rdata of RR
        }
      },
      content => 'string'    # Content of zone file (optional)
    }
  };

=item $client->ReadZone($input, sub { my ($call, $response) = @_; })

Returns a zone file as a content or split into option and rr.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)
      as_content => 'bool'  # Specify that content should be returned (optional)
    }
  };

  $response = {
    zone => # (optional) Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file
      software => 'string', # Software related to the zone file (optional)
      option => # (optional) Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of option (without $)
        value => 'string'   # Value of option
      },
      rr => # (optional) Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of RR
        ttl => 'string',    # TTL of RR (optional)
        class => 'string',  # Class of RR (optional)
        type => 'string',   # Type of RR
        rdata => 'string',  # Rdata of RR
      },
      content => 'string'   # Content of zone file (optional)
    }
  };

=item $client->UpdateZone($input, sub { my ($call) = @_; })

Update a zone file, this overwrites all zone data. Returns an error if it failed
to update the zone file otherwise there is no reponse.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)

      # Zone file data is created by option and rr or by a single content

      option => # (optional) Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of option (without $)
        value => 'string'   # Value of option
      },
      rr => # (optional) Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of RR
        ttl => 'string',    # TTL of RR (optional)
        class => 'string',  # Class of RR (optional)
        type => 'string',   # Type of RR
        rdata => 'string',  # Rdata of RR

        # If you wish to add more RR to the same name you can specify more rr
        # inside the rr.
            
        rr => # (optional) Single hash or an array of hashes as below:
        {
          ttl => 'string',   # TTL of RR (optional)
          class => 'string', # Class of RR (optional)
          type => 'string',  # Type of RR
          rdata => 'string', # Rdata of RR
        }
      },
      content => 'string'    # Content of zone file (optional)
    }
  };

=item $client->DeleteZone($input, sub { my ($call) = @_; })

Delete a zone file, returns an error if it failed to delete the zone file
otherwise there is no reponse.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)
    }
  };

=item $client->CreateZoneOption($input, sub { my ($call) = @_; })

Create a new zone option, returns an error if it failed to create the zone
option otherwise there is no reponse.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)

      option => # Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of option (without $)
        value => 'string'   # Value of option
      }
    }
  };

=item $client->ReadZoneOption($input, sub { my ($call, $response) = @_; })

Return zone options specified or all zone options for a zone file.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)

      option => # (optional) Single hash or an array of hashes as below:
      {
        name => 'string'    # Name of option (without $)
      }
    }
  };

  $response = {
    zone => # (optional) Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file
      software => 'string', # Software related to the zone file (optional)
      option => # (optional) Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of option (without $)
        value => 'string'   # Value of option
      }
    }
  };

=item $client->UpdateZoneOption($input, sub { my ($call) = @_; })

Update a zone option, this does not overwrite other zone options. Returns an
error if it failed to update the zone options otherwise there is no reponse.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)

      option => # Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of option (without $)
        value => 'string'   # Value of option
      }
    }
  };

=item $client->DeleteZoneOption($input, sub { my ($call) = @_; })

Delete a zone options, returns an error if it failed to delete the zone options
otherwise there is no reponse.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)

      option => # Single hash or an array of hashes as below:
      {
        name => 'string'    # Name of option (without $)
      }
    }
  };

=item $client->CreateZoneRr($input, sub { my ($call) = @_; })

Create a new zone resource record, returns an error if it failed to create the
zone resource record otherwise there is no reponse.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)

      rr => # Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of RR
        ttl => 'string',    # TTL of RR (optional)
        class => 'string',  # Class of RR (optional)
        type => 'string',   # Type of RR
        rdata => 'string',  # Rdata of RR

        # If you wish to add more RR to the same name you can specify more rr
        # inside the rr.
            
        rr => # (optional) Single hash or an array of hashes as below:
        {
          ttl => 'string',   # TTL of RR (optional)
          class => 'string', # Class of RR (optional)
          type => 'string',  # Type of RR
          rdata => 'string', # Rdata of RR
        }
      }
    }
  };

=item $client->ReadZoneRr($input, sub { my ($call, $response) = @_; })

Return zone resource records specified or all zone resource records for a zone
file.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)

      rr => # (optional) Single hash or an array of hashes as below:
      {
        name => 'string'    # Name of RR
      }
    }
  };

  $response = {
    zone => # (optional) Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file
      software => 'string', # Software related to the zone file (optional)
      rr => # (optional) Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of RR
        ttl => 'string',    # TTL of RR (optional)
        class => 'string',  # Class of RR (optional)
        type => 'string',   # Type of RR
        rdata => 'string',  # Rdata of RR
      }
    }
  };

=item $client->UpdateZoneRr($input, sub { my ($call) = @_; })

Update a zone resource record, this does not remove other zone resource records.
Returns an error if it failed to update the zone resource record otherwise there
is no reponse.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)

      rr => # Single hash or an array of hashes as below:
      {
        name => 'string',   # Name of RR
        ttl => 'string',    # TTL of RR (optional)
        class => 'string',  # Class of RR (optional)
        type => 'string',   # Type of RR
        rdata => 'string',  # Rdata of RR

        # If you wish to add more RR to the same name you can specify more rr
        # inside the rr.
            
        rr => # (optional) Single hash or an array of hashes as below:
        {
          ttl => 'string',   # TTL of RR (optional)
          class => 'string', # Class of RR (optional)
          type => 'string',  # Type of RR
          rdata => 'string', # Rdata of RR
        }
      }
    }
  };

=item $client->DeleteZoneRr($input, sub { my ($call) = @_; })

Delete a zone resource records, returns an error if it failed to delete the zone
resource record otherwise there is no reponse.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      file => 'string',     # Full path to zone file or relative path when used
                            # with software
      software => 'string', # Software to create zone file in, must be used if
                            # file is relative path (optional)

      rr => # Single hash or an array of hashes as below:
      {
        name => 'string'    # Name of RR
      }
    }
  };

=back

=head1 COMMANDS

=over 4

=item zones

List existing zones and related software.

=item zone create [--software <software>] <zone name> <local zone file>

Create a new zone with the content of a local zone file.

=item zone read [--software <software>] <zone names ... >

Read zones and display content.

=item zone update [--software <software>] <zone name> <local zone file>

Update a existing zone with the content of a local zone file.

=item zone delete [--software <software>] <zone name>

Delete the specified zone.

=item option create [--software <software>] <zone name> <option name> <option values ... >

Create a new zone option in the an existing zone.

=item option read [--software <software>] <zone name> [option name]

Read and display the specified option, or all if not given, from the zone.

=item option update [--software <software>] <zone name> <option name> <option values ... >

Update an existing option in a zone.

=item option delete [--software <software>] <zone name> <option name>

Delete the specified option from a zone.

=item rr create [--software <software>] [--ttl <ttl>] [--class <class>] <zone name> <rr name> <rr type> <rr data ... >

Create a new resource record in an existing zone.

=item rr read [--software <software>] <zone name> [rr name]

Read and display the specified resource record, or all if not given, from the zone.

=item rr update [--software <software>] [--ttl <ttl>] [--class <class>] <zone name> <rr name> <rr type> <rr data ... >

Update an existing resource record in a zone.

=item rr delete [--software <software>] <zone name> <rr name>

Delete the specified resource record from a zone.

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-dns/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::DNS

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-dns/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Plugin::DNS
