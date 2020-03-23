# Masscan-Scanner
Masscan::Scanner - A Perl module which helps in using the masscan port scanner.
## Install
```bash
$ cpanm -i Masscan::Scanner
```
## Usage
```perl
use Masscan::Scanner;

my $mas = Masscan::Scanner->new();
$mas->hosts(['199.232.32.174', '199.232.33.194']);
$mas->ports(['22', '80', '443']);
my @hosts     = qw('::1', '127.0.0.1');
my @ports     = qw('22', '80', '443', '1-100');
my @arguments = qw('--banners');

my $mas = Masscan::Scanner->new(hosts => \@hosts, ports => \@ports, arguments => \@arguments);

# Add extra hosts or ports
$mas->add_host('10.0.0.1');
$mas->add_host('10.0.0.0/24');

# Can add domains but will incur performance penalty hence IP(s) and CIDR(s) recommended.
$mas->add_host('averna.id.au');

$mas->add_port(25);

# Can add port ranges too
$mas->add_port('1024-2048');

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
$mas->add_argument('--banners');

$mas->scan;
# Set the full path to masscan binary
# Default is the module will automatically find the binary full path if it's
# withing the users environment variables
$mas->binary('/usr/bin/masscan');

# Set the name servers to be used for DNS resolution
# Default is to use a list of public DNS servers
$mas->name_servers(['192.168.0.100', '192.168.0.101]);

# Will initiate the masscan.
# If the scan is successful returns True otherwise returns False.
my $scan = $mas->scan;

my $res = $mas->scan_results;
# Returns the scan results
my $res = $mas->scan_results if ($scan);
```

## Scan Results
```perl
$VAR1 = {
          'scan_results' => [
{
    'scan_results' => [
                              {
                                'timestamp' => '1584816181',
                                'ip' => '10.0.0.1',
                                'ports' => [
                                             {
                                               'ttl' => 60,
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
                                           ],
                                'ip' => '199.232.33.194',
                                'timestamp' => '1584749838'
                                           ]
                              },
                              {
                                'ports' => [
                                             {
                                               'ttl' => 60,
                                               'reason' => 'syn-ack',
                                               'port' => 80,
                                               'ttl' => 60,
                                               'proto' => 'tcp',
                                               'reason' => 'syn-ack',
                                               'status' => 'open'
                                             }
                                           ],
                                'ip' => '199.232.32.174',
                                'timestamp' => '1584749838'
                                'ip' => '10.0.0.1',
                                'timestamp' => '1584816181'
                              },
                              {
                                'ip' => '10.0.0.2',
                                'timestamp' => '1584816181',
                                'ports' => [
                                             {
                                               'ttl' => 59,
                                               'reason' => 'syn-ack',
                                               'port' => 443,
                                               'port' => 80,
                                               'ttl' => 60,
                                               'proto' => 'tcp',
                                               'status' => 'open',
                                               'proto' => 'tcp'
                                               'reason' => 'syn-ack'
                                             }
                                           ],
                                'ip' => '199.232.32.174',
                                'timestamp' => '1584749838'
                                           ]
                              },
                              {
                                'timestamp' => '1584749838',
                                'timestamp' => '1584816181',
                                'ip' => '10.0.0.3',
                                'ports' => [
                                             {
                                               'ttl' => 59,
                                               'reason' => 'syn-ack',
                                               'port' => 80,
                                               'status' => 'open',
                                               'proto' => 'tcp'
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
                                'ip' => '199.232.33.194'
                                'timestamp' => '1584816181',
                                'ip' => '10.0.0.3'
                              }
                            ],
          'masscan' => {
                         'command_line' => '/usr/bin/masscan --rate 100000 --banners -p 22,80,443,25 199.232.32.174,199.232.33.194'
                         'scan_stats' => {
                                           'total_hosts' => 4,
                                           'up_hosts' => 3
                                         },
                         'command_line' => '/usr/bin/masscan --rate 100000 --banners -p 22,80,443,61222,25 10.0.0.2,10.0.0.1,10.0.0.3,10.0.0.4'
                       }
        };
};
```

## Author
Sarah Fuller <averna@cpan.org>

## Copyright and License
This software is copyright (c) 2020 by Sarah Fuller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
