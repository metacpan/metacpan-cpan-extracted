PUSHDIVERT(-1)
#
# Copyright (c) 1983 Eric P. Allman
# Copyright (c) 1988, 1993
#	The Regents of the University of California.  All rights reserved.
# Copyright 1998 Christopher Davis <ckd@loiosh.kei.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#	This product includes software developed by the University of
#	California, Berkeley and its contributors.
# 4. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

ifdef(`LISTGATE_MAILER_PATH',, `define(`LISTGATE_MAILER_PATH', /usr/local/bin/listgate)')
ifdef(`LISTGATE_MAILER_FLAGS',, `define(`LISTGATE_MAILER_FLAGS', `DFMlmnS')')
ifdef(`LISTGATE_MAILER_USER',, `define(`LISTGATE_MAILER_USER', `news:news')')
POPDIVERT
######################################
###  LISTGATE Mailer specification ###
######################################

VERSIONID(`$Id: listgate.m4,v 1.2 1998/02/19 08:37:50 eagle Exp $ based on usenet.m4 version 8.5')

Mlistgate,	P=LISTGATE_MAILER_PATH, F=LISTGATE_MAILER_FLAGS, S=10, R=20/40,
		_OPTINS(`LISTGATE_MAILER_MAX', `M=', `, ')T=X-Usenet/X-Usenet/X-Unix,
		U=LISTGATE_MAILER_USER, A=listgate $u
