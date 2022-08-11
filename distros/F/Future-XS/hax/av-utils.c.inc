/* vi: set ft=c : */

// TODO: move av_push_from_av() from perl-additions.c.inc to here

#define XPUSHs_from_AV(av)            \
  do {                                \
    EXTEND(SP, AvFILL(av)+1);         \
    size_t i;                         \
    for(i = 0; i < AvFILL(av)+1; i++) \
      PUSHs(AvARRAY(av)[i]);          \
  } while(0)

#define av_push_svn(av, svp, n)  S_av_push_svn(aTHX_ av, svp, n)
static void S_av_push_svn(pTHX_ AV *av, SV **svp, size_t n)
{
  while(n) {
    av_push(av, newSVsv(*svp));
    svp++; n--;
  }
}

#define newAV_svn_dup(svp, n)  S_newAV_svn_dup(aTHX_ svp, n)
static AV *S_newAV_svn_dup(pTHX_ SV **svp, size_t n)
{
  AV *av = newAV();
  av_push_svn(av, svp, n);
  return av;
}
