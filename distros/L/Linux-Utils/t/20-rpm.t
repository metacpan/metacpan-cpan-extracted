#!perl

use Test::More;
use Modern::Perl;
use Data::Printer alias => 'pdump';
use Util::Medley::File;
use English;
use Linux::Utils::RPM;

###################################################

my $file = Util::Medley::File->new;

my $rpm = Linux::Utils::RPM->new;
ok($rpm);

SKIP: {
	my $path = $file->which('rpm');
	skip "can't find rpm exe" if !$path;

    doRpmQueryAll($rpm);
    doRpmQueryAllByName($rpm, getRandomWildcardRpmName($rpm));
    doRpmQueryList($rpm);
    doRpmQueryFileOwner($path); 
}

done_testing;

###################################################

sub getRandomWildcardRpmName {
    my $rpm = shift;
    
    my $aref = $rpm->queryAll;
    my $name = shift @$aref;
    
    if ($name =~ /^(\w+)-/) {
        return sprintf '%s%s', $1, '*';	
    }
    
    die "rpmName: $name doesn't match regex???";
}

sub doRpmQueryList {
    my $rpm = shift;
    
    my $all = $rpm->queryAll;
    my $rpmName = shift @$all;
    
    my $list = $rpm->queryList(rpmName => $rpmName);
    ok(ref($list) eq 'ARRAY');
}

sub doRpmQueryFileOwner {
    my $file = shift;
    
    my $rpm_name = $rpm->queryFileOwner(file => $file);
    ok($rpm_name);
}

sub doRpmQueryAll {
    my $rpm = shift;
    
    my $aref = $rpm->queryAll;
    ok(ref($aref) eq 'ARRAY');
    ok(@$aref > 0); # there should be at least one rpm installed
}

sub doRpmQueryAllByName {
    my $rpm = shift;
    my $rpmName = shift;
     
    my $aref = $rpm->queryAll(rpmName => $rpmName);
    ok(ref($aref) eq 'ARRAY');
    ok(@$aref > 0); # there should be at least one rpm installed
}
