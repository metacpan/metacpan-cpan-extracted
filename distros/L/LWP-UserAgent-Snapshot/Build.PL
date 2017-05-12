use strict;
use warnings;
use Module::Build;

{ # define a handy rscan_dir function
    my $manifest_skip = qr/(?!)/; # this regex always fails 
    if (open my $fh, '<', 'MANIFEST.SKIP')
    {
        # map /.*/ chomps newlines, since . doesn't match EOLs
        $manifest_skip = join '|', map /(.*)/, <$fh>;
        close $fh;
        $manifest_skip = qr/$manifest_skip/;
    }

    sub rscan_dir
    {
        grep !/$manifest_skip/, @{ Module::Build->rscan_dir(@_) };
    }
}

my $builder = Module::Build->new
    (module_name         => 'LWP::UserAgent::Snapshot',
     license             => 'artistic',
     dist_author         => 'Nick Woolley <npw@cpan.org>',
     dist_version_from   => 'lib/LWP/UserAgent/Snapshot.pm',
     dist_abstract       => 'modifies the behaviour of LWP::UserAgent to record and playback data.',
     create_readme       => 1,
     create_makefile_pl  => 'traditional',
     build_requires => 
     {
         'Module::Build' => 0.28,
     },
     requires => 
     {
      'Test::More' => 0,
      'version'    => 0,
      'LWP::UserAgent' => 0,
      'HTTP::Response' => 0,
      'Digest::MD5' => 0,
     },
     recommends => 
     {
     },
     test_files         => [ rscan_dir('t', '\.t$') ],
     add_to_cleanup      => [ 'LWP-UserAgent-Snapshot-*' ],
    );

$builder->create_build_script();
