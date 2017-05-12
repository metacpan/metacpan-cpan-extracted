
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $deps = {
    'Test::Simple'        => 0.44,
    'Moo'                 => 0,
    'IO::All'             => 0,
    'Crypt::CBC'          => 0,
    'Crypt::Blowfish'     => 0,
    'MIME::Base64'        => 0,
    'Digest::SHA1'        => 0,
    'JSON::XS'            => 0,
    'Proc::ProcessTable'  => 0,
};

WriteMakefile(
    NAME         => 'Git::Crypt',
    VERSION_FROM => 'lib/Git/Crypt.pm',                       # finds \$VERSION
    AUTHOR       => 'Hernan Lopes (hernanlopes@gmail.com)',
    ABSTRACT =>
      'Encrypt/decrypt sensitive files before commit and save on public repos',
    EXE_FILES     => ["bin/gitcrypt"],
    PREREQ_PM     => $deps,
    TEST_REQUIRES => $deps,
    META_MERGE => {
        'meta-spec' => { version => 2 },
         resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/hernan604/Git-Crypt.git',
                 web  => 'https://github.com/hernan604/Git-Crypt',
             },
         },
    },
);
