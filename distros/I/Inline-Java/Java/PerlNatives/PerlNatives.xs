#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/*
#include "stdlib.h"
#include "string.h"
#include "stdio.h"
#include "stdarg.h"
*/

#ifdef __CYGWIN__
	#include "w32api/basetyps.h"
#endif

/* Include the JNI header file */
#include "jni.h"


void throw_ije(JNIEnv *env, char *msg){
	jclass ije ;

	ije = (*(env))->FindClass(env, "org/perl/inline/java/InlineJavaException") ;
	if ((*(env))->ExceptionCheck(env)){
		(*(env))->ExceptionDescribe(env) ;
		(*(env))->ExceptionClear(env) ;
		(*(env))->FatalError(env, "Can't find class InlineJavaException: exiting...") ;
	}
	(*(env))->ThrowNew(env, ije, msg) ;
}


/*
	Here we simply check if an exception is pending an re-throw it
*/
int check_exception_from_java(JNIEnv *env){
	jthrowable exc ;
	int ret = 0 ;

	exc = (*(env))->ExceptionOccurred(env) ;
	if (exc != NULL){
		/* (*(env))->ExceptionDescribe(env) ; */
		(*(env))->ExceptionClear(env) ;
		if ((*(env))->Throw(env, exc)){
			(*(env))->FatalError(env, "Throw of InlineJava*Exception failed: exiting...") ;
		}
		ret = 1 ;
	}

	return ret ;
}


jobject create_primitive_object(JNIEnv *env, char f, char *cls_name, jvalue val){
	jclass arg_cls ;
	jmethodID mid ;
	jobject ret = NULL ;
	char sign[64] ;

	arg_cls = (*(env))->FindClass(env, cls_name) ;
	if (check_exception_from_java(env)){
		return NULL ;
	}
	sprintf(sign, "(%c)V", f) ;
	mid = (*(env))->GetMethodID(env, arg_cls, "<init>", sign) ;
	if (check_exception_from_java(env)){
		return NULL ;
	}
	ret = (*(env))->NewObjectA(env, arg_cls, mid, &val) ;
	if (check_exception_from_java(env)){
		return NULL ;
	}

	return ret ;
}


jobject extract_va_arg(JNIEnv *env, va_list *list, char f){
	jobject ret = NULL ;
	jvalue val ;

	/*
		A bit of voodoo going on for J and F, but the rest I think is pretty
		kosher (on a 32 bit machine at least...)
	*/
	switch(f){
		case 'B':
			val.b = (jbyte)va_arg(*list, int) ;
			ret = create_primitive_object(env, f, "java/lang/Byte", val) ;
			break ;
		case 'S':
			val.s = (jshort)va_arg(*list, int) ;
			ret = create_primitive_object(env, f, "java/lang/Short", val) ;
			break ;
		case 'I':
			val.i = (jint)va_arg(*list, int) ;
			ret = create_primitive_object(env, f, "java/lang/Integer", val) ;
			break ;
		case 'J':
			val.d = (jdouble)va_arg(*list, double) ;
			ret = create_primitive_object(env, f, "java/lang/Long", val) ;
			break ;
		case 'F':
			/* Seems float is not properly promoted to double... */
			val.i = (jint)va_arg(*list, int) ;
			ret = create_primitive_object(env, f, "java/lang/Float", val) ;
			break ;
		case 'D':
			val.d = (jdouble)va_arg(*list, double) ;
			ret = create_primitive_object(env, f, "java/lang/Double", val) ;
			break ;
		case 'Z':
			val.z = (jboolean)va_arg(*list, int) ;
			ret = create_primitive_object(env, f, "java/lang/Boolean", val) ;
			break ;
		case 'C':
			val.c = (jchar)va_arg(*list, int) ;
			ret = create_primitive_object(env, f, "java/lang/Character", val) ;
			break ;
	}

	return ret ;
}


/*
	This is the generic native function that callback java to call the proper
	perl method.
*/
jobject JNICALL generic_perl_native(JNIEnv *env, jobject obj, ...){
	va_list list ;
	jclass cls ;
	jmethodID mid ;
	jstring jfmt ;
	char *fmt ;
	int fmt_len ;
	jclass obj_cls ;
	jobjectArray obj_array ;
	jobject arg ;
	int i ;
	jobject ret = NULL ;

	cls = (*(env))->GetObjectClass(env, obj) ;
	mid = (*(env))->GetMethodID(env, cls, "LookupMethod", "()Ljava/lang/String;") ;
	if (check_exception_from_java(env)){
		return NULL ;
	}

	/* Call obj.LookupMethod to get the format string */
	jfmt = (*(env))->CallObjectMethod(env, obj, mid) ;
	if (check_exception_from_java(env)){
		return NULL ;
	}

	fmt = (char *)((*(env))->GetStringUTFChars(env, jfmt, NULL)) ;
	fmt_len = strlen(fmt) ;

	obj_cls = (*(env))->FindClass(env, "java/lang/Object") ;
	if (check_exception_from_java(env)){
		return NULL ;
	}

	obj_array = (*(env))->NewObjectArray(env, fmt_len, obj_cls, NULL) ;
	if (check_exception_from_java(env)){
		return NULL ;
	}

	(*(env))->SetObjectArrayElement(env, obj_array, 0, obj) ;
	if (check_exception_from_java(env)){
		return NULL ;
	}
	va_start(list, obj) ;
	for (i = 1 ; i < fmt_len ; i++){
		if (fmt[i] != 'L'){
			arg = extract_va_arg(env, &list, fmt[i]) ;
			if (arg == NULL){
				return NULL ;
			}
		}
		else{
			arg = (jobject)va_arg(list, jobject) ;
		}
		(*(env))->SetObjectArrayElement(env, obj_array, i, arg) ;
		if (check_exception_from_java(env)){
			return NULL ;
		}
	}
	va_end(list) ;

	/* Call obj.InvokePerlMethod and grab the returned object and return it */
	mid = (*(env))->GetMethodID(env, cls, "InvokePerlMethod", "([Ljava/lang/Object;)Ljava/lang/Object;") ;
	if (check_exception_from_java(env)){
		return NULL ;
	}

	ret = (*(env))->CallObjectMethod(env, obj, mid, obj_array) ;
	if (check_exception_from_java(env)){
		return NULL ;
	}

	return ret ;
}


/*
	This function is used to register the specified native method and associate it with our magic
	method that trap and redirects all the Perl native calls.
*/
JNIEXPORT void JNICALL Java_org_perl_inline_java_InlineJavaPerlNatives_RegisterMethod(JNIEnv *env, jobject obj, jclass cls, jstring name, jstring signature){
	JNINativeMethod nm ;

	/* Register the function */
	nm.name = (char *)((*(env))->GetStringUTFChars(env, name, NULL)) ;
	nm.signature = (char *)((*(env))->GetStringUTFChars(env, signature, NULL)) ;
	nm.fnPtr = generic_perl_native ;

	(*(env))->RegisterNatives(env, cls, &nm, 1) ;
	(*(env))->ReleaseStringUTFChars(env, name, nm.name) ;
	(*(env))->ReleaseStringUTFChars(env, signature, nm.signature) ;
	if (check_exception_from_java(env)){
		return ;
	}
}
