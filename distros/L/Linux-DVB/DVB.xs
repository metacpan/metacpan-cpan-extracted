#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>

#include <linux/dvb/frontend.h>
#include <linux/dvb/dmx.h>

#define CONST(name) { #name, name }

typedef int FE_fd;

enum {
  SCT_PAT                  = 0x00,
  SCT_CAT                  = 0x01,
  SCT_PMT                  = 0x02,
  SCT_TSDT                 = 0x03,
  SCT_NIT                  = 0x40,//TODO
  SCT_NIT_OTHER            = 0x41,
  SCT_SDT                  = 0x42,
  SCT_SDT_OTHER            = 0x46,
  SCT_BAT                  = 0x4a,//TODO
  SCT_EIT_PRESENT          = 0x4e,
  SCT_EIT_PRESENT_OTHER    = 0x4f,
  SCT_EIT_SCHEDULE0        = 0x50,
  SCT_EIT_SCHEDULE15       = 0x5f,
  SCT_EIT_SCHEDULE_OTHER0  = 0x60,
  SCT_EIT_SCHEDULE_OTHER15 = 0x6f,
  SCT_TDT                  = 0x70,
  SCT_RST                  = 0x71,
  SCT_ST                   = 0x72,
  SCT_TOT                  = 0x73,
  SCT_RNT                  = 0x74,
  SCT_CST                  = 0x75,
  SCT_RCT                  = 0x76,
  SCT_CIT                  = 0x77,
  SCT_MPE                  = 0x78,
  SCT_DIT                  = 0x7e,
  SCT_SIT                  = 0x7f,
};

enum {
  DT_network_name                = 0x40,
  DT_service_list                = 0x41,
  DT_satellite_delivery_system   = 0x43,
  DT_cable_delivery_system       = 0x44,
  DT_service                     = 0x48,
  DT_country_availability        = 0x49,
  DT_linkage                     = 0x4a,
  DT_short_event                 = 0x4d,
  DT_extended_event              = 0x4e, //NYI
  DT_component                   = 0x50,
  DT_content                     = 0x54,
  DT_terrestrial_delivery_system = 0x5A,
  DT_private_data_specifier      = 0x5f,
  DT_short_smoothing_buffer      = 0x61, //NYI
  DT_scrambling_indicator        = 0x65, //NYI
  DT_PDC                         = 0x69,
};

static const struct consts {
  const char *name;
  const long value;
} consts [] = {
  CONST (FE_QPSK),
  CONST (FE_QAM),
  CONST (FE_OFDM),

  CONST (FE_IS_STUPID),
  CONST (FE_CAN_INVERSION_AUTO),
  CONST (FE_CAN_FEC_1_2),
  CONST (FE_CAN_FEC_2_3),
  CONST (FE_CAN_FEC_3_4),
  CONST (FE_CAN_FEC_4_5),
  CONST (FE_CAN_FEC_5_6),
  CONST (FE_CAN_FEC_6_7),
  CONST (FE_CAN_FEC_7_8),
  CONST (FE_CAN_FEC_8_9),
  CONST (FE_CAN_FEC_AUTO),
  CONST (FE_CAN_QPSK),
  CONST (FE_CAN_QAM_16),
  CONST (FE_CAN_QAM_32),
  CONST (FE_CAN_QAM_64),
  CONST (FE_CAN_QAM_128),
  CONST (FE_CAN_QAM_256),
  CONST (FE_CAN_QAM_AUTO),
  CONST (FE_CAN_TRANSMISSION_MODE_AUTO),
  CONST (FE_CAN_BANDWIDTH_AUTO),
  CONST (FE_CAN_GUARD_INTERVAL_AUTO),
  CONST (FE_CAN_HIERARCHY_AUTO),
  CONST (FE_NEEDS_BENDING),
  CONST (FE_CAN_RECOVER),
  CONST (FE_CAN_MUTE_TS),

  CONST (FE_HAS_SIGNAL),
  CONST (FE_HAS_CARRIER),
  CONST (FE_HAS_VITERBI),
  CONST (FE_HAS_SYNC),
  CONST (FE_HAS_LOCK),
  CONST (FE_TIMEDOUT),
  CONST (FE_REINIT),

  CONST (INVERSION_OFF),
  CONST (INVERSION_ON),
  CONST (INVERSION_AUTO),

  CONST (FEC_NONE),
  CONST (FEC_1_2),
  CONST (FEC_2_3),
  CONST (FEC_3_4),
  CONST (FEC_4_5),
  CONST (FEC_5_6),
  CONST (FEC_6_7),
  CONST (FEC_7_8),
  CONST (FEC_8_9),
  CONST (FEC_AUTO),

  CONST (QPSK),
  CONST (QAM_16),
  CONST (QAM_32),
  CONST (QAM_64),
  CONST (QAM_128),
  CONST (QAM_256),
  CONST (QAM_AUTO),

  CONST (TRANSMISSION_MODE_2K),
  CONST (TRANSMISSION_MODE_8K),
  CONST (TRANSMISSION_MODE_AUTO),

  CONST (BANDWIDTH_8_MHZ),
  CONST (BANDWIDTH_7_MHZ),
  CONST (BANDWIDTH_6_MHZ),
  CONST (BANDWIDTH_AUTO),

  CONST (GUARD_INTERVAL_1_32),
  CONST (GUARD_INTERVAL_1_16),
  CONST (GUARD_INTERVAL_1_8),
  CONST (GUARD_INTERVAL_1_4),
  CONST (GUARD_INTERVAL_AUTO),

  CONST (HIERARCHY_NONE),
  CONST (HIERARCHY_1),
  CONST (HIERARCHY_2),
  CONST (HIERARCHY_4),
  CONST (HIERARCHY_AUTO),

  CONST (DMX_OUT_DECODER),
  CONST (DMX_OUT_TAP),
  CONST (DMX_OUT_TS_TAP),

  CONST (DMX_IN_FRONTEND),
  CONST (DMX_IN_DVR),

  CONST (DMX_PES_AUDIO0),
  CONST (DMX_PES_VIDEO0),
  CONST (DMX_PES_TELETEXT0),
  CONST (DMX_PES_SUBTITLE0),
  CONST (DMX_PES_PCR0),

  CONST (DMX_PES_AUDIO1),
  CONST (DMX_PES_VIDEO1),
  CONST (DMX_PES_TELETEXT1),
  CONST (DMX_PES_SUBTITLE1),
  CONST (DMX_PES_PCR1),

  CONST (DMX_PES_AUDIO2),
  CONST (DMX_PES_VIDEO2),
  CONST (DMX_PES_TELETEXT2),
  CONST (DMX_PES_SUBTITLE2),
  CONST (DMX_PES_PCR2),

  CONST (DMX_PES_AUDIO3),
  CONST (DMX_PES_VIDEO3),
  CONST (DMX_PES_TELETEXT3),
  CONST (DMX_PES_SUBTITLE3),
  CONST (DMX_PES_PCR3),

  CONST (DMX_PES_OTHER),

  CONST (DMX_PES_AUDIO),
  CONST (DMX_PES_VIDEO),
  CONST (DMX_PES_TELETEXT),
  CONST (DMX_PES_SUBTITLE),
  CONST (DMX_PES_PCR),

  //CONST (DMX_SCRAMBLING_EV),
  //CONST (DMX_FRONTEND_EV),

  CONST (DMX_CHECK_CRC),
  CONST (DMX_ONESHOT),
  CONST (DMX_IMMEDIATE_START),
  CONST (DMX_KERNEL_CLIENT),

  CONST (DMX_SOURCE_FRONT0),
  CONST (DMX_SOURCE_FRONT1),
  CONST (DMX_SOURCE_FRONT2),
  CONST (DMX_SOURCE_FRONT3),

  CONST (DMX_SOURCE_DVR0),
  CONST (DMX_SOURCE_DVR1),
  CONST (DMX_SOURCE_DVR2),
  CONST (DMX_SOURCE_DVR3),

  //CONST (DMX_SCRAMBLING_OFF),
  //CONST (DMX_SCRAMBLING_ON),

  // constants defined by this file
  CONST (SCT_PAT),
  CONST (SCT_CAT),
  CONST (SCT_PMT),
  CONST (SCT_TSDT),
  CONST (SCT_NIT),
  CONST (SCT_NIT_OTHER),
  CONST (SCT_SDT),
  CONST (SCT_SDT_OTHER),
  CONST (SCT_BAT),
  CONST (SCT_EIT_PRESENT),
  CONST (SCT_EIT_PRESENT_OTHER),
  CONST (SCT_EIT_SCHEDULE0),
  CONST (SCT_EIT_SCHEDULE15),
  CONST (SCT_EIT_SCHEDULE_OTHER0),
  CONST (SCT_EIT_SCHEDULE_OTHER15),
  CONST (SCT_TDT),
  CONST (SCT_RST),
  CONST (SCT_ST),
  CONST (SCT_TOT),
  CONST (SCT_RNT),
  CONST (SCT_CST),
  CONST (SCT_RCT),
  CONST (SCT_CIT),
  CONST (SCT_MPE),
  CONST (SCT_DIT),
  CONST (SCT_SIT),

  CONST (DT_network_name),
  CONST (DT_service_list),
  CONST (DT_satellite_delivery_system),
  CONST (DT_cable_delivery_system),
  CONST (DT_service),
  CONST (DT_country_availability),
  CONST (DT_linkage),
  CONST (DT_short_event),
  CONST (DT_extended_event),
  CONST (DT_component),
  CONST (DT_content),
  CONST (DT_terrestrial_delivery_system),
  CONST (DT_private_data_specifier),
  CONST (DT_short_smoothing_buffer),
  CONST (DT_scrambling_indicator),
  CONST (DT_PDC),
};

#define HVS_S(hv,struct,member) hv_store (hv, #member, sizeof (#member) - 1, newSVpv (struct.member, 0), 0)
#define HVS_I(hv,struct,member) hv_store (hv, #member, sizeof (#member) - 1, newSViv (struct.member), 0)
#define HVS(hv,name,sv) hv_store (hv, #name, sizeof (#name) - 1, (sv), 0)

static void
get_parameters (HV *hv, struct dvb_frontend_parameters *p, fe_type_t type)
{
  HVS_I (hv, (*p), frequency);
  HVS_I (hv, (*p), inversion);

  switch (type)
    {
      case FE_QPSK:
        HVS_I (hv, (*p).u.qpsk, symbol_rate);
        HVS_I (hv, (*p).u.qpsk, fec_inner);
        break;

      case FE_QAM:
        HVS_I (hv, (*p).u.qam, symbol_rate);
        HVS_I (hv, (*p).u.qam, fec_inner);
        HVS_I (hv, (*p).u.qam, modulation);
        break;

      case FE_OFDM:
        HVS_I (hv, (*p).u.ofdm, bandwidth);
        HVS_I (hv, (*p).u.ofdm, code_rate_HP);
        HVS_I (hv, (*p).u.ofdm, code_rate_LP);
        HVS_I (hv, (*p).u.ofdm, constellation);
        HVS_I (hv, (*p).u.ofdm, transmission_mode);
        break;
    }
}

#define HVF_I(hv,struct,member)                                 \
  if (v = hv_fetch (hv, #member, sizeof (#member) - 1, 0))	\
    struct.member = SvIV (*v);					\
  else								\
    croak ("required hash key '%s' not specified", #member);

static void
set_parameters (HV *hv, struct dvb_frontend_parameters *p, fe_type_t type)
{
  SV **v;

  HVF_I (hv, (*p), frequency);
  HVF_I (hv, (*p), inversion);

  switch (type)
    {
      case FE_QPSK:
        HVF_I (hv, (*p).u.qpsk, symbol_rate);
        HVF_I (hv, (*p).u.qpsk, fec_inner);
        break;

      case FE_QAM:
        HVF_I (hv, (*p).u.qam, symbol_rate);
        HVF_I (hv, (*p).u.qam, fec_inner);
        HVF_I (hv, (*p).u.qam, modulation);
        break;

      case FE_OFDM:
        HVF_I (hv, (*p).u.ofdm, bandwidth);
        HVF_I (hv, (*p).u.ofdm, code_rate_HP);
        HVF_I (hv, (*p).u.ofdm, code_rate_LP);
        HVF_I (hv, (*p).u.ofdm, constellation);
        HVF_I (hv, (*p).u.ofdm, transmission_mode);
        break;
    }
}

typedef unsigned char u8;

static SV *dec_sv;
static u8 *dec_data;
static long dec_ofs, dec_len8;
static U32 dec_field;
STRLEN dec_len;

#define decode_overflow (dec_ofs > dec_len8)

static void
decode_set (SV *data)
{
  if (dec_sv) 
    SvREFCNT_dec (dec_sv);

  dec_sv   = newSVsv (data);
  dec_data = (u8 *)SvPVbyte (dec_sv, dec_len);
  dec_ofs  = 0;
  dec_len8 = dec_len << 3;
}

static U32
decode_field (int bits)
{
  u8 *p = dec_data + (dec_ofs >> 3);
  int frac = 8 - (dec_ofs & 7);
  dec_ofs += bits;

  if (decode_overflow)
    return dec_field = 0;

  U32 r = *p++;

  r &= (1UL << frac) - 1;
  
  if (bits < frac)
    r >>= (frac - bits);
  else
    {
      bits -= frac;

      while (bits >= 8)
        {
          r = (r << 8) | *p++;
          bits -= 8;
        }

      if (bits > 0)
        r = (r << bits) | (*p >> (8 - bits));
    }

  return dec_field = r;
}

U32
clamp (U32 len)
{
  return len < 4096
         && len <= dec_len8 - (dec_ofs >> 3) + 1 /* +1 to detect overflows */
            ? len : 0;
}

/* works on SvPOK strings ONLY */
void
safe_sv_chop (SV *sv, STRLEN count)
{
  if ((U32)count >= (U32)SvCUR (sv))
    SvCUR_set (sv, 0);
  else
    sv_chop (sv, SvPVX (sv) + count);
}

U32
bcd_to_int (U32 bcd_number)
{
  U32 result = 0;
  U32 multiplicator = 1;

  while (bcd_number != 0) 
    {
      result += (bcd_number & 0x0f) * multiplicator;
      bcd_number >>= 4;
      multiplicator *= 10;
    }

  return result;
}

static SV *
text2sv (u8 *data, U32 len)
{
  dSP;
  SV *sv = newSVpvn ((char *)data, clamp (len));

  PUSHMARK (SP);
  XPUSHs (sv);
  PUTBACK;
  call_pv ("Linux::DVB::Decode::text", G_VOID);

  return sv;
}

#define DEC_I(hv, bits, name)  HVS (hv, name, newSViv (decode_field (bits)))
#define DEC_T(hv, bytes, name) HVS (hv, name, text2sv (dec_data + (dec_ofs >> 3), clamp (bytes))), dec_ofs += clamp (bytes) << 3
#define DEC_S(hv, bytes, name) HVS (hv, name, newSVpvn ((char *)dec_data + (dec_ofs >> 3), clamp (bytes))), dec_ofs += clamp (bytes) << 3

static AV *
decode_descriptors (long end)
{
  AV *av = newAV ();

  while (dec_ofs < end)
    {
      HV *hv = newHV ();
      U8 type, len, len2;
      AV *av2;
      long end, end2;

      av_push (av, newRV_noinc ((SV *)hv));
      
      DEC_I (hv, 8, type);
      type = dec_field;
      len = decode_field (8);
      end = dec_ofs + (len << 3);
      
      if (end > dec_len8)
        return av;

      switch (type)
        {
          case DT_network_name:
            DEC_T (hv, (end - dec_ofs) >> 3, network_name);
            break;

	  case DT_service_list:
            {
              AV *services = newAV ();
              HVS (hv, services, newRV_noinc ((SV *)services));

	      while (dec_ofs < end) 
                {
                  HV *sv = newHV ();
                  av_push (services, newRV_noinc ((SV *)sv));

                  DEC_I (sv, 16, service_id);
                  DEC_I (sv,  8, service_type);

	        }
            }

	    break;

	  case DT_satellite_delivery_system: 
	    HVS (hv, frequency, newSVuv (bcd_to_int (decode_field (32))));
	    HVS (hv, orbital_position, newSVnv (bcd_to_int (decode_field (32)) / 10));
	    DEC_I (hv,  1, west_east_flag);
	    DEC_I (hv,  2, polarization);
	    DEC_I (hv,  5, modulation);
	    HVS (hv, symbol_rate, newSVuv (bcd_to_int (decode_field (28))));
	    DEC_I (hv,  4, fec_inner);
	    break;

	  case DT_cable_delivery_system: 
	    {
	      I16 qam_modulation = -1;

	      HVS (hv, frequency, newSVuv (bcd_to_int (decode_field (32))));
	      decode_field (12); // reserved
	      DEC_I (hv,  4, fec_outer);

	      DEC_I (hv,  8, modulation);

	      if (dec_field >= 1 && dec_field <= 5) 
	        qam_modulation = 1 << dec_field + 3;

	      HVS (hv, modulation_qam, newSViv (qam_modulation));

	      HVS (hv, symbol_rate, newSVuv (bcd_to_int (decode_field (28))));
	      DEC_I (hv,  4, fec_inner);

	      break;
	    }

          case DT_service:
            DEC_I (hv,  8, service_type);
            len2 = decode_field (8); DEC_T (hv, len2, service_provider_name);
            len2 = decode_field (8); DEC_T (hv, len2, service_name);
            break;

          case DT_country_availability:
            DEC_I (hv, 1, country_availability_flag);
            decode_field (7);

            DEC_S (hv, (end - dec_ofs) >> 3, private_data);
            //while (dec_ofs + 24 <= end)
            //  av_push (av, 
            break;

          case DT_linkage:
            DEC_I (hv, 16, transport_stream_id);
            DEC_I (hv, 16, original_network_id);
            DEC_I (hv, 16, service_id);
            DEC_I (hv,  8, linkage_type);

            if (dec_field == 8)
              {
                U32 hot, org;

                DEC_I (hv, 8, hand_over_type); hot = dec_field;
                decode_field (3);
                DEC_I (hv, 1, origin_type); org = dec_field;

                if (hot > 0x00 && hot < 0x04)
                  DEC_I (hv, 16, network_id);

                if (org == 0)
                  DEC_I (hv, 16, initial_service_id);
              }

            DEC_S (hv, (end - dec_ofs) >> 3, private_data);
            break;

          case DT_PDC:
            decode_field (4);
            DEC_I (hv, 20, programme_identification_label);
            break;

          case DT_component:
            decode_field (4);
            DEC_I (hv, 4, stream_content);
            DEC_I (hv, 8, component_type);
            DEC_I (hv, 8, component_tag);
            DEC_S (hv, 3, ISO_639_language_code);
            DEC_T (hv, (end - dec_ofs) >> 3, text);
            break;

          case DT_short_event:
            DEC_S (hv, 3, ISO_639_language_code);
            len2 = decode_field (8); DEC_T (hv, len2, event_name);
            len2 = decode_field (8); DEC_T (hv, len2, text);
            break;

          case DT_extended_event:
            DEC_I (hv, 4, descriptor_number);
            DEC_I (hv, 4, last_descriptor_number);
            DEC_S (hv, 3, ISO_639_language_code);

            len2 = decode_field (8); end2 = dec_ofs + (len2 << 3);
            av2 = newAV ();
            HVS (hv, items, newRV_noinc ((SV *)av2));

            while (dec_ofs < end2)
              {
                AV *av3 = newAV ();
                len2 = decode_field (8); av_push (av3, text2sv (dec_data + (dec_ofs >> 3), len2)), dec_ofs += len << 3;
                len2 = decode_field (8); av_push (av3, text2sv (dec_data + (dec_ofs >> 3), len2)), dec_ofs += len << 3;

                av_push (av2, newRV_noinc ((SV *)av3));
              }

            len2 = decode_field (8); DEC_T (hv, len2, text);
            break;

          case DT_content:
            av2 = newAV ();
            HVS (hv, items, newRV_noinc ((SV *)av2));
 
            while (dec_ofs < end)
              {
                HV *ev = newHV ();
 
                DEC_I (ev, 4, content_nibble_level_1);
                DEC_I (ev, 4, content_nibble_level_2);
                DEC_I (ev, 4, user_nibble_1);
                DEC_I (ev, 4, user_nibble_2);

                av_push (av2, newRV_noinc ((SV *)ev));
             }

            break;

	  case DT_terrestrial_delivery_system:
	    {
	      I8 bandwidth_mhz = -1;
	    
	      HVS (hv, centre_frequency, newSVuv (decode_field (32) * 10));

	      DEC_I (hv,  3, bandwidth);

	      if (dec_field <= 3) 
	        bandwidth_mhz = 8 - dec_field;

	      HVS (hv, bandwidth_mhz, newSViv (bandwidth_mhz));

	      DEC_I (hv,  1, priority);
	      DEC_I (hv,  1, time_slicing_indicator);
	      DEC_I (hv,  1, mpe_fec_indicator);
	      decode_field (2); // reserved
	      DEC_I (hv,  2, constellation);
	      DEC_I (hv,  3, hierarchy_information);
	      DEC_I (hv,  3, code_rate_hp_stream);
	      DEC_I (hv,  3, code_rate_lp_stream);
	      DEC_I (hv,  2, guard_interval);
	      DEC_I (hv,  2, transmission_mode);
	      DEC_I (hv,  1, other_frequency_use);
	      decode_field (32);
	    }
	    break;

          case DT_private_data_specifier:
            DEC_I (hv, 32, private_data_specifier);
            break;
           
          default:
            //fprintf (stderr, "UNKXXX %x\n", type);//D

          case 0:
          case 0x80:
          case 0x81:
          case 0x82:
          case 0x83:
          case 0x84:
          case 0x85:
          case 0x8d:
          case 0x8e:
          case 0xb2:
            DEC_S (hv, len, raw_data);
            break;
        }

      dec_ofs = end; // re-sync, in case of problems
    }

  return av;
}

MODULE = Linux::DVB		PACKAGE = Linux::DVB

PROTOTYPES: DISABLE

void
_consts ()
	PPCODE:
        const struct consts *c;
        for (c = consts;
             c < consts + sizeof (consts) / sizeof (consts[0]);
             c++)
          {
            XPUSHs (sv_2mortal (newSVpv (c->name, 0)));
            XPUSHs (sv_2mortal (newSViv (c->value)));
          }

MODULE = Linux::DVB		PACKAGE = Linux::DVB::Frontend

SV *
frontend_info (FE_fd fd)
	CODE:
        struct dvb_frontend_info fi;
        HV *hv;

        if (ioctl (fd, FE_GET_INFO, &fi) < 0)
	  XSRETURN_UNDEF;

        hv = newHV ();
        HVS_S (hv, fi, name);
        HVS_I (hv, fi, type);
	HVS_I (hv, fi, type);
	HVS_I (hv, fi, frequency_min);
	HVS_I (hv, fi, frequency_max);
	HVS_I (hv, fi, frequency_stepsize);
	HVS_I (hv, fi, frequency_tolerance);
	HVS_I (hv, fi, symbol_rate_min);
	HVS_I (hv, fi, symbol_rate_max);
	HVS_I (hv, fi, symbol_rate_tolerance);
	HVS_I (hv, fi, notifier_delay);
	HVS_I (hv, fi, caps);

        RETVAL = (SV *)newRV_noinc ((SV *)hv);
	OUTPUT:
        RETVAL

long
read_status (FE_fd fd)
	CODE:
        fe_status_t st;

        if (ioctl (fd, FE_READ_STATUS, &st) < 0)
	  XSRETURN_UNDEF;

        RETVAL = st;
	OUTPUT:
        RETVAL

U32
read_ber (FE_fd fd)
	CODE:
        uint32_t ber;
        if (ioctl (fd, FE_READ_BER, &ber) < 0)
	  XSRETURN_UNDEF;

        RETVAL = ber;
	OUTPUT:
        RETVAL

U32
read_snr (FE_fd fd)
	CODE:
        uint32_t ber;
        if (ioctl (fd, FE_READ_SNR, &ber) < 0)
	  XSRETURN_UNDEF;

        RETVAL = ber;
	OUTPUT:
        RETVAL


I16
signal_strength (FE_fd fd)
	CODE:
        int16_t st;
        if (ioctl (fd, FE_READ_SIGNAL_STRENGTH, &st) < 0)
	  XSRETURN_UNDEF;

        RETVAL = st;
	OUTPUT:
        RETVAL


U32
uncorrected_blocks (FE_fd fd)
	CODE:
        uint32_t ubl;
        if (ioctl (fd, FE_READ_UNCORRECTED_BLOCKS, &ubl) < 0)
	  XSRETURN_UNDEF;

        RETVAL = ubl;
	OUTPUT:
        RETVAL

int
_set (int fd, SV *parameters, int type)
	CODE:
        struct dvb_frontend_parameters p;

        if (!SvROK (parameters) || SvTYPE (SvRV (parameters)) != SVt_PVHV)
          croak ("Linux::DVB::Frontend::set requires a hash as argument");

        set_parameters ((HV *)SvRV (parameters), &p, type);

        if (ioctl (fd, FE_SET_FRONTEND, &p) < 0)
	  XSRETURN_UNDEF;

        RETVAL = 1;
	OUTPUT:
        RETVAL

SV *
_get (int fd, int type)
	CODE:
        struct dvb_frontend_parameters p;
        HV *hv;

        if (ioctl (fd, FE_GET_FRONTEND, &p) < 0)
	  XSRETURN_UNDEF;

        hv = newHV ();
        get_parameters (hv, &p, type);
        RETVAL = (SV *)newRV_noinc ((SV *)hv);
	OUTPUT:
        RETVAL

SV *
_event (int fd, int type)
	CODE:
        struct dvb_frontend_event e;
        HV *hv;

        if (ioctl (fd, FE_GET_EVENT, &e) < 0)
	  XSRETURN_UNDEF;

        hv = newHV ();
        HVS_I (hv, e, status);
        get_parameters (hv, &e.parameters, type);
        RETVAL = (SV *)newRV_noinc ((SV *)hv);
	OUTPUT:
        RETVAL

int
diseqc_reset_overload (FE_fd fd)
	CODE:
        RETVAL = !!ioctl (fd, FE_DISEQC_RESET_OVERLOAD);
	OUTPUT:
        RETVAL

int
diseqc_voltage (FE_fd fd, int volts)
	CODE:
        RETVAL = !!ioctl (fd, FE_SET_VOLTAGE, volts == 18
          ? SEC_VOLTAGE_18
          : SEC_VOLTAGE_13);
	OUTPUT:
        RETVAL

int
diseqc_tone (FE_fd fd, int on)
	CODE:
        RETVAL = !!ioctl (fd, FE_SET_TONE, on ? SEC_TONE_ON : SEC_TONE_OFF);
	OUTPUT:
        RETVAL

int
diseqc_send_burst (FE_fd fd, int type)
	CODE:
        RETVAL = !!ioctl (fd, FE_DISEQC_SEND_BURST, type ? SEC_MINI_B : SEC_MINI_A);
	OUTPUT:
        RETVAL

int
diseqc_cmd (FE_fd fd, SV *command_)
	CODE:
{
	STRLEN len;
	char *command = SvPVbyte (command_, len);
	struct dvb_diseqc_master_cmd cmd;

        memcpy (cmd.msg, command, len);
        cmd.msg_len = len;
        RETVAL = !!ioctl (fd, FE_DISEQC_SEND_MASTER_CMD, &cmd);
}
	OUTPUT:
        RETVAL

SV *
diseqc_reply (FE_fd fd, int timeout_ms)
	CODE:
{
	struct dvb_diseqc_slave_reply rep;
        rep.timeout = timeout_ms;

        if (!!ioctl (fd, FE_DISEQC_RECV_SLAVE_REPLY, &rep))
          RETVAL = newSVpvn ((char *)rep.msg, rep.msg_len);
        else
          RETVAL = &PL_sv_undef;
}
	OUTPUT:
        RETVAL

MODULE = Linux::DVB		PACKAGE = Linux::DVB::Demux

int
_start (int fd)
	ALIAS:
           _stop = 1
	CODE:
        if (ioctl (fd, ix ? DMX_STOP : DMX_START, 0) < 0)
	  XSRETURN_UNDEF;

        RETVAL = 1;
	OUTPUT:
        RETVAL

int
_filter (int fd, U16 pid, SV *filter, SV *mask, U32 timeout = 0, U32 flags = DMX_CHECK_CRC)
	CODE:
        struct dmx_sct_filter_params p;
        STRLEN l;
        char *s;

        memset (&p.filter, 0, sizeof (p.filter));

        p.pid = pid;
        s = SvPVbyte (filter, l); if (l > DMX_FILTER_SIZE) l = DMX_FILTER_SIZE; memcpy (p.filter.filter, s, l);
        s = SvPVbyte (mask  , l); if (l > DMX_FILTER_SIZE) l = DMX_FILTER_SIZE; memcpy (p.filter.mask  , s, l);
        p.timeout = timeout;
        p.flags = flags;
        if (ioctl (fd, DMX_SET_FILTER, &p) < 0)
	  XSRETURN_UNDEF;

        RETVAL = 1;
	OUTPUT:
        RETVAL

int
_pes_filter (int fd, U16 pid, long input, long output, long type, U32 flags = 0)
	CODE:
        struct dmx_pes_filter_params p;

        p.pid = pid;
        p.input = input;
        p.output = output;
        p.pes_type = type;
        p.flags = flags;
        if (ioctl (fd, DMX_SET_PES_FILTER, &p) < 0)
	  XSRETURN_UNDEF;

        RETVAL = 1;
	OUTPUT:
        RETVAL

int
_buffer (int fd, unsigned long size)
	CODE:

        if (ioctl (fd, DMX_SET_BUFFER_SIZE, size) < 0)
	  XSRETURN_UNDEF;

        RETVAL = 1;
	OUTPUT:
        RETVAL

MODULE = Linux::DVB		PACKAGE = Linux::DVB::Decode	PREFIX = decode_

void
decode_set (SV *data)
	CODE:

int
decode_len ()
	CODE:
        RETVAL = (dec_ofs + 7) >> 3;
	OUTPUT:
	RETVAL

U32
decode_field (int bits)

SV *
decode_si (SV *stream)
	CODE:
        HV *hv = newHV ();

        int syntax_indicator;
        U8 table_id;
        U16 length;
        long end;

        decode_set (stream);

        do {
          DEC_I (hv, 8, table_id);
          table_id = dec_field;
        } while (table_id == 0xff);

        syntax_indicator = decode_field (1);
        HVS (hv, section_syntax_indicator, newSViv (syntax_indicator));

        decode_field (1);
        decode_field (2);

        length = decode_field (12);
        end = dec_ofs + (length << 3);

        if (syntax_indicator)
	  {
            switch (table_id)
              {
                case SCT_NIT:
                case SCT_NIT_OTHER:
                  {
                    U16 descriptor_end_offset;

                    DEC_I (hv, 16, network_id);
                    decode_field (2); // reserved
                    DEC_I (hv,  5, version_number);
                    DEC_I (hv,  1, current_next_indicator);
                    DEC_I (hv,  8, section_number);
                    DEC_I (hv,  8, last_section_number);
                    decode_field (4); // reserved
                                            
                    AV *desc;
                    descriptor_end_offset = dec_ofs + (decode_field (12) << 3);
                    desc = decode_descriptors (descriptor_end_offset);
                    HVS (hv,network_descriptors, newRV_noinc ((SV *)desc));

                    decode_field (4); //reserved
                    decode_field (12); // Skip length, we read until the end

                    AV *events = newAV ();
                    HVS (hv, events, newRV_noinc ((SV *)events));
                    while (end - dec_ofs > 32) 
                      {
                        long dll;
                        HV *ev = newHV ();
                        av_push (events, newRV_noinc ((SV *)ev));

                        DEC_I (ev, 16, transport_stream_id);
                        DEC_I (ev, 16, original_network_id);
                        decode_field (4);

                        dll = dec_ofs + (decode_field (12) << 3);
                        desc = decode_descriptors (dll);
                        HVS (ev, descriptors, newRV_noinc ((SV *)desc));
                      }

                    decode_field (32); // skip CRC
                  }

                  break; 

                case SCT_EIT_PRESENT:
                case SCT_EIT_PRESENT_OTHER:
                case SCT_EIT_SCHEDULE0...SCT_EIT_SCHEDULE15: //GCC
                case SCT_EIT_SCHEDULE_OTHER0...SCT_EIT_SCHEDULE_OTHER15: //GCC
                  {
                    DEC_I (hv, 16, service_id);
                    decode_field (2);
                    DEC_I (hv,  5, version_number);
                    DEC_I (hv,  1, current_next_indicator);
                    DEC_I (hv,  8, section_number);
                    DEC_I (hv,  8, last_section_number);
                    DEC_I (hv, 16, transport_stream_id);
                    DEC_I (hv, 16, original_network_id);
                    DEC_I (hv,  8, segment_last_section_number);
                    DEC_I (hv,  8, last_table_id);

                    AV *events = newAV ();
                    HVS (hv, events, newRV_noinc ((SV *)events));

                    while (end - dec_ofs > 32)
                      {
                        long dll;
                        AV *desc;
                        HV *ev = newHV ();
                        av_push (events, newRV_noinc ((SV *)ev));

                        DEC_I (ev, 16, event_id);
                        DEC_I (ev, 16, start_time_mjd);
                        DEC_I (ev, 24, start_time_hms);
                        DEC_I (ev, 24, duration);
                        DEC_I (ev,  3, running_status);
                        DEC_I (ev,  1, free_CA_mode);

                        dll = dec_ofs + (decode_field (12) << 3);

                        desc = decode_descriptors (dll);
                        HVS (ev, descriptors, newRV_noinc ((SV *)desc));
                      }

                    decode_field (32); // skip CRC
                  }

                  break;

                case SCT_SDT:
                case SCT_SDT_OTHER:
                  DEC_I (hv, 16, transport_stream_id);
                  decode_field (2);
                  DEC_I (hv,  5, version_number);
                  DEC_I (hv,  1, current_next_indicator);
                  DEC_I (hv,  8, section_number);
                  DEC_I (hv,  8, last_section_number);
                  DEC_I (hv, 16, original_network_id);
                  decode_field (8);

                  AV *services = newAV ();
                  HVS (hv, services, newRV_noinc ((SV *)services));

                  while (end - dec_ofs > 32)
                    {
                      HV *ev = newHV ();
                      U32 dll;
                      AV *desc;
                      av_push (services, newRV_noinc ((SV *)ev));

                      DEC_I (ev, 16, service_id);
                      decode_field (6);
                      DEC_I (ev, 1, EIT_schedule_flags);
                      DEC_I (ev, 1, EIT_present_following_flag);
                      DEC_I (ev, 3, running_status);
                      DEC_I (ev, 1, free_CA_mode);

                      dll = dec_ofs + (decode_field (12) << 3);
                      
                      desc = decode_descriptors (dll);
                      HVS (ev, descriptors, newRV_noinc ((SV *)desc));
                    }

                  decode_field (32); // skip CRC
                  break;

                default:
                  DEC_S (hv, length, raw_data);
                  break;
              }

            if (decode_overflow)
              {
                SvREFCNT_dec (hv);
                safe_sv_chop (stream, (end + 7) >> 3);
                XSRETURN_UNDEF;
              }

            safe_sv_chop (stream, (dec_ofs + 7) >> 3);
          }
	else
          {
            SvREFCNT_dec (hv);
            safe_sv_chop (stream, (end + 7) >> 3);
            XSRETURN_UNDEF;
          }

        RETVAL = (SV *)newRV_noinc ((SV *)hv);
	OUTPUT:
        RETVAL

