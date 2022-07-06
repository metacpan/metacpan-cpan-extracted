use Module::Build;

Module::Build -> new
(
 module_name    => 'Lingua::EN::Sentence',
 license        => 'perl',
 dist_abstract  => "Split text into sentences",
 dist_author    => 'Shlomo Yona, Kim Ryan <kimryan at cpan org>',
 build_requires =>
 {
 	Test::More => 0.94,
 },
 configure_requires =>
 {
  Module::Build => 0.3800,
 },
 requires =>
 {
  'perl'   => '5.10.0',
  warnings => '1.06'
 },
 meta_merge =>
 {
    resources =>
    {
            repository => 'https://github.com/kimryan/Lingua-EN-Sentence'
    }
  }
) -> create_build_script();
