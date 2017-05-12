package Egg::View::Mail::Encode::ISO2022JP;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: ISO2022JP.pm 285 2008-02-28 04:20:55Z lushe $
#
use strict;
use warnings;
use Jcode;

our $VERSION = '0.01';

sub __get_mailbody {
	my($self, $data)= @_;
	my $body= $self->next::method($data);
	my $j= $self->{jcode_context} ||= Jcode->new('jcode');
	$data->{subject}= $j->set(\$data->{subject})->mime_encode;
	my $headers= $data->{headers} ||= {};
	$headers->{Encoding}= '7bit';
	$headers->{Charset} = 'ISO-2022-JP';
	\$j->set($body)->iso_2022_jp;
}

1;

__END__

=head1 NAME

Egg::View::Mail::Encode::ISO2022JP - Processing for Japanese mail is done. 

=head1 SYNOPSIS

  package MyApp::View::Mail::MyComp;
  use base qw/ Egg::View::Mail::Base /;
  
  ...........
  .....
  
  __PACKAGE__->setup_mailer( SMTP => qw/
    Encode::ISO2022JP
    MIME::Entity
    /);

=head1 DESCRIPTION

Processing necessary to send Japanese mail is done.

Please use use with L<Egg::View::Mail::MIME::Entity>.
It is a code matched to the specification of this component.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View::Mail>,
L<Egg::View::Mail::Base>,
L<Egg::View::Mail::MIME::Entity>,
L<Jcode>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

