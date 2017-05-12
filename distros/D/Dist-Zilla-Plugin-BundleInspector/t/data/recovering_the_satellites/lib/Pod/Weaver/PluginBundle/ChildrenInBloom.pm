package
  Pod::Weaver::PluginBundle::ChildrenInBloom;

# sufficient for testing
use String::RewritePrefix
  rewrite => {
    -as      => 'pkg',
    prefixes => {
      '-' => 'Pod::Weaver::Plugin::',
      ''  => 'Pod::Weaver::Section::',
    },
  };

sub mvp_bundle_config {
  return (
    [HaveYou => pkg(-SeenMeLately), {}],
    [Millers => pkg('Angels'), { ':version' => '1.23' }],
    [HorseDreamersBlues => pkg('Another'), {}],
  );
}

1;

=head1 INI

=bundle_ini_string

=cut
