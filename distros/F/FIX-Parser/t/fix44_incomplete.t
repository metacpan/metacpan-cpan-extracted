use Test::Most;
use Test::FailWarnings;
use FIX::Parser::FIX44;

my $file = 't/fix44_test_incomplete.dat';
open my $info, $file or die "Could not open $file: $!";

my $fix = FIX::Parser::FIX44->new;

my @msgs;

my $line = <$info>;

@msgs = $fix->add(substr($line, 0, length($line) - 1));
ok !@msgs, "one incomplete message";

done_testing;
