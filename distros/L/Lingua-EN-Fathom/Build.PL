use Module::Build;

Module::Build -> new
(
    module_name    => 'Lingua::EN::Fathom',
    license        => 'perl',
    dist_abstract  => "Measure readability of English text",
    dist_author    => 'Kim Ryan <kimryan at cpan org>',
    build_requires =>
    {
       Test::More => 0.94,
       Test::Pod  => 1.04,
    },
    configure_requires =>
    {
        Module::Build => 0.3800,
    },
    requires =>
    {
       locale => 1.00,
       strict => 1.04,
       warnings => 0,
       Lingua::EN::Syllable => 0.28,
       Lingua::EN::Sentence => 0.28
       
    },
    meta_merge =>
    {
        resources =>
        {
              repository => 'https://github.com/kimryan/Readability'
        }
    }     
) -> create_build_script();
