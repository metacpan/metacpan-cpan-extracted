use strict;
use Test::More tests => 5;
BEGIN{ use_ok("FormValidator::Simple") }
BEGIN{ use_ok("FormValidator::Simple::Validator") }
FormValidator::Simple->set_option(
    foo  => 'oof',
    bar  => 'rab',
);

my $o = FormValidator::Simple::Validator->options;
is($o->{foo}, 'oof');
is($o->{bar}, 'rab');

FormValidator::Simple->new( buz => 'zub' );

my $o2 = FormValidator::Simple::Validator->options;
is($o2->{buz}, 'zub');
