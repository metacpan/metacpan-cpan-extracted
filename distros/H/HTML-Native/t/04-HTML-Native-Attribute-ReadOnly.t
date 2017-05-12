#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    use_ok ( "HTML::Native::Attribute::ReadOnly" );
}

{
  my $attr = HTML::Native::Attribute::ReadOnly->new (
    [ qw ( active default ) ]
  );
  isa_ok ( $attr, "HTML::Native::Attribute::ReadOnly" );
  is ( $attr, "active default" );
  isa_ok ( \%$attr, "HTML::Native::Attribute::ReadOnlyHash" );
  isa_ok ( \@$attr, "HTML::Native::Attribute::ReadOnlyArray" );
  ok ( $attr->{active} );
  dies_ok { $attr->{active} = 0; };
  dies_ok { shift @$attr; };
}

done_testing();
