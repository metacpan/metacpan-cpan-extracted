BEGIN {
  $ENV{DEVEL_MOJOPROF_OUT_CSV} = 1;
}

use Mojo::Base -strict;
use Devel::MojoProf ();
use Test::More;

my $prof = Devel::MojoProf->singleton;

plan skip_all => $@ unless eval {
  my $t0 = [Time::HiRes::gettimeofday];
  $prof->reporter->report({
    file    => $0,
    line    => __LINE__,
    class   => 'Cool::Class',
    method  => "my_cool_method",
    t0      => $t0,
    elapsed => Time::HiRes::tv_interval($t0),
    message => qq(SELECT 1 as "something with quotes" and comma,),
  });
};

$ENV{MOJO_LOG_LEVEL} = 'warn' unless $ENV{HARNESS_IS_VERBOSE};

use Mojolicious::Lite;
for my $name (qw(blocking non-blocking promise)) {
  get "/$name" => sub {
    my $c = shift;
    Mojo::IOLoop->timer(rand(0.05), sub { $c->render(text => $name) });
  };
}

like $prof->reporter->out_csv, qr{\bdevel-mojoprof-reporter-\d+\.csv$}, 'generate out_csv';

my $ua = Mojo::UserAgent->new;
$ua->ioloop(Mojo::IOLoop->singleton);
$ua->server->app(app);
$prof->add_profiling_for('ua');
$ua->get('/blocking') for 1 .. 10;

my $csv   = Mojo::File->new($prof->reporter->out_csv);
my @lines = split /\n\r?/, $csv->slurp;
is @lines, 12, 'reported to file';
like $lines[0], qr{^t0,elapsed,class,method,file,line,message}, 'columns';
like $lines[1], qr{^\d+,0\.\d+,Cool::Class,my_cool_method,$0,15,"SELECT 1 as ""something with quotes"" and comma,"},
  'report with quotes';
like $lines[11], qr{^\d+,\d\.\d+,Mojo::UserAgent,start,$0,40,"GET \S+/blocking"}, 'report from ua';

unlink $prof->reporter->out_csv unless $ENV{TEST_KEEP_CSV};

done_testing;
