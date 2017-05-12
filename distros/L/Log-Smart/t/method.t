
use Test::More 'no_plan';
use Log::Smart;
use IO::File;
use File::Temp;


my $foo = "foo";
my $bar = "bar";
my $buz = "buz";
my $hash_ref = {$foo => $bar, $bar => $buz};

LOG $foo;
LOG $bar;
LOG $buz;
DUMP('dump', $hash_ref);
SKIP: {
    eval { require YAML };
    skip "YAML not installed", 0 if $@;
    YAML('yaml', $hash_ref);
}

my $log = IO::File->new('t/main.log', 'r') or die "can't open";

#LOG
my $line = $log->getline;
chomp $line;
is($line, 'foo', 'test foo');
$line = $log->getline;
chomp $line;
is($line, 'bar', 'test bar');
$line = $log->getline;
chomp $line;
is($line, 'buz', 'test buz');

#DUMP
$line = $log->getline;
chomp $line;
is($line, '[dump #DUMP]', 'test dump');
$line = $log->getline;
chomp $line;
is($line, '$VAR1 = {', 'test dump2');
$line = $log->getline;
chomp $line;
is($line, "          'bar' => 'buz',", 'test dump3');
$line = $log->getline;
chomp $line;
is($line, "          'foo' => 'bar'", 'test dump4');
$line = $log->getline;
chomp $line;
is($line, '        };', 'test dump5');

SKIP: {
    #YAML
    eval { require YAML };
    skip "YAML not installed", 4 if $@;

    $line = $log->getline;
    chomp $line;
    is($line, '[yaml #YAML]', 'yaml dump');
    $line = $log->getline;
    chomp $line;
    is($line, '---', 'yaml dump2');
    $line = $log->getline;
    chomp $line;
    is($line, 'bar: buz', 'yaml dump3');
    $line = $log->getline;
    chomp $line;
    is($line, 'foo: bar', 'yaml dump4');
}

$log->close;
CLOSE;
