libdvb_ts_lib ?= .

CFLAGS += -I$(libdvb_ts_lib)  -I$(libdvb_ts_lib)/shared

OBJS-libdvb_ts_lib := \
	$(libdvb_ts_lib)/ts_parse.o \
	$(libdvb_ts_lib)/ts_skip.o \
	$(libdvb_ts_lib)/ts_split.o \
	$(libdvb_ts_lib)/ts_cut.o \
	$(libdvb_ts_lib)/ts_bits.o \
	$(libdvb_ts_lib)/shared/dvb_error.o \
	$(libdvb_ts_lib)/dvbsnoop/crc32.o \
	$(libdvb_ts_lib)/tables/parse_si_eit.o\
	$(libdvb_ts_lib)/tables/parse_si_cit.o\
	$(libdvb_ts_lib)/tables/parse_si_sdt.o\
	$(libdvb_ts_lib)/tables/parse_si_pat.o\
	$(libdvb_ts_lib)/tables/parse_si_cat.o\
	$(libdvb_ts_lib)/tables/parse_si_pmt.o\
	$(libdvb_ts_lib)/tables/parse_si_nit.o\
	$(libdvb_ts_lib)/tables/parse_si_bat.o\
	$(libdvb_ts_lib)/tables/parse_si_tdt.o\
	$(libdvb_ts_lib)/tables/parse_si_rst.o\
	$(libdvb_ts_lib)/tables/parse_si_st.o\
	$(libdvb_ts_lib)/tables/parse_si_tot.o\
	$(libdvb_ts_lib)/tables/parse_si_dit.o\
	$(libdvb_ts_lib)/tables/parse_si_sit.o\
	$(libdvb_ts_lib)/tables/parse_si.o\
	\
	$(libdvb_ts_lib)/descriptors/parse_desc_network_name.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_service_list.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_stuffing.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_satellite_delivery_system.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_cable_delivery_system.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_vbi_teletext.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_bouquet_name.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_service.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_country_availability.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_linkage.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_nvod_reference.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_time_shifted_service.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_short_event.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_extended_event.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_time_shifted_event.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_component.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_stream_identifier.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_ca_identifier.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_content.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_parental_rating.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_teletext.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_telephone.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_local_time_offset.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_subtitling.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_terrestrial_delivery_system.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_multilingual_network_name.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_multilingual_bouquet_name.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_multilingual_service_name.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_multilingual_component.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_private_data_specifier.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_service_move.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_short_smoothing_buffer.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_frequency_list.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_partial_transport_stream.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_data_broadcast.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_scrambling.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_data_broadcast_id.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_transport_stream.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_dsng.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_pdc.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_ancillary_data.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_announcement_support.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_adaptation_field_data.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_service_availability.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_tva_content_identifier.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_s2_satellite_delivery_system.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_extension.o  \
	\
	$(libdvb_ts_lib)/descriptors/parse_desc_vbi_data.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_mosaic.o \
	$(libdvb_ts_lib)/descriptors/parse_desc_cell_frequency_link.o \
	\
	$(libdvb_ts_lib)/descriptors/parse_desc.o 
	
# multiple levels of for
#	$(libdvb_ts_lib)/descriptors/parse_desc_vbi_data.o \
#	$(libdvb_ts_lib)/descriptors/parse_desc_mosaic.o \
#	$(libdvb_ts_lib)/descriptors/parse_desc_cell_frequency_link.o \
#
