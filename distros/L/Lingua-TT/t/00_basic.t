##-*- Mode: CPerl -*-
use Test::More;

BEGIN {
  my @modules = qw(
		    Lingua::TT::CDBFile
		    Lingua::TT::DBFile::PackedArray
		    Lingua::TT::DBFile
		    Lingua::TT::Dict
		    Lingua::TT::Diff
		    Lingua::TT::Enum
		    Lingua::TT::Packed
		    Lingua::TT::Sort
		    Lingua::TT::TextAlignment
		    Lingua::TT::Unigrams
		    Lingua::TT
		 );
  use_ok($_) foreach (@modules);
  done_testing();
}
