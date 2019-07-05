#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use attributes;

use Future::AsyncAwait;

# :method
{
   async sub is_method :method { }

   my $cvf_method = grep { m/^method$/ } attributes::get( \&is_method );
   ok( $cvf_method, '&is_method has :method' );
}

# :lvalue - accepted but should warn
{
   my $warning;
   BEGIN { $SIG{__WARN__} = sub { $warning++ } }

   async sub is_lvalue :lvalue { }

   my $cvf_lvalue = grep { m/^lvalue$/ } attributes::get( \&is_lvalue );
   ok( $cvf_lvalue, '&is_lvalue has :lvalue' );
   ok( $warning, 'async sub :lvalue produces a warning' );

   BEGIN { undef $SIG{__WARN__} }
}

# :const happens to break currently, but it would be meaningless anyway

# some custom ones
{
   my $modify_invoked;

   sub MODIFY_CODE_ATTRIBUTES
   {
      my ( $pkg, $sub, $attr ) = @_;

      $modify_invoked++;
      is( $attr, "MyCustomAttribute(value here)", 'MODIFY_CODE_ATTRIBUTES takes attr' );

      return ();
   }

   async sub is_attributed :MyCustomAttribute(value here) { }
   ok( $modify_invoked, 'MODIFY_CODE_ATTRIBUTES invoked' );
}

done_testing;
