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
    (module_name         => 'HTML::Encapsulate',
     license             => 'artistic',
     dist_author         => 'Nick Woolley <npw@cpan.org>',
     dist_version_from   => 'lib/HTML/Encapsulate.pm',
     dist_abstract       => 'rewrites an HTML page as a self-contained set of files',
     create_readme       => 1,
     create_makefile_pl  => 'traditional',
     build_requires => 
     {
         'Module::Build' => 0.28,
         'LWP::UserAgent::Snapshot' => 0,
     },
     requires => 
     {
      'perl' => '5.6.1',
      'Test::More' => 0,
      'version'    => 0,
      'HTML::TreeBuilder::XPath' => 0,
      'LWP::UserAgent' => 0,
      'HTML::Tidy' => 0,
      'HTTP::Response::Encoding' => 0,
      'HTML::Entities' => 0,
      'HTML::HeadParser' => 0,
      'HTTP::Headers::Util' => 0,
      'HTTP::Request' => 0,
      'URI' => 0, 
     },
     # Encode::Detect recommended as a final fallback to encoding detection
     recommends => 
     {
      'Test::Files' => 0.14,
      'Encode::Detect' => 0,
      'Encode::Detect::Detector' => 0,
     },
     test_files         => [ rscan_dir('t', '\.t$') ],
     add_to_cleanup      => [ 'HTML-Encapsulate-*' ],
    );

$builder->create_build_script();
