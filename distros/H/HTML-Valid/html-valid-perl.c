typedef struct {
    TidyDoc tdoc;
    int n_mallocs;
}
html_valid_t;

typedef enum html_valid_status {
    html_valid_ok,
    /* Malloc or calloc failed. */
    html_valid_memory_failure,
    /* An upstream error from the library. */
    html_valid_tidy_error,
    html_valid_inconsistency,
    html_valid_unknown_option,
    html_valid_bad_option_type,
    html_valid_undefined_option,
    html_valid_non_numerical_option,
}
html_valid_status_t;

static html_valid_status_t
html_valid_create (html_valid_t * htv)
{
    htv->tdoc = tidyCreate ();
    htv->n_mallocs++;
    return html_valid_ok;
}

#define CALL(x) {				\
	html_valid_status_t status =		\
	    html_valid_ ## x;			\
	if (status != html_valid_ok) {		\
	    return status;			\
	}					\
    }

#define CALL_TIDY(x) {					\
	int rc;						\
	rc = x;						\
	if (rc < 0) {					\
	    warn ("Error %d from tidy library", rc);	\
	    return html_valid_tidy_error;		\
	}						\
    }


#define CHECK_INIT(htv) {			\
	if (! htv->tdoc) {			\
	    warn ("Uninitialized TidyDoc");	\
	    return html_valid_inconsistency;	\
	}					\
    }

static html_valid_status_t
html_valid_run (html_valid_t * htv, SV * html,
		SV ** output_ptr, SV ** errors_ptr)
{
    const char * html_string;
    STRLEN html_length;
    SV * output;
    SV * errors;

    TidyBuffer tidy_output = {0};
    TidyBuffer tidy_errbuf = {0};

    /* First set these up sanely in case the stuff hits the fan. */

    * output_ptr = & PL_sv_undef;
    * errors_ptr = & PL_sv_undef;

    /* Work around bug where allocator sometimes does not get set. */

    CopyAllocator (htv->tdoc, & tidy_output);
    CopyAllocator (htv->tdoc, & tidy_errbuf);

    html_string = SvPV (html, html_length);
    CALL_TIDY (tidySetErrorBuffer (htv->tdoc, & tidy_errbuf));
    htv->n_mallocs++;
    CALL_TIDY (tidyParseString (htv->tdoc, html_string));
    CALL_TIDY (tidyCleanAndRepair (htv->tdoc));
    CALL_TIDY (tidyRunDiagnostics (htv->tdoc));
    CALL_TIDY (tidySaveBuffer (htv->tdoc, & tidy_output));
    htv->n_mallocs++;

    /* Copy the contents of the buffers into the Perl scalars. */

    output = newSVpv ((char *) tidy_output.bp, tidy_output.size);
    errors = newSVpv ((char *) tidy_errbuf.bp, tidy_errbuf.size);

    /* HTML Tidy randomly segfaults here due to "allocator" not being
       set in some cases, hence the above CopyAllocator fix. */

    tidyBufFree (& tidy_output);
    htv->n_mallocs--;
    tidyBufFree (& tidy_errbuf);
    htv->n_mallocs--;

    /* These are not our mallocs, they are Perl's mallocs, so we don't
       increase htv->n_mallocs for these. After we return them, we no
       longer take care of these. */
    * output_ptr = output;
    * errors_ptr = errors;
    return html_valid_ok;
}

static html_valid_status_t
html_valid_set_string_option (html_valid_t * htv, const char * coption,
			      TidyOptionId ti, SV * value)
{
    const char * cvalue;
    STRLEN cvalue_length;
    if (! SvOK (value)) {
	warn ("cannot set option '%s' to undefined value",
	      coption);
	return html_valid_undefined_option;
    }
    cvalue = SvPV (value, cvalue_length);
    if (! tidyOptSetValue (htv->tdoc, ti, cvalue)) {
	warn ("Setting option %d to %s failed", ti, cvalue);
	return html_valid_tidy_error;
    }
    return html_valid_ok;
}

static html_valid_status_t
html_valid_set_number_option (html_valid_t * htv, const char * coption,
			      TidyOptionId ti, SV * value)
{
    int cvalue;
    if (! SvOK (value)) {
	warn ("cannot set option '%s' to undefined value",
	      coption);
	return html_valid_undefined_option;
    }
    if (! looks_like_number (value)) {
	warn ("option %s expects a numerical value, but you supplied %s",
	      coption, SvPV_nolen (value));
	return html_valid_non_numerical_option;
    }
    cvalue = SvIV (value);
    if (! tidyOptSetInt (htv->tdoc, ti, cvalue)) {
	warn ("Setting option %d to %d failed", ti, cvalue);
	return html_valid_tidy_error;
    }
    return html_valid_ok;
}

static html_valid_status_t
html_valid_set_option (html_valid_t * htv, SV * option, SV * value)
{
    TidyOption to;
    TidyOptionType tot;
    TidyOptionId ti;
    const char * coption;
    STRLEN coption_length;
    CHECK_INIT (htv);
    coption = SvPV (option, coption_length);
    to = tidyGetOptionByName(htv->tdoc, coption);
    if (to == 0) {
	warn ("unknown option %s", coption);
	return html_valid_unknown_option;
    }
    ti = tidyOptGetId (to);
    tot = tidyOptGetType (to);
    switch (tot) {
    case TidyString:
	CALL (set_string_option (htv, coption, ti, value));
	break;
    case TidyInteger:
	CALL (set_number_option (htv, coption, ti, value));
	break;
    case TidyBoolean:
	tidyOptSetBool (htv->tdoc, ti, SvTRUE (value));
	break;
    default:
	fprintf (stderr, "%s:%d: bad option type %d from tidy library.\n",
		 __FILE__, __LINE__, tot);
	return html_valid_bad_option_type;
    }
    return html_valid_ok;
}

static html_valid_status_t
html_valid_destroy (html_valid_t * htv)
{
    tidyRelease (htv->tdoc);
    htv->tdoc = 0;
    htv->n_mallocs--;
    return html_valid_ok;
}

static html_valid_status_t
html_valid_tag_information (HV * hv)
{
    int i;
    // n_html_tags is defined in html-tidy5.h as part of the "extra"
    // material.
    html_valid_tag_t tags[n_html_tags];
    TagInformation (tags);
    for (i = 0; i < n_html_tags; i++) {
	int name_len;
	AV * constants;
	SV * constants_ref;
	constants = newAV ();
	// Store the ID for reverse lookup of attributes.
	av_push (constants, newSVuv (i));
	av_push (constants, newSVuv (tags[i].versions));
	av_push (constants, newSVuv (tags[i].model));

	constants_ref = newRV_inc ((SV *) constants);
	name_len = strlen (tags[i].name);
/*
	fprintf (stderr, "Storing %s (%d) into hash.\n",
		 tags[i].name, name_len);
*/
	(void) hv_store (hv, tags[i].name, name_len, constants_ref, 0 /* no hash value */);
    }
    return html_valid_ok;
}

html_valid_status_t
html_valid_tag_attr (AV * av, unsigned int tag_id, unsigned int version)
{
    const char * yes_no[n_attributes];
    int i;
    int j;
    int n_attr;
    TagAttributes (tag_id, version, yes_no, & n_attr);
    if (av_len (av) != -1) {
	fprintf (stderr, "%s:%d: unexpected non-empty array with %d elements",
		 __FILE__, __LINE__, (int) (av_len (av) + 1));
	return html_valid_ok;
    }
    if (n_attr == 0) {
	return html_valid_ok;
    }
    j = 0;
    for (i = 0; i < n_attributes; i++) {
	if (yes_no[i]) {
	    SV * attribute;
	    attribute = newSVpv (yes_no[i], strlen (yes_no[i]));
	    av_push (av, attribute);
//	    fprintf (stderr, "Adding %d, %s\n", j, yes_no[i]);
	    j++;
	}
    }
    if (j != n_attr) {
	fprintf (stderr, "%s:%d: inconsistency between expected number of attributes %d and stored number %d\n",
		 __FILE__, __LINE__, n_attr, j);
    }
    return html_valid_ok;
}

html_valid_status_t
html_valid_all_attributes (AV * av)
{
    const char * yes_no[n_attributes];
    int i;
    TagAllAttributes (yes_no);
    if (av_len (av) != -1) {
	fprintf (stderr, "%s:%d: unexpected non-empty array with %d elements",
		 __FILE__, __LINE__, (int) (av_len (av) + 1));
	return html_valid_ok;
    }
    for (i = 0; i < n_attributes; i++) {
	SV * attribute;
	attribute = newSVpv (yes_no[i], strlen (yes_no[i]));
	av_push (av, attribute);
    }
    return html_valid_ok;
}

