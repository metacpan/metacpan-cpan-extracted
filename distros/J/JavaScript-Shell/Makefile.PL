use 5.008005;
use ExtUtils::MakeMaker;
use Archive::Extract;
use Config;

My_WriteMakefile(
    NAME => 'JavaScript::Shell',
    VERSION_FROM => 'lib/JavaScript/Shell.pm', # finds $VERSION
    PREREQ_PM => {
	'JSON::XS' => 0
    },
    ($] >= 5.005 ? ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/JavaScript/Shell.pm', # retrieve abstract from module
       AUTHOR => 'Mamod A. Mehyar <mamod.mehyar@gmail.com>') : ())
);

sub My_WriteMakefile {
    my %params=@_;
    my $ok = 0;
    $ok = getShell();
    WriteMakefile(%params);
    
    if (!$ok){
	print "couldn't fetch spidermonkey shell from remote host\n"
	. "please download your system binaries from\n"
	. "http://ftp.mozilla.org/pub/mozilla.org/firefox/nightly/latest-trunk\n"
	. "and extract to /lib/JavaScript/Shell/bin folder \n"
	. "You can skip testing for now and make install directly\n";
    }
}



sub getShell {
    
    my $os = $^O;
    my $file;
    if ($os =~ /^MS/i){
	$file = 'jsshell-win32.zip';
    } elsif ($os =~ /^Mac/i){
	$file = 'jsshell-mac.zip';
    } else {
	if ($Config{'archname'} =~ m/x86/){
	    $file = 'jsshell-linux-x86_64.zip';
	} else {
	    $file = 'jsshell-linux-i686.zip';
	}
	
    }
    
    my $response;
    my $stream;
    my $url = 'http://ftp.mozilla.org/pub/mozilla.org/firefox/nightly/latest-trunk/' . $file;
    #my $url = 'http://127.0.0.1/' . $file;
    
    print "\n ===================== Trying wget ==========================\n";
    system "wget $url";
    
    if (!-e $file) {
	
	print "\n ========== Trying to fetch using LWP::UserAgent ==========\n";
	eval "use LWP::UserAgent";
	if ($@){
	    print "We couldn't locate LWP::UserAgent Module\n";
	    print "LWP::UserAgent required to fetch regexes.yaml from server\n";
	    print "Please install it or get regexes.yaml file manually from\n";
	    print "https://raw.github.com/tobie/ua-parser/master/regexes.yaml\n";
	    print "and place it in the root folder of this distro\n";
	    print "then run Makefile.PL again\n";
	    exit;
	}
	
	
	
	my $ua = LWP::UserAgent->new;
	$ua->timeout(5);
	$ua->env_proxy();
	$response = $ua->get($url);
	if ($response->is_success) {
	    open(my $fh,'>>',$file);
	    binmode($fh);    
	    $fh->print($response->content);
	} else {
	    return 0;
	}
    }
    
    eval {
	my $ae = Archive::Extract->new( archive => $file );
	my $ok = $ae->extract( to => './lib/JavaScript/Shell/bin' );
    };
    
    ##remove
    unlink($file);
    
    if ($@){
	print "Couldn't Extract Archive $file \n";
	return 0;
    }
    
    return 1;
}


