package Module::Install::PRIVATE::Fix_Sort_Versions;

use strict;
use warnings;
use File::Slurper qw(read_text write_text);

use vars qw( @ISA $VERSION );

use Module::Install::Base;
@ISA = qw( Module::Install::Base );

$VERSION = sprintf "%d.%02d%02d", q/0.1.0/ =~ /(\d+)/g;

# ---------------------------------------------------------------------------

sub fix_sort_versions {
  my ($self, $file) = @_;

  $self->configure_requires('File::Slurp', 0);

  print "Fixing POD in $file\n";

  my $code = read_text($file, undef, 1);
  $code =~ s|^=encoding.*||m;
  write_text($file, $code, undef, 1);
}

1;
