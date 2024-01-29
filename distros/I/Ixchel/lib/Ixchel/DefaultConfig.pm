package Ixchel::DefaultConfig;

use 5.006;
use strict;
use warnings;
#use Rex::Hardware::Host;

=head1 NAME

Ixchel::DefaultConfig - The default config used for with Ixchel.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 SYNOPSIS

    use Ixchel::DefaultConfig;
    use Data::Dumper;

    print Dumper( Ixchel::DefaultConfig->get );

Also can easily be dumped via...

    ixchel -a dump_config --noConfig -o yaml

=head1 Functions

=head2 get

Returns a hash reference of the default config.

=cut

sub get {
	my $config = {
		suricata => {
			multi_instance    => 0,
			config_base       => '/usr/local/etc/suricata',
			instances         => {},
			config            => { 'rule-files' => ['suricata.rules'] },
			enable            => 0,
			enable_fastlog    => 1,
			enable_syslog     => 0,
			filestore_enable  => 1,
			dhcp_in_alert_eve => 0,
			enable_pcap_log   => 0,
			base_config       => 'https://raw.githubusercontent.com/OISF/suricata/master/suricata.yaml.in',
			base_fill_in      => {
				e_logdir             => '/var/log/suricata/',
				e_magic_file_comment => '',
				e_magic_file         => '/usr/share/misc/magic',
				e_defaultruledir     => '/etc/suricata/rules',
			},
			logging => {
				in_outputs      => 1,
				level           => 'notice',
				console         => 'no',
				console_json    => 0,
				file            => 'yes',
				file_level      => 'info',
				file_json       => 0,
				syslog          => 'no',
				syslog_facility => 'local5',
				syslog_format   => '[%i] <%d> -- ',
				syslog_json     => 0,
			},
			lilith => {
				enable => 0,
				config => {},
			},
			update => {
				enable       => 0,
				no_reload    => 0,
				no_test      => 0,
				offline      => 0,
				fail         => 0,
				disable_conf => 1,
				disable_file => undef,
				enable_conf  => 1,
				disable_file => undef,
				modify_conf  => 1,
				modify_file  => undef,
				drop_conf    => 1,
				drop_file    => undef,
				conf_file    => undef,
				update_file  => undef,
				when         => '33 0 * * *',
			},
		},
		suricata_extract => {
			enable      => 0,
			url         => '',
			slug        => '',
			apikey      => '',
			filestore   => '',
			ignore      => '',
			ignoreHosts => '',
			env_proxy   => 0,
			stats_file  => '/var/cache/suricata_extract_submit_stats.json',
			stats_dir   => '/var/cache/suricata_extract_submit_stats/',
			interval    => '*/2 * * * *',
		},
		sagan => {
			multi_instance      => 0,
			merged_base_include => 1,
			config_base         => '/usr/local/etc/',
			instances           => {},
			config              => {},
			rules               => [],
			instances_rules     => {},
			enable              => 0,
			base_config         => 'https://raw.githubusercontent.com/quadrantsec/sagan/main/etc/sagan.yaml',
			rules               => 'https://raw.githubusercontent.com/quadrantsec/sagan-rules/main/rules.yaml'
		},
		meer => {
			multi_instance => 0,
			config_base    => '/usr/local/etc/meer/',
			instances      => '',
			enable         => 0,
		},
		cape => {
			enable => 0,
		},
		mariadb => {
			enable => 0,
		},
		apache2 => {
			enable  => 0,
			version => '2.4',
			logdir  => '/var/log/apache',
		},
		chronyd => {
			enable => 0,
		},
		zfs => {
			enable => 0,
		},
		squid => {
			enable => 0,
		},
		proxy => {
			ftp   => '',
			http  => '',
			https => '',
		},
		cron => {
			enable   => 1,
			includes => [],
		},
		apt => {
			proxy_https => '',
			proxy_http  => '',
			proxy_ftp   => '',
			global      => 0,
		},
		perl => {
			modules         => [],
			cpanm           => 0,
			pkgs_optional   => [],
			pkgs_always_try => 1,
			pkgs_require    => [],
			cpanm_home      => undef,
		},
		systemd => {
			auto     => {},
			journald => {},
		},
		xeno_build => {
			build_dir => '/tmp',
		},
		nss_pam => {
			nscd_enable                   => 0,
			uri                           => '',
			base                          => '',
			ldap_version                  => 3,
			scope                         => 'sub',
			base_group                    => '',
			base_passwd                   => '',
			base_shadow                   => '',
			scope_group                   => 'sub',
			scope_hosts                   => 'sub',
			bind_timelimit                => '',
			timelimit                     => '',
			bindpw                        => '',
			binddn                        => '',
			rootpwmoddn                   => '',
			rootpwmodpw                   => '',
			ssl                           => '',
			tls_cacertdir                 => '',
			tls_cacertfile                => '',
			tls_crlcheck                  => '',
			tls_randfile                  => '',
			tls_ciphers                   => '',
			tls_cert                      => '',
			tls_key                       => '',
			filter_passwd                 => '',
			filter_shadow                 => '',
			filter_group                  => '',
			map_passwd_uid                => '',
			map_passwd_gidNumber          => '',
			map_passwd_uidNumber          => '',
			map_passwd_userPassword       => '',
			map_passwd_homeDirectory      => '',
			map_passwd_gecos              => '',
			map_passwd_loginShell         => '',
			map_group_member              => '',
			map_group_gidNumber           => '',
			map_group_cn                  => '',
			map_shadow_uid                => '',
			map_shadow_userPassword       => '',
			map_shadow_shadowLastChange   => '',
			pagesize                      => '',
			referrals                     => '',
			idle_timelimit                => '',
			nss_initgroups_ignoreusers    => '',
			nss_min_uid                   => '',
			nss_uid_offset                => '',
			nss_gid_offset                => '',
			nss_nested_groups             => '',
			nss_getgrent_skipmembers      => '',
			nss_disable_enumeration       => '',
			validnames                    => '',
			ignorecase                    => '',
			pam_authc_ppolicy             => '',
			pam_authc_search              => '',
			pam_authz_search              => '',
			pam_password_prohibit_message => '',
			cache                         => '',
			sasl_mech                     => '',
			sasl_realm                    => '',
			sasl_authcid                  => '',
			sasl_authzid                  => '',
			sasl_secprops                 => '',
			sasl_canonicalize             => '',
			krb5_ccname                   => '',
			dref                          => '',
		},
		sneck => {
			enable => 0,
			vars   => {},
			tests  => {},
		},
		env  => {},
		snmp => {
			community         => 'public',
			extend_env        => 'PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin LC_ALL=C',
			syslocation       => '',
			syscontact        => '',
			extend_base_dir   => '/usr/local/etc/snmp',
			config_file       => '/usr/local/etc/snmpd.conf',
			extend_avail_dir  => '',
			listen_types      => ['array'],
			listen_array      => [ 'udp:161', 'tcp:161' ],
			listen_file       => '',
			listen_script     => '',
			v3_limited_enable => '0',
			v3_limited_name   => '',
			v3_limited_pass   => '',
			extends           => {
				smart => {
					enable                 => 0,
					cache                  => '/var/cache/smart',
					use_cache              => 0,
					nightly_test_enable    => 1,
					nightly_test           => 'long',
					config                 => '/usr/local/etc/smart-extend.conf',
					additional_update_args => '',
				},
				systemd            => { enable => 0, cache => '/var/cache/systemd.extend', use_cache => 1 },
				mysql              => { enable => 0, host  => '127.0.0.1', port => '3306', ssl => 0, timeout => 0, },
				sneck              => { enable => 0, },
				bind               => { enable => 0, },
				borgbackup         => { enable => 0, },
				suricata_extract   => { enable => 0, },
				suricata           => { enable => 0, args => '', },
				sagan              => { enable => 0, args => '', },
				hv_monitor         => { enable => 0, },
				fail2ban           => { enable => 0, },
				supvervisord       => { enable => 0, },
				linux_softnet_stat => { enable => 0, },
				opensearch         => { enable => 0, host     => '127.0.0.1', port => 9200 },
				osupdate           => { enable => 1, interval => '*/5 * * * *', },
				privoxy            => { enable => 0, log      => '/var/log/privoxy/logfile' },
				chronyd            => { enable => 0, },
				zfs                => { enable => 0, },
				squid              => { enable => 0, },
				ifAlias            => { enable => 0, },
				ntp_client         => { enable => 0, },
				mojo_cape_submit   => { enable => 0, },
				mdadm              => { enable => 0, },
				distro             => { enable => 1, },
				logsize            => {
					enable          => 0,
					remote          => 0,
					remote_sub_dirs => 0,
					remote_exclude  => [ 'achive', ],
					suricata_flows  => 1,
					suricata_base   => 1,
					sagan_base      => 0,
					apache2         => 1,
					var_log         => 1,
				},
			},
		},
	};

	#	my $host_info=Rex::Hardware::Host->get();

	if ( $^O eq 'linux' ) {
		$config->{suricata}{config_base}            = '/etc/suricata';
		$config->{snmp}{extend_base_dir}            = '/etc/snmp/';
		$config->{snmp}{config_file}                = '/etc/snmp/snmpd.conf';
		$config->{snmp}{linux_softnet_stat}{enable} = 1;

		#		if ($host_info->{operating_system} eq 'Debian' || $host_info->{operating_system} eq 'Ubuntu') {
		#		}
	} elsif ( $^O eq 'freebsd' ) {
		$config->{suricata}{base_fill_in}{e_defaultruledir} = '/var/lib/suricata/rules';
	}

	$config->{suricata}{update}{disable_file} = $config->{suricata}{config_base} . '/disable.conf';
	$config->{suricata}{update}{enable_file}  = $config->{suricata}{config_base} . '/enable.conf';
	$config->{suricata}{update}{modify_file}  = $config->{suricata}{config_base} . '/modify.conf';
	$config->{suricata}{update}{drop_file}    = $config->{suricata}{config_base} . '/drop.conf';
	$config->{suricata}{update}{conf_file}    = $config->{suricata}{config_base} . '/suricata.yaml';
	$config->{suricata}{update}{update_file}  = $config->{suricata}{config_base} . '/update.yaml';

	return $config;
} ## end sub get

1;
