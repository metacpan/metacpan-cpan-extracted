# Prefer numeric version for backwards compatibility
BEGIN { require 5.010000 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

#<<<
package
  Dist::Starter::Exception;
#>>>

sub new {
  my $class = shift;

  use warnings FATAL => qw( misc uninitialized );
  bless { @_ }, $class
}

sub message { shift->{ message } }

1
