 #!/usr/bin/perl
use strict;
use lib 'lib';
use Filesys::Virtual::Chroot;

my $cr = Filesys::Virtual::Chroot->new(
	c => '/tmp',
	i => 0
) || die $Filesys::Virtual::Chroot::errstr;

print " Root: " . $cr->rroot . "\n";
print " Fake: " . $cr->vpwd . "\n";

if($cr->vchdir($ARGV[0])){
	print " Change directory success\r\n";
	print " Root: " . $cr->rroot . "\n";
	print " Real: " . $cr->rcwd . "\n";
	print " Fake: " . $cr->vcwd . "\n";
} else {
	print $cr->errstr . "\n";
}

exit;


