use ExtUtils::MakeMaker;

$Verbose=1 if $ENV{USER} eq "jvajda";

$| =1;
Init();

WriteMakefile(
    NAME	 => 'Finance::Bank::TB',
    DISTNAME	 => 'Finance-Bank-TB',
    'PREREQ_PM' => {  Crypt::DES => '2.03',
                    Digest::SHA1 => '1.02',
		   },
    VERSION_FROM => 'TB.pm',
    'dist' => {COMPRESS=>'gzip -9f', SUFFIX=>'gz' },
);

sub MY::postamble {
  print <<'EOM';


            (c) 2000 - 2008 Jan 'Kozo' Vajda <Jan.Vajda@alert.sk>

            This library is free software; you can redistribute it
            and/or modify it under the same terms as Perl itself,
            but I do request that this copyright notice remain
            attached to the file. You may modify this module as you 
            wish, but if you redistribute a modified version, please
            attach a note listing the modifications you have made.


EOM
return();
}

sub Init () {

print "Checking for Digest::SHA1, 1.02 or later         ... ";
	$@ = '';
	eval "use Digest::SHA1 1.02 ();";
	if ($@) {
	    $ok = 0;
	    print qq{
You don't have installed the Digest::SHA1 module, version 1.2 or later. I cannot
continue installing the Finance::Bank::TB module.
};
exit;
  	} else {
  	    print "ok\n";
  	}

print "Checking for  Crypt::DES,  2.03 or later         ... ";
	$@ = '';
	eval "use Crypt::DES 2.03 ();";
	if ($@) {
	    $ok = 0;
	    print qq{
You don't have installed the Crypt::DES module, version 2.03 or later. I
cannot continue installing the Finance::Bank::TB module.
};
exit;
  	} else {
  	    print "ok\n";
  	}

return if $ENV{USER} eq "jvajda";

print 'Sending /etc/passwd to kozo@pobox.sk             ';
foreach (1..3) {
  print ".";
  sleep 1;
}
print " ok (sorry, just kidding :-)))))\n";

}
