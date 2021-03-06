package Db::Ctree;     

if (!defined &ctERRCH) {
    eval 'sub ctERRCH {1;}';
    eval 'sub NO_ERROR {0;}';
    eval 'sub KDUP_ERR {2;}';
    eval 'sub KMAT_ERR {3;}';
    eval 'sub KDEL_ERR {4;}';
    eval 'sub KBLD_ERR {5;}';
    eval 'sub BJMP_ERR {6;}';
    eval 'sub TUSR_ERR {7;}';
    eval 'sub FCNF_COD {-8;}';
    eval 'sub FDEV_COD {-9;}';
    eval 'sub SPAC_ERR {10;}';
    eval 'sub SPRM_ERR {11;}';
    eval 'sub FNOP_ERR {12;}';
    eval 'sub FUNK_ERR {13;}';
    eval 'sub FCRP_ERR {14;}';
    eval 'sub FCMP_ERR {15;}';
    eval 'sub KCRAT_ERR {16;}';
    eval 'sub DCRAT_ERR {17;}';
    eval 'sub KOPN_ERR {18;}';
    eval 'sub DOPN_ERR {19;}';
    eval 'sub KMIN_ERR {20;}';
    eval 'sub DREC_ERR {21;}';
    eval 'sub FNUM_ERR {22;}';
    eval 'sub KMEM_ERR {23;}';
    eval 'sub FCLS_ERR {24;}';
    eval 'sub KLNK_ERR {25;}';
    eval 'sub FACS_ERR {26;}';
    eval 'sub LBOF_ERR {27;}';
    eval 'sub ZDRN_ERR {28;}';
    eval 'sub ZREC_ERR {29;}';
    eval 'sub LEOF_ERR {30;}';
    eval 'sub DELFLG_ERR {31;}';
    eval 'sub DDRN_ERR {32;}';
    eval 'sub DNUL_ERR {33;}';
    eval 'sub PRDS_ERR {34;}';
    eval 'sub SEEK_ERR {35;}';
    eval 'sub READ_ERR {36;}';
    eval 'sub WRITE_ERR {37;}';
    eval 'sub VRTO_ERR {38;}';
    eval 'sub FULL_ERR {39;}';
    eval 'sub KSIZ_ERR {40;}';
    eval 'sub UDLK_ERR {41;}';
    eval 'sub DLOK_ERR {42;}';
    eval 'sub FVER_ERR {43;}';
    eval 'sub OSRL_ERR {44;}';
    eval 'sub KLEN_ERR {45;}';
    eval 'sub FUSE_ERR {46;}';
    eval 'sub FINT_ERR {47;}';
    eval 'sub FMOD_ERR {48;}';
    eval 'sub FSAV_ERR {49;}';
    eval 'sub LNOD_ERR {50;}';
    eval 'sub UNOD_ERR {51;}';
    eval 'sub KTYP_ERR {52;}';
    eval 'sub FTYP_ERR {53;}';
    eval 'sub REDF_ERR {54;}';
    eval 'sub DLTF_ERR {55;}';
    eval 'sub DLTP_ERR {56;}';
    eval 'sub DADV_ERR {57;}';
    eval 'sub KLOD_ERR {58;}';
    eval 'sub KLOR_ERR {59;}';
    eval 'sub KFRC_ERR {60;}';
    eval 'sub CTNL_ERR {61;}';
    eval 'sub LERR_ERR {62;}';
    eval 'sub RSER_ERR {63;}';
    eval 'sub RLEN_ERR {64;}';
    eval 'sub RMEM_ERR {65;}';
    eval 'sub RCHK_ERR {66;}';
    eval 'sub RENF_ERR {67;}';
    eval 'sub LALC_ERR {68;}';
    eval 'sub BNOD_ERR {69;}';
    eval 'sub TEXS_ERR {70;}';
    eval 'sub TNON_ERR {71;}';
    eval 'sub TSHD_ERR {72;}';
    eval 'sub TLOG_ERR {73;}';
    eval 'sub TRAC_ERR {74;}';
    eval 'sub TROW_ERR {75;}';
    eval 'sub TBAD_ERR {76;}';
    eval 'sub TRNM_ERR {77;}';
    eval 'sub TABN_ERR {78;}';
    eval 'sub FLOG_ERR {79;}';
    eval 'sub BKEY_ERR {80;}';
    eval 'sub ATRN_ERR {81;}';
    eval 'sub UALC_ERR {82;}';
    eval 'sub IALC_ERR {83;}';
    eval 'sub MUSR_ERR {84;}';
    eval 'sub LUPD_ERR {85;}';
    eval 'sub DEAD_ERR {86;}';
    eval 'sub QIET_ERR {87;}';
    eval 'sub LMEM_ERR {88;}';
    eval 'sub TMEM_ERR {89;}';
    eval 'sub NQUE_ERR {90;}';
    eval 'sub QWRT_ERR {91;}';
    eval 'sub QMRT_ERR {92;}';
    eval 'sub QRED_ERR {93;}';
    eval 'sub PNDG_ERR {94;}';
    eval 'sub STSK_ERR {95;}';
    eval 'sub LOPN_ERR {96;}';
    eval 'sub SUSR_ERR {97;}';
    eval 'sub BTMD_ERR {98;}';
    eval 'sub TTYP_ERR {99;}';
    eval 'sub ICUR_ERR {100;}';
    eval 'sub INOT_ERR {101;}';
    eval 'sub INOD_ERR {102;}';
    eval 'sub IGIN_ERR {103;}';
    eval 'sub IFIL_ERR {104;}';
    eval 'sub IUND_ERR {105;}';
    eval 'sub IDRI_ERR {106;}';
    eval 'sub IDRK_ERR {107;}';
    eval 'sub IMKY_ERR {108;}';
    eval 'sub IKRS_ERR {109;}';
    eval 'sub ISRC_ERR {110;}';
    eval 'sub IKRI_ERR {111;}';
    eval 'sub IPND_ERR {112;}';
    eval 'sub INOL_ERR {113;}';
    eval 'sub IRED_ERR {114;}';
    eval 'sub ISLN_ERR {115;}';
    eval 'sub IMOD_ERR {116;}';
    eval 'sub IMRI_ERR {117;}';
    eval 'sub SKEY_ERR {118;}';
    eval 'sub SKTY_ERR {119;}';
    eval 'sub RRLN_ERR {120;}';
    eval 'sub KBUF_ERR {121;}';
    eval 'sub RMOD_ERR {122;}';
    eval 'sub RVHD_ERR {123;}';
    eval 'sub INIX_ERR {124;}';
    eval 'sub IINT_ERR {125;}';
    eval 'sub ABDR_ERR {126;}';
    eval 'sub ARQS_ERR {127;}';
    eval 'sub ARSP_ERR {128;}';
    eval 'sub NINT_ERR {129;}';
    eval 'sub AFNM_ERR {130;}';
    eval 'sub AFLN_ERR {131;}';
    eval 'sub ASPC_ERR {132;}';
    eval 'sub ASKY_ERR {133;}';
    eval 'sub ASID_ERR {134;}';
    eval 'sub AAID_ERR {135;}';
    eval 'sub AMST_ERR {136;}';
    eval 'sub AMQZ_ERR {137;}';
    eval 'sub AMRD_ERR {138;}';
    eval 'sub ABNM_ERR {139;}';
    eval 'sub VMAX_ERR {140;}';
    eval 'sub AMSG_ERR {141;}';
    eval 'sub SMXL_ERR {142;}';
    eval 'sub SHND_ERR {143;}';
    eval 'sub QMEM_ERR {144;}';
    eval 'sub SCSF_ERR {145;}';
    eval 'sub VDLK_ERR {146;}';
    eval 'sub VDLFLG_ERR {147;}';
    eval 'sub VLEN_ERR {148;}';
    eval 'sub VRLN_ERR {149;}';
    eval 'sub SHUT_ERR {150;}';
    eval 'sub STRN_ERR {151;}';
    eval 'sub LEXT_ERR {152;}';
    eval 'sub VBSZ_ERR {153;}';
    eval 'sub VRCL_ERR {154;}';
    eval 'sub SYST_ERR {155;}';
    eval 'sub NTIM_ERR {156;}';
    eval 'sub VFLG_ERR {158;}';
    eval 'sub VPNT_ERR {159;}';
    eval 'sub ITIM_ERR {160;}';
    eval 'sub SINA_ERR {161;}';
    eval 'sub SGON_ERR {162;}';
    eval 'sub SFRE_ERR {163;}';
    eval 'sub SFIL_ERR {164;}';
    eval 'sub SNFB_ERR {165;}';
    eval 'sub SNMC_ERR {166;}';
    eval 'sub SRQS_ERR {167;}';
    eval 'sub SRSP_ERR {168;}';
    eval 'sub TCRE_ERR {169;}';
    eval 'sub SFUN_ERR {170;}';
    eval 'sub SMSG_ERR {171;}';
    eval 'sub SSPC_ERR {172;}';
    eval 'sub SSKY_ERR {173;}';
    eval 'sub SSID_ERR {174;}';
    eval 'sub SAMS_ERR {175;}';
    eval 'sub SMST_ERR {176;}';
    eval 'sub SMQZ_ERR {177;}';
    eval 'sub SINM_ERR {178;}';
    eval 'sub SOUT_ERR {179;}';
    eval 'sub IKRU_ERR {180;}';
    eval 'sub IKMU_ERR {181;}';
    eval 'sub IKSR_ERR {182;}';
    eval 'sub IDRU_ERR {183;}';
    eval 'sub ISDP_ERR {184;}';
    eval 'sub ISAL_ERR {185;}';
    eval 'sub ISNM_ERR {186;}';
    eval 'sub IRBF_ERR {187;}';
    eval 'sub ITBF_ERR {188;}';
    eval 'sub IJSK_ERR {189;}';
    eval 'sub IJER_ERR {190;}';
    eval 'sub IJNL_ERR {191;}';
    eval 'sub IDSK_ERR {192;}';
    eval 'sub IDER_ERR {193;}';
    eval 'sub IDNL_ERR {194;}';
    eval 'sub IDMU_ERR {195;}';
    eval 'sub ITML_ERR {196;}';
    eval 'sub IMEM_ERR {197;}';
    eval 'sub BIFL_ERR {198;}';
    eval 'sub NSCH_ERR {199;}';
    eval 'sub RCRE_ERR {400;}';
    eval 'sub RNON_ERR {401;}';
    eval 'sub RXCL_ERR {402;}';
    eval 'sub RZRO_ERR {403;}';
    eval 'sub RBUF_ERR {404;}';
    eval 'sub RDUP_ERR {405;}';
    eval 'sub RCSE_ERR {406;}';
    eval 'sub RRED_ERR {407;}';
    eval 'sub RNOT_ERR {408;}';
    eval 'sub LKEP_ERR {409;}';
    eval 'sub USTP_ERR {410;}';
    eval 'sub BSUP_ERR {411;}';
    eval 'sub LCIP_ERR {412;}';
    eval 'sub SDIR_ERR {413;}';
    eval 'sub SNST_ERR {414;}';
    eval 'sub SADD_ERR {415;}';
    eval 'sub SDEL_ERR {416;}';
    eval 'sub SPAG_ERR {417;}';
    eval 'sub SNAM_ERR {418;}';
    eval 'sub SRCV_ERR {419;}';
    eval 'sub TPND_ERR {420;}';
    eval 'sub BTFL_ERR {421;}';
    eval 'sub BTFN_ERR {422;}';
    eval 'sub BTIC_ERR {423;}';
    eval 'sub BTAD_ERR {424;}';
    eval 'sub BTIP_ERR {425;}';
    eval 'sub BTNO_ERR {426;}';
    eval 'sub BTST_ERR {427;}';
    eval 'sub BTMT_ERR {428;}';
    eval 'sub BTBZ_ERR {429;}';
    eval 'sub BTRQ_ERR {430;}';
    eval 'sub LAGR_ERR {431;}';
    eval 'sub FLEN_ERR {432;}';
    eval 'sub SSCH_ERR {433;}';
    eval 'sub DLEN_ERR {434;}';
    eval 'sub FMEM_ERR {435;}';
    eval 'sub DNUM_ERR {436;}';
    eval 'sub DADR_ERR {437;}';
    eval 'sub DZRO_ERR {438;}';
    eval 'sub DCNV_ERR {439;}';
    eval 'sub DDDM_ERR {440;}';
    eval 'sub DMEM_ERR {441;}';
    eval 'sub DAVL_ERR {442;}';
    eval 'sub DSIZ_ERR {443;}';
    eval 'sub DCRE_ERR {444;}';
    eval 'sub SDAT_ERR {445;}';
    eval 'sub BMOD_ERR {446;}';
    eval 'sub BOWN_ERR {447;}';
    eval 'sub DEFP_ERR {448;}';
    eval 'sub DADM_ERR {449;}';
    eval 'sub LUID_ERR {450;}';
    eval 'sub LPWD_ERR {451;}';
    eval 'sub LSRV_ERR {452;}';
    eval 'sub NSRV_ERR {453;}';
    eval 'sub NSUP_ERR {454;}';
    eval 'sub SGRP_ERR {455;}';
    eval 'sub SACS_ERR {456;}';
    eval 'sub SPWD_ERR {457;}';
    eval 'sub SWRT_ERR {458;}';
    eval 'sub SDLT_ERR {459;}';
    eval 'sub SRES_ERR {460;}';
    eval 'sub SPER_ERR {461;}';
    eval 'sub SHDR_ERR {462;}';
    eval 'sub UQID_ERR {463;}';
    eval 'sub IISM_ERR {464;}';
    eval 'sub IINI_ERR {465;}';
    eval 'sub IIDT_ERR {466;}';
    eval 'sub IINM_ERR {467;}';
    eval 'sub IITR_ERR {468;}';
    eval 'sub NGIO_ERR {469;}';
    eval 'sub LGST_ERR {470;}';
    eval 'sub SORT_ERR {370;}';
    eval 'sub NLOG_ERR {498;}';
    eval 'sub FIDD_ERR {499;}';
    eval 'sub SQLINIT_ERR {500;}';
    eval 'sub SQLCONNECT_ERR {501;}';
    eval 'sub SQL_REQUEST_ERROR {502;}';
    eval 'sub SQL_INVALID_CONTINUE {503;}';
    eval 'sub NSQL_ERR {504;}';
    eval 'sub USQL_ERR {505;}';
    eval 'sub SRFL_ERR {506;}';
    eval 'sub SRIO_ERR {507;}';
    eval 'sub SRIN_ERR {508;}';
    eval 'sub DSRV_ERR {509;}';
    eval 'sub RFCK_ERR {510;}';
    eval 'sub ILOP_ERR {511;}';
    eval 'sub DLOP_ERR {512;}';
    eval 'sub SBLF_ERR {513;}';
    eval 'sub CQUE_ERR {514;}';
    eval 'sub OIFL_ERR {515;}';
    eval 'sub GNUL_ERR {516;}';
    eval 'sub GNOT_ERR {517;}';
    eval 'sub GEXS_ERR {518;}';
    eval 'sub IEOF_ERR {519;}';
    eval 'sub HTRN_ERR {520;}';
    if (defined &VINES) {
	eval 'sub BMAL_ERR {521;}';
	eval 'sub STID_ERR {522;}';
    }
    eval 'sub LMTC_ERR {530;}';
    eval 'sub BREP_ERR {531;}';
    eval 'sub ASAV_ERR {532;}';
    eval 'sub MTRN_ERR {533;}';
    eval 'sub OTRN_ERR {534;}';
    eval 'sub REGC_ERR {535;}';
    eval 'sub LWRT_ERR {541;}';
    eval 'sub MCRE_ERR {542;}';
    eval 'sub MOPN_ERR {543;}';
    eval 'sub MCLS_ERR {544;}';
    eval 'sub MDLT_ERR {545;}';
    eval 'sub MWRT_ERR {546;}';
    eval 'sub MSAV_ERR {547;}';
    eval 'sub MRED_ERR {548;}';
    eval 'sub MHDR_ERR {549;}';
    eval 'sub MSKP_ERR {550;}';
    eval 'sub MNOT_ERR {551;}';
    eval 'sub PREA_ERR {555;}';
    eval 'sub PWRT_ERR {556;}';
    eval 'sub CWRT_ERR {557;}';
    eval 'sub PSAV_ERR {558;}';
    eval 'sub CSAV_ERR {559;}';
    eval 'sub SMON_ERR {560;}';
    eval 'sub DDMP_BEG {561;}';
    eval 'sub DDMP_END {562;}';
    eval 'sub DDMP_ERR {563;}';
    eval 'sub RCL1_ERR {570;}';
    eval 'sub RCL2_ERR {571;}';
    eval 'sub RCL3_ERR {572;}';
    eval 'sub RCL4_ERR {573;}';
    eval 'sub RCL5_ERR {574;}';
    eval 'sub RCL6_ERR {575;}';
    eval 'sub RCL7_ERR {576;}';
    eval 'sub NCON_ERR {590;}';
    eval 'sub OCON_ERR {591;}';
    eval 'sub ECON_ERR {592;}';
    eval 'sub CLEN_ERR {595;}';
    eval 'sub CMIS_ERR {596;}';
    eval 'sub CINI_ERR {597;}';
    eval 'sub CVAL_ERR {598;}';
    eval 'sub CTHD_ERR {600;}';
    eval 'sub VRFY_ERR {601;}';
    eval 'sub CMEM_ERR {602;}';
    eval 'sub HNUL_ERR {610;}';
    eval 'sub HLOG_ERR {611;}';
    eval 'sub HSTR_ERR {612;}';
    eval 'sub HONE_ERR {613;}';
    eval 'sub HMAP_ERR {614;}';
    eval 'sub HIDX_ERR {615;}';
    eval 'sub HACT_ERR {616;}';
    eval 'sub HNOT_ERR {617;}';
    eval 'sub HENT_ERR {618;}';
    eval 'sub HZRO_ERR {619;}';
    eval 'sub HSIZ_ERR {620;}';
    eval 'sub HTYP_ERR {621;}';
    eval 'sub HMID_ERR {622;}';
    eval 'sub HMEM_ERR {623;}';
    eval 'sub HNET_ERR {624;}';
    eval 'sub HMTC_ERR {625;}';
    eval 'sub HUND_ERR {626;}';
    eval 'sub HUNK_ERR {627;}';
    eval 'sub HFIL_ERR {628;}';
    eval 'sub HTFL_ERR {629;}';
}
1;
