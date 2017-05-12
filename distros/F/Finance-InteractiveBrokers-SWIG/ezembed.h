/*
 *  Finance::InteractiveBrokers::SWIG - Perl/C embedding XS function header
 *
 *  Copyright (c) 2010-2014 Jason McManus
 *
 *  (Borrowed from Advanced Perl Programming, 1st Ed.)
 */

#ifndef EZEMBED_H
#define EZEMBED_H

#ifdef __cplusplus
extern "C" {
#endif 

typedef struct {
    char type;       
    void *pdata;
} Out_Param;

int perl_call_va (const char *subname, ...);

#ifdef __cplusplus
}
#endif 

#endif /* EZEMBED_H */

/* END */
