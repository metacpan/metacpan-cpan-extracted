use Test::More;

use Hazy;
use lib '.';
subtest basics => sub {
	run_test({
		find => 'css',
		files => [ qw/a.css b.css c.css/ ],
		expected_count => 3,
	});
	run_test({
		find => 'less',
		files => [ qw/a.less b.less c.less d.less e.less/ ],
		expected_count => 5,
	});
	run_test({
		find => 'meh',
		files => [ qw/a.meh b.meh c.meh d.meh e.meh f.meh g.meh h.meh/ ],
		expected_count => 8,
	});
};

sub run_test {
    my $new_dir = sprintf "t/lemon/%s", int( rand(10000000) );
    mkdir $new_dir;
    for my $file ( @{ $_[0]->{files} }, 'config' ) {
	    my $actual = sprintf "%s/%s", $new_dir, $file;
	    open my $before, ">", $actual;
	    print $before "test";
	    close $before;
    }

    my $hazy = Hazy->new( find => $_[0]->{find} );
    my ($config, @files ) = $hazy->lookup_dir($new_dir);
    is( scalar @files, $_[0]->{expected_count}, "expected output" );

    for my $file ( @{ $_[0]->{files} }, 'config' ) {
	    my $after = sprintf "%s/%s", $new_dir, $file;
    	    unlink ($after);
    }
    rmdir $new_dir;
};

done_testing();
