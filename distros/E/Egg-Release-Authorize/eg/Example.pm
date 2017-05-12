package MyApp::Model::Auth::Example;
use strict;
use warnings;
use base qw/ Egg::Model::Auth::Base /;

__PACKAGE__->config(
  label_name => 'auth_label',
  file=> {
    path   => MyApp->path_to(qw/ etc members /),
    fields => [qw/ uid psw active a_group age /],
    id_field       => 'uid',
    password_field => 'psw',
    active_field   => 'active',
    group_field    => 'a_group',
    separator      => qr{ *\t *},
    },
);

__PACKAGE__->setup_plugin(qw/ Keep /);

__PACKAGE__->setup_session( FileCache => qw/ Bind::Cookie / );

__PACKAGE__->setup_api( File => qw/ Crypt::Func / );

1;
