use Kelp::Base -strict;
 
use Kelp;
use Kelp::Test;
use HTTP::Request::Common;
use Test::More;

my $app = Kelp->new();
$app->load_module('ValidateTiny');

my $t = Kelp::Test->new( app => $app );

$app->add_route('/home', sub {
    
    my $self = shift;
    return $self->res->text->render('I am home');
});

$t->request( GET '/home', Content_Type => 'text/plain' )
  ->code_is(200)
  ->content_is('I am home');

$app->add_route('/home/:id', sub {
    
    my $self = shift;
    my $rules = {
    	fields => [ qw{id} ],
    	filters => [
    	   id => sub {
    	   	   
    	   	   my $value = shift;
    	   	   $value =~ s/^\s+//;
    	   	   $value =~ s/\s+$//;
    	   	   
    	   	   return $value;
    	   },
    	],
    	checks => [
    	   
    	   id => sub {return (shift eq '42') ? undef : 'Value must be 42';},
    	],
    };
    
    my $res = $self->validate($rules);
    my $val = $res->success ? $res->data->{id} : 0;
   
    $self->res->text->render($val);
});

can_ok $app, $_ for qw{validate};

$t->request( GET '/home/42', Content_Type => 'text/plain' )
  ->code_is(200)
  ->content_is('42');

$t->request( GET '/home/21', Content_Type => 'text/plain' )
  ->code_is(200)
  ->content_is('0');

$app->add_route('/query/:id', sub {
    
    my $self = shift;
    my $rules = {
        fields => [ qw{id name} ],
        filters => [
           qr/.+/ => sub {
               
               my $value = shift;
               $value =~ s/^\s+//;
               $value =~ s/\s+$//;
               
               return $value;
           },
        ],
        checks => [
           
           id => sub {return (shift eq '42') ? undef : 'Value must be 42';},
           name => sub {return (shift eq 'Perl') ? undef : 'Value must be Perl';}
        ],
    };
    
    my $res = $self->validate($rules);
    my $val = $res->success ? $res->data->{id} . '|' . $res->data->{name} : 0;
   
    $self->res->text->render($val);
});

$t->request( GET '/query/42?name=Perl', Content_Type => 'text/plain' )
  ->code_is(200)
  ->content_is('42|Perl');

$t->request( GET '/home/21?name=Python', Content_Type => 'text/plain' )
  ->code_is(200)
  ->content_is('0');

done_testing;



