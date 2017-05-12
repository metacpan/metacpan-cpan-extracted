/* mgx.h - provides extra mg functions */

#ifndef mg_find_by_vtbl

#define mg_find_by_vtbl(sv, vtbl) my_mg_find_by_vtbl(aTHX_ sv, vtbl)
static MAGIC*
my_mg_find_by_vtbl(pTHX_ SV* const sv, const MGVTBL* const vtbl){
	MAGIC* mg;

	assert(sv != NULL);
	for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
		if(mg->mg_virtual == vtbl){
			break;
		}
	}
	return mg;
}

/* safe version of mg_find_by_vtbl() */
#define MgFind(sv, vtbl) (SvMAGICAL(sv) ? mg_find_by_vtbl(sv, vtbl) : NULL)

#endif /* !mg_find_by_vtbl */
