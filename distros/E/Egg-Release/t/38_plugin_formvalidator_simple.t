use Test::More;
use lib qw( ./lib ../lib );
use Egg::Helper;

eval{ require FormValidator::Simple };

if ($@) { plan skip_all=> "FormValidator::Simple is not installed." } else {

plan tests=> 5;

ok my $e= Egg::Helper->run
   ( Vtest=> { vtest_plugins=> [qw/ FormValidator::Simple /] } );

can_ok $e, 'form';
  ok my $form= $e->form, q{$form= $e->form};
  isa_ok $form, 'FormValidator::Simple::Results';

can_ok $e, 'set_invalid_form';

}

