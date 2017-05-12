use Test::More tests => 3;

use HTML::Declare ':all';

my $html = HTML {
    _ => [
        HEAD { _ => [ TITLE { _ => 'Hello World!' } ] },
        BODY { _ => 'Hello World!' }
    ]
};
is( "$html\n", <<'EOF', 'Simple HTML ducument generated' );
<html><head><title>Hello World!</title></head><body>Hello World!</body></html>
EOF

my $html2 = HTML {
    _ => [
        HEAD { _ => TITLE { _ => 'Hello World!' } },
        BODY { _ => '<lalala><quoteme><br/>' }
    ]
};
is( "$html2\n", <<'EOF', 'Simple HTML documument with quoted text generated' );
<html><head><title>Hello World!</title></head><body>&lt;lalala&gt;&lt;quoteme&gt;&lt;br/&gt;</body></html>
EOF

my $html3 =
  DIV { _ => [ A { href => 'http://127.0.0.1', _ => '<< Home Sweet Home!' } ] };
is( "$html3\n", <<'EOF', 'Simple HTML snippet with quoted text generated' );
<div><a href="http://127.0.0.1">&lt;&lt; Home Sweet Home!</a></div>
EOF
