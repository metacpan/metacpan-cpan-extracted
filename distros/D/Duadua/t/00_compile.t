use Test::AllModules;

my %win_option = ();
if ($^O eq 'MSWin32') {
    # In case of MSWin32, Cwd.pm calls Win32.pm at runtime
    %win_option = (
        'lib' => ['lib', @INC],
    );
}

all_ok(
    search_path => 'Duadua',
    use_ok      => 1,
    fork        => 0,
    shuffle     => 1,
    %win_option
);
