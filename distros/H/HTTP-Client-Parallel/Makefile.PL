use inc::Module::Install 0.76;

all_from      'lib/HTTP/Client/Parallel.pm';
requires      'Exporter'                     => 0;
requires      'IO::File'                     => 0;
requires      'Scalar::Util'                 => 0;
requires      'File::Spec'                   => '0.80';
requires      'HTTP::Request'                => 0;
requires      'Params::Util'                 => '0.24';
requires      'POE'                          => '1.000';
requires      'POE::Component::Client::HTTP' => 0;
test_requires 'Test::More'                   => '0.42';
test_requires 'LWP::Online'                  => '1.06';
# test_requires 'Test::TempDir'                => '0.04';

WriteAll;
