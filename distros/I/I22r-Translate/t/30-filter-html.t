use I22r::Translate::Filter::HTML;
use I22r::Translate::Request;
use Test::More;
use Data::Dumper;

my $input1 = "<a href='foo'>bar</a>";
my $input2 = "<p/>hello, <i>Ivan</i>";
my $input3 = "nothing special";

my $req = I22r::Translate::Request->new(
    src => 'ab', dest => 'cd', 
    text => { 1 => $input1, 2 => $input2, 3 => $input3 } );

my $f = I22r::Translate::Filter::HTML->new;
ok($f, 'HTML filter created');

$f->apply($req, $_) for 1, 2, 3;

my %input = %{ $req->text };

ok($f->{map}, 'map created');
ok($req->{otext}, 'otext created');
ok(!$f->{map}{1}{__begin__}, 'no begin token on input 1');
ok($f->{map}{2}{__begin__}, 'begin token on input 2');
ok($input{1} =~ /bar/, 'text preserved on input 1');
ok($input{1} !~ /href/, 'html protected on input 1');
ok($input{2} =~ /hello.*Ivan/, 'text preserved on input 2');
ok($input{2} !~ /<i>/, 'html protected on input 2');
ok($input{3} eq $input3, 'input 3 preserved');

$f->unapply($req, $_) for 1, 2, 3;
my %r = map { $_ => { TEXT => $req->text->{$_} } } 1,2,3;

ok($r{1}{TEXT} eq $input1, 'postprocess restored input 1');
ok($r{2}{TEXT} eq $input2, 'postprocess restored input 2');

##########################################################

done_testing();



   
