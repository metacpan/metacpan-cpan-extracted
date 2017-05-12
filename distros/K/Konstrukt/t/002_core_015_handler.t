# check core module: handler

use strict;
use warnings;

use Test::More tests => 9;

#=== Dependencies
use Cwd;
my $cwd = getcwd();
$cwd .= "/" unless substr($cwd, -1, 1) eq "/";
my $root = "${cwd}t/data/Handler/";

#Handler

#create with ambiguous filename<->root combination
my $handler = Konstrukt::Test::TestHandler->new($root, "${root}testfile");
like($Konstrukt::Debug->format_error_messages(), qr/_must_ be relative to the document root/, "new: absolute path warning");
$Konstrukt::Debug->init(); #reset

#create with non absolute root
$handler = Konstrukt::Test::TestHandler->new("t/data/Handler/", "/testfile");
like($Konstrukt::Debug->format_error_messages(), qr/_must_ be an absolute path/, "new: relative root warning");
$Konstrukt::Debug->init(); #reset

#create test handler object with "normal" filename
$handler = Konstrukt::Test::TestHandler->new($root, '/testfile');
is(ref($handler), 'Konstrukt::Test::TestHandler', "new");
is($Konstrukt::Handler->{filename}, '/testfile', "filename");
is($Konstrukt::Handler->{abs_filename}, "${root}testfile", "abs_filename");

#process
is($handler->process(), "testdata", "process");

#handler
$handler->handler();
is($handler->{result}, "testdata", "handler");

#emergency exit
$handler = Konstrukt::Test::TestHandler->new($root, '/doesnt_exist');
eval {
	$handler->handler();
};
is($handler->{died}, 1, "emergency exit: own method");
$handler = Konstrukt::Test::TestHandlerNoEmExit->new($root, '/doesnt_exist');
eval {
	$handler->handler();
};
is(defined($@), 1, "emergency exit: default method");

exit;

package Konstrukt::Test::TestHandler;

use Konstrukt::Handler;

#inherit new(), process() and emergency_exit()
use base 'Konstrukt::Handler';

#create handler sub. usually a bit more comprehensive. see existing handlers
sub handler {
	my ($self) = @_;
	$self->{result} = $self->process();
}

#optional: overwrite method emergency_exit to provide some more info.
sub emergency_exit {
	my ($self) = @_;
	$self->{died} = 1;
	die;
}

1;

package Konstrukt::Test::TestHandlerNoEmExit;

use Konstrukt::Handler;

#inherit new(), process() and emergency_exit()
use base 'Konstrukt::Handler';

#create handler sub. usually a bit more comprehensive. see existing handlers
sub handler {
	my ($self) = @_;
	$self->{result} = $self->process();
}

1;

#Create file handler
use Konstrukt::Handler::File;

my $filehandler = Konstrukt::Handler::File->new('t/data', 'foo.txt');
#$Konstrukt::Settings->load_settings('/konstrukt.settings');
#my $result = $filehandler->process();
#print $result;

#Apache Handler
#use Konstrukt::Handler::Apache;

#CGI Handler
use Konstrukt::Handler::CGI;

#File Handler
use Konstrukt::Handler::File;
