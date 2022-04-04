package TestLLT;
use base 'Exporter';
our @EXPORT = qw( set_logger log_is log_like capture_stderr );

use Test::Builder;
my $Test = Test::Builder->new();

my $logger;
sub set_logger { $logger = shift }

sub log_is (&$$) {
   my ($sub, $value, $message) = @_;
   my $collector = '';
   open my $fh, '>', \$collector;
   $logger->fh($fh);
   $sub->($logger);
   close $fh;
   $Test->is_eq($collector, $value, $message);
} ## end sub log_is (&$$)

sub log_like (&$$) {
   my ($sub, $regex, $message) = @_;
   my $collector = '';
   open my $fh, '>', \$collector;
   $logger->fh($fh);
   $sub->($logger);
   close $fh;
   $Test->like($collector, $regex, $message);
} ## end sub log_like (&$$)

sub capture_stderr (&) {
   local *STDERR;
   close STDERR;
   my $stderr = '';
   open STDERR, '>', \$stderr;
   $_[0]->();
   close STDERR;
   return $stderr;
}

1;
