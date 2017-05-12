
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"

extern void AddSignalHelperParts(GtkType type, char ** names, void * unpacker, void * repacker);

SV * newSVGnomeSpellInfo(GnomeSpellInfo * si)
{
	HV * h;
	SV * r;
	
	if (!si)
		return newSVsv(&PL_sv_undef);
		
	h = newHV();
	r = newRV_inc((SV*)h);
	SvREFCNT_dec(h);

	hv_store(h, "original", 8, newSVpv(si->original, 0), 0);
	if (si->replacement)
		hv_store(h, "replacement", 11, newSVpv(si->replacement, 0), 0);
	hv_store(h, "word", 4, newSVpv(si->word, 0), 0);
	hv_store(h, "offset", 6, newSViv(si->offset), 0);
	if (si->words) {
		GSList * wlist;
		AV* words;
		SV *rw;
		int i;
		
		words = newAV();
		rw = newRV_inc((SV*)words);
		SvREFCNT_dec(words);
		wlist = si->words;
		for (i=0; wlist && wlist->data; ++i, wlist=wlist->next) {
			av_store(words, i, newSVpv((char*)wlist->data, 0));
		}
		hv_store(h, "words", 5, (SV*)words, 0);
		
	}
	
	return r;
}

#define sp (*_sp)
static int
fixup_spellinfo (SV ** * _sp, int match, GtkObject * object, 
	char * signame, int nparams, GtkArg * args, GtkType return_type) {

	dTHR;        
	XPUSHs(sv_2mortal(newSVGnomeSpellInfo(GTK_VALUE_POINTER(args[0]))));
	return 1;
}
#undef sp

static void 
init_gspell () {
	static char* names[] = {"found-word", "handled-word", 0};
	static int inited = 0;
	if (inited)
		return;
	inited = 1;
	AddSignalHelperParts(gnome_spell_get_type(), names, fixup_spellinfo, 0);
	
}

MODULE = Gnome::Spell		PACKAGE = Gnome::Spell		PREFIX = gnome_spell_

#ifdef GNOME_SPELL

Gnome::Spell_Sink
new (Class)
	SV *	Class
	CODE:
	{
		init_gspell();
		RETVAL = (GnomeSpell*)(gnome_spell_new());
	}
	OUTPUT:
	RETVAL

int
gnome_spell_check (spell, str)
	Gnome::Spell	spell
	char *	str

void
gnome_spell_accept (spell, word)
	Gnome::Spell	spell
	char *	word

void
gnome_spell_insert (spell, word, lowercase)
	Gnome::Spell	spell
	char *	word
	int	lowercase

int
gnome_spell_next (spell)
	Gnome::Spell	spell

void
gnome_spell_kill (spell)
	Gnome::Spell	spell

#endif


