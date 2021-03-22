#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Status/status.h"
#include "EditOp/editop.h"

#include "sim4.h"
#include "types.h"		/* sim4's types file. */
#include "sim4b1.h"
#include "args.h"
#include "encoding.h"
#include "poly.h"
#include "misc.h"
#include "align.h"
#include "seq.h"

SV *package_sim4_results(int dist, sim4_stats_t *st,
			 edit_script_list *Aligns, Exon *Exons,
			 int match_orienation,
			 char *genomic, char *cDNA);
AV *package_alignment_ops(edit_script_list *Aligns);
AV *package_exons(Exon *Exons);

static int MY_IDISPLAY(uchar A[], uchar B[], int M, int N, int S[], int AP, int BP,
		       int est_strand, Exon *exons,SV *align_SV);
static int format_exon_alignments(uchar A[], uchar B[], int M, int N,
				  int S[], int AP, int BP,
				  int est_strand, Exon *exons, AV *exon_aligns_AV);

static int format_alignments(uchar *seq1, uchar *seq2, int len1, int len2, 
			     edit_script_list **Aligns, Exon *Exons, 
			     int file_type, int match_ori,
			     SV *align_SV, AV* exon_aligns_AV);     
int package_alignment_strings(uchar *genomic, uchar *cDNA,
			      int genomic_len, int cDNA_len,
			      edit_script_list **Aligns,
			      Exon *Exons,
			      int file_type, int match_ori,
			      SV **alignment_string_sv,
			      AV **exon_alignment_strings_av);

sim4_args_t rs;
int file_type;

static int get_char_value(HV *args, char *name, char **val);
static int get_int_value(HV *args, char *name, int *val);
static void init_stats(sim4_stats_t *st);
static uchar *seq_revcomp_helper(uchar *s, int len);
static void add_offset_exons(Exon *,int);
static void add_offset_aligns(edit_script_list *,int);


/*
 * A helper function for the XS routine _sim4
 *
 */

SV *
sim4_helper(char *genomic, char *cDNA, SV *argsRef)
{
  int status = STAT_OK;
  char *status_message = NULL;
  int cost = 0;
  EditOp *eList = NULL;
  SV *rv = NULL;

  argv_scores_t ds;
  ss_t ss;

  struct edit_script_list *Aligns = NULL;
  struct edit_script_list *revAligns = NULL;
  int genomic_len, cDNA_len;
  int dist, revdist;
  int pT, pA;
  int xpT, xpA;
  char *rev_cDNA = NULL;
  int revxpT, revxpA;
  Exon *Exons = NULL;
  Exon *revExons = NULL;
  sim4_stats_t st;
  sim4_stats_t revst;
  int match_orientation;

  file_type = GEN_EST;
  genomic_len = strlen(genomic);
  cDNA_len = strlen(cDNA);

  /* fill up the sim4 argument struct with values from the perl argument
   * hash.
   */
  status = set_sim4_args(&rs, argsRef);
  BailError(status);

  /* initialize the various globals and statics that sim4
   * uses so that they have useful values.
   * -1 is magic, see bld_table....
   */
  bld_table(genomic-1, genomic_len-1, rs.W, INIT); 
  init_stats(&st);
  init_stats(&revst);
  DNA_scores(&ds, ss);
  pT = pA = xpT =  xpA = revxpT = revxpA = 0;


  /* validate the sequence using the sim4 semantics
   * and flail if unacceptable.
   */
  if (!is_DNA(genomic, genomic_len))
    BailErrorMsg(STAT_BAD_ARGS, "The genomic sequence is not a DNA sequence.");
  seq_toupper(genomic, genomic_len, NULL);
        
  if (!is_DNA(cDNA, cDNA_len))
    BailErrorMsg(STAT_BAD_ARGS,"The cDNA sequence is not a DNA sequence.");
  seq_toupper(cDNA, cDNA_len, NULL);

  if (rs.poly_flag && file_type==GEN_EST)  {
    get_polyAT(cDNA, cDNA_len, &pT, &pA, BOTH_AT);
  }

  if ((rs.reverse == 0) || (rs.reverse == 2)) {
    Aligns = SIM4(genomic, cDNA+pT, genomic_len, cDNA_len-pT-pA,
		  rs.W, rs.X, rs.K, rs.C, rs.weight,
		  &dist, &xpT, &xpA, &Exons, &st);
  }
  if ((rs.reverse == 1) || (rs.reverse == 2)) {
    rev_cDNA = malloc(cDNA_len + 1);
    BailNull(rev_cDNA, status);
    rev_cDNA = memcpy(rev_cDNA, cDNA, cDNA_len);
    rev_cDNA[cDNA_len] = '\0'; /* remember to null-terminate the string. */
    rev_cDNA = seq_revcomp_helper(rev_cDNA, cDNA_len);
    revAligns = SIM4(genomic, rev_cDNA+pA, genomic_len, cDNA_len-pT-pA,
		     rs.W, rs.X, rs.K, rs.C, rs.weight,
		     &revdist, &revxpT, &revxpA, &revExons, &revst);
  }
  
  if (revst.nmatches > st.nmatches) {
    match_orientation = BWD;
  }
  else {
    match_orientation = FWD;
  }

  if (rs.poly_flag) {
    if (match_orientation==FWD) {
      add_offset_exons(Exons, pT);  
      add_offset_aligns(Aligns, pT);
    } else {
      add_offset_exons(revExons,(file_type==EST_GEN)?pT:pA); 
      add_offset_aligns(revAligns, (file_type==EST_GEN)?pT:pA);
    }
  } 

  if (match_orientation == BWD) {
    rv = package_sim4_results(revdist, &revst, revAligns, revExons, match_orientation,
			      genomic, rev_cDNA);
  }
  else {
    rv = package_sim4_results(dist, &st, Aligns, Exons, match_orientation,
			      genomic, cDNA);
  }

  if (rev_cDNA)
    free(rev_cDNA);
  free_table();

  return(rv);

 bail:
  if (Aligns) { free_align(Aligns); Aligns = NULL; }
  if (Exons) { free_list(Exons); Exons = NULL; }
  if (rev_cDNA) {
    if (revAligns) { free_align(revAligns); revAligns = NULL; }
    if (revExons) { free_list(revExons); revExons = NULL; }
    free(rev_cDNA);
  }
  free_table();

  Perl_croak(aTHX_ "%s", status_message);
}

SV *
package_sim4_results(int dist, sim4_stats_t *st,
		     edit_script_list *Aligns, Exon *Exons,
		     int match_orientation,
		     char *genomic, char *cDNA)
{
  HV *hv = NULL;
  AV *alignments_av = NULL;
  SV *alignment_string_sv = NULL;
  AV *exon_alignments_av = NULL;
  AV *exons_av = NULL;  
  AV *av = NULL;
  int status = STAT_OK;
  
  int genomic_len;
  int cDNA_len;

  BailNull(Exons, status);	/* make sure there's something to package */
  if (! Exons->length > 0) {
    goto bail;
  }

  genomic_len = strlen(genomic);
  cDNA_len = strlen(cDNA);

  hv = newHV();
  BailNull(hv, status);

  
  /* standard ignore the return value thing...  */
  (void) hv_store(hv, "edit_distance", 13, newSViv(dist), 0);
  (void) hv_store(hv, "coverage_int", 12, newSViv(st->icoverage), 0);
  (void) hv_store(hv, "coverage_float", 14, newSVnv(st->fcoverage), 0);
  (void) hv_store(hv, "exon_count", 10, newSViv(st->mult), 0);
  (void) hv_store(hv, "number_matches", 14, newSViv(st->nmatches), 0);
  (void) hv_store(hv, "marginals", 9, newSViv(st->marginals), 0);
  if (match_orientation == FWD) 
    (void) hv_store(hv, "match_orientation", 17, newSVpv("forward", 0), 0);
  else 
    (void) hv_store(hv, "match_orientation", 17, newSVpv("reverse", 0), 0);
  alignments_av = package_alignment_ops(Aligns);
  BailNull(alignments_av, status);
  (void) hv_store(hv, "alignment_ops", 13, newRV_noinc((SV *) alignments_av), 0);
  
  exons_av = package_exons(Exons);
  BailNull(exons_av, status);
  (void) hv_store(hv, "exons", 5, newRV_noinc((SV *) exons_av), 0);
  
  if (rs.ali_flag ) {
    status = package_alignment_strings(genomic, cDNA,
				       genomic_len, cDNA_len,
				       &Aligns,
				       Exons,
				       GEN_EST, match_orientation,
				       &alignment_string_sv,
				       &exon_alignments_av);

    BailError(status);

    (void) hv_store(hv, "alignment_string", 16, alignment_string_sv, 0);
    (void) hv_store(hv, "exon_alignment_strings", 22,
		    newRV_noinc((SV *) exon_alignments_av), 0);

  }
    
  return(newRV_noinc((SV *) hv)); /* _sim4() takes care of sv_2mortal() */
 bail:
  if (hv) {
    hv_undef(hv);		/* ripple through and destroy as needed */
  }
  return((SV *) &PL_sv_undef); /* _sim4() takes care of sv_2mortal() */
}

AV *
package_exons(Exon *Exon)
{
  AV *av = NULL;
  HV *hv = NULL;
  int status;
  int i;

  av = newAV();
  BailNull(av, status);

  i = 0;
  while(Exon->to1) {
    hv = newHV();
    BailNull(hv, status);
    (void) hv_store(hv, "from1", 5, newSViv(Exon->from1), 0);
    (void) hv_store(hv, "to1", 3, newSViv(Exon->to1), 0);
    (void) hv_store(hv, "from2", 5, newSViv(Exon->from2), 0);
    (void) hv_store(hv, "to2", 3, newSViv(Exon->to2), 0);
    (void) hv_store(hv, "min_diag", 8, newSViv(Exon->min_diag), 0);
    (void) hv_store(hv, "max_diag", 8, newSViv(Exon->max_diag), 0);
    (void) hv_store(hv, "match", 5, newSViv(Exon->match), 0);
    switch (Exon->ori) {
    case 'C':
      (void) hv_store(hv, "ori", 3, newSVpv(" <-", 3), 0);
      break;
    case 'E':
      (void) hv_store(hv, "ori", 3, newSVpv(" ==", 3), 0);
      break;
    case 'G':
      (void) hv_store(hv, "ori", 3, newSVpv(" ->", 3), 0);
      break;
    case 'N':
      (void) hv_store(hv, "ori", 3, newSVpv(" --", 3), 0);
      break;
    case 0:
      (void) hv_store(hv, "ori", 3, &PL_sv_undef, 0);
      break;
    default :
      fatal("sim4_helper.c: Inconsistency. Check exon orientations.");
      break;
    }
    /*    (void) hv_store(hv, "ori", 3, newSViv(Exon->ori), 0); /* XXXX */
    (void) hv_store(hv, "length", 6, newSViv(Exon->length), 0);
    (void) hv_store(hv, "flag", 4, newSViv(Exon->flag), 0);
    (void) hv_store(hv, "ematches", 8, newSViv(Exon->ematches), 0);
    (void) hv_store(hv, "nmatches", 8, newSViv(Exon->nmatches), 0);
    (void) hv_store(hv, "edist", 5, newSViv(Exon->edist), 0);
    (void) hv_store(hv, "alen", 4, newSViv(Exon->alen), 0);    

    (void) av_store(av, i++, newRV_noinc((SV *) hv));

    Exon = Exon->next_exon;
  }

 bail:
  return(av);
}

AV *
package_alignment_ops(edit_script_list *Align)
{
  AV *av = NULL;
  AV *av2 = NULL;
  HV *hv = NULL;
  HV *hv2 = NULL;
  int status = STAT_OK;
  int i = 0;
  int j = 0;
  edit_script *script;
  
  av = newAV();
  BailNull(av, status);

  i = 0;
  while(Align) {
    hv = newHV();
    BailNull(hv, status);
    (void) hv_store(hv, "offset_1", 8, newSViv(Align->offset1), 0);
    (void) hv_store(hv, "len1", 4, newSViv(Align->len1), 0);
    (void) hv_store(hv, "offset_2", 8, newSViv(Align->offset2), 0);
    (void) hv_store(hv, "len2", 4, newSViv(Align->len2), 0);
    (void) hv_store(hv, "score", 5, newSViv(Align->score), 0);

    av2 = newAV();
    BailNull(av2, status);

    j = 0;
    script = Align->script;
    while(script) {
      char *ops[] = {
	"not_used",
	"delete",
	"insert",
	"substitute",
	"intron",
	"o_intron"};
      
      hv2 = newHV();
      BailNull(hv2, status);
      (void) hv_store(hv2, "op_type", 7, newSViv(script->op_type), 0);
      (void) hv_store(hv2, "count", 5, newSViv(script->num), 0);
      (void) hv_store(hv2, "op_label", 8,
		      newSVpv(ops[script->op_type], strlen(ops[script->op_type])), 0);

      (void) av_store(av2, j++, newRV_noinc((SV *) hv2));      
      script = script->next;
    }
    (void) hv_store(hv, "operations", 10, newRV_noinc((SV *) av2), 0);    
    
    (void) av_store(av, i++, newRV_noinc((SV *) hv));
    Align = Align->next_script;
  }
 bail:
  return(av);
}

int
package_alignment_strings(uchar *genomic, uchar *cDNA,
			  int genomic_len, int cDNA_len,
			  edit_script_list **Aligns,
			  Exon *Exons,
			  int file_type, int match_ori,
			  SV **alignment_string_sv,
			  AV **exon_alignment_strings_av)
{
  int status = STAT_OK;
  SV *sv = NULL;
  
  *alignment_string_sv = newSVpv("",0);	/* avoid uninitialized variable warning */
  BailNull(alignment_string_sv, status);
  
  *exon_alignment_strings_av = newAV();
  BailNull(exon_alignment_strings_av, status);

  status = format_alignments(genomic, cDNA, genomic_len, cDNA_len,
			     Aligns, Exons, file_type, match_ori,
			     *alignment_string_sv,
			     *exon_alignment_strings_av);
  BailError(status);
  
  return(status);
 bail:
  /* XXXX LEAK! */
  return(status);
}

/*
 * Mimic sim4's command line processing.  The arguments are in a hash, passed
 * in as a reference.  The hash contains the union of a set of default
 * arguements and user specified values.
 */

int
set_sim4_args(sim4_args_t *rs, SV *argsRef)
{
  int status = STAT_OK;
  char *status_message = "Unspecified error accessing arguments.";
  HV *args = NULL;
  
  /* check that it's really what it should be. */
  if (!argsRef ||
      !SvOK(argsRef) ||
      !SvROK(argsRef) ||
      (SvTYPE(SvRV(argsRef)) != SVt_PVHV))
    BailErrorMsg(STAT_BAD_ARGS, "Argument set isn't a reference to a hash.");
  args = (HV *)SvRV(argsRef);
  
  status = get_int_value(args, "A", &rs->ali_flag); BailError(status);
  if (rs->ali_flag != 0 && rs->ali_flag != 1)
    BailErrorMsg(STAT_BAD_ARGS, "Alignment flag (A) must be 0 or 1.\n");

  status = get_int_value(args, "P", &rs->poly_flag); BailError(status);

  status = get_int_value(args, "R", &rs->reverse); BailError(status);
  if (rs->reverse < 0 || rs->reverse > 2) 
    BailErrorMsg(STAT_BAD_ARGS, "Direction (R) must be 0, 1, or 2.\n");

  status = get_int_value(args, "E", &rs->cutoff); BailError(status);
  if (rs->cutoff < 3 || rs->cutoff > 10) 
    BailErrorMsg(STAT_BAD_ARGS, "Cutoff (E) must be between 3 and 10.");

  status = get_int_value(args, "D", &rs->DRANGE); BailError(status);
  if (rs->DRANGE < 0) 
    BailErrorMsg(STAT_BAD_ARGS, "D must be greater than zero.");

  status = get_int_value(args, "H", &rs->weight); BailError(status);
  rs->set_H = FALSE;
  if (rs->weight < 0) 
    BailErrorMsg(STAT_BAD_ARGS, "H must be greater than zero.");

  status = get_int_value(args, "W", &rs->W); BailError(status);
  if (rs->W < 1 || rs->W > 14) 
    BailErrorMsg(STAT_BAD_ARGS, "Cutoff (W) must be between 1 and 15.");

  status = get_int_value(args, "X", &rs->X); BailError(status);
  if (rs->X < 0) 
    BailErrorMsg(STAT_BAD_ARGS, "X must be greater than 0 (zero).");

  status = get_int_value(args, "K", &rs->K); BailError(status);
  rs->set_K = FALSE;
  if (rs->K < 0) 
    BailErrorMsg(STAT_BAD_ARGS, "K must be greater than 0 (zero).");

  status = get_int_value(args, "C", &rs->C); BailError(status);
  rs->set_C = FALSE;
  if (rs->C < 0) 
    BailErrorMsg(STAT_BAD_ARGS, "C must be greater than 0 (zero).");

  status = get_int_value(args, "N", &rs->acc_flag); BailError(status);

  status = get_int_value(args, "B", &rs->B); BailError(status);
  if (rs->B != 0 && rs->B != 1)
    BailErrorMsg(STAT_BAD_ARGS, "B must be either 0 (zero) or 1 (one).");

  status = get_char_value(args, "S", &rs->S); /* BailError(status); */
  if (rs->S != NULL)
    BailErrorMsg(STAT_BAD_ARGS, "Setting S is unsupported (sorry).");

  return(STAT_OK);
 bail:
  Perl_croak(aTHX_ "%s", status_message);
}

/*
 * Pull an integer value out of the argument hash.
 */
static int
get_int_value(HV *args, char *name, int *val)
{
  int status = STAT_OK;
  SV **tmpSV = NULL;

  tmpSV = hv_fetch(args, name, 1, 0); BailNull(tmpSV, status);
  if (SvOK(*tmpSV))
    *val = SvIV(*tmpSV);
  else {
    status = STAT_BAD_ARGS;
    BailError(status);
  }

 bail:
  return(status);
}

/*
 * Pull an integer value out of the argument hash.
 * Seems like SvPV_nolen would make more sense, but it seems to tickle something
 * when used with perl's "use warnings"....
 */
static int
get_char_value(HV *args, char *name, char **val)
{
  int status = STAT_OK;
  STRLEN len;
  SV **tmpSV = NULL;

  tmpSV = hv_fetch(args, name, 1, 0); BailNull(tmpSV, status);
  if (SvOK(*tmpSV))
    *val = SvPV(*tmpSV, len);
  else {
    status = STAT_BAD_ARGS;
    BailError(status);
  }
  
 bail:
  return(status);
}

static void init_stats(sim4_stats_t *st)
{
       (void)memset(st,0,sizeof(sim4_stats_t));
}


/* stolen en-masse from sim4's dna.c */

static uchar *seq_revcomp_helper(uchar *seq, int len)
{
	uchar *p, *s;

	/* assert(SEQ_CHARS in dcomp-' '); */
	/* seq_read should check this. */

	s = seq;
	p = s+len-1;
	while (s<=p) {
		uchar c;

		c = dna_cmpl(*s); 
		*s = dna_cmpl(*p); 
		*p = c;
		++s, --p;
	}
	return seq;
}

static void add_offset_exons(Exon *exons, int offset)
{
    Exon *t;

    if (!offset || !(exons)) return;
 
    t = exons;
    while (t) {
       if (t->to1) { t->from2 += offset; t->to2 += offset; }
       t = t->next_exon;
    }
}

static void add_offset_aligns(edit_script_list *aligns, int offset)
{
    edit_script_list *head;
                 
    if (!offset || !aligns) return;
             
    head = aligns;
    while (head) { head->offset2 += offset; head = head->next_script; }
    
    return;
}

/* lifted from sim4.init.c:print_align_lat() */
/*my_print_align_lat(uchar *seq1, uchar *seq2, int len1, int len2, */
static int
format_alignments(uchar *seq1, uchar *seq2, int len1, int len2, 
		  edit_script_list **Aligns, Exon *Exons, 
		  int file_type, int match_ori,
		  SV *align_SV, AV* exon_aligns_AV) 
{
  int status = STAT_OK;
  int *S;
  edit_script_list *head, *aligns;
  
  if (*Aligns==NULL)
    return(status);
  
  aligns = *Aligns;
  while (aligns!=NULL) {
    head = aligns;
    aligns = aligns->next_script; 
    
    S = (int *)ckalloc((2*head->len2+1+1)*sizeof(int));
    S++;            
    S2A(head->script, S, (file_type==1) ? 1:0);
    Free_script(head->script);
    
    /* file_type==GEN_EST !!!! XXXX */
    status = MY_IDISPLAY(seq1+ head->offset1-1-1, seq2+ head->offset2-1-1,
			 head->len1, head->len2, S,
			 head->offset1, head->offset2, 2, Exons,
			 align_SV);
    BailError(status);

    status =  format_exon_alignments(seq1+ head->offset1-1-1, seq2+ head->offset2-1-1,
				     head->len1, head->len2, S,
				     head->offset1, head->offset2, 2, Exons,
				     exon_aligns_AV);
    BailError(status);

    free(S-1);
    free(head);
  }                      
  *Aligns = NULL;

  /* XXXX FIX ME. */
 bail:
  return(status);                
}

static uchar ALINE[51], BLINE[51], CLINE[51];

static int
MY_IDISPLAY(uchar A[], uchar B[], int M, int N, int S[], int AP, int BP,
	    int est_strand, Exon *exons,
	    SV *align_SV)
{ 
  int status = STAT_OK;
  Exon *t0;
  register uchar *a, *b, *c, sign;
  register int    i,  j, op, index;
  int   lines, ap, bp, starti;
        
  if ((exons==NULL) || (!exons->to1 && (exons->next_exon==NULL)))
       fatal("align.c: Exon list cannot be empty.");
           
  /* find the starting exon for this alignment */
  t0 = exons;
  while (t0 && (((est_strand==2) && ((t0->from1!=AP) || (t0->from2!=BP))) ||
                ((est_strand==1) && ((t0->from1!=BP) || (t0->from2!=AP)))))
     t0 = t0->next_exon;
  if (!t0) fatal("align.c: Alignment fragment not found.");
          
  i = j = op = lines = index = 0;
  sign = '*'; ap = AP; bp = BP; a = ALINE; b = BLINE; c = CLINE;
  starti = (t0->next_exon && t0->next_exon->to1) ? (t0->to1+1):-1;

  while (i < M || j < N) {
    if (op == 0 && *S == 0) {
          op = *S++; *a = A[++i]; *b = B[++j];
          *c++ = (*a++ == *b++) ? '|' : ' ';
    } else {
        if (op == 0) { op = *S++; }
        if (op > 0) {
           if (est_strand==2) {
               *a++ = ' '; *b++ = B[++j]; *c++ = '-'; op--;
           } else {
               if (j+BP==starti) {
                   /* detected intron */
                   switch (t0->ori) {
                      case 'C': sign = '<'; break;
                      case 'G': sign = '>'; break;
                      case 'N': sign = '='; break;
                      default: fatal("align.c: Unrecognized intron type.");
                   } 
                   t0 = t0->next_exon;
                   starti=(t0->next_exon && t0->next_exon->to1)?(t0->to1+1):-1;
                   index = 1; *c++ = sign; *a++ = ' '; *b++ = B[++j]; op--;
               } else if (!index) {
                   *c++ = '-'; *a++ = ' '; *b++ = B[++j]; op--;
               } else { 
                   /* not the first deletion in the intron */
                   switch (index) {
                       case 0:
                       case 1:
                       case 2: *a++ = ' '; *b++ = B[++j];
                               *c++ = sign; op--; index++; break;
                       case 3:
                       case 4: *a++ = ' '; *b++ = '.'; *c++ = '.';
                                j++; op--; index++; break;
                       case 5: *a++ = ' '; *b++ = '.'; *c++ = '.';
                                j+= op-3; op = 3; index++; break;
                       case 6:
                       case 7: *a++ = ' '; *b++ = B[++j]; *c++ = sign;
                               op--; index++; break;
                       case 8: *a++ = ' '; *b++ = B[++j];
                               *c++ = sign; op--; index = 0; break;
                       }
               }   
           }   
        } else {   
           if (est_strand==1) {
               *a++ = A[++i]; *b++ = ' '; *c++ = '-'; op++;  
           } else {
               if (i+AP==starti) {
                   /* detected intron */
                   switch (t0->ori) { 
                      case 'C': sign = '<'; break;
                      case 'G': sign = '>'; break;
                      case 'N': sign = '='; break;
                      default: fatal("align.c: Unrecognized intron type.");
                   }   
                   t0 = t0->next_exon;
                   starti=(t0->next_exon && t0->next_exon->to1)?(t0->to1+1):-1;
                       
                   index = 1; *c++ = sign; *a++ = A[++i]; *b++ = ' '; op++;
               } else if (!index) { 
                   *c++ = '-'; *a++ = A[++i]; *b++ = ' '; op++;
               } else { 
                   /* not the first deletion in the intron */
                   switch (index) {
                       case 0:
                       case 1: 
                       case 2: *a++ = A[++i]; *b++ = ' '; *c++ = sign; op++;
                                index++; break;
                       case 3:
                       case 4: *a++ = '.'; *b++ = ' '; *c++ = '.';
                                i++; op++; index++; break;
                       case 5: *a++ = '.'; *b++ = ' '; *c++ = '.';
                                i+=(-op)-3; op=-3; index++; break;
                       case 6:
                       case 7: *a++ = A[++i]; *b++ = ' '; 
                               *c++ = sign; op++; index++; break;
                       case 8: *a++ = A[++i]; *b++ = ' ';
                               *c++ = sign; op++; index = 0; break;
                   }   
               }   
           }   
        }          
    }          
    if ((a >= ALINE+50) || ((i >= M) && (j >= N))) {
        *a = *b = *c = '\0';
        /*(void)printf("\n%7d ",50*lines++); */
	sv_catpvf(align_SV, "\n%7d ",50*lines++);
        for (b = ALINE+10; b <= a; b += 10)
	  /* (void)printf("    .    :"); */
	  sv_catpvf(align_SV, "    .    :");
        if (b <= a+5)           
	  /*(void)printf("    ."); */
	  sv_catpvf(align_SV, "    .");
        /*(void)printf("\n%7d %s\n        %s\n%7d %s\n",ap,ALINE,CLINE,bp,BLINE); */
	sv_catpvf(align_SV, "\n%7d %s\n        %s\n%7d %s\n",ap,ALINE,CLINE,bp,BLINE);
         ap = AP + i;           
         bp = BP + j;  
         a = ALINE;             
         b = BLINE;    
         c = CLINE;
    }
  }
  return(status);
}


/* once upon a time, this was a perfectly good copy of MY_IDISPLAY.
 * Then mutation began, and it became dedicated to creating alignment
 * strings just for the exons.
 * I'm not sure why it always works, since I don't completely understand
 * the way that the dang S array is laid out, but it mimics what MY_IDISPLAY
 * does (except that it's dedicated to est_strand=2, since that's all the perl
 * module ever does).
 *
 * This uses perl scalars as growable strings to manage the lines of the alignments,
 * since I'm already creating scalars as if they're toys....
 */
static int
format_exon_alignments(uchar A[], uchar B[], int M, int N, int S[], int AP, int BP,
		       int est_strand, Exon *exons,
		       AV *exon_aligns_AV)
{ 
  int status = STAT_OK;
  Exon *t0;
  register uchar *a, *b, *c, sign;
  register int    i,  j, op, index;
  int   lines, ap, bp, starti;
  int new_exon;
  int need_sequence_positions;
  int exon_counter;
  SV *align_SV;			/* the concatenated string. */
  SV *ALINE_SV;			/* the top alignment string */
  SV *CLINE_SV;			/* the middle alignment string */
  SV *BLINE_SV;			/* the bottom alignment string */

  
  if ((exons==NULL) || (!exons->to1 && (exons->next_exon==NULL)))
    fatal("format_exon_alignments: Exon list cannot be empty.");
  
  if (est_strand != 2) 
    fatal("format_exon_alignments: Yikes, our assumption that est_strand is 2 isn't true.");
  
  /* find the starting exon for this alignment */
  t0 = exons;
  while (t0 && ((est_strand==2) && ((t0->from1!=AP) || (t0->from2!=BP))))
    t0 = t0->next_exon;
  if (!t0) fatal("align.c: Alignment fragment not found.");
  
  /* XXXX foo */
#if 0  
  if (exon_aligns_AV == NULL)
    exon_aligns_AV = newAV();
  BailNull(exon_aligns_AV, status);
#endif

  i = j = op = lines = index = new_exon = exon_counter = 0;
  sign = '*'; ap = AP; bp = BP; a = ALINE; b = BLINE; c = CLINE;
  starti = (t0->next_exon && t0->next_exon->to1) ? (t0->to1+1):-1;
  
  align_SV = newSVpv("",0);	/* avoid uninitialized variable warning */
  BailNull(align_SV, status);

  ALINE_SV = newSVpv("",0);	/* avoid uninitialized variable warning */
  BailNull(ALINE_SV, status);

  BLINE_SV = newSVpv("",0);	/* avoid uninitialized variable warning */
  BailNull(BLINE_SV, status);

  CLINE_SV = newSVpv("",0);	/* avoid uninitialized variable warning */
  BailNull(CLINE_SV, status);
  
  while (i < M || j < N) {
    if (op == 0 && *S == 0) {
      op = *S++; *a = A[++i]; *b = B[++j];
      *c++ = (*a++ == *b++) ? '|' : ' ';
    } else {
      if (op == 0) {
	op = *S++;
      }
      if (op > 0) {
	*a++ = ' '; *b++ = B[++j]; *c++ = '-'; op--;
      } else {   
	if (i+AP==starti) {
	  t0 = t0->next_exon;
	  starti=(t0->next_exon && t0->next_exon->to1)?(t0->to1+1):-1;
	  i += (-op);
	  op = 0;
	  new_exon = 1;
	}
	else {
	  *c++ = '-'; *a++ = A[++i]; *b++ = ' '; op++;
	}
      }   
    }          
    if ((new_exon) || (a >= ALINE+50) || ((i >= M) && (j >= N))) {
      *a = *b = *c = '\0';

#if 0				/* Simon doesn't like these. */
      /* stick the base positions onto the beginning of the strings. */
      if (need_sequence_positions) {
	sv_catpvf(ALINE_SV, "%7d ", ap);
	sv_catpvf(CLINE_SV, "        ");
	sv_catpvf(BLINE_SV, "%7d ", bp);
	need_sequence_positions = 0;
      }
#endif

      /* concat the buffers containing the three alignment lines to their sv's */
      sv_catpv(ALINE_SV, ALINE);
      sv_catpv(CLINE_SV, CLINE);
      sv_catpv(BLINE_SV, BLINE);

      /* keep house. */
      ap = AP + i;           
      bp = BP + j;  
      a = ALINE;             
      b = BLINE;    
      c = CLINE;

      /* do we need to start a new exon? */
      if (new_exon) {
	/* concat the lines onto the sv for this exon. */
	sv_catsv(align_SV, ALINE_SV);
	sv_catpv(align_SV, "\n");
	sv_catsv(align_SV, CLINE_SV);
	sv_catpv(align_SV, "\n");
	sv_catsv(align_SV, BLINE_SV);
	sv_catpv(align_SV, "\n");

	/* stuff this exon's sv into the array of 'em */
	/* (void) av_store(exon_aligns_AV, exon_counter++, align_SV); */
	av_push(exon_aligns_AV, align_SV);
      
	/* reset the per-line sv's for the next time through. */
	sv_setpv(ALINE_SV, "");
	sv_setpv(CLINE_SV, "");
	sv_setpv(BLINE_SV, "");

	/* create a new sv for the next exon alignment string */
	align_SV = newSVpv("",0);	/* avoid uninitialized variable warning */
	BailNull(align_SV, status);

	/* and set up the flags correctly. */
	new_exon=0;
	need_sequence_positions = 1;
      }
    }
  }

  /*
   * Don't forget to spit out the last exon and clean up.
   */
  
  *a = *b = *c = '\0';

#if 0
  /* stick the base positions onto the beginning of the strings. */
  if (need_sequence_positions) {
    sv_catpvf(ALINE_SV, "%7d ", ap);
    sv_catpvf(CLINE_SV, "        ");
    sv_catpvf(BLINE_SV, "%7d ", bp);
    need_sequence_positions = 0;
  }
#endif
  
  /* concat the buffers containing the three alignment lines to their sv's */
  sv_catpv(ALINE_SV, ALINE);
  sv_catpv(CLINE_SV, CLINE);
  sv_catpv(BLINE_SV, BLINE);
  
  /* keep house. */
  ap = AP + i;           
  bp = BP + j;  
  a = ALINE;             
  b = BLINE;    
  c = CLINE;
  
  /* concat the lines onto the sv for this exon. */
  sv_catsv(align_SV, ALINE_SV);
  sv_catpv(align_SV, "\n");
  sv_catsv(align_SV, CLINE_SV);
  sv_catpv(align_SV, "\n");
  sv_catsv(align_SV, BLINE_SV);
  sv_catpv(align_SV, "\n");
    
  /* stuff this exon's sv into the array of 'em */
  /* (void) av_store(exon_aligns_AV, exon_counter++, align_SV); */
  av_push(exon_aligns_AV, align_SV);
    
  /* free! the per-line sv's. */
  SvREFCNT_dec(ALINE_SV);
  SvREFCNT_dec(CLINE_SV);
  SvREFCNT_dec(BLINE_SV);
    
 bail:
  return(status);
}

