# Copyright 1998 Robert Eden
# All rights reserved.
#
# Automatic licensing for this software is available.  This software
# can be copied and used under the terms of the GNU Public License,
# version 1 or (at your option) any later version, or under the
# terms of the Artistic license.  Both of these can be found with
# the Perl distribution, which this software is intended to augment.
#
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

package Db::Ctree;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
require DynaLoader;

$VERSION = '1.2';

@ISA = qw(Exporter DynaLoader);

%EXPORT_TAGS = ( ISAM => [ qw(
		    &AddRecord
		    &AddVRecord
		    &ChangeISAMContext
		    &CloseIFile
		    &CloseISAM
		    &CloseISAMContext
		    &CompactIFile
		    &CompactIFileXtd
		    &CreateIFile
		    &CreateIFileXtd
		    &CreateISAM
		    &CreateISAMXtd
		    &CurrentISAMKey
		    &DeleteIFile
		    &DeleteRecord
		    &DeleteVRecord
		    &FirstRecord
		    &GetGTERecord
		    &GetGTRecord
		    &GetIFile
		    &GetLTERecord
		    &GetLTRecord
		    &GetRecord
		    &InitISAMXtd
		    &LastRecord
		    &LockISAM
		    &NbrOfRecords
		    &NextRecord
		    &OpenIFile
		    &OpenIFileXtd
		    &OpenISAM
		    &OpenISAMContext
		    &OpenISAMXtd
		    &PreviousRecord
		    &PutIFile
		    &PutIFileXtd
		    &ReReadRecord
		    &ReReadVRecord
		    &ReWriteRecord
		    &ReWriteVRecord
		    &ReadIsamData
		    &RebuildIFile
		    &RebuildIFileXtd
		    &ResetRecord
		    &SetRecord
		    &VRecordLength
		    &InitISAM
		)],
	 LOW_LEVEL => [ qw(
		    &Abort
		    &AbortXtd
		    &AddCtResource
		    &AddKey
		    &AllocateBatch
		    &AllocateSet
		    &AvailableFileNbr
		    &Begin
		    &BuildKey
		    &ChangeBatch
		    &ChangeSet
		    &ClearTranError
		    &CloseCtFile
		    &CloseRFile
		    &Commit
		    &CreateDataFile
		    &CreateDataFileXtd
		    &CreateIndexFile
		    &CreateIndexFileXtd
		    &CreateIndexMember
		    &CtreeFlushFile
		    &CurrentFileOffset
		    &CurrentLowLevelKey
		    &DeleteCtFile
		    &DeleteCtResource
		    &DeleteKey
		    &DeleteKeyBlind
		    &DeleteRFile
		    &DoBatch
		    &EnableCtResource
		    &EstimateKeySpan
		    &FirstInSet
		    &FirstKey
		    &FreeBatch
		    &FreeSet
		    &GetAltSequence
		    &GetCtFileInfo
		    &GetCtResource
		    &GetCtTempFileName
		    &GetCtreePointer
		    &GetGTEKey
		    &GetGTKey
		    &GetKey
		    &GetLTEKey
		    &GetLTKey
		    &GetORDKey
		    &GetSerialNbr
		    &GetSuperFileNames
		    &GetSymbolicNames
		    &IOPERFORMANCE
		    &IOPERFORMANCEX
		    &InitCTree
		    &InitCTreeXtd
		    &KeyAtPercentile
		    &LastInSet
		    &LastKey
		    &LoadKey
		    &LockCtData
		    &MyGetDODA
		    &NbrOfKeyEntries
		    &NbrOfKeysInRange
		    &NewData
		    &NewVData
		    &NextInSet
		    &NextKey
		    &OpenCtFile
		    &OpenCtFileXtd
		    &OpenFileWithResource
		    &PermIIndex
		    &PositionSet
		    &PreviousInSet
		    &PreviousKey
		    &PutDODA
		    &ReadData
		    &ReadVData
		    &RegisterCtree
		    &ReleaseData
		    &ReleaseVData
		    &RestoreSavePoint
		    &Security
		    &SetAlternateSequence
		    &SetNodeName
		    &SetOperationState
		    &SetSavePoint
		    &SetVariableBytes
		    &StopServer
		    &StopUser
		    &SuperfilePrepassXtd
		    &SwitchCtree
		    &SystemConfiguration
		    &SystemMonitor
		    &TempIIndexXtd
		    &TransformKey
		    &UnRegisterCtree
		    &UpdateCtResource
		    &UpdateFileMode
		    &UpdateHeader
		    &VDataLength
		    &WhichCtree
		    &WriteData
		    &WriteVData
		    &vtclose
		)],
    VARIABLES => [ qw(
		    &isam_err
		    &isam_fil
		    &sysiocod
		    &uerr_cod
               )],
    ERRORCODE => [ qw(
		    &NO_ERROR
		    &KDUP_ERR
		    &KMAT_ERR
		    &KDEL_ERR
		    &KBLD_ERR
		    &BJMP_ERR
		    &TUSR_ERR
		    &FCNF_COD
		    &FDEV_COD
		    &SPAC_ERR
		    &SPRM_ERR
		    &FNOP_ERR
		    &FUNK_ERR
		    &FCRP_ERR
		    &FCMP_ERR
		    &KCRAT_ERR
		    &DCRAT_ERR
		    &KOPN_ERR
		    &DOPN_ERR
		    &KMIN_ERR
		    &DREC_ERR
		    &FNUM_ERR
		    &KMEM_ERR
		    &FCLS_ERR
		    &KLNK_ERR
		    &FACS_ERR
		    &LBOF_ERR
		    &ZDRN_ERR
		    &ZREC_ERR
		    &LEOF_ERR
		    &DELFLG_ERR
		    &DDRN_ERR
		    &DNUL_ERR
		    &PRDS_ERR
		    &SEEK_ERR
		    &READ_ERR
		    &WRITE_ERR
		    &VRTO_ERR
		    &FULL_ERR
		    &KSIZ_ERR
		    &UDLK_ERR
		    &DLOK_ERR
		    &FVER_ERR
		    &OSRL_ERR
		    &KLEN_ERR
		    &FUSE_ERR
		    &FINT_ERR
		    &FMOD_ERR
		    &FSAV_ERR
		    &LNOD_ERR
		    &UNOD_ERR
		    &KTYP_ERR
		    &FTYP_ERR
		    &REDF_ERR
		    &DLTF_ERR
		    &DLTP_ERR
		    &DADV_ERR
		    &KLOD_ERR
		    &KLOR_ERR
		    &KFRC_ERR
		    &CTNL_ERR
		    &LERR_ERR
		    &RSER_ERR
		    &RLEN_ERR
		    &RMEM_ERR
		    &RCHK_ERR
		    &RENF_ERR
		    &LALC_ERR
		    &BNOD_ERR
		    &TEXS_ERR
		    &TNON_ERR
		    &TSHD_ERR
		    &TLOG_ERR
		    &TRAC_ERR
		    &TROW_ERR
		    &TBAD_ERR
		    &TRNM_ERR
		    &TABN_ERR
		    &FLOG_ERR
		    &BKEY_ERR
		    &ATRN_ERR
		    &UALC_ERR
		    &IALC_ERR
		    &MUSR_ERR
		    &LUPD_ERR
		    &DEAD_ERR
		    &QIET_ERR
		    &LMEM_ERR
		    &TMEM_ERR
		    &NQUE_ERR
		    &QWRT_ERR
		    &QMRT_ERR
		    &QRED_ERR
		    &PNDG_ERR
		    &STSK_ERR
		    &LOPN_ERR
		    &SUSR_ERR
		    &BTMD_ERR
		    &TTYP_ERR
		    &ICUR_ERR
		    &INOT_ERR
		    &INOD_ERR
		    &IGIN_ERR
		    &IFIL_ERR
		    &IUND_ERR
		    &IDRI_ERR
		    &IDRK_ERR
		    &IMKY_ERR
		    &IKRS_ERR
		    &ISRC_ERR
		    &IKRI_ERR
		    &IPND_ERR
		    &INOL_ERR
		    &IRED_ERR
		    &ISLN_ERR
		    &IMOD_ERR
		    &IMRI_ERR
		    &SKEY_ERR
		    &SKTY_ERR
		    &RRLN_ERR
		    &KBUF_ERR
		    &RMOD_ERR
		    &RVHD_ERR
		    &INIX_ERR
		    &IINT_ERR
		    &ABDR_ERR
		    &ARQS_ERR
		    &ARSP_ERR
		    &NINT_ERR
		    &AFNM_ERR
		    &AFLN_ERR
		    &ASPC_ERR
		    &ASKY_ERR
		    &ASID_ERR
		    &AAID_ERR
		    &AMST_ERR
		    &AMQZ_ERR
		    &AMRD_ERR
		    &ABNM_ERR
		    &VMAX_ERR
		    &AMSG_ERR
		    &SMXL_ERR
		    &SHND_ERR
		    &QMEM_ERR
		    &SCSF_ERR
		    &VDLK_ERR
		    &VDLFLG_ERR
		    &VLEN_ERR
		    &VRLN_ERR
		    &SHUT_ERR
		    &STRN_ERR
		    &LEXT_ERR
		    &VBSZ_ERR
		    &VRCL_ERR
		    &SYST_ERR
		    &NTIM_ERR
		    &VFLG_ERR
		    &VPNT_ERR
		    &ITIM_ERR
		    &SINA_ERR
		    &SGON_ERR
		    &SFRE_ERR
		    &SFIL_ERR
		    &SNFB_ERR
		    &SNMC_ERR
		    &SRQS_ERR
		    &SRSP_ERR
		    &TCRE_ERR
		    &SFUN_ERR
		    &SMSG_ERR
		    &SSPC_ERR
		    &SSKY_ERR
		    &SSID_ERR
		    &SAMS_ERR
		    &SMST_ERR
		    &SMQZ_ERR
		    &SINM_ERR
		    &SOUT_ERR
		    &IKRU_ERR
		    &IKMU_ERR
		    &IKSR_ERR
		    &IDRU_ERR
		    &ISDP_ERR
		    &ISAL_ERR
		    &ISNM_ERR
		    &IRBF_ERR
		    &ITBF_ERR
		    &IJSK_ERR
		    &IJER_ERR
		    &IJNL_ERR
		    &IDSK_ERR
		    &IDER_ERR
		    &IDNL_ERR
		    &IDMU_ERR
		    &ITML_ERR
		    &IMEM_ERR
		    &BIFL_ERR
		    &NSCH_ERR
		    &RCRE_ERR
		    &RNON_ERR
		    &RXCL_ERR
		    &RZRO_ERR
		    &RBUF_ERR
		    &RDUP_ERR
		    &RCSE_ERR
		    &RRED_ERR
		    &RNOT_ERR
		    &LKEP_ERR
		    &USTP_ERR
		    &BSUP_ERR
		    &LCIP_ERR
		    &SDIR_ERR
		    &SNST_ERR
		    &SADD_ERR
		    &SDEL_ERR
		    &SPAG_ERR
		    &SNAM_ERR
		    &SRCV_ERR
		    &TPND_ERR
		    &BTFL_ERR
		    &BTFN_ERR
		    &BTIC_ERR
		    &BTAD_ERR
		    &BTIP_ERR
		    &BTNO_ERR
		    &BTST_ERR
		    &BTMT_ERR
		    &BTBZ_ERR
		    &BTRQ_ERR
		    &LAGR_ERR
		    &FLEN_ERR
		    &SSCH_ERR
		    &DLEN_ERR
		    &FMEM_ERR
		    &DNUM_ERR
		    &DADR_ERR
		    &DZRO_ERR
		    &DCNV_ERR
		    &DDDM_ERR
		    &DMEM_ERR
		    &DAVL_ERR
		    &DSIZ_ERR
		    &DCRE_ERR
		    &SDAT_ERR
		    &BMOD_ERR
		    &BOWN_ERR
		    &DEFP_ERR
		    &DADM_ERR
		    &LUID_ERR
		    &LPWD_ERR
		    &LSRV_ERR
		    &NSRV_ERR
		    &NSUP_ERR
		    &SGRP_ERR
		    &SACS_ERR
		    &SPWD_ERR
		    &SWRT_ERR
		    &SDLT_ERR
		    &SRES_ERR
		    &SPER_ERR
		    &SHDR_ERR
		    &UQID_ERR
		    &IISM_ERR
		    &IINI_ERR
		    &IIDT_ERR
		    &IINM_ERR
		    &IITR_ERR
		    &NGIO_ERR
		    &LGST_ERR
		    &SORT_ERR
		    &NLOG_ERR
		    &FIDD_ERR
		    &SQLINIT_ERR
		    &SQLCONNECT_ERR
		    &SQL_REQUEST_ERROR
		    &SQL_INVALID_CONTINUE
		    &NSQL_ERR
		    &USQL_ERR
		    &SRFL_ERR
		    &SRIO_ERR
		    &SRIN_ERR
		    &DSRV_ERR
		    &RFCK_ERR
		    &ILOP_ERR
		    &DLOP_ERR
		    &SBLF_ERR
		    &CQUE_ERR
		    &OIFL_ERR
		    &GNUL_ERR
		    &GNOT_ERR
		    &GEXS_ERR
		    &IEOF_ERR
		    &HTRN_ERR
		    &LMTC_ERR
		    &BREP_ERR
		    &ASAV_ERR
		    &MTRN_ERR
		    &OTRN_ERR
		    &REGC_ERR
		    &LWRT_ERR
		    &MCRE_ERR
		    &MOPN_ERR
		    &MCLS_ERR
		    &MDLT_ERR
		    &MWRT_ERR
		    &MSAV_ERR
		    &MRED_ERR
		    &MHDR_ERR
		    &MSKP_ERR
		    &MNOT_ERR
		    &PREA_ERR
		    &PWRT_ERR
		    &CWRT_ERR
		    &PSAV_ERR
		    &CSAV_ERR
		    &SMON_ERR
		    &DDMP_BEG
		    &DDMP_END
		    &DDMP_ERR
		    &RCL1_ERR
		    &RCL2_ERR
		    &RCL3_ERR
		    &RCL4_ERR
		    &RCL5_ERR
		    &RCL6_ERR
		    &RCL7_ERR
		    &NCON_ERR
		    &OCON_ERR
		    &ECON_ERR
		    &CLEN_ERR
		    &CMIS_ERR
		    &CINI_ERR
		    &CVAL_ERR
		    &CTHD_ERR
		    &VRFY_ERR
		    &CMEM_ERR
		    &HNUL_ERR
		    &HLOG_ERR
		    &HSTR_ERR
		    &HONE_ERR
		    &HMAP_ERR
		    &HIDX_ERR
		    &HACT_ERR
		    &HNOT_ERR
		    &HENT_ERR
		    &HZRO_ERR
		    &HSIZ_ERR
		    &HTYP_ERR
		    &HMID_ERR
		    &HMEM_ERR
		    &HNET_ERR
		    &HMTC_ERR
		    &HUND_ERR
		    &HUNK_ERR
		    &HFIL_ERR
		    &HTFL_ERR
               )],

    CONSTANTS => [ qw (
		    &ALIGNM 
		    &ALTSEG 
		    &ALTSEQSIZ 
		    &AUTOSAVE 
		    &AUTOTRN 
		    &BAKMOD 
		    &BAT_CAN 
		    &BAT_COMPLETE 
		    &BAT_DEL 
		    &BAT_FLTR 
		    &BAT_GET 
		    &BAT_GKEY 
		    &BAT_INS 
		    &BAT_KEYS 
		    &BAT_LOK_KEEP 
		    &BAT_LOK_RED 
		    &BAT_LOK_WRT 
		    &BAT_NXT 
		    &BAT_OPC_RESV 
		    &BAT_PKEY 
		    &BAT_RESV1 
		    &BAT_RET_KEY 
		    &BAT_RET_POS 
		    &BAT_RET_REC 
		    &BAT_RPOS 
		    &BAT_UPD 
		    &BAT_VERIFY 
		    &BCDSEG 
		    &BLDADD 
		    &CHECKLOCK 
		    &CHECKREAD 
		    &CIPFASE 
		    &COMMIT_SWAP 
		    &COMPLETE 
		    &CT_2STRING 
		    &CT_4STRING 
		    &CT_ARRAY 
		    &CT_BOOL 
		    &CT_CHAR 
		    &CT_CHARU 
		    &CT_DATE 
		    &CT_DBLSTR 
		    &CT_DFLOAT 
		    &CT_EFLOAT 
		    &CT_F2STRING 
		    &CT_F4STRING 
		    &CT_FPSTRING 
		    &CT_FSTRING 
		    &CT_INT2 
		    &CT_INT2U 
		    &CT_INT4 
		    &CT_INT4U 
		    &CT_LAST 
		    &CT_MONEY 
		    &CT_NUMSTR 
		    &CT_PSTRING 
		    &CT_RESRVD 
		    &CT_SFLOAT 
		    &CT_SQLBCD 
		    &CT_SQLBCDold 
		    &CT_STRFLT 
		    &CT_STRING 
		    &CT_STRLNG 
		    &CT_SUBSTR 
		    &CT_TIME 
		    &CT_TIMES 
		    &CT_TIMESold 
		    &CT_WLDCRD 
		    &DECADD 
		    &DECSEG 
		    &DEFERCP 
		    &DEF_DTREE1 
		    &DEF_DTREE2 
		    &DEF_DTREE3 
		    &DEF_IFIL 
		    &DEF_MAP 
		    &DEF_NAMES 
		    &DEF_NATLNG1 
		    &DEF_NATLNG2 
		    &DEF_NATLNG3 
		    &DEF_NUMBER 
		    &DEF_RESRVD1 
		    &DEF_RESRVD20 
		    &DEF_SQL1 
		    &DEF_SQL2 
		    &DEF_SQL3 
		    &DELUPDT 
		    &DISABLERES 
		    &DSCSEG 
		    &DUPCHANEL 
		    &ENABLE 
		    &ENABLE_BLK 
		    &ENDSEG 
		    &EXCLUSIVE 
		    &FCRES_CIDX 
		    &FCRES_DATA 
		    &FCRES_IDX 
		    &FCRES_SCRT 
		    &FCRES_SQL 
		    &FCRNAM_LEN 
		    &FILDEF 
		    &FILMOD 
		    &FILNAM 
		    &FILTYP 
		    &FLDELM 
		    &FLTSEG 
		    &FNLOCSRV 
		    &FNSRVDIR 
		    &FNSYSABS 
		    &FREE 
		    &FREE_FILE 
		    &FREE_TRAN 
		    &FRSADD 
		    &FRSFLD 
		    &FWDMOD 
		    &GLOBAL 
		    &GPF_ALL 
		    &GRPNAM 
		    &HYS 
		    &IDXNAM 
		    &INCADD 
		    &INTSEG 
		    &KEYDUP 
		    &KEYLEN 
		    &KEYMEM 
		    &KEYPAD 
		    &KEYTYP 
		    &LKSTATE 
		    &LK_BLOCK 
		    &LOGFIL 
		    &LOGIDX 
		    &LOGSIZ 
		    &LSTFLD 
		    &MBRMOD 
		    &MIRNAM 
		    &MIRROR_SKP 
		    &MIRRST 
		    &NO 
		    &NODSIZ 
		    &NONE 
		    &NONEXCLUSIVE 
		    &NOTREUSE 
		    &NXTADD 
		    &OPENCRPT 
		    &OPF_ALL 
		    &OPS_ADMOPN 
		    &OPS_AUTOISAM_TRN 
		    &OPS_CLIENT_TRM 
		    &OPS_COMMIT_SWP 
		    &OPS_FUNCTION_MON 
		    &OPS_LOCKON_BLK 
		    &OPS_LOCKON_GET 
		    &OPS_LOCK_MON 
		    &OPS_MEMORY_SWP 
		    &OPS_MIRROR_NOSWITCH 
		    &OPS_MIRROR_TRM 
		    &OPS_OMITCP 
		    &OPS_ONCE_BLK 
		    &OPS_ONCE_LOK 
		    &OPS_RSVD_2B2 
		    &OPS_RSVD_2B3 
		    &OPS_RSVD_2B4 
		    &OPS_SERIAL_UPD 
		    &OPS_SERVER_SHT 
		    &OPS_SKPDAT 
		    &OPS_STATE_OFF 
		    &OPS_STATE_ON 
		    &OPS_STATE_RET 
		    &OPS_STATE_SET 
		    &OPS_STATE_VRET 
		    &OPS_TRACK_MON 
		    &OPS_UNLOCK_ADD 
		    &OPS_UNLOCK_RWT 
		    &OPS_UNLOCK_UPD 
		    &OPS_VARLEN_CMB 
		    &OPS_internal 
		    &OPS_lockon 
		    &OPS_monitors 
		    &OPS_once 
		    &OPS_permanent 
		    &OPS_server 
		    &OVRFASE 
		    &OWNNAM 
		    &PARTIAL 
		    &PENDERR 
		    &PERFORM_DUMP 
		    &PERFORM_OFF 
		    &PERFORM_ON 
		    &PERMANENT 
		    &PERMSK 
		    &PHYSIZ 
		    &PREIMG 
		    &RCVMOD 
		    &READFIL 
		    &READREC 
		    &READREC_BLK 
		    &RECLEN 
		    &RECPAD 
		    &REGADD 
		    &REGSEG 
		    &RELKEY 
		    &RESET 
		    &RESTORE 
		    &RESTORECTREE 
		    &RESTORE_BLK 
		    &RESTRED 
		    &RESTRED_BLK 
		    &RESTRSV 
		    &RESTRSV_BLK 
		    &RES_FIRST 
		    &RES_LENGTH 
		    &RES_LOCK 
		    &RES_NAME 
		    &RES_NEXT 
		    &RES_POS 
		    &RES_TYPE 
		    &RES_TYPNUM 
		    &RES_UNAVL 
		    &REVMAP 
		    &RSTCURI 
		    &RSVSEG 
		    &SAVCURI 
		    &SAVECTREE 
		    &SAVENV 
		    &SCHEMA_DODA 
		    &SCHEMA_MAP 
		    &SCHEMA_MAPandNAMES 
		    &SCHEMA_NAMES 
		    &SCHSEG 
		    &SEC_FILEGRUP 
		    &SEC_FILEMASK 
		    &SEC_FILEOWNR 
		    &SEC_FILEWORD 
		    &SEGMSK 
		    &SGNSEG 
		    &SHADOW 
		    &SHARED 
		    &SRLSEG 
		    &SS_LOCK 
		    &SUPERFILE 
		    &SUSPEND 
		    &SWTCURI 
		    &SYSMON_MAIN 
		    &SYSMON_OFF 
		    &SegOff
		    &TRNBEGLK 
		    &TRNLOG 
		    &TRNNUM 
		    &TRNTIM 
		    &TWOFASE 
		    &UREGSEG 
		    &USCHSEG 
		    &USERPRF_CLRCHK 
		    &USERPRF_CODCNV 
		    &USERPRF_CUSTOM 
		    &USERPRF_LOCLIB 
		    &USERPRF_MEMABS 
		    &USERPRF_NDATA 
		    &USERPRF_NTKEY 
		    &USERPRF_PTHTMP 
		    &USERPRF_SAVENV 
		    &USERPRF_SERIAL 
		    &USERPRF_SQL 
		    &USRLSTSIZ 
		    &UVARSEG 
		    &UVSCHSEG 
		    &VARSEG 
		    &VIRTUAL 
		    &VLENGTH 
		    &VOID 
		    &VSCHSEG 
		    &WPF_ALL 
		    &WRITETHRU 
		    &XTDSEG 
		    &YES 
		    &YOURSEG1 
		    &YOURSEG2 
		    &cfg749X_MONITOR 
		    &cfg9074_MONITOR 
		    &cfg9477_MONITOR 
		    &cfgADMIN_MIRROR 
		    &cfgANSI 
		    &cfgBOUND 
		    &cfgBUFR_MEMORY 
		    &cfgCHECKPOINT_FLUSH 
		    &cfgCHECKPOINT_IDLE 
		    &cfgCHECKPOINT_INTERVAL 
		    &cfgCHECKPOINT_MONITOR 
		    &cfgCHECKPOINT_PREVIOUS 
		    &cfgCHKPNT_QLENGTH 
		    &cfgCOMMENTS 
		    &cfgCOMMIT 
		    &cfgCOMMIT_DELAY 
		    &cfgCOMM_PROTOCOL 
		    &cfgCOMPATIBILITY 
		    &cfgCONDIDX 
		    &cfgCONTEXT_HASH 
		    &cfgCTBATCH 
		    &cfgCTSTATUS_MASK 
		    &cfgCTSTATUS_SIZE 
		    &cfgCTSUPER 
		    &cfgCTS_ISAM 
		    &cfgDAT_MEMORY 
		    &cfgDEADLOCK_MONITOR 
		    &cfgDIAGNOSTICS 
		    &cfgDISKIO_MODEL 
		    &cfgDNODE_QLENGTH 
		    &cfgDUMP 
		    &cfgFILES 
		    &cfgFILE_HANDLES 
		    &cfgFILE_SPECS 
		    &cfgFORCE_LOGIDX 
		    &cfgFUNCTION_MONITOR 
		    &cfgFUTURE1 
		    &cfgGUEST_LOGON 
		    &cfgGUEST_MEMORY 
		    &cfgIDX_MEMORY 
		    &cfgKEEP_LOGS 
		    &cfgLAST 
		    &cfgLIST_MEMORY 
		    &cfgLOCAL_DIRECTORY 
		    &cfgLOCK_HASH 
		    &cfgLOCK_MONITOR 
		    &cfgLOCLIB 
		    &cfgLOGIDX 
		    &cfgLOGONS 
		    &cfgLOG_EVEN 
		    &cfgLOG_EVEN_MIRROR 
		    &cfgLOG_ODD 
		    &cfgLOG_ODD_MIRROR 
		    &cfgLOG_SPACE 
		    &cfgMAX_DAT_KEY 
		    &cfgMAX_KEY_SEG 
		    &cfgMEMORY_HIGH 
		    &cfgMEMORY_MONITOR 
		    &cfgMEMORY_TRACK 
		    &cfgMEMORY_USAGE 
		    &cfgMIRRORS 
		    &cfgMONAL1_QLENGTH 
		    &cfgMONAL2_QLENGTH 
		    &cfgMONITOR_MASK 
		    &cfgNET_ALLOCS 
		    &cfgNET_LOCKS 
		    &cfgNODEQ_MONITOR 
		    &cfgNODEQ_SEARCH 
		    &cfgNODE_DELAY 
		    &cfgNOGLOBALS 
		    &cfgOPEN_FCBS 
		    &cfgOPEN_FILES 
		    &cfgPAGE_SIZE 
		    &cfgPARMFILE 
		    &cfgPARMFILE_FORMAT 
		    &cfgPASCAL24 
		    &cfgPASCALst 
		    &cfgPATH_SEPARATOR 
		    &cfgPHYSICAL_FILES 
		    &cfgPREIMAGE_DUMP 
		    &cfgPREIMAGE_FILE 
		    &cfgPREIMAGE_HASH 
		    &cfgPROTOTYPE 
		    &cfgQUERY_MEMORY 
		    &cfgRECOVER_DETAILS 
		    &cfgRECOVER_FILES 
		    &cfgRECOVER_MEMLOG 
		    &cfgRECOVER_SKIPCLEAN 
		    &cfgREQUEST_DELAY 
		    &cfgREQUEST_DELTA 
		    &cfgRESOURCE 
		    &cfgRTREE 
		    &cfgSEMAPHORE_BLK 
		    &cfgSERVER_DIRECTORY 
		    &cfgSERVER_NAME 
		    &cfgSESSION_TIMEOUT 
		    &cfgSIGNAL_DOWN 
		    &cfgSIGNAL_MIRROR_EVENT 
		    &cfgSIGNAL_READY 
		    &cfgSKIP_MISSING_FILES 
		    &cfgSKIP_MISSING_MIRRORS 
		    &cfgSORT_MEMORY 
		    &cfgSQL_DEBUG 
		    &cfgSQL_SUPERFILES 
		    &cfgSQL_TABLES 
		    &cfgSTART_EVEN 
		    &cfgSTART_EVEN_MIRROR 
		    &cfgSTART_ODD 
		    &cfgSTART_ODD_MIRROR 
		    &cfgSUPPRESS_LOG_FLUSH 
		    &cfgSYSMON_QLENGTH 
		    &cfgTASKER_LOOP 
		    &cfgTASKER_NP 
		    &cfgTASKER_PC 
		    &cfgTASKER_SLEEP 
		    &cfgTASKER_SP 
		    &cfgTMPNAME_PATH 
		    &cfgTOT_MEMORY 
		    &cfgTRANPROC 
		    &cfgTRANSACTION_FLUSH 
		    &cfgTRAN_HIGH_MARK 
		    &cfgTRAN_TIMEOUT 
		    &cfgUNIFRMAT 
		    &cfgUSERS 
		    &cfgUSER_FILES 
		    &cfgUSER_MEMORY 
		    &cfgUSR_MEMORY 
		    &cfgUSR_MEM_RULE 
		    &cfgVARLDATA 
		    &cfgVARLKEYS 
		    &cfgWORD_ORDER 
		    &ctALIGNhdr 
		    &ctCFGLMT 
		    &ctDODA 
		    &ctDTYPES 
		    &ctDllDecl 
		    &ctEXPORT 
		    &ctFIXED 
		    &ctFLAVORhdr 
		    &ctHISTdata 
		    &ctHISTfirst 
		    &ctHISTfrwd 
		    &ctHISTindx 
		    &ctHISTinfo 
		    &ctHISTkdel 
		    &ctHISTkey 
		    &ctHISTlog 
		    &ctHISTmapmask 
		    &ctHISTnet 
		    &ctHISTnext 
		    &ctHISTnode 
		    &ctHISTpos 
		    &ctHISTuser 
		    &ctISAMKBUFhdr 
		    &ctKEEP 
		    &ctKEEP_OUT 
		    &ctLKIMDS 
		    &ctLKMD_RSV 
		    &ctLK_RSV 
		    &ctLK_RSV_BLK 
		    &ctNEWRECFLG 
		    &ctNUMENThdr 
		    &ctPORTH 
		    &ctSEGLEN 
		    &ctSEGMOD 
		    &ctSEGPOS 
		    &ctSERNUMhdr 
		    &ctTIMEIDhdr 
		    &ctTRANLOCK 
		    &ctTSTAMPhdr 
		    &ctUPF 
		    &ctUSERhdr 
		    &ctlogALL 
		    &ctlogALL_MIRROR 
		    &ctlogLOG 
		    &ctlogLOG_EVEN 
		    &ctlogLOG_EVEN_MIRROR 
		    &ctlogLOG_MIRROR 
		    &ctlogLOG_ODD 
		    &ctlogLOG_ODD_MIRROR 
		    &ctlogSTART 
		    &ctlogSTART_EVEN 
		    &ctlogSTART_EVEN_MIRROR 
		    &ctlogSTART_MIRROR 
		    &ctlogSTART_ODD 
		    &ctlogSTART_ODD_MIRROR 
               )] );

push @EXPORT_OK, @{$EXPORT_TAGS{ISAM}};
push @EXPORT_OK, @{$EXPORT_TAGS{LOW_LEVEL}};
push @EXPORT_OK, @{$EXPORT_TAGS{CONSTANTS}};
push @EXPORT_OK, @{$EXPORT_TAGS{ERRORCODE}};
push @EXPORT_OK, @{$EXPORT_TAGS{VARIABLES}};
$EXPORT_TAGS{ALL} = [@EXPORT_OK];

bootstrap Db::Ctree $VERSION;

# Preloaded methods go here.
require 'Ctport.ph';
require 'Cterrc.ph';

my $init=0;
my $DEBUG=0;

  sub DEBUG
  {
    print "DEBUG was $DEBUG, now $_[0]\n";
    $DEBUG = $_[0]
  }

  sub InitISAM
  {
    $init = MyInitISAM(@_);
  }

#
# routines to handle method access
#
  sub new
  {
    my $self   = shift;
    my $reqno   = shift;
    my $dbfile = shift;
    my $dbmode = shift;

    croak "usage: new dbno dbfile dbmode\n" if @_;
    croak "$dbfile not found!" unless -e $dbfile;
    croak "InitISAM never executed!" unless $init;

    print "Opening $dbfile as file $reqno\n" if $DEBUG;
    my $dbno=OpenFileWithResource($reqno,$dbfile,$dbmode);
    print "Opened  $dbfile as file $dbno status ".&isam_err."\n" if $DEBUG;
    croak sprintf("Error %d (isam_fil=%d) opening $dbfile",&isam_err,&isam_fil)
        if &isam_err;

    my $reclen = GetCtFileInfo($dbno,&RECLEN);
    croak "Unable to get RECLEN for $dbfile ".&uerr_cod if &uerr_cod;

    my $filtyp = GetCtFileInfo($dbno,&FILTYP);
    croak "Unable to get FILTYP for $dbfile ".&uerr_cod if &uerr_cod;

    my $keylen = GetCtFileInfo($dbno+1,&KEYLEN);
    croak "Unable to get RECLEN for $dbfile ".&uerr_cod if &uerr_cod;

    my $dbinfo = {
	DBFILE => $dbfile,
        DBMODE => $dbmode,
        DBNO   => $dbno,
        IDXNO  => $dbno+1,
        RECLEN => $reclen,
        KEYLEN => $keylen,
        FILTYP => $filtyp,
        VARIABLE => $filtyp == 2 ? 1 : 0,
        BUFFER => pack("a$reclen"," "),  # presized buffer
        KEYBUF => pack("a$keylen"," "),  # presized buffer
              };

     print "$dbfile opened as file $dbno\n" if $DEBUG;

    return bless $dbinfo, $self;
  } # new

#--------------------------------
  sub fetch_gte {
     my $self  = shift;
     my $key   = shift;
     my $dbno  = $self -> {DBNO};
     my $idxno = $self -> {IDXNO};
     my $record=  $self -> {BUFFER};
     my $keylen = $self -> {KEYLEN};

     $key = pack("a$keylen",$key) if length($key)<$keylen;

     my $st = GetGTERecord($idxno,$key,$record );
     return undef if $st == &INOT_ERR;

     croak "Error $st reading ".$self -> {DBNAME} if $st;
   
     if ($self -> {VARIABLE})
     {
       my $reclen = VRecordLength($dbno);
       $record = pack("a$reclen"," ");
       $st = ReReadVRecord($dbno,$record,$reclen);
       print "$st - ".length($record)." $record -readvdata\n" if $DEBUG;
       croak "Error $st reading ".$self -> {DBNAME} if $st;
     }  
      
     return $record;
     } #fetch_gte

#--------------------------------
  sub fetch_lte {
     my $self  = shift;
     my $key   = shift;
     my $dbno  = $self -> {DBNO};
     my $idxno = $self -> {IDXNO};
     my $record=  $self -> {BUFFER};
     my $keylen = $self -> {KEYLEN};

     $key = pack("a$keylen",$key) if length($key)<$keylen;

     my $st = GetLTERecord($idxno,$key,$record );
     return undef if $st == &INOT_ERR;

     croak "Error $st reading ".$self -> {DBNAME} if $st;
   
     if ($self -> {VARIABLE})
     {
       my $reclen = VRecordLength($dbno);
       $record = pack("a$reclen"," ");
       $st = ReReadVRecord($dbno,$record,$reclen);
       print "$st - ".length($record)." $record -readvdata\n" if $DEBUG;
       croak "Error $st reading ".$self -> {DBNAME} if $st;
     }  
      
     return $record;
     } #fetch_lte

#--------------------------------
  sub fetch_first {
     my $self  = shift;
     my $dbno  = $self -> {DBNO};
     my $idxno = $self -> {IDXNO};
     my $record=  $self -> {BUFFER};

     my $st = FirstRecord($idxno,$record );

     return undef if $st == &INOT_ERR;
     croak "Error $st reading ".$self -> {DBNAME} if $st;
   
     if ($self -> {VARIABLE})
     {
       my $reclen = VRecordLength($dbno);
       $record = pack("a$reclen"," ");
       $st = ReReadVRecord($dbno,$record,$reclen);
       print "$st - ".length($record)." $record -readvdata\n" if $DEBUG;
       croak "Error $st reading ".$self -> {DBNAME} if $st;
     }  
      
     return $record;
     } #fetch_first

#--------------------------------
  sub fetch_prev {
     my $self  = shift;
     my $dbno  = $self -> {DBNO};
     my $idxno = $self -> {IDXNO};
     my $record=  $self -> {BUFFER};

     my $st = PrevousRecord($idxno,$record );

     return undef if $st == &INOT_ERR;
     croak "Error $st reading ".$self -> {DBNAME} if $st;
   
     if ($self -> {VARIABLE})
     {
       my $reclen = VRecordLength($dbno);
       $record = pack("a$reclen"," ");
       $st = ReReadVRecord($dbno,$record,$reclen);
       print "$st - ".length($record)." $record -readvdata\n" if $DEBUG;
       croak "Error $st reading ".$self -> {DBNAME} if $st;
     }  
      
     return $record;
     } #fetch_prev

#--------------------------------
  sub fetch_next {
     my $self  = shift;
     my $dbno  = $self -> {DBNO};
     my $idxno = $self -> {IDXNO};
     my $record=  $self -> {BUFFER};

     my $st = NextRecord($idxno,$record );

     return undef if $st == &INOT_ERR;
     croak "Error $st reading ".$self -> {DBNAME} if $st;
   
     if ($self -> {VARIABLE})
     {
       my $reclen = VRecordLength($dbno);
       $record = pack("a$reclen"," ");
       $st = ReReadVRecord($dbno,$record,$reclen);
       print "$st - ".length($record)." $record -readvdata\n" if $DEBUG;
       croak "Error $st reading ".$self -> {DBNAME} if $st;
     }  
      
     return $record;
     } #fetch_next

#
# Routine to build schema per DODA
#
   sub build_schema 
   {
    my $self  = shift;
    my $dbno  = $self -> {DBNO};

    my ($fsymb,$fadr,$ftype,$flen);
    my @fname=();
    my @ftype=();
    my @doda=&MyGetDODA($dbno);

    print "build schema active\n" if $DEBUG;
    croak "Unable to get DODA for file $dbno!" if $#doda < 1;
    my $curpos=0;
    while ($#doda > 0)
    {
        $fsymb = shift @doda;
        $fadr  = shift @doda;
        $ftype = shift @doda;
        $flen  = shift @doda;
        if ($curpos != $fadr)
        {
             if ($curpos < $fadr)
             {
               my $padcnt = $fadr - $curpos;
               push @ftype,('x' x $padcnt);
               $curpos += $padcnt;
             }   
             else
             {
               carp "Warning: $fsymb DODA position $fadr, computed $curpos\n";
             }
        }
        push @fname,$fsymb;
        print "$fsymb type $ftype/$flen\n" if $DEBUG;
        if ($ftype == &CT_FSTRING)
        {
            push @ftype,"A$flen";
            $curpos += $flen;
        }
        elsif ($ftype == &CT_STRING)
        {
            push @ftype,'A*';
            $curpos += $flen;
        }
        elsif ($ftype == &CT_INT4)
        {
            push @ftype, 'l';
            $curpos += 4;
        }
        else
        {
            carp "bad field type $ftype for $fsymb";
        }
     } # doda while
       $self -> {FNAME} = \@fname;
       $self -> {FTYPE} = \@ftype;
       $self -> {FMASK} = join(" ",@ftype);
       return 0;
    } # build_schema


#
# Routine to split CTREE record per DODA
#
  sub unpack_record
  { 
   my $self    = shift;
   my $record    = shift;
   my $dbno    =  $self -> {DBNO};
   my $fname   =  $self -> {FNAME};
   my $ftype   =  $self -> {FTYPE};
   my $fmask   =  $self -> {FMASK};

   unless (defined $fname)
   {
      $self -> build_schema();
      $fname   =  $self -> {FNAME};
      $ftype   =  $self -> {FTYPE};
      $fmask   =  $self -> {FMASK};
   }

   my @fname  = @$fname;
   my @ftype  = @$ftype;
   my @values = unpack($fmask,$record);
   my %hash   = ();
   my @vbuff  = ();
   foreach (0..$#fname)
   {
      print "unpack_record $fname[$_] = $values[$_]\n" if $DEBUG;
      if ($ftype[$_] eq 'A*')
      {
        @vbuff  = split (/\0/,$values[$_]) if  $#vbuff < 0;
        $hash{$fname[$_]} = shift @vbuff;
      }
      else
      { 
         $hash{$fname[$_]} = $values[$_];
      }
   }
   return %hash;
  } #unpack record

	   
#
# routines to handle tied hahses
#
  sub TIEHASH
  {
      goto &new;
  } # TIEHASH
	   
#--------------------------------
  sub FETCH {
     my $self  = shift;
     my $key   = shift;
     my $dbno  = $self -> {DBNO};
     my $idxno = $self -> {IDXNO};
     my $record=  $self -> {BUFFER};

     my $keylen = $self -> {KEYLEN};

     $key = pack("a$keylen",$key) if length($key)<$keylen;
     my $st = GetRecord($idxno,$key,$record );
     print "FETCH: returned $st\n" if $DEBUG;

     return undef if $st == &INOT_ERR;
     croak "Error $st reading ".$self -> {DBNAME} if $st;
   
     if ($self -> {VARIABLE})
     {
       my $reclen = VRecordLength($dbno);
       $record = pack("a$reclen"," ");
       $st = ReReadVRecord($dbno,$record,$reclen);
       print "$st - ".length($record)." $record -readvdata\n" if $DEBUG;
       croak "Error $st reading ".$self -> {DBNAME} if $st;
     }  
      
     return $record;
     } #fetch

#--------------------------------
   sub STORE {
     my $self  = shift;
     my $key   = shift;
     my $value = shift;
     my $dbno  = $self -> {DBNO};
     my $idxno = $self -> {IDXNO};
 
     
     if ( ($self -> {VARIABLE}) ? AddVRecord($dbno,$value)
                                : AddRecord($dbno,$value,length($value)) )
     {
        croak sprintf("Error on AddRecord. isam_err=%d,isam_fil=%d",
                       &isam_err,&isam_fil);
     }
       
     return $value;
     }

#--------------------------------
  sub EXISTS {
     my $self  = shift;
     my $key   = shift;
     my $dbno  = $self -> {DBNO};
     my $idxno = $self -> {IDXNO};

     my $keylen = $self -> {KEYLEN};

     $key = pack("a$keylen",$key) if length($key)<$keylen;
     my $st = GetKey($idxno,$key);

     return  $st ? 0 : 1;
     } # EXISTS

#--------------------------------
   sub FIRSTKEY {
     my $self  = shift;
     my $dbno  = $self -> {DBNO};
     my $idxno = $self -> {IDXNO};
     my $key   = $self -> {BUFFER};
 
     FirstKey($idxno,$key);
     my $st = &uerr_cod;
     croak "Error $st on FirstKey ".$self -> {DBNAME} if $st;
       
     return $key;
     }

#--------------------------------
   sub NEXTKEY {
     my $self  = shift;
     my $key   = shift;
     my $dbno  = $self -> {DBNO};
     my $idxno = $self -> {IDXNO};
     my $keylen = $self -> {KEYLEN};

     $key = pack("a$keylen",$key) if length($key)<$keylen;
 
     my $rec  = NextKey($idxno,$key);
     my $st   = &uerr_cod;
     return undef unless ($rec || $st);

     croak "Error $st on NextKey ".$self -> {DBNAME} if $st;
       
     return $key;
     }

#--------------------------------
   sub DESTROY {
     my $self  = shift;
     my $dbno  = $self -> {DBNO};
 
     print "about to close file $dbno\n" if $DEBUG;

     my $st = CloseRFile($dbno);
     croak "Error $st on CloseRFile ".$self -> {DBNAME} if $st;

     }

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Db::Ctree - Perl extension to interface with Faircom's CTREE product

=head1 SYNOPSIS

  use Db::Ctree qw(:all);

  InitISAM(10,2,4);
  $ptr = Db::Ctree -> new(0,'file.dat',&SHARED);
  $record = $ptr -> fetch_first();
  while ($record)
  {
     print $record."\n";
     $record = $ptr -> fetch_next();
  }

=head1 DESCRIPTION

This module allows the use of some ISAM and Low-Level CTREE routines
from within perl.  It is a PERL5 replacement for CTREEPERL by John Conover.

In addition to base CTREE functionality, the ability to tie a hash to 
a CTREE table, and some method based access is available.


=head1 Base CTREE support.

Support is provided for most low-level and ISAM routines as documented in
the Faircom documentation.  Those routines that use C structures
(resource records, DODA) are not currently supported. A routine that reads
DODA records is available in the METHOD access method.

Like in C it is very important to pre-allocate the destination on reads.   
Db::CTree just calls the Ctree routine... you *WILL* crash perl just as fast
as you crash C without preallocating enough space.

=head1 Error code functions

With C, error status is available via global variables.  Db::Ctree provides
functions that access the following global "C" variables.

		    &isam_err
		    &isam_fil
		    &sysiocod
		    &uerr_cod

=head1 Perl hash TIE support

A limited Perl hash TIE implementation is available.  If the file has been 
created by a C program, includes resource records, and uses unique keys,
it can be TIED to a Perl hash.  Unique keys are required because the tie
uses the GetRecord facility which requires Unique keys.

TIE returns a pointer you can use for method access.

Preallocating of space is not required for TIE support.

The file is automatically closed when the hash (and ptr returned by TIE) is
destroyed or reassigned.

Sample Code:
   InitISAM(10,2,4);
   tie %hash, "Db::Ctree",2, $testIfile,&SHARED;
   foreach (keys (%hash) )
   {
       printf "%-10s=%s\n",$_,$hash{$_};
   }

=head1 Perl METHOD support

A limited Perl method access is provided. The following methods are available.
In case of error, most functions will return undef. For details, use the error
function defined above.

These functions ensure enough space is available for the CTREE return values.
There is no need to preallocate the space.  Variable/Fixed functions are 
also selected for you.


new (fileno,filename,mode)
        returns an object reference to the open file.

fetch_first()
        returns the first record based on the current index.

fetch_gte {$key)
        note:  key modified with current key
        returns the record just like getGTErecord
          
fetch_lte {$key)
        note:  key modified with current key
        returns the record just like getGTErecord
          
fetch_prev {)
        returns the record just like getGTErecord

fetch_next {)
        returns the record just like getGTErecord

unpack_record($record)
        note: DODA must be stored in file
        returns hash with fields as keys

Sample Code:
   InitISAM(10,2,4);
   $dbptr = Db::Ctree -> new(2, $testIfile,&SHARED);
   $record = $dbptr -> fetch_first;
   while ($record)
   {
       %hash = $dbptr -> unpack_record($record);
       print "$hash{COLUMN}\n";
       $record = $dbptr -> fetch_next;
   }


=head1 Notes

ISAM and LOW LEVEL calls do not preallocate space (like C). Be sure 
your variables are big enough! (Method and HASH access do this for you)

InitISAM sets a tag variable in a class with a DESTROY method that should
issue a StopUser upon a normal Perl exit (including Die's).  This prevents
leaving shared memory segments around in server based systems.  If you
coredump (die without Perl cleaning up), these memory segments can be
left around and eventually crash your server!

Ctree functions are not exported by default. EXPORTER tags are available for 
ALL,ISAM,LOWLEVEL,CONSTANTS and VARIABLES. Personally, I just import tag
":all" and live with the namespace pollution.

I've also included ctdump and ctload.  These are some simple ctree perl 
routines I've written to dump and load tables. (The tables were created
by a C program and have resource and DODA structures already.)

=head1 Author

Robert Eden
CommTech Corporation
rmeden@yahoo.com

=head1 SEE ALSO

perl(1),
Faircom C-Tree Plus Function Reference Guide,
Faircom C-Tree Plus Programmer's Guide
=cut
