# UNDER MOZILLA PUBLIC LICENSE
#     ``The contents of this file are subject to the Netscape Public License
#     Version 1.0 (the "License"); you may not use this file except in
#     compliance with the License. You may obtain a copy of the License at
#     http://www.mozilla.org/NPL/
#
#     Software distributed under the License is distributed on an "AS IS"
#     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
#     License for the specific language governing rights and limitations
#     under the License.
#
#     The Original Code is Mozilla Communicator client code, released March
#     31, 1998.
#
#     The Initial Developer of the Original Code is Netscape Communications
#     Corporation. Portions created by Netscape are Copyright (C) 1998
#     Netscape Communications Corporation. All Rights Reserved.
#
#     Contributor(s): Tuomas J. Lukka 1998.''
#                The contents of this file are partly derived from
#                stuff in the JS reference implementation.

# MEMORY LEAKS:
#  Browser objects not freed

open XS, ">JS.xs" or die"couldn't open JS.xs";

require '../VRMLFields.pm';

@Fields = qw/
	SFColor
	SFVec3f
	SFRotation
/;

{

my $ri = VRML::Field::SFRotation->rot_invert("rfrom->v","rto->v");
my $mv = VRML::Field::SFRotation->rot_multvec("rfrom->v","vfrom->v", "vto->v");

$extra{SFRotation} = {
	inverse => qq~
		JSObject *o;
		JSObject *proto;
		TJL_SFRotation *rfrom;
		TJL_SFRotation *rto;
	    proto = JS_GetPrototype(cx, obj);
	    o = JS_ConstructObject(cx, &cls_SFRotation, proto, NULL);
	    rfrom = JS_GetPrivate(cx,obj);
	    rto = JS_GetPrivate(cx,o);
	    {
	    $ri;
	    }
	    *rval = OBJECT_TO_JSVAL(o);
	~,
	multVec => qq~

		JSObject *ret ;
		JSObject *o;
		JSObject *ro;
		JSObject *proto;
		TJL_SFRotation *rfrom;
		TJL_SFVec3f *vfrom;
		TJL_SFVec3f *vto;
	if(JS_ConvertArguments(cx, argc, argv, "o",&o) == JS_FALSE) {
			if(verbose) printf("Convarg: false\\n");
			return JS_FALSE;
	};
	    if (!JS_InstanceOf(cx, o, &cls_SFVec3f, argv)) {
		die("multVec: has to be SFVec3f ");
		return JS_FALSE;
	    }
	    proto = JS_GetPrototype(cx, o);
	    ro = JS_ConstructObject(cx, &cls_SFVec3f, proto, NULL);
		rfrom = JS_GetPrivate(cx,obj);
		vfrom = JS_GetPrivate(cx,o);
		vto = JS_GetPrivate(cx,ro);
		{
		$mv
		}
	    *rval = OBJECT_TO_JSVAL(ro);

	~
};

my $veci = q~
JSObject *ret;
	    JSObject *v2;
		JSObject *proto;
		JSObject *ro;
		TJL_SFVec3f *vec1;
		TJL_SFVec3f *vec2;
		TJL_SFVec3f *res;
	if(JS_ConvertArguments(cx, argc, argv, "o",&v2) == JS_FALSE) {
			if(verbose) printf("Convarg: false\\n");
			return JS_FALSE;
	};
	    if (!JS_InstanceOf(cx, v2, &cls_SFVec3f, argv)) {
		die("vec function: has to be SFVec3f ");
		return JS_FALSE;
	    }
	    proto = JS_GetPrototype(cx, v2);
	    ro = JS_ConstructObject(cx, &cls_SFVec3f, proto, NULL);
	    vec1 = JS_GetPrivate(cx,obj);
	    vec2 = JS_GetPrivate(cx,v2);
	    res = JS_GetPrivate(cx,ro);
	    *rval = OBJECT_TO_JSVAL(ro);
	   ~;

my $vecr = q~
	JSObject *ret;
		JSObject *ro;
		JSObject *proto;
		TJL_SFVec3f *vec1;
		TJL_SFVec3f *res;
	if(JS_ConvertArguments(cx, argc, argv, "") == JS_FALSE) {
			if(verbose) printf("Convarg: false\\n");
			return JS_FALSE;
	};
	    proto = JS_GetPrototype(cx, obj);
	    ro = JS_ConstructObject(cx, &cls_SFVec3f, proto, NULL);
	    vec1 = JS_GetPrivate(cx,obj);
	    res = JS_GetPrivate(cx,ro);
	    *rval = OBJECT_TO_JSVAL(ro);
~;

my $veco = q~
	jsdouble result;
	jsdouble *dp;
	JSObject *ret;
		JSObject *proto;
		TJL_SFVec3f *vec1;
		TJL_SFVec3f *res;
	if(JS_ConvertArguments(cx, argc, argv, "") == JS_FALSE) {
			if(verbose) printf("Convarg: false\\n");
			return JS_FALSE;
	};
	    proto = JS_GetPrototype(cx, obj);
	    vec1 = JS_GetPrivate(cx,obj);
~;

$extra{SFVec3f} = {
	add => $veci.VRML::Field::SFVec3f->vec_add(qw/(*vec1).v (*vec2).v (*res).v/),
	cross => $veci.VRML::Field::SFVec3f->vec_cross(qw/(*vec1).v (*vec2).v (*res).v/),
	subtract => $veci.VRML::Field::SFVec3f->vec_subtract(qw/(*vec1).v (*vec2).v (*res).v/),
	normalize => $vecr.VRML::Field::SFVec3f->vec_normalize(qw/(*vec1).v (*res).v/),
	negate => $vecr.VRML::Field::SFVec3f->vec_negate(qw/(*vec1).v (*res).v/),
	length => $veco.VRML::Field::SFVec3f->vec_length(qw/(*vec1).v result/).
			" 
		        dp = JS_NewDouble(cx,result);
			*rval = DOUBLE_TO_JSVAL(dp); ",
};

}

$header .= join '', map {"extern JSClass cls_$_; "} @Fields;

$header .= "
$VRML::Field::avecmacros
";

$field_funcs = join '',map {get_offsf($_)} @Fields;

@MFFields = qw/
 	MFColor      
	MFVec3f
	MFRotation
	MFNode
	MFString
/;

$field_funcs .= join '',map {def_mffield($_)} @MFFields;

%bapi = qw(getName 0 getVersion  0 
getCurrentSpeed 0 getCurrentFrameRate 0 getWorldURL 0
	replaceWorld 1 loadURL 2 
	setDescription 1 
	createVrmlFromString 1
	createVrmlFromURL 3 
	addRoute 4 deleteRoute 4
);
for(keys %bapi) {
		$browser_fspecs .= qq'
			{"$_", browser_$_, 0},
		';
		$browser_functions .= qq'
static JSBool
browser_$_(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
	Browser_s *brow = JS_GetPrivate(cx,obj);
	int count;
	SV *sv;
	jsval v;
	int i;
	if(brow->magic != BROWMAGIC) {
		die("Wrong browser magic!");
	}
	if(argc != $bapi{$_}) {
		die("Invalid number of arguments for browser method");
	}
	for(i=0; i<argc; i++) {
		char buffer[80];
		sprintf(buffer,"__arg%d",i);
		JS_SetProperty(cx,obj,buffer,argv+i);
	}
	if(verbose) printf("Calling method with sv %d (%s)\\n",brow->js_sv,
		SvPV(brow->js_sv,na));
	{
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(sp);
		XPUSHs(brow->js_sv);
		PUTBACK;
		count = perl_call_method("brow_$_", G_SCALAR);
		if(count) {
			if(verbose) printf("Got return %f\\n",POPn);
		}
		PUTBACK;
		FREETMPS;
		LEAVE;
	}
	if(!JS_GetProperty(cx,obj,"__bret",&v)) {die("Brow return");}
	*rval = v;
	return JS_TRUE;
}

		';
}

#########################################################
#
# Define the SFNode class... this is the trickiest one..

$load_classes .= "
    proto_SFNode = JS_InitClass(cx, globalObj, NULL, &cls_SFNode,
		cons_SFNode, 3,
		NULL, meth_SFNode /* methods */,
		NULL, NULL);
	    { jsval v = OBJECT_TO_JSVAL(proto_SFNode);
    JS_SetProperty(cx, globalObj, \"__SFNode_proto\", &v);
    }
";

$field_funcs .= qq~

static JSObject *proto_SFNode;

static JSBool
cons_SFNode(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
	if(argc == 0) {
		die("SFNode construction: need at least 1 arg");
	} 
	if(argc == 1) {
		die("Sorry, can't construct a SFNode from VRML yet (XXX FIXME)");
	} else if(argc == 2) {
		JSString *str;
		char *p;
		str = JS_ValueToString(cx, argv[1]);
		p = JS_GetStringBytes(str);
		/* Hidden two-arg constructor: we construct it using
		 * an id... */
		if(verbose) printf("CONS_SFNODE: '%s'\n",p);
		if(!JS_DefineProperty(cx,obj,"__id",argv[1],
			NULL,NULL,JSPROP_PERMANENT)) {
				die("SFNode defprop error");
		}
		return JS_TRUE;
	} else {
		die("SFNode construction: invalid no of args");
	}
}

#define meth_SFNode NULL

static JSBool
setprop_SFNode(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
	dSP;
	JSObject *globalObj = JS_GetGlobalObject(cx);
	Browser_s *brow;
	jsval pv;
	int count;
	jsval v = OBJECT_TO_JSVAL(obj);
	JS_GetProperty(cx, globalObj, "Browser", &pv);
	if(!JSVAL_IS_OBJECT(pv)) {die("Browser not object?!?");}
	brow = JS_GetPrivate(cx, JSVAL_TO_OBJECT(pv));
	JS_SetProperty(cx, globalObj, "__node", &v);
	JS_SetProperty(cx, globalObj, "__prop", &id);
	JS_SetProperty(cx, globalObj, "__val", vp);
	if(verbose) printf("SFNode setprop \n");
		ENTER;
		SAVETMPS;
		PUSHMARK(sp);
		XPUSHs(brow->js_sv);
		PUTBACK;
		count = perl_call_method("node_setprop", G_SCALAR);
		if(count) {
			if(verbose) printf("Got return %f\\n",POPn);
		}
		PUTBACK;
		FREETMPS;
		LEAVE;
	return JS_TRUE;
}

static JSBool
getprop_SFNode(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
	if(verbose) printf("SFNode getprop \n");
	return JS_TRUE;
}

static JSClass cls_SFNode = {
	\"SFNode\", JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub, /* getprop_SFNode,*/ setprop_SFNode,
    JS_EnumerateStub, JS_ResolveStub,   JS_ConvertStub,   JS_FinalizeStub
};
~;


#########################################################
# Because this requires so different treatment in JS, we do not
# use VRMLFields.pm
sub def_mffield {
	my($f) = @_;
	my $sf = $f; $sf =~ s/^MF/SF/ or die("Invalid MF '$f'");

	$load_classes .= "
	    proto_$f = JS_InitClass(cx, globalObj, NULL, &cls_$f,
			cons_$f, 3,
			NULL, meth_$f /* methods */,
			NULL, NULL);
	    { jsval v = OBJECT_TO_JSVAL(proto_$f);
	    JS_SetProperty(cx, globalObj, \"__${f}_proto\", &v);
	    }
	";


	$add_classes .= <<__STOP__;


__STOP__

	return <<__STOP__;

static JSObject *proto_$f;

static JSBool
addprop_$f(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
	jsval v;
	jsval myv;
	int ind = JSVAL_TO_INT(id);
	int len;
	JSString *str;
	char *p;
	str = JS_ValueToString(cx, id);
	p = JS_GetStringBytes(str);
	if(!strcmp(p,"length") || !strcmp(p,"constructor") || 
	   !strcmp(p,"assign") || !strcmp(p,"__touched_flag")) {
		return JS_TRUE;
	}
	if(verbose) printf("JS MF %d addprop '%s'\\n",obj,p);
	{
		JSString *str;
		char *p;
		str = JS_ValueToString(cx, *vp);
		p = JS_GetStringBytes(str);
		if(verbose) printf("JS MF APVAL '%s'\n",p);
	}
	if(!JSVAL_IS_INT(id)){ 
		die("MF prop not int");
	}
	if(!JS_GetProperty(cx,obj,"length",&v)) {die("MF lenval");}
	len = JSVAL_TO_INT(v);
	if(verbose) printf("MF addprop %d %d\\n",ind,len);
	if(ind >= len) {
		len = ind+1;
		v = INT_TO_JSVAL(len);
		JS_SetProperty(cx,obj,"length",&v);
	}
	myv = INT_TO_JSVAL(1);
	JS_SetProperty(cx,obj,"__touched_flag",&myv);
	return JS_TRUE;
}

static JSBool 
setprop_$f(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
	jsval myv;
	JSString *str;
	char *p;
	str = JS_ValueToString(cx, id);
	p = JS_GetStringBytes(str);
	if(verbose) printf("JS MF %d setprop '%s'\\n",obj,p);
	{
		JSString *str;
		char *p;
		str = JS_ValueToString(cx, *vp);
		p = JS_GetStringBytes(str);
		if(verbose) printf("JS MF APVAL '%s'\n",p);
	}
	if(JSVAL_IS_INT(id)) {
		myv = INT_TO_JSVAL(1);
		JS_SetProperty(cx,obj,"__touched_flag",&myv);
	}
	return JS_TRUE;
}


static JSClass cls_$f = {
	"$f", JSCLASS_HAS_PRIVATE,
    addprop_$f,  JS_PropertyStub,  JS_PropertyStub, setprop_$f,
    JS_EnumerateStub, JS_ResolveStub,   JS_ConvertStub,   JS_FinalizeStub
};

static JSBool
cons_$f(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
	jsval v = INT_TO_JSVAL(argc);
	int i;
	if(!JS_DefineProperty(cx,obj,"length",v,
		NULL,NULL, JSPROP_PERMANENT )) {
			die("Array length property");
	};
	v = INT_TO_JSVAL(0);
	if(!JS_DefineProperty(cx,obj,"__touched_flag",v,
		NULL,NULL, JSPROP_PERMANENT)) {
			die("MF tflag");
	};
	if(!argv) return JS_TRUE;
	for(i=0; i<argc; i++) {
		jsval ind = INT_TO_JSVAL(i);
		char buf[80]; sprintf(buf,"%d",i);
		/* XXX Check type */
		if(!JS_DefineProperty(cx,obj,buf,argv[i],
			JS_PropertyStub, JS_PropertyStub,
			JSPROP_ENUMERATE)) {
				die("Array element"); 
		}
	}
	return JS_TRUE;
}

static JSBool
assign_$f(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    jsval val;
    jsval myv;
    int len;
    int i;
    JSObject *o;
    if (!JS_InstanceOf(cx, obj, &cls_$f, argv))
        return JS_FALSE;
    if(verbose) printf("ASSIGN HACK $f %d\\n",argc);
	if(JS_ConvertArguments(cx, argc, argv, "o",&o) == JS_FALSE) {
			if(verbose) printf("Convarg: false\\n");
			return JS_FALSE;
	};
    if (!JS_InstanceOf(cx, o, &cls_$f, argv)) {
    	die("Assignobj wasn't instance of me");
        return JS_FALSE;
    }
/* Now, we assign length properties from o to obj */
/* XXX HERE */
	myv = INT_TO_JSVAL(1);
    JS_SetProperty(cx,obj,"__touched_flag",&myv);
    JS_GetProperty(cx,o,"length",&val);
    JS_SetProperty(cx,obj,"length",&val);
    len = JSVAL_TO_INT(val); /* XXX Assume int */
    for(i=0; i<len; i++) {
		char buf[80]; sprintf(buf,"%d",i);
	    JS_GetProperty(cx,o,buf,&val);
	    JS_SetProperty(cx,obj,buf,&val);
    }

    *rval = OBJECT_TO_JSVAL(obj); 
    if(verbose) printf("Assgn: true\\n");
    return JS_TRUE;
}

static JSFunctionSpec (meth_$f)[] = {
/* $methlist, */
{"assign", assign_$f, 0},
/* {"toString", tostr_$f, 0},  */
{0}
};

__STOP__

}

#################################################################
#################################################################
#################################################################
#
# SF fields
#

sub get_offsf {
	my($f) = @_;
	$ft = "VRML::Field::$_";
	my ($cs) = $ft->cstruct;
	my ($cv) = $ft->ctype("v");
	my ($ct) = $ft->ctype("*ptr_");
	my ($ctp) = $ft->ctype("*");
	my ($c) = $ft->cfunc("(ptr->v)", "sv_");
	my ($ca) = $ft->calloc("(ptr->v)");
	my ($cf) = $ft->cfree("(ptr->v)");
	my ($cass) = $ft->cassign("(to->v)","(from->v)");
	my $jsprop = $ft->jsprop();
	my $numprop = $ft->jsnumprop("(ptr->v)");
	my $getprop = join "", map {
		"case $_: d = $numprop->{$_}; dp = JS_NewDouble(cx,d);
			*vp = DOUBLE_TO_JSVAL(dp); break; \n"
	} keys %$numprop;
	my $setprop = join "", map {
		"case $_: $numprop->{$_} = *JSVAL_TO_DOUBLE(myv); break; \n"
	} keys %$numprop;
	my $xtr = join "\n",map {
		"
		static JSBool
		${_}_$f(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
		{
		    if (!JS_InstanceOf(cx, obj, &cls_$f, argv))
			return JS_FALSE;
		     if(verbose) printf(\"METHOD: $_ $f\\n\");
		    {
			$extra{$f}{$_}
	            }
		    return JS_TRUE;
		}
		"
			} keys %{$extra{$f}};
	my $extmethods = join "\n", map {
		"{\"$_\", ${_}_$f, 0},"
	} keys %{$extra{$f}};

	my $jstostr = $ft->jstostr("(ptr->v)");
	$jstostr =~ s/\$RET\(([^)]*)\)/str_ = JS_NewStringCopyZ(cx,$1)/;
	my $jscons = $ft->jscons("(ptr->v)");
	if($#$jscons != 1) {
		$jscons->[1] = qq~
			if(verbose) printf("CONSTRUCTING: GOT %d args\\n",argc);
			if(argc==0) {
				$jscons->[4];
				return JS_TRUE;
			}
			if(JS_ConvertArguments(cx, argc, argv, "$jscons->[1]",
				$jscons->[2]) == JS_FALSE) {
					if(verbose) printf("Convarg: false\\n");
					return JS_FALSE;
			};
			if(verbose) printf("CONSARGS: %f %f %f\\n",pars[0],pars[1],pars[2]);
			{
				$jscons->[3];
			}
		~;
		$#$jscons = 1;
	}

	$load_classes .= "
	    proto_$f = JS_InitClass(cx, globalObj, NULL, &cls_$f,
			cons_$f, 3,
			NULL, meth_$f /* methods */,
			NULL, NULL);
	    { jsval v = OBJECT_TO_JSVAL(proto_$f);
	    JS_SetProperty(cx, globalObj, \"__${f}_proto\", &v);
	    }
	";

	$add_classes .= <<__STOP__;

void
set_property_$f(cp,p,name,sv)
	void *cp
	void *p
	char *name
	SV *sv
CODE:
    JSContext *cx = cp;
    JSObject *globalObj = p; 
    JSObject *obj;
	jsval v;
	if(!JS_GetProperty(cx,globalObj, name, &v)) {
		die("Getting object of $f: %s",name);
	}
     if(!JSVAL_IS_OBJECT(v)) {
     	die("Getting prop: not object (%d) '%s'",v,name);
     }
     obj = JSVAL_TO_OBJECT(v);
/*    if (!JS_InstanceOf(cx, obj, &cls_$f, argv)) {
    	die("Property %s was not of type $f",name);
    }
 */ /* Trust it... ARGH */
	set_$f(JS_GetPrivate(cx,obj), sv);

__STOP__

	return <<__STOP__

$cs

static JSObject *proto_$f;

typedef struct TJL_$f {
	int touched; 
	$cv;
} TJL_$f;

void *new_$f() {
	struct TJL_$f *ptr;
	ptr = malloc(sizeof(*ptr));
	ptr->touched = 0;
	$ca
	return ptr;
}

void del_$f(void *p) {
	struct TJL_$f *ptr = p;
	$cf
	free(ptr);
}

void asgn_$f(void *top, void *fromp) {
	struct TJL_$f *to = top;
	struct TJL_$f *from = fromp;
	to->touched ++;
	$cass
}

void set_$f(void *p, SV *sv_) {
	struct TJL_$f *ptr = p;
	ptr->touched = 0; /* ... */
	$c
}

JSBool 
getprop_$f(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
	jsdouble d;
	jsdouble *dp;
	struct TJL_$f *ptr = JS_GetPrivate(cx,obj);
	if(JSVAL_IS_INT(id)) {
		switch(JSVAL_TO_INT(id)) {
			$getprop
		}
	}
	return JS_TRUE;
}

static JSBool 
setprop_$f(JSContext *cx, JSObject *obj, jsval id, jsval *vp)
{
	struct TJL_$f *ptr = JS_GetPrivate(cx,obj);
	jsval myv;
	ptr->touched ++;
	if(!JS_ConvertValue(cx, *vp, JSTYPE_NUMBER, &myv)) {
		return JS_FALSE;
	}
	if(JSVAL_IS_INT(id)) {
		switch(JSVAL_TO_INT(id)) {
			$setprop
		}
	}
	return JS_TRUE;
}

JSClass cls_$f = {
	"$f", JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,  JS_PropertyStub,  getprop_$f,  setprop_$f,
    JS_EnumerateStub, JS_ResolveStub,   JS_ConvertStub,   JS_FinalizeStub
};

static  JSPropertySpec (prop_$f)[] = {
	$jsprop,
	{0}
};

static JSBool
tostr_$f(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    struct TJL_$f *ptr = JS_GetPrivate(cx,obj);
    JSString *str_;
    if (!JS_InstanceOf(cx, obj, &cls_$f, argv))
        return JS_FALSE;
    $jstostr    
    *rval = STRING_TO_JSVAL(str_);
    return JS_TRUE;
}

static JSBool
assign_$f(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    struct TJL_$f *ptr = JS_GetPrivate(cx,obj);
    struct TJL_$f *fptr;
    JSObject *o;
    JSObject *ofoo;
    if (!JS_InstanceOf(cx, obj, &cls_$f, argv))
        return JS_FALSE;
    if(verbose) printf("ASSIGN HACK $f %d\\n",argc);
	if(JS_ConvertArguments(cx, argc, argv, "o",&o,&o) == JS_FALSE) {
			if(verbose) printf("Convarg: false\\n");
			return JS_FALSE;
	};
    if (!JS_InstanceOf(cx, o, &cls_$f, argv)) {
    	die("Assignobj wasn't instance of me");
        return JS_FALSE;
    }
    fptr = JS_GetPrivate(cx,o);
/*
    printf("ptr: %d %f %f %f fptr: %d %f %f %f\\n", ptr, ptr->v.c[0],ptr->v.c[1],ptr->v.c[2],
    	fptr, fptr->v.c[0],fptr->v.c[1],fptr->v.c[2]);
 */
    asgn_$f(ptr,fptr);
/*
    printf("ptr: %d %f %f %f fptr: %d %f %f %f\\n", ptr, ptr->v.c[0],ptr->v.c[1],ptr->v.c[2],
    	fptr, fptr->v.c[0],fptr->v.c[1],fptr->v.c[2]);
 */
    *rval = OBJECT_TO_JSVAL(obj); 
    if(verbose) printf("Assgn: true\\n");
    return JS_TRUE;
}

static JSBool
touched_$f(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
    struct TJL_$f *ptr = JS_GetPrivate(cx,obj);
    int t;
    if (!JS_InstanceOf(cx, obj, &cls_$f, argv))
        return JS_FALSE;
    t = ptr->touched; ptr->touched = 0;
    if(verbose) printf("TOUCHED WAS %d\\n",t);
    *rval = INT_TO_JSVAL(t);
    return JS_TRUE;
}

$xtr

static JSFunctionSpec (meth_$f)[] = {
/* $methlist, */
{"assign", assign_$f, 0},
{"toString", tostr_$f, 0},
{"__touched", touched_$f, 0},
$extmethods
{0}
};

static JSBool 
cons_$f(JSContext *cx, JSObject *obj, uintN argc, jsval *argv, jsval *rval)
{
	void *p = new_$f();
	struct TJL_$f *ptr = p;
	$jscons->[0];

	JS_DefineProperties(cx, obj, prop_$f);
	JS_SetPrivate(cx, obj, p);
    /* printf("ptr: %d %f %f %f\\n", ptr, ptr->v.c[0],ptr->v.c[1],ptr->v.c[2]);
     */
      {
     	$jscons->[1]
      }
	return JS_TRUE;
}


__STOP__
}


#########################################################

print XS <<__STOP__
/* THIS FILE IS GENERATED BY genJS.pl. DO NOT EDIT */
/* THIS FILE IS GENERATED BY genJS.pl. DO NOT EDIT */
/* THIS FILE IS GENERATED BY genJS.pl. DO NOT EDIT */
/* UNDER MOZILLA PUBLIC LICENSE -- see the generating file
 * for actual license. THIS FILE IS NOT ACTUAL SOURCE CODE. */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include "jsapi.h"

#define STACK_CHUNK_SIZE 8192


static int verbose = 0;

static JSRuntime *rt;

/* Function-local: */
/* static JSObject *globalObj; */

#define BROWMAGIC 12345
typedef struct Browser_s {
	int magic;
	SV *js_sv;
	
} Browser_s;

static JSBool global_resolve(JSContext *cx, JSObject *obj, jsval id) 
{
	return JS_TRUE;
}

$header

$browser_functions

static JSClass my_global_class = {
    "global", 0,
    JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,
    JS_EnumerateStub, global_resolve,   JS_ConvertStub,   JS_FinalizeStub
};

static JSClass my_browser_class = {
    "_Browserclass", JSCLASS_HAS_PRIVATE,
    JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,  JS_PropertyStub,
    JS_EnumerateStub, JS_ResolveStub,   JS_ConvertStub,   JS_FinalizeStub
};

static JSFunctionSpec (my_browser_meth)[] = {
	$browser_fspecs
	{0}
};

double runscript(void *cxp, void *glo, char *script, SV*r) {
	JSContext *cx = cxp;
	JSObject *globalObj = glo;
	char *filename = "FOO" ;
	uintN lineno = 23;
	jsval rval;
	JSBool ok;
	jsdouble d;
	JSString *strval;
	char *strp;
	if(verbose) printf("Running script '%s'\\n",script);

	ok = JS_EvaluateScript(cx, globalObj, script, strlen(script),
		filename, lineno, &rval);
	if(ok) {
		strval = JS_ValueToString(cx, rval);
		strp = JS_GetStringBytes(strval);
		sv_setpv(r,strp);

		ok = JS_ValueToNumber(cx, rval, &d);
		if(ok) {
			/* printf("GOT: %f\\n",d); */
			return d;
		} else {
			die("VTN failure\\n");
		}


 	} else {
		die("Loadscript failure");
	}
return 0.0; /* Compiler satisfaction */
}

$field_funcs

void load_classes(JSContext *cx, JSObject *globalObj, SV *jssv) {
	int ok;
	char *str = "new _Browserclass()";
	jsval rval;
	Browser_s *brow = malloc(sizeof(Browser_s));
	JSObject *obj;
	brow->js_sv = newSVsv(jssv);
	brow->magic = BROWMAGIC;
	$load_classes
/*	JS_InitClass(cx,globalObj, NULL, &my_browser_class,
		NULL, 0,
		NULL, my_browser_meth,
		NULL, NULL);
 */
	obj = JS_DefineObject(cx,globalObj, "Browser", &my_browser_class,
		0, JSPROP_ENUMERATE| JSPROP_PERMANENT);
	JS_DefineFunctions(cx,obj,my_browser_meth);

	JS_SetPrivate(cx, obj, brow);

}

void errorrep(JSContext *cx, const char *message, JSErrorReport *report) {
/* This reports even stupid errors, like when using wrong number
 * of arguments for constructor which has variable numbers.
 * XXX FIX
 */
	/* fprintf(stderr,"JS ERROR: %s\\n", message); */
}

static JSBool 
set_touchable(JSContext *cx, JSObject *obj, jsval id, jsval *vp) {
	char *n = JS_GetStringBytes(JSVAL_TO_STRING(id));
	char buffer[100];
	jsval v;
	if(verbose) printf("SET_TOUCHABLE %s\\n",n);
	sprintf(buffer,"_%s_touched",n);
	v = INT_TO_JSVAL(1);
	JS_SetProperty(cx, obj, buffer, &v);
	return JS_TRUE;
}


MODULE=VRML::JS	PACKAGE=VRML::JS
PROTOTYPES: ENABLE

void
set_verbose(v)
	int v;
CODE:
	verbose = v;

void 
init()
CODE:
    rt = JS_Init(1000000L);
    if (!rt)
        die("can't create JavaScript runtime");


void *
newcontext (glob,jssv) 
void *glob
SV *jssv
CODE:	
    JSContext *cx;
    JSObject *globalObj; 
    cx = JS_NewContext(rt, STACK_CHUNK_SIZE);
    JS_SetErrorReporter(cx, errorrep);
    if (!cx)
        die("can't create JavaScript context");
    /*
     * The context definitely wants a global object, in order to have standard
     * classes and functions like Date and parseInt.  See below for details on
     * JS_NewObject.
     */
    globalObj = JS_NewObject(cx, &my_global_class, 0, 0);
    JS_InitStandardClasses(cx, globalObj);
    load_classes(cx,globalObj,jssv);
    glob = globalObj;
    RETVAL=cx;
OUTPUT:
	RETVAL
	glob

double
runscript(cp,p,s,str)
	void *cp
	void *p
	char *s
	SV *str

void
addasgnprop(cp,p,name,str)
	void *cp
	void *p
	char *name
	char *str
CODE:
    JSContext *cx = cp;
    JSObject *globalObj = p; 
    jsval rval;
    int ok;
    if(verbose) printf("Addasgn eval '%s'\\n",str);
	ok = JS_EvaluateScript(cx, globalObj, str, strlen(str),
		"bar", 15, &rval);
	if(!ok) { printf("SCRFAIL\\n"); die("Addasgn script fail"); }
    if(verbose) printf("Addasgn eval ok \\n",str);
        JS_DefineProperty(cx, globalObj, name, rval,
                  NULL, NULL, 0 | JSPROP_ASSIGNHACK | JSPROP_PERMANENT ); /* */

void
addwatchprop(cp,p,name)
	void *cp
	void *p
	char *name
CODE:
    JSContext *cx = cp;
    JSObject *globalObj = p; 
    jsval rval;
    int ok;
	char buffer[100];
	jsval v;
	ok = JS_DefineProperty(cx, globalObj, name, 
		INT_TO_JSVAL(0), 
		NULL, set_touchable,  0 | JSPROP_PERMANENT);
	if(!ok) {die("Addwatch script fail");}
	if(verbose) printf("SET_TOUCHABLE INIT %s\\n",name);
	sprintf(buffer,"_%s_touched",name);
	v = INT_TO_JSVAL(1);
	JS_SetProperty(cx, globalObj, buffer, &v);

$add_classes
__STOP__

