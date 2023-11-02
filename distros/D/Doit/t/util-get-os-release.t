#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use Doit;
use Doit::Util qw(get_os_release);
use Cwd qw(cwd);
use File::Temp qw(tempdir);
use Test::More;

return 1 if caller;

plan 'no_plan';

my $doit = Doit->init;

{
    my $os_release = get_os_release();
 SKIP: {
	skip "get_os_release did not return anything", 4
	    if !defined $os_release;
	ok $os_release->{ID}, 'ID should be defined in /etc/os-release';
	my $os_release_cached = get_os_release();
	is_deeply $os_release_cached, $os_release, '2nd call returns same (probably cached content)';
	my $os_release_uncached = get_os_release(refresh => 1);
	is_deeply $os_release_uncached, $os_release, 'refresh => 1 returns same (now uncached content)';
	my $os_release_explicit_file = get_os_release(file => '/etc/os-release');
	is_deeply $os_release_explicit_file, $os_release, '/etc/os-release is the default file';
    }
}

{
    my $tempdir = tempdir('doit_XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
    my $os_release_file = "$tempdir/os-release";
    $doit->write_binary({quiet=>1}, $os_release_file, <<'EOF');
NAME="Ubuntu"
VERSION="20.04.6 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.6 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal
EOF
    my $os_release = get_os_release(file => $os_release_file);
    is_deeply $os_release, {
	NAME => 'Ubuntu',
	VERSION => "20.04.6 LTS (Focal Fossa)",
	ID => 'ubuntu',
	ID_LIKE => 'debian',
	PRETTY_NAME => "Ubuntu 20.04.6 LTS",
	VERSION_ID => "20.04",
	HOME_URL => "https://www.ubuntu.com/",
	SUPPORT_URL => "https://help.ubuntu.com/",
	BUG_REPORT_URL => "https://bugs.launchpad.net/ubuntu/",
	PRIVACY_POLICY_URL => "https://www.ubuntu.com/legal/terms-and-policies/privacy-policy",
	VERSION_CODENAME => 'focal',
	UBUNTU_CODENAME => 'focal',
    }, 'expected os-release contents (Ubuntu 20.04)';
}

{
    my $tempdir = tempdir('doit_XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
    my $os_release_file = "$tempdir/os-release";
    $doit->write_binary({quiet=>1}, $os_release_file, <<'EOF');
NAME=FreeBSD
VERSION=15.0-CURRENT
VERSION_ID=15.0
ID=freebsd
ANSI_COLOR="0;31"
PRETTY_NAME="FreeBSD 15.0-CURRENT"
CPE_NAME=cpe:/o:freebsd:freebsd:15.0
HOME_URL=https://FreeBSD.org/
BUG_REPORT_URL=https://bugs.FreeBSD.org/
EOF
    my $os_release = get_os_release(file => $os_release_file);
    is_deeply $os_release, {
	NAME => 'FreeBSD',
	VERSION => '15.0-CURRENT',
	VERSION_ID => '15.0',
	ID => 'freebsd',
	ANSI_COLOR => '0;31',
	PRETTY_NAME => 'FreeBSD 15.0-CURRENT',
	CPE_NAME => 'cpe:/o:freebsd:freebsd:15.0',
	HOME_URL => 'https://FreeBSD.org/',
	BUG_REPORT_URL => 'https://bugs.FreeBSD.org/',
    }, 'expected os-release contents (FreeBSD 15)';
}

{
    my $tempdir = tempdir('doit_XXXXXXXX', TMPDIR => 1, CLEANUP => 1);
    my $os_release_file = "$tempdir/os-release";
    $doit->write_binary({quiet=>1}, $os_release_file, <<'EOF');
NAME="CentOS Linux"
VERSION="7 (Core)"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="7"
PRETTY_NAME="CentOS Linux 7 (Core)"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:7"
HOME_URL="https://www.centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"

CENTOS_MANTISBT_PROJECT="CentOS-7"
CENTOS_MANTISBT_PROJECT_VERSION="7"
REDHAT_SUPPORT_PRODUCT="centos"
REDHAT_SUPPORT_PRODUCT_VERSION="7"

EOF
    my $os_release = get_os_release(file => $os_release_file);
    is_deeply $os_release, {
	NAME => "CentOS Linux",
	VERSION => "7 (Core)",
	ID => "centos",
	ID_LIKE => "rhel fedora",
	VERSION_ID => 7,
	PRETTY_NAME => "CentOS Linux 7 (Core)",
	ANSI_COLOR => "0;31",
	CPE_NAME => "cpe:/o:centos:centos:7",
	HOME_URL => "https://www.centos.org/",
	BUG_REPORT_URL => "https://bugs.centos.org/",
	CENTOS_MANTISBT_PROJECT => "CentOS-7",
	CENTOS_MANTISBT_PROJECT_VERSION => 7,
	REDHAT_SUPPORT_PRODUCT => "centos",
	REDHAT_SUPPORT_PRODUCT_VERSION => 7,
    }, 'expected os-release contents (CentOS 7; empty lines are ignored)';
}

{
    eval { get_os_release(unhandled_option => 1) };
    like $@, qr{unhandled_option};
}

is get_os_release(file => cwd . '/this-file-does-not-exist'), undef, 'non-existing os-release file';
