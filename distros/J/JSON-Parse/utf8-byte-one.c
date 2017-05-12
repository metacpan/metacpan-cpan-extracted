    case BYTE_20_7F:
	ADDBYTE;
	goto string_start;

    case BYTE_C2_DF:
	ADDBYTE;
	goto byte_last_80_bf;

    case 0xE0:
	ADDBYTE;
	goto byte23_a0_bf;

    case BYTE_E1_EC:
	ADDBYTE;
	goto byte_penultimate_80_bf;

    case 0xED:
	ADDBYTE;
	goto byte23_80_9f;

    case BYTE_EE_EF:
	ADDBYTE;
	goto byte_penultimate_80_bf;

    case 0xF0:
	ADDBYTE;
	goto byte24_90_bf;

    case BYTE_F1_F3:
	ADDBYTE;
	goto byte24_80_bf;

    case 0xF4:
	ADDBYTE;
	goto byte24_80_8f;

