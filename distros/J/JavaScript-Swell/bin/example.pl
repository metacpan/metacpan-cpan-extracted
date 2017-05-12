use strict;
use lib './lib/';
use JavaScript::Swell;

my $data;
while (<>) {
    $data .= $_;
}

#print JavaScript::Swell->squish($data);
print JavaScript::Swell->swell($data);

