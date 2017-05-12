package Egg::Plugin::Charset;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Charset.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION = '3.00';

sub _setup {
	my($e)= @_;
	$e->mk_accessors('no_convert');
	$e->next::method;
}
sub _output {
	my $e= shift;
	my $body= $e->get_convert_body || return $e->next::method;
	$e->_convert_output_body($body);
	$e->next::method;
}
sub get_convert_body {
	my($e)= @_;
	my $res= $e->response;
	return (undef)
	   if ($e->no_convert or $e->request->is_head or $res->attachment);
	my $type;
	return (undef)
	   if ($type= $res->content_type and $type!~/^text\//i);
	$res->body;
}

1;

__END__

=head1 NAME

Egg::Plugin::Charset - Base class for Charset plugin.

=head1 SYNOPSIS

  use Egg qw/ Charset::UTF8 /;

=head1 DESCRIPTION

This module is a base class for the following subclasses.

=over 4

=item * L<Egg::Plugin::Charset::UTF8>

=item * L<Egg::Plugin::Charset::EUC_JP>

=item * L<Egg::Plugin::Charset::Shift_JIS>

=back

This module does interrupt to '_output'.
And, the character-code of contents set in $e->response->body is changed.

The module with this method of '_convert_body' is made to make the subclass by
oneself, and processing that converts the character-code in this method is written.

  package Egg::Plugin::Charset::AnyCode;
  use strict;
  use ConvertAny;
  
  sub _setup {
     my($e)= @_;
     $e->config->{content_language}= 'ja';
     $e->config->{charset_out}= "AnyCode";
     $e->next::method;
  }
  sub _convert_body {
     my $e    = shift;
     my $body = shift || return 0;
     $$body= ConvertAny->convert($body);  # $body is SCALAR reference.
  }

I think that it doesn't want to process this plug-in at times.

=head1 METHODS

=head2 no_convert ([BOOL])

The processing of this plugin can temporarily be canceled for this case by
setting an effective value to $e-E<gt>no_convert.

  $e->no_convert(1);

=head2 get_convert_body

The contents sources to be converted are returned.

Undefined is returned when $e-E<gt>no_convert or $e-E<gt>request-E<gt>is_head or
$e-E<gt>response-E<gt>attachment is effective.

Undefined is returned if there is no $e-E<gt>response-E<gt>content_type in the
text system.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Plugin::Charset::UTF8>,
L<Egg::Plugin::Charset::EUC_JP>,
L<Egg::Plugin::Charset::Shift_JIS>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

