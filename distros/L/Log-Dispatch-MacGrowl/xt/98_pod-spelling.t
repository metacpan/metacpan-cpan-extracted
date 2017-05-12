#

use strict;
use warnings;
use Test::More;

if( defined $ENV{PERL_TEST_SPELLING} and $ENV{PERL_TEST_SPELLING} ){
  if( eval { require Test::Spelling } ){
    ;
  }
  else{
    plan skip_all => "couldn't load Tetst::Spelling";
  }
}
else{
  plan skip_all => "define PERL_TEST_SPELLING to run these tests";
}

$ENV{LANG} = 'C';

my $cmd;
if( defined $ENV{SPELL_CMD} and $ENV{SPELL_CMD} ne '' ){
  $cmd = $ENV{SPELL_CMD};
}
else{
  for my $path( split /:/, $ENV{PATH} ){
    -x "$path/aspell" and $cmd="aspell list";
  }
}

if( $cmd ){
  Test::Spelling::set_spell_cmd($cmd);
  Test::Spelling::add_stopwords(<DATA>);
  Test::Spelling::all_pod_files_spelling_ok();
}
else{
  plan skip_all => "no spell/ispell/aspell";
}

__DATA__
OKAMOTO
Okamoto
Ryo
aquahill
icns
