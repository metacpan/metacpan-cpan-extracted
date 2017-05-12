#define FAILUTF8(want)					\
    parser->bad_beginning = startofutf8string - 1;	\
    parser->bad_type = json_string;			\
    parser->bad_byte = parser->end - 1;			\
    parser->expected = want;				\
    parser->error = json_error_unexpected_character;	\
    failbadinput (parser)

 byte_last_80_bf:

    switch (NEXTBYTE) {

    case BYTE_80_BF:
	ADDBYTE;
	goto string_start;
    default:
	FAILUTF8 (XBYTES_80_BF);
    }

 byte_penultimate_80_bf:

    switch (NEXTBYTE) {

    case BYTE_80_BF:
	ADDBYTE;
	goto byte_last_80_bf;
    default:
	FAILUTF8 (XBYTES_80_BF);
    }

 byte24_90_bf:

    switch (NEXTBYTE) {

    case BYTE_90_BF:
	ADDBYTE;
	goto byte_penultimate_80_bf;
    default:
	FAILUTF8 (XBYTES_90_BF);
    }

 byte23_80_9f:

    switch (NEXTBYTE) {

    case BYTE_80_9F:
	ADDBYTE;
	goto byte_last_80_bf;
    default:
	FAILUTF8 (XBYTES_80_9F);
    }

 byte23_a0_bf:

    switch (NEXTBYTE) {

    case BYTE_A0_BF:
	ADDBYTE;
	goto byte_last_80_bf;
    default:
	FAILUTF8 (XBYTES_A0_BF);
    }

 byte24_80_bf:

    switch (NEXTBYTE) {

    case BYTE_80_BF:
	ADDBYTE;
	goto byte_penultimate_80_bf;
    default:
	FAILUTF8 (XBYTES_80_BF);
    }

 byte24_80_8f:

    switch (NEXTBYTE) {

    case BYTE_80_8F:
	ADDBYTE;
	goto byte_penultimate_80_bf;
    default:
	FAILUTF8 (XBYTES_80_8F);
    }
