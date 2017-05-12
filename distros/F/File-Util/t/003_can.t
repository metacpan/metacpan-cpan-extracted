
use strict;
use warnings;

use Test::More tests => 41;
use Test::NoWarnings;

# load your module...
use lib './lib';
use File::Util;

my $ftl = File::Util->new();

# check to see if non-autoloaded File::Util methods are can-able ;O)
map { ok( ref( $ftl->can( $_ ) ) eq 'CODE', "can $_" ) } qw
   (
      _dropdots
      _release
      _seize
      atomize_path
      bitmask
      can_flock
      can_read
      can_write
      created
      diagnostic
      ebcdic
      escape_filename
      existent
      file_type
      isbin
      is_bin
      is_readable
      is_writable
      last_access
      last_modified
      line_count
      list_dir
      load_dir
      load_file
      flock_rules
      make_dir
      abort_depth
      needs_binmode
      new
      open_handle
      readlimit
      read_limit
      size
      strip_path
      trunc
      use_flock
      write_file
      valid_filename
      VERSION
      DESTROY
   );

exit;
