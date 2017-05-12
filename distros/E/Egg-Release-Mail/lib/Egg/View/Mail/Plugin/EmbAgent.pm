package Egg::View::Mail::Plugin::EmbAgent;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: EmbAgent.pm 332 2008-04-19 17:03:10Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.06';

sub __get_mailbody {
	my($self, $data)= @_;
	return $self->next::method($data)
	    if ($data->{no_embagent} or ! $data->{body});
	my $req   = $self->e->request;
	my $ipaddr= $req->address;
	my $regex = $data->{no_embagent_ip_regex}
	         || qr{^(?:192\.168\.|127\.0\.0\.1)};
	return $self->next::method($data) if $ipaddr=~m{$regex};
	my $body= $data->{body}= $self->__init_mailbody($data);
	$$body.= <<END_AGENT;


----------------------------------------------------------------------
END_AGENT
		if ($data->{embagent_remote_host}) {
			$$body.= <<END_AGENT;
REMOTE_HOST : @{[ $req->remote_host ]}
END_AGENT
		}
		$$body.= <<END_AGENT;
REMOTE_ADDR : @{[ $req->address ]}
USER_AGENT  : @{[ $req->agent ]}
----------------------------------------------------------------------
END_AGENT
	$self->next::method($data);
}

1;

__END__

=head1 NAME

Egg::View::Mail::Plugin::EmbAgent - Client information is put on the content of mail.

=head1 SYNOPSIS

  package MyApp::View::Mail::MyComp;
  use base qw/ Egg::View::Mail::Base /;
  
  ...........
  .....
  
  __PACKAGE__->setup_plugin('EmbAgent');

=head1 DESCRIPTION

Information on the access to the content of mail is put. It is MAIL plugin.

When 'EmbAgent' is passed to 'setup_plugin' method, it is built in.

There is a thing that how of information to stick changes when using it with 
other components that use '__get_mailbody' and adjust the built-in order, please.

  __PACKAGE__->setup_plugin(qw/
     Signature
     EmbAgent
     /);

The following items come to be evaluated by 'send' method of L<Egg::View::Mail::Base>
 when building it in. 

=head3 no_embagent

When an effective value is set, putting client information is canceled.

   $mail->send(
     body => .....,
     no_embagent => 1,
     );

=head3 embagent_remote_host

Information on REMOTE_HOST also sticks when an effective value is set.

   $mail->send(
     body => .....,
     embagent_remote_host => 1,
     );

Setting it in the configuration is good to always put up REMOTE_HOST.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View::Mail>,
L<Egg::View::Mail::Base>,
L<Egg::Request>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

