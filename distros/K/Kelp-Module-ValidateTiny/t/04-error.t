use Kelp::Base -strict;
 
use Kelp;
use Kelp::Test;
use HTTP::Request::Common;
use Test::More;

my $app = Kelp->new();
$app->load_module('ValidateTiny', , subs => [ qw{filter is_required} ]);

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
    
    my $rval = $self->validate($rules,
    	on_error => 'form.tt',
    	data => {
    		message => 'Fail!',
    	}
    );
    return $rval->response 
        unless $rval->success;
   
    $self->template('success.tt', $rval->data);
});

can_ok $app, $_ for qw{validate};

$t->request( GET '/home/42/perl', Content_Type => 'text/plain' )
  ->code_is(200)
  ->content_is('|42|PERL|');

$t->request( GET '/home/42/Python', Content_Type => 'text/plain' )
  ->code_is(200)
  ->content_is('42|Value must be PERL|Fail!');

done_testing;



