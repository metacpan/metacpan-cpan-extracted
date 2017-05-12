package Devel::Platform::Info::Linux;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.16';

=encoding utf8

=head1 NAME

Devel::Platform::Info::Linux - Retrieve Linux platform metadata

=cut

#----------------------------------------------------------------------------

my %commands = (
    '_issue1'   => 'cat /etc/issue',
    '_issue2'   => 'cat /etc/.issue',
    '_uname'    => 'uname -a',
    '_lsb'      => 'lsb_release -a',
    'kname'     => 'uname -s',
    'kvers'     => 'uname -r',
    'osname'    => 'uname -o',
    'archname'  => 'uname -m',
);

my %default = ();

# http://en.wikipedia.org/wiki/Arch_Linux#Versions
my %archlinux = (
    '0.1'           => 'Homer',
    '0.2'           => 'Vega',
    '0.3'           => 'Firefly',
    '0.4'           => 'Dragon',
    '0.5'           => 'Nova',
    '0.6'           => 'Widget',
    '0.7'           => 'Wombat',
    '0.8'           => 'Voodoo',
    '2007.05'       => 'Duke',
    '2007.08'       => "Don't Panic",
    '2008.06'       => 'Overlord',
    '2009.02'       => '2009.02',
    '2009.08'       => '2009.08',
    '2010.05'       => '2010.05',
    '2011.08.19'    => '2011.08.19',
);

# previously CrunchBang Linux hasn't normally used codenames, however from
# version 10 they are using Debian releases as a base, and thus are using 
# Muppet Show characters to compliment the Toy Story characters as used by
# Debian.

my %crunch = (
    '8.04.02'       => 'Back in Black',
    '10'            => 'Statler',
    '11'            => 'Waldorf',
);

# http://en.wikipedia.org/wiki/Debian#Release_history
my %debian = (
    '1.1'       => 'buzz',
    '1.2'       => 'rex',
    '1.3'       => 'bo',
    '2.0'       => 'hamm',
    '2.1'       => 'slink',
    '2.2'       => 'potato',
    '3.0'       => 'woody',
    '3.1'       => 'sarge',
    '4.0'       => 'etch',
    '4.1'       => 'etch',
    '4.2'       => 'etch',
    '4.3'       => 'etch',
    '4.4'       => 'etch',
    '4.5'       => 'etch',
    '4.6'       => 'etch',
    '4.7'       => 'etch',
    '4.8'       => 'etch',
    '4.9'       => 'etch',
    '5.0'       => 'lenny',
    '5.1'       => 'lenny',
    '5.2'       => 'lenny',
    '5.3'       => 'lenny',
    '5.4'       => 'lenny',
    '5.5'       => 'lenny',
    '5.6'       => 'lenny',
    '5.7'       => 'lenny',
    '5.8'       => 'lenny',
    '5.9'       => 'lenny',
    '5.10'      => 'lenny',
    '6.0'       => 'squeeze',
    '6.1'       => 'squeeze',
    '6.2'       => 'squeeze',
    '6.3'       => 'squeeze',
    '6.4'       => 'squeeze',
    '6.5'       => 'squeeze',
    '6.6'       => 'squeeze',
    '6.7'       => 'squeeze',
    '6.8'       => 'squeeze',
    '6.9'       => 'squeeze',
    '6.10'      => 'squeeze',
    '7.0'       => 'wheezy',
    '7.1'       => 'wheezy',
    '7.2'       => 'wheezy',
    '7.3'       => 'wheezy',
    '7.4'       => 'wheezy',
    '7.5'       => 'wheezy',
    '7.6'       => 'wheezy',
    '7.7'       => 'wheezy',
    '7.8'       => 'wheezy',
    '7.9'       => 'wheezy',
    '7.10'      => 'wheezy',
    '8.0'       => 'jessie',
    '8.1'       => 'jessie',
    '8.2'       => 'jessie',
    '8.3'       => 'jessie',
    '8.4'       => 'jessie',
    '9.0'       => 'stretch',
    '10.0'      => 'buster',
);

# Fedora naming scheme is no longer used:
# https://lists.fedoraproject.org/pipermail/advisory-board/2013-October/012209.html
# "The Fedora Board is terminating Release Names as they are currently
# fashioned following Fedora 20."

# http://en.wikipedia.org/wiki/Fedora_%28operating_system%29#Version_history
my %fedora = (
    '1'         => 'Yarrow',
    '2'         => 'Tettnang',
    '3'         => 'Heidelberg',
    '4'         => 'Stentz',
    '5'         => 'Bordeaux',
    '6'         => 'Zod',
    '7'         => 'Moonshine',
    '8'         => 'Werewolf',
    '9'         => 'Sulphur',
    '10'        => 'Cambridge',
    '11'        => 'Leonidas',
    '12'        => 'Constantine',
    '13'        => 'Goddard',
    '14'        => 'Laughlin',
    '15'        => 'Lovelock',
    '16'        => 'Verne',
    '17'        => 'Beefy Miracle',
    '18'        => 'Spherical Cow',
    '19'        => q[Schrödinger's Cat],
    '20'        => 'Heisenbug',
);

# http://en.wikipedia.org/wiki/Mandriva_Linux#Versions
my %mandriva = (
    '5.1'       => 'Venice',
    '5.2'       => 'Leeloo',
    '5.3'       => 'Festen',
    '6.0'       => 'Venus',
    '6.1'       => 'Helios',
    '7.0'       => 'Air',
    '7.1'       => 'Helium',
    '7.2'       => 'Odyssey (called Ulysses during beta)',
    '8.0'       => 'Traktopel',
    '8.1'       => 'Vitamin',
    '8.2'       => 'Bluebird',
    '9.0'       => 'Dolphin',
    '9.1'       => 'Bamboo',
    '9.2'       => 'FiveStar',
    '10.0'      => 'Community and Official',
    '10.1'      => 'Community',
    '10.1'      => 'Official',
    '10.2'      => 'Limited Edition 2005',
    '2006.0'    => 'Mandriva Linux 2006',
    '2007'      => 'Mandriva Linux 2007',
    '2007.1'    => 'Mandriva Linux 2007 Spring',
    '2008.0'    => 'Mandriva Linux 2008',
    '2008.1'    => 'Mandriva Linux 2008 Spring',
    '2009.0'    => 'Mandriva Linux 2009',
    '2009.1'    => 'Mandriva Linux 2009 Spring',
    '2010.0'    => 'Mandriva Linux 2010 (Adélie)',
    '2010.1'    => 'Mandriva Linux 2010 Spring',
    '2010.2'    => 'Mandriva Linux 2010.2',
    '2011.0'    => 'Hydrogen',
);

# http://en.wikipedia.org/wiki/Red_Hat_Linux#Version_history
# http://fedoraproject.org/wiki/History_of_Red_Hat_Linux
my %redhat = (
    '0.8'       => 'Preview',
    '0.9'       => 'Halloween',
    '1.0'       => q{Mother's Day},
    '1.1'       => q{Mother's Day+0.1},
    '2.0'       => '',
    '2.1'       => '',
    '3.0.3'     => 'Picasso',
    '3.95'      => 'Rembrandt',
    '4.0'       => 'Colgate',
    '4.1'       => 'Vanderbilt',
    '4.2'       => 'Biltmore',
    '4.95'      => 'Thunderbird',
    '4.96'      => 'Mustang',
    '5.0'       => 'Hurricane',
    '5.1'       => 'Manhattan',
    '5.2'       => 'Apollo',
    '5.9'       => 'Starbuck',
    '6.0'       => 'Hedwig',
    '6.0.95'    => 'Lorax',
    '6.1'       => 'Cartman',
    '6.1.95'    => 'Piglet',
    '6.2'       => 'Zoot',
    '6.2.98'    => 'Pinstripe',
    '7'         => 'Guinness',
    '7.0.90'    => 'Fisher',
    '7.0.91'    => 'Wolverine',
    '7.1'       => 'Seawolf',
    '7.1.92'    => 'Roswell',
    '7.2'       => 'Enigma',
    '7.2.92'    => 'Skipjack',
    '7.3'       => 'Valhalla',
    '7.3.92'    => 'Limbo',
    '7.3.93'    => 'Limbo',
    '7.3.94'    => 'Null',
    '8.0'       => 'Psyche',
    '8.0.93'    => 'Phoebe',
    '9'         => 'Shrike',
    '9.0.93'    => 'Severn',
);

# http://en.wikipedia.org/wiki/Red_Hat_Enterprise_Linux#Version_history
my %rhel = (
    '2.1 AS'    => 'Pensacola',
    '2.1'       => 'Pensacola',
    '2.1.1'     => 'Pensacola',
    '2.1.2'     => 'Pensacola',
    '2.1.3'     => 'Pensacola',
    '2.1.4'     => 'Pensacola',
    '2.1.5'     => 'Pensacola',
    '2.1.6'     => 'Pensacola',
    '2.1.7'     => 'Pensacola',
    '2.1 ES'    => 'Panama',
    '3'         => 'Taroon',
    '3.0'       => 'Taroon',
    '3.1'       => 'Taroon',
    '3.2'       => 'Taroon',
    '3.3'       => 'Taroon',
    '3.4'       => 'Taroon',
    '3.5'       => 'Taroon',
    '3.6'       => 'Taroon',
    '3.7'       => 'Taroon',
    '3.8'       => 'Taroon',
    '3.9'       => 'Taroon',
    '4'         => 'Nahant',
    '4.1'       => 'Nahant',
    '4.2'       => 'Nahant',
    '4.3'       => 'Nahant',
    '4.4'       => 'Nahant',
    '4.5'       => 'Nahant',
    '4.6'       => 'Nahant',
    '4.7'       => 'Nahant',
    '4.8'       => 'Nahant',
    '4.9'       => 'Nahant',
    '5'         => 'Tikanga',
    '5.1'       => 'Tikanga',
    '5.2'       => 'Tikanga',
    '5.3'       => 'Tikanga',
    '5.4'       => 'Tikanga',
    '5.5'       => 'Tikanga',
    '5.6'       => 'Tikanga',
    '5.7'       => 'Tikanga',
    '5.8'       => 'Tikanga',
    '6'         => 'Santiago',
    '6.1'       => 'Santiago',
    '6.2'       => 'Santiago',
    '6.3'       => 'Santiago',
    '6.4'       => 'Santiago',
    '6.5'       => 'Santiago',
    '7'         => 'Maipo',
);

# http://en.wikipedia.org/wiki/Scientific_Linux
my %scientific = (
    '3.0.1'     => 'Feynman',
    '3.0.2'     => 'Feynman',
    '3.0.3'     => 'Feynman',
    '3.0.4'     => 'Feynman',
    '3.0.5'     => 'Feynman',
    '3.0.6'     => 'Feynman',
    '3.0.7'     => 'Feynman',
    '3.0.8'     => 'Feynman',
    '3.0.9'     => 'Legacy',
    '4.0'       => 'Beryllium',
    '4.1'       => 'Beryllium',
    '4.2'       => 'Beryllium',
    '4.3'       => 'Beryllium',
    '4.4'       => 'Beryllium',
    '4.5'       => 'Beryllium',
    '4.6'       => 'Beryllium',
    '4.7'       => 'Beryllium',
    '4.8'       => 'Beryllium',
    '4.9'       => 'Beryllium',
    '5.0'       => 'Boron',
    '5.1'       => 'Boron',
    '5.2'       => 'Boron',
    '5.3'       => 'Boron',
    '5.4'       => 'Boron',
    '5.5'       => 'Boron',
    '5.6'       => 'Boron',
    '5.7'       => 'Boron',
    '5.8'       => 'Boron',
    '5.9'       => 'Boron',
    '6.0'       => 'Carbon',
    '6.1'       => 'Carbon',
    '6.2'       => 'Carbon',
    '6.3'       => 'Carbon',
    '6.4'       => 'Carbon',
    '6.5'       => 'Carbon',
    '6.6'       => 'Carbon',
    '6.7'       => 'Carbon',
    '6.8'       => 'Carbon',
    '6.9'       => 'Carbon',
    '6.10'      => 'Carbon',
    '6.11'      => 'Carbon',
    '7.0'       => 'Nitrogen',
    '7.1'       => 'Nitrogen',
    '7.2'       => 'Nitrogen',
);

# http://en.wikipedia.org/wiki/Ubuntu_%28operating_system%29#Releases
my %ubuntu = (
    '4.10'      => 'Warty Warthog',
    '5.04'      => 'Hoary Hedgehog',
    '5.10'      => 'Breezy Badger',
    '6.06'      => 'Dapper Drake',
    '6.10'      => 'Edgy Eft',
    '7.04'      => 'Feisty Fawn',
    '7.10'      => 'Gutsy Gibbon',
    '8.04'      => 'Hardy Heron',
    '8.10'      => 'Intrepid Ibex',
    '9.04'      => 'Jaunty Jackalope',
    '9.10'      => 'Karmic Koala',
    '10.04'     => 'Lucid Lynx',
    '10.10'     => 'Maverick Meerkat',
    '11.04'     => 'Natty Narwhal',
    '11.10'     => 'Oneiric Ocelot',
    '12.04'     => 'Precise Pangolin',
    '12.10'     => 'Quantal Quetzal',
    '13.04'     => 'Raring Ringtail',
    '13.10'     => 'Saucy Salamander',
    '14.04'     => 'Trusty Tahr',
    '14.10'     => 'Utopic Unicorn',
    '15.04'     => 'Vivid Vervet',
    '15.10'     => 'Wily Werewolf',
    '16.04'     => 'Xenial Xerus',
);

my %distributions = (
    'Adamantix'                 => { codenames => \%default,                        files => [ qw( /etc/adamantix_version ) ] },
    'Annvix'                    => { codenames => \%default,                        files => [ qw( /etc/annvix-release ) ] },
    'Arch Linux'                => { codenames => \%archlinux,                      files => [ qw( /etc/arch-release ) ] },
    'Arklinux'                  => { codenames => \%default,                        files => [ qw( /etc/arklinux-release ) ] },
    'Aurox Linux'               => { codenames => \%default,                        files => [ qw( /etc/aurox-release ) ] },
    'BlackCat'                  => { codenames => \%default,                        files => [ qw( /etc/blackcat-release ) ] },
    'Cobalt'                    => { codenames => \%default,                        files => [ qw( /etc/cobalt-release ) ] },
    'Conectiva'                 => { codenames => \%default,                        files => [ qw( /etc/conectiva-release ) ] },
    'CrunchBang Linux'          => { codenames => \%crunch,                         files => [ qw( /etc/lsb-release-crunchbang /etc/lsb-release ) ] },
    'Debian'                    => { codenames => \%debian,     key => 'debian',    files => [ qw( /etc/debian_version /etc/debian_release ) ] },
    'Fedora Core'               => { codenames => \%fedora,     key => 'fedora',    files => [ qw( /etc/fedora-release ) ] },
    'Gentoo Linux'              => { codenames => \%default,    key => 'gentoo',    files => [ qw( /etc/gentoo-release ) ] },
    'Immunix'                   => { codenames => \%default,                        files => [ qw( /etc/immunix-release ) ] },
    'Knoppix'                   => { codenames => \%default,                        files => [ qw( /etc/knoppix_version ) ] },
    'Libranet'                  => { codenames => \%default,                        files => [ qw( /etc/libranet_version ) ] },
    'Linux-From-Scratch'        => { codenames => \%default,                        files => [ qw( /etc/lfs-release ) ] },
    'Linux-PPC'                 => { codenames => \%default,                        files => [ qw( /etc/linuxppc-release ) ] },
    'Mandrake'                  => { codenames => \%mandriva,                       files => [ qw( /etc/mandrake-release ) ] },
    'Mandriva'                  => { codenames => \%mandriva,                       files => [ qw( /etc/mandriva-release /etc/mandrake-release /etc/mandakelinux-release ) ] },
    'Mandrake Linux'            => { codenames => \%mandriva,                       files => [ qw( /etc/mandriva-release /etc/mandrake-release /etc/mandakelinux-release ) ] },
    'MkLinux'                   => { codenames => \%default,                        files => [ qw( /etc/mklinux-release ) ] },
    'Novell Linux Desktop'      => { codenames => \%default,                        files => [ qw( /etc/nld-release ) ] },
    'Pardus'                    => { codenames => \%default,    key => 'pardus',    files => [ qw( /etc/pardus-release ) ] },
    'PLD Linux'                 => { codenames => \%default,                        files => [ qw( /etc/pld-release ) ] },
    'Red Flag'                  => { codenames => \%default,    key => 'redflag',   files => [ qw( /etc/redflag-release ) ] },
    'Red Hat Enterprise Linux'  => { codenames => \%rhel,       key => 'rhel',      files => [ qw( /etc/redhat-release /etc/redhat_version ) ] },
    'Red Hat Linux'             => { codenames => \%redhat,     key => 'redhat',    files => [ qw( /etc/redhat-release /etc/redhat_version ) ] },
    'Scientific Linux'          => { codenames => \%scientific,                     files => [ qw( /etc/lsb-release ) ] },
    'Slackware'                 => { codenames => \%default,    key => 'slackware', files => [ qw( /etc/slackware-version /etc/slackware-release ) ] },
    'SME Server'                => { codenames => \%default,                        files => [ qw( /etc/e-smith-release ) ] },
    'Sun JDS'                   => { codenames => \%default,                        files => [ qw( /etc/sun-release ) ] },
    'SUSE Linux'                => { codenames => \%default,    key => 'suse',      files => [ qw( /etc/SuSE-release /etc/novell-release ) ] },
    'SUSE Linux ES9'            => { codenames => \%default,    key => 'suse',      files => [ qw( /etc/sles-release ) ] },
    'Tiny Sofa'                 => { codenames => \%default,                        files => [ qw( /etc/tinysofa-release ) ] },
    'Trustix Secure Linux'      => { codenames => \%default,                        files => [ qw( /etc/trustix-release ) ] },
    'TurboLinux'                => { codenames => \%default,                        files => [ qw( /etc/turbolinux-release ) ] },
    'Ubuntu Linux'              => { codenames => \%ubuntu,                         files => [ qw( /etc/lsb-release ) ] },
    'UltraPenguin'              => { codenames => \%default,                        files => [ qw( /etc/ultrapenguin-release ) ] },
    'UnitedLinux'               => { codenames => \%default,                        files => [ qw( /etc/UnitedLinux-release ) ] },
    'VA-Linux/RH-VALE'          => { codenames => \%default,                        files => [ qw( /etc/va-release ) ] },
    'Yellow Dog'                => { codenames => \%default,                        files => [ qw( /etc/yellowdog-release ) ] },
    'Yoper'                     => { codenames => \%default,                        files => [ qw( /etc/yoper-release ) ] },
);

my %version_pattern = (
    'gentoo'    => 'Gentoo Base System version (.*)',
    'debian'    => '(.+)',
    'suse'      => 'VERSION = (.*)',
    'fedora'    => 'Fedora Core release (\d+) \(',
    'redflag'   => 'Red Flag (?:Desktop|Linux) (?:release |\()(.*?)(?: \(.+)?\)',
    'redhat'    => 'Red Hat Linux release (.*) \(',
    'rhel'      => 'Red Hat Enterprise Linux(?: Server)? release (.*) \(',
    'slackware' => '^Slackware (.+)$',
    'pardus'    => '^Pardus (.+)$',
);

my %oslabel_pattern = (
    'suse'      => '^(\S+)',
    'rhel'      => '(Red Hat Enterprise Linux(?: Server)?) release (.*) \(',
);

#----------------------------------------------------------------------------

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;

    return $self;
}

sub get_info {
    my $self  = shift;

    for my $cmd (keys %commands) {
        $self->{cmds}{$cmd} = `$commands{$cmd} 2>/dev/null`;
        $self->{cmds}{$cmd} =~ s/\s+$//s;
        $self->{info}{$cmd} = $self->{cmds}{$cmd}   if($cmd !~ /^_/);
    }

    $self->{info}{osflag}       = $^O;
    $self->{info}{kernel}       = lc($self->{info}{kname}) . '-' . $self->{info}{kvers};

    $self->{info}{is32bit}      = $self->{info}{archname} !~ /_(64)$/ ? 1 : 0;
    $self->{info}{is64bit}      = $self->{info}{archname} =~ /_(64)$/ ? 1 : 0;

    if($self->{cmds}{'_lsb'}) {
        ($self->{info}{oslabel})    = $self->{cmds}{'_lsb'} =~ /Distributor ID:\s*(.*?)\n/si;
        ($self->{info}{osvers})     = $self->{cmds}{'_lsb'} =~ /Release:\s*(.*?)\n/si;
        ($self->{info}{codename})   = $self->{cmds}{'_lsb'} =~ /Codename:\s*(.*)\n?/si;
    } else {
        $self->_release_version();
    }

    $self->{info}{source}{$commands{$_}} = $self->{cmds}{$_}    for(keys %commands);
    return $self->{info};
}

#----------------------------------------------------------------------------

sub _release_version {
    my $self = shift;

    for my $label (keys %distributions) {
        for my $file (@{ $distributions{$label}->{files} }) {
            next    unless(-f $file);
            my $line = `cat $file 2>/dev/null`;

            my ($version,$oslabel);
            if($distributions{$label}->{key}) {
                if($version_pattern{ $distributions{$label}->{key} }) {
                    ($version) = $line =~ /$version_pattern{ $distributions{$label}->{key} }/si;
                }
                if($oslabel_pattern{ $distributions{$label}->{key} }) {
                    ($oslabel) = $line =~ /$oslabel_pattern{ $distributions{$label}->{key} }/si;
                }
            }

            $version = $line    unless($version);
            $version =~ s/\s*$//;

            unless($oslabel) {
                if($self->{cmds}{'_issue1'}) {
                    ($oslabel) = $self->{cmds}{'_issue1'} =~ /^(\S*)/;
                } elsif($self->{cmds}{'_issue2'}) {
                    ($oslabel) = $self->{cmds}{'_issue2'} =~ /^(\S*)/;
                }
                $oslabel ||= $label;    # a last resort
            }

            $self->{info}{oslabel}  = $oslabel;
            $self->{info}{osvers}   = $version;
            $commands{'_cat'} = "cat $file";
            $self->{cmds}{'_cat'}  = $line;

            for my $vers (keys %{ $distributions{$label}->{codenames} }) {
                if($version =~ /^$vers\b/) {
                    $self->{info}{codename} = $distributions{$label}->{codenames}{$vers};
                    return;
                }
            }

            return;
        }
    }
}

1;

__END__

=head1 SYNOPSIS

  use Devel::Platform::Info::Linux;
  my $info = Devel::Platform::Info::Linux->new();
  my $data = $info->get_info();

=head1 DESCRIPTION

This module is a driver to determine platform metadata regarding the Linux
operating system. It should be called indirectly via it's parent 
Devel::Platform::Info

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Simply constructs the object.

=back

=head2 Methods

=over 4

=item * get_info

Returns a hash reference to the Linux platform metadata.

Returns the following keys:

  source
  archname
  osname
  osvers
  oslabel
  is32bit
  is64bit
  osflag

  codename
  kernel
  kname
  kvers

=back

=head1 REFERENCES

The following links were used to understand how to retrieve the metadata:

  * http://distrowatch.com/
  * Wikipedia pages for various Linux and Unix based OSes
  * http://search.cpan.org/dist/Sys-Info-Driver-Linux

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

RT Queue: http://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Platform-Info

=head1 AUTHORS

  Barbie (BARBIE) <barbie@cpan.org>
  Brian McCauley (NOBULL) <nobull67@gmail.com>
  Colin Newell (NEWELL) <newellc@cpan.org>
  Jon 'JJ' Allen (JONALLEN) <jj@jonallen.info>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2010-2016 Birmingham Perl Mongers

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
