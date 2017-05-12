use Config;
use File::Basename qw(basename dirname);
use lib 'lib';
use IP::Country;
my $reg = IP::Country->new();

my $VERSION = $reg->VERSION;

chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
        if ($Config{'osname'} eq 'VMS' or
            $Config{'osname'} eq 'OS2');  # "case-forgiving"
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'}
use strict;
\$^W=1;

my \$VERSION = '$VERSION';
!GROK!THIS!

print OUT <<'!NO!SUBS!';

use IP::Country;
use Geography::Countries;
use Socket qw ( inet_aton inet_ntoa );

getRevDate();
if ($#ARGV == 0){
    getCountry($ARGV[0]);
} else {
    print "> ";
    while(my $host = <>){
	chomp($host);
	getCountry($host);
	print "> ";
    }
}
print "\n";    

sub getCountry
{
    my $host = shift;
    my $dip = $host; # dotted IP
    my $ip = inet_aton($host);
    
    my ($cc,$country);
    if (defined $ip){
	my $reg = IP::Country->new();
	$cc = $reg->inet_ntocc($ip);
	$dip = inet_ntoa($ip);
    }

    if (!defined $cc){
	$cc = '??';
	$country = 'Not Found';
    } elsif ($cc eq '**'){
	$country = 'Private Network';
    } elsif ($cc eq 'AP'){
	$country = 'Asia-Pacific';
    } elsif ($cc eq 'EU'){
	$country = 'European Union';
    } else {
	$country = country($cc);
    }

    if (!defined $country){
	$country = 'Undefined';
    }
    
    if ($dip eq $host){
	print "  Address: $host\n  Country: $cc ($country)\n";
    } else {
	print "  Name: $host\n  Address: $dip\n  Country: $cc ($country)\n";
    }
}

sub getRevDate
{
    my $reg = IP::Country->new();
    my $tm = gmtime($reg->db_time());
    print "\n  IP::Country modules (v$VERSION)\n  Copyright (c) 2002-13 Nigel Wetters Gourlay\n";
    print "  Database updated $tm\n\n";
}

__END__

=head1 NAME

ip2cc - lookup country from IP address or hostname

=head1 SYNOPSIS

ip2cc [host-to-find]

=head1 DESCRIPTION

Ip2cc is a program to lookup countries of IP addresses. Ip2cc
has two modes: interactive and non-interactive.  Interactive mode allows
the user to query more than one hostname.  Non-interactive mode is
used to print just the country for a single host.

=head1 ARGUMENTS

Interactive mode is entered when no arguments are given.

Non-interactive mode is used when the name or Internet address of the
host to be looked up is given as the first argument.

=head1 SEE ALSO

IP::Country - the fast database used by this script.

=head1 AUTHOR

Nigel Wetters Gourlay <nwetters@cpan.org>

!NO!SUBS!

