#!/usr/bin/perl -w
use warnings;

=head1 DESCRIPTION

Test those bits of the functionality of test-link that can be done
safely without any network connection or servers..  Unfortunately this
mostly means behavior where it doesn't do anything.

We mostly don't want to test things which require a working network
connection (unscalable and unreliable)

We don't want much external configuration because this could cause
confusion.

We don't want to take too long becuase this should be run by every
single person trying to install the software.

=head1 TESTS

first we test normal http

then we try to test other protocols

=cut

use Cwd;

$ENV{HOME}=cwd() . "/t/homedir";
$config=$ENV{HOME} . "/.link-control.pl";
die "LinkController test config file, $config missing." unless -e $config;

BEGIN {print "1..7\n"}

@start = qw(perl -Iblib/lib);

#$verbose=255;
$verbose=0 unless defined $verbose;
$fail=0;
sub nogo {print "not "; $fail=1;}
sub ok {my $t=shift; print "ok $t\n"; $fail=0}

$::infos="fixlink-infostruc.test-tmp~";

$fixed='test-data/fixlink-cgi-infostruc';

unlink $::infos;
-e $::infos and die "can't unlink infostruc file $::infos";
open DEFS, ">$infos" or die "couldn't open $infos $!";
print DEFS "directory http://example.com/ "
    . cwd() . "/$fixed\n";
close DEFS or die "couldn't close $infos $!";

do "t/config/files.pl" or die "files.pl script not read: " . ($@ ? $@ :$!);
#die "files.pl script failed $@" if

-e $_ and die "file $_ exists" foreach ($lonp, $phasl, $linkdb);

# create a "urllist" file from the directories
system 'rm', '-rf', $fixed;

-e $fixed and die "couldn't delete $fixed";

system 'cp', '-pr', 'test-data/sample-infostruc', $fixed;

ok(1);

nogo if system @start, qw(blib/script/extract-links ), "--config-file=$conf",
  ($::verbose ? "--verbose" : "--silent") ;

ok(2);

nogo unless ( -e $lonp and -e $phasl and -e $linkdb );

ok(3);

$starturl='http://www.rum.com/';
$endurl='http://www.drinks.com/rum/';
$fixfile="$fixed/banana.html";

$::driver='fix-cgi-driver.test-tmp.pl';
my $cgi="blib/script/fix-link.cgi";
open (CGI_DRIVER,">$::driver") or die "couldn't open $driver: $!";
print CGI_DRIVER <<EOF;
#!/usr/bin/perl
use Cwd;
my \@store=\( \$ENV{PATH}, \$ENV{BASH_ENV} \);
\$ENV{PATH}="/bin:/usr/bin";
delete \$ENV{BASH_ENV};
#print "CGI driver starting directory " . cwd() . " dir list\\n";
#print \`ls\`;
(\$ENV{PATH}, \$ENV{BASH_ENV})=\@store;
EOF

if ( $::verbose ) {
  print CGI_DRIVER <<EOF;
\$::verbose=0;
\$::verbose=0xFFF;
\$WWW::Link::Selector::verbose=0xFFF;
\$WWW::Link::Selector::verbose=0xFFF;
\$WWW::Link::Repair::verbose=0xFFF;
\$WWW::Link::Repair::Substitutor::verbose=0xFFF;
\$WWW::Link_Controller::InfoStruc::verbose=0xFFF;
EOF
}else{
  print CGI_DRIVER <<EOF;
\$::verbose=0xFFF;
\$::verbose=0;
EOF
}

print CGI_DRIVER <<EOF;
\$fixed_config=0;
\$fixed_config=1;

do "./$conf" or die "script $conf failed: " . (\$@ ? \$@ : \$!);

use WWW::Link_Controller::InfoStruc;
WWW::Link_Controller::InfoStruc::default_infostrucs();

do "./$cgi" or die "script $cgi failed: " . (\$@ ? \$@ : \$!);
EOF

close CGI_DRIVER or die "couldn't close $driver: $!";

#add tainting for the CGIbin
@start = qw(perl -Iblib/lib -w);
#@start = qw(perl -Iblib/lib -w -T);

$command= (join (" ", @start) ) . " $driver";

$output =
`(echo "orig-url=$starturl"; echo "canned-suggestion=$endurl") | $command`;

print STDERR "output is\n$output\n" if $::verbose;

ok(4);

nogo unless system 'grep', $starturl, $fixfile;

ok(5);

nogo if system "grep $endurl $fixfile > /dev/null";

ok(6);

nogo unless $output =~
  m,\Q$starturl\E.*\Q$endurl\E.*carried out,s;

ok(7);

