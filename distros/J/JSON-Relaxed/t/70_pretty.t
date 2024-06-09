#! perl

use v5.26;
use strict;

use Test::More tests => 3;
use JSON::Relaxed;
note("JSON::Relaxed version $JSON::Relaxed::VERSION\n");

# PRP extensions.

my $json = <<'EOD';
# Lovely day
pdf.formats {
  title.footer = [ "%{copyright}", "", "%{page}" ]
  first.footer = [ "%{copyright}", "", "" ]
}
EOD

# Use combined keys.
my $p = JSON::Relaxed::Parser->new( croak_on_error => 0,
				    key_order => 1,
				    prp => 1 );
my $res = $p->parse($json);
my $xp = {
  pdf => {
    formats => {
      " key order " => [ qw(title first) ],
      first => {
        footer => [
          '%{copyright}',
          '',
          '',
        ],
      },
      title => {
        footer => [
          '%{copyright}',
          '',
          '%{page}',
        ],
      },
    },
  },
};
is_deeply( $res, $xp, "decode" );
diag($p->err_msg) if $p->is_error;

$res = $p->encode( data => $xp, pretty => 0, key_order => 1 );
is( "$res\n", <<EOD, "encode compact");
pdf.formats{title.footer:["%{copyright}","","%{page}"]first.footer:["%{copyright}","",""]}
EOD
$res = $p->parse($json);
$res = $p->encode( data => $res, pretty => 1 );
is( $res, <<EOD, "encode pretty");
pdf.formats {
  title.footer : [ "%{copyright}" "" "%{page}" ]
  first.footer : [ "%{copyright}" "" "" ]
}
EOD
