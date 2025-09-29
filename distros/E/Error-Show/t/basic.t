use strict;
use warnings;
use feature ":all";
use Test::More;

use Error::Show;

use File::Basename qw<dirname>;
my $file=__FILE__;

$@=undef;
my $dir=dirname $file;
my $context;


# Test context is empty stirng when no error
eval {
  require "./$dir/syntax-ok.pl";
};
#say STDERR "error is: ".length $@;


$context=Error::Show::context $@;
#say STDERR "error is: ",$@;
#say STDERR $context;
ok $context eq "", "Explicit Error variable";


# Test context is empty stirng when no error
$@=undef;
eval {
  require "./$dir/syntax-warning.pl";
};

$context=Error::Show::context $@;
ok $context eq "", "Explicit Error variable";


# Test context is not empty istring when with error
$@=undef;
eval {
  require "./$dir/syntax-error.pl";

};

$context=Error::Show::context $@;
ok $context ne "", "Explicit Error variable";


# Test internal frame capture and default import
#$context=context undef;
#ok $context =~ /64=> \$context=context undef;/, "Internal frame capture";
#say STDERR "CONTEXT $context";


done_testing;
