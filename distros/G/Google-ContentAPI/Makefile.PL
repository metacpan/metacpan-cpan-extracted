use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Google::ContentAPI',
    VERSION_FROM      => 'lib/Google/ContentAPI.pm',
    ABSTRACT_FROM     => 'lib/Google/ContentAPI.pm',
    AUTHOR            => 'Bill Gerrard <bill@gerrard.org>',
    LICENSE           => 'perl',
    MIN_PERL_VERSION => '5.008004',
    PREREQ_PM         => {
      'strict'              => 0,
      'JSON'                => 0,
      'JSON::WebToken'      => 0,
      'Crypt::OpenSSL::RSA' => 0,
      'REST::Client'        => 0,
      'HTML::Entities'      => 0,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/billgerrard/google-content-api.git',
                web  => 'https://github.com/billgerrard/google-content-api',
            },
        }})
     : ()
    ),
);
