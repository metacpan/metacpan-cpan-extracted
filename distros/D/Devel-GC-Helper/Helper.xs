#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


/* Global Data */

#define MY_CXT_KEY "Devel::GC::Helper::_guts" XS_VERSION

typedef struct {
  /* Put Global Data in here */
    int dummy;		/* you can access this elsewhere as MY_CXT.dummy */
} my_cxt_t;

START_MY_CXT

void gc_note_sv (PTR_TBL_t* tbl, SV* sstr);

void walk_stack (PTR_TBL_t* tbl, PERL_SI* si) {
  if (!si)
    return;

  if(ptr_table_fetch(tbl, si))
    return;
  ptr_table_store(tbl, si, (void*)1);


  gc_note_sv(tbl, (SV*) si->si_stack);
  walk_stack(tbl, si->si_prev);
  walk_stack(tbl, si->si_next);

}

void walk_ops (PTR_TBL_t* tbl, OP *o) {
  if (!o)
    return;

  if(ptr_table_fetch(tbl, o))
    return;
  ptr_table_store(tbl, o, (void*)1);
  for (; o; o = o->op_next) {
    switch (o->op_type) {
    case OP_ENTERLOOP:
    case OP_ENTERITER:
      walk_ops(tbl, cLOOPx(o)->op_redoop);
      walk_ops(tbl, cLOOPx(o)->op_nextop);
      walk_ops(tbl, cLOOPx(o)->op_lastop);
      break;
    case OP_QR:
    case OP_MATCH:
    case OP_SUBST:
      walk_ops(tbl, cPMOPx(o)->op_pmreplstart);
      break;
    case OP_MAPWHILE:
    case OP_AND:
    case OP_OR:
    case OP_ANDASSIGN:
    case OP_ORASSIGN:
    case OP_COND_EXPR:
    case OP_RANGE:
      walk_ops(tbl, (cLOGOPx(o)->op_other));
      break;
    }
  }
}

#include "regcomp.h"

void gc_note_re (PTR_TBL_t* tbl, REGEXP* r) {
  int i, len, npar;
  struct reg_substr_datum *s;

  if (!r)
    return;


  for (i = 0; i < 3; i++) {
    gc_note_sv(tbl, (SV*)r->substrs->data[i].substr);
    gc_note_sv(tbl, (SV*)r->substrs->data[i].utf8_substr);
  }

  if (r->data) {
    struct reg_data *d;
    const int count = r->data->count;

    for (i = 0; i < count; i++) {
      switch (r->data->what[i]) {
      case 's':
      case 'p':
        gc_note_sv(tbl, r->data->data[i]);
        break;
      }
    }
  }

}


void gc_note_mg (PTR_TBL_t* tbl, MAGIC* mg) {
  if (!mg)
    return;;

  for (; mg; mg = mg->mg_moremagic) {
    if (mg->mg_type == PERL_MAGIC_qr) {
      gc_note_re(tbl, (REGEXP*)mg->mg_obj);
    } else {
      gc_note_sv(tbl, mg->mg_obj);
    }
  }
}



void gc_note_sv (PTR_TBL_t* tbl, SV* sstr) {

  if (!sstr || SvTYPE(sstr) == SVTYPEMASK)
    return;

  /* look for it in the table first */
  if(ptr_table_fetch(tbl, sstr)) {
    return;
  }

  ptr_table_store(tbl, sstr, (void*)1);

  switch (SvTYPE(sstr)) {
  case SVt_RV:
  case SVt_PV:
  case SVt_PVIV:
  case SVt_PVNV:
    if (SvROK(sstr) && !SvWEAKREF(sstr))
      gc_note_sv(tbl, SvRV(sstr));       /** TODO WEAKREFS? **/
    break;
  case SVt_PVMG:
    gc_note_sv(tbl, (SV*) SvSTASH(sstr));
    if (SvROK(sstr) && !SvWEAKREF(sstr))
      gc_note_sv(tbl, SvRV(sstr));       /** TODO WEAKREFS? **/
    gc_note_mg(tbl, SvMAGIC(sstr));
    break;
  case SVt_PVBM:
    gc_note_sv(tbl, (SV*) SvSTASH(sstr));
    gc_note_mg(tbl, SvMAGIC(sstr));
    if (SvROK(sstr) && !SvWEAKREF(sstr))
      gc_note_sv(tbl, SvRV(sstr));
    break;
  case SVt_PVLV:
    gc_note_sv(tbl, (SV*) SvSTASH(sstr));
    gc_note_mg(tbl, SvMAGIC(sstr));
    if (SvROK(sstr) && !SvWEAKREF(sstr))
      gc_note_sv(tbl, SvRV(sstr));
    if (LvTYPE(sstr) == 'T') 
      /* tied HE */
      gc_note_sv(tbl, HeVAL((HE*)LvTARG(sstr)));
    else
      gc_note_sv(tbl, LvTARG(sstr));
    break;
  case SVt_PVGV:
    gc_note_sv(tbl, (SV*) SvSTASH(sstr));
    if (SvROK(sstr) && !SvWEAKREF(sstr))
      gc_note_sv(tbl, SvRV(sstr));       /** TODO WEAKREFS? **/
    gc_note_sv(tbl, (SV*) GvSTASH(sstr));
    if (GvGP(sstr)) {
      gc_note_sv(tbl, (SV*) GvGP(sstr)->gp_sv);
      gc_note_sv(tbl, (SV*) GvGP(sstr)->gp_io);
      gc_note_sv(tbl, (SV*) GvGP(sstr)->gp_form);
      gc_note_sv(tbl, (SV*) GvGP(sstr)->gp_av);
      gc_note_sv(tbl, (SV*) GvGP(sstr)->gp_hv);
      gc_note_sv(tbl, (SV*) GvGP(sstr)->gp_egv);
      gc_note_sv(tbl, (SV*) GvGP(sstr)->gp_cv);
    }
    gc_note_mg(tbl, SvMAGIC(sstr));
    break;
  case SVt_PVIO:
    gc_note_sv(tbl, (SV*) SvSTASH(sstr));
    if (SvROK(sstr) && !SvWEAKREF(sstr))
      gc_note_sv(tbl, SvRV(sstr));       /** TODO WEAKREFS? **/
    gc_note_mg(tbl, SvMAGIC(sstr));
    gc_note_sv(tbl, (SV*) IoTOP_GV(sstr));
    gc_note_sv(tbl, (SV*) IoFMT_GV(sstr));
    gc_note_sv(tbl, (SV*) IoBOTTOM_GV(sstr));
    break;
  case SVt_PVAV:
    gc_note_sv(tbl, (SV*) SvSTASH(sstr));
    gc_note_sv(tbl,  AvARYLEN((AV*)sstr));
    if (AvARRAY((AV*)sstr)) {
      /** ptr_table_store(PL_ptr_table, src_ary, 1); is this neded? it is not a reall sv is it? **/
      SV **src_ary  = AvARRAY((AV*)sstr);
      SSize_t items = AvFILLp((AV*)sstr) + 1;
      if (AvREAL((AV*)sstr)) {
        while (items-- > 0) {
          gc_note_sv(tbl, *src_ary++);
        }
      }
      else {
        while (items-- > 0)
          gc_note_sv(tbl, *src_ary++);
      }
    }
    gc_note_mg(tbl, SvMAGIC(sstr));
    break;
  case SVt_PVHV: {
    HE* val;
    I32 retlen;
    gc_note_sv(tbl, (SV*) SvSTASH(sstr));
    hv_iterinit((HV*) sstr);
    while (val = hv_iternext_flags((HV*) sstr, HV_ITERNEXT_WANTPLACEHOLDERS)) {
      gc_note_sv(tbl, hv_iterval((HV*) sstr, val));
    }
    gc_note_mg(tbl, SvMAGIC(sstr));
    hv_iterinit((HV*) sstr);
    break;
  }
  case SVt_PVCV:
  case SVt_PVFM:
    gc_note_sv(tbl, (SV*) SvSTASH(sstr));
    if (SvROK(sstr) && !SvWEAKREF(sstr))
      gc_note_sv(tbl, SvRV(sstr));       /** TODO WEAKREFS? **/
    gc_note_sv(tbl, (SV*) CvSTASH(sstr));
    gc_note_sv(tbl, (SV*) CvOUTSIDE(sstr));
    gc_note_sv(tbl, (SV*) CvPADLIST(sstr));
    if (CvCONST(sstr))
      gc_note_sv(tbl, CvXSUBANY(sstr).any_ptr);
    gc_note_mg(tbl, SvMAGIC(sstr));
    gc_note_sv(tbl, (SV*) CvGV(sstr));
    break;
  }
}


PTR_TBL_t*  sweep_root() {
  dTHX;
  PTR_TBL_t *tbl;
  tbl = Perl_ptr_table_new(aTHX);

  ptr_table_store(tbl, &PL_sv_undef, (void*) 1);
  ptr_table_store(tbl, &PL_sv_placeholder, (void*) 1);
  ptr_table_store(tbl, &PL_sv_no, (void*) 1);
  ptr_table_store(tbl, &PL_sv_yes, (void*) 1);

  gc_note_sv(tbl, PL_compiling.cop_io);
  gc_note_sv(tbl, PL_compiling.cop_warnings);


  gc_note_sv(tbl, PL_patchlevel);

  gc_note_sv(tbl, (SV*) PL_defstash);
  gc_note_sv(tbl, (SV*) PL_debstash);
  gc_note_sv(tbl, (SV*) PL_curstash);
  gc_note_sv(tbl, (SV*) PL_globalstash);

  gc_note_sv(tbl, (SV*) PL_envgv);
  gc_note_sv(tbl, (SV*) PL_incgv);
  gc_note_sv(tbl, (SV*) PL_hintgv);

  gc_note_sv(tbl, PL_diehook);
  gc_note_sv(tbl, PL_warnhook);

  gc_note_sv(tbl, (SV*) PL_main_cv);

  gc_note_sv(tbl, PL_e_script);

  gc_note_sv(tbl, PL_formfeed);
  gc_note_sv(tbl, PL_encoding);



  gc_note_sv(tbl, (SV*) PL_stdingv);
  gc_note_sv(tbl, (SV*) PL_stderrgv);
  gc_note_sv(tbl, (SV*) PL_defgv);
  gc_note_sv(tbl, (SV*) PL_argvgv);
  gc_note_sv(tbl, (SV*) PL_argvoutgv);
  gc_note_sv(tbl, (SV*) PL_argvout_stack);

  gc_note_sv(tbl, (SV*) PL_replgv);
  gc_note_sv(tbl, (SV*) PL_errgv);

  gc_note_sv(tbl, (SV*) PL_DBgv);
  gc_note_sv(tbl, (SV*) PL_DBline);
  gc_note_sv(tbl, (SV*) PL_DBsub);
  gc_note_sv(tbl, PL_DBtrace);
  gc_note_sv(tbl, PL_DBsingle);
  gc_note_sv(tbl, PL_DBsignal);
  gc_note_sv(tbl, (SV*) PL_lineary);
  gc_note_sv(tbl, (SV*) PL_dbargs);

  gc_note_sv(tbl, (SV*) PL_debstash);
  gc_note_sv(tbl, (SV*) PL_globalstash);
  gc_note_sv(tbl, PL_curstname);
  gc_note_sv(tbl, (SV*) PL_defstash);
  gc_note_sv(tbl, (SV*) PL_curstash);
  gc_note_sv(tbl, (SV*) PL_nullstash);



  gc_note_sv(tbl, (SV*) PL_beginav);
  gc_note_sv(tbl, (SV*) PL_beginav_save);
  gc_note_sv(tbl, (SV*) PL_checkav_save);
  gc_note_sv(tbl, (SV*) PL_endav);
  gc_note_sv(tbl, (SV*) PL_checkav);
  gc_note_sv(tbl, (SV*) PL_initav);

  gc_note_sv(tbl, (SV*) PL_fdpid);

  gc_note_sv(tbl, PL_mess_sv);

  gc_note_sv(tbl, (SV*) PL_main_cv);

  gc_note_sv(tbl, (SV*) PL_preambleav);

  gc_note_sv(tbl, PL_ors_sv);

  gc_note_sv(tbl, (SV*) PL_modglobal);
  gc_note_sv(tbl, (SV*) PL_custom_op_names);
  gc_note_sv(tbl, (SV*) PL_custom_op_descs);
  gc_note_sv(tbl, (SV*) PL_rsfp_filters);
  gc_note_sv(tbl, (SV*) PL_compcv);


  gc_note_sv(tbl, (SV*) PL_comppad);
  gc_note_sv(tbl, (SV*) PL_comppad_name);

  gc_note_sv(tbl, (SV*) PL_DBcv);

  gc_note_sv(tbl, PL_lex_stuff);
  gc_note_sv(tbl, PL_lex_repl);

  gc_note_sv(tbl, PL_linestr);

  gc_note_sv(tbl, PL_subname);

  gc_note_sv(tbl, (SV*) PL_in_my_stash);

  gc_note_sv(tbl, PL_utf8_alnum);
  gc_note_sv(tbl, PL_utf8_alnumc);
  gc_note_sv(tbl, PL_utf8_ascii);
  gc_note_sv(tbl, PL_utf8_alpha);
  gc_note_sv(tbl, PL_utf8_space);
  gc_note_sv(tbl, PL_utf8_cntrl);
  gc_note_sv(tbl, PL_utf8_graph);
  gc_note_sv(tbl, PL_utf8_digit);
  gc_note_sv(tbl, PL_utf8_upper);
  gc_note_sv(tbl, PL_utf8_lower);
  gc_note_sv(tbl, PL_utf8_print);
  gc_note_sv(tbl, PL_utf8_punct);
  gc_note_sv(tbl, PL_utf8_xdigit);
  gc_note_sv(tbl, PL_utf8_mark);
  gc_note_sv(tbl, PL_utf8_toupper);
  gc_note_sv(tbl, PL_utf8_totitle);
  gc_note_sv(tbl, PL_utf8_tolower);
  gc_note_sv(tbl, PL_utf8_tofold);
  gc_note_sv(tbl, PL_utf8_idstart);
  gc_note_sv(tbl, PL_utf8_idcont);

  gc_note_sv(tbl, (SV*) PL_last_swash_hv);


  if (PL_psig_ptr) {
    I32 i;
    for (i = 1; i < SIG_SIZE; i++) {
      gc_note_sv(tbl,PL_psig_ptr[i]);
      gc_note_sv(tbl,PL_psig_name[i]);
    }
  }
  {
    I32 i = 0;
    while (i <= PL_tmps_ix) {
      gc_note_sv(tbl, PL_tmps_stack[i]);
      ++i;
    }
  }

  gc_note_sv(tbl, (SV*) PL_curstack);
  gc_note_sv(tbl, (SV*) PL_mainstack);

  gc_note_sv(tbl, (SV*) PL_statgv);
  gc_note_sv(tbl, PL_statname);

  gc_note_sv(tbl, PL_nrs);

  gc_note_sv(tbl, PL_rs);
  gc_note_sv(tbl, (SV*) PL_last_in_gv);
  gc_note_sv(tbl, PL_ofs_sv);
  gc_note_sv(tbl, (SV*) PL_defoutgv);
  gc_note_sv(tbl, PL_toptarget);
  gc_note_sv(tbl, PL_bodytarget);
  gc_note_sv(tbl, PL_formtarget);

  gc_note_sv(tbl, PL_errors);

  gc_note_sv(tbl, (SV*) PL_sortstash);
  gc_note_sv(tbl, (SV*) PL_firstgv);
  gc_note_sv(tbl, (SV*) PL_secondgv);

  gc_note_sv(tbl, (SV*) PL_pidstatus);

  gc_note_sv(tbl, PL_lastscream);
  gc_note_sv(tbl, PL_reg_sv);


  gc_note_sv(tbl, (SV*) PL_stashcache);


  ptr_table_store(tbl, (SV*) PL_strtab, (void*) 1);

  gc_note_sv(tbl, PL_numeric_radix_sv);

  {
    I32 i = 0;
    while (i <= PL_tmps_ix)
      gc_note_sv(tbl, PL_tmps_stack[i++]);

    walk_stack(tbl, PL_curstackinfo);
  }

  {
    const I32 len = av_len((AV*)PL_regex_padav);
    SV** const regexen = AvARRAY((AV*)PL_regex_padav);
    IV i;
    for(i = 0; i <= len; i++) {
      if(SvREPADTMP(regexen[i])) {
        gc_note_sv(tbl, regexen[i]);
      } else {
        gc_note_sv(tbl, regexen[i]);
        gc_note_re(tbl, (INT2PTR(REGEXP *, SvIVX(regexen[i]))));
      }
    }
    gc_note_sv(tbl, (SV*) PL_regex_padav);
  }

  return tbl;
}




MODULE = Devel::GC::Helper		PACKAGE = Devel::GC::Helper


BOOT:
{
    MY_CXT_INIT;
    /* If any of the fields in the my_cxt_t struct need
       to be initialised, do it here.
     */
}

SV*
sweep()
PPCODE:
{
  PTR_TBL_t* tbl = sweep_root();
  AV* av = newAV();
  {
    SV* sva;
    I32 visited = 0;
    for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
      register const SV * const svend = &sva[SvREFCNT(sva)];
      SV* svi;
      for (svi = sva + 1; svi < svend; ++svi) {
        if (SvTYPE(svi) != SVTYPEMASK
            && SvREFCNT(svi)
            && svi != (SV*)av
            )
          {
            if (!ptr_table_fetch(tbl, svi)
                && (
                    SvTYPE(svi) == SVt_RV
                    || SvTYPE(svi) == SVt_PVAV
                    || SvTYPE(svi) == SVt_PVHV
                    || SvTYPE(svi) == SVt_PVCV
                    || (SvTYPE(svi) == SVt_PVMG && SvMAGICAL(svi))
                    )
                ) {
              av_push(av, svi);
              SvREFCNT_inc(svi);
              visited++;
            }
          }
      }
    }
    while (visited--) {
      SV** sv = av_fetch(av, visited, (I32)0);
      if(sv) {
        av_store(av, visited, newRV_inc(*sv));
      }
    }
  }
  ST(0) = newRV_noinc((SV*)av);
  sv_2mortal(ST(0));
  XSRETURN(1);
}

