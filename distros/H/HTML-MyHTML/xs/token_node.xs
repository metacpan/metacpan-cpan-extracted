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

MODULE = HTML::MyHTML::Token::Node  PACKAGE = HTML::MyHTML::Token::Node
PROTOTYPES: DISABLE

#=sort 1

SV*
info(token_node, tree)
	HTML::MyHTML::Token::Node token_node;
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = newRV_noinc((SV *)sm_get_token_node_info(tree, token_node));
	OUTPUT:
		RETVAL

myhtml_tag_id_t
tag_id(token_node)
	HTML::MyHTML::Token::Node token_node;
	
	CODE:
		RETVAL = myhtml_token_node_tag_id(token_node);
	OUTPUT:
		RETVAL

SV*
tag_name(token_node, tree)
	HTML::MyHTML::Token::Node token_node;
	HTML::MyHTML::Tree tree;
	
	CODE:
		size_t length;
		const char* name = myhtml_tag_name_by_id(tree, myhtml_token_node_tag_id(token_node), &length);
		RETVAL = newSVpv(name, length);
	OUTPUT:
		RETVAL

#=sort 14

bool
is_close_self(token_node)
	HTML::MyHTML::Token::Node token_node;
	
	CODE:
		RETVAL = myhtml_token_node_is_close_self(token_node);
	OUTPUT:
		RETVAL

#=sort 15

HTML::MyHTML::Tree::Attr
attr_first(token_node)
	HTML::MyHTML::Token::Node token_node;
	
	CODE:
		RETVAL = myhtml_token_node_attribute_first(token_node);
	OUTPUT:
		RETVAL

#=sort 16

HTML::MyHTML::Tree::Attr
attr_last(token_node)
	HTML::MyHTML::Token::Node token_node;
	
	CODE:
		RETVAL = myhtml_token_node_attribute_last(token_node);
	OUTPUT:
		RETVAL

SV*
text(token_node)
	HTML::MyHTML::Token::Node token_node;
	
	CODE:
		size_t length;
		const char* text = myhtml_token_node_text(token_node, &length);
		RETVAL = newSVpv(text, length);
	OUTPUT:
		RETVAL

#=sort 21

HTML::MyHTML::String
string(token_node)
	HTML::MyHTML::Token::Node token_node;
	
	CODE:
		RETVAL = myhtml_token_node_string(token_node);
	OUTPUT:
		RETVAL

#=sort 22

void
wait_for_done(token_node)
	HTML::MyHTML::Token::Node token_node;
	
	CODE:
		myhtml_token_node_wait_for_done(token_node);

