use strict;
use Test;
BEGIN {
    plan(tests => 1, 
	 todo => [],
	 onfail => sub {},
	);
    mkdir('./_cpr', 0777) unless -d './_cpr';
}

use Inline Config => 
           DIRECTORY => './_cpr/';
use Inline CPR => <<'END';

int main(void) {
        
    printf("Hello World, I'm running under Perl version %s\n",
           CPR_eval("use Config; $Config{version}")
          );

    return 42;
}

END

# test 1
ok(cpr_main == 42);
