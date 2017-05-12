use strict;
use warnings;

package TestResolver;

use base qw(HTML::Mason::Resolver);
use File::Spec;

sub get_info {
  my ($self, $path, $comp_key, $comp_root) = @_;

  my $srcfile = File::Spec->canonpath(File::Spec->catfile($comp_root, $path));
  return if -f $srcfile;

  return HTML::Mason::ComponentSource->new(
    friendly_name => $srcfile,
    comp_id       => "/$comp_key$path",
    last_modified => time,
    comp_path     => $path,
    comp_class    => 'HTML::Mason::Component::FileBased',
    extra         => { comp_root => $comp_key },
    source_callback => sub { "auto: $path" },
  );
}

1;
