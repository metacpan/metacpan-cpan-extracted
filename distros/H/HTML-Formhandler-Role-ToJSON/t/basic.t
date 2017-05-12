use Test::Most;

BEGIN {
  package MyApp::Form::Email;

  use HTML::FormHandler::Moose;

  extends 'HTML::FormHandler';
  with 'HTML::Formhandler::Role::ToJSON';

  has_field 'email' => (
    type=>'Email',
    size => 96,
    required => 1);

  has_field 'fname' => (
    type=>'Text',
    size => 96,
    required => 1);

  has_field 'lname' => (
    type=>'Text',
    size => 96,
    required => 1);
}

{
  ok my $form = MyApp::Form::Email->new;
  ok !$form->process(params=>+{a=>1});
  ok my $data = $form->TO_JSON;
  ok $data->{error_by_field}->{email};
}

{
  ok my $form = MyApp::Form::Email->new;
  ok $form->process(params=>+{email=>'jjn@yahoo.com', fname=>'aaa', lname=>'ddd'});
  ok my $data = $form->TO_JSON;
  ok $data->{fields}->{email};
}

done_testing;
