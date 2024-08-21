#! perl

use v5.26;
use strict;

use Test::More tests => 6;
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

#### Object serialization

my $data = { a => bless { "xx" => { a => "yy" } } => 'Ape' };

# Used serializer.
is( $p->encode( data => $data ), "a{a:yy}", "Objects" );

package Ape {

sub TO_JSON { $_[0]->{xx} }

}

$data = { a => bless {} => 'Nut' };

# "true" is just another string.
is( $p->encode( data => $data ), "a:\"true\"", "Objects" );

package Nut {

sub TO_JSON { "true" }

}

$data = { a => bless {} => 'Mice' };

# A boolean object is boolean.
is( $p->encode( data => $data ), "a:true", "Objects" );

package Mice {

sub TO_JSON { $JSON::Boolean::true }

}
