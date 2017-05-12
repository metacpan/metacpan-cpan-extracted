# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use Test::More tests => 54;
use lib 'lib';
use Java::JVM::Classfile;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $c = Java::JVM::Classfile->new("examples/Spin.class");
ok(ref($c), "Loaded Spin");
is($c->magic, 0xCAFEBABE, "Good magic");
is($c->version, '46.0', "Right compiler version");
is($c->class, 'Spin', "Right class");
is($c->superclass, 'java/lang/Object', "Right superclass");
is(scalar(@{$c->constant_pool}), 30, "Full constant pool");
is_deeply($c->access_flags, ['public', 'super'], "Correct super class access flags");
is(scalar(@{$c->interfaces}), 0, "No interfaces");
is(scalar(@{$c->fields}), 0, "No fields");
is(scalar(@{$c->methods}), 3, "Right number of methods");

my $method = $c->methods->[0];
is($method->name, '<init>', "<init> named");
is($method->descriptor, '()V', "<init> descriptor");
is_deeply($method->access_flags, ['public'], "<init> has is public");
is(scalar(@{$method->attributes}), 1, "<init> has 1 attribute");
is($method->attributes->[0]->name, 'Code', "<init> has Code attribute");
my $code = $method->attributes->[0]->value;
is($code->max_stack, 1, "<init> has 1 max stack");
is($code->max_locals, 1, "<init> has 1 max locals");
my $text;
foreach my $instruction (@{$code->code}) {
  $text .= $instruction->label . ':' if defined $instruction->label;
  $text .= "\t" . $instruction->op . "\t" . (join ", ", @{$instruction->args}) . "\n";
}
is($text, "	aload_0	
	invokespecial	java/lang/Object, <init>, ()V
	return	
", "<init> contains good code");
is(scalar(@{$code->attributes}), 1, "<init> code has 1 attribute");
is($code->attributes->[0]->name, 'LineNumberTable', "<init> code has LineNumberTable attribute");
$text = "";
$text .= "\t" . $_->offset . ", " . $_->line . "\n" foreach (@{$code->attributes->[0]->value});
is($text, "	0, 3\n", "<init> code LineNumberTable correct");

$method = $c->methods->[1];
is($method->name, 'main', "main named");
is($method->descriptor, '([Ljava/lang/String;)V', "main descriptor");
is(scalar(@{$method->access_flags}), 2, "main has two access flags");
is(scalar(grep { $_ eq 'public' } @{$method->access_flags}), 1, "main has access flags public");
is(scalar(grep { $_ eq 'static' } @{$method->access_flags}), 1, "main has access flags static");
is(scalar(@{$method->attributes}), 1, "main has 1 attribute");
is($method->attributes->[0]->name, 'Code', "main has Code attribute");
$code = $method->attributes->[0]->value;
is($code->max_stack, 0, "main has 0 max stack");
is($code->max_locals, 1, "main has 1 max locals");
$text = "";
foreach my $instruction (@{$code->code}) {
  $text .= $instruction->label . ':' if defined $instruction->label;
  $text .= "\t" . $instruction->op . "\t" . (join ", ", @{$instruction->args}) . "\n";
#  $text .= "\t" . $instruction->op . "\t" . (join ", ", map { $_ = '"\n"' if $_ eq "\n" } @{$instruction->args}) . "\n";
}
is($text, q|	invokestatic	Spin, spin, ()V
	return	
|, "main contains good code");
is(scalar(@{$code->attributes}), 1, "main code has 1 attribute");
is($code->attributes->[0]->name, 'LineNumberTable', "main code has LineNumberTable attribute");
$text = "";
$text .= "\t" . $_->offset . ", " . $_->line . "\n" foreach (@{$code->attributes->[0]->value});
is($text, "	0, 5
	3, 6
", "main code LineNumberTable correct");

is(scalar(@{$c->attributes}), 1, "Right number of attributes");
is($c->attributes->[0]->name, 'SourceFile', "SourceFile attribute present");
is($c->attributes->[0]->value, 'Spin.java', "SourceFile attribute value correct");


$method = $c->methods->[2];
is($method->name, 'spin', "spin named");
is($method->descriptor, '()V', "descriptor");
is(scalar(@{$method->access_flags}), 2, "two access flags");
is(scalar(grep { $_ eq 'public' } @{$method->access_flags}), 1, "access flags public");
is(scalar(grep { $_ eq 'static' } @{$method->access_flags}), 1, "access flags static");
is(scalar(@{$method->attributes}), 1, "1 attribute");
is($method->attributes->[0]->name, 'Code', "Code attribute");
$code = $method->attributes->[0]->value;
is($code->max_stack, 2, "2 max stack");
is($code->max_locals, 1, "1 max locals");
$text = "";
foreach my $instruction (@{$code->code}) {
  $text .= $instruction->label . ':' if defined $instruction->label;
  $text .= "\t" . $instruction->op . "\t" . (join ", ", @{$instruction->args}) . "\n";
}
is($text, q|	iconst_0	
	istore_0	
	goto	L8
L5:	iinc	0, 1
L8:	iload_0	
	sipush	1000
	if_icmplt	L5
	getstatic	java/lang/System, out, Ljava/io/PrintStream;
	iload_0	
	invokevirtual	java/io/PrintStream, print, (I)V
	return	
|, "main contains good code");
is(scalar(@{$code->attributes}), 1, "main code has 1 attribute");
is($code->attributes->[0]->name, 'LineNumberTable', "main code has LineNumberTable attribute");
$text = "";
$text .= "\t" . $_->offset . ", " . $_->line . "\n" foreach (@{$code->attributes->[0]->value});
is($text, "	0, 10
	15, 11
	22, 12
", "main code LineNumberTable correct");

is(scalar(@{$c->attributes}), 1, "Right number of attributes");
is($c->attributes->[0]->name, 'SourceFile', "SourceFile attribute present");
is($c->attributes->[0]->value, 'Spin.java', "SourceFile attribute value correct");

exit;

