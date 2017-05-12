use Test::More tests => 1;

BEGIN {
    chdir "t" if -d "t";
    use lib qw(../lib);
}

require Devel::CallStack;
eval 'Devel::CallStack::import("Devel::CallStack", "bad")';
like($@, qr/Devel::CallStack::import: 'bad' unknown/);
