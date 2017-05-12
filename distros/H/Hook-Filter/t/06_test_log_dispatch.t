#################################################################
#
#   $Id: 06_test_log_dispatch.t,v 1.5 2008/08/26 08:11:23 erwan_lemonnier Exp $
#
#   test filtering Log::Dispatch with Hook::Filter
#

package MyTest1;

sub test {
    my $dispatcher = shift;
    $dispatcher->log(level => 'info',
		     message => "second message\n");
    $dispatcher->log_to(name => 'file',
			level => 'info',
			message => "second message bis\n");
}

1;

package MyTest2;

sub test {
    my $dispatcher = shift;
    $dispatcher->log(level => 'info',
		     message => "third message\n");
    $dispatcher->log_to(name => 'file',
			level => 'info',
			message => "third message bis\n");
}

1;

package main;

use Test::More;
use Data::Dumper;
use lib "../lib/";

my $rule_file;

# need to run this in an init block that executes before the init block from Hook::Filter,
# otherwise Hook::Filter won't find Log::Dispatch's symbol table upon creating the hooks
BEGIN {
    eval "use Module::Pluggable"; plan skip_all => "Module::Pluggable required for testing Hook::Filter" if $@;
    eval "use File::Spec"; plan skip_all => "File::Spec required for testing Hook::Filter" if $@;
    eval "use Log::Dispatch"; plan skip_all => "Log::Dispatch required for testing Log::Dispatch compatibility" if $@;
    eval "use Log::Dispatch::File"; plan skip_all => "Log::Dispatch::File required for testing Log::Dispatch compatibility" if $@;

    $rule_file = "./tmp_rules_file";

    `rm $rule_file` if (-e $rule_file);
    `touch $rule_file`;
    `echo "from !~ /^MyTest1/" >> $rule_file`;

    # ok, Log::Dispatch is available
    plan tests => 6;

    use_ok('Hook::Filter', hook => ['Log::Dispatch::log','Log::Dispatch::log_to'], rules => $rule_file);
}

my $dispatcher = Log::Dispatch->new;
$dispatcher->add(Log::Dispatch::File->new(name => 'file',
					  min_level => 'debug',
					  filename => './tmp_log_dispatch_file'));

$dispatcher->log(level => 'info',
		 message => "first message\n");

$dispatcher->log_to(name => 'file',
		    level => 'info',
		    message => "first message bis\n");

MyTest1::test($dispatcher);
MyTest2::test($dispatcher);

# log file should now contain first and third messages, but not second ones
open(IN,"tmp_log_dispatch_file") or die "failed to open log file: $!";
is(<IN>,"first message\n","check line 1");
is(<IN>,"first message bis\n","check line 2");
is(<IN>,"third message\n","check line 3");
is(<IN>,"third message bis\n","check line 4");
is(<IN>,undef,"check EOF");
close(IN);

`rm tmp_log_dispatch_file`;
`rm $rule_file`;

