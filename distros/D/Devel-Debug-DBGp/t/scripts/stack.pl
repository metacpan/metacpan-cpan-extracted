sub fact {
    $DB::single = 1;

    return $_[0] == 1 ? 1 : $_[0] * fact($_[0] - 1);
}

$DB::single = 1;

fact(5);

$DB::single = 1;

eval {
    $DB::single = 1;

    eval <<'EOT';
$DB::single = 1;

1; # avoid return
EOT

    1; # avoid return
};

require 't/scripts/break.pm';

1; # avoid exit
