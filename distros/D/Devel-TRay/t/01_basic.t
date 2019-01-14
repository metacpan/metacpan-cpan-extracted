use Test::More;
use Capture::Tiny ':all';
use Data::Dumper;

BEGIN {
    use_ok('Devel::TRay');
    use_ok('DB');
}

subtest "Devel::TRay::_get_enabled_module_filters" => sub {

    # _get_enabled_module_filters must return only values which
    # 1) starts from _hide
    # 2) are true = 1 or some string value

    use_ok( 'Devel::TRay',
        'subs_matching=X:hide_core=1:hide_abc=1:hide_xyz=0' );

    is_deeply(
        DB::_get_enabled_module_filters(),
        [ 'hide_abc', 'hide_core' ],
        'Return abc sorted where val = 1 or some str'
    );

    use_ok( 'Devel::TRay', 'xyz=1:abc=0:foo=bar' );
    is_deeply( DB::_get_enabled_module_filters(),
        [], 'Empty list when no filters used' );
};

subtest "DB::_extract_module_name" => sub {
    ok( 'Data::Dumper' eq DB::_extract_module_name('Data::Dumper::Dump'),
        'Data::Dumper::Dump' );
    ok( 'Module::Load' eq DB::_extract_module_name('Module::Load::_load'),
        "Sub name starts from _" );
    ok( '(eval)' eq DB::_extract_module_name('(eval)'),
        "Sub name without :: " );
};

# data for testing, list of modules
my $m = {
    cpan => [
        'CPAN',             'Module::Load',
        'Module::CoreList', 'Data::Dumper',
        'File::Slurper',    'Moose'
    ],
    core  => [ 'CPAN',        'Module::Load', 'Module::CoreList' ],
    other => [ 'CCXX::Debug', 'XPortal',      'ABC' ]
};

subtest "DB::_is_cpan_published" => sub {
    ok DB::_is_cpan_published( $m->{cpan}[0] ),
      $m->{cpan}[0] . ' is published on CPAN';
    ok !DB::_is_cpan_published( $m->{other}[0] ),
      $m->{other}[0] . ' is NOT published on CPAN';
};

subtest "DB::_is_core" => sub {
    ok DB::_is_core( $m->{core}[0] ),   $m->{core}[0] . ' is core module';
    ok !DB::_is_core( $m->{other}[0] ), $m->{other}[0] . ' is not core module';
};

subtest "DB::_is_eval" => sub {
    ok DB::_is_eval('(eval)'),              'Is eval';
    ok !DB::_is_eval('Data::Dumper::Dump'), 'Not eval';
};

subtest "DB::_check_filter" => sub {
    ok DB::_check_filter( 'hide_core', $m->{core}[0] ),
      $m->{core}[0] . ' hide_core OK';
    ok !DB::_check_filter( 'hide_core', $m->{other}[0] ),
      $m->{core}[0] . ' hide_core NOT OK';

    ok DB::_check_filter( 'hide_cpan', $m->{cpan}[0] ),
      $m->{core}[0] . ' hide_cpan OK';
    ok !DB::_check_filter( 'hide_cpan', $m->{other}[0] ),
      $m->{core}[0] . ' hide_cpan NOT OK';

    ok DB::_check_filter( 'hide_eval', '(eval)' ), 'hide_eval OK';
    ok !DB::_check_filter( 'hide_eval', $m->{other}[0] ),
      $m->{other}[0] . ' hide_eval NOT OK';
};

subtest "DB::_leave_in_trace" => sub {
    use_ok( 'Devel::TRay', 'hide_core=1:hide_cpan=1:hide_eval=1' );
    my $f = DB::_get_enabled_module_filters();
    ok !DB::_leave_in_trace( $m->{cpan}[3], $f );
    ok !DB::_leave_in_trace( $m->{core}[0], $f );
    ok !DB::_leave_in_trace( '(eval)',      $f );
    ok DB::_leave_in_trace( $m->{other}[0], $f );
};

subtest "DB::_filter_calls" => sub {
    use_ok( 'Devel::TRay', 'hide_core=1:hide_cpan=1:hide_eval=1' );
    my $t = [
        { 'sub' => 'CODE(0x2c207b0)', 'depth' => 2 },
        { 'sub' => 'UNIVERSAL::can',  'depth' => 3 },
        { 'sub' => 'main::foo',       'depth' => 1 }
    ];
    DB::_filter_calls($t);
    is_deeply $t, [ { 'sub' => 'main::foo', 'depth' => 1 } ],
      'Filter is correct';
    is_deeply $DB::traced_modules, ['main'], 'Traced list is ok';

    # parent calls filters
    # + trace folding
};

subtest "main" => sub {
    my $options = 'hide_core=1:hide_cpan=1:hide_eval=1:show_lines=0';
    my $stderr  = capture_stderr {
        system( 'perl -d:TRay=' . $options . ' t/test.pl' );
    };
    is $stderr, "  main::foo\n    main::bar\n",
      "Trace print is fine and default indent is two spaces";
};

done_testing();
