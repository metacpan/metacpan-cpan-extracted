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

=description

This package provides a type library derived from L<Type::Library> which
extends the L<Types::Standard>, L<Types::Common::Numeric>, and
L<Types::Common::String> libraries, and adds additional type constraints.

+=head1 TYPES

This package can export the following type constraints.

+=head2 Any

  # Any

The Any type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Any> function can be
used to throw an exception is the argument can not be validated. The C<is_Any>
function can be used to return true or false if the argument can not be
validated.

+=head2 AnyObj

  # AnyObj

The AnyObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Any> object. The
C<assert_AnyObj> function can be used to throw an exception if the argument can
not be validated. The C<is_AnyObj> function can be used to return true or false if
the argument can not be validated.

+=head2 AnyObject

  # AnyObject

The AnyObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Any> object. The
C<assert_AnyObject> function can be used to throw an exception if the argument can
not be validated. The C<is_AnyObject> function can be used to return true or false
if the argument can not be validated.

+=head2 ArrayLike

  # ArrayLike

The ArrayLike type constraint is provided by the L<Types::TypeTiny> library.
Please see that documentation for more information. The C<assert_ArrayLike>
function can be used to throw an exception if the argument can not be
validated. The C<is_ArrayLike> function can be used to return true or false if
the argument can not be validated.

+=head2 ArrayObj

  # ArrayObj

The ArrayObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Array> object. The
C<assert_ArrayObj> function can be used to throw an exception if the argument can
not be validated. The C<is_ArrayObj> function can be used to return true or false
if the argument can not be validated.

+=head2 ArrayObject

  # ArrayObject

The ArrayObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Array> object. The
C<assert_ArrayObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ArrayObject> function can be used to return true or
false if the argument can not be validated.

+=head2 ArrayRef

  # ArrayRef

The ArrayRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ArrayRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_ArrayRef> function can be used to return true or false if the
argument can not be validated.

+=head2 Bool

  # Bool

The Bool type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Bool> function can be
used to throw an exception if the argument can not be validated. The C<is_Bool>
function can be used to return true or false if the argument can not be
validated.

+=head2 ClassName

  # ClassName["MyClass"]

The ClassName type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ClassName>
function can be used to throw an exception if the argument can not be
validated. The C<is_ClassName> function can be used to return true or false if the
argument can not be validated.

+=head2 CodeLike

  # CodeLike

The CodeLike type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_CodeLike> function can be
used to throw an exception if the argument can not be validated. The C<is_CodeLike>
function can be used to return true or false if the argument can not be
validated.

+=head2 CodeObj

  # CodeObj

The CodeObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Code> object. The C<assert_CodeObj>
function can be used to throw an exception if the argument can not be
validated. The C<is_CodeObj> function can be used to return true or false if the
argument can not be validated.

+=head2 CodeObject

  # CodeObject

The CodeObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Code> object. The
C<assert_CodeObject> function can be used to throw an exception if the argument
can not be validated. The C<is_CodeObject> function can be used to return true or
false if the argument can not be validated.

+=head2 CodeRef

  # CodeRef

The CodeRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_CodeRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_CodeRef> function can be used to return true or false if the argument can not
be validated.

+=head2 ConsumerOf

  # ConsumerOf["MyRole"]

The ConsumerOf type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ConsumerOf>
function can be used to throw an exception if the argument can not be
validated. The C<is_ConsumerOf> function can be used to return true or false if
the argument can not be validated.

+=head2 DataObj

  # DataObj

The DataObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Data> object. The
C<assert_DataObj> function can be used to throw an exception if the argument
can not be validated. The C<is_DataObj> function can be used to return true or
false if the argument can not be validated.

+=head2 DataObject

  # DataObject

The DataObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Data> object. The
C<assert_DataObject> function can be used to throw an exception if the argument
can not be validated. The C<is_DataObject> function can be used to return true
or false if the argument can not be validated.

+=head2 Defined

  # Defined

The Defined type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Defined> function
can be used to throw an exception if the argument can not be validated. The
C<is_Defined> function can be used to return true or false if the argument can not
be validated.

+=head2 Dict

  # Dict

The Dict type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Dict> function can be
used to throw an exception if the argument can not be validated. The C<is_Dict>
function can be used to return true or false if the argument can not be
validated.

+=head2 Enum

  # Enum[qw(A B C)]

The Enum type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Enum> function can be
used to throw an exception if the argument can not be validated. The C<is_Enum>
function can be used to return true or false if the argument can not be
validated.

+=head2 ExceptionObj

  # ExceptionObj

The ExceptionObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Exception> object. The
C<assert_ExceptionObj> function can be used to throw an exception if the
argument can not be validated. The C<is_ExceptionObj> function can be used to
return true or false if the argument can not be validated.

+=head2 ExceptionObject

  # ExceptionObject

The ExceptionObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Exception> object. The
C<assert_ExceptionObject> function can be used to throw an exception if the
argument can not be validated. The C<is_ExceptionObject> function can be used
to return true or false if the argument can not be validated.

+=head2 FileHandle

  # FileHandle

The FileHandle type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_FileHandle>
function can be used to throw an exception if the argument can not be
validated. The C<is_FileHandle> function can be used to return true or false if
the argument can not be validated.

+=head2 FloatObj

  # FloatObj

The FloatObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Float> object. The
C<assert_FloatObj> function can be used to throw an exception if the argument can
not be validated. The C<is_FloatObj> function can be used to return true or false
if the argument can not be validated.

+=head2 FloatObject

  # FloatObject

The FloatObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Float> object. The
C<assert_FloatObject> function can be used to throw an exception if the argument
can not be validated. The C<is_FloatObject> function can be used to return true or
false if the argument can not be validated.

+=head2 FuncObj

  # FuncObj

The FuncObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Func> object. The
C<assert_FuncObj> function can be used to throw an exception if the argument
can not be validated. The C<is_FuncObj> function can be used to return true or
false if the argument can not be validated.

+=head2 FuncObject

  # FuncObject

The FuncObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Func> object. The
C<assert_FuncObject> function can be used to throw an exception if the argument
can not be validated. The C<is_FuncObject> function can be used to return true
or false if the argument can not be validated.

+=head2 GlobRef

  # GlobRef

The GlobRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_GlobRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_GlobRef> function can be used to return true or false if the argument can not
be validated.

+=head2 HasMethods

  # HasMethods["new"]

The HasMethods type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_HasMethods>
function can be used to throw an exception if the argument can not be
validated. The C<is_HasMethods> function can be used to return true or false if
the argument can not be validated.

+=head2 HashLike

  # HashLike

The HashLike type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_HashLike> function can be
used to throw an exception if the argument can not be validated. The C<is_HashLike>
function can be used to return true or false if the argument can not be
validated.

+=head2 HashObj

  # HashObj

The HashObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Hash> object. The C<assert_HashObj>
function can be used to throw an exception if the argument can not be
validated. The C<is_HashObj> function can be used to return true or false if the
argument can not be validated.

+=head2 HashObject

  # HashObject

The HashObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Hash> object. The
C<assert_HashObject> function can be used to throw an exception if the argument
can not be validated. The C<is_HashObject> function can be used to return true or
false if the argument can not be validated.

+=head2 HashRef

  # HashRef

The HashRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_HashRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_HashRef> function can be used to return true or false if the argument can not
be validated.

+=head2 InstanceOf

  # InstanceOf[MyClass]

The InstanceOf type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_InstanceOf>
function can be used to throw an exception if the argument can not be
validated. The C<is_InstanceOf> function can be used to return true or false if
the argument can not be validated.

+=head2 Int

  # Int

The Int type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Int> function can be
used to throw an exception if the argument can not be validated. The C<is_Int>
function can be used to return true or false if the argument can not be
validated.

+=head2 IntObj

  # IntObj

The IntObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntObj> function can be used to throw an exception if the argument can
not be validated. The C<is_IntObj> function can be used to return true or false if
the argument can not be validated.

+=head2 IntObject

  # IntObject

The IntObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntObject> function can be used to throw an exception if the argument can
not be validated. The C<is_IntObject> function can be used to return true or false
if the argument can not be validated.

+=head2 IntRange

  # IntRange[0, 25]

The IntRange type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_IntRange> function can be
used to throw an exception if the argument can not be validated. The C<is_IntRange>
function can be used to return true or false if the argument can not be
validated.

+=head2 IntegerObj

  # IntegerObj

The IntegerObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntegerObj> function can be used to throw an exception if the argument
can not be validated. The C<is_IntegerObj> function can be used to return true or
false if the argument can not be validated.

+=head2 IntegerObject

  # IntegerObject

The IntegerObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntegerObject> function can be used to throw an exception if the argument
can not be validated. The C<is_IntegerObject> function can be used to return true
or false if the argument can not be validated.

+=head2 Item

  # Item

The Item type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Item> function can be
used to throw an exception if the argument can not be validated. The C<is_Item>
function can be used to return true or false if the argument can not be
validated.

+=head2 LaxNum

  # LaxNum

The LaxNum type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_LaxNum> function
can be used to throw an exception if the argument can not be validated. The
C<is_LaxNum> function can be used to return true or false if the argument can not
be validated.

+=head2 LowerCaseSimpleStr

  # LowerCaseSimpleStr

The LowerCaseSimpleStr type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_LowerCaseSimpleStr> function can be used to throw an exception if the
argument can not be validated. The C<is_LowerCaseSimpleStr> function can be used
to return true or false if the argument can not be validated.
information.

+=head2 LowerCaseStr

  # LowerCaseStr

The LowerCaseStr type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The C<assert_type>
function can be used to throw an exception if the argument can not be
validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.

+=head2 Map

  # Map[Int, HashRef]

The Map type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Map> function can be
used to throw an exception if the argument can not be validated. The C<is_Map>
function can be used to return true or false if the argument can not be
validated.

+=head2 Maybe

  # Maybe[Object]

The Maybe type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Maybe> function can be
used to throw an exception if the argument can not be validated. The C<is_Maybe>
function can be used to return true or false if the argument can not be
validated.

+=head2 NegativeInt

  # NegativeInt

The NegativeInt type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_NegativeInt> function can be used to throw an exception if the argument
can not be validated. The C<is_NegativeInt> function can be used to return true or
false if the argument can not be validated.

+=head2 NegativeNum

  # NegativeNum

The NegativeNum type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_NegativeNum> function can be used to throw an exception if the argument
can not be validated. The C<is_NegativeNum> function can be used to return true or
false if the argument can not be validated.

+=head2 NegativeOrZeroInt

  # NegativeOrZeroInt

The NegativeOrZeroInt type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_NegativeOrZeroInt> function can be used to throw an exception if the
argument can not be validated. The C<is_NegativeOrZeroInt> function can be used to
return true or false if the argument can not be validated.
information.

+=head2 NegativeOrZeroNum

  # NegativeOrZeroNum

The NegativeOrZeroNum type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

+=head2 NonEmptySimpleStr

  # NonEmptySimpleStr

The NonEmptySimpleStr type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

+=head2 NonEmptyStr

  # NonEmptyStr

The NonEmptyStr type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_type> function
can be used to throw an exception if the argument can not be validated. The
C<is_type> function can be used to return true or false if the argument can not be
validated.

+=head2 Num

  # Num

The Num type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Num> function can be
used to throw an exception if the argument can not be validated. The C<is_Num>
function can be used to return true or false if the argument can not be
validated.

+=head2 NumObj

  # NumObj

The NumObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumObj> function can be used to throw an exception if the argument can
not be validated. The C<is_NumObj> function can be used to return true or false if
the argument can not be validated.

+=head2 NumObject

  # NumObject

The NumObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumObject> function can be used to throw an exception if the argument can
not be validated. The C<is_NumObject> function can be used to return true or false
if the argument can not be validated.

+=head2 NumRange

  # NumRange[0, 25]

The NumRange type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_NumRange> function can be
used to throw an exception if the argument can not be validated. The C<is_NumRange>
function can be used to return true or false if the argument can not be
validated.

+=head2 NumberObject

  # NumberObject

The NumberObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumberObject> function can be used to throw an exception if the argument
can not be validated. The C<is_NumberObject> function can be used to return true
or false if the argument can not be validated.

+=head2 NumericCode

  # NumericCode

The NumericCode type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_NumericCode> function can be used to throw an exception if the argument
can not be validated. The C<is_NumericCode> function can be used to return true or
false if the argument can not be validated.

+=head2 Object

  # Object

The Object type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Object> function
can be used to throw an exception if the argument can not be validated. The
C<is_Object> function can be used to return true or false if the argument can not
be validated.

+=head2 OptList

  # OptList

The OptList type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_OptList> function
can be used to throw an exception if the argument can not be validated. The
C<is_OptList> function can be used to return true or false if the argument can not
be validated.

+=head2 Optional

  # Dict[id => Optional[Int]]

The Optional type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Optional>
function can be used to throw an exception if the argument can not be
validated. The C<is_Optional> function can be used to return true or false if the
argument can not be validated.

+=head2 Overload

  # Overload[qw("")]

The Overload type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Overload>
function can be used to throw an exception if the argument can not be
validated. The C<is_Overload> function can be used to return true or false if the
argument can not be validated.

+=head2 Password

  # Password

The Password type constraint is provided by the L<Types::Common::String>
library.  Please see that documentation for more information. The
C<assert_Password> function can be used to throw an exception if the argument
can not be validated. The C<is_Password> function can be used to return true or
false if the argument can not be validated.

+=head2 PositiveInt

  # PositiveInt

The PositiveInt type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_PositiveInt> function can be used to throw an exception if the argument
can not be validated. The C<is_PositiveInt> function can be used to return true or
false if the argument can not be validated.

+=head2 PositiveNum

  # PositiveNum

The PositiveNum type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_PositiveNum> function can be used to throw an exception if the argument
can not be validated. The C<is_PositiveNum> function can be used to return true or
false if the argument can not be validated.

+=head2 PositiveOrZeroInt

  # PositiveOrZeroInt

The PositiveOrZeroInt type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_PositiveOrZeroInt> function can be used to throw an exception if the
argument can not be validated. The C<is_PositiveOrZeroInt> function can be used to
return true or false if the argument can not be validated.
information.

+=head2 PositiveOrZeroNum

  # PositiveOrZeroNum

The PositiveOrZeroNum type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

+=head2 Ref

  # Ref["SCALAR"]

The Ref type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_type> function can be
used to throw an exception if the argument can not be validated. The C<is_type>
function can be used to return true or false if the argument can not be
validated.

+=head2 RegexpObj

  # RegexpObj

The RegexpObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Regexp> object. The
C<assert_RegexpObj> function can be used to throw an exception if the argument can
not be validated. The C<is_RegexpObj> function can be used to return true or false
if the argument can not be validated.

+=head2 RegexpObject

  # RegexpObject

The RegexpObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Regexp> object. The
C<assert_RegexpObject> function can be used to throw an exception if the argument
can not be validated. The C<is_RegexpObject> function can be used to return true
or false if the argument can not be validated.

+=head2 RegexpRef

  # RegexpRef

The RegexpRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_RegexpRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_RegexpRef> function can be used to return true or false if the
argument can not be validated.

+=head2 ReplaceObj

  # ReplaceObj

The ReplaceObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Replace> object. The
C<assert_ReplaceObj> function can be used to throw an exception if the argument
can not be validated. The C<is_ReplaceObj> function can be used to return true
or false if the argument can not be validated.

+=head2 ReplaceObject

  # ReplaceObject

The ReplaceObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Replace> object. The
C<assert_ReplaceObject> function can be used to throw an exception if the
argument can not be validated. The C<is_ReplaceObject> function can be used to
return true or false if the argument can not be validated.

+=head2 RoleName

  # RoleName

The RoleName type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_RoleName>
function can be used to throw an exception if the argument can not be
validated. The C<is_RoleName> function can be used to return true or false if the
argument can not be validated.

+=head2 ScalarObj

  # ScalarObj

The ScalarObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Scalar> object. The
C<assert_ScalarObj> function can be used to throw an exception if the argument can
not be validated. The C<is_ScalarObj> function can be used to return true or false
if the argument can not be validated.

+=head2 ScalarObject

  # ScalarObject

The ScalarObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Scalar> object. The
C<assert_ScalarObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ScalarObject> function can be used to return true
or false if the argument can not be validated.

+=head2 ScalarRef

  # ScalarRef

The ScalarRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ScalarRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_ScalarRef> function can be used to return true or false if the
argument can not be validated.

+=head2 SearchObj

  # SearchObj

The SearchObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Search> object. The
C<assert_SearchObj> function can be used to throw an exception if the argument
can not be validated. The C<is_SearchObj> function can be used to return true
or false if the argument can not be validated.

+=head2 SearchObject

  # SearchObject

The SearchObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Search> object. The
C<assert_SearchObject> function can be used to throw an exception if the
argument can not be validated. The C<is_SearchObject> function can be used to
return true or false if the argument can not be validated.

+=head2 SimpleStr

  # SimpleStr

The SimpleStr type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_SimpleStr> function can be used to throw an exception if the argument can
not be validated. The C<is_SimpleStr> function can be used to return true or false
if the argument can not be validated.

+=head2 SingleDigit

  # SingleDigit

The SingleDigit type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_SingleDigit> function can be used to throw an exception if the argument
can not be validated. The C<is_SingleDigit> function can be used to return true or
false if the argument can not be validated.

+=head2 SpaceObj

  # SpaceObj

The SpaceObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Space> object. The
C<assert_SpaceObj> function can be used to throw an exception if the argument
can not be validated. The C<is_SpaceObj> function can be used to return true or
false if the argument can not be validated.

+=head2 SpaceObject

  # SpaceObject

The SpaceObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Space> object. The
C<assert_SpaceObject> function can be used to throw an exception if the
argument can not be validated. The C<is_SpaceObject> function can be used to
return true or false if the argument can not be validated.

+=head2 Str

  # Str

The Str type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Str> function can be
used to throw an exception if the argument can not be validated. The C<is_Str>
function can be used to return true or false if the argument can not be
validated.

+=head2 StrMatch

  # StrMatch[qr/^[A-Z]+$/]

The StrMatch type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_StrMatch>
function can be used to throw an exception if the argument can not be
validated. The C<is_StrMatch> function can be used to return true or false if the
argument can not be validated.

+=head2 StrObj

  # StrObj

The StrObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StrObj> function can be used to throw an exception if the argument can
not be validated. The C<is_StrObj> function can be used to return true or false if
the argument can not be validated.

+=head2 StrObject

  # StrObject

The StrObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StrObject> function can be used to throw an exception if the argument can
not be validated. The C<is_StrObject> function can be used to return true or false
if the argument can not be validated.

+=head2 StrictNum

  # StrictNum

The StrictNum type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_StrictNum>
function can be used to throw an exception if the argument can not be
validated. The C<is_StrictNum> function can be used to return true or false if the
argument can not be validated.

+=head2 StringLike

  # StringLike

The StringLike type constraint is provided by the L<Types::TypeTiny> library.
Please see that documentation for more information. The C<assert_StringLike>
function can be used to throw an exception if the argument can not be
validated. The C<is_StringLike> function can be used to return true or false if
the argument can not be validated.

+=head2 StringObj

  # StringObj

The StringObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StringObj> function can be used to throw an exception if the argument can
not be validated. The C<is_StringObj> function can be used to return true or false
if the argument can not be validated.

+=head2 StringObject

  # StringObject

The StringObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StringObject> function can be used to throw an exception if the argument
can not be validated. The C<is_StringObject> function can be used to return true
or false if the argument can not be validated.

+=head2 StrongPassword

  # StrongPassword

The StrongPassword type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_StrongPassword> function can be used to throw an exception if the
argument can not be validated. The C<is_StrongPassword> function can be used to
return true or false if the argument can not be validated.

+=head2 Tied

  # Tied["MyClass"]

The Tied type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Tied> function can be
used to throw an exception if the argument can not be validated. The C<is_Tied>
function can be used to return true or false if the argument can not be
validated.

+=head2 Tuple

  # Tuple[Int, Str, Str]

The Tuple type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Tuple> function can be
used to throw an exception if the argument can not be validated. The C<is_Tuple>
function can be used to return true or false if the argument can not be
validated.

+=head2 TypeTiny

  # TypeTiny

The TypeTiny type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_TypeTiny> function can be
used to throw an exception if the argument can not be validated. The C<is_TypeTiny>
function can be used to return true or false if the argument can not be
validated.

+=head2 Undef

  # Undef

The Undef type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Undef> function can be
used to throw an exception if the argument can not be validated. The C<is_Undef>
function can be used to return true or false if the argument can not be
validated.

+=head2 UndefObj

  # UndefObj

The UndefObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Undef> object. The
C<assert_UndefObj> function can be used to throw an exception if the argument can
not be validated. The C<is_UndefObj> function can be used to return true or false
if the argument can not be validated.

+=head2 UndefObject

  # UndefObject

The UndefObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Undef> object. The
C<assert_UndefObject> function can be used to throw an exception if the argument
can not be validated. The C<is_UndefObject> function can be used to return true or
false if the argument can not be validated.

+=head2 UpperCaseSimpleStr

  # UpperCaseSimpleStr

The UpperCaseSimpleStr type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_UpperCaseSimpleStr> function can be used to throw an exception if the
argument can not be validated. The C<is_UpperCaseSimpleStr> function can be used
to return true or false if the argument can not be validated.
information.

+=head2 UpperCaseStr

  # UpperCaseStr

The UpperCaseStr type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_UpperCaseStr> function can be used to throw an exception if the
argument can not be validated. The C<is_UpperCaseStr> function can be used to
return true or false if the argument can not be validated.

+=head2 Value

  # Value

The Value type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Value> function can be
used to throw an exception if the argument can not be validated. The C<is_Value>
function can be used to return true or false if the argument can not be
validated.

=cut

# TESTING

use_ok 'Data::Object::Library';

ok 1 and done_testing;
