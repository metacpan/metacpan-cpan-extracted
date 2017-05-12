# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 39;
use lib 'lib';
use Java::JVM::Classfile;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $c = Java::JVM::Classfile->new("examples/Bench.class");
ok(ref($c), "Loaded Bench");
ok($c->magic == 0xCAFEBABE, "Good magic");
ok($c->version eq '45.3', "Right compiler version");
ok($c->class eq 'Bench', "Right class");
ok($c->superclass eq 'java/lang/Object', "Right superclass");
ok(scalar(@{$c->constant_pool}) == 45, "Full constant pool");
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
  $text .= $instruction->label . ':' if defined $instruction->label;
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
ok($code->max_stack == 3, "main has 3 max stack");
ok($code->max_locals == 5, "main has 5 max locals");
$text = "";
foreach my $instruction (@{$code->code}) {
  $text .= $instruction->label . ':' if defined $instruction->label;
  $text .= "\t" . $instruction->op . "\t" . (join ", ", map { ($_ eq "\n") ? '"\n"' : $_ } @{$instruction->args}) . "\n";
}
is($text, q|	iconst_1	
	istore_1	
	iconst_1	
	istore_2	
	iconst_1	
	istore_3	
	iconst_1	
	istore	4
	goto	L74
L12:	iconst_1	
	istore_2	
	goto	L65
L17:	getstatic	java/lang/System, out, Ljava/io/PrintStream;
	new	java/lang/StringBuffer
	dup	
	invokespecial	java/lang/StringBuffer, <init>, ()V
	iload_1	
	invokevirtual	java/lang/StringBuffer, append, (I)Ljava/lang/StringBuffer;
	ldc	, 
	invokevirtual	java/lang/StringBuffer, append, (Ljava/lang/String;)Ljava/lang/StringBuffer;
	iload_2	
	invokevirtual	java/lang/StringBuffer, append, (I)Ljava/lang/StringBuffer;
	ldc	"\n"
	invokevirtual	java/lang/StringBuffer, append, (Ljava/lang/String;)Ljava/lang/StringBuffer;
	invokevirtual	java/lang/StringBuffer, toString, ()Ljava/lang/String;
	invokevirtual	java/io/PrintStream, print, (Ljava/lang/String;)V
	iinc	3, 1
	iload	4
	iload_3	
	iconst_2	
	imul	
	iadd	
	istore	4
	iinc	2, 1
L65:	iload_2	
	bipush	10
	if_icmplt	L17
	iinc	1, 1
L74:	iload_1	
	bipush	10
	if_icmplt	L12
	return	
|, "main contains good code");
ok(scalar(@{$code->attributes}) == 1, "main code has 1 attribute");
ok($code->attributes->[0]->name eq 'LineNumberTable', "main code has LineNumberTable attribute");
$text = "";
$text .= "\t" . $_->offset . ", " . $_->line . "\n" foreach (@{$code->attributes->[0]->value});
ok($text eq "	0, 3
	2, 4
	4, 5
	6, 6
	9, 7
	12, 8
	14, 9
	17, 10
	51, 11
	54, 12
	62, 13
	65, 9
	71, 15
	74, 7
	80, 17
", "main code LineNumberTable correct");

ok(scalar(@{$c->attributes}) == 1, "Right number of attributes");
ok($c->attributes->[0]->name eq 'SourceFile', "SourceFile attribute present");
ok($c->attributes->[0]->value eq 'Bench.java', "SourceFile attribute value correct");


exit;

