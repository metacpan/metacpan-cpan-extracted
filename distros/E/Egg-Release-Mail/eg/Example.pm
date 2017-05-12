package Example::View::Mail::Example;
use strict;
use warnings;
use base qw/ Egg::View::Mail::Base /;

our $VERSION= '0.01';

__PACKAGE__->config(
  label_name => 'mail_test',
  .........
  ....
);

__PACKAGE__->setup_plugin(qw/
  PortCheck
  Lot
  EmbAgent
  Signature
  Jfold
  /);

__PACKAGE__->setup_mailer( SMTP => qw/
  Encode::ISO2022JP
  MIME::Entity
  /);

__PACKAGE__->setup_template( Mason => 'mail/inquiry.tt' );

1;
