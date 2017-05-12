#include "GfsmPerl.h"
#include <fcntl.h>

#undef VERSION
#include <gfsmConfig.h>

/*======================================================================
 * Memory Stuff
 */

//-- threads
#ifdef GFSM_PERL_THREADS
 perl_mutex gfsm_perl_mutex;
#endif

#ifdef GFSM_PERL_USE_VTABLE
 GMemVTable gfsm_perl_vtable =
  {
    gfsm_perl_malloc,
    gfsm_perl_realloc,
    gfsm_perl_free,
    NULL,
    NULL,
    NULL
  };
#endif

void gfsm_perl_init(void)
{
#ifdef GFSM_PERL_THREADS
   MUTEX_INIT(&gfsm_perl_mutex);
#endif
#ifdef GFSM_PERL_USE_VTABLE
   g_mem_set_vtable(&gfsm_perl_vtable);
#endif
   //gfsm_allocators_enable();
}

gpointer gfsm_perl_malloc(gsize n_bytes)
{
  gpointer ptr=NULL;
  GFSM_PERL_LOCK;
  Newc(0, ptr, n_bytes, char, gpointer);
  GFSM_PERL_UNLOCK;
  return ptr;
}

gpointer gfsm_perl_realloc(gpointer mem, gsize n_bytes)
{
  GFSM_PERL_LOCK;
  Renewc(mem, n_bytes, char, gpointer);
  GFSM_PERL_UNLOCK;
  return mem;
}

void gfsm_perl_free(gpointer mem)
{
  GFSM_PERL_LOCK;
  Safefree(mem);
  GFSM_PERL_UNLOCK;
}

void gfsm_perl_blow_chunks(void)
{
#if 0
  g_blow_chunks(); //-- Calls g_mem_chunk_clean() on all GMemChunk objects.  Deprecated since glib v2.10
#endif
}


/*======================================================================
 * Paths
 */

AV *gfsm_perl_paths_to_av(gfsmSet *paths_s)
{
  int i;
  AV *RETVAL = newAV();
  GPtrArray *paths_a=g_ptr_array_sized_new(gfsm_set_size(paths_s));
  gfsm_set_to_ptr_array(paths_s, paths_a);

  for (i=0; i < paths_a->len; i++) {
    gfsmPath *path = (gfsmPath*)g_ptr_array_index(paths_a,i);
    HV       *hv   = gfsm_perl_path_to_hv(path);
    av_push(RETVAL, newRV((SV*)hv));
  }
  g_ptr_array_free(paths_a,TRUE);

  sv_2mortal((SV*)RETVAL);  
  return RETVAL;
}

HV *gfsm_perl_path_to_hv(gfsmPath *path)
{
  HV *hv = newHV();
  AV *lo = gfsm_perl_ptr_array_to_av_uv(path->lo);
  AV *hi = gfsm_perl_ptr_array_to_av_uv(path->hi);

  hv_store(hv, "lo", 2, newRV((SV*)lo), 0);
  hv_store(hv, "hi", 2, newRV((SV*)hi), 0);
  hv_store(hv, "w",  1, newSVnv(gfsm_perl_weight_getfloat(path->w)), 0);

  sv_2mortal((SV*)hv);
  return hv;
}

AV *gfsm_perl_ptr_array_to_av_uv(GPtrArray *ary)
{
  AV *av = newAV();
  guint i;
  for (i=0; i < ary->len; i++) {
    av_push(av, newSVuv((UV)GPOINTER_TO_SIZE(g_ptr_array_index(ary,i))));
  }
  sv_2mortal((SV*)av);
  return av;
}

/*======================================================================
 * ArcPaths
 */

AV *gfsm_perl_arcpaths_to_av(GSList *arcpaths)
{
  AV *RETVAL = newAV();

  for (; arcpaths != NULL; arcpaths=arcpaths->next) {
    gfsmArcPath *ap = (gfsmArcPath*)arcpaths->data;
    SV *sv = gfsm_perl_arcpath_to_sv(ap);
    av_push(RETVAL, sv);
  }

  sv_2mortal((SV*)RETVAL);  
  return RETVAL;
}

SV *gfsm_perl_arcpath_to_sv(gfsmArcPath *ap)
{
  SV *sv = newSV( ap->len*sizeof(gfsmArc) );
  sv_setpvn(sv,"",0);
  guint i;
  for (i=0; i < (ap->len-1); ++i) {
    sv_catpvn(sv, ap->pdata[i], sizeof(gfsmArc));
  }
  if (ap->len>0) {
    gfsmArc a = { gfsmNoState,gfsmNoState, gfsmNoLabel,gfsmNoLabel, gfsmNoWeight };
    a.weight = gfsm_ptr2weight(ap->pdata[ap->len-1]);
    sv_catpvn(sv, (char*)&a, sizeof(gfsmArc));
  }
  //sv_2mortal(sv);
  return sv;
}

/*======================================================================
 * gfsmPerlAlphabet
 */

/*--------------------------------------------------------------
 * gfsmPerlAlphabet: scalars etc.
 */
gfsmUserAlphabetMethods gfsm_perl_alphabet_methods =
  {
    (gfsmAlphabetKeyLookupFunc)gfsm_perl_alphabet_key_lookup,   //-- key_lookup: key->label lookup func
    (gfsmAlphabetLabLookupFunc)gfsm_perl_alphabet_label_lookup, //-- lab_lookup: label->key lookup func
    (gfsmAlphabetInsertFunc)gfsm_perl_alphabet_insert,          //-- insert: insertion function
    (gfsmAlphabetLabRemoveFunc)gfsm_perl_alphabet_remove,       //-- lab_remove: label removal function
    (gfsmAlphabetKeyReadFunc)gfsm_perl_alphabet_scalar_read,    //-- key_read: key input function
    (gfsmAlphabetKeyWriteFunc)gfsm_perl_alphabet_scalar_write   //-- key_write: key output function
  };

/*--------------------------------------------------------------
 * gfsmPerlAlphabet: constructors etc.
 */
gfsmAlphabet *gfsm_perl_alphabet_new(void)
{
  gfsmPerlAlphabet *alph = gfsm_slice_new0(gfsmPerlAlphabet);
  ((gfsmAlphabet*)alph)->type = gfsmATUser;
  alph->hv = newHV();
  alph->av = newAV();
  gfsm_user_alphabet_init((gfsmUserAlphabet*)alph,
			  NULL, NULL, NULL, NULL, NULL,
			  &gfsm_perl_alphabet_methods);
  return (gfsmAlphabet*)alph;
}

void gfsm_perl_alphabet_free(gfsmPerlAlphabet *alph)
{
  AV *av = alph->av;
  HV *hv = alph->hv;
  g_ptr_array_free(((gfsmPointerAlphabet*)alph)->labels2keys,TRUE);
  g_hash_table_destroy(((gfsmPointerAlphabet*)alph)->keys2labels);
  gfsm_slice_free(gfsmPerlAlphabet,alph);
  av_undef(av);
  hv_undef(hv);
}

/*--------------------------------------------------------------
 * gfsmPerlAlphabet: user methods: lookup
 */

//----------------
// key_lookup: key->label lookup function
gfsmLabelVal gfsm_perl_alphabet_key_lookup(gfsmPerlAlphabet *alph, SV* key)
{
  gfsmLabelVal lab = gfsmNoLabel;
  HE *he = hv_fetch_ent(alph->hv, key, 0, 0);

#ifdef GFSMDEBUG
  fprintf(stderr, "gfsm_perl_alphabet_key_lookup(keysv=%p, s=%s, utf8=%d)\n", key, (key ? SvPV_nolen(key) : ""), (key ? SvUTF8(key) : 0));
#endif

  if (he) {
    SV *labsv = HeVAL(he);
    if (labsv && SvOK(labsv)) { lab = (gfsmLabelVal)SvUV(labsv); }
  }

#ifdef GFSMDEBUG
  fprintf(stderr, "gfsm_perl_alphabet_key_lookup(keysv=%p) returning %u\n", key, lab);
#endif

  return lab;
}

//----------------
// lab_lookup: label->key lookup function
SV* gfsm_perl_alphabet_label_lookup(gfsmPerlAlphabet *alph, gfsmLabelVal lab)
{
  SV **labval = av_fetch(alph->av, (I32)lab, 0);

#ifdef GFSMDEBUG
  fprintf(stderr, "gfsm_perl_alphabet_label_lookup(lab=%u)\n", lab);
#endif

  if (labval && *labval && SvOK(*labval)) {
    return *labval;
  }

#ifdef GFSMDEBUG
  fprintf(stderr, "-> gfsm_perl_alphabet_label_lookup(lab=%u) returning NULL\n", lab);
#endif

  return NULL;
}

/*--------------------------------------------------------------
 * gfsmPerlAlphabet: user methods: insert/remove
 */

//----------------
//-- insert: insertion function
gfsmLabelVal gfsm_perl_alphabet_insert(gfsmPerlAlphabet *alph, SV *key, gfsmLabelVal lab)
{
  SV *akeysv, *hlabsv;

#ifdef GFSMDEBUG
  gfsmLabelVal lab0 = lab;
  fprintf(stderr, "gfsm_perl_alphabet_insert(key=%p, s=%s, utf8=%d, lab=%u)\n", key, (key ? SvPV_nolen(key): ""), (key ? SvUTF8(key) : -1), lab);
#endif

  if (lab == gfsmNoLabel) { lab = av_len(alph->av)+1; }

  //-- remove conflicting entries: key
  if ( hv_exists_ent(alph->hv, key, 0) ) {
    HE *he = hv_fetch_ent(alph->hv, key, 0, 0);
    hlabsv = HeVAL(he);
    av_delete(alph->av, (I32)SvUV(hlabsv), G_DISCARD);
  }
  //-- remove conflicting entries: label
  if ( av_exists(alph->av, (I32)lab) ) {
    gfsm_perl_alphabet_remove(alph, lab);
  }

  //-- copy the key before inserting (otherwise strangeness ensues)
  akeysv = sv_mortalcopy(key);     //-- array element: key
  SvREFCNT_inc(akeysv);            //   : mortal needs incremented refcount

  hlabsv = sv_newmortal();         //-- hash element
  sv_setuv(hlabsv,lab);            //   : label
  SvREFCNT_inc(hlabsv);            //   : mortal needs incremented refcount

  //-- store: hash
  if ( hv_store_ent(alph->hv, key, hlabsv, 0)==NULL ) {
    SvREFCNT_dec(hlabsv);
  }

  //-- store: array
  if ( av_store(alph->av, lab, akeysv)==NULL ) {
    SvREFCNT_dec(akeysv);
  }

#ifdef GFSMDEBUG
  fprintf(stderr, "gfsm_perl_alphabet_insert(key=%p, lab=%u): storing lab=%u\n", key, lab0, lab);
#endif

  return lab;
}

//----------------
//-- lab_remove: label removal function
void gfsm_perl_alphabet_remove(gfsmPerlAlphabet *alph, gfsmLabelVal lab)
{
  SV *keysv = gfsm_perl_alphabet_label_lookup(alph,lab);

#ifdef GFSMDEBUG
  fprintf(stderr, "gfsm_perl_alphabet_remove(lab=%u): keysv=%p\n", lab, keysv);
#endif

  //-- remove: hash
  if (keysv && SvOK(keysv)) {
    hv_delete_ent(alph->hv, keysv, G_DISCARD, 0);
  } else {
    warn("gfsm_perl_alphabet_remove(): bad keysv!");
  }

  //-- remove: array
  av_delete(alph->av, (I32)lab, G_DISCARD);

#ifdef GFSMDEBUG
  fprintf(stderr, "gfsm_perl_alphabet_remove(lab=%u,keysv=%p): done.\n", lab, keysv);
#endif

}

/*--------------------------------------------------------------
 * gfsmPerlAlphabet: DEBUG
 */
#ifdef GFSMDEBUG
SV *addav(AV *av, int ix, SV *val)
{
  SV *RETVAL = newSVsv(val);
  SvREFCNT_inc(RETVAL);
  if (av_store(av,ix,RETVAL)==NULL) {
    SvREFCNT_dec(RETVAL);
  }
  return RETVAL;
}
void rmav(AV *av, int ix)
{
  av_delete(av,ix,G_DISCARD);
}

SV *addhv(HV *hv, SV *key, SV *val)
{
  SV *RETVAL = newSVsv(val);
  SvREFCNT_inc(RETVAL);
  if ( hv_store_ent(hv, key, RETVAL, 0)==NULL ) {
    SvREFCNT_dec(RETVAL);
  }
  return RETVAL;
}

void rmhv(HV *hv, SV *key)
{
  hv_delete_ent(hv,key,G_DISCARD,0);
}
#endif


/*--------------------------------------------------------------
 * gfsmPerlAlphabet: user methods: string I/O
 */

//----------------
//-- string read function for perl scalars
SV *gfsm_perl_alphabet_scalar_read(gfsmPerlAlphabet *alph, GString *gstr)
{
  return newSVpvn_flags(gstr->str, gstr->len, (((gfsmAlphabet*)alph)->utf8 ? SVf_UTF8 : 0));
}

//----------------
//-- string write function for perl scalars
void gfsm_perl_alphabet_scalar_write(gfsmPerlAlphabet *alph, SV *sv, GString *gstr)
{
  g_string_truncate(gstr,0);
  g_string_append_len(gstr, SvPV_nolen(sv), sv_len(sv));
}


/*======================================================================
 * I/O: Constructors: SV*
 */
gfsmIOHandle *gfsmperl_io_new_sv(SV *sv, size_t pos)
{
  gfsmPerlSVHandle *svh = gfsm_slice_new(gfsmPerlSVHandle);
  gfsmIOHandle *ioh = gfsmio_handle_new(gfsmIOTUser,svh);

  SvUTF8_off(sv); //-- unset UTF8 flag for this SV*

  svh->sv = sv;
  svh->pos = pos;

  ioh->read_func = (gfsmIOReadFunc)gfsmperl_read_sv;
  ioh->write_func = (gfsmIOWriteFunc)gfsmperl_write_sv;
  ioh->eof_func = (gfsmIOEofFunc)gfsmperl_eof_sv;

  return ioh;
}

void gfsmperl_io_free_sv(gfsmIOHandle *ioh)
{
  gfsmPerlSVHandle *svh = (gfsmPerlSVHandle*)ioh->handle;
  gfsm_slice_free(gfsmPerlSVHandle,svh);
  gfsmio_handle_free(ioh);
}

/*======================================================================
 * I/O: Methods: SV*
 */
gboolean gfsmperl_eof_sv(gfsmPerlSVHandle *svh)
{ return svh && svh->sv ? (STRLEN)svh->pos >= sv_len(svh->sv) : TRUE; }

gboolean gfsmperl_read_sv(gfsmPerlSVHandle *svh, void *buf, size_t nbytes)
{
  char *svbytes;
  STRLEN len;
  if (!svh || !svh->sv) return FALSE;

  svbytes = sv_2pvbyte(svh->sv, &len);
  if ((STRLEN)(svh->pos+nbytes) <= len) {
    //-- normal case: just copy
    memcpy(buf, svbytes+svh->pos, nbytes);
    svh->pos += nbytes;
    return TRUE;
  }
  //-- overflow: grab what we can
  memcpy(buf, svbytes+svh->pos, len-svh->pos);
  svh->pos = len;
  return FALSE;
}

gboolean gfsmperl_write_sv(gfsmPerlSVHandle *svh, const void *buf, size_t nbytes)
{
  if (!svh || !svh->sv) return FALSE;
  sv_catpvn(svh->sv, buf, (STRLEN)nbytes);
  return TRUE;
}
