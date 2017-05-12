package Grimlock::Web::Model::Email;
{
  $Grimlock::Web::Model::Email::VERSION = '0.11';
}
use Moose;
use namespace::autoclean;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;
use Carp qw( croak );


sub send {
  my ( $self, $params ) = @_;
  my $email =  Email::Simple->create(
    header => [
      To => $params->{'to'},
      From => $params->{'from'},
      Subject => $params->{'subject'},
    ],
    body => $params->{'body'}
  );
  sendmail($email);
  warn "CREATED EMAIL";
  
}

1;
