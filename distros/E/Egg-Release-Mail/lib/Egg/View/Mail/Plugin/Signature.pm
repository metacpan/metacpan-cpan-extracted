package Egg::View::Mail::Plugin::Signature;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Signature.pm 332 2008-04-19 17:03:10Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.06';

sub __get_mailbody {
	my($self, $data)= @_;
	return $self->next::method($data) unless $data->{body};
	my $body= $data->{body}= $self->__init_mailbody($data);
	$$body = $data->{body_header}. $$body if $data->{body_header};
	$$body.= "\n$data->{body_footer}"     if $data->{body_footer};
	$$body.= "\n$data->{signature}"       if $data->{signature};
	$self->next::method($data);
}

1;

__END__

=head1 NAME

Egg::View::Mail::Plugin::Signature - Famous etc. are added to the content of the transmission of mail. 

=head1 SYNOPSIS

  package MyApp::View::Mail::MyComp;
  use base qw/ Egg::View::Mail::Base /;
  
  ...........
  .....
  
  __PACKAGE__->setup_plugin('Signature');

=head1 DESCRIPTION

It is MAIL plugin to add famous etc. to the content when mail is transmitted.

When 'Signature' is passed to 'setup_plugin' method, it is built in.

There is a thing that processing the same as the aim is not done by the competition
 with other plugins. Please adjust the built-in order. 

  __PACKAGE__->setup_plugin(qw/
    Signature
    EmbAgent
    /);

When the following items are set by the argument and the configuration of 'send'
method, the content is added to the content of mail. 

=head3 body_header

Text added to uppermost part of content of mail.

  $mail->send( ...... , body_header => $header_text );

=head3 body_footer

Text added under content of mail.

  $mail->send( ...... , body_footer => $footer_text );

=head3 signature

Text added the under content of mail.

  $mail->send( ...... , signature => $signature_text );

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View::Mail>,
L<Egg::View::Mail::Base>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

