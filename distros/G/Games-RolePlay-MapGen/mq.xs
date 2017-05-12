#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

struct point { double x,y; int m; };

#define X(a) (SvNV(*av_fetch(a,0,0)))
#define Y(a) (SvNV(*av_fetch(a,1,0)))

#define LOS     1
#define ALL_LHS 2
#define ALL_RHS 4

// AV *av_fwc(AV *a, int i) {{{
AV *av_fwc(AV *a, int i) {
    SV *s = *av_fetch(a,i,0);
    AV *x = (AV *) SvRV(s);

    if ((!SvROK(s)) || (SvTYPE(x) != SVt_PVAV))
        croak("bad element (wrong type) in line segment array while processing from _std_intersect_loop()");

    if (av_len(x) != 1)
        croak("bad element (wrong size) in line segment array while processing from _std_intersect_loop()");

    return x;
}
// }}}
// int intersect(struct point A, struct point B, struct point C, struct point D) {{{
int intersect(struct point A, struct point B, struct point C, struct point D) {
    double d,p;
    // fprintf(stderr, "[xs] A(%9.6f,%9.6f) B(%9.6f,%9.6f) C(%9.6f,%9.6f) D(%9.6f,%9.6f)", A.x,A.y, B.x,B.y, C.x,C.y, D.x,D.y);

    // perl // # P = p*A + (1-p)*B
    // perl // # Q = q*C + (1-q)*D
    // perl // 
    // perl // # for p=0, P=A, and for p=1, P=B
    // perl // # for 0<=p<=1, P is on the line segment between A and B
    // perl // 
    // perl // # find p,q such than P=Q
    // perl // # (... lengthy derivation ...)
    // perl // 
    // perl // my $d = ($ax-$bx)*($cy-$dy) - ($ay-$by)*($cx-$dx);

    d = (A.x-B.x)*(C.y-D.y) - (A.y-B.y)*(C.x-D.x);
    // fprintf(stderr, " d=%f", d);

    // perl // if( $cx == $dx and $cy == $dy ) {
    // perl //     # 6/25/7 we're a point on the rhs ... apparently this happens when you remove the extrude shortcutting
    // perl // 
    // perl //     if( $ay == $by and $cy == $ay ) {
    // perl //         return ($cx, $cy) if $ax <= $cx and $cx <= $bx;
    // perl // 
    // perl //     } elsif( $ax == $bx and $cx == $ax ) {
    // perl //         return ($cx, $cy) if $ay <= $cy and $cy <= $by;
    // perl //     }
    // perl // 
    // perl //     die "probably a bug";
    // perl // }

    if( C.x == D.x && C.y == D.y ) {
        if( A.y == B.y && C.y == A.y ) {
            if( A.x <= C.x && C.x <= B.x ) 
                return 1;

        } else if( A.x == B.x && C.x == A.x ) {
            if( A.y <= C.y && C.y <= B.y )
                return 1;
        }

        die("probably a bug");
    }

    if( d == 0 ) {
        // perl // if( $d == 0 ) {
        // perl //     # d=0 when len(C->D)==0 !!
        // perl //     for my $l ([$ax,$ay], [$bx, $by]) {
        // perl //     for my $r ([$cx,$cy], [$dx, $dy]) {
        // perl //         return (@$l) if $l->[0] == $r->[0] and $l->[1] == $r->[1];
        // perl //     }}

        if( (A.x == C.x && A.y == C.y) || (B.x == C.x && B.y == C.y) || (A.x == D.x && A.y == D.y) || (B.x == D.x && B.y == D.y) )
            return 1;

        // perl // 
        // perl //     # NOTE: another huge bug from 6/23/7 !! This vertical overlap was totally overlooked before.
        // perl //     # This is arguably not the most efficient way to check it, but it's literally better than *nothing*
        // perl //     if( fabs($ax-$bx)<0.0001 and fabs($bx-$cx)<0.0001 and fabs($cx-$dx)<0.0001 ) {
        // perl //         return ($cx,$cy) if $ay <= $cy and $cy <= $by;
        // perl //         return ($dx,$dy) if $ay <= $dy and $dy <= $by;
        // perl // 
        if( fabs(A.x-B.x)<0.0001 && fabs(B.x-C.x)<0.0001 && fabs(C.x-D.x)<0.0001 ) {
            if( (A.y<=C.y && C.y<=B.y) || (A.y<=D.y && D.y<=B.y) )
                return 1;
        }

        // perl //     # 6/25/7 -- sorta the same deal as above, but horizontal
        // perl //     } elsif( fabs($ay-$by)<0.0001 and fabs($by-$cy)<0.0001 and fabs($cy-$dy)<0.0001 ) {
        // perl //         return ($cx,$cy) if $ax <= $cx and $cx <= $bx;
        // perl //         return ($dx,$dy) if $ax <= $dx and $dx <= $bx;
        // perl //     }
        if( fabs(A.y-B.y)<0.0001 && fabs(B.y-C.y)<0.0001 && fabs(C.y-D.y)<0.0001 ) {
            if( (A.x<=C.x && C.x<=B.x) || (A.x<=D.x && D.x<=B.x) )
                return 1;
        }

        // perl //     ## DEBUG ## warn "\t\tlsi p=||\n";
        // perl //     return; # probably parallel
        // perl // }
        return 0;
    }

    // perl // my $p = ( ($by-$dy)*($cx-$dx) - ($bx-$dx)*($cy-$dy) ) / $d;

    p = ( (B.y-D.y)*(C.x-D.x) - (B.x-D.x)*(C.y-D.y) ) / d;
    // fprintf(stderr, " p=%f", p);

    // perl // ## NOTE: this was an effin hard bug to find...
    // perl // ## my @w = ( ( ($p <= 1) ? 1:0 ), ( ($p == 1) ? 1:0 ), ( ($p != 1) ? 1:0 ), ( ($p  - 1) ),);
    // perl // ## warn "\t\tlsi p=$p (@w)\n";
    // perl // ## lsi p-1 = 2.22044604925031e-16 = 1?  No, not actually, sometimes...
    // perl // 
    // perl // $p = 0 if fabs($p)   < 0.00001; # fixed 6/23/7
    // perl // $p = 1 if fabs($p-1) < 0.00001;

    if( fabs(p)   < 0.00001 ) p = 0;
    if( fabs(p-1) < 0.00001 ) p = 1;

    // fprintf(stderr, " p=%f\n", p);

    // perl // ## DEBUG ## warn "\t\tlsi p=$p\n";
    // perl // 
    // perl // # we probably don't need to find q because we already restricted the domain/range above
    // perl // return unless $p >= 0 and $p <= 1;

    if( p>=0 && p<=1 ) // reversed this logic
        return 1;

    // perl // 
    // perl // my $px = $p*$ax + (1-$p)*$bx;
    // perl // my $py = $p*$ay + (1-$p)*$by;
    // perl // 
    // perl // return ($px, $py);

    return 0; // reversed this logic
}
// }}}
// int inner_any_any(struct point *lps, struct point *rps, struct point *op1, struct point *op2, int strategy) {{{
int inner_any_any(struct point *lps, struct point *rps, struct point *op1, struct point *op2, int strategy) {
    int i,j,k;
    int l,r,o;
    int blocked;

    l=lps[0].m; r=rps[0].m; o=op1[0].m;

    if( strategy ) {
        for(i=0; i<=l; i++) {
        for(j=0; j<=r; j++) {
            blocked = 0;
            for(k=0; k<=o; k++) {
                if( intersect(op1[k], op2[k], lps[i], rps[j]) ) {
                    blocked ++;
                    break;
                }
            }

            if( !blocked )
                return 1;
        }}

    } else {
        for(i=0; i<=l; i++) {
        for(j=0; j<=r; j++) {
            blocked = 0;
            for(k=0; k<=o; k++) {
                if( intersect(op1[k], op2[k], lps[i], rps[j]) ) {
                    blocked ++; break;
                }
            }

            if( blocked )
                return 1;
        }}
    }

    return 0;
}
// }}}
// int inner_any_all(struct point *lps, struct point *rps, struct point *op1, struct point *op2, int strategy) {{{
int inner_any_all(struct point *lps, struct point *rps, struct point *op1, struct point *op2, int strategy) {
    int i,j,k;
    int l,r,o;
    int blocked;
    int c;

    l=lps[0].m; r=rps[0].m; o=op1[0].m;

    if( strategy ) {
        for(i=0; i<=l; i++) { c=0;
            for(j=0; j<=r; j++) {
                blocked = 0;
                for(k=0; k<=o; k++) {
                    if( intersect(op1[k], op2[k], lps[i], rps[j]) ) {
                        blocked ++;
                        break;
                    }
                }

                if( !blocked )
                    c++;
            }

            // fprintf(stderr, "\e[1;30m[%0.4f,%0.4f] c=%d;j=%d\e[m\n", lps[i].x,lps[i].y, c,j );

            if( c==j )
                return 1;
        }

    } else {
        for(i=0; i<=l; i++) { c=0;
            for(j=0; j<=r; j++) {
                blocked = 0;
                for(k=0; k<=o; k++) {
                    if( intersect(op1[k], op2[k], lps[i], rps[j]) ) {
                        blocked ++;
                        break;
                    }
                }

                if( blocked )
                    c++;
            }

            if( c==j )
                return 1;
        }
    }

    return 0;
}
// }}}
// int inner_all_any(struct point *lps, struct point *rps, struct point *op1, struct point *op2, int strategy) {{{
int inner_all_any(struct point *lps, struct point *rps, struct point *op1, struct point *op2, int strategy) {
    int i,j,k;
    int l,r,o;
    int blocked;
    int c = 0;

    l=lps[0].m; r=rps[0].m; o=op1[0].m;

    if( strategy ) {
        for(j=0; j<=r; j++) { c=0;
            for(i=0; i<=l; i++) {
                blocked = 0;
                for(k=0; k<=o; k++) {
                    if( intersect(op1[k], op2[k], lps[i], rps[j]) ) {
                        blocked ++;
                        break;
                    }
                }

                if( !blocked )
                    c++;
            }

            if( c==j )
                return 1;
        }

    } else {
        for(j=0; j<=r; j++) { c=0;
            for(i=0; i<=l; i++) {
                blocked = 0;
                for(k=0; k<=o; k++) {
                    if( intersect(op1[k], op2[k], lps[i], rps[j]) ) {
                        blocked ++;
                        break;
                    }
                }

                if( blocked )
                    c++;
            }

            if( c==j )
                return 1;
        }
    }

    return 0;
}
// }}}
// int inner_all_all(struct point *lps, struct point *rps, struct point *op1, struct point *op2, int strategy) {{{
int inner_all_all(struct point *lps, struct point *rps, struct point *op1, struct point *op2, int strategy) {
    int i,j,k;
    int l,r,o;
    int blocked;

    l=lps[0].m; r=rps[0].m; o=op1[0].m;

    if( strategy ) {
        for(i=0; i<=l; i++) {
            for(j=0; j<=r; j++) {
                for(k=0; k<=o; k++) {
                    if( intersect(op1[k], op2[k], lps[i], rps[j]) )
                        return 0; // if any one segment blocks any rhs (or lhs) ... 0!!
                }
            }
        }

    } else {
        for(i=0; i<=l; i++) {
            for(j=0; j<=r; j++) {
                blocked = 0;
                for(k=0; k<=o; k++) {
                    if( intersect(op1[k], op2[k], lps[i], rps[j]) ) {
                        blocked = 1; // here though, we can mis one or two
                        break;
                    }
                }

                if( !blocked ) // as long as each lhs and rhs are blocked by something
                    return 0;
            }
        }
    }

    return 1;
}
// }}}
// int std_loop(SV *sv_lhs, SV*sv_rhs, SV*sv_ods, int strategy) {{{
int std_loop(SV *sv_lhs, SV*sv_rhs, SV*sv_ods, int strategy) {
    AV *lhs, *rhs, *ods;
    int l,r,o;
    int i,j,k;

    struct point *lps, *rps, *op1, *op2;
    AV *t1,*t2;

    int ret = -1;

    // fprintf(stderr, "beg std_loop(strategy=%d)\n", strategy);

    if ((!SvROK(sv_lhs)) || (SvTYPE(lhs = (AV*)SvRV(sv_lhs)) != SVt_PVAV)) croak("first argument to _std_intersect_loop() isn't an arrayref");
    if ((!SvROK(sv_rhs)) || (SvTYPE(rhs = (AV*)SvRV(sv_rhs)) != SVt_PVAV)) croak("second argument to _std_intersect_loop() isn't an arrayref");
    if ((!SvROK(sv_ods)) || (SvTYPE(ods = (AV*)SvRV(sv_ods)) != SVt_PVAV)) croak("third argument to _std_intersect_loop() isn't an arrayref");

    l = av_len(lhs); r = av_len(rhs); o = av_len(ods);

    if( l<0 || r<0 ) croak("the lhs and rhs arrays must have locations in them");

    if( o>=0 ) {
        lps = calloc(l+1, sizeof(struct point)); rps = calloc(r+1, sizeof(struct point));
        op1 = calloc(o+1, sizeof(struct point)); op2 = calloc(o+1, sizeof(struct point));

        lps[0].m = l; rps[0].m = r; op1[0].m = o;

        for(i=0; i<=l; i++) { t1 = av_fwc(lhs,i); lps[i].x = X(t1); lps[i].y = Y(t1); }
        for(j=0; j<=r; j++) { t1 = av_fwc(rhs,j); rps[j].x = X(t1); rps[j].y = Y(t1); }
        for(k=0; k<=o; k++) {
            t1 = (AV *)SvRV(*av_fetch(ods,k,0));
            t2 = av_fwc(t1,0); op1[k].x = X(t2); op1[k].y = Y(t2);
            t2 = av_fwc(t1,1); op2[k].x = X(t2); op2[k].y = Y(t2);
        }

        // printf("SET\n");
        // for(i=0; i<=l; i++) { printf("[%f,%f]\n", lps[i].x, lps[i].y); }
        // for(j=0; j<=l; j++) { printf("[%f,%f]\n", rps[j].x, rps[j].y); }
        // printf("DONE\n");

        // fprintf(stderr, "\e[1;30m strategy=%d \e[m", strategy);

        if( strategy & ALL_RHS && strategy & ALL_LHS ) {
            ret = inner_all_all(lps,rps,op1,op2, strategy & LOS);

        } else if( strategy & ALL_LHS ) {
            ret = inner_all_any(lps,rps,op1,op2, strategy & LOS);

        } else if( strategy & ALL_RHS ) {
            ret = inner_any_all(lps,rps,op1,op2, strategy & LOS);

        } else {
            ret = inner_any_any(lps,rps,op1,op2, strategy & LOS);
        }

        free(lps); free(rps); free(op1); free(op2);

    } else {
        ret = (strategy & LOS ) ? 1:0;
    }

    return ret;
}
// }}}

MODULE = Games::RolePlay::MapGen PACKAGE = Games::RolePlay::MapGen::MapQueue
PROTOTYPES: ENABLE

int
any_any_intersect_loop(sv_lhs,sv_rhs,sv_ods)
    SV *sv_lhs
    SV *sv_rhs
    SV *sv_ods

    CODE:
    RETVAL = std_loop(sv_lhs,sv_rhs,sv_ods,0);

    OUTPUT:
    RETVAL

int
any_any_los_loop(sv_lhs,sv_rhs,sv_ods)
    SV *sv_lhs
    SV *sv_rhs
    SV *sv_ods

    CODE:
    RETVAL = std_loop(sv_lhs,sv_rhs,sv_ods,LOS);

    OUTPUT:
    RETVAL

int
any_all_intersect_loop(sv_lhs,sv_rhs,sv_ods)
    SV *sv_lhs
    SV *sv_rhs
    SV *sv_ods

    CODE:
    RETVAL = std_loop(sv_lhs,sv_rhs,sv_ods,ALL_RHS);

    OUTPUT:
    RETVAL

int
any_all_los_loop(sv_lhs,sv_rhs,sv_ods)
    SV *sv_lhs
    SV *sv_rhs
    SV *sv_ods

    CODE:
    RETVAL = std_loop(sv_lhs,sv_rhs,sv_ods,ALL_RHS+LOS);

    OUTPUT:
    RETVAL

int
all_any_intersect_loop(sv_lhs,sv_rhs,sv_ods)
    SV *sv_lhs
    SV *sv_rhs
    SV *sv_ods

    CODE:
    RETVAL = std_loop(sv_lhs,sv_rhs,sv_ods,ALL_LHS);

    OUTPUT:
    RETVAL

int
all_any_los_loop(sv_lhs,sv_rhs,sv_ods)
    SV *sv_lhs
    SV *sv_rhs
    SV *sv_ods

    CODE:
    RETVAL = std_loop(sv_lhs,sv_rhs,sv_ods,ALL_LHS+LOS);

    OUTPUT:
    RETVAL

int
all_all_intersect_loop(sv_lhs,sv_rhs,sv_ods)
    SV *sv_lhs
    SV *sv_rhs
    SV *sv_ods

    CODE:
    RETVAL = std_loop(sv_lhs,sv_rhs,sv_ods,ALL_RHS+ALL_LHS);

    OUTPUT:
    RETVAL

int
all_all_los_loop(sv_lhs,sv_rhs,sv_ods)
    SV *sv_lhs
    SV *sv_rhs
    SV *sv_ods

    CODE:
    RETVAL = std_loop(sv_lhs,sv_rhs,sv_ods,ALL_RHS+ALL_LHS+LOS);

    OUTPUT:
    RETVAL
