# Test POD Docs
use Test::More ;
use lib ('..');
use Data::Dumper;
$Data::Dumper::Indent = 1;

SKIP: {
   eval("use Test::Pod;");
   if ($@) {plan('skip_all', "No Test::Pod Available");}
};
#NOTNEEDED:plan('tests', 13);
my @poddirs = ('blib', 'script', ); # '../blib'
# Extra may be given
my @podfiles = all_pod_files( @poddirs );
#DEBUG:print(Dumper(\@podfiles));
all_pod_files_ok(@podfiles);
