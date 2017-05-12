use Module::Build;

Module::Build->new(
  module_name => 'HTML::BBReverse',
  license => 'perl',
  create_makefile_pl => 'passthrough',
  dist_author => 'Yoran Heling <yorhel@cpan.org>',
)->create_build_script;
