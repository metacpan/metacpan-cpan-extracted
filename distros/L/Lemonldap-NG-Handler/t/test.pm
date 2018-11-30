package main;

sub hostname { 'test1.example.com' }

package Lemonldap::NG::Handler::Test;

use Lemonldap::NG::Handler::Main;
our @ISA = qw(Lemonldap::NG::Handler::Main);
our $header;

use constant defaultLogger => 'Lemonldap::NG::Common::Logger::Std';

use constant REDIRECT => 302;

#sub hostname           { 'test1.example.com' }
*hostname = \&main::hostname;
*logger   = \&Lemonldap::NG::Handler::Main::logger;
sub newRequest         { 1 }
sub header_in          { "" }
sub is_initial_req     { '1' }
sub remote_ip          { '127.0.0.1' }
sub args               { undef }
sub unparsed_uri       { '/' }
sub uri                { '/' }
sub uri_with_args      { '/' }
sub get_server_port    { '80' }
sub set_header_out     { $header = join( ':', $_[1], $_[2], ); }
sub setServerSignature { 1 }
sub _lmLog             { 1 }
1;
