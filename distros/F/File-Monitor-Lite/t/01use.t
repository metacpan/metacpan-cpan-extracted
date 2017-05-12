use Test::More tests => 9;

use_ok 'File::Monitor::Lite' ;
note 'different init test';
new_ok File::Monitor::Lite => [name=> '*.test', in => '.',];
new_ok File::Monitor::Lite => [name=> qr/.+\.haml/, in => '.',];
new_ok File::Monitor::Lite => [name=> ['*.html',qr/.+\.tt$/,], in => '.',];
my $m1 = File::Monitor::Lite->new( name => ['*.test'], in => '.',);
foreach $meth (qw(check modified created deleted observed)){
    can_ok $m1, $meth;
}
