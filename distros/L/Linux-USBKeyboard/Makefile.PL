unless($ENV{AUTOMATED_TESTING}) {
die "

You must run Build.PL to configure this distribution.

If you are running CPAN or CPANPLUS, please reconfigure your client to
use the Build.PL file.  This file only exists to stop older CPANPLUS
clients from 'inventing' an empty Makefile.PL.

Thanks,
Eric
"
}
else {
warn "

  ERROR!  Your cpan tester appears to be misconfigured.

",
"Please run the Build.PL file.\n"x50,
"

Please.

Thanks,
Eric
";
exit 0;
}
