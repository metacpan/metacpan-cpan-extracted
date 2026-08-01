# The benchmark app: plaintext "Hello, World!" — the canonical PSGI micro-
# benchmark. Kept identical for every server so the numbers compare the
# servers, not the app.
my $body = "Hello, World!";
my $len  = length $body;
sub {
    [ 200,
      [ 'Content-Type' => 'text/plain', 'Content-Length' => $len ],
      [ $body ],
    ];
};
