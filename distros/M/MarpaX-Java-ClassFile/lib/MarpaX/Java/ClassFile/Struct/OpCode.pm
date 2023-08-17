use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::OpCode;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_constant_pool offset relativeOffset mnemonic code parameters/],
  -oneLineDescription => 1,
  '""' => [
           [ sub { '{Offset, RelativeOffset, Code}' } => sub { '{' . join(', ', $_[0]->offset, $_[0]->relativeOffset, join(' ', $_[0]->mnemonic, @{$_[0]->parameters})) . '}' } ]
          ];

# The operand of each ldc instruction and each ldc_w instruction must be a valid index into the constant_pool table.
# The constant pool entry referenced by that index must be of type:
sub _around_when_first_param_is_and_index {
  my ($orig, $self) = @_;
  my $list = $self->$orig;
  #
  # Deep copy what is necessary
  #
  my @copy = @{$list};
  #
  # Change the "y" part of x => y in the description of the first field
  #
  my $firstParam = $copy[0];
  my $x = $firstParam->[0];
  my $y = $firstParam->[1];
  my $newy = sub { $y->(@_) . ' // ' . $_[0]->_constant_pool->[$_[0]->parameters->[0]] };
  $copy[0] = [ $x, $newy ];

  \@copy
}

# ABSTRACT: Op code

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U1/;
use Types::Standard qw/Str ArrayRef/;
use Types::Common::Numeric qw/PositiveOrZeroInt/;

has _constant_pool => ( is => 'rw', required => 1, isa => ArrayRef);
has offset         => ( is => 'ro', required => 1, isa => PositiveOrZeroInt );
has relativeOffset => ( is => 'ro', required => 1, isa => PositiveOrZeroInt );
has mnemonic       => ( is => 'ro', required => 1, isa => Str );
has code           => ( is => 'ro', required => 1, isa => U1 );
has parameters     => ( is => 'ro', required => 1, isa => ArrayRef );

#
# Do the per-opcode detail in this package
#
package MarpaX::Java::ClassFile::Struct::OpCode::Aaload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Aastore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Aconst_null;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Aload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Aload_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Aload_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Aload_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Aload_3;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Anewarray;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Areturn;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Arraylength;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Astore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Astore_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Astore_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Astore_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Astore_3;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Athrow;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Baload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Bastore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Bipush;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Caload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Castore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Checkcast;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::D2f;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::D2i;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::D2l;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dadd;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Daload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dastore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dcmpg;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dcmpl;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dconst_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dconst_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ddiv;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dload_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dload_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dload_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dload_3;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dmul;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dneg;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Drem;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dreturn;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dstore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dstore_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dstore_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dstore_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dstore_3;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dsub;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dup;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dup_x1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dup_x2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dup2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dup2_x1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Dup2_x2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::F2d;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::F2i;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::F2l;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fadd;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Faload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fastore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fcmpg;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fcmpl;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fconst_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fconst_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fconst_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fdiv;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fload_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fload_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fload_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fload_3;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fmul;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fneg;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Frem;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Freturn;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fstore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fstore_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fstore_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fstore_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fstore_3;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Fsub;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Getfield;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Getstatic;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Goto;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Goto_w;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::I2b;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::I2c;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::I2d;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::I2f;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::I2l;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::I2s;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iadd;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iaload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iand;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iastore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iconst_m1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iconst_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iconst_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iconst_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iconst_3;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iconst_4;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iconst_5;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Idiv;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::If_acmpeq;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::If_acmpne;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::If_icmpeq;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::If_icmpne;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::If_icmplt;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::If_icmpge;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::If_icmpgt;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::If_icmple;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ifeq;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ifne;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iflt;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ifge;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ifgt;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ifle;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ifnonnull;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ifnull;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iinc;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iload_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iload_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iload_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iload_3;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Imul;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ineg;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Instanceof;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Invokedynamic;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Invokeinterface;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Invokespecial;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Invokestatic;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Invokevirtual;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Ior;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Irem;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ireturn;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ishl;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ishr;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Istore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Istore_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Istore_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Istore_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Istore_3;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Isub;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Iushr;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ixor;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Jsr;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Jsr_w;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::L2d;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::L2f;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::L2i;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Ladd;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Laload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Land;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lastore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lcmp;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lconst_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lconst_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

# The operand of each ldc instruction and each ldc_w instruction must be a valid index into the constant_pool table.
# The constant pool entry referenced by that index must be of type:

package MarpaX::Java::ClassFile::Struct::OpCode::Ldc;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Ldc_w;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Ldc2_w;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Ldiv;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lload_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lload_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lload_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lload_3;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lmul;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lneg;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lookupswitch;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lor;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lrem;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lreturn;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lshl;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lshr;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lstore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lstore_0;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lstore_1;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lstore_2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lstore_3;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lsub;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lushr;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Lxor;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Monitorenter;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Monitorexit;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Multianewarray;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::New;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Newarray;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Nop;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Pop;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Pop2;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Putfield;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Putstatic;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';
use Class::Method::Modifiers qw/around/;
around stringifySetup => sub { goto &MarpaX::Java::ClassFile::Struct::OpCode::_around_when_first_param_is_and_index };

package MarpaX::Java::ClassFile::Struct::OpCode::Ret;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Return;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Saload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Sastore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Sipush;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Swap;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Tableswitch;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_iload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_fload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_aload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_lload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_dload;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_istore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_fstore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_astore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_lstore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_dstore;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_ret;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

package MarpaX::Java::ClassFile::Struct::OpCode::Wide_iinc;
use parent 'MarpaX::Java::ClassFile::Struct::OpCode';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::OpCode - Op code

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
