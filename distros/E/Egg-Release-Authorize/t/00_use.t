use Test::More tests => 16;

BEGIN {
  use_ok 'Egg::Release::Authorize';
  use_ok 'Egg::Helper::Model::Auth';
  use_ok 'Egg::Model::Auth';
  use_ok 'Egg::Model::Auth::API::DBI';
  use_ok 'Egg::Model::Auth::API::DBIC';
  use_ok 'Egg::Model::Auth::API::File';
  use_ok 'Egg::Model::Auth::Base';
  use_ok 'Egg::Model::Auth::Base::API';
  use_ok 'Egg::Model::Auth::Bind::Cookie';
  use_ok 'Egg::Model::Auth::Crypt::CBC';
  use_ok 'Egg::Model::Auth::Crypt::Func';
  use_ok 'Egg::Model::Auth::Crypt::MD5';
  use_ok 'Egg::Model::Auth::Crypt::SHA1';
  use_ok 'Egg::Model::Auth::Plugin::Keep';
  use_ok 'Egg::Model::Auth::Session::FileCache';
  use_ok 'Egg::Model::Auth::Session::SessionKit';
  };
