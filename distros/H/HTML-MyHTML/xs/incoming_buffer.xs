#/*
# Copyright 2015-2016 Alexander Borisov
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
# Author: lex.borisov@gmail.com (Alexander Borisov)
#*/

MODULE = HTML::Incoming::Buffer  PACKAGE = HTML::Incoming::Buffer
PROTOTYPES: DISABLE


HTML::Incoming::Buffer
find_by_position(inc_buffer, begin)
	HTML::Incoming::Buffer inc_buffer;
	SV* begin;
	
	CODE:
		RETVAL = myhtml_incoming_buffer_find_by_position(inc_buffer, SvIV(begin));
	OUTPUT:
		RETVAL
	POSTCALL:
	  if(RETVAL == NULL)
		XSRETURN_UNDEF;

SV*
data(inc_buffer)
	HTML::Incoming::Buffer inc_buffer;
	
	CODE:
		const char *data = myhtml_incoming_buffer_data(inc_buffer);
		RETVAL = newSVpv(data, myhtml_incoming_buffer_size(inc_buffer));
	OUTPUT:
		RETVAL

SV*
length(inc_buffer)
	HTML::Incoming::Buffer inc_buffer;
	
	CODE:
		RETVAL = newSViv(myhtml_incoming_buffer_length(inc_buffer));
	OUTPUT:
		RETVAL

SV*
size(inc_buffer)
	HTML::Incoming::Buffer inc_buffer;
	
	CODE:
		RETVAL = newSViv(myhtml_incoming_buffer_size(inc_buffer));
	OUTPUT:
		RETVAL

SV*
offset(inc_buffer)
	HTML::Incoming::Buffer inc_buffer;
	
	CODE:
		RETVAL = newSViv(myhtml_incoming_buffer_offset(inc_buffer));
	OUTPUT:
		RETVAL

SV*
relative_begin(inc_buffer, begin)
	HTML::Incoming::Buffer inc_buffer;
	SV* begin;
	
	CODE:
		RETVAL = newSViv(myhtml_incoming_buffer_relative_begin(inc_buffer, SvIV(begin)));
	OUTPUT:
		RETVAL

SV*
available_length(inc_buffer, relative_begin, length)
	HTML::Incoming::Buffer inc_buffer;
	SV* relative_begin;
	SV* length;
	
	CODE:
		RETVAL = newSViv(myhtml_incoming_buffer_available_length(inc_buffer, SvIV(relative_begin), SvIV(length)));
	OUTPUT:
		RETVAL

HTML::Incoming::Buffer
next(inc_buffer)
	HTML::Incoming::Buffer inc_buffer;
	
	CODE:
		RETVAL = myhtml_incoming_buffer_next(inc_buffer);
	OUTPUT:
		RETVAL
	POSTCALL:
	  if(RETVAL == NULL)
		XSRETURN_UNDEF;

HTML::Incoming::Buffer
prev(inc_buffer)
	HTML::Incoming::Buffer inc_buffer;
	
	CODE:
		RETVAL = myhtml_incoming_buffer_prev(inc_buffer);
	OUTPUT:
		RETVAL
	POSTCALL:
	  if(RETVAL == NULL)
		XSRETURN_UNDEF;

