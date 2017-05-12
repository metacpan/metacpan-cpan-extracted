use strict;
use Test::More tests => 4;

BEGIN {
    use_ok 'Env::Heroku::Pg';
    use_ok 'Env::Heroku::Redis';
    use_ok 'Env::Heroku::Rediscloud';
    use_ok 'Env::Heroku::Cloudinary';
}
