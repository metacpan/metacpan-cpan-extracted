package MyApp::Model::FsaveDate;
use strict;
use warnings;

our $VERSION= '0.01';

package MyApp::Model::FsaveDate::handler;
use strict;
use base qw/ Egg::Model::FsaveDate::Base /;

__PACKAGE__->config(
  base_path   => MyApp->path_to(qw/ etc FsaveDate /),
  amount_save => 90,
  extention   => 'txt',
  );

1;
