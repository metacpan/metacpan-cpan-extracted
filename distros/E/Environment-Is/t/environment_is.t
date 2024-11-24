use Test2::V0 -no_srand => 1;
use Environment::Is qw( is_docker is_interactive is_wsl );

diag '';
diag '';
diag '';

diag "is_docker      = @{[ is_docker ]}";
diag "is_interactive = @{[ is_interactive ]}";
diag "is_wsl         = @{[ is_wsl ]}";

diag '';
diag '';

ok 1;

done_testing;


