#!/bin/bash

perl -I../ - <<"TEST" >s 2>e
use Debug::Message;
use Log::Dispatch;
use Log::Dispatch::Screen;

my $dispatcher = Log::Dispatch->new;
$dispatcher->add( Log::Dispatch::Screen->new( name => 'screen',
                                              min_level => '0' ));


my $std = Debug::Message->new('1');
$std->add_dispatcher($dispatcher);
$std->print("print");
$std->warn("warn");
$std->err("err");
$std->printn("print");
$std->warnn("warn");
$std->errn("err");
__END__
TEST

#grep ^$ s >/dev/null && echo "stdout() working" || echo "stdout() faulty" && true $(( error++ ))
#grep '^\\\[33mwarn\\[0m\\[1;31merr\\[0m$' e >/dev/null && echo "stderr() working" || echo "stderr() faulty" && true $(( error++ ))
#[ $error -gt 0 ] && echo "Debug::Message test failed" || echo "Debug::Message test completed successfully"
cat s e
rm s e

exit 0
