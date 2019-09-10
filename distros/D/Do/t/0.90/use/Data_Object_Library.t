use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Library

=abstract

Data-Object Type Library

=synopsis

  use Data::Object::Library;

=inherits

Type::Library
Types::Standard
Types::Common::String
Types::Common::Numeric

=description

This package provides a core type library for the L<Do> framework.

=footers

+=head1 CONSTRAINTS

This package provides the following type constraints.

+=head2 any

  # Any

The C<Any> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Any> function can be
used to throw an exception is the argument can not be validated. The C<is_Any>
function can be used to return true or false if the argument can not be
validated.

+=head2 arraylike

  # ArrayLike

The C<ArrayLike> type constraint is provided by the L<Types::TypeTiny> library.
Please see that documentation for more information. The C<assert_ArrayLike>
function can be used to throw an exception if the argument can not be
validated. The C<is_ArrayLike> function can be used to return true or false if
the argument can not be validated.

+=head2 argsobj

  # ArgsObj

The C<ArgsObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Args> object. The
C<assert_ArgsObj> function can be used to throw an exception if the argument
can not be validated. The C<is_ArgsObj> function can be used to return true or
false if the argument can not be validated.

+=head2 argsobject

  # ArgsObject

The C<ArgsObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Args> object. The
C<assert_ArgsObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ArgsObject> function can be used to return true
or false if the argument can not be validated.

+=head2 arrayobj

  # ArrayObj

The C<ArrayObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Array> object. The
C<assert_ArrayObj> function can be used to throw an exception if the argument can
not be validated. The C<is_ArrayObj> function can be used to return true or false
if the argument can not be validated.

+=head2 arrayobject

  # ArrayObject

The C<ArrayObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Array> object. The
C<assert_ArrayObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ArrayObject> function can be used to return true or
false if the argument can not be validated.

+=head2 arrayref

  # ArrayRef

The C<ArrayRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ArrayRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_ArrayRef> function can be used to return true or false if the
argument can not be validated.

+=head2 bool

  # Bool

The C<Bool> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Bool> function can be
used to throw an exception if the argument can not be validated. The C<is_Bool>
function can be used to return true or false if the argument can not be
validated.

+=head2 classname

  # ClassName["MyClass"]

The C<ClassName> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ClassName>
function can be used to throw an exception if the argument can not be
validated. The C<is_ClassName> function can be used to return true or false if the
argument can not be validated.

+=head2 codelike

  # CodeLike

The C<CodeLike> type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_CodeLike> function can be
used to throw an exception if the argument can not be validated. The C<is_CodeLike>
function can be used to return true or false if the argument can not be
validated.

+=head2 cliobj

  # CliObj

The C<CliObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Cli> object. The C<assert_CliObj>
function can be used to throw an exception if the argument can not be
validated. The C<is_CliObj> function can be used to return true or false if the
argument can not be validated.

+=head2 cliobject

  # CliObject

The C<CliObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Cli> object. The
C<assert_CliObject> function can be used to throw an exception if the argument
can not be validated. The C<is_CliObject> function can be used to return true or
false if the argument can not be validated.

+=head2 codeobj

  # CodeObj

The C<CodeObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Code> object. The C<assert_CodeObj>
function can be used to throw an exception if the argument can not be
validated. The C<is_CodeObj> function can be used to return true or false if the
argument can not be validated.

+=head2 codeobject

  # CodeObject

The C<CodeObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Code> object. The
C<assert_CodeObject> function can be used to throw an exception if the argument
can not be validated. The C<is_CodeObject> function can be used to return true or
false if the argument can not be validated.

+=head2 coderef

  # CodeRef

The C<CodeRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_CodeRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_CodeRef> function can be used to return true or false if the argument can not
be validated.

+=head2 consumerof

  # ConsumerOf["MyRole"]

The C<ConsumerOf> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ConsumerOf>
function can be used to throw an exception if the argument can not be
validated. The C<is_ConsumerOf> function can be used to return true or false if
the argument can not be validated.

+=head2 dataobj

  # DataObj

The C<DataObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Data> object. The
C<assert_DataObj> function can be used to throw an exception if the argument
can not be validated. The C<is_DataObj> function can be used to return true or
false if the argument can not be validated.

+=head2 dataobject

  # DataObject

The C<DataObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Data> object. The
C<assert_DataObject> function can be used to throw an exception if the argument
can not be validated. The C<is_DataObject> function can be used to return true
or false if the argument can not be validated.

+=head2 defined

  # Defined

The C<Defined> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Defined> function
can be used to throw an exception if the argument can not be validated. The
C<is_Defined> function can be used to return true or false if the argument can not
be validated.

+=head2 dict

  # Dict

The C<Dict> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Dict> function can be
used to throw an exception if the argument can not be validated. The C<is_Dict>
function can be used to return true or false if the argument can not be
validated.

+=head2 enum

  # Enum[qw(A B C)]

The C<Enum> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Enum> function can be
used to throw an exception if the argument can not be validated. The C<is_Enum>
function can be used to return true or false if the argument can not be
validated.

+=head2 exceptionobj

  # ExceptionObj

The C<ExceptionObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Exception> object. The
C<assert_ExceptionObj> function can be used to throw an exception if the
argument can not be validated. The C<is_ExceptionObj> function can be used to
return true or false if the argument can not be validated.

+=head2 exceptionobject

  # ExceptionObject

The C<ExceptionObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Exception> object. The
C<assert_ExceptionObject> function can be used to throw an exception if the
argument can not be validated. The C<is_ExceptionObject> function can be used
to return true or false if the argument can not be validated.

+=head2 filehandle

  # FileHandle

The C<FileHandle> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_FileHandle>
function can be used to throw an exception if the argument can not be
validated. The C<is_FileHandle> function can be used to return true or false if
the argument can not be validated.

+=head2 floatobj

  # FloatObj

The C<FloatObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Float> object. The
C<assert_FloatObj> function can be used to throw an exception if the argument can
not be validated. The C<is_FloatObj> function can be used to return true or false
if the argument can not be validated.

+=head2 floatobject

  # FloatObject

The C<FloatObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Float> object. The
C<assert_FloatObject> function can be used to throw an exception if the argument
can not be validated. The C<is_FloatObject> function can be used to return true or
false if the argument can not be validated.

+=head2 funcobj

  # FuncObj

The C<FuncObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Func> object. The
C<assert_FuncObj> function can be used to throw an exception if the argument
can not be validated. The C<is_FuncObj> function can be used to return true or
false if the argument can not be validated.

+=head2 funcobject

  # FuncObject

The C<FuncObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Func> object. The
C<assert_FuncObject> function can be used to throw an exception if the argument
can not be validated. The C<is_FuncObject> function can be used to return true
or false if the argument can not be validated.

+=head2 globref

  # GlobRef

The C<GlobRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_GlobRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_GlobRef> function can be used to return true or false if the argument can not
be validated.

+=head2 hasmethods

  # HasMethods["new"]

The C<HasMethods> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_HasMethods>
function can be used to throw an exception if the argument can not be
validated. The C<is_HasMethods> function can be used to return true or false if
the argument can not be validated.

+=head2 hashlike

  # HashLike

The C<HashLike> type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_HashLike> function can be
used to throw an exception if the argument can not be validated. The C<is_HashLike>
function can be used to return true or false if the argument can not be
validated.

+=head2 hashobj

  # HashObj

The C<HashObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Hash> object. The C<assert_HashObj>
function can be used to throw an exception if the argument can not be
validated. The C<is_HashObj> function can be used to return true or false if the
argument can not be validated.

+=head2 hashobject

  # HashObject

The C<HashObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Hash> object. The
C<assert_HashObject> function can be used to throw an exception if the argument
can not be validated. The C<is_HashObject> function can be used to return true or
false if the argument can not be validated.

+=head2 hashref

  # HashRef

The C<HashRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_HashRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_HashRef> function can be used to return true or false if the argument can not
be validated.

+=head2 instanceof

  # InstanceOf[MyClass]

The C<InstanceOf> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_InstanceOf>
function can be used to throw an exception if the argument can not be
validated. The C<is_InstanceOf> function can be used to return true or false if
the argument can not be validated.

+=head2 int

  # Int

The C<Int> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Int> function can be
used to throw an exception if the argument can not be validated. The C<is_Int>
function can be used to return true or false if the argument can not be
validated.

+=head2 intobj

  # IntObj

The C<IntObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntObj> function can be used to throw an exception if the argument can
not be validated. The C<is_IntObj> function can be used to return true or false if
the argument can not be validated.

+=head2 intobject

  # IntObject

The C<IntObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntObject> function can be used to throw an exception if the argument can
not be validated. The C<is_IntObject> function can be used to return true or false
if the argument can not be validated.

+=head2 intrange

  # IntRange[0, 25]

The C<IntRange> type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_IntRange> function can be
used to throw an exception if the argument can not be validated. The C<is_IntRange>
function can be used to return true or false if the argument can not be
validated.

+=head2 integerobj

  # IntegerObj

The C<IntegerObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntegerObj> function can be used to throw an exception if the argument
can not be validated. The C<is_IntegerObj> function can be used to return true or
false if the argument can not be validated.

+=head2 integerobject

  # IntegerObject

The C<IntegerObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntegerObject> function can be used to throw an exception if the argument
can not be validated. The C<is_IntegerObject> function can be used to return true
or false if the argument can not be validated.

+=head2 item

  # Item

The C<Item> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Item> function can be
used to throw an exception if the argument can not be validated. The C<is_Item>
function can be used to return true or false if the argument can not be
validated.

+=head2 laxnum

  # LaxNum

The C<LaxNum> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_LaxNum> function
can be used to throw an exception if the argument can not be validated. The
C<is_LaxNum> function can be used to return true or false if the argument can not
be validated.

+=head2 lowercasesimplestr

  # LowerCaseSimpleStr

The C<LowerCaseSimpleStr> type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_LowerCaseSimpleStr> function can be used to throw an exception if the
argument can not be validated. The C<is_LowerCaseSimpleStr> function can be used
to return true or false if the argument can not be validated.
information.

+=head2 lowercasestr

  # LowerCaseStr

The C<LowerCaseStr> type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The C<assert_type>
function can be used to throw an exception if the argument can not be
validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.

+=head2 map

  # Map[Int, HashRef]

The C<Map> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Map> function can be
used to throw an exception if the argument can not be validated. The C<is_Map>
function can be used to return true or false if the argument can not be
validated.

+=head2 maybe

  # Maybe[Object]

The C<Maybe> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Maybe> function can be
used to throw an exception if the argument can not be validated. The C<is_Maybe>
function can be used to return true or false if the argument can not be
validated.

+=head2 negativeint

  # NegativeInt

The C<NegativeInt> type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_NegativeInt> function can be used to throw an exception if the argument
can not be validated. The C<is_NegativeInt> function can be used to return true or
false if the argument can not be validated.

+=head2 negativenum

  # NegativeNum

The C<NegativeNum> type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_NegativeNum> function can be used to throw an exception if the argument
can not be validated. The C<is_NegativeNum> function can be used to return true or
false if the argument can not be validated.

+=head2 negativeorzeroint

  # NegativeOrZeroInt

The C<NegativeOrZeroInt> type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_NegativeOrZeroInt> function can be used to throw an exception if the
argument can not be validated. The C<is_NegativeOrZeroInt> function can be used to
return true or false if the argument can not be validated.
information.

+=head2 negativeorzeronum

  # NegativeOrZeroNum

The C<NegativeOrZeroNum> type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

+=head2 nonemptysimplestr

  # NonEmptySimpleStr

The C<NonEmptySimpleStr> type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

+=head2 nonemptystr

  # NonEmptyStr

The C<NonEmptyStr> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_type> function
can be used to throw an exception if the argument can not be validated. The
C<is_type> function can be used to return true or false if the argument can not be
validated.

+=head2 num

  # Num

The C<Num> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Num> function can be
used to throw an exception if the argument can not be validated. The C<is_Num>
function can be used to return true or false if the argument can not be
validated.

+=head2 numobj

  # NumObj

The C<NumObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumObj> function can be used to throw an exception if the argument can
not be validated. The C<is_NumObj> function can be used to return true or false if
the argument can not be validated.

+=head2 numobject

  # NumObject

The C<NumObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumObject> function can be used to throw an exception if the argument can
not be validated. The C<is_NumObject> function can be used to return true or false
if the argument can not be validated.

+=head2 numrange

  # NumRange[0, 25]

The C<NumRange> type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_NumRange> function can be
used to throw an exception if the argument can not be validated. The C<is_NumRange>
function can be used to return true or false if the argument can not be
validated.

+=head2 numberobject

  # NumberObject

The C<NumberObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumberObject> function can be used to throw an exception if the argument
can not be validated. The C<is_NumberObject> function can be used to return true
or false if the argument can not be validated.

+=head2 numericcode

  # NumericCode

The C<NumericCode> type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_NumericCode> function can be used to throw an exception if the argument
can not be validated. The C<is_NumericCode> function can be used to return true or
false if the argument can not be validated.

+=head2 object

  # Object

The C<Object> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Object> function
can be used to throw an exception if the argument can not be validated. The
C<is_Object> function can be used to return true or false if the argument can not
be validated.

+=head2 optsobj

  # OptsObj

The C<OptsObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Opts> object. The
C<assert_OptsObj> function can be used to throw an exception if the argument
can not be validated. The C<is_OptsObj> function can be used to return true or
false if the argument can not be validated.

+=head2 optsobject

  # OptsObject

The C<OptsObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Opts> object. The
C<assert_OptsObject> function can be used to throw an exception if the argument
can not be validated. The C<is_OptsObject> function can be used to return true
  or false if the argument can not be validated.

+=head2 optlist

  # OptList

The C<OptList> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_OptList> function
can be used to throw an exception if the argument can not be validated. The
C<is_OptList> function can be used to return true or false if the argument can not
be validated.

+=head2 optional

  # Dict[id => Optional[Int]]

The C<Optional> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Optional>
function can be used to throw an exception if the argument can not be
validated. The C<is_Optional> function can be used to return true or false if the
argument can not be validated.

+=head2 overload

  # Overload[qw("")]

The C<Overload> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Overload>
function can be used to throw an exception if the argument can not be
validated. The C<is_Overload> function can be used to return true or false if the
argument can not be validated.

+=head2 password

  # Password

The C<Password> type constraint is provided by the L<Types::Common::String>
library.  Please see that documentation for more information. The
C<assert_Password> function can be used to throw an exception if the argument
can not be validated. The C<is_Password> function can be used to return true or
false if the argument can not be validated.

+=head2 positiveint

  # PositiveInt

The C<PositiveInt> type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_PositiveInt> function can be used to throw an exception if the argument
can not be validated. The C<is_PositiveInt> function can be used to return true or
false if the argument can not be validated.

+=head2 positivenum

  # PositiveNum

The C<PositiveNum> type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_PositiveNum> function can be used to throw an exception if the argument
can not be validated. The C<is_PositiveNum> function can be used to return true or
false if the argument can not be validated.

+=head2 positiveorzeroint

  # PositiveOrZeroInt

The C<PositiveOrZeroInt> type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_PositiveOrZeroInt> function can be used to throw an exception if the
argument can not be validated. The C<is_PositiveOrZeroInt> function can be used to
return true or false if the argument can not be validated.
information.

+=head2 positiveorzeronum

  # PositiveOrZeroNum

The C<PositiveOrZeroNum> type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

+=head2 ref

  # Ref["SCALAR"]

The C<Ref> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_type> function can be
used to throw an exception if the argument can not be validated. The C<is_type>
function can be used to return true or false if the argument can not be
validated.

+=head2 regexpobj

  # RegexpObj

The C<RegexpObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Regexp> object. The
C<assert_RegexpObj> function can be used to throw an exception if the argument can
not be validated. The C<is_RegexpObj> function can be used to return true or false
if the argument can not be validated.

+=head2 regexpobject

  # RegexpObject

The C<RegexpObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Regexp> object. The
C<assert_RegexpObject> function can be used to throw an exception if the argument
can not be validated. The C<is_RegexpObject> function can be used to return true
or false if the argument can not be validated.

+=head2 regexpref

  # RegexpRef

The C<RegexpRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_RegexpRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_RegexpRef> function can be used to return true or false if the
argument can not be validated.

+=head2 replaceobj

  # ReplaceObj

The C<ReplaceObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Replace> object. The
C<assert_ReplaceObj> function can be used to throw an exception if the argument
can not be validated. The C<is_ReplaceObj> function can be used to return true
or false if the argument can not be validated.

+=head2 replaceobject

  # ReplaceObject

The C<ReplaceObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Replace> object. The
C<assert_ReplaceObject> function can be used to throw an exception if the
argument can not be validated. The C<is_ReplaceObject> function can be used to
return true or false if the argument can not be validated.

+=head2 rolename

  # RoleName

The C<RoleName> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_RoleName>
function can be used to throw an exception if the argument can not be
validated. The C<is_RoleName> function can be used to return true or false if the
argument can not be validated.

+=head2 scalarobj

  # ScalarObj

The C<ScalarObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Scalar> object. The
C<assert_ScalarObj> function can be used to throw an exception if the argument can
not be validated. The C<is_ScalarObj> function can be used to return true or false
if the argument can not be validated.

+=head2 scalarobject

  # ScalarObject

The C<ScalarObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Scalar> object. The
C<assert_ScalarObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ScalarObject> function can be used to return true
or false if the argument can not be validated.

+=head2 scalarref

  # ScalarRef

The C<ScalarRef> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ScalarRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_ScalarRef> function can be used to return true or false if the
argument can not be validated.

+=head2 searchobj

  # SearchObj

The C<SearchObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Search> object. The
C<assert_SearchObj> function can be used to throw an exception if the argument
can not be validated. The C<is_SearchObj> function can be used to return true
or false if the argument can not be validated.

+=head2 searchobject

  # SearchObject

The C<SearchObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Search> object. The
C<assert_SearchObject> function can be used to throw an exception if the
argument can not be validated. The C<is_SearchObject> function can be used to
return true or false if the argument can not be validated.

+=head2 simplestr

  # SimpleStr

The C<SimpleStr> type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_SimpleStr> function can be used to throw an exception if the argument can
not be validated. The C<is_SimpleStr> function can be used to return true or false
if the argument can not be validated.

+=head2 singledigit

  # SingleDigit

The C<SingleDigit> type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_SingleDigit> function can be used to throw an exception if the argument
can not be validated. The C<is_SingleDigit> function can be used to return true or
false if the argument can not be validated.

+=head2 spaceobj

  # SpaceObj

The C<SpaceObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Space> object. The
C<assert_SpaceObj> function can be used to throw an exception if the argument
can not be validated. The C<is_SpaceObj> function can be used to return true or
false if the argument can not be validated.

+=head2 spaceobject

  # SpaceObject

The C<SpaceObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Space> object. The
C<assert_SpaceObject> function can be used to throw an exception if the
argument can not be validated. The C<is_SpaceObject> function can be used to
return true or false if the argument can not be validated.

+=head2 stateobj

  # StateObj

The C<StateObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::State> object. The
C<assert_StateObj> function can be used to throw an exception if the argument
can not be validated. The C<is_StateObj> function can be used to return true or
false if the argument can not be validated.

+=head2 stateobject

  # StateObject

The C<StateObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::State> object. The
C<assert_StateObject> function can be used to throw an exception if the
argument can not be validated. The C<is_StateObject> function can be used to
return true or false if the argument can not be validated.

+=head2 str

  # Str

The C<Str> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Str> function can be
used to throw an exception if the argument can not be validated. The C<is_Str>
function can be used to return true or false if the argument can not be
validated.

+=head2 strmatch

  # StrMatch[qr/^[A-Z]+$/]

The C<StrMatch> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_StrMatch>
function can be used to throw an exception if the argument can not be
validated. The C<is_StrMatch> function can be used to return true or false if the
argument can not be validated.

+=head2 strobj

  # StrObj

The C<StrObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StrObj> function can be used to throw an exception if the argument can
not be validated. The C<is_StrObj> function can be used to return true or false if
the argument can not be validated.

+=head2 strobject

  # StrObject

The C<StrObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StrObject> function can be used to throw an exception if the argument can
not be validated. The C<is_StrObject> function can be used to return true or false
if the argument can not be validated.

+=head2 strictnum

  # StrictNum

The C<StrictNum> type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_StrictNum>
function can be used to throw an exception if the argument can not be
validated. The C<is_StrictNum> function can be used to return true or false if the
argument can not be validated.

+=head2 stringlike

  # StringLike

The C<StringLike> type constraint is provided by the L<Types::TypeTiny> library.
Please see that documentation for more information. The C<assert_StringLike>
function can be used to throw an exception if the argument can not be
validated. The C<is_StringLike> function can be used to return true or false if
the argument can not be validated.

+=head2 stringobj

  # StringObj

The C<StringObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StringObj> function can be used to throw an exception if the argument can
not be validated. The C<is_StringObj> function can be used to return true or false
if the argument can not be validated.

+=head2 stringobject

  # StringObject

The C<StringObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StringObject> function can be used to throw an exception if the argument
can not be validated. The C<is_StringObject> function can be used to return true
or false if the argument can not be validated.

+=head2 strongpassword

  # StrongPassword

The C<StrongPassword> type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_StrongPassword> function can be used to throw an exception if the
argument can not be validated. The C<is_StrongPassword> function can be used to
return true or false if the argument can not be validated.

+=head2 structobj

  # StructObj

The C<StructObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Struct> object. The
C<assert_StructObj> function can be used to throw an exception if the argument
can not be validated. The C<is_StructObj> function can be used to return true
  or false if the argument can not be validated.

+=head2 structobject

  # StructObject

The C<StructObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Struct> object. The
C<assert_StructObject> function can be used to throw an exception if the
argument can not be validated. The C<is_StructObject> function can be used to
return true or false if the argument can not be validated.

+=head2 tied

  # Tied["MyClass"]

The C<Tied> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Tied> function can be
used to throw an exception if the argument can not be validated. The C<is_Tied>
function can be used to return true or false if the argument can not be
validated.

+=head2 tuple

  # Tuple[Int, Str, Str]

The C<Tuple> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Tuple> function can be
used to throw an exception if the argument can not be validated. The C<is_Tuple>
function can be used to return true or false if the argument can not be
validated.

+=head2 typetiny

  # TypeTiny

The C<TypeTiny> type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_TypeTiny> function can be
used to throw an exception if the argument can not be validated. The C<is_TypeTiny>
function can be used to return true or false if the argument can not be
validated.

+=head2 undef

  # Undef

The C<Undef> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Undef> function can be
used to throw an exception if the argument can not be validated. The C<is_Undef>
function can be used to return true or false if the argument can not be
validated.

+=head2 undefobj

  # UndefObj

The C<UndefObj> type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Undef> object. The
C<assert_UndefObj> function can be used to throw an exception if the argument can
not be validated. The C<is_UndefObj> function can be used to return true or false
if the argument can not be validated.

+=head2 undefobject

  # UndefObject

The C<UndefObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Undef> object. The
C<assert_UndefObject> function can be used to throw an exception if the argument
can not be validated. The C<is_UndefObject> function can be used to return true or
false if the argument can not be validated.

+=head2 uppercasesimplestr

  # UpperCaseSimpleStr

The C<UpperCaseSimpleStr> type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_UpperCaseSimpleStr> function can be used to throw an exception if the
argument can not be validated. The C<is_UpperCaseSimpleStr> function can be used
to return true or false if the argument can not be validated.
information.

+=head2 uppercasestr

  # UpperCaseStr

The C<UpperCaseStr> type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_UpperCaseStr> function can be used to throw an exception if the
argument can not be validated. The C<is_UpperCaseStr> function can be used to
return true or false if the argument can not be validated.

+=head2 value

  # Value

The C<Value> type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Value> function can be
used to throw an exception if the argument can not be validated. The C<is_Value>
function can be used to return true or false if the argument can not be
validated.

+=head2 varsobj

  # VarsObj

The C<VarsObj> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Vars> object. The
C<assert_VarsObj> function can be used to throw an exception if the argument
can not be validated. The C<is_VarsObj> function can be used to return true or
false if the argument can not be validated.

+=head2 varsobject

  # VarsObject

The C<VarsObject> type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Vars> object. The
C<assert_VarsObject> function can be used to throw an exception if the argument
can not be validated. The C<is_VarsObject> function can be used to return true
  or false if the argument can not be validated.

=cut

# TESTING

use_ok 'Data::Object::Library';

ok 1 and done_testing;
