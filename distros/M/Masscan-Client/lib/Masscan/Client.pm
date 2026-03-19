package Masscan::Client;
use strict;
use warnings;
use 5.020;
use Moose;
use MooseX::AttributeShortcuts;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(:all);
use MooseX::Types::Structured qw(:all);
use Carp;
use English qw(-no_match_vars);
use File::Spec;
use File::Temp;
use IPC::Open3;
use POSIX qw(WEXITSTATUS);
use Symbol 'gensym';
use JSON;
use Net::DNS;
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use Data::Validate::Domain qw(is_domain);
use Log::Log4perl qw(:easy);
use Log::Log4perl::Appender::ScreenColoredLevels::UsingMyColors;
use Try::Catch;
use Data::Dumper;
use namespace::autoclean;

our $VERSION = '0.2';

has hosts => (
    is       => 'rw',
    isa      => ArrayRef,
    required => 0,
    default  => sub { [] },
);

has ports => (
    is       => 'rw',
    isa      => ArrayRef,
    required => 0,
    default  => sub { [] },
);

has arguments => (
    is       => 'rw',
    isa      => ArrayRef,
    required => 0,
    default  => sub { [] },
);

has binary => (
    is       => 'rw',
    isa      => Str,
    required => 0,
    builder  => '_build_binary',
    lazy     => 1,
);

has command_line => (
    is       => 'rw',
    isa      => Str,
    required => 0,
);

has scan_results_file => (
    is       => 'rw',
    isa      => Str,
    required => 0,
    builder  => 'build_scan_results_file',
    lazy     => 1,
);

has sudo => (
    is       => 'rw',
    isa      => Int,
    required => 0,
    default  => 0,
);

has verbose => (
    is       => 'rw',
    isa      => Int,
    required => 0,
    default  => 0,
);

has logger => (
    is       => 'ro',
    isa      => Object,
    required => 0,
    builder  => 'build_logger',
    lazy     => 1,
);

has name_servers => (
    is       => 'rw',
    isa      => ArrayRef,
    required => 0,
    builder  => 'build_name_servers',
);

sub add_host {
    my ($self, $host) = @_;

    if (!$self -> _is_valid_host($host)) {
        return 0;
    }

    return push $self -> hosts -> @*, $host;
}

sub add_port {
    my ($self, $port) = @_;

    if (!$self -> _is_valid_port($port)) {
        return 0;
    }

    return push $self -> ports -> @*, $port;
}

sub add_argument {
    my ($self, $arg) = @_;

    return push $self -> arguments -> @*, $arg;
}

sub scan {
    my ($self) = @_;
    my $binary = $self -> binary;
    my $hosts  = $self -> _aref_to_str(
        $self -> _hosts_to_ips($self -> hosts),
        'hosts'
    );
    my $ports  = $self -> _aref_to_str($self -> ports, 'ports');
    my $fstore = $self -> scan_results_file;
    my $args   = $self -> _aref_to_str($self -> arguments, 'args');
    my $sudo   = q{};

    if (!$args) {
        $args = q{};
    }

    if ($self -> sudo) {
        $sudo = $self -> _build_binary('sudo');
    }

    my $cmd = "$sudo $binary $args -p $ports $hosts";

    $self -> logger -> info('Starting masscan');
    $self -> logger -> debug("Command: $cmd");

    $self -> command_line($cmd);

    if (!$binary || $binary !~ m{masscan$}xmsi) {
        $self -> logger -> fatal('masscan not found');
        croak;
    }

    $self -> logger -> info('Attempting to run command');
    my $scan = $self -> _run_cmd($cmd . " -oJ $fstore");

    if ($scan -> {success}) {
        $self -> logger -> info('Command executed successfully');
    }

    if (!$scan -> {success}) {
        $self -> logger -> error(
            "Command has failed: $scan -> {stderr} "
                . 'Ensure root or sudo permissions'
        );
    }

    if ($scan -> {success}) {
        return 1;
    }

    return 0;
}

sub scan_results {
    my ($self) = @_;
    my $cmd  = $self -> command_line;
    my $sres = $self -> _from_json(
        $self -> _slurp_file($self -> scan_results_file)
    );
    my %up_hosts;

    if (!$sres) {
        $self -> logger -> warn('No results');
        $sres = [];
    }

    for my $result ($sres -> @*) {
        $up_hosts{$result -> {ip}} = 1;
    }

    $self -> logger -> info('Collating scan results');

    return {
        masscan      => {
            command_line => $cmd,
            scan_stats   => {
                total_hosts => scalar($self -> hosts -> @*),
                up_hosts    => scalar(keys %up_hosts),
            },
        },
        scan_results => $sres,
    };
}

sub _run_cmd {
    my ($self, $cmd) = @_;

    my ($stdin, $stdout, $stderr);
    $stderr = gensym;
    my $pid = open3($stdin, $stdout, $stderr, $cmd);
    my $waited_pid = waitpid $pid, 0;

    my $success = 0;
    if ($waited_pid == $pid && WEXITSTATUS($CHILD_ERROR) == 0) {
        $success = 1;
    }

    return {
        stdout  => $self -> _slurp($stdout),
        stderr  => $self -> _slurp($stderr),
        success => $success,
    };
}

sub _slurp_file {
    my ($self, $path) = @_;
    my $file_data;
    my $file_read_succeeded = 0;

    $self -> logger -> debug("Slurping up file: $path");

    try {
        open(my $fh, '<', $path)
            || croak("Unable to open $path: $ERRNO");
        $file_data = $self -> _slurp($fh);
        if (!close $fh) {
            croak("Unable to close $path: $ERRNO");
        }
        $file_read_succeeded = 1;
    }
    catch {
        $self -> logger -> warn(
            "$ERRNO. " . 'Most likely scan was not successful.'
        );
    };

    if ($file_read_succeeded) {
        return $file_data;
    }

    return;
}

sub _slurp {
    my ($self, $glob) = @_;

    local $INPUT_RECORD_SEPARATOR = undef;
    return scalar <$glob>;
}

sub _hosts_to_ips {
    my ($self, $hosts) = @_;
    my @sane_hosts;

    for my $host ($hosts -> @*) {
        $self -> logger -> info("Checking $host sanity");

        if ($self -> _is_valid_host($host)) {
            if (is_domain($host)) {
                my $ips = $self -> _resolve_dns($host);
                for my $ip ($ips -> @*) {
                    push @sane_hosts, $ip;
                }
            }

            if (!is_domain($host)) {
                push @sane_hosts, $host;
                $self -> logger -> info("Added $host to scan list");
            }
        }
    }

    return \@sane_hosts;
}

sub _is_valid_host {
    my ($self, $host) = @_;
    my $target = $host || 0;

    $target =~ s{\/.*$}{}xmsg;

    if (is_ipv4($target) || is_ipv6($target) || is_domain($target)) {
        $self -> logger -> debug(
            "$host is a valid IP address or domain name"
        );
        return 1;
    }

    $self -> logger -> warn(
        "$host is not a valid IP address or domain name"
    );
    return 0;
}

sub _is_valid_port {
    my ($self, $port) = @_;
    my $target = $port || 0;

    if ($target =~ m{^\d+$}xms || $target =~ m{^\d+-\d+$}xms) {
        $self -> logger -> debug(
            "$port is valid port number or port range"
        );
        return 1;
    }

    $self -> logger -> warn(
        "$port is not valid port number or port range"
    );
    return 0;
}

sub _aref_to_str {
    my ($self, $aref, $type) = @_;
    my $str = q{};

    $self -> logger -> info("Converting $type ArrayRef to masscan cli format");

    if ($type eq 'hosts') {
        my @hosts;
        for my $host ($aref -> @*) {
            if ($self -> _is_valid_host($host)) {
                    push @hosts, $host;
            }
        }
        return join q{,}, @hosts;
    }

    if ($type eq 'ports') {
        my @ports;
        for my $port ($aref -> @*) {
            if ($self -> _is_valid_port($port)) {
                    push @ports, $port;
            }
        }
        return join q{,}, @ports;
    }

    if ($type eq 'args') {
        for my $arg ($aref -> @*) {
            $str .= $arg . q{ };
        }
        $str =~ s/\s+$//xms;
        return $str;
    }

    return $str;
}

sub _from_json {
    my ($self, $json) = @_;
    my $decoded_data = [];

    if (!$json) {
        return [];
    }

    try {
        $decoded_data = decode_json($json);
    }
    catch {
        $self -> logger -> warn('Unable to parse scan results JSON');
        $decoded_data = [];
    };

    return $decoded_data;
}

sub _resolve_dns {
    my ($self, $domain) = @_;
    my $resolver = Net::DNS::Resolver -> new;
    my @ips;

    if ($self -> name_servers) {
        $resolver -> nameservers($self -> name_servers -> @*);
    }

    if ($domain) {
        my $query = $resolver -> search($domain);
        if ($query) {
            for my $answer ($query -> answer) {
                if ($answer -> type eq 'A') {
                    push @ips, $answer -> address;
                }

                if ($answer -> type eq 'AAAA') {
                    push @ips, $answer -> address;
                }
            }
        }

        if (!$query) {
            return [];
        }
    }

    if (!@ips) {
        return [];
    }

    return \@ips;
}

sub build_name_servers {
    my ($self) = @_;

    return [
        '1.1.1.1',
        '2606:4700:4700::1111',
        '1.0.0.1',
        '2606:4700:4700::1001',
        '8.8.8.8',
        '2001:4860:4860::8888',
        '8.8.4.4',
        '2001:4860:4860::8844'
    ];
}

sub build_scan_results_file {
    my ($self) = @_;
    my $handle = File::Temp -> new();

    return $handle -> filename;
}

sub _build_binary {
    my ($self, $binary) = @_;

    if (!$binary) {
        $binary = 'masscan';
    }

    my $sep = q{:};
    if ($OSNAME =~ m{Win}xms) {
        $sep = q{;};
    }

    for my $dir (split $sep, $ENV{PATH}) {
        my $dh;
        if (!opendir $dh, $dir) {
            next;
        }
        my @files = readdir $dh;
        if (!closedir $dh) {
            next;
        }

        for my $file (@files) {
            if ($file !~ m{^$binary(?:[.]exe)?$}xms) {
                next;
            }
            my $path = File::Spec -> catfile($dir, $file);
            if (!(-r $path && (-x _ || -l _))) {
                next;
            }
            return $path;
        }
    }

    return;
}

sub build_logger {
    my ($self) = @_;
    my $conf = _build_log_conf('OFF');

    if ($self -> verbose) {
        $conf = _build_log_conf('DEBUG');
    }

    Log::Log4perl -> init(\$conf);

    return Log::Log4perl -> get_logger(__PACKAGE__);
}

sub _build_log_conf {
    my ($level) = @_;

    return <<"__LOG_CONF__";
log4perl.logger                         = TRACE, Screen
log4perl.appender.Screen                = Log::Log4perl::Appender::ScreenColoredLevels::UsingMyColors
log4perl.appender.Screen.Threshold      = $level
log4perl.appender.Screen.stderr         = 0
log4perl.appender.Screen.utf8           = 1
log4perl.appender.Screen.layout         = Log::Log4perl::Layout::PatternLayout::Multiline
log4perl.appender.Screen.color.trace    = cyan
log4perl.appender.Screen.color.debug    = magenta
log4perl.appender.Screen.color.info     = green
log4perl.appender.Screen.color.warn     = yellow
log4perl.appender.Screen.color.error    = red
log4perl.appender.Screen.color.fatal    = bright_red
log4perl.appender.Screen.layout.ConversionPattern = %d{yyyy-MM-dd HH:mm} %M (%L) [%p] %m{indent=4} %n
__LOG_CONF__
}

__PACKAGE__ -> meta -> make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Masscan::Client - A Perl module which helps in using the masscan port scanner.

=head1 VERSION

version 0.2

=head1 SYNOPSIS

    use Masscan::Client;

    my @hosts     = qw(::1 127.0.0.1);
    my @ports     = qw(22 80 443 1-100);
    my @arguments = qw(--banners);

    my $mas = Masscan::Client -> new(
        hosts     => \@hosts,
        ports     => \@ports,
        arguments => \@arguments
    );

    $mas -> add_host('10.0.0.1');
    $mas -> add_host('10.0.0.0/24');
    $mas -> add_port(25);
    $mas -> add_port(110);

    $mas -> add_port('1024-2048');
    $mas -> add_port('3000-65535');

    $mas -> add_host('averna.id.au');
    $mas -> add_host('duckduckgo.com');

    $mas -> sudo(1);

    $mas -> verbose(1);

    $mas -> add_argument('--rate 100000');

    $mas -> binary('/usr/bin/masscan');

    $mas -> name_servers(['192.168.0.100', '192.168.0.101']);

    my $scan = $mas -> scan;
    my $res;
    if ($scan) {
        $res = $mas -> scan_results;
    }

=head1 DESCRIPTION

Masscan::Client provides an object-oriented interface for building,
running, and parsing masscan scans from Perl code.

=head1 SUBROUTINES/METHODS

=head2 add_host

    This method allows the addition of a host to the host list to be scaned.

    my $mas = Masscan::Client -> new();
    $mas -> add_host('127.0.0.1');

=head2 add_port

    This method allows the addition of a port or port range to the port list to be scaned.

    my $mas = Masscan::Client -> new();
    $mas -> add_port(443);
    $mas -> add_port('1-65535');

=head2 add_argument

    This method allows the addition of masscan command line arguments.

    my $mas = Masscan::Client -> new(
        hosts => ['127.0.0.1', '10.0.0.1'],
        ports => [80, 443]
    );
    $mas -> add_argument('--banners');
    $mas -> add_argument('--rate 100000');

=head2 scan

    Will initiate the scan of what hosts & ports have been provided.
    Returns true fi the scan was successful otherwise returns false.

    my $mas = Masscan::Client -> new();
    $mas -> hosts(['127.0.0.1', '::1']);
    $mas -> ports(['22', '80', '443']);
    $mas -> add_port('1024');

    $mas -> scan;

=head2 scan_results

    Returns the result of the masscan as a Perl data structure.

    my $mas = Masscan::Client -> new();
    $mas -> hosts(['127.0.0.1', '::1']);
    $mas -> ports(['22', '80', '443']);
    $mas -> add_port('1024');

    my $scan = $mas -> scan;

    if ($scan) {
        my $res = $mas -> scan_results;
    }

=head1 SCAN RESULTS

    The scan_results method returns a data structure like so:

    {
        'scan_results' => [
                              {
                                'timestamp' => '1584816181',
                                'ip' => '10.0.0.1',
                                'ports' => [
                                             {
                                               'status' => 'open',
                                               'reason' => 'syn-ack',
                                               'port' => 443,
                                               'proto' => 'tcp',
                                               'ttl' => 60
                                             }
                                           ]
                              },
                              {
                                'timestamp' => '1584816181',
                                'ip' => '10.0.0.2',
                                'ports' => [
                                             {
                                               'reason' => 'syn-ack',
                                               'status' => 'open',
                                               'port' => 443,
                                               'ttl' => 60,
                                               'proto' => 'tcp'
                                             }
                                           ]
                              },
                              {
                                'ports' => [
                                             {
                                               'port' => 80,
                                               'ttl' => 60,
                                               'proto' => 'tcp',
                                               'reason' => 'syn-ack',
                                               'status' => 'open'
                                             }
                                           ],
                                'ip' => '10.0.0.1',
                                'timestamp' => '1584816181'
                              },
                              {
                                'ip' => '10.0.0.2',
                                'timestamp' => '1584816181',
                                'ports' => [
                                             {
                                               'port' => 80,
                                               'ttl' => 60,
                                               'proto' => 'tcp',
                                               'status' => 'open',
                                               'reason' => 'syn-ack'
                                             }
                                           ]
                              },
                              {
                                'timestamp' => '1584816181',
                                'ip' => '10.0.0.3',
                                'ports' => [
                                             {
                                               'reason' => 'syn-ack',
                                               'status' => 'open',
                                               'proto' => 'tcp',
                                               'ttl' => 111,
                                               'port' => 80
                                             }
                                           ]
                              },
                              {
                                'ports' => [
                                             {
                                               'ttl' => 111,
                                               'proto' => 'tcp',
                                               'port' => 443,
                                               'reason' => 'syn-ack',
                                               'status' => 'open'
                                             }
                                           ],
                                'timestamp' => '1584816181',
                                'ip' => '10.0.0.3'
                              }
                            ],
          'masscan' => {
                         'scan_stats' => {
                                           'total_hosts' => 4,
                                           'up_hosts' => 3
                                         },
                         'command_line' => '/usr/bin/masscan --rate 100000 --banners -p 22,80,443,61222,25 10.0.0.2,10.0.0.1,10.0.0.3,10.0.0.4'
                       }
    };

=head1 DIAGNOSTICS

The module logs warnings and errors through Log::Log4perl. Typical
diagnostics include invalid host or port input, missing masscan binary,
and JSON parsing failures in scan output.

=head1 CONFIGURATION AND ENVIRONMENT

The module discovers the masscan binary from the `PATH` environment
variable when not explicitly set. DNS lookups use configurable name
servers through the `name_servers` attribute.

=head1 DEPENDENCIES

Core dependencies include Moose, JSON, Net::DNS, Data::Validate::IP,
Data::Validate::Domain, Try::Catch, and Log::Log4perl.

=head1 INCOMPATIBILITIES

No known incompatibilities are documented.

=head1 BUGS AND LIMITATIONS

Scan execution depends on the external masscan binary and required
execution privileges in the runtime environment.

=head1 AUTHOR

Heitor Gouvea <hgouvea@cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Heitor Gouvea.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
