#!/usr/bin/perl -w
use warnings;

=head1 DESCRIPTION

test features of extract link, particularly related to directory based
extraction

=cut

use Cwd;

$ENV{HOME}=cwd() . "/t/homedir";
$config=$ENV{HOME} . "/.link-control.pl";
die "LinkController test config file, $config missing." unless -e $config;

BEGIN {print "1..4\n"}

@start = qw(perl -Iblib/lib);

#$verbose=255;
$verbose=0 unless defined $verbose;
$fail=0;
sub nogo {print "not "; $fail=1;}
sub ok {my $t=shift; print "ok $t\n"; $fail=0}

sub fgrep {
  ($string, $file)=@_;
  my $result = not system "grep $string $file > /dev/null";
  print "grep $string $file > /dev/null gives $result\n" if $verbose;
  return $result;
}

$::extractme="test-data/extract-infostruc";

$::infos="extract-link-infostruc.test-tmp~";

unlink $::infos;
-e $::infos and die "can't unlink infostruc file $::infos";
open DEFS, ">$infos" or die "couldn't open $infos $!";
print DEFS "advanced http://example.com/ \n";
close DEFS or die "couldn't close $infos $!";

do "t/config/files.pl" or die "files.pl script not read: " . ($@ ? $@ :$!);
#die "files.pl script failed $@" if $@;

$dir=cwd() . "/$::extractme";

open (CONFIG, ">>$conf") or die "can't open conf file: $conf";
print CONFIG <<"EOF";
\$::infostrucs{'http://example.com/'} = {
    mode => "directory",
    file_base => "$dir",
    prune_re => "leitheatre|dbadmin", #ignore referrals
#    resource_exclude_re => "\.secret\$", #secrets shouldn't get into link database
#    link_exclude_re => "^http://([a-z]+\.)+example\.com", #example.com doesn't matter
};
1;
EOF
close CONFIG  or die "can't close conf file: $conf";

unlink ($lonp, $phasl, $linkdb);

-e $_ and die "file $_ exists" foreach ($lonp, $phasl, $linkdb);

$linkfile="link-list.test-tmp~";

nogo if system @start, qw(blib/script/extract-links ), "--config-file=$conf",
  "--out-uri-list=$linkfile", ($::verbose ? "--verbose" : "--silent") ;

ok(1);

nogo unless ( -e $lonp and -e $phasl and -e $linkdb );

ok(2);

nogo if fgrep ("http://ignore.example.com", $linkfile);

ok(3);

nogo unless fgrep ("http://find.example.com", $linkfile);

ok(4);
