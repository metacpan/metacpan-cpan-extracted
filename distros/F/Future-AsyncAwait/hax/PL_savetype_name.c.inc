/* vi: set ft=c : */

static char *PL_savetype_name[] PERL_UNUSED_DECL = {
  /* These have been present since 5.16 */
  [SAVEt_ADELETE]             = "ADELETE",
  [SAVEt_AELEM]               = "AELEM",
  [SAVEt_ALLOC]               = "ALLOC",
  [SAVEt_APTR]                = "APTR",
  [SAVEt_AV]                  = "AV",
  [SAVEt_BOOL]                = "BOOL",
  [SAVEt_CLEARSV]             = "CLEARSV",
  [SAVEt_COMPILE_WARNINGS]    = "COMPILE_WARNINGS",
  [SAVEt_COMPPAD]             = "COMPPAD",
  [SAVEt_DELETE]              = "DELETE",
  [SAVEt_DESTRUCTOR]          = "DESTRUCTOR",
  [SAVEt_DESTRUCTOR_X]        = "DESTRUCTOR_X",
  [SAVEt_FREECOPHH]           = "FREECOPHH",
  [SAVEt_FREEOP]              = "FREEOP",
  [SAVEt_FREEPV]              = "FREEPV",
  [SAVEt_FREESV]              = "FREESV",
  [SAVEt_GENERIC_PVREF]       = "GENERIC_PVREF",
  [SAVEt_GENERIC_SVREF]       = "GENERIC_SVREF",
  [SAVEt_GP]                  = "GP",
  [SAVEt_GVSV]                = "GVSV",
  [SAVEt_HELEM]               = "HELEM",
  [SAVEt_HINTS]               = "HINTS",
  [SAVEt_HPTR]                = "HPTR",
  [SAVEt_HV]                  = "HV",
  [SAVEt_I16]                 = "I16",
  [SAVEt_I32]                 = "I32",
  [SAVEt_I32_SMALL]           = "I32_SMALL",
  [SAVEt_I8]                  = "I8",
  [SAVEt_INT]                 = "INT",
  [SAVEt_INT_SMALL]           = "INT_SMALL",
  [SAVEt_ITEM]                = "ITEM",
  [SAVEt_IV]                  = "IV",
#ifdef SAVEt_LONG  /* removed by perl 5.41.3 */
  [SAVEt_LONG]                = "LONG",
#endif
  [SAVEt_MORTALIZESV]         = "MORTALIZESV",
  [SAVEt_NSTAB]               = "NSTAB",
  [SAVEt_OP]                  = "OP",
  [SAVEt_PADSV_AND_MORTALIZE] = "PADSV_AND_MORTALIZE",
  [SAVEt_PARSER]              = "PARSER",
  [SAVEt_PPTR]                = "PPTR",
  [SAVEt_REGCONTEXT]          = "REGCONTEXT",
  [SAVEt_SAVESWITCHSTACK]     = "SAVESWITCHSTACK",
  [SAVEt_SET_SVFLAGS]         = "SET_SVFLAGS",
  [SAVEt_SHARED_PVREF]        = "SHARED_PVREF",
  [SAVEt_SPTR]                = "SPTR",
  [SAVEt_STACK_POS]           = "STACK_POS",
  [SAVEt_SVREF]               = "SVREF",
  [SAVEt_SV]                  = "SV",
  [SAVEt_VPTR]                = "VPTR",

#if HAVE_PERL_VERSION(5,18,0)
  [SAVEt_CLEARPADRANGE]       = "CLEARPADRANGE",
  [SAVEt_GVSLOT]              = "GVSLOT",
#endif

#if HAVE_PERL_VERSION(5,20,0)
  [SAVEt_READONLY_OFF]        = "READONLY_OFF",
  [SAVEt_STRLEN]              = "STRLEN",
#endif

#if HAVE_PERL_VERSION(5,22,0)
  [SAVEt_FREEPADNAME]         = "FREEPADNAME",
#endif

#if HAVE_PERL_VERSION(5,24,0)
  [SAVEt_TMPSFLOOR]           = "TMPSFLOOR",
#endif

#if HAVE_PERL_VERSION(5,34,0)
  [SAVEt_STRLEN_SMALL]        = "STRLEN_SMALL",
  [SAVEt_HINTS_HH]            = "HINTS_HH",
#endif
};
