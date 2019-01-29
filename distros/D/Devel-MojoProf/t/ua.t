use Mojo::Base -strict;
use Devel::MojoProf -ua;
use Test::More;

$ENV{MOJO_LOG_LEVEL} = 'warn' unless $ENV{HARNESS_IS_VERBOSE};

use Mojolicious::Lite;
for my $name (qw(blocking non-blocking promise)) {
  get "/$name" => sub {
    my $c = shift;
    Mojo::IOLoop->timer(rand(0.2), sub { $c->render(text => $name) });
  };
}

my @report;
Devel::MojoProf->singleton->reporter(sub {
  push @report, $_[1];
  shift->Devel::MojoProf::_default_reporter(@_) if $ENV{HARNESS_IS_VERBOSE};
});

my $ua = Mojo::UserAgent->new;
$ua->ioloop(Mojo::IOLoop->singleton);
$ua->server->app(app);

$ua->get('/blocking');
is $report[-1]{class},     'Mojo::UserAgent',         'report class';
is $report[-1]{method},    'start',                   'report method';
like $report[-1]{message}, qr{^GET http\S+/blocking}, 'report blocking';
like $report[-1]{elapsed}, qr{^\d+\.\d+$},            'report elapsed';
like $report[-1]{file},    qr{ua\.t$},                'report file';
like $report[-1]{line},    qr{^\d+$},                 'report line';
like $report[-1]{t0}[0], qr{^\d+$}, 'report t0.0';
like $report[-1]{t0}[1], qr{^\d+$}, 'report t0.1';

$ua->get('/non-blocking', sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
like $report[-1]{message}, qr{^GET http\S+/non-blocking}, 'report non-blocking';

$ua->get_p('/promise')->wait;
like $report[-1]{message}, qr{^GET http\S+/promise}, 'report promise';

done_testing;
