use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING' unless $ENV{RELEASE_TESTING};

eval { require Pod::Text; 1 }
    or plan skip_all => 'Pod::Text required';

open my $fh, '<', 'README' or die "cannot read README: $!";
my $have = do { local $/; <$fh> };

my $parser = Pod::Text->new;
my $want = '';
$parser->output_string(\$want);
$parser->parse_file('lib/EV/Kafka.pm');

is $want, $have, 'README is in sync with lib/EV/Kafka.pm POD'
    . ' (run: pod2text lib/EV/Kafka.pm > README)';
done_testing;
