#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Differences;

BEGIN {
    use_ok( 'MarpaX::ESLIF::URI' ) || print "Bail out!\n";
}

my %DATA =
  (
   "file:///path/to/file" => {
                              scheme    => { origin => "file",                                 decoded => "file",                                 normalized => "file" },
                              string    => { origin => "file:///path/to/file",                 decoded => "file:///path/to/file",                 normalized => "file:///path/to/file" },
                              path      => { origin => "/path/to/file",                        decoded => "/path/to/file",                        normalized => "/path/to/file" },
                              segments  => { origin => ["path", "to", "file"],                 decoded => ["path", "to", "file"],                 normalized => ["path", "to", "file"] }
                             },
   "file:/path/to/file" => {
                              scheme    => { origin => "file",                                 decoded => "file",                                 normalized => "file" },
                              string    => { origin => "file:/path/to/file",                   decoded => "file:/path/to/file",                   normalized => "file:/path/to/file" },
                              path      => { origin => "/path/to/file",                        decoded => "/path/to/file",                        normalized => "/path/to/file" },
                              segments  => { origin => ["path", "to", "file"],                 decoded => ["path", "to", "file"],                 normalized => ["path", "to", "file"] }
                             },
   "file://host.example.com/path/to/file" => {
                              scheme    => { origin => "file",                                 decoded => "file",                                 normalized => "file" },
                              string    => { origin => "file://host.example.com/path/to/file", decoded => "file://host.example.com/path/to/file", normalized => "file://host.example.com/path/to/file" },
                              path      => { origin => "/path/to/file",                        decoded => "/path/to/file",                        normalized => "/path/to/file" },
                              segments  => { origin => ["path", "to", "file"],                 decoded => ["path", "to", "file"],                 normalized => ["path", "to", "file"] },
                              authority => { origin => "host.example.com",                     decoded => "host.example.com",                     normalized => "host.example.com" },
                              host      => { origin => "host.example.com",                     decoded => "host.example.com",                     normalized => "host.example.com" }
                             },
   "file:c:/path/to/file" => {
                              scheme    => { origin => "file",                                 decoded => "file",                                 normalized => "file" },
                              string    => { origin => "file:c:/path/to/file",                 decoded => "file:c:/path/to/file",                 normalized => "file:C:/path/to/file" },
                              drive     => { origin => "c",                                    decoded => "c",                                    normalized => "C" },
                              path      => { origin => "c:/path/to/file",                      decoded => "c:/path/to/file",                      normalized => "C:/path/to/file" },
                              segments  => { origin => ["c:", "path", "to", "file"],           decoded => ["c:", "path", "to", "file"],           normalized => ["C:", "path", "to", "file"] }
                             },
   "file:///c:/path/to/file" => {
                              scheme    => { origin => "file",                                 decoded => "file",                                 normalized => "file" },
                              string    => { origin => "file:///c:/path/to/file",              decoded => "file:///c:/path/to/file",              normalized => "file:///C:/path/to/file" },
                              drive     => { origin => "c",                                    decoded => "c",                                    normalized => "C" },
                              path      => { origin => "/c:/path/to/file",                     decoded => "/c:/path/to/file",                     normalized => "/C:/path/to/file" },
                              segments  => { origin => ["c:", "path", "to", "file"],           decoded => ["c:", "path", "to", "file"],           normalized => ["C:", "path", "to", "file"] }
                             },
   "file:/c:/path/to/file" => {
                              scheme    => { origin => "file",                                 decoded => "file",                                 normalized => "file" },
                              string    => { origin => "file:/c:/path/to/file",                decoded => "file:/c:/path/to/file",                normalized => "file:/C:/path/to/file" },
                              drive     => { origin => "c",                                    decoded => "c",                                    normalized => "C" },
                              path      => { origin => "/c:/path/to/file",                     decoded => "/c:/path/to/file",                     normalized => "/C:/path/to/file" },
                              segments  => { origin => ["c:", "path", "to", "file"],           decoded => ["c:", "path", "to", "file"],           normalized => ["C:", "path", "to", "file"] }
                             },
   "file:c|/path/to/file" => {
                              scheme    => { origin => "file",                                 decoded => "file",                                 normalized => "file" },
                              string    => { origin => "file:c|/path/to/file",                 decoded => "file:c|/path/to/file",                 normalized => "file:C|/path/to/file" },
                              drive     => { origin => "c",                                    decoded => "c",                                    normalized => "C" },
                              path      => { origin => "c|/path/to/file",                      decoded => "c|/path/to/file",                      normalized => "C|/path/to/file" },
                              segments  => { origin => ["c|", "path", "to", "file"],           decoded => ["c|", "path", "to", "file"],           normalized => ["C|", "path", "to", "file"] }
                             },
   "file:///c|/path/to/file" => {
                              scheme    => { origin => "file",                                 decoded => "file",                                 normalized => "file" },
                              string    => { origin => "file:///c|/path/to/file",              decoded => "file:///c|/path/to/file",              normalized => "file:///C|/path/to/file" },
                              drive     => { origin => "c",                                    decoded => "c",                                    normalized => "C" },
                              path      => { origin => "/c|/path/to/file",                     decoded => "/c|/path/to/file",                     normalized => "/C|/path/to/file" },
                              segments  => { origin => ["c|", "path", "to", "file"],           decoded => ["c|", "path", "to", "file"],           normalized => ["C|", "path", "to", "file"] }
                             },
   "file:/c|/path/to/file" => {
                              scheme    => { origin => "file",                                 decoded => "file",                                 normalized => "file" },
                              string    => { origin => "file:/c|/path/to/file",                decoded => "file:/c|/path/to/file",                normalized => "file:/C|/path/to/file" },
                              drive     => { origin => "c",                                    decoded => "c",                                    normalized => "C" },
                              path      => { origin => "/c|/path/to/file",                     decoded => "/c|/path/to/file",                     normalized => "/C|/path/to/file" },
                              segments  => { origin => ["c|", "path", "to", "file"],           decoded => ["c|", "path", "to", "file"],           normalized => ["C|", "path", "to", "file"] }
                             },
  );

foreach my $origin (sort keys %DATA) {
  my $uri = MarpaX::ESLIF::URI->new($origin);
  isa_ok($uri, 'MarpaX::ESLIF::URI::file', "\$uri = MarpaX::ESLIF::URI->new('$origin')");
  my $methods = $DATA{$origin};
  foreach my $method (sort keys %{$methods}) {
    foreach my $type (sort keys %{$methods->{$method}}) {
      my $got = $uri->$method($type);
      my $expected = $methods->{$method}->{$type};
      my $test_name = "\$uri->$method('$type')";
      if (ref($expected)) {
        eq_or_diff($got, $expected, "$test_name is " . (defined($expected) ? (ref($expected) eq 'ARRAY' ? "[" . join(", ", map { "'$_'" } @{$expected}) . "]" : "$expected") : "undef"));
      } else {
        is($got, $expected, "$test_name is " . (defined($expected) ? "'$expected'" : "undef"));
      }
    }
  }
}

done_testing();
