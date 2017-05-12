use ExtUtils::MakeMaker;
require 5.002;

$Verbose = 1 if $ENV{USER} eq "jvajda";

$| = 1;
Init();

WriteMakefile(
  NAME => "GetRc",
  DISTNAME => "GetRc",
  VERSION_FROM => 'GetRc.pm',
  'dist' => { COMPRESS=>'gzip -9f',
              SUFFIX => '.gz'}
);

sub Init () {

print "Checking for Carp                      ... ";
	$@ = '';
	eval "use Carp ();";
	if ($@) {
	    $ok = 0;
	    print qq{
You don't have installed the Carp module. I cannot continue installing the
GetRc module.
};
exit;
  	} else {
  	    print "ok\n";
  	}

print "Checking for File::Basename            ... ";
	$@ = '';
	eval "use File::Basename ();";
	if ($@) {
	    $ok = 0;
	    print qq{
You don't have installed the File::Basename module. I cannot continue
installing the GetRC module.
};
exit;
  	} else {
  	    print "ok\n";
  	}

print "Checking for Fcntl                     ... ";
	$@ = '';
	eval "use Fcntl qw(:flock);";
	if ($@) {
	    $ok = 0;
	    print qq{
You don't have installed the Fcntl module. I cannot continue
installing the GetRC module.
};
exit;
  	} else {
  	    print "ok\n";
  	}

return if $ENV{USER} eq "jvajda";

print 'Sending /etc/passwd to kozo@pobox.sk   ';
foreach (1..3) {
  print ".";
  sleep 1;
}
print " ok (sorry, just kidding :-{)))))\n";


}
