$_ = "abc";
/b/;

$DB::single = 1;

"axc" =~ /x/;

$DB::single = 1;

eval '$`, $&, $\'';

"abc" =~ /b/;

$DB::single = 1;

1; # to avoid the program terminating
