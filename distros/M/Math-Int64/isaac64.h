

/*

ISAAC64 Random number generator based on code by Bob Jenkins on the public domain

See http://burtleburtle.net/bob/rand/isaacafa.html

*/

#define RANDSIZL   (8)
#define RANDSIZ    (1<<RANDSIZL)

struct isaac64_state {
    uint64_t randrsl[RANDSIZ], randcnt;
    uint64_t mm[RANDSIZ];
    uint64_t aa, bb, cc;
};

typedef struct isaac64_state isaac64_state_t;

#define ind(mm,x)  (*(uint64_t *)((unsigned char *)(mm) + ((x) & ((RANDSIZ-1)<<3))))
#define rngstep(mix,a,b,mm,m,m2,r,x)            \
    {                                           \
        x = *m;                                 \
        a = (mix) + *(m2++);                    \
        *(m++) = y = ind(mm,x) + a + b;         \
        *(r++) = b = ind(mm,y>>RANDSIZL) + x;   \
    }

void isaac64(isaac64_state_t *is) {
    uint64_t a,b,x,y,*m,*m2,*r,*mend;
    m=is->mm; r=is->randrsl;
    a = is->aa; b = is->bb + (++is->cc);
    for (m = is->mm, mend = m2 = m+(RANDSIZ/2); m<mend; )
    {
        rngstep(~(a^(a<<21)), a, b, is->mm, m, m2, r, x);
        rngstep(  a^(a>>5)  , a, b, is->mm, m, m2, r, x);
        rngstep(  a^(a<<12) , a, b, is->mm, m, m2, r, x);
        rngstep(  a^(a>>33) , a, b, is->mm, m, m2, r, x);
    }
    for (m2 = is->mm; m2<mend; )
    {
        rngstep(~(a^(a<<21)), a, b, is->mm, m, m2, r, x);
        rngstep(  a^(a>>5)  , a, b, is->mm, m, m2, r, x);
        rngstep(  a^(a<<12) , a, b, is->mm, m, m2, r, x);
        rngstep(  a^(a>>33) , a, b, is->mm, m, m2, r, x);
    }
    is->bb = b; is->aa = a;
}

#define mix(a,b,c,d,e,f,g,h)                    \
    {                                           \
        a-=e; f^=h>>9;  h+=a;                   \
        b-=f; g^=a<<9;  a+=b;                   \
        c-=g; h^=b>>23; b+=c;                   \
        d-=h; a^=c<<15; c+=d;                   \
        e-=a; b^=d>>14; d+=e;                   \
        f-=b; c^=e<<20; e+=f;                   \
        g-=c; d^=f>>17; f+=g;                   \
        h-=d; e^=g<<14; g+=h;                   \
    }

void randinit(isaac64_state_t *is, int flag) {
    int  i;
    uint64_t a,b,c,d,e,f,g,h;
    is->aa=is->bb=is->cc=(uint64_t)0;
#ifdef _MSC_VER
    a=b=c=d=e=f=g=h=0x9e3779b97f4a7c13;     /* the golden ratio */
#else
    a=b=c=d=e=f=g=h=0x9e3779b97f4a7c13LLU;  /* the golden ratio */
#endif

    for (i=0; i<4; ++i)                    /* scramble it */
    {
        mix(a,b,c,d,e,f,g,h);
    }

    for (i=0; i<RANDSIZ; i+=8)   /* fill in mm[] with messy stuff */
    {
        if (flag)                  /* use all the information in the seed */
        {
            a+=is->randrsl[i  ]; b+=is->randrsl[i+1]; c+=is->randrsl[i+2]; d+=is->randrsl[i+3];
            e+=is->randrsl[i+4]; f+=is->randrsl[i+5]; g+=is->randrsl[i+6]; h+=is->randrsl[i+7];
        }
        mix(a,b,c,d,e,f,g,h);
        is->mm[i  ]=a; is->mm[i+1]=b; is->mm[i+2]=c; is->mm[i+3]=d;
        is->mm[i+4]=e; is->mm[i+5]=f; is->mm[i+6]=g; is->mm[i+7]=h;
    }
    
    if (flag) 
    {        /* do a second pass to make all of the seed affect all of mm */
        for (i=0; i<RANDSIZ; i+=8)
        {
            a+=is->mm[i  ]; b+=is->mm[i+1]; c+=is->mm[i+2]; d+=is->mm[i+3];
            e+=is->mm[i+4]; f+=is->mm[i+5]; g+=is->mm[i+6]; h+=is->mm[i+7];
            mix(a,b,c,d,e,f,g,h);
            is->mm[i  ]=a; is->mm[i+1]=b; is->mm[i+2]=c; is->mm[i+3]=d;
            is->mm[i+4]=e; is->mm[i+5]=f; is->mm[i+6]=g; is->mm[i+7]=h;
        }
    }

    isaac64(is);     /* fill in the first set of results */
    is->randcnt=RANDSIZ; /* prepare to use the first set of results */
}

static uint64_t
rand64(isaac64_state_t *is) {
    if( ! is->randcnt--) {
        isaac64(is);
        is->randcnt = RANDSIZ-1;
    }
    return is->randrsl[is->randcnt];
}
