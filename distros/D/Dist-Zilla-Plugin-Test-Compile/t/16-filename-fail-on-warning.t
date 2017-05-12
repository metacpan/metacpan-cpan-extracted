use strict;
use warnings;

use Path::Tiny;
my $code = path('t', '06-filename.t')->slurp_utf8;

$code =~ s/fail_on_warning => 'none'/fail_on_warning => 'author'/;
$code =~ s{is\(\$num_tests, 1, 'correct number of files were tested'}
          {is\(\$num_tests, 2, 'tested one file, and warnings (via being in xt/author)'};

eval $code;
die $@ if $@;
