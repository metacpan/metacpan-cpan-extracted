use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('File::PackageIndexer') };

my $indexer = File::PackageIndexer->new();
isa_ok($indexer, 'File::PackageIndexer');

SCOPE: {
  open my $fh, '<', $INC{"File/PackageIndexer.pm"} or die $!;
  my $code = do {local $/=undef; <$fh>};
  close $fh;

  my $res = $indexer->parse($code);
  ok(ref($res) && ref($res) eq 'HASH', "returns hash ref");

  my $cmp = {
    'File::PackageIndexer' => {
      name => 'File::PackageIndexer',
      subs => {
        parse => 1,
        lazy_create_pkg => 1,
        _handle_includes => 1,
        default_package => 1,
        merge_results => 1,
        merge_results_inplace => 1,
        clean_results => 1,
        clean => 1,
        new => 1,
      },
      isa => [],
    },
  };

  is_deeply($res, $cmp);
}


SCOPE: {
  open my $fh, '<', $INC{"File/PackageIndexer/PPI/Util.pm"} or die $!;
  my $code = do {local $/=undef; <$fh>};
  close $fh;

  my $res = $indexer->parse($code);
  ok(ref($res) && ref($res) eq 'HASH', "returns hash ref");

  my $cmp = {
    'File::PackageIndexer::PPI::Util' => {
      name => 'File::PackageIndexer::PPI::Util',
      subs => {
        constructor_to_structure => 1,
        _hash_constructor_to_structure => 1,
        _array_constructor_to_structure => 1,
        token_to_string => 1,
        get_keyname => 1,
        is_method_call => 1,
        is_class_method_call => 1,
        is_instance_method_call => 1,
        qw_to_list => 1,
        list_structure_to_array => 1,
        list_structure_to_hash => 1,
      },
      isa => [],
    },
  };

  is_deeply($res, $cmp);
}

