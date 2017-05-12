use 5.010000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTTP::Server::Simple::CGI::PreFork',
    VERSION_FROM      => 'lib/HTTP/Server/Simple/CGI/PreFork.pm', # finds $VERSION
    PREREQ_PM         => {
    "HTTP::Server::Simple" => 0.44,
    "IO::Socket::INET6" => 0,
    "Socket6"           => 0,
    "Net::Server"       => 2,
    "Net::Server::PreFork"    => 0,
    "Net::Server::Single"     => 0,
    "Net::Server::Proto::SSLEAY" => 0,
    "Net::SSLeay"   => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (#ABSTRACT_FROM  => 'lib/Maplat/ProdIT.pm', # retrieve abstract from module
       AUTHOR         => 'Rene Schickbauer <rene.schickbauer@magnapowertrain.com>') : ()),
);
