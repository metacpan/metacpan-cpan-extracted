package Lilith;

use 5.006;
use strict;
use warnings;
use POE qw(Wheel::FollowTail);
use JSON;
use Sys::Hostname;
use DBI;
use Digest::SHA qw(sha256_base64);
use File::ReadBackwards;
use Sys::Syslog;
use YAML::PP;
use File::Slurp;

=head1 NAME

Lilith - Work with Suricata/Sagan EVE logs and PostgreSQL.

=head1 VERSION

Version 0.6.0

=cut

our $VERSION = '0.6.0';

=head1 SYNOPSIS

    my $toml_raw = read_file($config_file) or die 'Failed to read "' . $config_file . '"';
    my ( $toml, $err ) = from_toml($toml_raw);
    unless ($toml) {
        die "Error parsing toml,'" . $config_file . "'" . $err;
    }

     my $lilith=Lilith->new(
                            dsn=>$toml->{dsn},
                            sagan=>$toml->{sagan},
                            suricata=>$toml->{suricata},
                            user=>$toml->{user},
                            pass=>$toml->{pass},
                           );


     $lilith->create_table(
                           dsn=>$toml->{dsn},
                           sagan=>$toml->{sagan},
                           suricata=>$toml->{suricata},
                           user=>$toml->{user},
                           pass=>$toml->{pass},
                          );

    my %files;
    my @toml_keys = keys( %{$toml} );
    my $int       = 0;
    while ( defined( $toml_keys[$int] ) ) {
        my $item = $toml_keys[$int];

        if ( ref( $toml->{$item} ) eq "HASH" ) {
                # add the file in question
                $files{$item} = $toml->{$item};
        }

        $int++;
    }

    $ilith->run(
                files=>\%files,
               );

=head1 FUNCTIONS

=head1 new

Initiates it.

    my $lilith=Lilith->run(
                           dsn=>$toml->{dsn},
                           sagan=>$toml->{sagan},
                           suricata=>$toml->{suricata},
                           user=>$toml->{user},
                           pass=>$toml->{pass},
                          );

The args taken by this are as below.

    - dsn :: The DSN to use for with DBI.

    - sagan :: Name of the table for Sagan alerts.
      Default :: sagan_alerts

    - suricata :: Name of the table for Suricata alerts.
      Default :: suricata_alerts

    - cape :: Name of the table for CAPEv2 alerts.
      Default :: cape_alerts

    - user :: Name for use with DBI for the DB connection.
      Default :: lilith

    - pass :: pass for use with DBI for the DB connection.
      Default :: undef

    - sid_ignore :: Array of SIDs to ignore for Suricata and Sagan
                    for the extend.
      Default :: undef

    - class_ignore :: Array of classes to ignore for the
                      extend for Suricata and Sagan
      Default :: undef

    - suricata_sid_ignore :: Array of SIDs to ignore for Suricata
                             for the extend.
      Default :: undef

    - suricata_class_ignore :: Array of classes to ignore for the
                               extend for Suricata.
      Default :: undef

    - sagan_sid_ignore :: Array of SIDs to ignore for Sagan for
                          the extend.
      Default :: undef

    - sagan_class_ignore :: Array of classes to ignore for the
                            extend for Sagan.
      Default :: undef

=cut

sub new {
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{dsn} ) ) {
		die('"dsn" is not defined');
	}

	if ( !defined( $opts{user} ) ) {
		$opts{user} = 'lilith';
	}

	if ( !defined( $opts{sagan} ) ) {
		$opts{sagan} = 'sagan_alerts';
	}

	if ( !defined( $opts{suricata} ) ) {
		$opts{suricata} = 'suricata_alerts';
	}

	if ( !defined( $opts{cape} ) ) {
		$opts{cape} = 'cape_alerts';
	}

	if ( !defined( $opts{sid_ignore} ) ) {
		my @empty_array;
		$opts{sid_ignore} = \@empty_array;
	}

	if ( !defined( $opts{class_ignore} ) ) {
		my @empty_array;
		$opts{class_ignore} = \@empty_array;
	}

	if ( !defined( $opts{suricata_sid_ignore} ) ) {
		my @empty_array;
		$opts{suricata_sid_ignore} = \@empty_array;
	}

	if ( !defined( $opts{suricata_class_ignore} ) ) {
		my @empty_array;
		$opts{suricata_class_ignore} = \@empty_array;
	}

	if ( !defined( $opts{sagan_sid_ignore} ) ) {
		my @empty_array;
		$opts{sagan_sid_ignore} = \@empty_array;
	}

	if ( !defined( $opts{sagan_class_ignore} ) ) {
		my @empty_array;
		$opts{sagan_class_ignore} = \@empty_array;
	}

	my $self = {
		sid_ignore            => $opts{sid_ignore},
		suricata_sid_ignore   => $opts{suricata_sid_ignore},
		sagan_sid_ignore      => $opts{sagan_sid_ignore},
		class_ignore          => $opts{class_ignore},
		suricata_class_ignore => $opts{suricata_class_ignore},
		sagan_class_ignore    => $opts{sagan_class_ignore},
		dsn                   => $opts{dsn},
		user                  => $opts{user},
		pass                  => $opts{pass},
		sagan                 => $opts{sagan},
		suricata              => $opts{suricata},
		cape                  => $opts{cape},
		debug                 => $opts{debug},
		class_map             => {
			'Not Suspicious Traffic'                                      => '!SusT',
			'Unknown Traffic'                                             => 'UnknownT',
			'Attempted Information Leak'                                  => '!IL',
			'Information Leak'                                            => 'IL',
			'Large Scale Information Leak'                                => 'LrgSclIL',
			'Attempted Denial of Service'                                 => 'ADoS',
			'Denial of Service'                                           => 'DoS',
			'Attempted User Privilege Gain'                               => 'AUPG',
			'Unsuccessful User Privilege Gain'                            => '!SucUsrPG',
			'Successful User Privilege Gain'                              => 'SucUsrPG',
			'Attempted Administrator Privilege Gain'                      => '!SucAdmPG',
			'Successful Administrator Privilege Gain'                     => 'SucAdmPG',
			'Decode of an RPC Query'                                      => 'DRPCQ',
			'Executable code was detected'                                => 'ExeCode',
			'A suspicious string was detected'                            => 'SusString',
			'A suspicious filename was detected'                          => 'SusFilename',
			'An attempted login using a suspicious username was detected' => '!LoginUser',
			'A system call was detected'                                  => 'Syscall',
			'A TCP connection was detected'                               => 'TCPconn',
			'A Network Trojan was detected'                               => 'NetTrojan',
			'A client was using an unusual port'                          => 'OddClntPrt',
			'Detection of a Network Scan'                                 => 'NetScan',
			'Detection of a Denial of Service Attack'                     => 'DOS',
			'Detection of a non-standard protocol or event'               => 'NS PoE',
			'Generic Protocol Command Decode'                             => 'GPCD',
			'access to a potentially vulnerable web application'          => 'PotVulWebApp',
			'Web Application Attack'                                      => 'WebAppAtk',
			'Misc activity'                                               => 'MiscActivity',
			'Misc Attack'                                                 => 'MiscAtk',
			'Generic ICMP event'                                          => 'GenICMP',
			'Inappropriate Content was Detected'                          => '!AppCont',
			'Potential Corporate Privacy Violation'                       => 'PotCorpPriVio',
			'Attempt to login by a default username and password'         => '!DefUserPass',
			'Targeted Malicious Activity was Detected'                    => 'TargetedMalAct',
			'Exploit Kit Activity Detected'                               => 'ExpKit',
			'Device Retrieving External IP Address Detected'              => 'RetrExtIP',
			'Domain Observed Used for C2 Detected'                        => 'C2domain',
			'Possibly Unwanted Program Detected'                          => 'PotUnwantedProg',
			'Successful Credential Theft Detected'                        => 'CredTheft',
			'Possible Social Engineering Attempted'                       => 'PosSocEng',
			'Crypto Currency Mining Activity Detected'                    => 'Mining',
			'Malware Command and Control Activity Detected'               => 'MalC2act',
			'Potentially Bad Traffic'                                     => 'PotBadTraf',
			'Unsuccessful Admin Privilege'                                => 'SucAdmPG',
			'Exploit Attempt'                                             => 'ExpAtmp',
			'Program Error'                                               => 'ProgErr',
			'Suspicious Command Execution'                                => 'SusProgExec',
			'Network event'                                               => 'NetEvent',
			'System event'                                                => 'SysEvent',
			'Configuration Change'                                        => 'ConfChg',
			'Spam'                                                        => 'Spam',
			'Attempted Access To File or Directory'                       => 'FoDAccAtmp',
			'Suspicious Traffic'                                          => 'SusT',
			'Configuration Error'                                         => 'ConfErr',
			'Hardware Event'                                              => 'HWevent',
			''                                                            => 'blankC',
		},
		lc_class_map     => {},
		rev_class_map    => {},
		lc_rev_class_map => {},
		snmp_class_map   => {},
	};
	bless $self;

	my @keys = keys( %{ $self->{class_map} } );
	foreach my $key (@keys) {
		my $lc_key = lc($key);
		$self->{lc_class_map}{$lc_key}                              = $self->{class_map}{$key};
		$self->{rev_class_map}{ $self->{class_map}{$key} }          = $key;
		$self->{lc_rev_class_map}{ lc( $self->{class_map}{$key} ) } = $key;
		$self->{snmp_class_map}{$lc_key}                            = $self->{class_map}{$key};
		$self->{snmp_class_map}{$lc_key}                            = $self->{class_map}{$key};
		$self->{snmp_class_map}{$lc_key} =~ s/^\!/not\_/;
		$self->{snmp_class_map}{$lc_key} =~ s/\ /\_/;
	} ## end foreach my $key (@keys)

	return $self;
} ## end sub new

=head2 run

Start processing. This method is not expected to return.

    $lilith->run(
                 files=>{
                        foo=>{
                              type=>'suricata',
                              instance=>'foo-pie',
                              eve=>'/var/log/suricata/alerts-pie.json',
                              },
                        'foo-lae'=>{
                                    type=>'sagan',
                                    eve=>'/var/log/sagan/alerts-lae.json',
                                    },
                        },
                );

One argument named 'files' is taken and it is hash of
hashes. The keys are below.

    - type :: Either 'suricata', 'sagan', or 'cape', depending
              on the type it is.

    - eve :: Path to the EVE file to read.

    - instance :: Instance name. If not specified the key
                  is used.

=cut

sub run {
	my ( $self, %opts ) = @_;

	my $dbh;
	eval { $dbh = DBI->connect_cached( $self->{dsn}, $self->{user}, $self->{pass} ); };
	if ($@) {
		warn($@);
		openlog( 'lilith', undef, 'daemon' );
		syslog( 'LOG_ERR', $@ );
		closelog;
	}

	# process each file
	my $file_count = 0;
	foreach my $item_key ( keys( %{ $opts{files} } ) ) {
		my $item = $opts{files}->{$item_key};
		if ( !defined( $item->{instance} ) ) {
			warn( 'No instance name specified for ' . $item_key . ' so using that as the instance name' );
			$item->{instance} = $item_key;
		}

		if ( !defined( $item->{type} ) ) {
			die( 'No type specified for ' . $item->{instance} );
		} elsif ( $item->{type} ne 'suricata' && $item->{type} ne 'sagan' && $item->{type} ne 'cape' ) {
			die( 'Type, ' . $item->{type} . ', for instance ' . $item->{instance} . ' is not a known type' );
		}

		if ( !defined( $item->{eve} ) ) {
			die( 'No file specified for ' . $item->{instance} );
		}

		# create each POE session out for each EVE file we are following
		POE::Session->create(
			inline_states => {
				_start => sub {
					$_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
						Filename   => $_[HEAP]{eve},
						InputEvent => "got_log_line",
					);
				},
				got_log_line => sub {
					my $self = $_[HEAP]{self};
					my $json;
					eval { $json = decode_json( $_[ARG0] ) };
					if ($@) {
						return;
					}

					my $dbh;
					eval { $dbh = DBI->connect_cached( $self->{dsn}, $self->{user}, $self->{pass} ); };
					if ($@) {
						warn($@);
						openlog( 'lilith', undef, 'daemon' );
						syslog( 'LOG_ERR', $@ );
						closelog;
					}

					eval {
						if (   defined($json)
							&& defined( $json->{event_type} )
							&& $json->{event_type} eq 'alert' )
						{
							# put the event ID together
							my $event_id
								= sha256_base64( $_[HEAP]{instance}
									. $_[HEAP]{host}
									. $json->{timestamp}
									. $json->{flow_id}
									. $json->{in_iface} );

							# handle if suricata
							if ( $_[HEAP]{type} eq 'suricata' ) {
								my $sth
									= $dbh->prepare( 'insert into '
										. $self->{suricata}
										. ' ( instance, host, timestamp, flow_id, event_id, in_iface, src_ip, src_port, dest_ip, dest_port, proto, app_proto, flow_pkts_toserver, flow_bytes_toserver, flow_pkts_toclient, flow_bytes_toclient, flow_start, classification, signature, gid, sid, rev, raw ) '
										. ' VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? );'
									);
								$sth->execute(
									$_[HEAP]{instance},           $_[HEAP]{host},
									$json->{timestamp},           $json->{flow_id},
									$event_id,                    $json->{in_iface},
									$json->{src_ip},              $json->{src_port},
									$json->{dest_ip},             $json->{dest_port},
									$json->{proto},               $json->{app_proto},
									$json->{flow}{pkts_toserver}, $json->{flow}{bytes_toserver},
									$json->{flow}{pkts_toclient}, $json->{flow}{bytes_toclient},
									$json->{flow}{start},         $json->{alert}{category},
									$json->{alert}{signature},    $json->{alert}{gid},
									$json->{alert}{signature_id}, $json->{alert}{rev},
									$_[ARG0]
								);
							} ## end if ( $_[HEAP]{type} eq 'suricata' )

							#handle if sagan
							elsif ( $_[HEAP]{type} eq 'sagan' ) {
								my $sth
									= $dbh->prepare( 'insert into '
										. $self->{sagan}
										. ' ( instance, instance_host, timestamp, event_id, flow_id, in_iface, src_ip, src_port, dest_ip, dest_port, proto, facility, host, level, priority, program, proto, xff, stream, classification, signature, gid, sid, rev, raw) '
										. ' VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? );'
									);
								$sth->execute(
									$_[HEAP]{instance},           $_[HEAP]{host},
									$json->{timestamp},           $event_id,
									$json->{flow_id},             $json->{in_iface},
									$json->{src_ip},              $json->{src_port},
									$json->{dest_ip},             $json->{dest_port},
									$json->{proto},               $json->{facility},
									$json->{host},                $json->{level},
									$json->{priority},            $json->{program},
									$json->{proto},               $json->{xff},
									$json->{stream},              $json->{alert}{category},
									$json->{alert}{signature},    $json->{alert}{gid},
									$json->{alert}{signature_id}, $json->{alert}{rev},
									$_[ARG0],
								);
							} elsif ( $_[HEAP]{type} eq 'cape' ) {
								my $sth
									= $dbh->prepare( 'insert into '
										. $self->{cape}
										. ' ( instance, target, instance_host, task, start, stop, malscore, subbed_from_ip, subbed_from_host, pkg, md5, sha1, sha256, slug, url, url_hostname, proto, src_ip, src_port, dest_ip, dest_port, size, raw ) '
										. ' VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? );'
									);

								my $url;
								if ( defined( $json->{http} ) && defined( $json->{http}{url} ) ) {
									$url = $json->{http}{url};
								}

								my $url_hostname;
								if ( defined( $json->{http} ) && defined( $json->{http}{hostname} ) ) {
									$url_hostname = $json->{http}{hostname};
								}

								my $proto;
								if ( defined( $json->{proto} ) ) {
									$proto = $json->{proto};
								}

								my $src_ip;
								if ( defined( $json->{src_ip} ) ) {
									$src_ip = $json->{src_ip};
								}

								my $src_port;
								if ( defined( $json->{src_port} ) ) {
									$src_port = $json->{src_port};
								}

								my $dest_ip;
								if ( defined( $json->{dest_ip} ) ) {
									$dest_ip = $json->{dest_ip};
								}

								my $dest_port;
								if ( defined( $json->{dest_port} ) ) {
									$dest_port = $json->{dest_port};
								}

								my $size;
								if ( defined( $json->{cape_submit} ) && defined( $json->{cape_submit}{size} ) ) {
									$size = $json->{cape_submit}{size};
								} elsif ( defined( $json->{fileinfo} ) && defined( $json->{fileinfo}{size} ) ) {
									$size = $json->{fileinfo}{size};
								}

								# figure out what to use for the target
								my $target;
								if ( defined( $json->{cape_submit} ) && defined( $json->{cape_submit}{name} ) ) {
									$target = $json->{cape_submit}{name};
								} elsif ( defined( $json->{suricata_extract_submit} )
									&& defined( $json->{suricata_extract_submit}{name} ) )
								{
									$target = $json->{suricata_extract_submit}{name};
								} else {
									$target = $json->{row}{target};
								}

								my $subbed_from_ip;
								if ( defined( $json->{cape_submit} ) && defined( $json->{cape_submit}{remote_ip} ) )
								{
									$subbed_from_ip = $json->{cape_submit}{remote_ip};
								}

								my $subbed_from_host;
								if (   defined( $json->{suricata_extract_submit} )
									&& defined( $json->{suricata_extract_submit}{host} ) )
								{
									$subbed_from_host = $json->{suricata_extract_submit}{host};
								}

								my $md5;
								if ( defined( $json->{cape_submit} ) && defined( $json->{cape_submit}{md5} ) ) {
									$md5 = $json->{cape_submit}{md5};
								} elsif ( defined( $json->{suricata_extract_submit} )
									&& defined( $json->{suricata_extract_submit}{md5} ) )
								{
									$md5 = $json->{suricata_extract_submit}{md5};
								}

								my $sha1;
								if ( defined( $json->{cape_submit} ) && defined( $json->{cape_submit}{sha1} ) ) {
									$sha1 = $json->{cape_submit}{sha1};
								} elsif ( defined( $json->{suricata_extract_submit} )
									&& defined( $json->{suricata_extract_submit}{sha1} ) )
								{
									$sha1 = $json->{suricata_extract_submit}{sha1};
								}

								my $sha256;
								if ( defined( $json->{cape_submit} ) && defined( $json->{cape_submit}{sha256} ) ) {
									$sha256 = $json->{cape_submit}{sha256};
								} elsif ( defined( $json->{suricata_extract_submit} )
									&& defined( $json->{suricata_extract_submit}{sha256} ) )
								{
									$sha256 = $json->{suricata_extract_submit}{sha256};
								}

								my $slug;
								if ( defined( $json->{suricata_extract_submit}{slug} ) ) {
									$slug = $json->{suricata_extract_submit}{slug};
								} elsif ( defined( $json->{cape_submit} ) && defined( $json->{cape_submit}{slug} ) )
								{
									$slug = $json->{cape_submit}{slug};
								}

								$target =~ s/^.*\///g;
								$sth->execute(
									$_[HEAP]{instance},       $target,
									$_[HEAP]{host},           $json->{row}{id},
									$json->{row}{started_on}, $json->{row}{completed_on},
									$json->{malscore},        $subbed_from_ip,
									$subbed_from_host,        $json->{row}{package},
									$md5,                     $sha1,
									$sha256,                  $slug,
									$url,                     $url_hostname,
									$proto,                   $src_ip,
									$src_port,                $dest_ip,
									$dest_port,               $size,
									$_[ARG0],
								);
							} ## end elsif ( $_[HEAP]{type} eq 'cape' )
						} ## end if ( defined($json) && defined( $json->{event_type...}))
						if ($@) {
							warn( 'SQL INSERT issue... ' . $@ );
							openlog( 'lilith', undef, 'daemon' );
							syslog( 'LOG_ERR', 'SQL INSERT issue... ' . $@ );
							closelog;
						}
					} ## end eval

				},
			},
			heap => {
				eve      => $item->{eve},
				type     => $item->{type},
				host     => hostname,
				instance => $item->{instance},
				self     => $self,
			},
		);

	} ## end foreach my $item_key ( keys( %{ $opts{files} } ...))

	POE::Kernel->run;
} ## end sub run

=head2 create_tables

Just creates the required tables in the DB.

     $lilith->create_tables;

=cut

sub create_tables {
	my ( $self, %opts ) = @_;

	my $dbh = DBI->connect_cached( $self->{dsn}, $self->{user}, $self->{pass} );

	my $sth
		= $dbh->prepare( 'create table '
			. $self->{suricata} . ' ('
			. 'id bigserial NOT NULL, '
			. 'instance varchar(255) NOT NULL,'
			. 'host varchar(255) NOT NULL,'
			. 'timestamp TIMESTAMP WITH TIME ZONE NOT NULL, '
			. 'event_id varchar(64) NOT NULL, '
			. 'flow_id bigint, '
			. 'in_iface varchar(255), '
			. 'src_ip inet, '
			. 'src_port integer, '
			. 'dest_ip inet, '
			. 'dest_port integer, '
			. 'proto varchar(32), '
			. 'app_proto varchar(255), '
			. 'flow_pkts_toserver integer, '
			. 'flow_bytes_toserver integer, '
			. 'flow_pkts_toclient integer, '
			. 'flow_bytes_toclient integer, '
			. 'flow_start TIMESTAMP WITH TIME ZONE, '
			. 'classification varchar(1024), '
			. 'signature varchar(2048),'
			. 'gid int, '
			. 'sid bigint, '
			. 'rev bigint, '
			. 'raw json NOT NULL, '
			. 'PRIMARY KEY(id) );' );
	$sth->execute();

	$sth
		= $dbh->prepare( 'create table '
			. $self->{sagan} . ' ('
			. 'id bigserial NOT NULL, '
			. 'instance varchar(255)  NOT NULL, '
			. 'instance_host varchar(255)  NOT NULL, '
			. 'timestamp TIMESTAMP WITH TIME ZONE, '
			. 'event_id varchar(64) NOT NULL, '
			. 'flow_id bigint, '
			. 'in_iface varchar(255), '
			. 'src_ip inet, '
			. 'src_port integer, '
			. 'dest_ip inet, '
			. 'dest_port integer, '
			. 'proto varchar(32), '
			. 'facility varchar(255), '
			. 'host varchar(255), '
			. 'level varchar(255), '
			. 'priority varchar(255), '
			. 'program varchar(255), '
			. 'xff inet, '
			. 'stream bigint, '
			. 'classification varchar(1024), '
			. 'signature varchar(2048),'
			. 'gid int, '
			. 'sid bigint, '
			. 'rev bigint, '
			. 'raw json NOT NULL, '
			. 'PRIMARY KEY(id) );' );
	$sth->execute();

	$sth
		= $dbh->prepare( 'create table '
			. $self->{cape} . ' ('
			. 'id bigserial NOT NULL, '
			. 'instance varchar(255)  NOT NULL, '
			. 'target varchar(255)  NOT NULL, '
			. 'instance_host varchar(255)  NOT NULL, '
			. 'task bigserial NOT NULL, '
			. 'start TIMESTAMP WITH TIME ZONE, '
			. 'stop TIMESTAMP WITH TIME ZONE, '
			. 'malscore bigint NOT NULL, '
			. 'subbed_from_ip inet, '
			. 'subbed_from_host varchar(255), '
			. 'pkg varchar(255), '
			. 'md5 varchar(255), '
			. 'sha1 varchar(255), '
			. 'sha256 varchar(255), '
			. 'slug varchar(255), '
			. 'url varchar(255), '
			. 'url_hostname varchar(255), '
			. 'proto varchar(255), '
			. 'src_ip inet, '
			. 'src_port integer, '
			. 'dest_ip inet, '
			. 'dest_port integer, '
			. 'size integer, '
			. 'raw jsonb NOT NULL, '
			. 'PRIMARY KEY(id) );' );
	$sth->execute();

} ## end sub create_tables

=head2 extend

	my $return=$lilith->extend(
		                       go_back_minutes=>5,
	                          );

=cut

sub extend {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{go_back_minutes} ) ) {
		$opts{go_back_minutes} = 5;
	}

	#
	# basic initial stuff
	#

	# librenms return hash
	my $to_return = {
		data => {
			totals             => { total => 0, },
			sagan_instances    => {},
			suricata_instances => {},
			sagan_totals       => { total => 0, },
			suricata_totals    => { total => 0, },
		},
		version     => 1,
		error       => '0',
		errorString => '',
	};

	#
	# Do the search in eval incase of failure
	#

	my $sagan_found    = ();
	my $suricata_found = ();
	eval {
		my $dbh;
		eval { $dbh = DBI->connect_cached( $self->{dsn}, $self->{user}, $self->{pass} ); };
		if ($@) {
			die( 'DBI->connect_cached failure.. ' . $@ );
		}

		my $hostname = hostname;

		#
		# suricata SQL bit
		#

		my $sql
			= 'select * from '
			. $self->{suricata}
			. " where timestamp >= CURRENT_TIMESTAMP - interval '"
			. $opts{go_back_minutes}
			. " minutes' and host ='"
			. $hostname . "'";

		$sql = $sql . ';';
		if ( $self->{debug} ) {
			warn( 'SQL search "' . $sql . '"' );
		}
		my $sth = $dbh->prepare($sql);
		$sth->execute();

		while ( my $row = $sth->fetchrow_hashref ) {
			push( @{$suricata_found}, $row );
		}

		#
		# Sagan SQL bit
		#

		$sql
			= 'select * from '
			. $self->{sagan}
			. " where timestamp >= CURRENT_TIMESTAMP - interval '"
			. $opts{go_back_minutes}
			. " minutes' and instance_host = '"
			. $hostname . "'";

		$sql = $sql . ';';
		if ( $self->{debug} ) {
			warn( 'SQL search "' . $sql . '"' );
		}
		$sth = $dbh->prepare($sql);
		$sth->execute();

		while ( my $row = $sth->fetchrow_hashref ) {
			push( @{$sagan_found}, $row );
		}

	};
	if ($@) {
		$to_return->{error}       = 1;
		$to_return->{errorString} = $@;
	}

	foreach my $row ( @{$suricata_found} ) {
		$to_return->{data}{totals}{total}++;
		$to_return->{data}{suricata_totals}{total}++;
		my $snmp_class = $self->get_short_class_snmp( $row->{classification} );
		if ( !defined( $to_return->{data}{totals}{$snmp_class} ) ) {
			$to_return->{data}{totals}{$snmp_class} = 1;
		} else {
			$to_return->{data}{totals}{$snmp_class}++;
		}
		if ( !defined( $to_return->{data}{suricata_totals}{$snmp_class} ) ) {
			$to_return->{data}{suricata_totals}{$snmp_class} = 1;
		} else {
			$to_return->{data}{suricata_totals}{$snmp_class}++;
		}
		if ( !defined( $to_return->{data}{suricata_instances}{ $row->{instance} } ) ) {
			$to_return->{data}{suricata_instances}{ $row->{instance} } = { total => 0 };
		}
		$to_return->{data}{suricata_instances}{ $row->{instance} }{total}++;
		if ( !defined( $to_return->{data}{suricata_instances}{ $row->{instance} }{$snmp_class} ) ) {
			$to_return->{data}{suricata_instances}{ $row->{instance} }{$snmp_class} = 1;
		} else {
			$to_return->{data}{suricata_instances}{ $row->{instance} }{$snmp_class}++;
		}
	} ## end foreach my $row ( @{$suricata_found} )

	foreach my $row ( @{$sagan_found} ) {
		$to_return->{data}{totals}{total}++;
		$to_return->{data}{sagan_totals}{total}++;
		my $snmp_class = $self->get_short_class_snmp( $row->{classification} );
		if ( !defined( $to_return->{data}{totals}{$snmp_class} ) ) {
			$to_return->{data}{totals}{$snmp_class} = 1;
		} else {
			$to_return->{data}{totals}{$snmp_class}++;
		}
		if ( !defined( $to_return->{data}{sagan_totals}{$snmp_class} ) ) {
			$to_return->{data}{sagan_totals}{$snmp_class} = 1;
		} else {
			$to_return->{data}{sagan_totals}{$snmp_class}++;
		}
		if ( !defined( $to_return->{data}{sagan_instances}{ $row->{instance} } ) ) {
			$to_return->{data}{sagan_instances}{ $row->{instance} } = { total => 0 };
		}
		$to_return->{data}{sagan_instances}{ $row->{instance} }{total}++;
		if ( !defined( $to_return->{data}{sagan_instances}{ $row->{instance} }{$snmp_class} ) ) {
			$to_return->{data}{sagan_instances}{ $row->{instance} }{$snmp_class} = 1;
		} else {
			$to_return->{data}{sagan_instances}{ $row->{instance} }{$snmp_class}++;
		}
	} ## end foreach my $row ( @{$sagan_found} )

	return $to_return;
} ## end sub extend

=head2 generate_baphomet_yamls

Geneartes fastlog parsing YAMLs for baphomet.

One argument is required is required and that is the dir to write out to.

If there are any errors, it will die.

=cut

sub generate_baphomet_yamls {
	my ( $self, $dir ) = @_;

	# run some basic checks prior to starting trying to write them all
	if ( !defined($dir) ) {
		die('No directory specified to write files to');
	} elsif ( !-d $dir ) {
		die( '"' . $dir . '" is not a directory' );
	} elsif ( !-w $dir ) {
		die( '"' . $dir . '" is not writable' );
	}

	my $ypp  = YAML::PP->new( schema => [qw/ + Perl /] );
	my @keys = keys( %{ $self->{class_map} } );
	foreach my $class ( sort(@keys) ) {
		my $lc_key    = lc($class);
		my $snmp_name = $self->{snmp_class_map}{$lc_key};

		my $yaml = $ypp->dump_string(
			{
				vars => {
					'fastlog_class_to_use' => $class,
				},
				start_chomp   => 1,
				start_pattern => '[== fastlog_chomp ==]',
				includes      => ['common.yaml'],
				regexp        => ['[== fastlog_chomped_with_class  ==]'],
				tests         => {
					found_1 => {
						line =>
							'03/26/2023-19:30:50.356934  [**] [1:0123456:123] Rule Description Goes Here [**] [Classification: '
							. $class
							. '] [Priority: 2] {TCP} 5.6.7.8:6163 -> 1.2.3.4:443',
						found => 1,
						data  => {
							'group'    => '1',
							'rule'     => '0123456',
							'rev'      => '123',
							'SRC'      => '5.6.7.8',
							'DEST'     => '1.2.3.4',
							'pri'      => '2',
							'proto'    => 'TCP',
							'dst_port' => '443',
							'src_port' => '6163',
						},
						undefed => [ 'HOST', 'SUBNET', 'IP4', 'IP6', 'ADDR', 'DNS' ],
					},
					found_2 => {
						line =>
							'03/26/2023-19:30:50.356934  [**] [1:0123456:123] Rule Description Goes Here [**] [Classification: '
							. $class
							. '] [Priority: 2] {UDP} 5.6.7.8:26163 -> 1.2.3.4:4',
						found => 1,
						data  => {
							'group'    => '1',
							'rule'     => '0123456',
							'rev'      => '123',
							'SRC'      => '5.6.7.8',
							'DEST'     => '1.2.3.4',
							'pri'      => '2',
							'proto'    => 'UDP',
							'dst_port' => '4',
							'src_port' => '26163',
						},
						undefed => [ 'HOST', 'SUBNET', 'IP4', 'IP6', 'ADDR', 'DNS' ],
					},
					found_3 => {
						line =>
							'03/26/2023-19:30:50  [**] [1:0123456:123] Rule Description Goes Here [**] [Classification: '
							. $class
							. '] [Priority: 2] {UDP} 5.6.7.8:26163 -> 1.2.3.4:4',
						found => 1,
						data  => {
							'group'    => '1',
							'rule'     => '0123456',
							'rev'      => '123',
							'SRC'      => '5.6.7.8',
							'DEST'     => '1.2.3.4',
							'pri'      => '2',
							'proto'    => 'UDP',
							'dst_port' => '4',
							'src_port' => '26163',
						},
						undefed => [ 'HOST', 'SUBNET', 'IP4', 'IP6', 'ADDR', 'DNS' ],
					},
					notFound_1 => {
						line =>
							'03/26/2023-19:30:50.356934  [**] [1:0123456:123] Rule Description Goes Here [**] [Classification: '
							. reverse($class)
							. '] [Priority: 2] {UDP} 5.6.7.8:26163 -> 1.2.3.4:4',
						found   => 0,
						data    => {},
						undefed => [
							'HOST',  'SUBNET',   'IP4',  'IP6', 'ADDR', 'DNS',
							'DEST',  'SRC',      'rule', 'rev', 'pri',  'group',
							'proto', 'dst_port', 'src_port'
						],
					},
				}
			}
		);

		my $name = 'fastlog_' . $snmp_name;
		$name =~ s/\ /_/g;
		write_file( $dir . '/' . $name . '.yaml', $yaml );
	} ## end foreach my $class ( sort(@keys) )

	return 1;
} ## end sub generate_baphomet_yamls

=head2 get_short_class

Get SNMP short class name for a class.

    my $short_class_name=$lilith->get_short_class($class);

=cut

sub get_short_class {
	my ( $self, $class ) = @_;

	if ( !defined($class) ) {
		return ('undefC');
	}

	if ( defined( $self->{lc_class_map}->{ lc($class) } ) ) {
		return $self->{lc_class_map}->{ lc($class) };
	}

	return ('unknownC');
} ## end sub get_short_class

=head2 get_short_class_snmp

Get SNMP short class name for a class. This
is the same as the short class name, but with /^\!/
replaced with 'not_'.

    my $snmp_class_name=$lilith->get_short_class_snmp($class);

=cut

sub get_short_class_snmp {
	my ( $self, $class ) = @_;

	if ( !defined($class) ) {
		return ('undefC');
	}

	if ( defined( $self->{snmp_class_map}->{ lc($class) } ) ) {
		return $self->{snmp_class_map}->{ lc($class) };
	}

	return ('unknownC');
} ## end sub get_short_class_snmp

=head2 get_short_class_snmp_list

Gets a list of short SNMP class names.

    my $snmp_classes=$lilith->get_short_class_snmp_list;

    foreach my $item (@{ $snmp_classes }){
        print $item."\n";
    }

=cut

sub get_short_class_snmp_list {
	my ($self) = @_;

	my $snmp_classes = [ 'undefC', 'unknownC' ];
	foreach my $item ( keys( %{ $self->{snmp_class_map} } ) ) {
		push( @{$snmp_classes}, $self->{snmp_class_map}{$item} );
	}

	return $snmp_classes;
} ## end sub get_short_class_snmp_list

=head2 search

Searches the specified table and returns a array of found rows.

    - table :: 'suricata', 'cape', 'sagan' depending on the desired table to
               use. Will die if something other is specified. The table
               name used is based on what was passed to new(if not the
               default).
      Default :: suricata

    - go_back_minutes :: How far back to search in minutes.
      Default :: 1440

    - limit :: Limit on how many to return.
      Default :: undef

    - offset :: Offset for when using limit.
      Default :: undef

    - order_by :: Column to order by.
      Default :: timetamp
      Cape Default :: id

    - order_dir :: Direction to order.
      Default :: ASC

Below are simple search items that if given will be matched via a basic equality.

    - src_ip
    - dest_ip
    - event_id
    - md5
    - sha1
    - sha256
    - subbed_from_ip

    # will become "and src_ip = '192.168.1.2'"
    src_ip => '192.168.1.2',

Below are a list of numeric items. The value taken is a array and anything
prefixed '!' with add as a and not equal.

    - src_port
    - dest_port
    - gid
    - sid
    - rev
    - id
    - size
    - malscore
    - task

    # will become "and src_port = '22' and src_port != ''512'"
    src_port => ['22', '!512'],

Below are a list of string items. On top of these variables,
any of those with '_like' or '_not' will my modified respectively.

    - host
    - instance_host
    - instance
    - class
    - signature
    - app_proto
    - in_iface
    - url
    - url_hostname
    - slug
    - pkg

    # will become "and host = 'foo.bar'"
    host => 'foo.bar',

    # will become "and class != 'foo'"
    class => 'foo',
    class_not => 1,

    # will become "and instance like '%foo'"
    instance => '%foo',
    instance_like => 1,

    # will become "and instance not like '%foo'"
    instance => '%foo',
    instance_like => 1,
    instance_not => 1,

Below are complex items.

    - ip
    - port

    # will become "and ( src_ip != '192.168.1.2' or dest_ip != '192.168.1.2' )"
    ip => '192.16.1.2'

    # will become "and ( src_port != '22' or dest_port != '22' )"
    port => '22'

=cut

sub search {
	my ( $self, %opts ) = @_;

	#
	# basic requirements sanity checking
	#

	if ( !defined( $opts{table} ) ) {
		$opts{table} = 'suricata';
	} else {
		if ( $opts{table} ne 'suricata' && $opts{table} ne 'sagan' && $opts{table} ne 'cape' ) {
			die( '"' . $opts{table} . '" is not a known table type' );
		}
	}

	if ( !defined( $opts{go_back_minutes} ) ) {
		$opts{go_back_minutes} = '1440';
	} else {
		if ( $opts{go_back_minutes} !~ /^[0-9]+$/ ) {
			die( '"' . $opts{go_back_minutes} . '" for go_back_minutes is not numeric' );
		}
	}

	if ( defined( $opts{limit} ) && $opts{limit} !~ /^[0-9]+$/ ) {
		die( '"' . $opts{limit} . '" is not numeric and limit needs to be numeric' );
	}

	if ( defined( $opts{offset} ) && $opts{offset} !~ /^[0-9]+$/ ) {
		die( '"' . $opts{offset} . '" is not numeric and offset needs to be numeric' );
	}

	if ( defined( $opts{order_by} ) && $opts{order_by} !~ /^[\_a-zA-Z]+$/ ) {
		die( '"' . $opts{order_by} . '" is set for order_by and it does not match /^[\_a-zA-Z]+$/' );
	}

	if ( defined( $opts{order_dir} ) && $opts{order_dir} ne 'ASC' && $opts{order_dir} ne 'DESC' ) {
		die( '"' . $opts{order_dir} . '" for order_dir must by either ASC or DESC' );
	} elsif ( !defined( $opts{order_dir} ) ) {
		$opts{order_dir} = 'ASC';
	}

	if ( !defined( $opts{order_by} ) ) {
		if ( $opts{table} ne 'cape' ) {
			$opts{order_by} = 'timestamp';
		} else {
			$opts{order_by} = 'stop';
		}
	}

	my $table = $self->{suricata};
	if ( $opts{table} eq 'sagan' ) {
		$table = $self->{sagan};
	} elsif ( $opts{table} eq 'cape' ) {
		$table = $self->{cape};
	}

	#
	# make sure all the set variables are not dangerous or potentially dangerous
	#

	my @to_check = (
		'src_ip', 'src_port',   'dest_ip',       'dest_port',     'ip',        'port',
		'host',   'host',       'instance_host', 'instance_host', 'instance',  'instance',
		'class',  'class_like', 'signature',     'signature',     'app_proto', 'app_proto_like',
		'proto',  'gid',        'sid',           'rev',           'id',        'event_id',
		'in_iface'
	);

	foreach my $var_to_check (@to_check) {
		if ( defined( $opts{$var_to_check} ) && $opts{$var_to_check} =~ /[\\\']/ ) {
			die( '"' . $opts{$var_to_check} . '" for "' . $var_to_check . '" matched /[\\\']/' );
		}
	}

	#
	# makes sure order_by is sane
	#

	my @order_by = (
		'src_ip',    'src_port',  'dest_ip',          'dest_port',
		'host',      'host_like', 'instance_host',    'instance_host',
		'instance',  'instance',  'class',            'class',
		'signature', 'signature', 'app_proto',        'app_proto',
		'proto',     'gid',       'sid',              'rev',
		'timestamp', 'id',        'in_iface',         'url_hostname',
		'url',       'slug',      'sha256',           'sha1',
		'md5',       'pkg',       'subbed_from_host', 'subbed_from_ip',
		'malscore',  'task',      'target',           'proto',
		'size',      'id',        'stop',             'start'
	);

	my $valid_order_by;

	foreach my $item (@order_by) {
		if ( $item eq $opts{order_by} ) {
			$valid_order_by = 1;
		}
	}

	if ( !$valid_order_by ) {
		die( '"' . $opts{order_by} . '" is not a valid column name for order_by' );
	}

	#
	# assemble
	#

	my $host = hostname;

	my $dbh = DBI->connect_cached( $self->{dsn}, $self->{user}, $self->{pass} );

	my $sql = 'select * from ' . $table . ' where';
	if ( defined( $opts{no_time} ) && $opts{no_time} ) {
		$sql = $sql . ' id >= 0';
	} else {
		my $go_back_column = 'timestamp';
		if ( $opts{table} eq 'cape' ) {
			$go_back_column = 'stop';
		}
		$sql
			= $sql . " "
			. $go_back_column
			. " >= CURRENT_TIMESTAMP - interval '"
			. $opts{go_back_minutes}
			. " minutes'";
	} ## end else [ if ( defined( $opts{no_time} ) && $opts{no_time...})]

	#
	# add simple items
	#

	my @simple = ( 'src_ip', 'dest_ip', 'proto', 'event_id', 'md5', 'sha1', 'sha256', 'subbed_from_ip' );

	foreach my $item (@simple) {
		if ( defined( $opts{$item} ) ) {
			$sql = $sql . " and " . $item . " = '" . $opts{$item} . "'";
		}
	}

	#
	# add numeric items
	#

	my @numeric = ( 'src_port', 'dest_port', 'gid', 'sid', 'rev', 'id', 'size', 'malscore', 'task' );

	foreach my $item (@numeric) {
		if ( defined( $opts{$item} ) ) {

			# remove and tabs or spaces
			$opts{$item} =~ s/[\ \t]//g;
			my @arg_split = split( /\,/, $opts{$item} );

			# process each item
			foreach my $arg (@arg_split) {

				# match the start of the item
				if ( $arg =~ /^[0-9]+$/ ) {
					$sql = $sql . " and " . $item . " = '" . $arg . "'";
				} elsif ( $arg =~ /^\<\=[0-9]+$/ ) {
					$arg =~ s/^\<\=//;
					$sql = $sql . " and " . $item . " <= '" . $arg . "'";
				} elsif ( $arg =~ /^\<[0-9]+$/ ) {
					$arg =~ s/^\<//;
					$sql = $sql . " and " . $item . " < '" . $arg . "'";
				} elsif ( $arg =~ /^\>\=[0-9]+$/ ) {
					$arg =~ s/^\>\=//;
					$sql = $sql . " and " . $item . " >= '" . $arg . "'";
				} elsif ( $arg =~ /^\>[0-9]+$/ ) {
					$arg =~ s/^\>\=//;
					$sql = $sql . " and " . $item . " > '" . $arg . "'";
				} elsif ( $arg =~ /^\![0-9]+$/ ) {
					$arg =~ s/^\!//;
					$sql = $sql . " and " . $item . " != '" . $arg . "'";
				} elsif ( $arg =~ /^$/ ) {

					# only exists for skipping when some one has passes something starting
					# with a ,, ending with a,, or with ,, in it.
				} else {
					# if we get here, it means we don't have a valid use case for what ever was passed and should error
					die( '"' . $arg . '" does not appear to be a valid item for a numeric search for the ' . $item );
				}
			} ## end foreach my $arg (@arg_split)
		} ## end if ( defined( $opts{$item} ) )
	} ## end foreach my $item (@numeric)

	#
	# handle string items
	#

	my @strings = (
		'host',         'instance_host', 'instance', 'class',
		'signature',    'app_proto',     'in_iface', 'url',
		'url_hostname', 'slug',          'pkg',      'subbed_from_host'
	);

	foreach my $item (@strings) {
		if ( defined( $opts{$item} ) ) {
			if ( defined( $opts{ $item . '_like' } ) && $opts{ $item . '_like' } ) {
				if ( defined( $opts{$item} . '_not' ) && !$opts{ $item . '_not' } ) {
					$sql = $sql . " and " . $item . " like '" . $opts{$item} . "'";
				} else {
					$sql = $sql . " and " . $item . " not like '" . $opts{$item} . "'";
				}
			} else {
				if ( defined( $opts{$item} . '_not' ) && !$opts{ $item . '_not' } ) {
					$sql = $sql . " and " . $item . " = '" . $opts{$item} . "'";
				} else {
					$sql = $sql . " and " . $item . " != '" . $opts{$item} . "'";
				}
			}
		} ## end if ( defined( $opts{$item} ) )
	} ## end foreach my $item (@strings)

	#
	# more complex items
	#

	if ( defined( $opts{ip} ) ) {
		$sql = $sql . " and ( src_ip = '" . $opts{ip} . "' or dest_ip = '" . $opts{ip} . "' )";
	}

	if ( defined( $opts{port} ) ) {
		$sql = $sql . " and ( src_port = '" . $opts{port} . "'  or dest_port = '" . $opts{port} . "' )";
	}

	#
	# finalize the SQL query... ORDER, LIMIT, and OFFSET
	#

	if ( defined( $opts{order_by} ) ) {
		$sql = $sql . ' ORDER BY ' . $opts{order_by} . ' ' . $opts{order_dir};
	}

	if ( defined( $opts{linit} ) ) {
		$sql = $sql . ' LIMIT ' . $opts{limit};
	}

	if ( defined( $opts{offset} ) ) {
		$sql = $sql . ' OFFSET ' . $opts{offset};
	}

	#
	# run the query
	#

	$sql = $sql . ';';
	if ( $self->{debug} ) {
		warn( 'SQL search "' . $sql . '"' );
	}
	my $sth = $dbh->prepare($sql);
	$sth->execute();

	my $found = ();
	while ( my $row = $sth->fetchrow_hashref ) {
		push( @{$found}, $row );
	}

	$dbh->disconnect;

	return $found;
} ## end sub search

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lilith at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lilith>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lilith


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Lilith>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Lilith>

=item * Search CPAN

L<https://metacpan.org/release/Lilith>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Lilith
