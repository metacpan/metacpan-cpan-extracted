#!/usr/bin/perl -w
use strict;
use Test::More tests => 30;
use Test::MockModule;

require_ok('CGI::Maypole');
ok($CGI::Maypole::VERSION, 'defines $VERSION');
ok($INC{'CGI/Simple.pm'}, 'requires CGI::Simple');
ok($INC{'Maypole/Headers.pm'}, 'requires Maypole::Headers');
ok(CGI::Maypole->isa('Maypole'), '@ISA = Maypole');

my %calls;
my $mock_maypole = new Test::MockModule('CGI::Maypole');
my $mock_cgi = new Test::MockModule('CGI::Simple');
$mock_cgi->mock(path_info => sub {
    delete $_[0]->{'.path_info'};
    my $orig_path_info = $mock_cgi->original('path_info');
    goto $orig_path_info;
});

# run()
can_ok('CGI::Maypole' => 'run');
$mock_maypole->mock(handler => sub {$calls{handler} = \@_; 'X'});
my $status = CGI::Maypole->run('TEST');
ok($calls{handler}, '... calls handler()');
is_deeply($calls{handler}, ['CGI::Maypole'],
          '... as a method, passing 0 arguments');
is($status, 'X', '... and returns its status');

my $r = bless {}, 'CGI::Maypole';
$r->headers_out(Maypole::Headers->new);
$ENV{HTTP_HOST}      = 'localhost';
$ENV{SCRIPT_NAME}    = '/maypole/index.cgi';
$ENV{PATH_INFO}      = '/';
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'beer=1;beer=2;pub=red+lion;handpump';
$ENV{DOCUMENT_ROOT}  = '/var/tmp/maypole';
for (keys %ENV) {
    delete $ENV{$_} if /^HTTPS?/;
}

# get_request()
can_ok($r => 'get_request');
my $cgi = $r->get_request;
isa_ok($cgi, 'CGI::Simple', '... returns a CGI::Simple object');
is($cgi, $r->{cgi}, '... and stores it in the "cgi" slot');

# parse_location()
can_ok($r => 'parse_location');
$ENV{HTTP_REFERER} = 'http://maypole.perl.org/';
$ENV{HTTP_USER_AGENT} = 'tty';
$r->parse_location;
is($r->headers_in->get('Referer'), 'http://maypole.perl.org/',
   '... sets headers_in() from HTTP variables');
is_deeply([$r->headers_in->field_names], [qw(Referer User-Agent)],
   '... loads only those HTTP variables');
is($r->path, 'frontpage', '... sets "path" to frontpage if undefined');

#delete $r->{cgi}{'.path_info'};
$ENV{PATH_INFO} = '/brewery/view/1/2/3';
$r->parse_location;
is($r->path, 'brewery/view/1/2/3', '... path is PATH_INFO without leading /');
is($r->table, 'brewery', '... sets "table" to first part of PATH_INFO');
is($r->action, 'view', '... sets "action" to second part of PATH_INFO');
is_deeply($r->args, [1,2,3],
          '... sets "args" to a list of remaining path segments');

$mock_maypole->mock(
    parse_path => sub {$calls{parse_path} = \@_},
    parse_args => sub {$calls{parse_args} = \@_},
);
$r->parse_location;
is_deeply($calls{parse_path}, [$r], '... calls parse_path');
is_deeply($calls{parse_args}, [$r], '... calls parse_args');


# parse_args()
$mock_maypole->unmock('parse_args');
can_ok($r => 'parse_args');
$cgi->parse_query_string;
$r->parse_args;
is_deeply($r->params, { beer => [1,2], pub => 'red lion', handpump => undef },
          '... parsed params');
is_deeply($r->params, $r->query, '... query and params are identical');

# send_output()
can_ok($r => 'send_output');
SKIP: {
    eval "require IO::CaptureOutput";
    skip "IO::CaptureOutput not installed", 2 if $@;
    $r->content_type('text/plain');
    $r->document_encoding('iso8859-1');
    $r->output('Hello World!');

    my $stdout;
    eval {
        IO::CaptureOutput::capture(sub {$r->send_output}, \$stdout);
    };
    diag $@ if $@;
    my $compare = join "\cM\cJ", 'Content-length: 12',
        'Content-Type: text/plain; charset=iso8859-1', '', 'Hello World!';
    is($stdout, $compare, '... prints output, including content-type header');

    # test custom output headers
    $r->headers_out->set(X_Bender => 'kiss my shiny metal ass');
    eval {
        IO::CaptureOutput::capture(sub {$r->send_output}, \$stdout);
    };
    diag $@ if $@;

    my $CL = 'Content-length: 12';
    my $XB = 'X-bender: kiss my shiny metal ass';
    my $nl = "\cM\cJ";
    my $re = join $nl, "($CL$nl$XB)|($XB$nl$CL)",
        'Content-Type: text/plain; charset=iso8859-1',
        '', 'Hello World!';
    like($stdout, qr/$re/, '... prints output, including custom headers');
}

# get_template_root()
can_ok($r => 'get_template_root');
is($r->get_template_root(), '/var/tmp/maypole/index.cgi',
   '... catdir(document_root, [relative_url])');
