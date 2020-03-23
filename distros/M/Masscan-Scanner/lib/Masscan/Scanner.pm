package Masscan::Scanner;
use strict;
use warnings;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;
use File::Spec;
use File::Temp;
use IPC::Open3;
use Symbol 'gensym';
use JSON;
use Net::DNS;
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use Data::Validate::Domain qw(is_domain);
use Term::ANSIColor qw(:constants);
use Log::Log4perl qw(:easy);
use Try::Catch;
use Data::Dumper;

# ABSTRACT: A Perl module which helps in using the masscan port scanner.

has hosts =>
(
    is       => 'rw',
    isa      => ArrayRef,
    required => 0,
    default  => sub{[]},
);

has ports =>
(
    is       => 'rw',
    isa      => ArrayRef,
    required => 0,
    default  => sub{[]},
);

has arguments =>
(
    is       => 'rw',
    isa      => ArrayRef,
    required => 0,
    default  => sub{[]},
);

has binary =>
(
    is       => 'rw',
    isa      => Str,
    required => 0,
    default  => sub{_find_binary()},
    lazy     => 1,
);

has command_line =>
(
    is       => 'rw',
    isa      => Str,
    required => 0,
    lazy     => 1,
);

has scan_results_file =>
(
    is       => 'rw',
    isa      => Str,
    required => 0,
    default  => sub{_tmp_file()},
    lazy     => 1,
);

has sudo =>
(
    is       => 'rw',
    isa      => Int,
    required => 0,
    default  => 0,
);

has verbose =>
(
    is       => 'rw',
    isa      => Int,
    required => 0,
    default  => 0,
);

has name_servers =>
(
    is       => 'rw',
    isa      => ArrayRef,
    required => 0,
    default  => sub{['1.1.1.1', '2606:4700:4700::1111', '1.0.0.1', '2606:4700:4700::1001', '8.8.8.8', '2001:4860:4860::8888', '8.8.4.4', '2001:4860:4860::8844']},
);

sub add_host
{
    my $self = shift;
    my $host = shift;

    return ($self->_is_valid_host($host)) ? push($self->hosts->@*, $host) : 0;
}

sub add_port
{
    my $self = shift;
    my $port = shift;

    return ($self->_is_valid_port($port)) ? push($self->ports->@*, $port) : 0;
}

sub add_argument
{
    my $self = shift;
    my $arg  = shift;

    return push($self->arguments->@*, $arg);
}

sub scan
{
    my $self   = shift;
    my $binary = $self->binary;
    my $hosts  = $self->_aref_to_str($self->_hosts_to_ips($self->hosts), 'hosts');
    my $ports  = $self->_aref_to_str($self->ports, 'ports');
    my $fstore = $self->scan_results_file;
    my $args   = $self->_aref_to_str($self->arguments, 'args') || '';
    my $sudo   = ($self->sudo) ? $self->_find_binary('sudo') : '';
    my $cmd    = "$sudo $binary $args -p $ports $hosts";

    $self->_info('Starting masscan');
    $self->_debug("Command: '$cmd'");

    $self->command_line($cmd);
    $self->_error('masscan not found') && die if (!$binary || $binary !~ m{masscan$}xmi);

    $self->_info('Attempting to run command');
    my $scan = $self->_run_cmd($cmd . " -oJ $fstore");
    $self->_info(($scan->{success}) ? 'Command executed successfully.': "Command has failed: $scan->{stderr}");

    return ($scan->{success}) ? 1 : 0;
}

sub scan_results
{
    my $self = shift;
    my $cmd  = $self->command_line;
    my $sres = $self->_from_json($self->_slurp_file($self->scan_results_file));
    my %up_hosts;

    map{$up_hosts{$_->{ip}} = 1}($sres->@*);
    $self->_info('Collating scan results');

    return {
                masscan      => {
                                    command_line => $cmd,
                                    scan_stats   => {
                                                        total_hosts => scalar($self->hosts->@*),
                                                        up_hosts    => scalar(%up_hosts),
                                                    },
                                },
                scan_results => $sres,
           }
}

# internal method _run_cmd
# Runs a system command and slurps up the results.
#
# Returns hashref containing STDOUT, STDERR and if
# the command ran successfully.
sub _run_cmd
{
    my $self = shift;
    my $cmd  = shift;

    my ($stdin, $stdout, $stderr);
    $stderr = gensym;
    my $pid = open3($stdin, $stdout, $stderr, $cmd);
    waitpid($pid, 0);

    return {
                stdout  => $self->_slurp($stdout),
                stderr  => $self->_slurp($stderr),
                success => (($? >> 8) == 0) ? 1 : 0,
           }
}

# internal method _slurp_file
# Given a path to a file this will read the entire contents of said file into
# memory.
#
# Returns entire content of file as a Str.
sub _slurp_file
{
    my $self = shift;
    my $path = shift;

    $self->_debug("Slurping up file: '$path'");

    open(my $fh, '<', $path) || die $!;
        my $data = $self->_slurp($fh);
    close($fh);

    return $data;
}

# internal method _slurp
# Given a glob we'll slurp that all up into memory.
#
# Returns entire content as a Str.
sub _slurp
{
    my $self = shift;
    my $glob = shift;

    $/ = undef;
    return (<$glob> || undef)
}

# internal method _tmp_file
# Generates a tempoary file where results can be stored.
#
# Returns full path to temp file.
sub _tmp_file
{
    my $self = shift;
    my $fh   = File::Temp->new();

    return $fh->filename;
}

# internal method _hosts_to_ips
# Ensures sanity of host list & resolves domain names to their IP address.
#
# Returns ArrayRef of valid Ip(s) which will be accepted by masscan.
sub _hosts_to_ips
{
    my $self  = shift;
    my $hosts = shift;
    my @sane_hosts;

    for my $host ($hosts->@*)
    {
        $self->_info("Checking '$host' sanity");

        if ($self->_is_valid_host($host))
        {
            if (is_domain($host))
            {
                push(@sane_hosts, $self->_resolve_dns_name($host)->[0]);
            }
            else
            {
                push(@sane_hosts, $host);
                $self->_info("Added '$host' to scan list");
            }
        }
    }

    return \@sane_hosts;
}

# internal method _is_valid_host
# Checks if a provided host is indeed a valid IP || domain.
#
# Returns True or False.
sub _is_valid_host
{
    my $self = shift;
    my $host = shift || 0;
    my $test = $host;

    $test =~ s/\/.*$//g;

    if (is_ipv4($test) || is_ipv6($test) || is_domain($test))
    {
        $self->_debug("'$host' is a valid IP address or domain name");
        return 1;
    }

    $self->_warn("'$host' is not a valid IP address or domain name");
    return 0;
}

# internal method _is_valid_port
# Checks if a provided is valid in terms of what masscan will accept. This can
# look like a single port Int like "80" or a port range like "1-80".
#
# Returns True or False.
sub _is_valid_port
{
    my $self = shift;
    my $port = shift || 0;

    if ($port =~ m{^\d+$}xm || $port =~ m{^\d+-\d+$}xm)
    {
        $self->_debug("'$port' is valid port number or port range");
        return 1;
    }

    $self->_warn("'$port' is not valid port number or port range");
    return 0;
}

# internal method _aref_to_str
# When this module is invoked the hosts and ports to be scanned are provided as
# an ArrayRef. This method takes the array and converts it into a valid Str
# Which will be accepted by masscan.
#
# Returns Str
sub _aref_to_str
{
    my $self = shift;
    my $aref = shift;
    my $type = shift;
    my $str;

    $self->_info("Converting '$type' ArrayRef to masscan cli format");

    for ($type)
    {
        m{hosts} && do {map{$str .= ($self->_is_valid_host($_)) ? $_ . ',' : ''}($aref->@*); last};
        m{ports} && do {map{$str .= ($self->_is_valid_port($_)) ? $_ . ',' : ''}($aref->@*); last};
        m{args}  && do {map{$str .= $_ . ' '}($aref->@*); last};
    }

    $str =~ s/,$//g;
    $str =~ s/\s+$//g;

    $self->_debug("ArrayRef to masscan cli format: '$str'");

    return $str;
}

# internal method _from_json
# Does what it implies. Will convert JSON format into a Perl data structure.
#
# Returns Perl data structure.
sub _from_json
{
    my $self = shift;
    my $data = shift;

    try
    {
        my $json = JSON->new->utf8->space_after->allow_nonref->convert_blessed->relaxed(1);
        $self->_info('Converting results from JSON to Perl data structure');

        return $json->decode($data);
    }
    catch
    {
        return [];
    }
}

# internal method _find_binary
# If masscan is within the users path then we should be able to find it.
#
# Returns full path to masscan binary
sub _find_binary
{
    my $self   = shift;
    my $binary = shift || 'masscan';

    local($_);

    my $sep = ($^O =~ /Win/) ? ';' : ':';

    for my $dir (split($sep, $ENV{'PATH'}))
    {
        opendir(my $dh, $dir) || next;
        my @files = (readdir($dh));
        closedir($dh);

        my $path;

        for my $file (@files)
        {
            next unless $file =~ m{^$binary(?:.exe)?$};
            $path = File::Spec->catfile($dir, $file);
            next unless -r $path && (-x _ || -l _);
            return $path;
            last $dh;
        }
    }
}

# internal method _log
# Sets up logging.
#
# Returns logger Object.
sub _log
{
    my $self = shift;

    ($self->verbose) ? Log::Log4perl->easy_init($DEBUG) : Log::Log4perl->easy_init($WARN);

    return Log::Log4perl->get_logger(__PACKAGE__);
}

# internal method _debug
# prints debug logs.
sub _debug
{
    my $self   = shift;
    my $msg    = shift;
    my $logger = $self->_log;

    $logger->debug(MAGENTA, '[DEBUG] ' . $msg, RESET);

    return;
}

# internal method _info
# prints info logs.
sub _info
{
    my $self   = shift;
    my $msg    = shift;
    my $logger = $self->_log;

    $logger->info(GREEN, '[INFO] ' . $msg, RESET);

    return;
}

# internal method _warn
# prints warn logs.
sub _warn
{
    my $self   = shift;
    my $msg    = shift;
    my $logger = $self->_log;

    $logger->warn(YELLOW, '[WARN] ' . $msg, RESET);

    return;
}

# internal method _error
# prints error logs.
sub _error
{
    my $self   = shift;
    my $msg    = shift;
    my $logger = $self->_log;

    $logger->warn(RED, '[ERROR] ' . $msg, RESET);

    return;
}

# internal method _resolve_dns_name
# Given a domain name this method will attempt to resolve the name to it's
# IP(s).
#
# Returns ArrayRef of IP(s).
sub _resolve_dns_name
{
    my $self = shift;
    my $name = shift;
    my @ips;

    $self->_info("Getting IP address for '$name'");

    try
    {
        my $resolver = new Net::DNS::Resolver();
        $resolver->retry(3);
        $resolver->tcp_timeout(4);
        $resolver->udp_timeout(4);
        $resolver->nameservers($self->name_servers->@*);
        my $res = $resolver->search($name, 'A');

        for my $answer ($res->answer)
        {
            for my $ip ($answer->address)
            {
                if ($answer->can('address'))
                {
                    push(@ips, $ip);
                }
            }
        }
    }
    catch
    {
        $self->_warn("Could not get IP(s) for '$name'");
        return [];
    };

    return \@ips;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Masscan::Scanner - A Perl module which helps in using the masscan port scanner.

=head1 VERSION

version 20200322.230436

=head1 SYNOPSIS

    use Masscan::Scanner;

    my @hosts     = qw('::1', '127.0.0.1');
    my @ports     = qw('22', '80', '443', '1-100');
    my @arguments = qw('--banners');

    my $mas = Masscan::Scanner->new(hosts => \@hosts, ports => \@ports, arguments => \@arguments);

    # Add extra hosts or ports
    $mas->add_host('10.0.0.1');
    $mas->add_host('10.0.0.0/24');
    $mas->add_port(25);
    $mas->add_port(110);

    # Can add port ranges too
    $mas->add_port('1024-2048');
    $mas->add_port('3000-65535');

    # Can add domains but will incur a performance penalty hence IP(s) and CIDR(s) recommended.
    $mas->add_host('averna.id.au');
    $mas->add_host('duckduckgo.com');

    # It is usually required that masscan is run as a privilaged user.
    # Obviously this module can be successfully run as the root user.
    # However, if this is being run by an unprivilaged user then sudo can be enabled.
    #
    # PLEASE NOTE: This module assumes the user can run the masscan command without
    # providing their password. Usually this is achieved by permitting the user to
    # run masscan within the /etc/sudoers file like so:a
    #
    # In /etc/sudoers: user averna = (root) NOPASSWD: /usr/bin/masscan
    $mas->sudo(1);

    # Turn on verbose mode
    # Default is off
    $mas->verbose(1);

    # Add extra masscan arguments
    $mas->add_argument('--rate 100000');

    # Set the full path to masscan binary
    # Default is the module will automatically find the binary full path if it's
    # withing the users environment path.
    $mas->binary('/usr/bin/masscan');

    # Set the name servers to be used for DNS resolution
    # Default is to use a list of public DNS servers
    $mas->name_servers(['192.168.0.100', '192.168.0.101']);

    # Will initiate the masscan.
    # If the scan is successful returns True otherwise returns False.
    my $scan = $mas->scan;

    # Returns the scan results
    my $res = $mas->scan_results if ($scan);

=head1 METHODS

=head2 add_host

    This method allows the addition of a host to the host list to be scaned.

    my $mas = Masscan::Scanner->new();
    $mas->add_host('127.0.0.1');

=head2 add_port

    This method allows the addition of a port or port range to the port list to be scaned.

    my $mas = Masscan::Scanner->new();
    $mas->add_port(443);
    $mas->add_port('1-65535');

=head2 add_argument

    This method allows the addition of masscan command line arguments.

    my $mas = Masscan::Scanner->new(hosts => ['127.0.0.1', '10.0.0.1'], ports => [80. 443]);
    $mas->add_argument('--banners');
    $mas->add_argument('--rate 100000');

=head2 scan

    Will initiate the scan of what hosts & ports have been provided.
    Returns true fi the scan was successful otherwise returns false.

    my $mas = Masscan::Scanner->new();
    $mas->hosts(['127.0.0.1', '::1']);
    $mas->ports(['22', '80', '443']);
    $mas->add_port('1024');

    $mas->scan;

=head2 scan_results

    Returns the result of the masscan as a Perl data structure.

    my $mas = Masscan::Scanner->new();
    $mas->hosts(['127.0.0.1', '::1']);
    $mas->ports(['22', '80', '443']);
    $mas->add_port('1024');

    my $scan = $mas->scan;

    if ($scan)
    {
        my $res = $mas->scan_results;
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

=head1 AUTHOR

Sarah Fuller <averna@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Sarah Fuller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
