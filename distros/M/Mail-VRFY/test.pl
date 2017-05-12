#!/usr/local/bin/perl

use strict;
use Mail::VRFY;

my $version = Mail::VRFY::Version();
print "# testing Mail::VRFY v${version} on platform: $^O\n";

my $a;
$SIG{ALRM} = sub { print "\nok - skipping internet checks. \n"; exit; };

my @emails = qw/postmaster@google.com postmaster@aol.com postmaster@yahoo.com postmaster@nanog.org postmaster@nic.museum/;

my $num = @emails + 1;
print "1..$num\n";
my $err;

# we make sure all of these pass
for my $email (@emails){
    print "# Testing ${email} (syntax only): ";
    my $code = Mail::VRFY::CheckAddress(addr => $email, method => 'syntax', timeout => 1, debug => 0);
    print Mail::VRFY::English($code) ."\n";
    if($code){
        print "not ok - syntax problem with $email - please report this!\n";
        $err++;
    }else{
        print "ok - $email is syntactically valid\n";
    }
}

exit $err if $err;

my $filt = 0;
# we only make sure one of these pass
for my $email (@emails){
    print "# Testing ${email}...\n";
    my $code = Mail::VRFY::CheckAddress(addr => $email, method => 'extended', timeout => 21, debug => 0);

    print '# ' . Mail::VRFY::English($code) ."\n";
    if( $code ){
        if( $code == 4 ){
            $filt++;
        }
    }else{
        print "ok - $email tested good\n";
        exit;
    }
}

# if all emails we tried got back code 4
if( $filt == @emails ){
    print "# no email addresses tested were valid; your outbound SMTP connections are likely filtered.\n",
          "# skip internet checks? [Y/n] ";
    alarm(10);
    chop($a=<STDIN>);
    alarm(0);

    if( $a =~ /^y(?:es)?$/i ){
        print "ok - skipping internet checks. \n";
    }else{
        print "not ok - could not connect to any SMTP servers.\n";
        exit 1;
    }
}else{
    print "not ok - all outbound SMTP tests failed.\n";
    exit 1;
}
