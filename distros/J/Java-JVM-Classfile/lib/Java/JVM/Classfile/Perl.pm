package Java::JVM::Classfile::Perl;

use strict;
use vars qw($VERSION @ISA);
use Java::JVM::Classfile;

$VERSION = '0.16';

sub new {
  my $class = shift;
  my $filename = shift;
  my $self = {};

  my $c = Java::JVM::Classfile->new($filename);
  $self->{_class} = $c;
  bless $self, $class;
  return $self;
}

sub as_perl {
  my $self = shift;
  my $c = $self->{_class};
  my $code;
  my @cpool = @{$c->constant_pool};

  $code .= q|
package java::io::PrintStream;
sub new {
  my $class = shift;
  my $self = {};
  return bless $self, $class;
}
sub print {
  my $self = shift;
  print shift();
}
sub println {
  my $self = shift;
  my $arg = shift;
  print $arg if defined $arg;
  print "\n";
}

package java::lang::Integer;
sub parseInt {
  my($class, $s) = @_;
  return $s + 0;
}

package java::lang::System;
sub out {
  return java::io::PrintStream->new();
}

package java::lang::String;
sub new {
  my $class = shift;
  my $self = {};
  $self->{value} = "";
  return bless $self, $class;
}

sub valueOf {
  my $class = shift;
  return $_[0];
}

package java::lang::StringBuffer;
sub new {
  my $class = shift;
  my $self = {};
  $self->{value} = "";
  return bless $self, $class;
}
sub append {
  my $self = shift;
  my $text = shift;
  $self->{value} .= $text;
  return $self;
}
sub toString {
  my $self = shift;
  return $self->{value};
}
|;

  $code .= "\npackage " . $c->class . ";\n";

  $code .= "no warnings 'recursion';\n";

  die "Subclasses not supported!" if $c->superclass ne "java/lang/Object";

  foreach my $method (@{$c->methods}) {
    next if $method->name eq '<init>';
    $code .= "\nsub " . $method->name . " {\n";

    $code .= "my \@stack;\n";
    $code .= "my \$class = shift();\n";
    $code .= "my \@locals = \@_;\n";
    $code .= "my(\$o, \$p, \$return, \@in);\n";
    $code .= "my \@params;\n";
#    $code .= qq|print "locals ";\n|;
#    $code .= qq|print join("# ", \@\$locals[0]) . "\\n";\n|;
    foreach my $att (@{$method->attributes}) {
      my $name = $att->name;
      my $value = $att->value;
      next unless $name eq 'Code';
      foreach my $instruction (@{$value->code}) {
	my $label = $instruction->label;
	my $op = $instruction->op;
	my @args = @{$instruction->args};
	$code .= "$label:\n" if defined $label;
	my $javacode = "\t$op\t" . (join ", ", @{$instruction->args});
	$code .= "# $javacode\n";
#	$code .= qq|print "\@stack / code = $javacode\\n";\n|;
	if ($op eq 'getstatic') {
	  my $class = $args[0];
	  $class =~ s|/|::|g;
	  my $field = $args[1];
	  $code .= "push \@stack, $class->$field;\n";
	} elsif ($op eq 'new') {
	  my $class = $args[0];
	  $class =~ s|/|::|g;
	  $code .= "push \@stack, $class->new();\n";
	} elsif ($op eq 'invokevirtual') {
	  my $class = $args[0];
	  $class =~ s|/|::|g;
	  my $method = $args[1];
	  my $signature = $args[2];
          $code .= $self->invokevirtual_code($class, $method, $signature);
	} elsif ($op eq 'invokestatic') {
	  my $class = $args[0];
	  $class =~ s|/|::|g;
	  my $method = $args[1];
	  my $signature = $args[2];
	  my($in, $out) = $signature =~ /^\((.*?)\)(.*?)$/;
          $code .= $self->invokestatic_code($class, $method, $signature);
	} elsif ($op eq 'invokespecial') {
	  $code .= "pop \@stack;\n";
	} elsif ($op eq 'ldc') {
	  my $arg = $args[0];
	  $code .= "push \@stack, '$arg';\n";
	} elsif ($op eq 'ldc2_w') {
	  my $arg = $args[0] << 8 | $args[1]; # See JVM specs
	  $code .= "push \@stack, ".$cpool[$arg]->values->[0].";\n";
	  $code .= "push \@stack, 'FAKE VALUE FOR LONG';\n";
	} elsif ($op eq 'bipush' or $op eq 'sipush') {
	  my $arg = $args[0];
	  $code .= "push \@stack, $arg;\n";
	} elsif ($op eq 'return') {
	  $code .= "return;\n";
	} elsif ($op =~ /^[fldai]return$/) {
	  $code .= "return pop(\@stack);\n";
	} elsif ($op =~ /^[li]const_(\d)/) {
	  $code .= "push \@stack, $1;\n";
	} elsif ($op =~ /^[fai]store_(\d)/) {
	  $code .= "\$locals[$1] = pop \@stack;\n";
	} elsif ($op =~ /^[ld]store_(\d)/) {
	  $code .= "pop \@stack;\n";
	  $code .= "\$locals[$1] = pop \@stack;\n";
	} elsif ($op =~ /^[fai]store/) {
	  my $i = $args[0];
	  $code .= "\$locals[$i] = pop \@stack;\n";
	} elsif ($op =~ /^[ld]store/) {
	  my $i = $args[0];
	  $code .= "\$locals[$i] = pop \@stack;\n";
	  $code .= "pop \@stack;\n";
	} elsif ($op =~ /[fai]load_(\d)/) {
	  $code .= "push \@stack, \$locals[$1];\n";
	} elsif ($op =~ /[ld]load_(\d)/) {
	  $code .= "push \@stack, \$locals[$1];\n";
	  $code .= "push \@stack, 'FAKE VALUE FOR LONGS';\n";
	} elsif ($op =~ /^[fai]load$/) {
	  my $i = $args[0];
	  $code .= "push \@stack, \$locals[$i];\n";
	} elsif ($op =~ /^[ld]load$/) {
	  my $i = $args[0];
	  $code .= "push \@stack, \$locals[$i];\n";
	  $code .= "push \@stack, 'FAKE VALUE FOR LONGS';\n";
	} elsif ($op eq 'goto') {
	  my $label = $args[0];
	  $code .= "goto $label;\n";
	} elsif ($op eq 'dup') {
	  $code .= "push \@stack, \$stack[-1];\n";
	} elsif ($op =~ /^[fi]add$/) {
	  $code .= "push \@stack, (pop \@stack) + (pop \@stack);\n";
	} elsif ($op =~ /^[ld]add$/) {
	  $code .= qq|pop \@stack;
\$o = pop \@stack;
pop \@stack;
\$o += pop \@stack;
push \@stack, \$o;\n|;
	} elsif ($op =~ /^[fldi]sub/) {
	  $code .= "push \@stack, - (pop \@stack) + (pop \@stack);\n";
	} elsif ($op =~ /^[fldi]mul/) {
	  $code .= "push \@stack, (pop \@stack) * (pop \@stack);\n";
	} elsif ($op eq 'aaload') {
	  $code .= qq|\$o = pop \@stack;
	  my \$array = pop \@stack;
	  push \@stack, \$array->[\$o];\n|;
	} elsif ($op eq 'iinc') {
	  my $i = $args[0];
	  my $n = $args[1];
	  $code .= "\$locals[$i] += $n;\n";
	} elsif ($op eq 'if_icmplt') {
	  my $label = $args[0];
	  $code .= "goto $label if (pop \@stack) > (pop \@stack);\n";
	} elsif ($op eq 'if_icmpge') {
	  my $label = $args[0];
	  $code .= "goto $label if (pop \@stack) <= (pop \@stack);\n";
	} elsif ($op eq 'ifne') {
	  my $label = $args[0];
	  $code .= "goto $label if (pop \@stack);\n";
	} else {
	  $code .= "# ?\n";
	}
      }
    }
    $code .= "}\n\n";
  }
#  $code .= qq|print join(", ", \@ARGV) . "\\n";\n|;
  $code .= $c->class . "->main([\@ARGV]);\n";
  return $code;
}

# Invoking static methods
sub invokestatic_code {
    my $self = shift;
    my ($class, $method, $signature) = @_;

    my ($code, $incount, $doubles);
    my($in, $out) = $signature =~ /^\((.*?)\)(.*?)$/;

    $in =~ s/L[^;]*;/L/g;
    $incount = () = $in =~ /[FIL]/g;
    $doubles = () = $in =~ /[JD]/g;
    $incount += 2*$doubles;
    $out = "" if defined($out) && $out eq 'V';
    if ($in) {
	$code .= qq|\@params = splice(\@stack,-$incount);
\$return = $class->$method(\@params); # $in / $out\n|;
    } else {
	$code .= "\$return = $class->$method(); # $in / $out\n";
    }
    $code .= "push \@stack, \$return;\n" if $out;
 
    return $code;
}

# Invoking virtual methods
sub invokevirtual_code {
    my $self = shift;
    my ($class, $method, $signature) = @_;

    my ($code, $incount, $doubles);
    my($in, $out) = $signature =~ /^\((.*?)\)(.*?)$/;
    $in =~ s/L[^;]*;/L/g;
    $incount = () = $in =~ /[FIL]/g;
    $doubles = () = $in =~ /[JD]/g;
    $incount += 2*$doubles;
    $out = "" if defined($out) && $out eq 'V';

    if ($in) {
	$code .= qq|\@params = splice(\@stack,-$incount);
\$p = pop \@stack;
\$return = \$p->$method(\@params); # $in / $out\n|;
    } else {
	$code .= "\$return = (pop \@stack)->$method(); # $in / $out\n";
    }
    $code .= "push \@stack, \$return;\n" if $out;

    return $code;
}

1;
