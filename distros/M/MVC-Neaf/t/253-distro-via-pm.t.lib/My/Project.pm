package My::Project;

use strict;
use warnings;

use MVC::Neaf;

neaf static => '/files' => './static';
neaf view => 'tt' => 'TT', INCLUDE_PATH => './tpl';

get '/index.html',
    -view => 'tt',
    -template => 'index.tt',
    sub {
        return { name => 'world' };
    };

neaf->run;

