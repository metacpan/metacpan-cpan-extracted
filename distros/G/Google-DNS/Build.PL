use strict;
use warnings;
use Module::Build::Pluggable qw/CPANfile/;

my $builder = Module::Build::Pluggable->new(
    name                => 'Google-DNS',
    module_name         => 'Google::DNS',
    license             => 'perl',
    dist_author         => 'Dai Okabayashi <bayashi@cpan.org>',
    script_files        => [ 'script/digle' ],
    dist_version_from   => 'lib/Google/DNS.pm',
    add_to_cleanup      => [ 'Google-DNS-*' ],
    meta_merge     => {
      resources => {
        repository  => 'http://github.com/bayashi/Google-DNS',
        bugtracker  => 'http://github.com/bayashi/Google-DNS/issues',
        x_IRC       => {
            url => 'irc://chat.freenode.org/#bayadev',
            web => 'http://webchat.freenode.net/?channels=%23bayadev',
        },
      }
    },
    recursive_test_files => 1,
    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? ['t/', 'xt/'] : ['t/'],
    create_license => 1,
);

$builder->create_build_script();
