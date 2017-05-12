#!perl
use strict;
use Test::More tests => 4;

# This test is not here to encourage you to muck about in the object guts, but
# to provide a test for when Email::Simple has a way to provide optional
# extended header munging.

use_ok('Email::Simple');

my $email_text = <<END_MESSAGE;
Alpha: this header comes first
Bravo: this header comes second
Alpha: this header comes third

The body is irrelevant.
END_MESSAGE

my $email = Email::Simple->new($email_text);
isa_ok($email, "Email::Simple");

sub Email::Simple::header_prepend {
  my ($self, $field, @values) = @_;

  for my $value (reverse @values) {
    unshift @{ $self->header_obj->{headers} }, $field, $value;
  }
}

$email->header_prepend(Alpha => 'this header comes firstest');

is_deeply(
  [ $email->header_pairs ],
  [
    Alpha => 'this header comes firstest',
    Alpha => 'this header comes first',
    Bravo => 'this header comes second',
    Alpha => 'this header comes third',
  ],
  "we can prepend an existing header",
);

$email->header_prepend('Zero' => 'this header comes zeroeth', 'and 0+1th');

is_deeply(
  [ $email->header_pairs ],
  [
    Zero  => 'this header comes zeroeth',
    Zero  => 'and 0+1th',
    Alpha => 'this header comes firstest',
    Alpha => 'this header comes first',
    Bravo => 'this header comes second',
    Alpha => 'this header comes third',
  ],
  "we can prepend mutiply, too, and to a new header",
);
