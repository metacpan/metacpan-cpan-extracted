# /*---------------------------------------------------------------------------------------------------*/

# /*---------------------------------------------------------------------------------------------------*/

BOOT:
	HV *globals ;
	HV *rh, *rh2 ;
#
	globals = get_hv("Linux::DVB::DVBT::Advert::Constants::CONSTANTS", TRUE) ;
	HVS_INT(globals, FRAMES_PER_SEC, FPS) ;
#
	rh = (HV *)sv_2mortal((SV *)newHV());
	rh2 = (HV *)sv_2mortal((SV *)newHV());
	HVS_INT(rh2, BLACK, METHOD_BLACK) ;
	HVS_INT(rh2, LOGO,  METHOD_LOGO) ;
	HVS_INT(rh2, AUDIO, METHOD_AUDIO) ;
	HVS_INT(rh2, BANNER, METHOD_BANNER) ;
	HVS(rh, detection_method, newRV((SV *)rh2)) ;
#
	rh2 = (HV *)sv_2mortal((SV *)newHV());
	HVS_INT(rh2, MIN,   METHOD_MIN) ;
	HVS_INT(rh2, DEFAULT, METHOD_DEFAULT) ;
	HVS(rh, detection_method_special, newRV((SV *)rh2)) ;
#
	HVS(globals, Advert, newRV((SV *)rh)) ;
#


