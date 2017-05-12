
# ConstantPoolEntry
package Java::JVM::Classfile::ConstantPoolEntry;
use Class::Struct;
use overload '""' => \&as_text;
struct(type => '$', #'
       values => '@');
sub as_text {
  my $self = shift;
  return $self->type . '(' . join(", ", @{$self->values}) . ')';
}
sub value {
  my $self = shift;
  return $self->values->[0];
}

# Method
package Java::JVM::Classfile::Method;
use Class::Struct;
use overload '""' => \&as_text;
struct(access_flags => '@',
       name => '$',
       descriptor => '$',
       attributes => '$'); #'
sub as_text {
  my $self = shift;
  my $result = "";
  $result .= $self->name . " ";
  $result .= $self->descriptor . " ";
  $result .= "[" . join(", ", @{$self->access_flags}) . "] ";
  $result .="= " . join(", ", @{$self->attributes}) . "] ";
  return $result;
}

# Field
package Java::JVM::Classfile::Field;
use Class::Struct;
use overload '""' => \&as_text;
struct(access_flags => '@',
       name => '$',
       descriptor => '$',
       attributes => '$'); #'
sub as_text {
  my $self = shift;
  my $result = "";
  $result .= $self->name . " ";
  $result .= $self->descriptor . " ";
  $result .= "[" . join(", ", @{$self->access_flags}) . "] ";
  $result .="= " . join(", ", @{$self->attributes}) . "] ";
  return $result;
}


# Attribute
package Java::JVM::Classfile::Attribute;
use Class::Struct;
use overload '""' => \&as_text;
struct(name => '$',
       value => '$');
sub as_text {
  my $self = shift;
  my $name = $self->name;
  return $name . ' (' . $self->value . ')';
}

# Attribute::Code
package Java::JVM::Classfile::Attribute::Code;
use Class::Struct;
use overload '""' => \&as_text;
struct(max_stack => '$',
       max_locals => '$',
       code => '$',
       exception_table => '$',
       attributes => '$');
sub as_text {
  my $self = shift;
  my $return;
  $return .= "stack(" . $self->max_stack . ")";
  $return .= ", locals(" . $self->max_locals . ")";
}

# Struct
package Java::JVM::Classfile::Struct;
use Class::Struct;
use overload '""' => \&as_text;
struct(magic => '$',
       version => '$',
       constant_pool => '$',
       access_flags => '@',
       class => '$',
       superclass => '$',
       interfaces => '$',
       fields => '$',
       methods => '$',
       attributes => '$',
); #'
sub as_text {
  my $self = shift;
  my $result;
  $result .= "Magic: " . $self->magic . "\n";
  $result .= "Version: " . $self->version . "\n";
  $result .= "Class: " . $self->class . "\n";
  $result .= "Superclass: " . $self->superclass . "\n";
  $result .= "Constant pool:\n" . join(", ", @{$self->constant_pool}) . "\n";
  $result .= "Access flags: " . join(", ", @{$self->access_flags}) . "\n";
  $result .= "Interfaces: " . join(", ", @{$self->interfaces} ) . "\n";
  $result .= "Fields:\n" . join(",\n", @{$self->fields}) . "\n";
  $result .= "Methods:\n" . join(",\n", @{$self->methods}) . "\n";
  $result .= "Attributes:\n" . join(", ", @{$self->attributes}) . "\n";
  return $result;
}

# Instruction
package Java::JVM::Classfile::Instruction;
use Class::Struct;
struct(label => '$',
       op => '$', # '
       args => '@');
use overload '""' => \&as_text;
sub as_text {
  my $self = shift;
  my $label = $self->label;
  my $op = $self->op;
  my @args = @{$self->args};

  my $output;
  $output .= 'L' . $label . ':' if defined $label;
  $output .= "\t";
  $output .= $op;
  $output .= "\t";
  $output .= join(", ", @args);
  return $output;
}

# LineNumber
package Java::JVM::Classfile::LineNumber;
use Class::Struct;
struct(offset => '$',
       line => '$');

package Java::JVM::Classfile::LocalVariable;
use Class::Struct;
struct(start_pc => '$', length => '$', name => '$', descriptor => '$', index => '$');

package Java::JVM::Classfile::LocalVariableType;
use Class::Struct;
struct(start_pc => '$', length => '$', name => '$', signature => '$', index => '$');

package Java::JVM::Classfile::Exception;
use Class::Struct;
struct(start_pc => '$', end_pc => '$', handler_pc => '$', catch_type => '$');


# Classfile
package Java::JVM::Classfile;

use strict;
use vars qw($VERSION);
use IO::File;
use Carp qw(croak);

use constant Utf8 => 1;
use constant Integer => 3;
use constant Float => 4;
use constant Long => 5;
use constant Double => 6;
use constant Class => 7;
use constant Fieldref => 9;
use constant String => 8;
use constant Methodref => 10;
use constant InterfaceMethodref => 11;
use constant NameAndType => 12;

use constant ACC_PUBLIC       => 0x0001;
use constant ACC_PRIVATE      => 0x0002;
use constant ACC_PROTECTED    => 0x0004;
use constant ACC_STATIC       => 0x0008;

use constant ACC_FINAL        => 0x0010;
use constant ACC_SYNCHRONIZED => 0x0020;
use constant ACC_VOLATILE     => 0x0040;
use constant ACC_TRANSIENT    => 0x0080;

use constant ACC_NATIVE       => 0x0100;
use constant ACC_INTERFACE    => 0x0200;
use constant ACC_ABSTRACT     => 0x0400;
use constant ACC_STRICT       => 0x0800;

# Applies to classes compiled by new compilers only
use constant ACC_SUPER        => 0x0020;
use constant MAX_ACC_FLAG     => ACC_ABSTRACT;
my @CLASSACCESS;
$CLASSACCESS[0] = "public";
$CLASSACCESS[3] = "final";
$CLASSACCESS[5] = "super";
$CLASSACCESS[8] = "interface";
$CLASSACCESS[9] = "abstract";

my @METHODACCESS;
$METHODACCESS[0] = "public";
$METHODACCESS[1] = "private";
$METHODACCESS[2] = "protected";
$METHODACCESS[3] = "static";
$METHODACCESS[4] = "final";
$METHODACCESS[5] = "synchronized";
$METHODACCESS[7] = "native";
$METHODACCESS[9] = "abstract";
$METHODACCESS[10] = "strict";

my @ACCESS = (
    "public", "private", "protected", "static", "final", "synchronized",
    "volatile", "transient", "native", "interface", "abstract");

$VERSION = '0.20';

use constant T_BOOLEAN => 4;
use constant T_CHAR    => 5;
use constant T_FLOAT   => 6;
use constant T_DOUBLE  => 7;
use constant T_BYTE    => 8;
use constant T_SHORT   => 9;
use constant T_INT     => 10;
use constant T_LONG    => 11;
use constant T_VOID      => 12;
use constant T_ARRAY     => 13;
use constant T_OBJECT    => 14;
use constant T_REFERENCE => 14;
use constant T_UNKNOWN   => 15;
use constant T_ADDRESS   => 16;

# Import all the constants
use Java::JVM::Classfile::Ops qw(%ops);

sub new {
  my $proto = shift;
  my $filename = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  $self->{FILENAME} = $filename;

  bless($self, $class);
  return $self->_parse;

#  return $self;
}

sub _parse {
  my $self = shift;
  $self->{FH} = IO::File->new($self->{FILENAME}) or croak("Couldn't read class " . $self->{FILENAME} . "!");

  my $magic = $self->check_magic;
  my $version = $self->read_version;
  my $constant_pool = $self->read_constant_pool;
  my($access_flags, $class, $superclass) = $self->read_class_info($constant_pool);
  my $interfaces = $self->read_interfaces($constant_pool);
  my $fields = $self->read_fields($constant_pool);
  my $methods = $self->read_methods($constant_pool);
  my $attributes = $self->read_attributes($constant_pool);

  my $struct = Java::JVM::Classfile::Struct->new(
    magic => $magic,
    version => $version,
    constant_pool => $constant_pool,
    access_flags => $access_flags,
    class => $class,
    superclass => $superclass,
    interfaces => $interfaces,
    fields => $fields,
    methods => $methods,
    attributes => $attributes,
  );

#  print $struct;

  die "Junk at end of file!\n" unless $self->{FH}->eof;
  $self->{FH}->close;
  return $struct;
}

sub check_magic {
  my $self = shift;
  my $magic = $self->read_u4;
  die "Not Java class file!\n" unless ($magic eq 0xCAFEBABE);
  return $magic;
}

sub read_version {
  my $self = shift;
  my $minor = $self->read_u2;
  my $major = $self->read_u2;
  return "$major.$minor";
}

sub read_constant_pool {
  my $self = shift;
  my $count = $self->read_u2;

  my @constant_pool;

#  print "Constant pool entries: $count \n";
  for(my $index=1; $index<$count; $index++) {
#    print "constant pool $index: ";
    my $type = $self->read_u1;
    if ($type == Methodref) {
      my $class_index = $self->read_u2;
      my $name_and_type_index = $self->read_u2;
      $constant_pool[$index] = Java::JVM::Classfile::ConstantPoolEntry->new(type =>
        'methodref', values => [$class_index, $name_and_type_index]);
#      print "methodref $class_index, $name_and_type_index\n";
    } elsif ($type == Fieldref) {
      my $class_index = $self->read_u2;
      my $name_and_type_index = $self->read_u2;
      $constant_pool[$index] = Java::JVM::Classfile::ConstantPoolEntry->new(type =>
        'fieldref', values => [$class_index, $name_and_type_index]);
#      print "fieldref $class_index, $name_and_type_index\n";
    } elsif ($type == InterfaceMethodref) {
      my $class_index = $self->read_u2;
      my $name_and_type_index = $self->read_u2;
      $constant_pool[$index] = Java::JVM::Classfile::ConstantPoolEntry->new(type =>
        'interfacemethodref', values => [$class_index, $name_and_type_index]);
#      print "interfacemethodref $class_index, $name_and_type_index\n";
    } elsif ($type == Class) {
      my $name_index = $self->read_u2;
      $constant_pool[$index] = Java::JVM::Classfile::ConstantPoolEntry->new(type =>
        'class', values => [$name_index]);
#      print "class $name_index\n";
    } elsif ($type == Utf8) {
      my $length = $self->read_u2;
      my $string;
      $string .= chr($self->read_u1) foreach (1..$length);
      $constant_pool[$index] = Java::JVM::Classfile::ConstantPoolEntry->new(type =>
        'utf8', values => [$string]);
#      print "String: $string\n";
    } elsif ($type == NameAndType) {
      my $name_index = $self->read_u2;
      my $descriptor_index = $self->read_u2;
      $constant_pool[$index] = Java::JVM::Classfile::ConstantPoolEntry->new(type =>
        'nameandtype', values => [$name_index, $descriptor_index]);
#      print "nameandtype: $name_index $descriptor_index\n";
    } elsif ($type == String) {
      my $string_index = $self->read_u2;
      $constant_pool[$index] = Java::JVM::Classfile::ConstantPoolEntry->new(type =>
        'string', values => [$string_index]);
#      print "String: $string_index\n";
    } elsif ($type == Integer) {
      my $bytes = $self->read_u4;
      $constant_pool[$index] = Java::JVM::Classfile::ConstantPoolEntry->new(type =>
        'integer', values => [$bytes]);
#      print "Integer: \n";
    } elsif ($type == Float) {
      my $bytes = $self->read_u4;
      my $float = $self->float_value($bytes);
      $constant_pool[$index] = Java::JVM::Classfile::ConstantPoolEntry->new(type =>
        'float', values => [$float]);
#      print "Float: \n";

# JVM Specs: All 8-byte constants take up two entries in the constant_pool 
# table of the class file. If a CONSTANT_Long_info or CONSTANT_Double_info 
# structure is the item in the constant_pool table at index n, then the next 
# usable item in the pool is located at index n+2. The constant_pool index 
# n+1 must be valid but is considered unusable. (In retrospect, making 8-byte 
# constants take two constant pool entries was a poor choice.)

    } elsif ($type == Long) {
      my $high_bytes = $self->read_u4;
      my $low_bytes = $self->read_u4;
      my $long = $self->long_value($high_bytes, $low_bytes);
      $constant_pool[$index] = Java::JVM::Classfile::ConstantPoolEntry->new(type =>
              'long', values => [$long]);
      $constant_pool[++$index] = 0;
#      print "Long: $long\n";
    } elsif ($type == Double) {
      my $high_bytes = $self->read_u4;
      my $low_bytes = $self->read_u4;
      my $double = $self->double_value($high_bytes, $low_bytes);
      $constant_pool[$index] = Java::JVM::Classfile::ConstantPoolEntry->new(type =>
              'double', values => [$double]);
      $constant_pool[++$index] = 0;
#      print "Double: $high_bytes, $low_bytes\n";
    } else {
      die "unknown constant type $type in pool!\n";
    }
  }

  return \@constant_pool;
}

# JVM long format is ((long) high_bytes << 32) + low_bytes 
sub long_value {

    my $self = shift;
    my ($high_bytes, $low_bytes) = @_;
    return ($high_bytes << 32) + $low_bytes;
}

# JVM floats are in IEEE 754 floating-point single format
sub float_value {

    my $self = shift;
    my ($bits) = @_;

    my $s = (($bits >> 31) == 0) ? 1 : -1;
    my $e = (($bits >> 23) & 0xff);
    my $m = ($e == 0) ? ($bits & 0x7fffff) << 1 : ($bits & 0x7fffff) | 0x800000;

    return $s*$m*(2**($e-150));
}

# JVM doubles are in IEEE 754 floating-point double format
sub double_value {

    my $self = shift;
    my ($high_bytes, $low_bytes) = @_;
    return 3.14;
}

sub read_class_info {
  my($self, $constant_pool) = @_;


  my @flags;
  my $access_flags = $self->read_u2;

  if(($access_flags & ACC_INTERFACE) != 0) {
    $access_flags |= ACC_ABSTRACT;
  }

  if((($access_flags & ACC_ABSTRACT) != 0) && 
     (($access_flags & ACC_FINAL)    != 0 )) {
    die("Class can't be both final and abstract");
  }

#  print "Access flags: $access_flags = ";
  my $bits = reverse unpack("B*", pack ("c*" ,$access_flags));
#  print "($bits) is ";
  foreach my $index (0..length($bits)) {
#    print $CLASSACCESS[$index] if substr($bits, $index, 1);
    push @flags, $CLASSACCESS[$index] if substr($bits, $index, 1);
  }
#  print "\n";
  my $myclass_name = $self->read_class_name($constant_pool, 'Class');

  my $superclass_name = $self->read_class_name($constant_pool, 'Superclass');

  return \@flags, $myclass_name, $superclass_name;
#  print "Class is $class_name_index, super $superclass_name_index\n";
}

sub read_interfaces {
  my ($self, $constant_pool) = @_;

  my $interfaces_count = $self->read_u2;
  my @interfaces;
  for my $ii (0 .. $interfaces_count-1) {
    push @interfaces, $self->read_class_name($constant_pool, 'Interface');
  }

  return \@interfaces;
}

sub read_class_name {
  my ($self, $constant_pool, $diagnostics) = @_;
  return get_class_name($self->read_u2, $constant_pool, $diagnostics);
}

sub get_class_name {
  my ($index, $constant_pool, $diagnostics) = @_;
  my $class = $constant_pool->[$index];
  die "$diagnostics name index doesn't point to class!" unless $class->type eq 'class';
  my $class_name = $constant_pool->[$class->value];
  die "$diagnostics name class doesn't point to string!" unless $class_name->type eq 'utf8';
  return $class_name->value;
}

sub read_fields {
  my ($self, $constant_pool) = @_;

  my $fields_count = $self->read_u2;
  my @fields;
  for my $fi (0 .. $fields_count-1) {
    my @access_flags = $self->read_access_flags;

    my $name = $self->read_name($constant_pool);
    my $descriptor = $self->read_descriptor($constant_pool);
    my $attributes = $self->read_attributes($constant_pool);

    push @fields, Java::JVM::Classfile::Field->new(
        name         => $name,
        access_flags => \@access_flags,
        descriptor   => $descriptor,
        attributes   => $attributes
    );
  }
  
  return \@fields;
}

sub read_constant_string {
  my ($self, $constant_pool, $diagnostics) = @_;
  my $name_index = $self->read_u2; #name_index
  my $name_struct = $constant_pool->[$name_index];
  die "$diagnostics: index doesn't point to string" unless $name_struct->type eq 'utf8';
  return $name_struct->value;
}

sub read_name { read_constant_string(@_, 'name');}

sub read_descriptor { read_constant_string(@_, 'descriptor');}

sub read_signature { read_constant_string(@_, 'signature');}

sub read_access_flags {
  my $self = shift;
    my $access_flags = $self->read_u2;
    my @access_flags;

    my $bits = reverse unpack("B*", pack ("c*" ,$access_flags));
    foreach my $index (0..length($bits)) {
      push @access_flags, $METHODACCESS[$index] if substr($bits, $index, 1);
    }
    return @access_flags;
  }

sub read_methods {
  my($self, $constant_pool) = @_;

  my @methods;

  my $method_count = $self->read_u2;
#  print "Methods: $method_count\n";

  foreach my $index (0..$method_count-1) {
#    $methods[$_] = $self->read_u2;

    my @access_flags = $self->read_access_flags;
    my $name = $self->read_name($constant_pool);
    my $descriptor = $self->read_descriptor($constant_pool);
    my $attributes = $self->read_attributes($constant_pool);

    push @methods, Java::JVM::Classfile::Method->new(
      name => $name,
      access_flags => \@access_flags,
      descriptor => $descriptor,
      attributes => $attributes,
    );
  }

  return \@methods;
}

sub read_attributes {
  my($self, $constant_pool) = @_;

  my $attributes_count = $self->read_u2;
#  print "count: $attributes_count\n";
  my @attributes;
  foreach (0..$attributes_count-1) {
    my $attribute_name_index = $self->read_u2;
#    print "index: $attribute_name_index\n";
    my $attribute_name = $constant_pool->[$attribute_name_index];
#    print "= $attribute_name\n";
    die "attribute_name_index doesn't point to string" unless $attribute_name->type eq 'utf8';
    $attribute_name = $attribute_name->value;
    my $attribute_length = $self->read_u4;
    my $info;
    if ($attribute_name eq 'Code') {
      my $max_stack = $self->read_u2;
      my $max_locals = $self->read_u2;
      my $code = $self->read_code($constant_pool);
      my $exception_table_length = $self->read_u2;
      my @exception_table;
      for (1 .. $exception_table_length) {
        my $start_pc = $self->read_u2; 
        my $end_pc = $self->read_u2;
        my $handler_pc = $self->read_u2;
        my $catch_type_index = $self->read_u2;
        my $catch_type = $catch_type_index ? get_class_name($catch_type_index, $constant_pool, 'Exception') : "*";
        push @exception_table, Java::JVM::Classfile::Exception->new(
          start_pc=>$start_pc, end_pc=>$end_pc, handler_pc=>$handler_pc, catch_type=>$catch_type)
      }
      
      my $atts = $self->read_attributes($constant_pool);

      $info = Java::JVM::Classfile::Attribute::Code->new(
        max_stack => $max_stack,
        max_locals => $max_locals,
        code => $code,
        exception_table => \@exception_table,
        attributes => $atts,
      );
    } elsif ($attribute_name eq 'SourceFile') {
      die "length not 2" if $attribute_length != 2;
      my $sourcefile_index = $self->read_u2;
      my $sourcefile = $constant_pool->[$sourcefile_index];
      die "sourcefile_index doesn't point to string" unless $sourcefile->type eq 'utf8';
      $info = $sourcefile->value;
    } elsif ($attribute_name eq 'LineNumberTable') {
      my $line_number_table_length = $self->read_u2;
      my @lines;
      foreach (0..$line_number_table_length-1) {
	my $start_pc = $self->read_u2;
	my $line_number = $self->read_u2;
	push @lines, Java::JVM::Classfile::LineNumber->new(offset => $start_pc, line => $line_number);
      }
      $info = \@lines;
    } elsif ($attribute_name eq 'LocalVariableTypeTable') {
      my $local_variable_table_length = $self->read_u2;
      my @local_variables;
      for (1 .. $local_variable_table_length) {
        my $start_pc = $self->read_u2;
        my $length = $self->read_u2; #TODO validate
        my $name = $self->read_name($constant_pool);
        my $signature = $self->read_signature($constant_pool);
        my $index = $self->read_u2;
        push @local_variables, Java::JVM::Classfile::LocalVariableType->new(
          start_pc=>$start_pc, 'length'=>$length, name=>$name, signature=>$signature, 'index'=>$index
        );
      }
      $info = \@local_variables;
    } elsif ($attribute_name eq 'LocalVariableTable') {
      my $local_variable_table_length = $self->read_u2;
      my @local_variables;
      for (1 .. $local_variable_table_length) {
        my $start_pc = $self->read_u2;
        my $length = $self->read_u2; #TODO validate 
        my $name = $self->read_name($constant_pool);
        my $descriptor = $self->read_descriptor($constant_pool);
        my $index = $self->read_u2;
        push @local_variables, Java::JVM::Classfile::LocalVariable->new(
          start_pc=>$start_pc, 'length'=>$length, name=>$name, descriptor=>$descriptor, 'index'=>$index
        );
      }
      $info = \@local_variables;
    } elsif ($attribute_name eq 'Signature') {
      $info = $self->read_signature($constant_pool);
    } else {
      warn "unknown attribute $attribute_name!\n";
      # Fake it for now
      $info = "";
      $info .= chr($self->read_u1) foreach (0..$attribute_length-1);
    }
#    print "info: $info<--\n" if $attribute_name ne 'Code';
    push @attributes, Java::JVM::Classfile::Attribute->new(name => $attribute_name, value => $info);
  }
  return \@attributes;
}


sub read_code {
  my($self, $constant_pool) = @_;

  my $code_length = $self->read_u4;
  my $offset = 0;
  my $is_wide = 0;
  my $index = 0;

  my @instructions;
  my @fixups;
  my %offsets;
  my %offset;

  while($offset < $code_length) {
    my $origoffset = $offset;
    my $u1 = $self->read_u1;
    $offset += 1;
    my $op = $ops{$u1};
    my $opname = $op->{name};
    my $type = $op->{type};
    my @operands;
#    print "# $opname ($type)\n";

    if ($type eq 'noargs') {
    } elsif ($type eq 'byte') {
      my $u1 = $self->read_u1;
      $offset += 1;
      push @operands, $u1;
    } elsif ($type eq 'bytevar') {
      my $u1 = $self->read_u1;
      $offset += 1;
      push @operands, $u1;
    } elsif ($type eq 'byteindex') {
      my $u1 = $self->read_u1;
      $offset += 1;
      push @operands, $self->get_index($u1, $constant_pool);
    } elsif ($type eq 'twobytes') {
      my $u1 = $self->read_u1;
      $u1 = $u1 - 256 if $u1 > 128;
      $offset += 1;
      push @operands, $u1;
      $u1 = $self->read_u1;
      $u1 = $u1 - 256 if $u1 > 128;
      $offset += 1;
      push @operands, $u1;
    } elsif ($type eq 'int') {
      my $u2 = $self->read_u2;
      $offset += 2;
      push @operands, $u2;
    } elsif ($type eq 'intindex') {
      my $u2 = $self->read_u2;
      $offset += 2;
      push @operands, $self->get_index($u2, $constant_pool);
    } elsif ($type eq 'intbranch') {
      my $u2 = $self->read_u2;
      $u2 = $u2 - 65536 if $u2 > 31268;
      $offset += 2;
      push @operands, $u2;
      push @fixups, $index;
    } else {
      die "unknown type $type, uh-oh!";
    }

    my $i = Java::JVM::Classfile::Instruction->new(op => $opname, args => \@operands, label => 'L'.$origoffset);
    push @instructions, $i;
#    print "$i\n";
#    print "# $offset $opname " . join(", ", @operands) . "\n";

    $offsets{$origoffset} = $index;
    $offset{$index} = $origoffset;
    $index++;
  }

  # Fix up pointers
  my %is_target;
  foreach my $fixup (@fixups) {
    my $i = $instructions[$fixup];
    my $offset = $i->args->[0] + $offset{$fixup};
    my $target = $instructions[$offsets{$offset}];
#    print "! Fixing up $i ($offset) -> $target\n";
    $instructions[$fixup] = Java::JVM::Classfile::Instruction->new(
    op => $i->op, args => ['L'.$offset], label => $i->label);
    $i = $instructions[$fixup];
    $is_target{$target}++;
  }

  foreach my $i (@instructions) {
    $i->label(undef) unless $is_target{$i};
  }

  return \@instructions;
}

sub get_index {
  my($self, $index, $constant_pool) = @_;

  my $constant = $constant_pool->[$index];
  my $type = $constant->type;
  my @operands;

#  print "# $index = $constant\n";
  if ($type eq 'methodref') {
    push @operands, $constant_pool->[$constant_pool->[$constant->values->[0]]->values->[0]]->value;
    push @operands, $constant_pool->[$constant_pool->[$constant->values->[1]]->values->[0]]->value;
    push @operands, $constant_pool->[$constant_pool->[$constant->values->[1]]->values->[1]]->value;
  } elsif ($type eq 'interfacemethodref') {
    push @operands, $constant_pool->[$constant_pool->[$constant->values->[0]]->values->[0]]->value;
    push @operands, $constant_pool->[$constant_pool->[$constant->values->[1]]->values->[0]]->value;
    push @operands, $constant_pool->[$constant_pool->[$constant->values->[1]]->values->[1]]->value;
  } elsif ($type eq 'fieldref') {
    push @operands, $constant_pool->[$constant_pool->[$constant->values->[0]]->values->[0]]->value;
    push @operands, $constant_pool->[$constant_pool->[$constant->values->[1]]->values->[0]]->value;
    push @operands, $constant_pool->[$constant_pool->[$constant->values->[1]]->values->[1]]->value;
  } elsif ($type eq 'class') {
    push @operands, $constant_pool->[$constant->value]->value;
  } elsif ($type eq 'string') {
    push @operands, $constant_pool->[$constant->value]->value;
  } elsif ($type eq 'float') {
    push @operands, $constant->value;
  } elsif ($type eq 'integer') {
    push @operands, $constant->value;
  } else {
    die "unknown index type $type!\n";
  }

  return @operands;
}

sub read_u4 {
  my $self = shift;
  my $fh = $self->{FH};
  local $/ = \1;
  my $int = unpack('C', <$fh>);
  $int *= 256;
  $int += unpack('C', <$fh>);
  $int *= 256;
  $int += unpack('C', <$fh>);
  $int *= 256;
  $int += unpack('C', <$fh>);
  return $int;
}

sub read_u2 {
  my $self = shift;
  my $fh = $self->{FH};
  local $/ = \1;
  my $int = unpack('C', <$fh>);
  $int *= 256;
  $int += unpack('C', <$fh>);
  return $int;
}

sub read_u1 {
  my $self = shift;
  my $fh = $self->{FH};
  local $/ = \1;
  my $int = unpack('C', <$fh>);
  return $int;
}


1;

__END__

=head1 NAME

Java::JVM::Classfile - Parse JVM Classfiles

=head1 SYNOPSIS

  use Java::JVM::Classfile;

  my $c = Java::JVM::Classfile->new("HelloWorld.class");
  print "Class: " . $c->class . "\n";
  print "Methods: " . scalar(@{$c->methods}) . "\n";

=head1 DESCRIPTION

The Java Virtual Machine (JVM) is an abstract machine which processes
JVM classfiles. Such classfiles contain, broadly speaking,
representations of the Java methods and member fields forming the
definition of a single class, information to support the exception
mechanism and a system for representing additional class
attributes. The JVM itself exists primarily to load and link
classfiles into the running machine on demand (performed by the Class
Loader), represent those classes internally by means of a number of
runtime data structures and facilitate execution (a role shared
between the Execution Engine (which is responsible for execution of
JVM instructions) and the Native Method Interface which allows a Java
program to execute non-Java code, generally ANSI C/C++.

This Perl module reveals the information in a highly-compressed JVM
classfile by representing the information as a series of objects. It
is hoped that this module will eventually lead to a JVM implementation
in Perl (or Parrot), or possibly a way-ahead-of-time (WAT) to Perl (or
Parrot) compiler for Java.

It is important to remember that the Java classfile is
highly-compressed. Classfiles are intended to be as small as possible
as they are often sent across the network. This may explain the
slightly odd object tree. One of the most important things to consider
is the idea of a constant pool. All constants (constant strings,
method names and signatures etc.) are clustered in the constant pool
at the start of the classfile, and sprinkled throughout the file are
references to the constant pool. The module attempts to hide this
optimisation as much as possible from the user, however.

It is probably important to at least have briefly read "The JavaTM
Virtual Machine Specification", http://java.sun.com/docs/books/vmspec/

=head1 METHODS

=head2 new

This is the constructor, it takes the filename of the classfile to
parse and returns an object:

  my $c = Java::JVM::Classfile->new("HelloWorld.class");

=head2 magic

This method returns the magic number for the classfile. All valid
classfiles should have the magic number 0xCAFEBABE:

  my $magic = $c->magic;

=head2 version

This method returns the version of the classfile. The version consists
of a major number and a minor number. For example, "45.3" has major
number 45 and minor number 3:

  my $version = $c->version;

=head2 class

This method returns the name of the class that this classfile
corresponds to:

  my $class = $c->class;

=head2 superclass

This method returns the name of the superclass of the class that this
classfile corresponds to:

  my $superclass = $c->superclass;

=head2 constant_pool

This method returns the constant pool entries as an array
reference. Each entry is an object. Currently undocumented.

  my $constant_pool = $c->constant_pool;

=head2 access_flags

This method returns the access flags for the class as an array
reference. Possible flags are:

=over 4

=item abstract

Declared abstract; may not be instantiated

=item final

Declared final; no subclasses allowed

=item interface

Is an interface, not a class

=item public

Declared public; may be accessed from outside its package

=item super

Treat superclass methods specially when invoked by the invokespecial instruction

=back

  print "Flags: " . join(", ", @{$c->access_flags}) . "\n";

=head2 interfaces

This method returns an array reference of the interfaces defined in
the classfile:

  my $interfaces = $c->interfaces;

=head2 fields

This method returns an array reference of the fields defined in
the classfile:

  my $fields = $c->fields;

=head2 methods

This method returns an array reference of the methods defined in
the classfile:

  my $methods = $c->methods;

Each Java method is represented by an object which has the following
methods: name, descriptor, access_flags and attributes. name and
descriptor return the method name and descriptor. Possible access
flags are:

=over 4

=item abstract

Declared abstract; no implementation is provided

=item final

Declared final; may not be overridden

=item native

Declared native; implemented in a language other than Java

=item private

Declared private; accessible only within the defining class

=item protected

Declared protected; may be accessed within subclasses

=item public

Declared public; may be accessed from outside its package

=item static

Declared static

=item strict

Declared strictfp; floating-point mode is FP-strict

=item synchronized

Declared synchronized; invocation is wrapped in a monitor lock

=back

Various attributes are possible, the most common being the Code
attribute, where the value holds information about the Java bytecode
for the method:

  foreach my $method (@{$c->methods}) {
    print "  " . $method->name . " " . $method->descriptor;
    print "\n    ";
    print "is " . join(", ", @{$method->access_flags});
    print "\n    ";
    print "has attributes: ";
    foreach my $att (@{$method->attributes}) {
      my $name = $att->name;
      my $value = $att->value;
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
    print "\n";
  }

Note that in the case of the Code attribute, the value contains an
object which has three main methods: max_stack (the maximum depth of
stack needed by the method), max_locals (the number of local variables
used by the method), code (returns an arrayref of instruction objects
which have op, args and label methods), and attributes. One attribute
that Code can have is the LineNumberTable attributes, which has an
arrayref of objects as a value. These have offset and line methods,
representing a link between bytecode offset and sourcecode line.



=head2 attributes

This method returns an array reference of the attributes defined in
the classfile. Attributes are common in many places in the classfile -
here in particular we have the classfile attributes.

  my $attributes = $c->attributes;

Attributes are represented by an object that has name and value methods:

  foreach my $attribute (@{$c->attributes}) {
    print "  " . $attribute->name . " = " . $attribute->value . "\n";
  }

Possible attributes include the SourceFile attribute, the value of
which is the source file that was compiled into this classfile.

=head1 BUGS

A number of classfile features are not currently supported. This will
be fixed real soon now.

Not enough test programs.

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2001-7, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

