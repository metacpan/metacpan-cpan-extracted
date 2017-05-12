#!/usr/bin/env perl

BEGIN { require './t/inc/setup.pl' };

use strict;
use warnings;
use Scalar::Util qw/weaken/;

plan tests => 47;

# Use the provided constructor.
{
  my $boxed = GI::BoxedStruct->new;
  isa_ok ($boxed, 'GI::BoxedStruct');
  is ($boxed->long_, 0);
  is ($boxed->g_strv, undef);
  is ($boxed->long_ (42), 0);
  $boxed->inv;
  weaken $boxed;
  is ($boxed, undef);
}

# Use our generic constructor.
{
  my $boxed = Glib::Boxed::new ('GI::BoxedStruct', {long_ => 42});
  isa_ok ($boxed, 'GI::BoxedStruct');
  is ($boxed->long_, 42);
  is ($boxed->g_strv, undef);
  $boxed->inv;

  $boxed = Glib::Boxed::new ('GI::BoxedStruct', long_ => 42);
  isa_ok ($boxed, 'GI::BoxedStruct');
  is ($boxed->long_, 42);
  is ($boxed->g_strv, undef);
  $boxed->inv;
}

SKIP: {
  skip 'new stuff', 6
    unless check_gi_version (0, 12, 0);
  my $boxed = GI::BoxedStruct::returnv ();
  isa_ok ($boxed, 'GI::BoxedStruct');
  is ($boxed->long_, 42);
  is_deeply ($boxed->g_strv, [qw/0 1 2/]);
  $boxed->inv;
  weaken $boxed;
  is ($boxed, undef);
  # make sure we haven't destroyed the static object
  isa_ok (GI::BoxedStruct::returnv (), 'GI::BoxedStruct');
  isa_ok (GI::BoxedStruct::returnv ()->copy, 'GI::BoxedStruct');
}

SKIP: {
  skip 'new stuff', 5
    unless check_gi_version (0, 12, 0);
  my $boxed = GI::BoxedStruct::out ();
  isa_ok ($boxed, 'GI::BoxedStruct');
  is ($boxed->long_, 42);
  # $boxed->g_strv contains garbage
  weaken $boxed;
  is ($boxed, undef);
  # make sure we haven't destroyed the static object
  isa_ok (GI::BoxedStruct::out (), 'GI::BoxedStruct');
  isa_ok (GI::BoxedStruct::out ()->copy, 'GI::BoxedStruct');
}

SKIP: {
  skip 'new stuff', 4
    unless check_gi_version (0, 12, 0);
  my $boxed_out = GI::BoxedStruct::out ();
  my $boxed = GI::BoxedStruct::inout ($boxed_out);
  isa_ok ($boxed, 'GI::BoxedStruct');
  is ($boxed->long_, 0);
  is ($boxed_out->long_, 42);
  # $boxed->g_strv contains garbage
  weaken $boxed;
  is ($boxed, undef);
}

# --------------------------------------------------------------------------- #

SKIP: {
  skip 'new stuff', 5
    unless check_gi_version (0, 12, 0);
  my $boxed = Regress::TestSimpleBoxedA::const_return ();
  isa_ok ($boxed, 'Regress::TestSimpleBoxedA');
  isa_ok ($boxed, 'Glib::Boxed');
  my $copy = $boxed->copy;
  ok ($boxed->equals ($copy));
  weaken $boxed;
  is ($boxed, undef);
  weaken $copy;
  is ($copy, undef);
}

{
  my $boxed = Regress::TestBoxed->new;
  isa_ok ($boxed, 'Regress::TestBoxed');
  isa_ok ($boxed, 'Glib::Boxed');
  my $copy = $boxed->copy;
  isa_ok ($boxed, 'Regress::TestBoxed');
  isa_ok ($boxed, 'Glib::Boxed');
  ok ($boxed->equals ($copy));
  weaken $boxed;
  is ($boxed, undef);
  weaken $copy;
  is ($copy, undef);

  $boxed = Regress::TestBoxed->new_alternative_constructor1 (23);
  isa_ok ($boxed, 'Regress::TestBoxed');
  isa_ok ($boxed, 'Glib::Boxed');
  weaken $boxed;
  is ($boxed, undef);

  $boxed = Regress::TestBoxed->new_alternative_constructor2 (23, 42);
  isa_ok ($boxed, 'Regress::TestBoxed');
  isa_ok ($boxed, 'Glib::Boxed');
  weaken $boxed;
  is ($boxed, undef);

  $boxed = Regress::TestBoxed->new_alternative_constructor3 ("perl");
  isa_ok ($boxed, 'Regress::TestBoxed');
  isa_ok ($boxed, 'Glib::Boxed');
  weaken $boxed;
  is ($boxed, undef);
}
