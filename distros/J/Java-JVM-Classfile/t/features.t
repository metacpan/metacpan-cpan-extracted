use strict;
use Test::Simple tests => 13;
use lib 'lib';
use Java::JVM::Classfile;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $c = Java::JVM::Classfile->new("examples/Features.class");
ok($c->class eq 'Features', 'class name');
ok(scalar(@{$c->interfaces}) == 1, 'interfaces');
ok($c->interfaces->[0] eq 'java/lang/Runnable', 'interface');
ok(scalar(@{$c->fields}) == 2, 'fields');
ok($c->fields->[0]->name eq 'cnt', 'field name');
ok($c->fields->[0]->descriptor eq 'I', 'field type');
my $run = $c->methods->[1];
ok($run->name eq 'run', 'method run');
ok($run->attributes->[0]->name eq 'Code', 'code');
my $code = $run->attributes->[0]->value;
ok(scalar(@{$code->exception_table}) >= 2, 'exceptions');
ok($code->exception_table->[0]->catch_type eq 'java/lang/ClassCastException', 'catch');
ok($code->exception_table->[1]->catch_type eq '*', 'finally');
ok($code->attributes->[1]->name eq 'LocalVariableTable', 'debug: loval variables'); 
