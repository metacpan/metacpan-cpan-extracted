use Test::More tests => 13;

BEGIN {
  use_ok 'Egg::Release::Mail';
  use_ok 'Egg::View::Mail';
  use_ok 'Egg::View::Mail::Base';
  use_ok 'Egg::View::Mail::Encode::ISO2022JP';
  use_ok 'Egg::View::Mail::Mailer::CMD';
  use_ok 'Egg::View::Mail::Mailer::SMTP';
  use_ok 'Egg::View::Mail::MIME::Entity';
  use_ok 'Egg::View::Mail::Plugin::EmbAgent';
  use_ok 'Egg::View::Mail::Plugin::Jfold';
  use_ok 'Egg::View::Mail::Plugin::Lot';
  use_ok 'Egg::View::Mail::Plugin::PortCheck';
  use_ok 'Egg::View::Mail::Plugin::SaveBody';
  use_ok 'Egg::View::Mail::Plugin::Signature';
  };
