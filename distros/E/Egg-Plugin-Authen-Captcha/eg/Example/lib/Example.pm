package Example;
use strict;
use warnings;
use Egg qw/
  -Debug
  Authen::Captcha
  /;

our $VERSION= '0.01';

__PACKAGE__->egg_startup(

  title      => 'Example',
  root       => '/path/to/Example',
  static_uri => '/',
  template_path=> ['< $e.dir.template >', '< $e.dir.comp >'],
  MODEL => ['Session'],
  VIEW  => [ ..... ],

  plugin_session=> {
    .....
    ...
    },

  plugin_authen_captcha => {
    data_folder   => '<e.dir.etc>/AuthCaptcha',
    output_folder => '<e.dir.static>/AuthCaptcha',
    width         => 27,
    height        => 38,
    },

  );

# Dispatch. ------------------------------------------------
__PACKAGE__->dispatch_map(
  view=> \&view,
  post=> \&post,
  );
# ----------------------------------------------------------

sub view {
	my($e)= @_;
	$e->stash->{authen_capcha}=
	   $e->session->{authen_capcha}= $e->authc->generate_code(5);
	$e->template('/authen_input.tt');
}
sub post {
	my($e)= @_;
	my $md5chk= $e->session->{authen_capcha}
	         || return $e->finished(403);
	my $md5hex= $e->req->param('authen_capcha')
	         || return $e->template('/input_error.tt');
	$md5chk eq $md5hex
	         || return $e->template('/input_error.tt');
	$e->template('/success.tt');
}

1;
