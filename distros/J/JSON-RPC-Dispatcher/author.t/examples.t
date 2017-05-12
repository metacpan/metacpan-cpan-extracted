use LWP::UserAgent;
use Test::More tests=>9;

my $ua = LWP::UserAgent->new;

unless ($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"ping","id":"1"}')->is_success) {
    die "You need to 'plackup -E prod eg/app.psgi' before running these tests!";
}

is($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"ping","id":"1"}')->content,
    '{"jsonrpc":"2.0","id":"1","result":"pong"}',
    'ping test');

is($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"echo","params":["Hello World!"],"id":"1"}')->content,
    '{"jsonrpc":"2.0","id":"1","result":"Hello World!"}',
    'echo test');

is($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"echo","params":["déjà vu"],"id":"1"}')->content,
    '{"jsonrpc":"2.0","id":"1","result":"déjà vu"}',
    'utf8 parameter test');

is($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"sum","params":[2,3,5],"id":"1"}')->content,
    '{"jsonrpc":"2.0","id":"1","result":10}',
    'sum test');

is($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"guess","params":[5],"id":"1"}')->content,
    '{"jsonrpc":"2.0","error":{"data":5,"message":"Too low.","code":987},"id":"1"}',
    'guess low test');

is($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"guess","params":[15],"id":"1"}')->content,
    '{"jsonrpc":"2.0","error":{"data":15,"message":"Too high.","code":986},"id":"1"}',
    'guess high test');

is($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"guess","params":[10],"id":"1"}')->content,
    '{"jsonrpc":"2.0","id":"1","result":"Correct!"}',
    'guess correct test');

is($ua->post('http://localhost:5000/', Content=>'{"jsonrpc":"2.0","method":"ping"}')->code,
    204,
    'notification test');

is($ua->post('http://localhost:5000/', Content=>'[{"jsonrpc":"2.0","method":"ping"},{"jsonrpc":"2.0","method":"guess","params":[10],"id":"1"},{"jsonrpc":"2.0","method":"guess","params":[5],"id":"1"}]')->content,
    '[{"jsonrpc":"2.0","id":"1","result":"Correct!"},{"jsonrpc":"2.0","error":{"data":5,"message":"Too low.","code":987},"id":"1"}]',
    'bulk test');


