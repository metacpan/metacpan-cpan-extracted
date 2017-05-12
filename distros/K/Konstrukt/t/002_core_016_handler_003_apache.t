# check core module: apache handler

use strict;
use warnings;

use Test::More tests => 4;

#=== Dependencies
use Cwd;
my $cwd = getcwd();
$cwd .= "/" unless substr($cwd, -1, 1) eq "/";
my $root = "${cwd}t/data/Handler/Apache/";

#use fake Apache::Constants, Apache::Cookie, Apache::FakeRequest
unshift @INC, "${root}lib";

#set up fake request
#see also fake request package below
require Apache::FakeRequest;
our $fakerequest = Apache::FakeRequest->new(
	document_root  => $root,
	filename       => "${root}testfile",
	uri            => 'http://testserver/testfile',
	method         => 'GET',
	subprocess_env => \%{ENV},
);

#mod_perl 1
$ENV{MOD_PERL} = 1;
require Konstrukt::Handler::Apache;

$fakerequest->reset_print_buffer();
is(Konstrukt::Handler::Apache::handler($fakerequest), 0, "handler");
is($fakerequest->{printed}, "testdata", "handler: result");

#mod_perl 2
$ENV{MOD_PERL} = 2;
$ENV{MOD_PERL_API_VERSION} = 2;

require Konstrukt::Handler::Apache;

$fakerequest->reset_print_buffer();
is(Konstrukt::Handler::Apache::handler($fakerequest), 0, "handler");
is($fakerequest->{printed}, "testdata", "handler: result");
