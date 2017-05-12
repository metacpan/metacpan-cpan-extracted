package EO::System::Perl;

use strict;
use warnings;

use Config;
use EO::Array;
use EO::Singleton;
use base qw( EO::Singleton );

our $VERSION = 0.96;

sub can_thread {
  !!$Config{usethreads};
}

sub version {
  return $];
}

sub binary {
  return $^X;
}

sub include_path {
  return EO::Array->new_with_array( @INC );
}

sub architecture {
  return $Config{archname};
}

1;
