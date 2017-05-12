use strict;
use Test::More (tests => 8);

BEGIN
{
    use_ok("DateTime");
    use_ok("HTTP::Headers");
    use_ok("HTTP::RobotsTag");
}

my $p = HTTP::RobotsTag->new();
ok($p);
isa_ok($p, "HTTP::RobotsTag");

my $header = HTTP::Headers->new(
    'X-Robots-Tag' => 'unavailable_after: 7 Jul 2007 15:30:00 JST'
);

my $rules = $p->parse_headers($header);

ok( $rules->can_index, "can index" );

{
    my $limit = DateTime->new( year => 2007, month => 7, day => 1);
    ok( $rules->is_available( $limit ), "is available on $limit" );
}

{
    my $limit = DateTime->new( year => 2007, month => 8, day => 1);
    ok( ! $rules->is_available( $limit ), "is not available on $limit" );
}