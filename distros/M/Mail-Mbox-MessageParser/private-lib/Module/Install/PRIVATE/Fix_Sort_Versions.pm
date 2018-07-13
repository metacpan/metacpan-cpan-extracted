package Module::Install::PRIVATE::Fix_Sort_Versions;

use strict;
use warnings;

use vars qw( @ISA $VERSION );

use Module::Install::Base;
@ISA = qw( Module::Install::Base );

$VERSION = sprintf "%d.%02d%02d", q/0.1.0/ =~ /(\d+)/g;

# ---------------------------------------------------------------------------

sub fix_sort_versions {
  my ($self, $file) = @_;

  $self->perl_version('5.005');

  $self->include_deps('File::Slurper', 0);

  require File::Slurper;
  File::Slurper->import('read_text', 'write_text');

  print "Fixing POD in $file\n";

  my $code = read_text($file, undef, 1);
  $code =~ s|^=encoding.*||m;
  write_text($file, $code, undef, 1);
}

1;
