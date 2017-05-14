%module "Java::Wrapper"

%{
#include <ObjectWrapper.h>
#include <ArrayWrapper.h>
#include <ArgumentArray.h>
//#include <gcj/cni.h>
//#include <iostream>
//using namespace std;
%}

%typemap(in) jstring {
        if ( SvPOK($input) ) {
                char *perl_str = SvPV($input, PL_na);
                $1 = JvNewStringLatin1(perl_str);
        } else {
                croak("Invalid input type, expecting string");
        }
}

%typemap(out) jstring {
        EXTEND(sp, 1);
        $result = sv_newmortal();

        jint len = JvGetStringUTFLength($1);
        if ( len == 0 ) {
                sv_setpv($result, "");
        } else {
                char *buffer = new char[len + 1];
                JvGetStringUTFRegion($1, 0, len, buffer);
                buffer[(int) len] = '\0';
                sv_setpv($result, buffer);
                SvUTF8_on($result);
                delete buffer;
        }
        argvi++;
}

%typemap(in) jboolean {
	jboolean jbool = SvTRUE($input) ? true : false;
	$1 = jbool;
}

%typemap(out) jboolean {
	EXTEND(sp, 1);
        $result = $1 ? &PL_sv_yes : &PL_sv_no;
	argvi++;
}

%typemap(in) jint {
        int cpp_int = 0;
        if ( SvIOK($input) ) {
                cpp_int = SvIV($input);
        } else {
                croak("Cannot convert argument to type jint");
        }
        jint real_val(cpp_int);
        $1 = real_val;
}

%typemap(out) jint {
	EXTEND(sp, 1);
	$result = newSViv((int) $1);
	argvi++;
}

%typemap(in) jshort {
	short int cpp_short = 0;
	if ( SvIOK($input) ) {
		cpp_short = SvIV($input);
	} else {
		croak("Cannot convert argument to type short");
	}
	jshort real_val(cpp_short);
	$1 = real_val;
}

%typemap(in) jlong {
	long int cpp_long = 0;
	if ( SvIOK($input) ) {
		cpp_long = SvIV($input);
	} else {
		croak("Cannot convert argument to type long");
	}
	jlong real_val(cpp_long);
	$1 = real_val;
}

%typemap(in) jfloat {
	float cpp_float = 0;
	if ( SvNOK($input) ) {
		cpp_float = SvNV($input);
	} else {
		croak("Cannot convert argument to type float");
	}
	jfloat real_val(cpp_float);
	$1 = real_val;
}

%typemap(in) jdouble {
	double cpp_double = 0;
	if ( SvNOK($input) ) {
		cpp_double = SvNV($input);
	} else {
		croak("Cannot convert argument to type double");
	}
	jdouble real_val(cpp_double);
	$1 = real_val;
}

%typemap(in) jbyte {
	jbyteArray myBytes = NULL;
        if ( SvPOK($input) ) {
                char *perl_str = SvPV($input, PL_na);
                jstring myStr = JvNewStringLatin1(perl_str);
		myBytes = myStr->getBytes();
        } else {
                croak("Invalid input type, expecting string");
        }
	jbyte *bytes = elements(myBytes);
	$1 = bytes[0];
}

%typemap(in) jchar {
	jstring myStr = NULL;
        if ( SvPOK($input) ) {
                char *perl_str = SvPV($input, PL_na);
                myStr = JvNewStringLatin1(perl_str);
        } else {
                croak("Invalid input type, expecting string");
        }
	$1 = myStr->charAt(0);
}

class ArgumentArray
{
public:
  ArgumentArray (jint);
  virtual void addElement (::ObjectWrapper *);
  virtual jint getSize ();
};

class ObjectWrapper
{
public:
  ObjectWrapper ();
  virtual jboolean perl_isa (jstring);
  virtual jboolean can (jstring);
  virtual jstring toString ();
  virtual jboolean isArray ();
  virtual ::ObjectWrapper *invokeMethod (jstring, ::ArgumentArray *);
  virtual ::ObjectWrapper *getLastThrownException ();
  virtual ::ObjectWrapper *getField (jstring);
  virtual void setField (jstring, ::ObjectWrapper *);
  static ::ObjectWrapper *getLastStaticThrownException ();
  static ::ObjectWrapper *newClassInstance (jstring, ::ArgumentArray *);
  static ::ObjectWrapper *invokeStaticMethod (jstring, jstring, ::ArgumentArray *);
  static ::ArrayWrapper *newJavaArray (jstring, jint);
  static ::ObjectWrapper *wrapInt (jint);
  static ::ObjectWrapper *wrapString (jstring);
  static ::ObjectWrapper *wrapBoolean (jboolean);
  static ::ObjectWrapper *wrapShort (jshort);
  static ::ObjectWrapper *wrapLong (jlong);
  static ::ObjectWrapper *wrapFloat (jfloat);
  static ::ObjectWrapper *wrapDouble (jdouble);
  static ::ObjectWrapper *wrapByte (jbyte);
  static ::ObjectWrapper *wrapChar (jchar);
};

class ArrayWrapper : public ::ObjectWrapper
{
public:
  ArrayWrapper (jstring, jint);
  virtual jint getSize ();
  virtual void set (::ObjectWrapper *, jint);
  virtual ::ObjectWrapper *get (jint);
  virtual jstring toString ();
  static ::ArrayWrapper *getObjectAsArray (::ObjectWrapper *);
};
