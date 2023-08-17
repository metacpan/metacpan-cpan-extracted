
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use v5.10;
use strict;
use warnings;
use Test::More;

{

	package Form;

	use Form::Tiny;

	use namespace::autoclean;

	__PACKAGE__->form_meta;
}

my $form = Form->new;
can_ok $form, 'form_meta';
is $form->form_meta->package, 'Form';

done_testing;
