package Lim::Plugin::OpenDNSSEC;

use common::sense;

use base qw(Lim::Component);

=encoding utf8

=head1 NAME

Lim::Plugin::OpenDNSSEC - OpenDNSSEC management plugin for Lim

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

  use Lim::Plugin::OpenDNSSEC;

  # Create a Server object
  $server = Lim::Plugin::OpenDNSSEC->Server;

  # Create a Client object
  $client = Lim::Plugin::OpenDNSSEC->Client;

  # Create a CLI object
  $cli = Lim::Plugin::OpenDNSSEC->CLI;

=head1 DESCRIPTION

This plugin lets you manage a OpenDNSSEC installation via Lim.

=head1 METHODS

=over 4

=item $plugin_name = Lim::Plugin::OpenDNSSEC->Name

Returns the plugin's name.

=cut

sub Name {
    'OpenDNSSEC';
}

=item $plugin_description = Lim::Plugin::OpenDNSSEC->Description

Returns the plugin's description.

=cut

sub Description {
    'This plugin lets you manage a OpenDNSSEC installation via Lim.';
}

=item $call_hash_ref = Lim::Plugin::OpenDNSSEC->Calls

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
        # Calls for config files: conf.xml kasp.xml zonelist.xml zonefetch.xml addns.xml
        #
        ReadConfigs => {
            out => {
                file => {
                    name => 'string',
                    write => 'integer',
                    read => 'integer'
                }
            }
        },
        CreateConfig => {
            uri_map => [
                'file.name=.+'
            ],
            in => {
                file => {
                    '' => 'required',
                    name => 'string',
                    content => 'string'
                }
            }
        },
        ReadConfig => {
            uri_map => [
                'file.name=.+'
            ],
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
            uri_map => [
                'file.name=.+'
            ],
            in => {
                file => {
                    '' => 'required',
                    name => 'string',
                    content => 'string'
                }
            }
        },
        DeleteConfig => {
            uri_map => [
                'file.name=.+'
            ],
            in => {
                file => {
                    '' => 'required',
                    name => 'string'
                }
            }
        },
        #
        # Calls for ods-control
        #
        UpdateControl => {
            uri_map => [
                'start/program.name=\w+ => UpdateControlStart',
                'stop/program.name=\w+ => UpdateControlStop'
            ]
        },
        UpdateControlStart => {
            uri_map => [
                'program.name=\w+'
            ],
            in => {
                program => {
                    name => 'string'
                }
            }
        },
        UpdateControlStop => {
            uri_map => [
                'program.name=\w+'
            ],
            in => {
                program => {
                    name => 'string'
                }
            }
        },
        #
        # Redirect calls for (Create|Read|Update|Delete)Enforcer*
        #
        CreateEnforcer => {
            uri_map => [
                'setup => CreateEnforcerSetup',
                'zone/zone.name=[\w\.]+ => CreateEnforcerZone',
                'key/import/key.zone=[\w\.]+ => CreateEnforcerKeyImport',
                'database/backup => CreateEnforcerDatabaseBackup'
            ]
        },
        ReadEnforcer => {
            uri_map => [
                'zones => ReadEnforcerZoneList',
                'repositories => ReadEnforcerRepositoryList',
                'policies => ReadEnforcerPolicyList',
                'policy/policy.name=\w+/export => ReadEnforcerPolicyExport',
                'keys => ReadEnforcerKeyList',
                'zone/zone.name=[\w\.]+/keys => ReadEnforcerKeyList',
                'key => ReadEnforcerKeyExport',
                'zone/zone.name=[\w\.]+/key => ReadEnforcerKeyExport',
                'backups => ReadEnforcerBackupList',
                'rollovers => ReadEnforcerRolloverList',
                'zonelist => ReadEnforcerZonelistExport'
            ]
        },
        UpdateEnforcer => {
            uri_map => [
                'update => UpdateEnforcerUpdate',
                'update/update.section=\w+ => UpdateEnforcerUpdate',
                'zone/zone.name=[\w\.]+/rollover => UpdateEnforcerKeyRollover',
                'zone/zone.name=[\w\.]+/key/zone.keytype=\w+/rollover => UpdateEnforcerKeyRollover',
                'policy/policy.name=[\w\.]+/rollover => UpdateEnforcerKeyRollover',
                'policy/policy.name=[\w\.]+/key/zone.keytype=\w+/rollover => UpdateEnforcerKeyRollover',
                'zone/zone.name=[\w\.]+/key/ksk/retire => UpdateEnforcerKeyKskRetire',
                'zone/zone.name=[\w\.]+/key/zone.cka_id=\w+/retire => UpdateEnforcerKeyKskRetire',
                'zone/zone.name=[\w\.]+/key/dsseen => UpdateEnforcerKeyDsSeen',
                'zone/zone.name=[\w\.]+/key/zone.cka_id=\w+/dsseen => UpdateEnforcerKeyDsSeen',
                'backup/prepare => UpdateEnforcerBackupPrepare',
                'repository/repository.name=\w+/backup/prepare => UpdateEnforcerBackupPrepare',
                'backup/commit => UpdateEnforcerBackupCommit',
                'repository/repository.name=\w+backup/commit => UpdateEnforcerBackupCommit',
                'backup/rollback => UpdateEnforcerBackupRollback',
                'repository/repository.name=\w+backup/rollback => UpdateEnforcerBackupRollback',
                'backup/done => UpdateEnforcerBackupDone',
                'repository/repository.name=\w+backup/done => UpdateEnforcerBackupDone'
            ]
        },
        DeleteEnforcer => {
            uri_map => [
                'zones => DeleteEnforcerZone zone.all=1',
                'zone/zone.name=[\w\.]+ => DeleteEnforcerZone',
                'policies/purge => DeleteEnforcerPolicyPurge',
                'zone/zone.name=[\w\.]+/purge => DeleteEnforcerKeyPurge',
                'policy/policy.name=[\w\.]+/purge => DeleteEnforcerKeyPurge'
            ]
        },
        #
        # Call for ods-ksmutil/ods-enforcer setup
        #
        CreateEnforcerSetup => {
        },
        #
        # Call for ods-ksmutil/ods-enforcer update *
        #
        UpdateEnforcerUpdate => {
            in => {
                update => {
                    section => 'string'
                }
            }
        },
        #
        # Call for ods-ksmutil/ods-enforcer zone *
        #
        CreateEnforcerZone => {
            in => {
                zone => {
                    '' => 'required',
                    name => 'string',
                    policy => 'string',
                    signerconf => 'string',
                    input => 'string',
                    output => 'string',
                    no_xml => 'bool optional'
                }
            }
        },
        ReadEnforcerZoneList => {
            out => {
                zone => {
                    name => 'string',
                    policy => 'string'
                }
            }
        },
        DeleteEnforcerZone => {
            in => {
                zone => {
                    '' => 'required',
                    all => 'bool optional',
                    name => 'string optional',
                    no_xml => 'bool optional'
                },
            }
        },
        #
        # Call for ods-ksmutil/ods-enforcer repository *
        #
        ReadEnforcerRepositoryList => {
            out => {
                repository => {
                    name => 'string',
                    capacity => 'integer',
                    require_backup => 'bool'
                }
            }
        },
        #
        # Calls for ods-ksmutil/ods-enforcer policy *
        #
        ReadEnforcerPolicyList => {
            out => {
                policy => {
                    name => 'string',
                    description => 'string'
                }
            }
        },
        ReadEnforcerPolicyExport => {
            in => {
                policy => {
                    name => 'string'
                }
            },
            out => {
                kasp => 'string optional',
                policy => {
                    name => 'string',
                    kasp => 'string'
                }
            }
        },
        DeleteEnforcerPolicyPurge => {
        },
        #
        # Calls for ods-ksmutil/ods-enforcer key *
        #
        ReadEnforcerKeyList => {
            in => {
                verbose => 'bool optional',
                zone => {
                    name => 'string'
                }
            },
            out => {
                zone => {
                    name => 'string',
                    key => {
                        '' => 'required',
                        type => 'string',
                        state => 'string',
                        next_transaction => 'string',
                        cka_id => 'string optional',
                        repository => 'string optional',
                        keytag => 'string optional'
                    }
                }
            }
        },
        ReadEnforcerKeyExport => {
            in => {
                keystate => 'string optional',
                keytype => 'string optional',
                ds => 'bool optional',
                zone => {
                    name => 'string',
                    keystate => 'string optional',
                    keytype => 'string optional',
                    ds => 'bool optional'
                }
            },
            out => {
                rr => {
                    name => 'string',
                    ttl => 'integer',
                    class => 'string',
                    type => 'string',
                    rdata => 'string'
                }
            }
        },
        CreateEnforcerKeyImport => {
            in => {
                key => {
                    '' => 'required',
                    zone => 'string',
                    cka_id => 'string',
                    repository => 'string',
                    bits => 'integer',
                    algorithm => 'integer',
                    keystate => 'string',
                    keytype => 'string',
                    time => 'string',
                    retire => 'string optional'
                }
            }
        },
        UpdateEnforcerKeyRollover => {
            in => {
                zone => {
                    name => 'string',
                    keytype => 'string optional'
                },
                policy => {
                    name => 'string',
                    keytype => 'string optional'
                }
            }
        },
        DeleteEnforcerKeyPurge => {
            in => {
                zone => {
                    name => 'string'
                },
                policy => {
                    name => 'string'
                }
            },
            out => {
                key => {
                    cka_id => 'string'
                }
            }
        },
        CreateEnforcerKeyGenerate => {
            in => {
                policy => {
                    '' => 'required',
                    name => 'string',
                    interval => 'string'
                }
            },
            out => {
                key => {
                    cka_id => 'string',
                    repository => 'string',
                    bits => 'integer',
                    algorithm => 'integer',
                    keytype => 'string'
                }
            }
        },
        UpdateEnforcerKeyKskRetire => {
            in => {
                zone => {
                    '' => 'required',
                    name => 'string',
                    cka_id => 'string optional',
                    keytag => 'string optional'
                }
            }
        },
        UpdateEnforcerKeyDsSeen => {
            in => {
                zone => {
                    '' => 'required',
                    name => 'string',
                    cka_id => 'string optional',
                    keytag => 'string optional',
                    no_retire => 'bool optional'
                }
            }
        },
        #
        # Calls for ods-ksmutil/ods-enforcer backup *
        #
        UpdateEnforcerBackupPrepare => {
            in => {
                repository => {
                    name => 'string'
                }
            }
        },
        UpdateEnforcerBackupCommit => {
            in => {
                repository => {
                    name => 'string'
                }
            }
        },
        UpdateEnforcerBackupRollback => {
            in => {
                repository => {
                    name => 'string'
                }
            }
        },
        UpdateEnforcerBackupDone => {
            in => {
                repository => {
                    name => 'string'
                }
            }
        },
        ReadEnforcerBackupList => {
            in => {
                repository => {
                    name => 'string'
                }
            },
            out => {
                repository => {
                    name => 'string',
                    backup => {
                        date => 'string'
                    },
                    unbacked_up_keys => 'bool optional',
                    prepared_keys => 'bool optional'
                }
            }
        },
        #
        # Call for ods-ksmutil/ods-enforcer rollover list
        #
        ReadEnforcerRolloverList => {
            in => {
                zone => {
                    name => 'string'
                }
            },
            out => {
                zone => {
                    name => 'string',
                    keytype => 'string',
                    rollover_expected => 'string'
                }
            }
        },
        #
        # Call for ods-ksmutil/ods-enforcer database backup
        #
        CreateEnforcerDatabaseBackup => {
        },
        #
        # Call for ods-ksmutil/ods-enforcer zonelist export
        #
        ReadEnforcerZonelistExport => {
            out => {
                zonelist => 'string'
            }
        },
        #
        # Redirect calls for (Create|Read|Update|Delete)Signer*
        #
        ReadSigner => {
            uri_map => [
                'zones => ReadSignerZones',
                'zone/zone.name=[\w\.]+ => ReadSignerZones',
                'queue => ReadSignerQueue',
                'running => ReadSignerRunning'
            ]
        },
        UpdateSigner => {
            uri_map => [
                'sign => UpdateSignerSign',
                'sign/zone.name=[\w\.]+ => UpdateSignerSign',
                'clear/zone.name=[\w\.]+ => UpdateSignerClear',
                'flush => UpdateSignerFlush',
                'update => UpdateSignerUpdate',
                'update/zone.name=[\w\.]+ => UpdateSignerUpdate',
                'reload => UpdateSignerReload',
                'verbosity/verbosity=\d+ => UpdateSignerVerbosity'
            ]
        },
        #
        # Calls for ods-signer *
        #
        ReadSignerZones => {
            out => {
                zone => {
                    name => 'string'
                }
            }
        },
        UpdateSignerSign => {
            in => {
                zone => {
                    name => 'string'
                }
            }
        },
        UpdateSignerClear => {
            in => {
                zone => {
                    '' => 'required',
                    name => 'string'
                }
            }
        },
        ReadSignerQueue => {
            out => {
                now => 'string optional',
                task => {
                    type => 'string',
                    date => 'string',
                    zone => 'string'
                }
            }
        },
        UpdateSignerFlush => {
        },
        UpdateSignerUpdate => {
            in => {
                zone => {
                    name => 'string'
                }
            }
        },
        ReadSignerRunning => {
            out => {
                running => 'bool'
            }
        },
        UpdateSignerReload => {
        },
        UpdateSignerVerbosity => {
            in => {
                verbosity => 'integer'
            }
        },
        #
        # Redirect calls for (Create|Read|Update|Delete)Hsm*
        #
        CreateHsm => {
            'generate => CreateHsmGenerate',
            'dnskey => CreateHsmDnskey'
        },
        ReadHsm => {
            'keys => ReadHsmList',
            'repository/repository.name=\w+/keys => ReadHsmList',
            'repository/repository.name=\w+/test => ReadHsmTest',
            'info => ReadHsmInfo'
        },
        DeleteHsm => {
            'key/key.id=\w+ => DeleteHsmRemove',
            'repository/repository.name=\w+/purge => DeleteHsmPurge'
        },
        #
        # Calls for ods-hsmutil *
        #
        ReadHsmList => {
            in => {
                repository => {
                    name => 'string'
                }
            },
            out => {
                key => {
                    repository => 'string',
                    id => 'string',
                    keytype => 'string',
                    keysize => 'integer'
                }
            }
        },
        CreateHsmGenerate => {
            in => {
                key => {
                    '' => 'required',
                    repository => 'string',
                    keysize => 'integer'
                }
            },
            out => {
                key => {
                    repository => 'string',
                    id => 'string',
                    keysize => 'integer',
                    keytype => 'string'
                }
            }
        },
        DeleteHsmRemove => {
            in => {
                key => {
                    '' => 'required',
                    id => 'string'
                }
            }
        },
        DeleteHsmPurge => {
            in => {
                repository => {
                    '' => 'required',
                    name => 'string'
                }
            }
        },
        CreateHsmDnskey => {
            in => {
                key => {
                    '' => 'required',
                    id => 'string',
                    name => 'string'
                }
            },
            out => {
                key => {
                    id => 'string',
                    name => 'string',
                    rr => 'string'
                }
            }
        },
        ReadHsmTest => {
            in => {
                repository => {
                    '' => 'required',
                    name => 'string'
                }
            }
        },
        ReadHsmInfo => {
            out => {
                repository => {
                    name => 'string',
                    module => 'string',
                    slot => 'integer',
                    token_label => 'string',
                    manufacturer => 'string',
                    model => 'string',
                    serial => 'string'
                }
            }
        }
    };
}

=item $command_hash_ref = Lim::Plugin::OpenDNSSEC->Commands

Returns a hash reference to the CLI commands that can be made by this plugin.

See COMMANDS for list of commands and arguments.

=cut

sub Commands {
    {
        version => [ 'Show version of the plugin and OpenDNSSEC' ],
        configs => [ 'List configuration files' ],
        config => {
            view => [ '<file>', 'Display the content of a configuration file' ],
            edit => [ '<file>', 'Edit a configuration file' ]
        },
        start => {
            enforcer => [ 'Start Enforcer' ],
            signer => [ 'Start Signer' ]
        },
        stop => {
            enforcer => [ 'Stop Enforcer' ],
            signer => [ 'Stop Signer' ]
        },
        setup => [ 'Import configuration into the database and delete existing information' ],
        update => {
            all => [ 'Update datebase with all configurations' ],
            kasp => [ 'Update database with the KASP configuration' ],
            zonelist => [ 'Update database with the zonelist configuration' ],
            conf => [ 'Update database with the configuration' ]
        },
        zone => {
            add => [ '[--no-xml] <zone> <policy> <signconf> <input file> <output file>', 'Add a zone' ],
            list => [ 'List zones' ],
            delete => [ '[--no-xml] <zone>', 'Delete a zone' ]
        },
        repository => {
            list => [ 'List repositories' ]
        },
        policy => {
            list => [ 'List policies' ],
            export => [ '<policies ... >', 'Export the specified policies and display them' ]
        },
        key => {
            list => [ '[--verbose] [<zones ... >]', 'List keys for specified zones or all keys' ],
            export => [ '[--keytype <key type>] [--keystate <key state>] [--ds] [<zones ... >]', 'Export keys for specified zones or all keys as resource records' ],
            import => [ '--cka_id <CKA_ID> --repository <repository> --bits <bits> --algorithm <algorithm> --keystate <key state> --keytype <key type> --time <time> [--retire-time <retire_time>] --zone <zone>', 'Import a key into a zone' ],
            rollover => {
                zone => [ '[--keytype <key type>] <zones ... >', 'Do a key rollover for the specified zones' ],
                policy => [ '[--keytype <key type>] <policies ... >', 'Do a key rollover for the specified policies' ]
            },
            purge => {
                zone => [ '[--keytype <key type>] <zones ... >', 'Purge keys from the specified zones' ],
                policy => [ '[--keytype <key type>] <policies ... >', 'Purge keys from the specified policies' ]
            },
            generate => [ '<policy> <interval>', 'Generate keys for the specified policy and interval' ],
            ksk => {
                retire => [ '[--cka_id <CKA_ID>] [--keytag <key tag>] <zone>', 'Retire the KSK for the specified zone' ]
            },
            ds => {
                seen => [ '[--cka_id <CKA_ID>] [--keytag <key tag>] [--no-retrie] <zone>', 'Mark the DS seen for the specified zone' ]
            }
        },
        backup => {
            prepare => [ '[<repositories ... >]', 'Prepare for backup on specified repositories or all' ],
            commit => [ '[<repositories ... >]', 'Commit the backup on specified repositories or all' ],
            rollback => [ '[<repositories ... >]', 'Rollback the backup on specified repositories or all' ],
            done => [ '[<repositories ... >]', 'Notify OpenDNSSEC that a backup has been done on specified repositories or all' ],
            list => [ '[<repositories ... >]', 'List backup for the specified repositories or all' ]
        },
        rollover => {
            list => [ '[<zones ... >]', 'List schedualed rollover for specified zones or all' ]
        },
        database => {
            backup => [ 'Create a database backup' ]
        },
        zonelist => {
            export => [ 'Export the zonelist and display it' ]
        },
        signer => {
            zones => [ 'List zones' ],
            sign => [ '[<zones ... >]', 'Schedual specified zones or all for signing' ],
            clear => [ '<zones ... >', 'Clear the internal state for the specified zones' ],
            queue => [ 'Display the task queue' ],
            flush => [ 'Flush all tasks on queue, executing them immediately' ],
            update => [ '[<zones ... >]', 'Issue an update for the specified zones or all' ],
            running => [ 'Check if the Signer is running' ],
            reload => [ 'Tell the Signer to reload' ],
            verbosity => [ '<verbosity>', 'Change the verbosity' ]
        },
        hsm => {
            list => [ '[<repositories ... >]', 'List repositories information for the specified one or all' ],
            generate => [ '<repository> <key size>', 'Generate a key in the specified repository' ],
            remove => [ '<key ids ... >', 'Remove the specified keys' ],
            purge => [ '<repositories ... >', 'Purge the specified repositories' ],
            dnskey => [ '<key id> <owner name>', 'Create a DNSKEY' ],
            test => [ '<repositories ... >', 'Test the specified repositories' ],
            info => [ 'Display HSM information' ]
        }
    };
}

=back

=head1 CALLS

See L<Lim::Component::Client> on how calls and callback functions should be
used.

=over 4

=item $client->ReadVersion(sub { my ($call) = @_; })

Get the version of the plugin and version of OpenDNSSEC found.

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
      name => string,   # Full path file name
      read => integer,  # True if readable
      write => integer, # True if writable
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
      content => string, # ...
      name => string,    # ...
    }
  };

=item $client->DeleteConfig($input, sub { my ($call) = @_; })

Delete a config file, returns an error if it failed to delete the config file
otherwise there is no reponse.

  $input = {
    file => # Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->UpdateControlStart($input, sub { my ($call) = @_; })

Start the specified OpenDNSSEC program (enforcer or signer) or all of them.
Returns an error if it failed to start otherwise there is no response.

  $input = {
    program => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->UpdateControlStop($input, sub { my ($call) = @_; })

Stop the specified OpenDNSSEC program (enforcer or signer) or all of them.
Returns an error if it failed to stop otherwise there is no response.

  $input = {
    program => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->CreateEnforcerSetup(sub { my ($call) = @_; })

Setup the Enforcer database by importing configurations, this will delete any
existing information. Returns an error if it failed to setup otherwise there is
no response.

=item $client->UpdateEnforcerUpdate($input, sub { my ($call) = @_; })

Update the specified configuration section (conf, kasp or zonelist) or all of
them. Returns an error if it failed to update otherwise there is no response.

  $input = {
    update => # (optional) Single hash or an array of hashes as below:
    {
      section => string, # ...
    }
  };

=item $client->CreateEnforcerZone($input, sub { my ($call) = @_; })

Add a new zone into OpenDNSSEC, returns an error if it failed to add the zone
otherwise there is no response.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      input => string,      # ...
      name => string,       # ...
      no_xml => bool,       # ... (optional)
      output => string,     # ...
      policy => string,     # ...
      signerconf => string, # ...
    }
  };

=item $client->ReadEnforcerZoneList(sub { my ($call) = @_; })

Get a list of zones and related policies.

  $response = {
    zone => # Single hash or an array of hashes as below:
    {
      name => string,   # ...
      policy => string, # ...
    }
  };

=item $client->DeleteEnforcerZone($input, sub { my ($call) = @_; })

Remove a zone from OpenDNSSEC, returns an error if it failed to remove the zone
otherwise there is no response.

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      all => bool,    # ... (optional)
      name => string, # ... (optional)
      no_xml => bool, # ... (optional)
    }
  };

=item $client->ReadEnforcerRepositoryList(sub { my ($call) = @_; })

Get a list of available repositories.

  $response = {
    repository => # Single hash or an array of hashes as below:
    {
      capacity => integer,    # ...
      name => string,         # ...
      require_backup => bool, # ...
    }
  };

=item $client->ReadEnforcerPolicyList(sub { my ($call) = @_; })

Get a list of available policies.

  $response = {
    policy => # Single hash or an array of hashes as below:
    {
      description => string, # ...
      name => string,        # ...
    }
  };

=item $client->ReadEnforcerPolicyExport($input, sub { my ($call) = @_; })

Export the specified policy or all. Returns an error if it failed to export.

  $input = {
    policy => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

  $response = {
    kasp => string, # ... (optional)
    policy => # Single hash or an array of hashes as below:
    {
      kasp => string, # ...
      name => string, # ...
    }
  };

=item $client->DeleteEnforcerPolicyPurge(sub { my ($call) = @_; })

Undocumented

=item $client->ReadEnforcerKeyList($input, sub { my ($call) = @_; })

Get a list of keys for the specified zone or all. Returns an error if it failed
to get the list of keys.

  $input = {
    verbose => bool, # ... (optional)
    zone => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

  $response = {
    zone => # Single hash or an array of hashes as below:
    {
      name => string, # ...
      key => # Single hash or an array of hashes as below:
      {
        cka_id => string,           # ... (optional)
        keytag => string,           # ... (optional)
        next_transaction => string, # ...
        repository => string,       # ... (optional)
        state => string,            # ...
        type => string,             # ...
      }
    }
  };

=item $client->ReadEnforcerKeyExport($input, sub { my ($call) = @_; })

Export the specified keys

  $input = {
    ds => bool,         # ... (optional)
    keystate => string, # ... (optional)
    keytype => string,  # ... (optional)
    zone => # (optional) Single hash or an array of hashes as below:
    {
      ds => bool,         # ... (optional)
      keystate => string, # ... (optional)
      keytype => string,  # ... (optional)
      name => string,     # ...
    }
  };

  $response = {
    rr => # Single hash or an array of hashes as below:
    {
      class => string, # ...
      name => string,  # ...
      rdata => string, # ...
      ttl => integer,  # ...
      type => string,  # ...
    }
  };

=item $client->CreateEnforcerKeyImport($input, sub { my ($call) = @_; })

...

  $input = {
    key => # Single hash or an array of hashes as below:
    {
      algorithm => integer, # ...
      bits => integer,      # ...
      cka_id => string,     # ...
      keystate => string,   # ...
      keytype => string,    # ...
      repository => string, # ...
      retire => string,     # ... (optional)
      time => string,       # ...
      zone => string,       # ...
    }
  };

=item $client->UpdateEnforcerKeyRollover($input, sub { my ($call) = @_; })

...

  $input = {
    policy => # (optional) Single hash or an array of hashes as below:
    {
      keytype => string, # ... (optional)
      name => string,    # ...
    },
    zone => # (optional) Single hash or an array of hashes as below:
    {
      keytype => string, # ... (optional)
      name => string,    # ...
    }
  };

=item $client->DeleteEnforcerKeyPurge($input, sub { my ($call) = @_; })

...

  $input = {
    policy => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    },
    zone => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

  $response = {
    key => # Single hash or an array of hashes as below:
    {
      cka_id => string, # ...
    }
  };

=item $client->CreateEnforcerKeyGenerate($input, sub { my ($call) = @_; })

...

  $input = {
    policy => # Single hash or an array of hashes as below:
    {
      interval => string, # ...
      name => string,     # ...
    }
  };

  $response = {
    key => # Single hash or an array of hashes as below:
    {
      algorithm => integer, # ...
      bits => integer,      # ...
      cka_id => string,     # ...
      keytype => string,    # ...
      repository => string, # ...
    }
  };

=item $client->UpdateEnforcerKeyKskRetire($input, sub { my ($call) = @_; })

...

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      cka_id => string, # ... (optional)
      keytag => string, # ... (optional)
      name => string,   # ...
    }
  };

=item $client->UpdateEnforcerKeyDsSeen($input, sub { my ($call) = @_; })

...

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      cka_id => string,  # ... (optional)
      keytag => string,  # ... (optional)
      name => string,    # ...
      no_retire => bool, # ... (optional)
    }
  };

=item $client->UpdateEnforcerBackupPrepare($input, sub { my ($call) = @_; })

...

  $input = {
    repository => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->UpdateEnforcerBackupCommit($input, sub { my ($call) = @_; })

...

  $input = {
    repository => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->UpdateEnforcerBackupRollback($input, sub { my ($call) = @_; })

...

  $input = {
    repository => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->UpdateEnforcerBackupDone($input, sub { my ($call) = @_; })

...

  $input = {
    repository => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->ReadEnforcerBackupList($input, sub { my ($call) = @_; })

...

  $input = {
    repository => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

  $response = {
    repository => # Single hash or an array of hashes as below:
    {
      name => string,           # ...
      prepared_keys => bool,    # ... (optional)
      unbacked_up_keys => bool, # ... (optional)
      backup => # Single hash or an array of hashes as below:
      {
        date => string, # ...
      }
    }
  };

=item $client->ReadEnforcerRolloverList($input, sub { my ($call) = @_; })

...

  $input = {
    zone => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

  $response = {
    zone => # Single hash or an array of hashes as below:
    {
      keytype => string,           # ...
      name => string,              # ...
      rollover_expected => string, # ...
    }
  };

=item $client->CreateEnforcerDatabaseBackup(sub { my ($call) = @_; })

...

=item $client->ReadEnforcerZonelistExport(sub { my ($call) = @_; })

...

  $response = {
    zonelist => string, # ...
  };

=item $client->ReadSignerZones(sub { my ($call) = @_; })

...

  $response = {
    zone => # Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->UpdateSignerSign($input, sub { my ($call) = @_; })

...

  $input = {
    zone => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->UpdateSignerClear($input, sub { my ($call) = @_; })

...

  $input = {
    zone => # Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->ReadSignerQueue(sub { my ($call) = @_; })

...

  $response = {
    now => string, # ... (optional)
    task => # Single hash or an array of hashes as below:
    {
      date => string, # ...
      type => string, # ...
      zone => string, # ...
    }
  };

=item $client->UpdateSignerFlush(sub { my ($call) = @_; })

...

=item $client->UpdateSignerUpdate($input, sub { my ($call) = @_; })

...

  $input = {
    zone => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->ReadSignerRunning(sub { my ($call) = @_; })

...

  $response = {
    running => bool, # ...
  };

=item $client->UpdateSignerReload(sub { my ($call) = @_; })

...

=item $client->UpdateSignerVerbosity($input, sub { my ($call) = @_; })

...

  $input = {
    verbosity => integer, # ...
  };

=item $client->ReadHsmList($input, sub { my ($call) = @_; })

...

  $input = {
    repository => # (optional) Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

  $response = {
    key => # Single hash or an array of hashes as below:
    {
      id => string,         # ...
      keysize => integer,   # ...
      keytype => string,    # ...
      repository => string, # ...
    }
  };

=item $client->CreateHsmGenerate($input, sub { my ($call) = @_; })

...

  $input = {
    key => # Single hash or an array of hashes as below:
    {
      keysize => integer,   # ...
      repository => string, # ...
    }
  };

  $response = {
    key => # Single hash or an array of hashes as below:
    {
      id => string,         # ...
      keysize => integer,   # ...
      keytype => string,    # ...
      repository => string, # ...
    }
  };

=item $client->DeleteHsmRemove($input, sub { my ($call) = @_; })

...

  $input = {
    key => # Single hash or an array of hashes as below:
    {
      id => string, # ...
    }
  };

=item $client->DeleteHsmPurge($input, sub { my ($call) = @_; })

...

  $input = {
    repository => # Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->CreateHsmDnskey($input, sub { my ($call) = @_; })

...

  $input = {
    key => # Single hash or an array of hashes as below:
    {
      id => string,   # ...
      name => string, # ...
    }
  };

  $response = {
    key => # Single hash or an array of hashes as below:
    {
      id => string,   # ...
      name => string, # ...
      rr => string,   # ...
    }
  };

=item $client->ReadHsmTest($input, sub { my ($call) = @_; })

...

  $input = {
    repository => # Single hash or an array of hashes as below:
    {
      name => string, # ...
    }
  };

=item $client->ReadHsmInfo(sub { my ($call) = @_; })

...

  $response = {
    repository => # Single hash or an array of hashes as below:
    {
      manufacturer => string, # ...
      model => string,        # ...
      module => string,       # ...
      name => string,         # ...
      serial => string,       # ...
      slot => integer,        # ...
      token_label => string,  # ...
    }
  };

=back

=head1 COMMANDS

=over 4

=item version

Show version of the plugin and OpenDNSSEC.

=item configs

List configuration files.

=item config view <file>

Display the content of a configuration file.

=item config edit <file>

Edit a configuration file.

=item start enforcer

Start Enforcer.

=item start signer

Start Signer.

=item stop enforcer

Stop Enforcer.

=item stop signer

Stop Signer.

=item setup

Import configuration into the database and delete existing information.

=item update all

Update datebase with all configurations.

=item update kasp

Update database with the KASP configuration.

=item update zonelist

Update database with the zonelist configuration.

=item update conf

Update database with the configuration.

=item zone add [--no-xml] <zone> <policy> <signconf> <input file> <output file>

Add a zone.

=item zone list

List zones.

=item zone delete [--no-xml] <zone>

Delete a zone.

=item repository list

List repositories.

=item policy list

List policies.

=item policy export <policies ... >

Export the specified policies and display them.

=item key list [--verbose] [<zones ... >]

List keys for specified zones or all keys.

=item key export [--keytype <key type>] [--keystate <key state>] [--ds] [<zones ... >]

Export keys for specified zones or all keys as resource records.

=item key import --cka_id <CKA_ID> --repository <repository> --bits <bits> --algorithm <algorithm> --keystate <key state> --keytype <key type> --time <time> [--retire-time <retire_time>] --zone <zone>

Import a key into a zone.

=item key rollover zone [--keytype <key type>] <zones ... >

Do a key rollover for the specified zones.

=item key rollover policy [--keytype <key type>] <policies ... >

Do a key rollover for the specified policies.

=item key purge zone [--keytype <key type>] <zones ... >

Purge keys from the specified zones.

=item key purge policy [--keytype <key type>] <policies ... >

Purge keys from the specified policies.

=item key generate <policy> <interval>

Generate keys for the specified policy and interval.

=item key ksk retire [--cka_id <CKA_ID>] [--keytag <key tag>] <zone>

Retire the KSK for the specified zone.

=item key ds seen [--cka_id <CKA_ID>] [--keytag <key tag>] [--no-retrie] <zone>

Mark the DS seen for the specified zone.

=item backup prepare [<repositories ... >]

Prepare for backup on specified repositories or all.

=item backup commit [<repositories ... >]

Commit the backup on specified repositories or all.

=item backup rollback [<repositories ... >]

Rollback the backup on specified repositories or all.

=item backup done [<repositories ... >]

Notify OpenDNSSEC that a backup has been done on specified repositories or all.

=item backup list [<repositories ... >]

List backup for the specified repositories or all.

=item rollover list [<zones ... >]

List schedualed rollover for specified zones or all.

=item database backup

Create a database backup.

=item zonelist export

Export the zonelist and display it.

=item signer zones

List zones.

=item signer sign [<zones ... >]

Schedual specified zones or all for signing.

=item signer clear <zones ... >

Clear the internal state for the specified zones.

=item signer queue

Display the task queue.

=item signer flush

Flush all tasks on queue, executing them immediately.

=item signer update [<zones ... >]

Issue an update for the specified zones or all.

=item signer running

Check if the Signer is running.

=item signer reload

Tell the Signer to reload.

=item signer verbosity <verbosity>

Change the verbosity.

=item hsm list [<repositories ... >]

List repositories information for the specified one or all.

=item hsm generate <repository> <key size>

Generate a key in the specified repository.

=item hsm remove <key ids ... >

Remove the specified keys.

=item hsm purge <repositories ... >

Purge the specified repositories.

=item hsm dnskey <key id> <owner name>

Create a DNSKEY.

=item hsm test <repositories ... >

Test the specified repositories.

=item hsm info

Display HSM information.

=back

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim-plugin-opendnssec/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lim::Plugin::OpenDNSSEC

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim-plugin-opendnssec/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Plugin::OpenDNSSEC
