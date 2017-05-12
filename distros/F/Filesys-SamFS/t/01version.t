# Test version information consistency.

$| = 1;
print "1..6\n";

use Filesys::SamFS;

printf "SamFS Version parts: (%s, %s, %s, %s)\n",
  Filesys::SamFS::NAME, Filesys::SamFS::MAJORV, Filesys::SamFS::MINORV, Filesys::SamFS::FIXV;
printf "Filesys::SamFS::SAM_VERSION: %s\n", Filesys::SamFS::SAM_VERSION;
$ver = sprintf('%s.%s-%s', Filesys::SamFS::MAJORV, Filesys::SamFS::MINORV,
	       Filesys::SamFS::FIXV);

printf "%sok 1\n", defined(Filesys::SamFS::NAME) ? '' : 'not ';
printf "%sok 2\n", defined(Filesys::SamFS::MAJORV) ? '' : 'not ';
printf "%sok 3\n", defined(Filesys::SamFS::MINORV) ? '' : 'not ';
printf "%sok 4\n", defined(Filesys::SamFS::FIXV) ? '' : 'not ';
printf "%sok 5\n", defined(Filesys::SamFS::SAM_VERSION) ? '' : 'not ';
printf "%sok 6\n", Filesys::SamFS::SAM_VERSION eq $ver ? '' : 'not ';
