use JSON::Tiny 'j';

my @json
  = split /-{4}/, do { open my $fh, '<sample.json'; local $/ = undef; <$fh> };

sub json_tiny { [ map { j $_ } @json ]; }

my $value = json_tiny;

