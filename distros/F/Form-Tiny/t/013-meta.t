use v5.10;
use warnings;
use Test::More;
use lib 't/lib';
use TestForm;

my $form = TestForm->new;
isa_ok $form->form_meta, 'Form::Tiny::Meta';

done_testing();
