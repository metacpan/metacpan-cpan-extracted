PUSHDIVERT(-1)
#
#   Mailer for IspMailGate
#

ifdef(`ISPMAILGATE_MAILER_ARGS',,
	`define(`ISPMAILGATE_MAILER_ARGS', ispMailGateD --debug --from $f $u $f)')
ifdef(`ISPMAILGATE_MAILER_PATH',,
	`define(`ISPMAILGATE_MAILER_PATH', /usr/bin/ispMailGateD)')
ifdef(`ISPMAILGATE_MAILER_MAX',,
	`define(`ISPMAILGATE_MAILER_MAX', 10000000)')
POPDIVERT
####################################
###   ISPMAILGATE Mailer specification   ###
####################################

VERSIONID(`@(#)ISPMAILGATE.m4	19-Aug-1999')

MISPMAILGATE,		P=ISPMAILGATE_MAILER_PATH, F=DFMhu, S=15, R=25, M=ISPMAILGATE_MAILER_MAX, T=X-Phone/X-ISPMAILGATE/X-Unix,
		A=ISPMAILGATE_MAILER_ARGS

LOCAL_CONFIG
CPISPMAILGATE
