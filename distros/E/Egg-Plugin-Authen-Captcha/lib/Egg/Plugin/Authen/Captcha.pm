package Egg::Plugin::Authen::Captcha;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Captcha.pm 317 2008-04-17 11:58:43Z lushe $
#
use strict;
use warnings;
use Authen::Captcha;
use base qw/ Class::Data::Inheritable /;

our $VERSION = '0.03';

__PACKAGE__->mk_classdata('authc');

sub _setup {
	my($e)= @_;
	my $option= $e->config->{plugin_authen_captcha} ||= {};
	__PACKAGE__->authc( Authen::Captcha->new(%$option) );
	$e->next::method;
}

1;

__END__

=head1 NAME

Egg::Plugin::Authen::Captcha - Plugin for Authen::Captcha.

=head1 SYNOPSIS

  use Egg qw/ Authen::Captcha /;

  # The validation code is obtained.
  my $md5hex= $e->authc->generate_code(5);
  
  # It preserves it in the session.
  $e->session->{authen_capcha}= $md5hex;
  
  # The attestation image is displayed.
  <img src="/authen_captcha/<% $md5hex %>.png" />
  
  # Check on input code
  my $in= $e->req->param('auth_code') || return 'I want input of auth_code.';
  $in eq $e->session->{authen_capcha} || return 'auth_code is not corresponding.';

=head1 DESCRIPTION

It is a plug-in to attest capture.

see L<Authen::Captcha>.

=head1 CONFIGURATION

Please set it with the key named 'plugin_authen_captcha'.

  plugin_authen_captcha => {
    data_folder   => '<e.dir.etc>/AuthCaptcha',
    output_folder => '<e.dir.static>/AuthCaptcha',
    width         => 30,
    height        => 40,
    },

All set values are passed by the constructor of Authen::Captcha.

see L<Authen::Captcha>.

=head1 METHODS

=head2 authc

Authen::Captcha object is returned.

  my $ac= $e->authc;

=head1 SEE ALSO

L<Authen::Captcha>,
L<Class::Data::Inheritable>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

