


 # /*---------------------------------------------------------------------------------------------------*/
 # /* Use the specified parameters (or AUTO) to tune the frontend */

int
dvb_tune (DVB *dvb, HV *parameters)
    INIT:
		SV **val;

		int frequency=0;

		/* We hope that any unset params will cope just using the AUTO option */
		int inversion=TUNING_AUTO;
		int bandwidth=TUNING_AUTO;
		int code_rate_high=TUNING_AUTO;
		int code_rate_low=TUNING_AUTO;
		int modulation=TUNING_AUTO;
		int transmission=TUNING_AUTO;
		int guard_interval=TUNING_AUTO;
		int hierarchy=TUNING_AUTO;

		int timeout=DEFAULT_TIMEOUT;

	CODE:

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, " == DVBT.xs::dvb_tune() ================\n") ;
 }

		/* Read all those HASH values that are actually set into discrete variables */
		HVF_I(parameters, frequency) ;
		HVF_I(parameters, inversion) ;
		HVF_I(parameters, bandwidth) ;
		HVF_I(parameters, code_rate_high) ;
		HVF_I(parameters, code_rate_low) ;
		HVF_I(parameters, modulation) ;
		HVF_I(parameters, transmission) ;
		HVF_I(parameters, guard_interval) ;
		HVF_I(parameters, hierarchy) ;
		HVF_I(parameters, timeout) ;

		if (frequency <= 0)
	          croak ("Linux::DVB::DVBT::dvb_tune requires a valid frequency");

		/* use 3x global timeout for tuning */
		timeout *= 3 ;

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, "#@f DVBT.xs::dvb_tune() : tuning freq=%d Hz, inv=(%d) "
		"bandwidth=(%d) code_rate=(%d - %d) constellation=(%d) "
		"transmission=(%d) guard=(%d) hierarchy=(%d)\n",
		frequency,
		inversion,
		bandwidth,
		code_rate_high,
		code_rate_low,
		modulation,
		transmission,
		guard_interval,
		hierarchy
	) ;
 }

		// set tuning
		RETVAL = dvb_tune(dvb,
				/* For frontend tuning */
				frequency,
				inversion,
				bandwidth,
				code_rate_high,
				code_rate_low,
				modulation,
				transmission,
				guard_interval,
				hierarchy,
				timeout) ;

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, " rc = %d\n", RETVAL) ;
	fprintf(stderr, " == DVBT.xs::dvb_tune() - END ================\n") ;
 }

	OUTPUT:
        RETVAL


 # /*---------------------------------------------------------------------------------------------------*/
 # /* Same as dvb_tune() but ensures that the frequency tuned to is added to the scan list */
int
dvb_scan_tune (DVB *dvb, HV *parameters)
    INIT:
		SV **val;

		int frequency=0;

		/* We hope that any unset params will cope just using the AUTO option */
		int inversion=TUNING_AUTO;
		int bandwidth=TUNING_AUTO;
		int code_rate_high=TUNING_AUTO;
		int code_rate_low=TUNING_AUTO;
		int modulation=TUNING_AUTO;
		int transmission=TUNING_AUTO;
		int guard_interval=TUNING_AUTO;
		int hierarchy=TUNING_AUTO;

		int timeout=DEFAULT_TIMEOUT;

	CODE:

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, " == DVBT.xs::dvb_scan_tune() ================\n") ;
 }

		/* Read all those HASH values that are actually set into discrete variables */
		HVF_I(parameters, frequency) ;
		HVF_I(parameters, inversion) ;
		HVF_I(parameters, bandwidth) ;
		HVF_I(parameters, code_rate_high) ;
		HVF_I(parameters, code_rate_low) ;
		HVF_I(parameters, modulation) ;
		HVF_I(parameters, transmission) ;
		HVF_I(parameters, guard_interval) ;
		HVF_I(parameters, hierarchy) ;
		HVF_I(parameters, timeout) ;

		if (frequency <= 0)
	          croak ("Linux::DVB::DVBT::dvb_tune requires a valid frequency");

		/* use 3x global timeout for tuning */
		timeout *= 3 ;

 if (DVBT_DEBUG >= 10)
 {
	fprintf(stderr, "#@f DVBT.xs::dvb_scan_tune() : tuning freq=%d Hz, inv=(%d) "
		"bandwidth=(%d) code_rate=(%d - %d) constellation=(%d) "
		"transmission=(%d) guard=(%d) hierarchy=(%d)\n",
		frequency,
		inversion,
		bandwidth,
		code_rate_high,
		code_rate_low,
		modulation,
		transmission,
		guard_interval,
		hierarchy
	) ;
 }

		// set tuning
		RETVAL = dvb_scan_tune(dvb,
				/* For frontend tuning */
				frequency,
				inversion,
				bandwidth,
				code_rate_high,
				code_rate_low,
				modulation,
				transmission,
				guard_interval,
				hierarchy,
				timeout) ;

	OUTPUT:
        RETVAL


# /*---------------------------------------------------------------------------------------------------*/
# /* Get frontend signal stats */
SV *
dvb_signal_quality(DVB *dvb)

 INIT:
   HV * results;
	unsigned 		ber ;
	unsigned		snr ;
	unsigned		strength ;
	unsigned		uncorrected_blocks ;
	int ok ;

   results = (HV *)sv_2mortal((SV *)newHV());

 CODE:
 	/* get info */
   ok = dvb_signal_quality(dvb, &ber, &snr, &strength, &uncorrected_blocks) ;

 	/** Create Perl data **/
	HVS(results, ber, newSViv((int)ber)) ;
	HVS(results, snr, newSViv((int)snr)) ;
	HVS(results, strength, newSViv((int)strength)) ;
	HVS(results, uncorrected_blocks, newSViv((int)uncorrected_blocks)) ;
	HVS(results, ok, newSViv(ok)) ;

   RETVAL = newRV((SV *)results);
 OUTPUT:
   RETVAL

# /*---------------------------------------------------------------------------------------------------*/
# /* Round up frequency */
int
dvb_round_freq(int freqin)

 CODE:
   RETVAL = ROUND_FREQUENCY(freqin) ;
 OUTPUT:
   RETVAL

# /*---------------------------------------------------------------------------------------------------*/
# /* See if this adapter frontend is busy */
int
dvb_is_busy(DVB *dvb)

 CODE:
   RETVAL = dvb_frontend_is_busy(dvb) ;
 OUTPUT:
   RETVAL

