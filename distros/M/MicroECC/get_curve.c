#include "uECC.h"


/*
#if uECC_SUPPORTS_secp160r1
uECC_Curve uECC_secp160r1(void);
#endif
#if uECC_SUPPORTS_secp192r1
uECC_Curve uECC_secp192r1(void);
#endif
#if uECC_SUPPORTS_secp224r1
uECC_Curve uECC_secp224r1(void);
#endif
#if uECC_SUPPORTS_secp256r1
uECC_Curve uECC_secp256r1(void);
#endif
#if uECC_SUPPORTS_secp256k1
uECC_Curve uECC_secp256k1(void);
#endif
*/

uECC_Curve get_curve(int i) {
	uECC_Curve curve;
	switch(i) {

		case 0:
			curve = uECC_secp160r1();
			break;

		case 1:
			curve = uECC_secp192r1();
			break;

		case 2:
			curve = uECC_secp224r1();
			break;
			
		case 3:
			curve =  uECC_secp256r1();
			break;

		case 4:
			curve = uECC_secp256k1();
			break;

		default:
			curve = uECC_secp256k1();
			break;
	}

	return curve;
}
