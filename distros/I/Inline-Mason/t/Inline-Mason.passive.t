use Test::More qw(no_plan);
use Inline::Mason qw(passive as_subs);
Inline::Mason::load_file('t/external_mason');
like( NIFTY(lang => 'Inline::Mason'), qr/Inline::Mason/, 'nifty passive');

__END__
