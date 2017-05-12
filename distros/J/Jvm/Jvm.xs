/* -*- tab-width: 4; -*- 
 * Copyright (c) 2000 Ye, wei. 
 * All rights reserved.
 * This program is free software; you can redistribute it and/or 
 * modify it under the same terms as Perl itself.
 *
 * Ident = $Id: Jvm.xs,v 1.13 2001/09/08 06:57:09 yw Exp $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <jni.h>

typedef JNIEnv * Jvm;
typedef jvalue* _jvalueArray;

Jvm g_jvm = NULL;

JNIEnv* createJVM () {
    JNIEnv *env;
    JavaVM *jvm;
	JavaVMInitArgs vm_args;
    jint res;
    char classpath[2048];
	JavaVMOption options[3] = {{NULL,NULL},{NULL,NULL},{NULL,NULL}};

	SV 	*cp, *curr_cp, *lp, *curr_lp;
	char *cp_ptr, *lp_ptr;
	STRLEN cp_len, lp_len;

    /* IMPORTANT: specify vm_args version # if you use JDK1.1.2 and beyond */
    vm_args.version = JNI_VERSION_1_2;
    vm_args.ignoreUnrecognized = JNI_FALSE;
	/* if don't specify this option, gdb will core dump */
	options[0].optionString="-XX:+AllowUserSignalHandlers";

	/* Add our classpath set in $Jvm::CLASSPATH */
	cp = get_sv("Jvm::CLASSPATH", 0);
	if(cp != NULL) {
		curr_cp = newSVpv("-Djava.class.path=:", 0);
		sv_catsv(curr_cp, cp);
		cp_ptr = SvPV(curr_cp, cp_len);
		Newz(1, options[1].optionString, cp_len + 1, char);
		options[1].optionString = strcpy(options[1].optionString, cp_ptr);
	}


	/* Add our librarypath set in $Jvm::LIBPATH */
	lp = get_sv("Jvm::LIBPATH", 0);
	if(lp != NULL) {
		curr_lp = newSVpv("-Djava.library.path=:", 0);
		sv_catsv(curr_lp, lp);
		lp_ptr = SvPV(curr_lp, lp_len);
		Newz(1, options[2].optionString, lp_len + 1, char);
		options[2].optionString = strcpy(options[2].optionString, lp_ptr);
	}

	vm_args.options = options; 
    vm_args.nOptions = 3;

	JNI_GetDefaultJavaVMInitArgs(&vm_args);


    /* Create the Java VM */
	res = JNI_CreateJavaVM(&jvm,(void **)&env,(void **)&vm_args);
    if (res) {
        croak("Failed to create Java VM!");
    }

	return env;
}

/* when free ?? */
const char * str2utf (char * str) {
	const char * utf;
	jboolean isCopy = 1;
	jstring jstr = (*g_jvm)->NewStringUTF(g_jvm, str);
	utf = (*g_jvm)->GetStringUTFChars(g_jvm, jstr, &isCopy);
	return utf;
}

jobject arrayMalloc(char* sig, AV* av) {
	jobject ja  = NULL;
	int x;
	jsize len = av_len(av) + 1;
	SV **esv;
	if(sig[0]=='Z') {
		jboolean* buf = (jboolean *) safemalloc(len*sizeof(jboolean));
		for(esv = AvARRAY(av), x=0; x < len; esv++, x++) buf[x]=SvIV(*esv);
		ja = (*g_jvm)->NewBooleanArray(g_jvm, len);
		(*g_jvm)->SetBooleanArrayRegion(g_jvm, ja, 0, len, buf);	
		safefree((void*)buf);
	} else if(sig[0]=='B') {
		jbyte* buf = (jbyte *) safemalloc(len*sizeof(jbyte));
		for(esv =  AvARRAY(av), x=0; x < len; esv++, x++) buf[x]=SvIV(*esv);
		ja = (*g_jvm)->NewByteArray(g_jvm, len);
		(*g_jvm)->SetByteArrayRegion(g_jvm, ja, 0, len, buf);	
		safefree((void*)buf);
	} else if(sig[0]=='C') {
		jchar* buf = (jchar *) safemalloc(len*sizeof(jchar));
		for(esv =  AvARRAY(av), x=0; x < len; esv++, x++) buf[x]=(jchar)SvIV(*esv);
		ja = (*g_jvm)->NewCharArray(g_jvm, len);
		(*g_jvm)->SetCharArrayRegion(g_jvm, ja, 0, len, buf);	
		safefree((void*)buf);
	} else if(sig[0]=='S') {
		jshort* buf = (jshort *) safemalloc(len*sizeof(jshort));
		for(esv =  AvARRAY(av), x=0; x < len; esv++, x++) buf[x]=SvIV(*esv);
		ja = (*g_jvm)->NewShortArray(g_jvm, len);
		(*g_jvm)->SetShortArrayRegion(g_jvm, ja, 0, len, buf);	
		safefree((void*)buf);
	} else if(sig[0]=='I') {
		jint* buf = (jint *) safemalloc(len*sizeof(jint));
		for(esv =  AvARRAY(av), x=0; x < len; esv++, x++) buf[x]=SvIV(*esv);
		ja = (*g_jvm)->NewIntArray(g_jvm, len);
		(*g_jvm)->SetIntArrayRegion(g_jvm, ja, 0, len, buf);	
		safefree((void*)buf);
	} else if(sig[0]=='J') {
		jlong* buf = (jlong *) safemalloc(len*sizeof(jlong));
		for(esv =  AvARRAY(av), x=0; x < len; esv++, x++) buf[x]=SvNV(*esv);
		ja = (*g_jvm)->NewLongArray(g_jvm, len);
		(*g_jvm)->SetLongArrayRegion(g_jvm, ja, 0, len, buf);	
		safefree((void*)buf);
	} else if(sig[0]=='F') {
		jfloat* buf = (jfloat *) safemalloc(len*sizeof(jfloat));
		for(esv =  AvARRAY(av), x=0; x < len; esv++, x++) buf[x]=SvNV(*esv);
		ja = (*g_jvm)->NewFloatArray(g_jvm, len);
		(*g_jvm)->SetFloatArrayRegion(g_jvm, ja, 0, len, buf);	
		safefree((void*)buf);
	} else if(sig[0]=='D') {
		jdouble* buf = (jdouble *) safemalloc(len*sizeof(jdouble));
		for(esv =  AvARRAY(av), x=0; x < len; esv++, x++) buf[x]=SvNV(*esv);
		ja = (*g_jvm)->NewDoubleArray(g_jvm, len);
		(*g_jvm)->SetDoubleArrayRegion(g_jvm, ja, 0, len, buf);	
		safefree((void*)buf);
	} else if(sig[0]=='L') {
		char className[1024];
		jclass jcl;
		jobjectArray ja_ary;
		strncpy(className, sig+1, strlen(sig)-2); /* take out leading 'L' and trailing ';' */
		className[strlen(sig)-2]='\0';
		/*printf("Class:%s\n", className);*/
		jcl =(*g_jvm)->FindClass(g_jvm, className);
		/*printf("cls: %d\n", jcl);*/
		ja_ary = (*g_jvm)->NewObjectArray(g_jvm, len, jcl, 0);
		if(strcmp(sig, "Ljava/lang/String;")==0) {
			for(esv =  AvARRAY(av), x=0; x < len; esv++, x++) {
				jobject str = (jobject)(*g_jvm)->NewStringUTF(g_jvm, SvPV(*esv,PL_na));
				(*g_jvm)->SetObjectArrayElement(g_jvm, ja_ary, x, str);
			}
		} else {
			croak("ObjectArray haven't been implemented yet!");
		}
		ja=ja_ary;
	} else {
		croak("unkown sig '%s'!", sig);
	}
	
	return ja;
}


/*
 * The chars returned from jstring seems are UTF string.
 * So we convert them to char[].
 */

SV * getStr(jstring jstr) {
		int i;
		jboolean isCopy=0;
		SV * ret;
		const char * s = (const char*)(*g_jvm)->GetStringChars(g_jvm, jstr, &isCopy);
		int size = (*g_jvm)->GetStringLength(g_jvm, jstr);
		char *pStr=(char*)safemalloc(size+1);
		for(i=0; i<size; i++) {
			/* printf("getString() ret: %c\n", s[i*2]);*/
			pStr[i]=s[i*2];
		}
		pStr[size]='\0';
		
		ret = newSVpv(pStr, 0);
		safefree(pStr);
		return ret;
}

MODULE = Jvm		PACKAGE = Jvm		


int
_initJVM(CLASS="Jvm")
	char * CLASS

	CODE:
	if(g_jvm == NULL) { 
		/* printf("Create Jvm!\n"); */
		g_jvm=createJVM();
		RETVAL = g_jvm ? 0 : -1;
	} else 
		RETVAL = 0;

	OUTPUT:
		RETVAL

int
getVersion()

	CODE:
	RETVAL=(*g_jvm)->GetVersion(g_jvm);

	OUTPUT:
	RETVAL

jclass
findClass(classname)
	char * classname

	CODE:
	/* IMPORTANT: Change 'java.lang.String' to 'java/lang/String'! */
	int i=0;
	for(i=0; i< strlen(classname); i++) {
		if(classname[i]=='.') classname[i]='/';
	}

	/* printf("findClass(%s)\n", classname); */
	RETVAL= (*g_jvm)->FindClass(g_jvm,classname);

	OUTPUT:
	RETVAL

jstring
newStringUTF(str)
	char * str

	CODE:
	RETVAL= (*g_jvm)->NewStringUTF(g_jvm, str);
	
	OUTPUT:
	RETVAL

_jvalueArray
_createArgs(pSigs, pArgs)
	SV* pSigs
	SV* pArgs

	PREINIT:
	int count;
	AV * pAvSigs = NULL;
	AV * pAvArgs = NULL;
	int i;
	
	CODE:
	/* sv_dump(SvRV(pSigs)); */
	if(SvROK(pSigs)) pAvSigs = (AV*) SvRV(pSigs);
	else croak("Sigs is not a reference to an array!");
	if(SvROK(pArgs)) pAvArgs = (AV*) SvRV(pArgs);
	else croak("Args is not a reference to an array!");

	count = av_len(pAvSigs)+1;
	if(count != (av_len(pAvArgs)+1))
		croak("Args count does not match that of Sigs!\n");

	/* printf("AV count: %d\n", count); */

	if(count != 0) {

		RETVAL=(_jvalueArray)malloc(sizeof(jvalue)*(count+1));
		/* At first, I thought it need put the NULL at the end of entry to mark the END of array 
		 * In fact, it's not nessary, JVM can know the arguments count by method Signature.
	     */
		RETVAL[count].l=NULL;
		for(i=0; i< count; i++) {
			SV** sv_sig=av_fetch(pAvSigs, i, 0);
			SV** sv_arg=av_fetch(pAvArgs, i, 0);
			SV* sv=sv_arg[0];

			char *pSig = SvPV(sv_sig[0],PL_na);
			/* printf("%d:%s\n", i, pSig); */
			if(strcmp(pSig, "Z") == 0) {
				RETVAL[i].z=(jboolean)(SvIV(sv) != 0);
			} else if(strcmp(pSig, "B")==0) {
				RETVAL[i].b= (jbyte)SvIV(sv);
			} else if(strcmp(pSig, "C")==0) {
				RETVAL[i].c=(jchar)SvIV(sv);
			} else if(strcmp(pSig, "S")==0) {
				RETVAL[i].s=(jshort)SvIV(sv);
			} else if(strcmp(pSig, "I")==0) {
				RETVAL[i].i=(jint)SvIV(sv);
			} else if(strcmp(pSig, "J")==0) {
				RETVAL[i].j=(jlong)SvNV(sv);
			} else if(strcmp(pSig, "F")==0) {
				RETVAL[i].f=(jfloat)SvNV(sv);
			} else if(strcmp(pSig, "D")==0) {
				RETVAL[i].d=(jdouble)SvNV(sv);
			} else if(strcmp(pSig, "Ljava/lang/String;")==0) {
				jstring jstr = (*g_jvm)->NewStringUTF(g_jvm,  SvPV(sv,PL_na));
				RETVAL[i].l=jstr;
			} else if(pSig[0] == 'L') {
				SV* s= SvRV(sv);
				IV tmp = SvIV(s);
				jobject obj = (jobject) tmp;
				RETVAL[i].l=obj;

				/* sv_dump((SV*)(SvRV(sv_arg[0])));	 */
			} else if(pSig[0] == '[') {
				if(SvROK(sv)) {
					SV* rv = (SV*)SvRV(sv);
					if(SvOBJECT(rv))
						RETVAL[i].l=(jobject)SvIV(rv);
					else if(SvTYPE(rv) == SVt_PVAV) {
						jsize len = av_len((AV*)rv) + 1;
						jobject ja=arrayMalloc(pSig+1, (AV*) rv);
						RETVAL[i].l=(jobject)ja;
					} else 
						RETVAL[i].l=(jobject)(void*)0;
				} else {
					croak("it should be ref to ARRAY, but this var is unknown!");
				}
			} else croak("unkown sig!");
		}
	} else {
		RETVAL=(_jvalueArray)&PL_sv_undef;
	}

	OUTPUT:
	RETVAL



AV*
returnArray(sig, obj)
	char* sig
	jobject obj

	CODE:
	{
		AV* av = newAV();
		int i;
		int count=(*g_jvm)->GetArrayLength(g_jvm, obj);
		RETVAL=av;
		/* ignore the first '[' sig */
		if(sig[0] == '[') sig++;
		else croak("The return sig '%s' is not an array.", sig);

		if(sig[0] == 'Z') {	
			jboolean* buf=safemalloc(count*sizeof(jboolean));
			/* printf("Len:%d\n", count); */
			(*g_jvm)->GetBooleanArrayRegion(g_jvm, obj, 0, count, buf);
			for(i=0; i< count; i++) {
				av_push(av, newSViv(buf[i]));
			}
			safefree(buf);
		} else if(sig[0] == 'B') {
			jbyte* buf=safemalloc(count*sizeof(jbyte));
			(*g_jvm)->GetByteArrayRegion(g_jvm, obj, 0, count, buf);
			for(i=0; i< count; i++) {
				av_push(av, newSViv(buf[i]));
			}
			safefree(buf);
		} else if(sig[0] == 'C') {
			jchar* buf=safemalloc(count*sizeof(jchar));
			(*g_jvm)->GetCharArrayRegion(g_jvm, obj, 0, count, buf);
			for(i=0; i< count; i++) {
				av_push(av, newSViv(buf[i]));
			}
			safefree(buf);
		} else if(sig[0] == 'S') {
			jshort* buf=safemalloc(count*sizeof(jshort));
			(*g_jvm)->GetShortArrayRegion(g_jvm, obj, 0, count, buf);
			for(i=0; i< count; i++) {
				av_push(av, newSViv(buf[i]));
			}
			safefree(buf);
		} else if(sig[0] == 'I') {
			jint* buf=safemalloc(count*sizeof(jint));
			(*g_jvm)->GetIntArrayRegion(g_jvm, obj, 0, count, buf);
			for(i=0; i< count; i++) {
				av_push(av, newSViv(buf[i]));
			}
			safefree(buf);
		} else if(sig[0] == 'J') {
			jlong* buf=safemalloc(count*sizeof(jlong));
			(*g_jvm)->GetLongArrayRegion(g_jvm, obj, 0, count, buf);
			for(i=0; i< count; i++) {
				av_push(av, newSVnv(buf[i]));
			}
			safefree(buf);
		} else if(sig[0] == 'F') {
			jfloat* buf=safemalloc(count*sizeof(jfloat));
			(*g_jvm)->GetFloatArrayRegion(g_jvm, obj, 0, count, buf);
			for(i=0; i< count; i++) {
				av_push(av, newSVnv(buf[i]));
			}
			safefree(buf);
		} else if(sig[0] == 'D') {
			jdouble* buf=safemalloc(count*sizeof(jdouble));
			(*g_jvm)->GetDoubleArrayRegion(g_jvm, obj, 0, count, buf);
			for(i=0; i< count; i++) {
				av_push(av, newSVnv(buf[i]));
			}
			safefree(buf);
		} else if(strcmp(sig, "Ljava/lang/String;") == 0) {
			for(i=0; i<count; i++) {
				jstring jstr=(*g_jvm)->GetObjectArrayElement(g_jvm, obj, i);
				av_push(av, getStr(jstr));
			}
		} else {
			croak("unkown sig!");
		}
	}
	OUTPUT:
		RETVAL

###############################################################

MODULE = Jvm		PACKAGE = jstring


jsize
getStringLength(jstr)
	jstring jstr

	CODE:
	RETVAL=(*g_jvm)->GetStringLength(g_jvm, jstr);

	OUTPUT:
	RETVAL

SV*
getString(jstr)
	jstring	jstr 

	CODE:
	/* input maybe jstring, maybe jobject, so we force the jobject to jstring. 
	if(sv_derived_from(ST(0), "jstring") || sv_derived_from(ST(0), "jobject")) {
		IV tmp = SvIV((SV*)SvRV(ST(1)));
            	jstr = INT2PTR(jstring,tmp);
	} else 
		croak("jstr is NEITHER of type jstring *NOR* jobject!");
	*/

	
	RETVAL=getStr(jstr);
	

	OUTPUT:
	RETVAL

###############################################################

MODULE = Jvm		PACKAGE = jclass

jmethodID
getMethodID(cls, methodName, sig)
	jclass cls
	char* methodName
	char* sig

	CODE:
	RETVAL=(*g_jvm)->GetMethodID(g_jvm, cls, methodName, sig);

	OUTPUT:
	RETVAL

jmethodID
getStaticMethodID(cls, methodName, sig)
	jclass cls
	char * methodName
	char * sig 

	CODE:
	RETVAL= (*g_jvm)->GetStaticMethodID(g_jvm, cls, methodName, sig);
	
	OUTPUT:
	RETVAL


jobject
newObject(cls, methodID, args)
	jclass cls
	jmethodID methodID
	_jvalueArray args

	CODE:
	/* printf("%x\n",SvRV(ST(2))); */
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;

	RETVAL=(*g_jvm)->NewObjectA(g_jvm, cls, methodID, args);

	/* printf("New allocated jobject: %x\n", RETVAL); */
		
	OUTPUT:
	RETVAL

jboolean
callStaticBooleanMethod(cls, mid, args)
	jclass cls
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallStaticBooleanMethodA(g_jvm, cls, mid, args);

	OUTPUT:
	RETVAL


jbyte
callStaticByteMethod(cls, mid, args)
	jclass cls
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallStaticByteMethodA(g_jvm, cls, mid, args);

	OUTPUT:
	RETVAL


jchar
callStaticCharMethod(cls, mid, args)
	jclass cls
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallStaticCharMethodA(g_jvm, cls, mid, args);

	OUTPUT:
	RETVAL


jshort
callStaticShortMethod(cls, mid, args)
	jclass cls
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallStaticShortMethodA(g_jvm, cls, mid, args);

	OUTPUT:
	RETVAL


jint
callStaticIntMethod(cls, mid, args)
	jclass cls
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallStaticIntMethodA(g_jvm, cls, mid, args);

	OUTPUT:
	RETVAL


jlong
callStaticLongMethod(cls, mid, args)
	jclass cls
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallStaticLongMethodA(g_jvm, cls, mid, args);

	OUTPUT:
	RETVAL


jfloat
callStaticFloatMethod(cls, mid, args)
	jclass cls
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallStaticFloatMethodA(g_jvm, cls, mid, args);

	OUTPUT:
	RETVAL


jdouble
callStaticDoubleMethod(cls, mid, args)
	jclass cls
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallStaticDoubleMethodA(g_jvm, cls, mid, args);

	OUTPUT:
	RETVAL


void
callStaticVoidMethod(cls, mid, args)
	jclass cls
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	(*g_jvm)->CallStaticVoidMethodA(g_jvm, cls, mid, args);

jobject
callStaticObjectMethod(cls, mid, args)
	jclass cls
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	/* printf("%x,%x,%x\n", cls, mid, args); */
	RETVAL=(*g_jvm)->CallStaticObjectMethodA(g_jvm, cls, mid, args);

	OUTPUT:
	RETVAL


jfieldID
getStaticFieldID(cls, name, sig)
	jclass cls
	char* name
	char* sig

	CODE:
	RETVAL=(*g_jvm)->GetStaticFieldID(g_jvm, cls, name, sig);

	OUTPUT:
	RETVAL

jboolean
getStaticBooleanField(cls, fldID)
	jclass cls
	jfieldID fldID

	CODE:
	RETVAL=(*g_jvm)->GetStaticBooleanField(g_jvm, cls, fldID);

	OUTPUT:
	RETVAL

jbyte
getStaticByteField(cls, fldID)
	jclass cls
	jfieldID fldID

	CODE:
	RETVAL=(*g_jvm)->GetStaticByteField(g_jvm, cls, fldID);

	OUTPUT:
	RETVAL

jchar
getStaticCharField(cls, fldID)
	jclass cls
	jfieldID fldID

	CODE:
	RETVAL=(*g_jvm)->GetStaticCharField(g_jvm, cls, fldID);

	OUTPUT:
	RETVAL

jshort
getStaticShortField(cls, fldID)
	jclass cls
	jfieldID fldID

	CODE:
	RETVAL=(*g_jvm)->GetStaticShortField(g_jvm, cls, fldID);

	OUTPUT:
	RETVAL

jint
getStaticIntField(cls, fldID)
	jclass cls
	jfieldID fldID

	CODE:
	RETVAL=(*g_jvm)->GetStaticIntField(g_jvm, cls, fldID);

	OUTPUT:
	RETVAL

jlong
getStaticLongField(cls, fldID)
	jclass cls
	jfieldID fldID

	CODE:
	RETVAL=(*g_jvm)->GetStaticLongField(g_jvm, cls, fldID);

	OUTPUT:
	RETVAL

jfloat
getStaticFloatField(cls, fldID)
	jclass cls
	jfieldID fldID

	CODE:
	RETVAL=(*g_jvm)->GetStaticFloatField(g_jvm, cls, fldID);

	OUTPUT:
	RETVAL

jdouble
getStaticDoubleField(cls, fldID)
	jclass cls
	jfieldID fldID

	CODE:
	RETVAL=(*g_jvm)->GetStaticDoubleField(g_jvm, cls, fldID);

	OUTPUT:
	RETVAL

jobject
getStaticObjectField(cls, fldID)
	jclass cls
	jfieldID fldID

	CODE:
	RETVAL=(*g_jvm)->GetStaticObjectField(g_jvm, cls, fldID);

	OUTPUT:
	RETVAL


void
setStaticBoleanField(cls, fldID, value)
	jclass cls
	jfieldID fldID
	jboolean value

	CODE:
	(*g_jvm)->SetStaticBooleanField(g_jvm, cls, fldID, value);


void
setStaticByteField(cls, fldID, value)
	jclass cls
	jfieldID fldID
	jbyte value

	CODE:
	(*g_jvm)->SetStaticByteField(g_jvm, cls, fldID, value);


void
setStaticCharField(cls, fldID, value)
	jclass cls
	jfieldID fldID
	jchar value

	CODE:
	(*g_jvm)->SetStaticCharField(g_jvm, cls, fldID, value);


void
setStaticShortField(cls, fldID, value)
	jclass cls
	jfieldID fldID
	jshort value

	CODE:
	(*g_jvm)->SetStaticShortField(g_jvm, cls, fldID, value);


void
setStaticIntField(cls, fldID, value)
	jclass cls
	jfieldID fldID
	jint value

	CODE:
	(*g_jvm)->SetStaticIntField(g_jvm, cls, fldID, value);


void
setStaticLongField(cls, fldID, value)
	jclass cls
	jfieldID fldID
	jlong value

	CODE:
	(*g_jvm)->SetStaticLongField(g_jvm, cls, fldID, value);


void
setStaticFloatField(cls, fldID, value)
	jclass cls
	jfieldID fldID
	jfloat value

	CODE:
	(*g_jvm)->SetStaticFloatField(g_jvm, cls, fldID, value);


void
setStaticDoubleField(cls, fldID, value)
	jclass cls
	jfieldID fldID
	jdouble value

	CODE:
	(*g_jvm)->SetStaticDoubleField(g_jvm, cls, fldID, value);


void
setStaticObjectField(cls, fldID, value)
	jclass cls
	jfieldID fldID
	jobject value

	CODE:
	(*g_jvm)->SetStaticObjectField(g_jvm, cls, fldID, value);

###############################################################

MODULE = Jvm		PACKAGE = jobject

jobject
newGlobalRef(obj)
	jobject obj

	CODE:
	RETVAL=(*g_jvm)->NewGlobalRef(g_jvm, obj);

	OUTPUT:
	RETVAL

void
deleteGlobalRef(globalRefObj)
	jobject globalRefObj

	CODE:
	(*g_jvm)->DeleteGlobalRef(g_jvm, globalRefObj);


jclass
getObjectClass(obj)
	jobject obj

	CODE:
	RETVAL=(*g_jvm)->GetObjectClass(g_jvm, obj);
	
	OUTPUT:
	RETVAL



jboolean
callBooleanMethod(obj, mid, args)
	jobject obj
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallBooleanMethodA(g_jvm, obj, mid, args);

	OUTPUT:
	RETVAL

jbyte
callByteMethod(obj, mid, args)
	jobject obj
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallByteMethodA(g_jvm, obj, mid, args);

	OUTPUT:
	RETVAL

jchar
callCharMethod(obj, mid, args)
	jobject obj
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallCharMethodA(g_jvm, obj, mid, args);

	OUTPUT:
	RETVAL

jshort
callShortMethod(obj, mid, args)
	jobject obj
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallShortMethodA(g_jvm, obj, mid, args);

	OUTPUT:
	RETVAL

jint
callIntMethod(obj, mid, args)
	jobject obj
	jmethodID mid
	_jvalueArray args 

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallIntMethodA(g_jvm, obj, mid, args);

	OUTPUT:
	RETVAL

jlong
callLongMethod(obj, mid, args)
	jobject obj
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallLongMethodA(g_jvm, obj, mid, args);

	OUTPUT:
	RETVAL

jfloat
callFloatMethod(obj, mid, args)
	jobject obj
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallFloatMethodA(g_jvm, obj, mid, args);

	OUTPUT:
	RETVAL

jdouble
callDoubleMethod(obj, mid, args)
	jobject obj
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallDoubleMethodA(g_jvm, obj, mid, args);

	OUTPUT:
	RETVAL

void
callVoidMethod(obj, mid, args)
	jobject obj
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	(*g_jvm)->CallVoidMethodA(g_jvm, obj, mid, args);



jobject
callObjectMethod(obj, mid, args)
	jobject obj
	jmethodID mid
	_jvalueArray args

	CODE:
	if(args == (_jvalueArray)&PL_sv_undef) args = NULL;
	RETVAL=(*g_jvm)->CallObjectMethodA(g_jvm, obj, mid, args);

	OUTPUT:
	RETVAL
