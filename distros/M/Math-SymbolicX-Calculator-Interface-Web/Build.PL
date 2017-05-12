use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Math::SymbolicX::Calculator::Interface::Web',
   dist_author => 'Steffen Mueller <smueller@cpan.org>',
   license => 'perl',
   requires => {
       'Math::SymbolicX::Calculator::Interface' => '0.01',
       'Params::Util' => '0',
       'Math::Symbolic' => '0.501',
       'Parse::RecDescent' => '0',
       'HTTP::Server::Simple' => '0',
       'CGI::Ajax' => '0',
       'Pod::Usage' => '0',
       'Getopt::Long' => '0',
               },
   recommends => {
                  'Test::Pod' => '1.0',
                  'Test::Pod::Coverage' => '1.0',
                 },
   build_requires => {
                      'Test::More' => 0,
                     },
   create_makefile_pl => 'traditional',
#   conflicts => {},
   script_files => ['bin/symbolic_calculator_web_server'],
  );

$b->create_build_script;

