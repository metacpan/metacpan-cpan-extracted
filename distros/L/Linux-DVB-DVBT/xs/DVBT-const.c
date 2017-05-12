# /*---------------------------------------------------------------------------------------------------*/

# /*---------------------------------------------------------------------------------------------------*/

BOOT:
	HV *globals ;
	HV *rh, *rh2 ;
#
	globals = get_hv("Linux::DVB::DVBT::Constants::CONSTANTS", TRUE) ;
	HVS_INT(globals, FRAMES_PER_SEC, FPS) ;
#
# /* Dummy to get around the "used only once: possible typo" warning */
	globals = get_hv("Linux::DVB::DVBT::Constants::CONSTANTS", FALSE) ;
#



