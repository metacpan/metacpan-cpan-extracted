#!/usr/bin/env perl
use strict;
use warnings;

use Lingua::EN::CommonMistakes;
use Lingua::EN::CommonMistakes qw(:british %BRITISH);
use Lingua::EN::CommonMistakes qw(:american %AMERICAN);
use Lingua::EN::CommonMistakes qw(:no-punct %NO_PUNCT);
use Test::More;
use Test::Warn;

sub test_default {
  is( $MISTAKES{depency}, 'dependency', 'default: depency -> dependency' );
  is( $MISTAKES{dont}, q{don't}, q{default: dont -> don't} );
  ok( !$MISTAKES{recognized}, 'default: british not enabled' );
  ok( !$MISTAKES{recognised}, 'default: american not enabled' );
}

sub test_british {
  is( $BRITISH{recognized}, 'recognised', 'british: recognized -> recognised' );
}

sub test_american {
  is( $AMERICAN{recognised}, 'recognized',
    'american: recognised -> recognized' );
}

sub test_no_punct {
  ok( !$NO_PUNCT{dont}, 'no-punct: dont is not an error' );
}

sub test_unknown_tag {
  warning_is {
    Lingua::EN::CommonMistakes->import(qw(:abc %BAD1));
  }
  'Lingua::EN::CommonMistakes: import argument :abc is not understood', 'warn';

  warning_is {
    no warnings 'Lingua::EN::CommonMistakes';
    Lingua::EN::CommonMistakes->import(qw(:abc %BAD2));
  }
  undef, 'do not warn';
}

sub run {
  test_default;
  test_british;
  test_american;
  test_no_punct;
  test_unknown_tag;
}

if ( !caller ) {
  run;
  done_testing;
}
