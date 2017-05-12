# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::Simple tests => 39;
use lib 'lib';
use Java::JVM::Classfile;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $c = Java::JVM::Classfile->new("examples/HelloWorld.class");
ok(ref($c), "Loaded HelloWorld");
ok($c->magic == 0xCAFEBABE, "Good magic");
ok($c->version eq '45.3', "Right compiler version");
ok($c->class eq 'HelloWorld', "Right class");
ok($c->superclass eq 'java/lang/Object', "Right superclass");
ok(scalar(@{$c->constant_pool}) == 29, "Full constant pool");
ok(scalar(@{$c->access_flags}) == 1, "Right number of class access flags");
ok($c->access_flags->[0] eq 'super', "Correct super class access flags");
ok(scalar(@{$c->interfaces}) == 0, "No interfaces");
ok(scalar(@{$c->fields}) == 0, "No fields");
ok(scalar(@{$c->methods}) == 2, "Right number of methods");

my $method = $c->methods->[0];
ok($method->name eq '<init>', "<init> named");
ok($method->descriptor eq '()V', "<init> descriptor");
ok(scalar(@{$method->access_flags}) == 0, "<init> has no access flags");
ok(scalar(@{$method->attributes}) == 1, "<init> has 1 attribute");
ok($method->attributes->[0]->name eq 'Code', "<init> has Code attribute");
my $code = $method->attributes->[0]->value;
ok($code->max_stack == 1, "<init> has 1 max stack");
ok($code->max_locals == 1, "<init> has 1 max locals");
my $text;
foreach my $instruction (@{$code->code}) {
  $text .= "\t" . $instruction->op . "\t" . (join ", ", @{$instruction->args}) . "\n";
}
ok($text eq "	aload_0	
	invokespecial	java/lang/Object, <init>, ()V
	return	
", "<init> contains good code");
ok(scalar(@{$code->attributes}) == 1, "<init> code has 1 attribute");
ok($code->attributes->[0]->name eq 'LineNumberTable', "<init> code has LineNumberTable attribute");
$text = "";
$text .= "\t" . $_->offset . ", " . $_->line . "\n" foreach (@{$code->attributes->[0]->value});
ok($text eq "	0, 1\n", "<init> code LineNumberTable correct");


$method = $c->methods->[1];
ok($method->name eq 'main', "main named");
ok($method->descriptor eq '([Ljava/lang/String;)V', "main descriptor");
ok(scalar(@{$method->access_flags}) == 2, "main has two access flags");
ok(scalar(grep { $_ eq 'public' } @{$method->access_flags}) == 1, "main has access flags public");
ok(scalar(grep { $_ eq 'static' } @{$method->access_flags}) == 1, "main has access flags static");
ok(scalar(@{$method->attributes}) == 1, "main has 1 attribute");
ok($method->attributes->[0]->name eq 'Code', "main has Code attribute");
$code = $method->attributes->[0]->value;
ok($code->max_stack == 2, "main has 2 max stack");
ok($code->max_locals == 1, "main has 1 max locals");
$text = "";
foreach my $instruction (@{$code->code}) {
  $text .= "\t" . $instruction->op . "\t" . (join ", ", @{$instruction->args}) . "\n";
}
ok($text eq "	getstatic	java/lang/System, out, Ljava/io/PrintStream;
	ldc	Hello, world!
	invokevirtual	java/io/PrintStream, print, (Ljava/lang/String;)V
	return	
", "main contains good code");
ok(scalar(@{$code->attributes}) == 1, "main code has 1 attribute");
ok($code->attributes->[0]->name eq 'LineNumberTable', "main code has LineNumberTable attribute");
$text = "";
$text .= "\t" . $_->offset . ", " . $_->line . "\n" foreach (@{$code->attributes->[0]->value});
ok($text eq "	0, 3
	8, 4
", "main code LineNumberTable correct");

ok(scalar(@{$c->attributes}) == 1, "Right number of attributes");
ok($c->attributes->[0]->name eq 'SourceFile', "SourceFile attribute present");
ok($c->attributes->[0]->value eq 'HelloWorld.java', "SourceFile attribute value correct");


exit;

