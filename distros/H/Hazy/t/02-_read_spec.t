use Test::More;

use Hazy;
use lib '.';

subtest basics => sub {
	run_test({
		string => '$one: #fff; %two: 0 auto;',
		expected => { '$one' => '#fff', '%two' => '0 auto' },
	});
	run_test({
		string => '&one: #fff; @two: 0 auto;',
		expected => { '&one' => '#fff', '@two' => '0 auto' },
	});
	run_test({
		string => '!one: #fff; *two: 0 auto;',
		expected => { '!one' => '#fff', '*two' => '0 auto' },
	});
	run_test({
		string => '`one: #fff; )two: 0 auto; (three: 0 0 0 0;',
		expected => { '`one' => '#fff', ')two' => '0 auto', '(three' => '0 0 0 0' },
	});
	run_test({
		string => '$one: #fff; $two: 0 auto; %three: ! margin:0 0 0 0; color:#ccc; !',
		expected => { '$one' => '#fff', '$two' => '0 auto', '%three' => 'margin:0 0 0 0; color:#ccc;' },
	});
};

sub run_test {
    my $new_dir = sprintf "t/lemon/%s", getcwd, int( rand(10000000) );
    mkdir $new_dir;
    my $file = sprintf "%s/config", $new_dir;

    open my $before, ">", $file;
    print $before $_[0]->{string};
    close $before;
    is_deeply( &Hazy::_read_spec($file), $_[0]->{expected}, "expected output" );
    unlink ($file);
    rmdir $new_dir;
};

done_testing();
