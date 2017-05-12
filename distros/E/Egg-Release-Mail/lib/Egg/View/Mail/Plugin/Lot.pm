package Egg::View::Mail::Plugin::Lot;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Lot.pm 285 2008-02-28 04:20:55Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;

our $VERSION = '0.01';

sub send {
	my $self= shift;
	my $attr= { %{$self->config},
	  %{ $_[0] ? ($_[1] ? {@_}: $_[0]) : croak q{I want mail data.} },
	  };
	my $toadder= $attr->{to} || croak q{I want to address.};
	my $start_hook= $attr->{start_hook} || sub {};
	my $end_hook  = $attr->{end_hook}   || sub {};
	my $count;
	for (ref($toadder) eq 'ARRAY' ? @$toadder : $toadder) {
		++$count;
		my %data= ( %$attr, to=> $_ );
		$data{body}= $self->create_mail_body(\%data);
		$start_hook->($count, \%data);
		$self->mail_send(\%data);
		$end_hook->($count, \%data);
	}
	$count || 0;
}

1;

__END__

=head1 NAME

Egg::View::Mail::Plugin::Lot - MAIL plugin that enables specification of two or more destinations. 

=head1 SYNOPSIS

  package MyApp::View::Mail::MyComp;
  use base qw/ Egg::View::Mail::Base /;
  
  ...........
  .....
  
  __PACKAGE__->setup_plugin('Lot');

=head1 DESCRIPTION

It is MAIL plugin that enables the specification of two or more destinations.

When 'Lot' is passed to 'setup_plugin' method, it is built in.

=head1 METHODS

=head2 send

Mail is transmitted.

Two or more addresses can be passed to 'to'.

  $mail->send(
    to => [qw/
      hoge@mydomain
      fooo@anydomain
      .....
      /],
    body => $mail_body,
    );

'send' method of Egg::View::Mail::Base is Obarraided.

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

