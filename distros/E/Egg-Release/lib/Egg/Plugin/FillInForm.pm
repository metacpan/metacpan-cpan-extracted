package Egg::Plugin::FillInForm;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: FillInForm.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use HTML::FillInForm;

our $VERSION = '3.00';

sub _setup {
	my($e)= @_;
	$e->mk_accessors('fillin_ok');
	$e->config->{plugin_fillinform} ||= {};
	if ($e->isa('Egg::Plugin::FormValidator::Simple')) {
		no warnings 'redefine';
		*_valid_error= sub {
			my($egg)= @_;
			return ( $egg->stash->{error}
			      || $egg->form->has_missing
			      || $egg->form->has_invalid ) ? 1: 0;
		  };
	} else {
		*_valid_error= sub { 0 };
	}
	$e->next::method;
}
sub fillform_render {
	my $e   = shift;
	my $body= shift || $e->response->body || return 0;
	   $body= \$body unless ref($body);
	my $fdat= $_[0] ? ($_[1] ? {@_}: $_[0]): $e->request->params;
	return 0 unless %$fdat;
	$$body= HTML::FillInForm->new->fill(
	  scalarref => $body, fdat => $fdat,
	  %{$e->config->{plugin_fillinform}},
	  );
	$body;
}
sub fillform {
	my $e= shift;
	my $body= $e->fillform_render(@_) || return 0;
	$e->response->body($body);
}
sub _finalize {
	my($e)= @_;
	$e->fillform if ( $e->fillin_ok or $e->_valid_error );
	$e->next::method;
}

1;

__END__

=head1 NAME

Egg::Plugin::FillInForm - HTML::FillInForm for Egg.

=head1 SYNOPSIS

  use Egg qw/ FillInForm /;
  
  __PACKAGE__->egg_startup(
  
    plugin_fillinform => {
      fill_password => 0,
      ignore_fields => [qw{ param1 param2 }],
      ...
      },
  
  );
  
  $e->fillin_ok(1);
  
  my $output= $e->fillform_render(\$html, $hash);
  
  $e->fillform;

=head1 DESCRIPTION

L<HTML::FillInForm> It is a plugin to use.

=head1 METHODS

=head2 fillform_render ([HTML_TEXT], [HASH])

It is L<HTML::FillInForm> as for the argument. Is passed and the result is 
returned.

When HTML_TEXT is omitted, $e->response->body is used.

When HASH is omitted, $e-E<gt>request-E<gt>params is used.

  my $output= $e->fillform_render(\$html, $hash);

=head2 fillform ([HTML_TAXT], [HASH])

The result of 'fillform_render' is set in $e-E<gt>response-E<gt>body.

  $e->fillform_render(\$html, $hash);

=head2 fillin_ok ( [BOOL] )

Fillform comes to be done by '_finalize' when keeping effective.

When the check error of this plugin occurs when L<Egg::Plugin::FormValidator::Simple>
is loaded, fillform is always done.

  $e->fillin_ok(1);

=head1 SEE ALSO

L<Egg::Release>,
L<HTML::FillInForm>,
L<Egg::Plugin::FormValidator::Simple>,
L<Catalyst::Plugin::FillInForm>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

