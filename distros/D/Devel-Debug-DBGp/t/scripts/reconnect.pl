my $i = 0;

$i = 1;

# here we detach

$i = 2;
$i = 3;

# reconnect (actual use case is multiple uWSGI requests)

DB::connectOrReconnect();
$DB::single = 1;

$i = 4;

$i++; # just to avoid the program exiting
