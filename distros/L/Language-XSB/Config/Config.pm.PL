our $VERSION = '0.01';

use Config;

my $xsb='xsb';
my $xsb_opts='';
my $xsb_module='xsb_config';
print "inspecting XSB configuration...\n";
my $xsb_out=
    `$xsb $xsb_opts $xsb_module`;

my %xsb_config;
my $inconfig=undef;
for (split /\s*\n\s*/, $xsb_out) {
    $inconfig='in', next if /^__XSB_CONFIG_BEGIN__$/;
    next unless $inconfig;
    $inconfig='done', last if /^__XSB_CONFIG_END__$/;
    /^(.*?)\s*=\s*(.*)$/
	or die "unable to parse configuration options from".
	    " xsb output:\n$xsb_out\n";
    $xsb_config{$1}=$2;
    print "$1=$2\n";
}

$inconfig eq 'done' or die
    "****************************************************\n".
    "unable to inspect XSB configuration. Be sure\n".
    "that the '$xsb' program is in your command PATH.\n".
    "****************************************************\n";

open PM, '>', $ARGV[0]
    or die "unable to create file '$_[0]'\n";

print PM qq{
package Language::XSB::Config;

our \$VERSION = '$VERSION';

use strict;
use warnings;

require Exporter;
our \@ISA = qw(Exporter);
our \@EXPORT = qw(\%XsbConfig);

our \%XsbConfig = ( HOME => '$xsb_config{HOME}',
		   XSB_O => '$xsb_config{XSB_O}',
		   CONFDIR => '$xsb_config{CONFDIR}',
		   EMUDIR => '$xsb_config{EMUDIR}',
		   perl5 => '$Config{perl5}' );


1;
__END__

};
