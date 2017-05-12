use ExtUtils::MakeMaker;
#
#require 5.6;

WriteMakefile(
  'NAME'         => 'JRPC',  #  module name (Mod::Pack)
  #'DISTNAME' => '', # Explicit dist filename
  'VERSION_FROM' => 'JRPC.pm', # finds $VERSION
  'ABSTRACT'     => 'Fast and extensible JSON-RPC Service Framework (CGI/mod_perl/Nginx)',
  #ABSTRACT_FROM
  'AUTHOR'       => 'Olli Hollmen',
  # Class name => ver
  'PREREQ_PM'    => {
    'CGI' => 0, # Note in new debian this will NOT be in CORE
    'Data::Dumper' => 0,
    'JSON::XS' => 0, # libjson-xs-perl
    'LWP' => 0, # libwww-perl
    'HTTP::Server::Simple' => 0, # libhttp-server-simple-perl
  },
  # Ref to executables to be copied to INST_SCRIPT directory
  # 'EXE_FILES' => [],
  # Mapping of XS to C files
  #'XS' => {'Image Depot.xs' => 'Image Depot.c'},
  #'XSOPT' => '-extern',
  #'TYPEMAPS' => ['','']
);
