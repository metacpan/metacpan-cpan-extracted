use inc::Module::Install;

name        'Iodef-Pb-Simple';
all_from    'lib/Iodef/Pb/Simple.pm';
no_index    'examples';

requires    'Module::Install'               => '1.00';
requires    'Class::Accessor'               => '0.34';
requires    'Google::ProtocolBuffers'       => '0.08';
requires    'DateTime'                      => '0.61';
requires    'DateTime::Format::DateParse'   => '0.05';
requires    'Regexp::Common::net'           => '2010010201';
requires    'Regexp::Common::net::CIDR'     => '0.02';
requires    'Encode'                        => '2.35';
requires    'Snort::Rule'                   => '1.07';
requires    'Parse::Range'                  => '0.96';
requires    'JSON::XS'                      => '2.29';
requires    'Compress::Snappy'              => '0.18';
requires    'MIME::Base64'                  => '0.08';
requires    'HTML::Table'                   => '2.08';
requires    'Digest::SHA'                   => '5.40';
requires    'Text::Table'                   => '1.126';
requires    'OSSP::uuid'                    => '1.0602';

homepage    'https://github.com/collectiveintel/iodef-pb-simple-perl';
bugtracker  'https://github.com/collectiveintel/iodef-pb-simple-perl/issues';
repository  'https://github.com/collectiveintel/iodef-pb-simple-perl.git';

WriteAll();
