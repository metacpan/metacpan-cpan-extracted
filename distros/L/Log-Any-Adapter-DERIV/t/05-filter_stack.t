use strict;
use warnings;
use Test::More;
use Log::Any qw($log);
use Log::Any::Adapter qw();
use Log::Any::Adapter::DERIV;
use Log::Any::Adapter::Util qw(numeric_level);
use Path::Tiny;
use JSON::MaybeUTF8 qw(:v1);


sub test_log{
    my ($log_level, $severity, $has_stack) = @_;
    my $json_log_file = Path::Tiny->tempfile;
    Log::Any::Adapter->import('DERIV', json_log_file => "$json_log_file", log_level => $log_level);
    $log->$severity('test info');
    my $log_message = $json_log_file->slurp;
    chomp($log_message);
    $log_message = decode_json_text($log_message);
    my $exist_stack = exists($log_message->{stack});
    if($has_stack){
        ok($exist_stack, "log_level $log_level severity $severity should have stack")
    }
    else{
        ok(!$exist_stack, "log_level $log_level severity $severity should not have stack");
    }
}
my @levels = qw(
         trace
         debug
         info
         notice
         warning
         error
         critical
         alert
         emergency
);
my %hash_has_stack;
$hash_has_stack{info}{notice} = 0;
$hash_has_stack{info}{info} = 0;
$hash_has_stack{notice}{notice} = 0;
for my $log_level (@levels){
    for my $severity (@levels){
        next if (numeric_level($log_level) < numeric_level($severity));
       test_log($log_level, $severity, $hash_has_stack{$log_level}{$severity} // 1) ;
    }
}

done_testing();
