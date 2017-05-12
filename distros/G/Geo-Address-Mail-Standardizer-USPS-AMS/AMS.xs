#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <zip4.h>
#include <z4dpv.h>

// convenience macros for a few cases:
//
//   - newSVpvs only works for literals
//   - might set undef via NULL pointer

#define newSVpvn_nolen(s) newSVpvn(s, strlen(s))
#define newSVpvn_nolen_undef(s) newSVpvn(s, s ? strlen(s) : 0)

MODULE = Geo::Address::Mail::Standardizer::USPS::AMS PACKAGE = Geo::Address::Mail::Standardizer::USPS::AMS PREFIX = ams_

void ams_init(SV * self)
PPCODE:
	Z4OPEN_PARM	z4cfg;
	int			status;
	char *		statedir;
	char *		datadir;
	char *		path_comm;
	char *		path_dpv;
	char *		path_elot;
	char *		path_lacslink;
	char *		path_suitelink;

	// get paths to the database and the security key file
	// as provided by the appropriate moose attributes

	PUSHMARK(SP);
	XPUSHs(self);
	PUTBACK;

	call_method("datadir", 0);
	datadir = strdup(SvPV_nolen(ST(0)));
	POPs;

	PUSHMARK(SP);
	XPUSHs(self);
	PUTBACK;

	call_method("statedir", 0);
	statedir = strdup(SvPV_nolen(ST(0)));
	POPs;

	// construct all of the common paths

	path_comm		= malloc(strlen(datadir) + 16);
	path_dpv		= malloc(strlen(datadir) + 16);
	path_elot		= malloc(strlen(datadir) + 16);
	path_lacslink	= malloc(strlen(datadir) + 16);
	path_suitelink	= malloc(strlen(datadir) + 16);

	sprintf(path_comm,		"%s/comm",		datadir);
	sprintf(path_dpv,		"%s/dpv",		datadir);
	sprintf(path_elot,		"%s/elot",		datadir);
	sprintf(path_lacslink,	"%s/lacslink",	datadir);
	sprintf(path_suitelink,	"%s/suitelink",	datadir);

	// zero out the config structure as indicated by the
	// documentation

	memset(&z4cfg, 0, sizeof(Z4OPEN_PARM));

	z4cfg.systemflag		= 'Y';

	z4cfg.abrstflag			= 'N';
	z4cfg.elotflag			= 'N';
	z4cfg.ewsflag			= 'N';
	z4cfg.dpvflag			= 'Y';
	z4cfg.llkflag			= 'Y';
	z4cfg.stelnkflag		= 'N';

	z4cfg.config.system		= statedir;
	z4cfg.config.address1	= path_comm;
	z4cfg.config.addrindex	= path_comm;
	z4cfg.config.citystate	= path_comm;
	z4cfg.config.crossref	= path_comm;
	z4cfg.config.fnsnpath	= path_comm;
	z4cfg.config.llkpath	= path_lacslink;
	z4cfg.config.dpvpath	= path_dpv;

	//z4cfg.config.system		= path_comm;
	//z4cfg.config.elot		= path_elot;
	//z4cfg.config.elotindex	= path_elot;
	//z4cfg.config.stelnkpath	= path_suitelink;
	//z4cfg.config.abrstpath	= 

	status = z4opencfg(&z4cfg);

	//printf("z4cfg.config.address1: %s\n", z4cfg.config.address1);
	//printf("z4cfg.config.dpvpath: %s\n", z4cfg.config.dpvpath);
	//printf("z4cfg.config.llkpath: %s\n", z4cfg.config.llkpath);
	//printf("z4open: %d\n", status);
	//printf("z4cfg.status: %d\n", z4cfg.status);

	free(path_comm);
	free(path_dpv);
	free(path_elot);
	free(path_lacslink);
	free(path_suitelink);

	switch (status) {
		case 1: z4close(); croak("AMS not in sync"); break;
		case 2: z4close(); croak("AMS has expired"); break;
		case 4: z4close(); croak("AMS failed to open DPV"); break;
		case 5: z4close(); croak("AMS failed to open DPV"); break;
		case 7: z4close(); croak("AMS failed to open LACSLink"); break;
		case 13: z4close(); croak("AMS failed to open SuiteLink"); break;
		case 17: z4close(); croak("AMS failed to open ASNs"); break;
	}

SV * ams__standardize(SV * self, SV * addr)
CODE:
	ZIP4_PARM	data;		// AMS zip4 object
	ADDR_REC *	arec;		// AMS zip4 address object
	int			res;		// generic function return variable
	HV *		hviaddr;	// hash: input address
	HV *		hvoaddr;	// hash: output address
	HV *		hvres;		// hash: return value
	HV *		hvchanged;	// hash: changed fields
	HV *		hvfootnote;	// hash: footnotes
	SV **		svp;		// pointer to transient scalars
	SV *		sv;			// scalar: transient value
	AV *		avaddrs;	// array: list of address hashes
	char *		err;		// error message
	int			pages;		// number of pages of x10 records
	int			i;			// throwaway counter
	char *p;
	char c;

	hviaddr = (HV *) SvRV(addr);

	memset(&data, 0, sizeof(ZIP4_PARM));

	if ((svp = hv_fetch(hviaddr, "street", 6, 0)) && SvOK(*svp) && SvTRUE(*svp))
		strncpy(data.iadl1, SvPV_nolen(*svp), sizeof(data.iadl1)-1);

	if ((svp = hv_fetch(hviaddr, "secondary", 9, 0)) && SvOK(*svp) && SvTRUE(*svp))
		strncpy(data.iadl3, SvPV_nolen(*svp), sizeof(data.iadl3)-1);

	if ((svp = hv_fetch(hviaddr, "city", 4, 0)) && SvOK(*svp) && SvTRUE(*svp))
		strncpy(data.ictyi, SvPV_nolen(*svp), sizeof(data.ictyi)-1);

	if ((svp = hv_fetch(hviaddr, "state", 5, 0)) && SvOK(*svp) && SvTRUE(*svp))
		strncpy(data.istai, SvPV_nolen(*svp), sizeof(data.istai)-1);

	if ((svp = hv_fetch(hviaddr, "zip", 3, 0)) && SvOK(*svp) && SvTRUE(*svp))
		strncpy(data.izipc, SvPV_nolen(*svp), sizeof(data.izipc)-1);

	res = z4adrinq(&data);

	if (res)
		croak("z4adrinq failed");

	//printf("z4adrinq: %d\n", res);
	//printf("retcc: %d\n", data.retcc);

	hvres		= newHV();
	hvfootnote	= newHV();
	avaddrs		= NULL;
	hvchanged	= NULL;
	hvoaddr		= NULL;
	err			= NULL;

	switch (data.retcc) {
		case Z4_INVADDR:	err = "invalid input address";	break;
		case Z4_INVZIP:		err = "invalid ZIP code";		break;
		case Z4_INVSTATE:	err = "invalid state";			break;
		case Z4_INVCITY:	err = "invalid city";			break;
		case Z4_NOTFND:		err = "no match found";			break;

		case Z4_MULTIPLE:
		break;

		case Z4_DEFAULT:
            hv_stores(hvres, "default", newSViv(1)); // no break; we want to fall through
		case Z4_SINGLE:
			hvoaddr = newHV();
			hvchanged = newHV();

			hv_stores(hvoaddr, "street",		newSVpvn_nolen(data.dadl1));
			hv_stores(hvoaddr, "name",			newSVpvn_nolen(data.dadl2));
			hv_stores(hvoaddr, "street2",		newSVpvn_nolen(data.dadl3));
			hv_stores(hvoaddr, "city",			newSVpvn_nolen(data.dctya));
			hv_stores(hvoaddr, "state",			newSVpvn_nolen(data.dstaa));

			sv = newSVpvn_nolen(data.zipc);

			if (data.addon) {
				sv_catpvs(sv, "-");
				sv_catpvn(sv, data.addon, 4);
			}

			hv_stores(hvoaddr, "postal_code",	sv);

			//if (data.foot.l || data.foot.m || data.foot.n)
			//	hv_stores(hvchanged, "street", newSViv(1));

			if (strcmp(data.izipc, SvPV_nolen(sv)))
				hv_stores(hvchanged, "postal_code", newSViv(1));
			if (strcmp(data.iadl1, data.dadl1))
				hv_stores(hvchanged, "street", newSViv(1));
			if (strcmp(data.iadl3, data.dadl3))
				hv_stores(hvchanged, "street2", newSViv(1));
			if (strcmp(data.ictyi, data.dctya))
				hv_stores(hvchanged, "city", newSViv(1));
			if (strcmp(data.istai, data.dstaa))
				hv_stores(hvchanged, "state", newSViv(1));

			hv_stores(hvres, "standardized_address", newRV_inc((SV *) hvoaddr));
			hv_stores(hvres, "changed", newRV_inc((SV *) hvchanged));
		break;
	}

	// Populate the footnotes hash
	for (p = &data.foot.a; p < &data.foot.a + sizeof(data.foot); p++)
		if(*p && *p == 'A' + p - &data.foot.a) {
			char * hkey;
			hkey = malloc(2);
			snprintf(hkey, 2, "%c", *p);
			hv_store(hvfootnote, hkey, 1, newSViv(1), 0);
			free(hkey);
		}
//		printf("%c", *p && *p == 'A' + p - &data.foot.a ? *p : '-');
//	printf("\n");

	// if the address inquiry returned any responses at all,
	// go ahead and standardize them all, creating hashrefs
	// for each address.  these hashref representations of
	// "candidate" addresses will be returned to the caller
	// for coercion to Geo::Address::Mail::US objects.  they
	// will then be accessible via the Results object.

	if (data.respn > 0) {
		avaddrs	= newAV();
		pages	= ceil(data.respn / 10);
        if (data.respn > 1) {
            hv_stores(hvres, "multiple", newSViv(1));
        } else {
            hv_stores(hvres, "single", newSViv(1));
        }

		for (i = 0; i < data.respn; i++) {
			z4adrstd(&data, i);

			//for (p = &data.foot.a; p < &data.foot.a + sizeof(data.foot); p++)
			//	printf("%c", *p && *p == 'A' + p - &data.foot.a ? *p : '-');
			//printf("\n");

			hvoaddr = newHV();

			hv_stores(hvoaddr, "street",		newSVpvn_nolen(data.dadl1));
			hv_stores(hvoaddr, "name",			newSVpvn_nolen(data.dadl2));
			hv_stores(hvoaddr, "street2",		newSVpvn_nolen(data.dadl3));
			hv_stores(hvoaddr, "city",			newSVpvn_nolen(data.dctya));
			hv_stores(hvoaddr, "state",			newSVpvn_nolen(data.dstaa));

			sv = newSVpvn_nolen(data.zipc);

			if (data.addon) {
				sv_catpvs(sv, "-");
				sv_catpvn(sv, data.addon, 4);
			}

			hv_stores(hvoaddr, "last",			newSVpvn_nolen(data.dlast));
			hv_stores(hvoaddr, "postal_code",	sv);

			av_push(avaddrs, newRV_inc((SV *) hvoaddr));

			if (i+1 % 10 == 0 && i+1 < data.respn)
				z4scroll(&data);
		}
	}

	hv_stores(hvres, "found", newSViv(data.respn));
	hv_stores(hvres, "footnotes", newRV_inc((SV *) hvfootnote));

	if (avaddrs)
		hv_stores(hvres, "candidates", newRV_inc((SV *) avaddrs));
	if (err)
		hv_stores(hvres, "error", newSVpvn_nolen(err));

	RETVAL = newRV_inc((SV *) hvres);
OUTPUT:
	RETVAL

