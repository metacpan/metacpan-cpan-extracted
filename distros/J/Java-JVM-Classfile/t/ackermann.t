use strict;
use Test::More tests => 54;
use lib 'lib';
use Java::JVM::Classfile;
ok(1); # If we made it this far, we're ok.

my $c = Java::JVM::Classfile->new("examples/Ackermann.class");
ok(ref($c), "Loaded class");
is($c->magic, 0xCAFEBABE, "Good magic");
is($c->version, '46.0', "Right compiler version");
is($c->class, 'Ackermann', "Right class");
is($c->superclass, 'java/lang/Object', "Right superclass");
is(scalar(@{$c->constant_pool}), 49, "Full constant pool");
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
is($text, "	0, 4\n", "<init> code LineNumberTable correct");

$method = $c->methods->[1];
is($method->name, 'main', "main named");
is($method->descriptor, '([Ljava/lang/String;)V', "main descriptor");
is(scalar(@{$method->access_flags}), 2, "main has two access flags");
is(scalar(grep { $_ eq 'public' } @{$method->access_flags}), 1, "main has access flags public");
is(scalar(grep { $_ eq 'static' } @{$method->access_flags}), 1, "main has access flags static");
is(scalar(@{$method->attributes}), 1, "main has 1 attribute");
is($method->attributes->[0]->name, 'Code', "main has Code attribute");
$code = $method->attributes->[0]->value;
is($code->max_stack, 4, "main has 4 max stack");
is($code->max_locals, 2, "main has 2 max locals");
$text = "";
foreach my $instruction (@{$code->code}) {
  $text .= $instruction->label . ':' if defined $instruction->label;
  $text .= "\t" . $instruction->op . "\t" . (join ", ", @{$instruction->args}) . "\n";
}
is($text, q|	iconst_5	
	istore_1	
	getstatic	java/lang/System, out, Ljava/io/PrintStream;
	new	java/lang/StringBuffer
	dup	
	invokespecial	java/lang/StringBuffer, <init>, ()V
	ldc	Ack(3,
	invokevirtual	java/lang/StringBuffer, append, (Ljava/lang/String;)Ljava/lang/StringBuffer;
	iload_1	
	invokevirtual	java/lang/StringBuffer, append, (I)Ljava/lang/StringBuffer;
	ldc	): 
	invokevirtual	java/lang/StringBuffer, append, (Ljava/lang/String;)Ljava/lang/StringBuffer;
	iconst_3	
	iload_1	
	invokestatic	Ackermann, Ack, (II)I
	invokevirtual	java/lang/StringBuffer, append, (I)Ljava/lang/StringBuffer;
	invokevirtual	java/lang/StringBuffer, toString, ()Ljava/lang/String;
	invokevirtual	java/io/PrintStream, println, (Ljava/lang/String;)V
	return	
|, "main contains good code");
is(scalar(@{$code->attributes}), 1, "main code has 1 attribute");
is($code->attributes->[0]->name, 'LineNumberTable', "main code has LineNumberTable attribute");
$text = "";
$text .= "\t" . $_->offset . ", " . $_->line . "\n" foreach (@{$code->attributes->[0]->value});
is($text, "	0, 6
	2, 7
	40, 8
", "main code LineNumberTable correct");

is(scalar(@{$c->attributes}), 1, "Right number of attributes");
is($c->attributes->[0]->name, 'SourceFile', "SourceFile attribute present");
is($c->attributes->[0]->value, 'Ackermann.java', "SourceFile attribute value correct");


$method = $c->methods->[2];
is($method->name, 'Ack', "method named");
is($method->descriptor, '(II)I', "descriptor");
is(scalar(@{$method->access_flags}), 2, "two access flags");
is(scalar(grep { $_ eq 'public' } @{$method->access_flags}), 1, "access flags public");
is(scalar(grep { $_ eq 'static' } @{$method->access_flags}), 1, "access flags static");
is(scalar(@{$method->attributes}), 1, "1 attribute");
is($method->attributes->[0]->name, 'Code', "Code attribute");
$code = $method->attributes->[0]->value;
is($code->max_stack, 4, "4 max stack");
is($code->max_locals, 2, "2 max locals");
$text = "";
foreach my $instruction (@{$code->code}) {
  $text .= $instruction->label . ':' if defined $instruction->label;
  $text .= "\t" . $instruction->op . "\t" . (join ", ", @{$instruction->args}) . "\n";
}
is($text, q|	iload_0	
	ifne	L10
	iload_1	
	iconst_1	
	iadd	
	goto	L37
L10:	iload_1	
	ifne	L24
	iload_0	
	iconst_1	
	isub	
	iconst_1	
	invokestatic	Ackermann, Ack, (II)I
	goto	L37
L24:	iload_0	
	iconst_1	
	isub	
	iload_0	
	iload_1	
	iconst_1	
	isub	
	invokestatic	Ackermann, Ack, (II)I
	invokestatic	Ackermann, Ack, (II)I
L37:	ireturn	
|, "main contains good code");
is(scalar(@{$code->attributes}), 1, "main code has 1 attribute");
is($code->attributes->[0]->name, 'LineNumberTable', "main code has LineNumberTable attribute");
$text = "";
$text .= "\t" . $_->offset . ", " . $_->line . "\n" foreach (@{$code->attributes->[0]->value});
is($text, "	0, 10
", "main code LineNumberTable correct");

is(scalar(@{$c->attributes}), 1, "Right number of attributes");
is($c->attributes->[0]->name, 'SourceFile', "SourceFile attribute present");
is($c->attributes->[0]->value, 'Ackermann.java', "SourceFile attribute value correct");

exit;

