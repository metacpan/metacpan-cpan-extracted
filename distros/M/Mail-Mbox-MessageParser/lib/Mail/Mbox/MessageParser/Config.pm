package Mail::Mbox::MessageParser::Config;

use strict;

use vars qw( $VERSION %Config );

$VERSION = sprintf "%d.%02d%02d", q/0.1.2/ =~ /(\d+)/g;

%Mail::Mbox::MessageParser::Config = (
  'programs' => {
    'bzip' => '/usr/bin/bzip2',
    'bzip2' => '/usr/bin/bzip2',
    'cat' => '/usr/local/opt/coreutils/libexec/gnubin/cat',
    'diff' => '/usr/bin/diff',
    'grep' => undef,
    'gzip' => '/usr/bin/gzip',
    'lzip' => '/usr/local/bin/lzip',
    'xz' => '/usr/local/bin/xz',
  },

  'max_testchar_buffer_size' => 1048576,

  'read_chunk_size' => 20000,

  'from_pattern' => q/(?mx)^
    (From\s
      # Skip names, months, days
      (?> [^:\n]+ )
      # Match time
      (?: :\d\d){1,2}
      # Match time zone (EST), hour shift (+0500), and-or year
      (?: \s+ (?: [A-Z]{2,6} | [+-]?\d{4} ) ){1,3}
      # smail compatibility
      (\sremote\sfrom\s.*)?
    )/,

);

1;

