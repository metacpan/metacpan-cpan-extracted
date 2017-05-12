use strict;

use Cwd;
use File::Spec;

use HTML::Mason::Tests;

print "1..9\n";

my $comp_root = File::Spec->catdir( getcwd(), 'mason_tests', 'comps' );
($comp_root) = $comp_root =~ /(.*)/;
my $data_dir = File::Spec->catdir( getcwd(), 'mason_tests', 'data' );
($data_dir) = $data_dir =~ /(.*)/;

my $tests = HTML::Mason::Tests->tests_class->new( name => 'print',
                                                  description => 'printing to standard output' );

my $interp = HTML::Mason::Tests->tests_class->_make_interp
    ( comp_root => $comp_root,
      data_dir => $data_dir
      );

{
    my $source = <<'EOF';
ok 1
% print "ok 2\n";
EOF

    my $comp = $interp->make_component( comp_source => $source );

    my $req = $interp->make_request(comp=>$comp);

    $req->exec();
}

# same stuff but with autoflush
{
    my $source = <<'EOF';
ok 3
% print "ok 4\n";
EOF

    my $comp = $interp->make_component( comp_source => $source );

    my $req = $interp->make_request( comp=>$comp, autoflush => 1 );

    $req->exec();
}

{
    my $source = <<'EOF';
ok 5
% print "ok 6\n";
ok 7
% print "ok 8\n";
% print "", "ok ", "9", "\n";
EOF

    my $comp = $interp->make_component( comp_source => $source );

    my $req = $interp->make_request( comp=>$comp );

    $req->exec();
}
