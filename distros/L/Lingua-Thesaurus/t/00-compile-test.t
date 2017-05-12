#!perl

use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
  my @modules = qw/Lingua::Thesaurus
                   Lingua::Thesaurus::IO
                   Lingua::Thesaurus::IO::LivelinkCollectionServer
                   Lingua::Thesaurus::IO::Jurivoc
                   Lingua::Thesaurus::Storage
                   Lingua::Thesaurus::Storage::SQLite
                   Lingua::Thesaurus::Term/;

  plan tests => scalar(@modules);
  use_ok($_) or print "Bail out!\n" foreach @modules;
}

diag( "Testing Lingua::Thesaurus $Lingua::Thesaurus::VERSION, Perl $], $^X" );
