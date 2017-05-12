#!/usr/bin/perl -w
use strict;
use lib 'lib';
use Java::JVM::Classfile;

my $c = Java::JVM::Classfile->new(shift || "HelloWorld.class");
print "Magic: " . $c->magic . "\n";
print "Version: " . $c->version . "\n";
print "Class: " . $c->class . "\n";
print "Superclass: " . $c->superclass . "\n";
print "Constant pool: " . scalar(@{$c->constant_pool}) . "\n";
print "Access flags: " . join(", ", @{$c->access_flags}) . "\n";

print "Interfaces: " . scalar(@{$c->interfaces}) . "\n";
print "Fields: " . scalar(@{$c->fields}) . "\n";

print "Methods: " . scalar(@{$c->methods}) . "\n";
foreach my $method (@{$c->methods}) {
  print "  " . $method->name . " " . $method->descriptor;
  print "\n    ";
  print "is " . join(", ", @{$method->access_flags});
  print "\n    ";
  print "has attributes:\n";
  foreach my $att (@{$method->attributes}) {
    my $name = $att->name;
    my $value = $att->value;
print "# $name = $value\n";
    if ($att->name eq 'Code') {
      print "      $name: ";
      print "stack(" . $value->max_stack . ")";
      print ", locals(" . $value->max_locals . ")\n";
      foreach my $instruction (@{$value->code}) {
	print $instruction->label . ':' if defined $instruction->label;
	print "\t" . $instruction->op . "\t" . (join ", ", @{$instruction->args}) . "\n";
      }
      print "\n";
      foreach my $att2 (@{$value->attributes}) {
	my $name2 = $att2->name;
	my $value2 = $att2->value;
	if ($name2 eq 'LineNumberTable') {
	  print "\tLineNumberTable (offset, line)\n";
	  print "\t" . $_->offset . ", " . $_->line . "\n" foreach (@$value2);
	} else {
	  print "!\t$name2 = $value2\n";
	}
      }
    } else {
      print "!\t$name $value\n";
    }
  }
}

print "Attributes: " . scalar(@{$c->attributes}) . "\n";

foreach my $attribute (@{$c->attributes}) {
  print "  " . $attribute->name . " = " . $attribute->value . "\n";
}
