#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

struct pMG;
typedef struct pMG pMG;
struct pMG {
    XPVMG*	sv_any;		
    U32		sv_refcnt;
    union {
        U32		sv_flags;
        struct {
            unsigned long type : 8;
            unsigned long f_IOK : 1;
            unsigned long f_NOK : 1;
            unsigned long f_POK : 1;
            unsigned long f_ROK : 1;
            unsigned long p_IOK: 1;
            unsigned long p_NOK: 1;
            unsigned long p_POK : 1;
            unsigned long p_SCREAM_phv_CLONEABLE_phv_CLONEABLE_prv_PCS_IMPORTED : 1;
            unsigned long s_PADSTALE_SVpad_STATE : 1;
            unsigned long s_PADTMP_SVpad_TYPED : 1;
            unsigned long s_PADMY_SVpad_OUR : 1;
            unsigned long s_TEMP : 1;            
            unsigned long s_OBJECT : 1;
            unsigned long s_GMG : 1;
            unsigned long s_SMG : 1;
            unsigned long s_RMG : 1;
            unsigned long f_FAKE_SVphv_REHASH : 1;
            unsigned long f_OOK : 1;
            unsigned long f_BREAK: 1;
            unsigned long f_READONLY : 1;
            unsigned long f_AMAGIC : 1;
            unsigned long f_UTF8_SVphv_SHAREKEYS : 1;
            unsigned long pav_REAL_phv_LAZYDEL_pbm_VALID_repl_EVAL : 1;
            unsigned long f_IVisUV_pav_REIFY_phv_HASKFLAGS_pfm_COMPILED_pbm_TAIL_prv_WEAKREF : 1;
        } flagsraw;
    };
    union {				
	IV      svu_iv;	
	UV      svu_uv;	
	pMG*     svu_rv;	
	char*   svu_pv;	
	pMG**    svu_array;		
	HE**	svu_hash;		
	GP*	svu_gp;			
    }	sv_u;
};


typedef struct {
    char * key;
    U32 hash;
    const unsigned long klen;
} hvCacheKeyStruct;

//X macros
struct {
#define XMM(x) hvCacheKeyStruct x;
#include "hvkeys.h"
#undef XMM
} hvCache  = {
#define XMM(x) {NULL, 0, sizeof(#x)-1},
#include "hvkeys.h"
#undef XMM    
};
//all hash keys must be valid c identifiers, this isn't a problem for
//objects, there are solutions to the problem of hash key names not being
//valid C identifiers, but I am not going to use them in this module at the
//moment
#define HVKC_KEY(x) (hvCache.x.key)
#define HVKC_KLEN(x) (hvCache.x.klen)
#define HVKC_HASH(x) (hvCache.x.hash)

//this messes up CPU caching on purpose by the key in the last hash being random
//since struct hvCache happens to have all idential member types
//it can be safely cast to an array, potentially parameter x can be a macro
//integer constant, 4 funcs call the func that accesses the hash, each of the 4
//funcs pass a constant macro integer to the hash accessor, a hvCacheKeyStruct *
//could also be passed, but that can only originate from runtime code, pointers
//obviously cant survive IPC or network I/O or being saved to a disk, if the
//4 funcs are sourcing their data from a file, it would be more efficient
//to code a system of macro const integers to represent some data slices in the file
//and have the macro const integers be converted by the 1 and only hash accessor
//func, rather than put the file data slices to hvCacheKeyStruct* conversion code
//in 4 different funcs,

//how to generate the array index consts, easy, a macro that expands to
//"(((size_t)&hvcache.KeyName - (size_t)&hvCache)/sizeof(hvCache.KeyName))"

#define HVKC_ARR_KEY(x)  ((((hvCacheKeyStruct*)&(hvCache))+(x))->key)
#define HVKC_ARR_KLEN(x) ((((hvCacheKeyStruct*)&(hvCache))+(x))->klen)
#define HVKC_ARR_HASH(x) ((((hvCacheKeyStruct*)&(hvCache))+(x))->hash)

//it is impossible to do a fetch and supply the hash number through the PODed
//public API, hv_common_key_len is marked as public API but is unPODed

//old way of doing things
#define hvkc_hv_fetch(hv, key, klen, lval, hash)                                   \
((SV**) hv_common_key_len((hv), (key), (klen), (lval)               \
? (HV_FETCH_JUST_SV | HV_FETCH_LVALUE)    \
: HV_FETCH_JUST_SV, NULL, (hash)))

//new way of doing things, since this is a macro, the it is all optimized away
//by the C compiler
#define hvkc_hv_fetch_kc(hv, key, lval)                                   \
((SV**) hv_common_key_len((hv), (HVKC_KEY(key)), (HVKC_KLEN(key)), (lval)               \
? (HV_FETCH_JUST_SV | HV_FETCH_LVALUE)    \
: HV_FETCH_JUST_SV, NULL, (HVKC_HASH(key))))


typedef struct {
    char * str;
    size_t strLen;
}InitStructSlice;

//this is supposed to match the key name data layout in makefile.pl
typedef struct {
        size_t structLen;
#define XMM(x) char * x; size_t x##Len;
#include "hvkeys.h"
#undef XMM
    } InitStruct;




#define MODNAME "Example::XS::FasterHashes"
MODULE = Example::XS::FasterHashes		PACKAGE = Example::XS::FasterHashes		

BOOT:
{
    //for ithreads, from my tries, hash num is the same, shared PV is different, so only first
    //interp gets shared PV acceleration, both get hash num acceleration
    InitStruct * HVKeysInitStruct;
    const unsigned long  SliceCount  = (sizeof(InitStruct)-sizeof(size_t))/sizeof(InitStructSlice);
    //pointer to fixed length array declaration, this is a pointer to the
    //string that represents .bin file we loaded in the PM file
    InitStructSlice (*HVKeysInitStructSlice)[(sizeof(InitStruct)-sizeof(size_t))/sizeof(InitStructSlice)];
    unsigned int i; //generate the supposed length of key name data file from
    //hvkeys.h, this is optimized to a integer, if .bin doesn't match at runtime,
    //we catch it here
    const unsigned long InitStructTotalLength  = sizeof(InitStruct)
#define XMM(x) + sizeof(#x)
#include "hvkeys.h" 
#undef XMM
    ;
    AV * const av = get_av(MODNAME "::HashKeys", GV_ADD);
    {//new block for scope
    unsigned long HVKeysInitStructPVLen;
    //sanity check against self's PM
    if(items != 3) goto apierror; 
    {
        SV * HVKeysInitStructSV = ST(2); //0 is class name, 1 is $VERSION I think
        HVKeysInitStruct = (InitStruct *) SvPV(HVKeysInitStructSV, HVKeysInitStructPVLen);
    } //lots of sanity checks, very lightweight
    if(HVKeysInitStructPVLen != InitStructTotalLength) goto apierror;
    if(HVKeysInitStruct->structLen != InitStructTotalLength) goto apierror;
    }//end of block
    //a really complicated pointer to fixed len array cast, 1st line cast, 2nd data
    HVKeysInitStructSlice = (InitStructSlice (*)[(sizeof(InitStruct)-sizeof(size_t))/(sizeof(InitStructSlice))])
                            ((char *) HVKeysInitStruct + sizeof(HVKeysInitStruct->structLen));
    for(i = 0; i < SliceCount; i++) { //fixup ptrs
        SV * keysv;
        (*HVKeysInitStructSlice)[i].str  += (size_t)HVKeysInitStruct;
        {//begin block
        hvCacheKeyStruct * const keyStrtVar = ((hvCacheKeyStruct*)&hvCache)+i;
        //turn relative offset to abs pointer
        //more sanity checking, the key lengths are initialized R/W static data
        //in the DLL, the char * cant, and hash num 99% of time can't be
        //compile time initialized 
        if(keyStrtVar->klen != (*HVKeysInitStructSlice)[i].strLen) goto apierror;
        //this can't be const-ed on 99% of perls because of random salting
        //since 5.8.1, see http://perl5.git.perl.org/perl.git/blob/7bef440cec6de046112398f991b1dd7d23689e23:/hv.h#l114
        //if you are adventerous, you can use those macros to have PERL_HASH be
        //optimized to a constant placed by the compiler in the DLL,
        //or calculate the PERL_HASH in makefile.pl
        //I will not attempt to do that here and I have no such perl build to
        //test it with
        PERL_HASH(keyStrtVar->hash, (*HVKeysInitStructSlice)[i].str, keyStrtVar->klen);
        //add it to the shared string table, since we have no instances of these hash key
        //names yet in the process, the SV must be saved somewhere, or else
        //the shared string we entered will be deleted by mortal system
        keysv = newSVpvn_share((*HVKeysInitStructSlice)[i].str, keyStrtVar->klen, keyStrtVar->hash);
        keyStrtVar->key = SvPVX(keysv);
        av_push(av, keysv); //dont leak it or let it destruct, when package destructs, the key names
        //destruct, this SV right now is the 1 and only holder of the shared string
        //if this SV is freed, the shared string is removed,
        //see http://perl5.git.perl.org/perl.git/blob/7bef440cec6de046112398f991b1dd7d23689e23:/sv.c#l6250
        }//end block
    }
    if(0){
        apierror:
        croak("%s: PM file doesn't match XS file", MODNAME);
    }
}


void
get(self, num)
SV * self
unsigned long num
PREINIT:
    void * voidPtr = 0;
    char * finalKeyName;
    unsigned long finalKeyNameLen;
CODE:
    if (SvROK((HV*)self) && SvTYPE(SvRV((HV*)self))==SVt_PVHV)
        self = SvRV((HV*)self);
    else
        Perl_croak(aTHX_ "%s: %s is not a hash reference",
            MODNAME "::get",
            "self");
    //this adds some randomness to the hash lookups
#define SWITCHMACRO(num,key) case (num): finalKeyName = #key; finalKeyNameLen = sizeof(#key)-1; break;
    switch(num){
    SWITCHMACRO(1,jiugsdh1)
    SWITCHMACRO(2,iusidfsd2)
    SWITCHMACRO(3,ihfsdgsfg3)
    SWITCHMACRO(4,sudfyf4)
    SWITCHMACRO(5,sfyuihldfss5)
    SWITCHMACRO(6,iuodafohsd6)
    SWITCHMACRO(7,kjsdjdfsj7)
#undef SWITCHMACRO
    default:
        printf("huh?"); exit(1);
    }
    (SV **)voidPtr = hvkc_hv_fetch((HV *)self, "layer1", sizeof("layer1")-1, 0,0);
    if(voidPtr){
        (SV *)voidPtr = *(SV **)voidPtr;
        if (SvROK((SV *)voidPtr)){
            (SV *)voidPtr = SvRV((SV *)voidPtr);
            if (SvTYPE((SV *)voidPtr)==SVt_PVHV) {
                (SV **)voidPtr = hvkc_hv_fetch((HV *)voidPtr, "layer2", sizeof("layer2")-1,0,0);
                if(voidPtr) {
                    (SV *)voidPtr = *(SV **)voidPtr;
                    if (SvROK((SV *)voidPtr)){
                        (SV *)voidPtr = SvRV((SV *)voidPtr);
                        if (SvTYPE((SV *)voidPtr)==SVt_PVHV) {
                            (SV **)voidPtr = hvkc_hv_fetch((HV *)voidPtr, "layer3", sizeof("layer3")-1,0,0);
                            if(voidPtr) {
                                (SV *)voidPtr = *(SV **)voidPtr;
                                if (SvROK((SV *)voidPtr)){
                                    (SV *)voidPtr = SvRV((SV *)voidPtr);
                                    if (SvTYPE((SV *)voidPtr)==SVt_PVHV) {
                                        (SV **)voidPtr = hvkc_hv_fetch((HV *)voidPtr, finalKeyName, finalKeyNameLen,0,0);
                                        if(voidPtr) {
                                            voidPtr = (void *)SvIV(*(SV **)voidPtr);
                                        }
                                        //else stays null
                                    }
                                    else {voidPtr = NULL;}
                                }
                                else {voidPtr = NULL;}
                            }
                            //else stays null
                        }
                        else {voidPtr = NULL;}
                    }
                    else {voidPtr = NULL;}
                }
                //else stays null
            }
            else {voidPtr = NULL;}
        }
        else {voidPtr = NULL;}
    }
    //else stays null
    if(voidPtr != (void *)999) {//do something with the data
        printf("wrong number at end of hash tree");
        exit(1);
    }

void
getKC(self, num)
SV * self
unsigned long num
PREINIT:
    void * voidPtr = 0;
CODE:
    if (SvROK((HV*)self) && SvTYPE(SvRV((HV*)self))==SVt_PVHV)
        self = SvRV((HV*)self);
    else
        Perl_croak(aTHX_ "%s: %s is not a hash reference",
            MODNAME "::getKC",
            "self");
    (SV **)voidPtr = hvkc_hv_fetch_kc((HV *)self, layer1,0);
    if(voidPtr){
        (SV *)voidPtr = *(SV **)voidPtr;
        if (SvROK((SV *)voidPtr)){
            (SV *)voidPtr = SvRV((SV *)voidPtr);
            if (SvTYPE((SV *)voidPtr)==SVt_PVHV) {
                (SV **)voidPtr = hvkc_hv_fetch_kc((HV *)voidPtr, layer2,0);
                if(voidPtr) {
                    (SV *)voidPtr = *(SV **)voidPtr;
                    if (SvROK((SV *)voidPtr)){
                        (SV *)voidPtr = SvRV((SV *)voidPtr);
                        if (SvTYPE((SV *)voidPtr)==SVt_PVHV) {
                            (SV **)voidPtr = hvkc_hv_fetch_kc((HV *)voidPtr, layer3,0);
                            if(voidPtr) {
                                (SV *)voidPtr = *(SV **)voidPtr;
                                if (SvROK((SV *)voidPtr)){
                                    (SV *)voidPtr = SvRV((SV *)voidPtr);
                                    if (SvTYPE((SV *)voidPtr)==SVt_PVHV) {
                                        num -= 1; //the array is 0 based
                                        (SV **)voidPtr = hvkc_hv_fetch((HV *)voidPtr, HVKC_ARR_KEY(num), HVKC_ARR_KLEN(num), 0, HVKC_ARR_HASH(num));
                                        if(voidPtr) {
                                            voidPtr = (void *)SvIV(*(SV **)voidPtr);
                                        }
                                        //else stays null
                                    }
                                    else {voidPtr = NULL;}
                                }
                                else {voidPtr = NULL;}
                            }
                            //else stays null
                        }
                        else {voidPtr = NULL;}
                    }
                    else {voidPtr = NULL;}
                }
                //else stays null
            }
            else {voidPtr = NULL;}
        }
        else {voidPtr = NULL;}
    }
    //else stays null
    if(voidPtr != (void *)999) {//do something with the data
        printf("wrong number at end of hash tree");
        exit(1);
    }

