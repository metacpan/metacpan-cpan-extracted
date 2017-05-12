package Example::Model::Session::Example;
use strict;
use warnings;
use base qw/ Egg::Model::Session::Manager::Base /;

our $VERSION= '0.01';

__PACKAGE__->config(

#  label_name => 'session_label',

  );

__PACKAGE__->startup(
  Base::FileCache
  Bind::Cookie
  ID::SHA1
  );

package Example::Model::Session::Example::TieHash;
use strict;
use warnings;
use base qw/ Egg::Model::Session::Manager::TieHash /;

1;
