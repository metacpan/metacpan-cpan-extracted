%module "GCJ::Cni"

%{
#include <java/lang/Thread.h>
#include <java/lang/ThreadGroup.h>
%}

%typemap(in) jstring {
	//convert perl string to jstring using JvNewStringLatin1
	if ( SvROK($input) ) {
		//if this is a refference to an object
		$1 = (jstring) $input;
	} else if ( SvPOK($input) ) {
		//if this is a Perl String
		$1 = JvNewStringLatin1(SvPV($input, PL_na));
	} else {
		//I dont know what this is... how do I reflect that?
	}
}

%typemap(in) JvVMInitArgs {
	//Take in a perl hash and convert it to propper structs
}

typedef int jint;
typedef int jsize;
//typedef char jchar;

jint JvCreateJavaVM (JvVMInitArgs* vm_args);
jstring JvNewStringLatin1 (const char *bytes);
jstring JvNewStringLatin1 (const char *bytes, jsize len);
jstring JvAllocString (jsize sz);
jstring JvNewString (const jchar *chars, jsize len);
//jchar* JvGetStringChars (jstring str);
//jsize JvGetStringUTFLength (jstring string);
//jsize JvGetStringUTFRegion (jstring str, jsize start, jsize len, char *buf);
jstring JvNewStringUTF (const char *bytes);
java::lang::Thread* JvAttachCurrentThread (jstring name, java::lang::ThreadGroup* group);
java::lang::Thread* JvAttachCurrentThreadAsDaemon (jstring name, java::lang::ThreadGroup* group);
jint JvDetachCurrentThread (void);
