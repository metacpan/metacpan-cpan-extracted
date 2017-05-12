/*
Copyright (c) 2007-2010 Don Owens <don@regexguy.com>.  All rights reserved.

 This is free software; you can redistribute it and/or modify it under
 the Perl Artistic license.  You should have received a copy of the
 Artistic license with this distribution, in the file named
 "Artistic".  You may also obtain a copy from
 http://regexguy.com/license/Artistic

 This program is distributed in the hope that it will be
 useful, but WITHOUT ANY WARRANTY; without even the implied
 warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
*/

#ifndef EVT_H
#define EVT_H

#include "jsonevt.h"
#include "jsonevt_utils.h"

SV *
do_json_parse_buf(SV * self_sv, char * buf, STRLEN buf_len);

SV * do_json_parse(SV * self_sv, SV * json_str_sv);
SV * do_json_parse_file(SV * self_sv, SV * file_sv);
SV * do_json_dummy_parse(SV *self_sv, SV * json_str_sv);

#endif

