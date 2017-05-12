package Test::HTML::FormHandlerX::Field::reCAPTCHA;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';

has_field 'recaptcha' => (
    type=>'reCAPTCHA', 
    public_key=>'public',
    private_key=>'private',
    required=>1,
);

use Test::More;

ok my $form = Test::HTML::FormHandlerX::Field::reCAPTCHA->new,
  'Created Form';

done_testing;
