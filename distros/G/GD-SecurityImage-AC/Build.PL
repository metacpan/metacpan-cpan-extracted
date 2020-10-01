use strict;

use Module::Build;

my $build = Module::Build->new
      ( module_name    => 'GD::SecurityImage::AC',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'A drop-in replacement for Authen::Captcha',
        license        => 'mit',
        requires       => {
            'perl'              => '5.006',
            'warnings'          => 0,
            'GD::SecurityImage' => '1.60',
            'Digest::MD5'       => 0,
        },
        build_requires => { },
        test_requires => {
            'perl'              => '5.006',
            'warnings'          => 0,
            'GD::SecurityImage' => '1.60',
            'Digest::MD5'       => 0,
        },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-GD-SecurityImage-AC/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-GD-SecurityImage-AC',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-GD-SecurityImage-AC.git',
                   web  => 'https://github.com/JerilynFranz/perl-GD-SecurityImage-AC',
               },
            },
        },
      )->create_build_script;
