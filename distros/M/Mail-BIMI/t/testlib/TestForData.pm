package TestForData;
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Test::Exception;
extends 'Mail::BIMI::Base';
with(
  'Mail::BIMI::Role::Data',
);

sub get_pass($self) {
  return $self->get_data_from_file('asn1.txt');
}

sub get_fail($self) {
  return $self->get_data_from_file('bogus.file');
}

1;

