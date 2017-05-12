use Kelp::Base -strict;
 
use Kelp;
use Kelp::Test;
use HTTP::Request::Common;
use Test::More;

my $app = Kelp->new();
$app->load_module('ValidateTiny', subs => [ qw{filter is_required} ]);

my $t = Kelp::Test->new( app => $app );

$app->add_route('/home/:id/:name', sub {
    
    my $self = shift;
    my $rules = {
        fields => [ qw{id name} ],
        filters => [
           qr/.+/ => filter('trim'),
           name => filter('uc'),
        ],
        checks => [
           qr/.+/ => is_required(),
           name => sub {return (shift eq 'PERL') ? undef : 'Value must be PERL';},
        ],
    };
    
    my $res = $self->validate($rules);
    my $val = $res->success ? $res->data->{id} . '|' . $res->data->{name}: 0;
   
    $self->res->text->render($val);
});

can_ok $app, $_ for qw{validate};

$t->request( GET '/home/42/perl', Content_Type => 'text/plain' )
  ->code_is(200)
  ->content_is('42|PERL');

$t->request( GET '/home/42/Python', Content_Type => 'text/plain' )
  ->code_is(200)
  ->content_is('0');

$app->add_route([POST => '/home'], sub {
    
    my $self = shift;
    my $rules = {
        fields => [ qw{id name} ],
        filters => [
           qr/.+/ => filter('trim'),
           name => filter('uc'),
        ],
        checks => [
           qr/.+/ => is_required(),
           name => sub {return (shift eq 'PERL') ? undef : 'Value must be PERL';},
        ],
    };
    
    my $res = $self->validate($rules);
    my $val = $res->success ? $res->data->{id} . '|' . $res->data->{name}: 0;
   
    $self->res->text->render($val);
});

can_ok $app, $_ for qw{validate};

$t->request( POST '/home', [id => 42, name => 'perl'] )
  ->code_is(200)
  ->content_is('42|PERL');

$t->request( POST '/home', [id => 21, name => 'Python'] )
  ->code_is(200)
  ->content_is('0');

done_testing;



