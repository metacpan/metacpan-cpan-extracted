# -*- perl -*-

=head1 WHATS THIS

This prog allows cmdline options (evaluated in a BEGIN) to selectively
pull in separate packages (currently X & Y), both of which use
AutoCategorize, and which therefore should be munged.

By using either uppercase or lowercase options, you can control the
order that the modules are used wrt use of AutoCategorize in the main
script; uppercase options use the module 1st, lowercase use them after
main() use AutoCategorize is compiled.

=cut

BEGIN {
    # it seems unholy to do this, but perl Core does..
    chdir 't' if -d 't';
    use lib '../lib';
    $ENV{PERL5LIB} = '../lib';    # so children will see it too
}

my $opts;
BEGIN {
    use Getopt::Std;
    getopts ('wxyzWXYZvd', $opts={})
	or die qq{
	    only options [abXYv] allowed
		-W : load X.pm before AutoCategorize
		-w :           after AutoCategorize
		-X : load X.pm before AutoCategorize
		-x :           after AutoCategorize
		-Y : load Y.pm before AutoCategorize
		-y :           after AutoCategorize
		-Z : load Z.pm before AutoCategorize
		-z :           after AutoCategorize
		-v : verbose
		};
		       
    $DB::single = 1 if $opts->{d};

    foreach $mod ('W','X','Y','Z') {
	if ($opts->{$mod}) {
	    print "loading $mod\n";
	    require "$mod.pm";
	    $mod->import;
	}
    }
}

use Log::Log4perl::AutoCategorize 
    (
     alias => 'myLogger',
     $opts->{v}
     ? # verbose - use default logger (to Screen), and 
     ( #debug => 'vfmjdsrsriabcz',
       debug => 've',	#debug => 'abcevfmrsi',
      )
     : # use log-conf, wo excessive screen
     ( initfile => 'log-conf',
       debug => ''
       ),
     );

BEGIN {
    foreach $mod ('W','X','Y','Z') {
	if ($opts->{lc $mod}) {
	    print "loading $mod\n";
	    require "$mod.pm";
	    $mod->import;
	}
    }
}

# OK - now do runtime 
# NOTE that the test expects particular line numbers, and will fail if
# you add even a blank line or comment here (above the myLogger calls)

foreach (1..5) {
    myLogger->warn($_);
    myLogger->info($_);

    foreach $mod ('W','X','Y','Z') {
	if ($opts->{$mod} or $opts->{lc $mod}) {
	    #print "running $mod\n";
	    $mod->truck($_);
	}
    }
}

__END__

