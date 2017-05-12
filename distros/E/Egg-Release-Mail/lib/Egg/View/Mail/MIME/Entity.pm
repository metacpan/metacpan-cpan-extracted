package Egg::View::Mail::MIME::Entity;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Entity.pm 285 2008-02-28 04:20:55Z lushe $
#
use strict;
use warnings;
use MIME::Entity;

our $VERSION = '0.01';

sub create_mail_body {
	my($self, $data)= @_;
	my $mime= do {
		my %attr;
		my $body= $self->__get_mailbody($data);
		if (my $headers= $data->{headers}) { %attr= %$headers }
		for ( [qw/ to          To          /],
		      [qw/ from        From        /],
		      [qw/ cc          CC          /],
		      [qw/ bcc         BCC         /],
		      [qw/ replay_to   Reply-To    /],
		      [qw/ return_path Return-Path /],
		      [qw/ subject     Subject     /],
		      [qw/ x_mailer    X-Mailer    /] ) {
			$attr{$_->[1]}= $data->{$_->[0]} if $data->{$_->[0]};
		}
		MIME::Entity->build( %attr, Data=> [$$body] );
	  };
	if (my $attach= $data->{attach}) {
		eval{
			if (ref($attach) eq 'HASH') {
				$mime->attach(%$attach);
			} elsif (ref($attach) eq 'ARRAY') {
				$mime->attach(%$_) for @{$self->attach};
			}
		  };
		$@ and die $@;
	}
	\$mime->stringify;
}

1;

__END__

=head1 NAME

Egg::View::Mail::MIME::Entity - The content of the transmission of mail is made with MIMI::Entity. 

=head1 SYNOPSIS

  package MyApp::View::Mail::MyComp;
  use base qw/ Egg::View::Mail::Base /;
  
  ...........
  .....
  
  __PACKAGE__->setup_mailer( CMD => 'MIME::Entity' );

=head1 DESCRIPTION

It is MAIL component for the content of the transmission of mail to be made from
L<MIMI::Entity>.

Use is enabled specifying 'MIME::Entity' for the second argument of 'setup_mailer'
method.

  __PACKAGE__->setup_mailer( SMTP => qw/ MIME::Entity / );

=head1 METHODS

=head2 create_mail_body ([MAIL_DATA_HASH])

The result is returned by the SCALAR reference by processing MAIL_DATA_HASH with
L<MIMI::Entity>.

The following item comes to be evaluated by the argument and the configuration 
of 'send' method of L<Egg::View::Mail::Base>.

=head3 headers

The header that wants to be included in the content of mail can be passed with 
HASH.

  headers => {
    'X-Hoge' => 'fooo',
    },

=head3 attach

The attached file is put up by mail.

  attach => [
    {
      Path     => '/path/to/images/abc.gif',
      Type     => 'image/gif',
      Encoding => 'Base64',
      },
    {
      Path     => '/path/to/content/abc.txt',
      Type     => 'text/plain',
      },
    ],

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View::Mail>,
L<Egg::View::Mail::Base>,
L<MIME::Entity>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

