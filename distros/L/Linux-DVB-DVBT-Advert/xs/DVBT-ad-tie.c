# /*---------------------------------------------------------------------------------------------------*/
# /* Implements a tied HASH pointing to advert results */

# // VERSION = "1.003"

# /*---------------------------------------------------------------------------------------------------*/
# /*  */

ADAV *
TIEARRAY(char *CLASS, char *TYPE, AV *extra=NULL)

	INIT:
		ADA_METHOD(TIEARRAY);
		SV *sv ;
		char *key = "" ;
		int threshold = 1 ;
		ADAV *that ;
		enum Adav_type	type ;
		Adata *user_data ;

	CODE:
		ada_dbg_printf("== ADAV:TIEARRAY(%s) ==\n", TYPE) ;
		Newz(0, RETVAL, 1, ADAV);

		if (strcmp(TYPE, "ADATA")==0)
		{
			type = ADAV_ADATA ;
			if( extra && (SvTYPE((SV*)extra) == SVt_PVAV) && (av_len( extra ) > -1) )
			{
				// Adata*
				sv = av_pop( extra );
				if (sv_isobject(sv) && SvTYPE(SvRV(sv)) == SVt_PVMG)
				{
					IV tmp = SvIV((SV*)SvRV(sv));
					user_data = INT2PTR(Adata *, tmp);
				}
				else
				{
					croak("FILTER tie invalid ADAV*");
				}
			}
			else
			{
				croak("ADATA tie requires array ref with [Adata*]");
			}

		}
		else if (strcmp(TYPE, "FILTER")==0)
		{
			type = ADAV_FILTERED ;

			if( extra && (SvTYPE((SV*)extra) == SVt_PVAV) && (av_len( extra ) > -1) )
			{
				// threshold
				if (av_len( extra ) > 1)
				{
					sv = av_pop( extra );
					threshold = SvIV(sv) ;
				}

				// key
				if (av_len( extra ) > 0)
				{
					sv = av_pop( extra );
					key = SvPV_nolen(sv) ;
				}

				// ADAV*
				sv = av_pop( extra );
				if (sv_isobject(sv) && SvTYPE(SvRV(sv)) == SVt_PVMG)
				{
					IV tmp = SvIV((SV*)SvRV(sv));
					that = INT2PTR(ADAV *, tmp);
					ADA_CHECK_OBJECT(that) ;

					user_data = that->user_data ;
				}
				else
				{
					croak("FILTER tie invalid ADAV*");
				}

				create_adav_filter(RETVAL, user_data, key, threshold) ;
			}
			else
			{
				croak("FILTER tie requires array ref with [ADAV*, char*]");
			}

		}
		else if (strcmp(TYPE, "LOGO")==0)
		{
			type = ADAV_LOGO ;

			if( extra && (SvTYPE((SV*)extra) == SVt_PVAV) && (av_len( extra ) > -1) )
			{
				// ADAV*
				sv = av_pop( extra );
				if (sv_isobject(sv) && SvTYPE(SvRV(sv)) == SVt_PVMG)
				{
					IV tmp = SvIV((SV*)SvRV(sv));
					that = INT2PTR(ADAV *, tmp);
					ADA_CHECK_OBJECT(that) ;

					user_data = that->user_data ;
				}
				else
				{
					croak("LOGO tie invalid ADAV*");
				}

				create_adav_logo(RETVAL, user_data) ;
			}
			else
			{
				croak("LOGO tie requires array ref with [ADAV*]");
			}

		}
		else if ((strcmp(TYPE, "CSV")==0) || (strcmp(TYPE, "ADV")==0))
		{
			type = ADAV_CSV ;

			if( extra && (SvTYPE((SV*)extra) == SVt_PVAV) && (av_len( extra ) > -1) )
			{
				// ADAV*
				sv = av_pop( extra );
				if (sv_isobject(sv) && SvTYPE(SvRV(sv)) == SVt_PVMG)
				{
					IV tmp = SvIV((SV*)SvRV(sv));
					that = INT2PTR(ADAV *, tmp);
					ADA_CHECK_OBJECT(that) ;

					user_data = that->user_data ;
				}
				else
				{
					croak("CSV tie invalid ADAV*");
				}

				create_adav_csv(RETVAL, user_data) ;
			}
			else
			{
				croak("CSV tie requires array ref with [ADAV*]");
			}

		}
		else
		{
			croak ("Unsupported tie type");
		}
		RETVAL->user_data = user_data ;
		RETVAL->signature = ADA_SIGNATURE;
		RETVAL->type = type ;

		ada_dbg_printf("== ADAV:TIEARRAY(%s) - %p - END ==\n", TYPE, RETVAL) ;

	OUTPUT:
		RETVAL


# /*---------------------------------------------------------------------------------------------------*/
# /*  */

void
ADAV::DESTROY()

	INIT:
		ADA_METHOD(DESTROY);

	CODE:
		ADA_CHECK_THIS ;

		if (THIS->type == ADAV_ADATA)
		{
			// free all of the user data
			free_user_data(THIS->user_data) ;
			clear_adav(THIS) ;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			// free up filtered list
			free_adav_filter(THIS) ;
		}
		else if (THIS->type == ADAV_LOGO)
		{
			// free up logo list
			free_adav_logo(THIS) ;
		}
		else if (THIS->type == ADAV_CSV)
		{
			// free up csv list
			free_adav_csv(THIS) ;
		}
		else
		{
			croak ("Unsupported tie type");
		}

		ADA_END_THIS ;
		Safefree(THIS);

# /*---------------------------------------------------------------------------------------------------*/
# /*  */

SV *
ADAV::FETCH(int idx)

	INIT:
		ADA_METHOD(FETCH);
		HV *results ;
		int frame ;

	CODE:
		ADA_CHECK_THIS_NODBG ;

		if (THIS->type == ADAV_ADATA)
		{
			if ((idx >= THIS->user_data->results_list_size) || (idx < 0))
				XSRETURN_UNDEF;

			results = advert_result(THIS->user_data, THIS->user_data->results_list[idx].idx) ;
			RETVAL = newRV((SV *)results);
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			if ((idx >= THIS->filter_data.num_elems) || (idx < 0))
				XSRETURN_UNDEF;

			// get frame info first
			frame = THIS->filter_data.data[idx].frame ;
			results = advert_result(THIS->user_data, THIS->user_data->results_list[frame].idx) ;

			// update with the filtered list stuff
			HVS_INT(results, frame_end, THIS->filter_data.data[idx].frame_end ) ;
			HVS_INT(results, gap, THIS->filter_data.data[idx].gap ) ;

			// return
			RETVAL = newRV((SV *)results);
		}
		else if (THIS->type == ADAV_LOGO)
		{
			if ((idx >= THIS->logo_data.num_elems) || (idx < 0))
				XSRETURN_UNDEF;

			// get frame info first
			frame = THIS->logo_data.data[idx].frame ;
			results = advert_result(THIS->user_data, THIS->user_data->results_list[frame].idx) ;

			// update with the logo list stuff
			HVS_INT(results, frame_end, THIS->logo_data.data[idx].frame_end ) ;
			HVS_INT(results, gap, THIS->logo_data.data[idx].gap ) ;
			HVS_INT(results, match_percent, THIS->logo_data.data[idx].match_percent ) ;
			HVS_INT(results, ave_percent, THIS->logo_data.data[idx].ave_percent ) ;

			// return
			RETVAL = newRV((SV *)results);
		}
		else if (THIS->type == ADAV_CSV)
		{
			if ((idx >= THIS->csv_data.num_elems) || (idx < 0))
				XSRETURN_UNDEF;

			// get frame info first
			frame = THIS->csv_data.data[idx].frame ;
			results = advert_result(THIS->user_data, THIS->user_data->results_list[frame].idx) ;

			// update with the csv list stuff
			fetch_csv(THIS, idx, results) ;

			// return
			RETVAL = newRV((SV *)results);
		}

	OUTPUT:
		RETVAL

# /*---------------------------------------------------------------------------------------------------*/
# /*  */

SV *
ADAV::POP()

	INIT:
		ADA_METHOD(POP);
		HV *results ;
		int frame ;

	CODE:
		ADA_CHECK_THIS ;

		if (THIS->type == ADAV_ADATA)
		{
			ADA_UNEXPECTED_CALL;
			//if (THIS->user_data->results_list_size <= 0)
			//	XSRETURN_UNDEF;

			//results = advert_result(THIS->user_data, THIS->user_data->results_list[THIS->user_data->results_list_size-1].idx) ;
			//THIS->user_data->results_list_size-- ;

			//RETVAL = newRV((SV *)results);
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			if (THIS->filter_data.num_elems <= 0)
				XSRETURN_UNDEF;

			// get frame info first
			frame = THIS->filter_data.data[THIS->filter_data.num_elems-1].frame ;
			results = advert_result(THIS->user_data, THIS->user_data->results_list[frame].idx) ;

			// update with the filtered list stuff
			HVS_INT(results, frame_end, THIS->filter_data.data[THIS->filter_data.num_elems-1].frame_end ) ;
			HVS_INT(results, gap, THIS->filter_data.data[THIS->filter_data.num_elems-1].gap ) ;

			THIS->filter_data.num_elems-- ;

			// return
			RETVAL = newRV((SV *)results);
		}
		else if (THIS->type == ADAV_LOGO)
		{
			if (THIS->logo_data.num_elems <= 0)
				XSRETURN_UNDEF;

			// get frame info first
			frame = THIS->logo_data.data[THIS->logo_data.num_elems-1].frame ;
			results = advert_result(THIS->user_data, THIS->user_data->results_list[frame].idx) ;

			// update with the logo list stuff
			HVS_INT(results, frame_end, THIS->logo_data.data[THIS->logo_data.num_elems-1].frame_end ) ;
			HVS_INT(results, gap, THIS->logo_data.data[THIS->logo_data.num_elems-1].gap ) ;

			THIS->logo_data.num_elems-- ;

			// return
			RETVAL = newRV((SV *)results);
		}
		else if (THIS->type == ADAV_CSV)
		{
			ADA_UNEXPECTED_CALL;
		}
		ADA_END_THIS ;

	OUTPUT:
		RETVAL


# /*---------------------------------------------------------------------------------------------------*/
# /* Push value(s) - only valid for calling on logo array */

SV *
ADAV::PUSH(SV *sv_arg, ...)

	INIT:
		ADA_METHOD(PUSH);
		SV *sv_val ;
		HV *hv_val ;
		int idx ;
		HV *results ;

	CODE:
		ADA_CHECK_THIS ;

		if (THIS->type == ADAV_ADATA)
		{
			ADA_UNEXPECTED_CALL;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			ADA_UNEXPECTED_CALL;
		}
		else if (THIS->type == ADAV_LOGO)
		{
			ada_dbg_printf("PUSH(%d) - curr size=%d\n", items-1, THIS->logo_data.num_elems) ;

			for (idx=1; idx < items; ++idx)
			{
				sv_val = ST(idx) ;
				ada_dbg_printf(" + %d - type=%d\n", idx, SvTYPE(sv_val)) ;
  				//if(SvTYPE(sv_val) == SVt_RV)
  				{
					// process item
					hv_val = (HV *)SvRV(sv_val) ;
					results = store_logo(THIS, THIS->logo_data.num_elems, hv_val) ;
  				}
			}

			ada_dbg_printf("PUSH() - END size=%d\n", THIS->logo_data.num_elems) ;

			// return
			RETVAL = newRV((SV *)results);
		}
		else if (THIS->type == ADAV_CSV)
		{
			ADA_UNEXPECTED_CALL;
		}
		ADA_END_THIS ;


	OUTPUT:
		RETVAL


# /*---------------------------------------------------------------------------------------------------*/
# /* unshift value(s) - only valid for calling on logo array */

SV *
ADAV::UNSHIFT(SV *sv_arg, ...)

	INIT:
		ADA_METHOD(UNSHIFT);
		SV *sv_val ;
		HV *hv_val ;
		int idx ;
		HV *results ;

	CODE:
		ADA_CHECK_THIS ;

		if (THIS->type == ADAV_ADATA)
		{
			ADA_UNEXPECTED_CALL;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			ADA_UNEXPECTED_CALL;
		}
		else if (THIS->type == ADAV_LOGO)
		{
			ada_dbg_printf("UNSHIFT(%d) - curr size=%d\n", items-1, THIS->logo_data.num_elems) ;

			unshift_logo(THIS, items-1) ;

			ada_dbg_printf(" + size=%d\n", THIS->logo_data.num_elems) ;

			for (idx=1; idx < items; ++idx)
			{
				sv_val = ST(idx) ;
				//if(SvTYPE(sv_val) == SVt_RV)
				{
					// process item
					hv_val = (HV *)SvRV(sv_val) ;
					results = store_logo(THIS, idx-1, hv_val) ;
				}
			}
			ada_dbg_printf("UNSHIFT() - END size=%d\n", THIS->logo_data.num_elems) ;

			// return
			RETVAL = newRV((SV *)results);
		}
		else if (THIS->type == ADAV_CSV)
		{
			ADA_UNEXPECTED_CALL;
		}
		ADA_END_THIS ;

	OUTPUT:
		RETVAL




# /*---------------------------------------------------------------------------------------------------*/
# /* Store value - only valid for calling on logo/csv array */

SV *
ADAV::STORE(int idx, HV *hv_val)

	INIT:
		ADA_METHOD(STORE);
		HV *results ;

	CODE:
		ADA_CHECK_THIS ;

		if (THIS->type == ADAV_ADATA)
		{
			ADA_UNEXPECTED_CALL;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			ADA_UNEXPECTED_CALL;
		}
		else if (THIS->type == ADAV_LOGO)
		{
			results = store_logo(THIS, idx, hv_val) ;

			// return
			RETVAL = newRV((SV *)results);
		}
		else if (THIS->type == ADAV_CSV)
		{
			if ( (idx < 0) || (idx >= THIS->logo_data.num_elems) )
				XSRETURN_UNDEF;

			results = store_csv(THIS, idx, hv_val) ;

			// return
			RETVAL = newRV((SV *)results);
		}
		ADA_END_THIS ;

	OUTPUT:
		RETVAL

# /*---------------------------------------------------------------------------------------------------*/
# /* Splice - only supports 'splice @list, offset' that removes from offset to end of array            */
# /* Does NOT return anything                                                                          */

SV *
ADAV::SPLICE(int offset)

	INIT:
		ADA_METHOD(SPLICE);

	CODE:
		ADA_CHECK_THIS ;

		if (THIS->type == ADAV_ADATA)
		{
			ADA_UNEXPECTED_CALL;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			ADA_UNEXPECTED_CALL;
		}
		else if (THIS->type == ADAV_LOGO)
		{
			ada_dbg_printf("%s(%d) - curr size=%d\n", method, offset, THIS->logo_data.num_elems) ;

			if (THIS->logo_data.num_elems <= 0)
				XSRETURN_UNDEF;

			// len=10
			//
			// 0 1 2 3 4 5 6 7 8 9
			//       ^-------------- offset=3, new_len=3
			//                   ^-- offset=-1 => 9, new_len=9
			//               ^------ offset=-3 => 7, new_len=7

			if (offset < 0)
			{
				// offset from end
				offset = THIS->logo_data.num_elems + offset ;
			}

			if ( (offset < 0) || (offset >= THIS->logo_data.num_elems) )
				XSRETURN_UNDEF;

			// adjust element count
			THIS->logo_data.num_elems = offset ;

			ada_dbg_printf("%s() - END new size=%d\n", method, THIS->logo_data.num_elems) ;


			XSRETURN_UNDEF;
		}
		else if (THIS->type == ADAV_CSV)
		{
			ADA_UNEXPECTED_CALL;
		}
		ADA_END_THIS ;

	OUTPUT:
		RETVAL


# /*---------------------------------------------------------------------------------------------------*/
# /* Get the current "array" size */

int
ADAV::FETCHSIZE()

	INIT:
		ADA_METHOD(FETCHSIZE);

	CODE:
		//ADA_CHECK_THIS_NODBG ;
		ADA_CHECK_THIS ;

		if (THIS->type == ADAV_ADATA)
		{
			RETVAL = THIS->user_data->results_list_size;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			RETVAL = THIS->filter_data.num_elems;
		}
		else if (THIS->type == ADAV_LOGO)
		{
			RETVAL = THIS->logo_data.num_elems;
		}
		else if (THIS->type == ADAV_CSV)
		{
			RETVAL = THIS->csv_data.num_elems;
		}
		ada_dbg_printf("%s() - END size=%d\n", method, RETVAL) ;

	OUTPUT:
		RETVAL

# /*---------------------------------------------------------------------------------------------------*/
# /* UNSUPPORTED */

int
ADAV::STORESIZE(int size)

	INIT:
		ADA_METHOD(STORESIZE);

	CODE:
		ADA_CHECK_THIS ;
		ADA_UNEXPECTED_CALL ;

	OUTPUT:
		RETVAL


# /*---------------------------------------------------------------------------------------------------*/
# /* Clear the array - only supported for filtered/logo array  */

void
ADAV::CLEAR()

	INIT:
		ADA_METHOD(CLEAR);

	CODE:
		ADA_CHECK_THIS ;

		if (THIS->type == ADAV_ADATA)
		{
			ADA_UNEXPECTED_CALL ;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			THIS->filter_data.num_elems = 0 ;
		}
		else if (THIS->type == ADAV_LOGO)
		{
			THIS->logo_data.num_elems = 0 ;
		}
		else if (THIS->type == ADAV_CSV)
		{
			ADA_UNEXPECTED_CALL ;
		}
		ADA_END_THIS ;

# /*---------------------------------------------------------------------------------------------------*/
# /* Ignore - only valid for calling on filtered/logo/csv array */

void
ADAV::EXTEND(int size)

	INIT:
		ADA_METHOD(EXTEND);

	CODE:
		ADA_CHECK_THIS ;

		if (THIS->type == ADAV_ADATA)
		{
			ADA_UNEXPECTED_CALL ;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			// do nothing
		}
		else if (THIS->type == ADAV_LOGO)
		{
			// do nothing
		}
		else if (THIS->type == ADAV_CSV)
		{
			// do nothing
		}

		ADA_END_THIS ;


# /*---------------------------------------------------------------------------------------------------*/
# /*  */

void
ADAV::EXISTS(int idx)

	INIT:
		ADA_METHOD(EXISTS);

		HV *results ;
		int frame ;

	PPCODE:
		ADA_CHECK_THIS ;

		if (THIS->type == ADAV_ADATA)
		{
			if ((idx >= THIS->user_data->results_list_size) || (idx < 0))
				XSRETURN_NO ;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			if ((idx >= THIS->filter_data.num_elems) || (idx < 0))
				XSRETURN_NO ;
		}
		else if (THIS->type == ADAV_LOGO)
		{
			if ((idx >= THIS->logo_data.num_elems) || (idx < 0))
				XSRETURN_NO ;
		}
		else if (THIS->type == ADAV_CSV)
		{
			if ((idx >= THIS->csv_data.num_elems) || (idx < 0))
				XSRETURN_NO ;
		}
		ADA_END_THIS ;

		XSRETURN_YES;


# /*===================================================================================================*/


# /*---------------------------------------------------------------------------------------------------*/
# /* Update the gap count - only valid for filtered/logo array */

void
ADAV::update_gaps()

	INIT:
		ADA_METHOD(update_gaps);

	CODE:
		ADA_CHECK_THIS ;

		//fprintf(stderr, "ADAV:FETCHSIZE()\n") ;
		if (THIS->type == ADAV_ADATA)
		{
			ADA_UNEXPECTED_CALL ;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			filtered_update_gaps(THIS) ;
		}
		else if (THIS->type == ADAV_LOGO)
		{
			logo_update_gaps(THIS) ;
		}
		else if (THIS->type == ADAV_CSV)
		{
			ADA_UNEXPECTED_CALL ;
		}
		ADA_END_THIS ;


# /*---------------------------------------------------------------------------------------------------*/
# /* Add the key to all HASH entries - only valid for csv array */

void
ADAV::add_key(SV *key)

	INIT:
		ADA_METHOD(update_gaps);

	CODE:
		ADA_CHECK_THIS ;

		//fprintf(stderr, "ADAV:FETCHSIZE()\n") ;
		if (THIS->type == ADAV_ADATA)
		{
			ADA_UNEXPECTED_CALL ;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			ADA_UNEXPECTED_CALL ;
		}
		else if (THIS->type == ADAV_LOGO)
		{
			ADA_UNEXPECTED_CALL ;
		}
		else if (THIS->type == ADAV_CSV)
		{
			csv_add_key(THIS, key) ;
		}
		ADA_END_THIS ;


# /*---------------------------------------------------------------------------------------------------*/
# /* Check logo gap values - only valid for logo array */

void
ADAV::logo_frames_sanity(int frame)

	INIT:
		ADA_METHOD(logo_frames_sanity);

	CODE:
		ADA_CHECK_THIS_NODBG ;

		//fprintf(stderr, "ADAV:FETCHSIZE()\n") ;
		if (THIS->type == ADAV_ADATA)
		{
			ADA_UNEXPECTED_CALL ;
		}
		else if (THIS->type == ADAV_FILTERED)
		{
			ADA_UNEXPECTED_CALL ;
		}
		else if (THIS->type == ADAV_LOGO)
		{
			logo_frames_sanity(THIS, frame) ;
		}
		else if (THIS->type == ADAV_CSV)
		{
			ADA_UNEXPECTED_CALL ;
		}
		ADA_END_THIS ;

