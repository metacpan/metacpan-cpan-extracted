use Kelp::Base -strict;
use Test::More;
use lib 't/lib';
use MyApp;
use Class::Inspector;

my $app = MyApp->new( mode => 'preload' );

for ( qw/Author Book/ ) {
    ok(Class::Inspector->loaded("MyApp::DB::$_"));
}


done_testing;
