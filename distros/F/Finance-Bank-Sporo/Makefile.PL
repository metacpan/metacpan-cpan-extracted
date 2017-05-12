use ExtUtils::MakeMaker;
use Config;

$Verbose=1 if $ENV{USER} eq "jvajda";

$| =1;
Init();

WriteMakefile(
    NAME	 => 'Finance::Bank::Sporo',
    DISTNAME	 => 'Finance-Bank-Sporo',
    VERSION_FROM => 'Sporo.pm',
    'dist' => {COMPRESS=>'gzip -9f', SUFFIX=>'gz' },
);

sub Init () {
print "Checking for URI::Escape            ... ";
	$@ = '';
	eval "use URI::Escape ();";
	if ($@) {
	    $ok = 0;
	    print qq{
You don't have installed the URI::Escape module. I cannot continue installing
the Bank::Sporo module.
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
