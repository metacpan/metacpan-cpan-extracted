BEGIN { $ENV{PERL_JSON_BACKEND} = 0; } # JSON::PP.

use JSON;

my @json
  = split /-{4}/, do { open my $fh, '<sample.json'; local $/ = undef; <$fh> };

sub json_pp { my $j = JSON->new; [ map { $j->decode($_) } @json ]; }

my $value = json_pp;
