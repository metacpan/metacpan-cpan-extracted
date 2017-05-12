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

MODULE = HTML::MyHTML::Tree::Node  PACKAGE = HTML::MyHTML::Tree::Node
PROTOTYPES: DISABLE

#=sort 1

SV*
info(node, tree)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = newRV_noinc((SV *)sm_get_node_info(tree, node));
	OUTPUT:
		RETVAL

#=sort 2

HTML::MyHTML::Tree::Node
next(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_next(node);
	OUTPUT:
		RETVAL
	POSTCALL:
	  if(RETVAL == NULL)
		XSRETURN_UNDEF;

#=sort 3

HTML::MyHTML::Tree::Node
prev(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_prev(node);
	OUTPUT:
		RETVAL
	POSTCALL:
	  if(RETVAL == NULL)
		XSRETURN_UNDEF;

#=sort 4

HTML::MyHTML::Tree::Node
parent(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_parent(node);
	OUTPUT:
		RETVAL
	POSTCALL:
	  if(RETVAL == NULL)
		XSRETURN_UNDEF;

#=sort 5

HTML::MyHTML::Tree::Node
child(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_child(node);
	OUTPUT:
		RETVAL
	POSTCALL:
	  if(RETVAL == NULL)
		XSRETURN_UNDEF;

#=sort 6

HTML::MyHTML::Tree::Node
last_child(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_last_child(node);
	OUTPUT:
		RETVAL
	POSTCALL:
	  if(RETVAL == NULL)
		XSRETURN_UNDEF;

#=sort 6

HTML::MyHTML::Token::Node
token(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_token(node);
	OUTPUT:
		RETVAL
	POSTCALL:
	  if(RETVAL == NULL)
		XSRETURN_UNDEF;

#=sort 6

SV*
get_nodes_by_attribute_key(node, tree, key, out_status = &PL_sv_undef)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	SV* key;
	SV* out_status;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_key = NULL;
		
		if(SvOK(key)) {
			char_key = SvPV(key, len);
		}
		
		myhtml_status_t status;
		myhtml_collection_t *collection = myhtml_get_nodes_by_attribute_key(tree, NULL, node, char_key, len, &status);
		sm_set_out_status(out_status, status);
		
		if(status == MyHTML_STATUS_OK) {
			RETVAL = newRV_noinc((SV *)sm_get_elements_by_collections(collection));
		}
		else {
			RETVAL = &PL_sv_undef;
		}
	OUTPUT:
		RETVAL

#=sort 6

SV*
get_nodes_by_attribute_value(node, tree, case_insensitive, key, value, out_status = &PL_sv_undef)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	SV* case_insensitive;
	SV* key;
	SV* value;
	SV* out_status;
	
	CODE:
		RETVAL = sm_get_nodes_by_attribute_value(node, tree, case_insensitive, key, value, out_status, myhtml_get_nodes_by_attribute_value);
		
	OUTPUT:
		RETVAL

#=sort 6

SV*
get_nodes_by_attribute_value_whitespace_separated(node, tree, case_insensitive, key, value, out_status = &PL_sv_undef)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	SV* case_insensitive;
	SV* key;
	SV* value;
	SV* out_status;
	
	CODE:
		RETVAL = sm_get_nodes_by_attribute_value(node, tree, case_insensitive, key, value, out_status, myhtml_get_nodes_by_attribute_value_whitespace_separated);
		
	OUTPUT:
		RETVAL

#=sort 6

SV*
get_nodes_by_attribute_value_begin(node, tree, case_insensitive, key, value, out_status = &PL_sv_undef)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	SV* case_insensitive;
	SV* key;
	SV* value;
	SV* out_status;
	
	CODE:
		RETVAL = sm_get_nodes_by_attribute_value(node, tree, case_insensitive, key, value, out_status, myhtml_get_nodes_by_attribute_value_begin);
		
	OUTPUT:
		RETVAL

SV*
get_nodes_by_attribute_value_end(node, tree, case_insensitive, key, value, out_status = &PL_sv_undef)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	SV* case_insensitive;
	SV* key;
	SV* value;
	SV* out_status;
	
	CODE:
		RETVAL = sm_get_nodes_by_attribute_value(node, tree, case_insensitive, key, value, out_status, myhtml_get_nodes_by_attribute_value_end);
		
	OUTPUT:
		RETVAL

SV*
get_nodes_by_attribute_value_contain(node, tree, case_insensitive, key, value, out_status = &PL_sv_undef)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	SV* case_insensitive;
	SV* key;
	SV* value;
	SV* out_status;
	
	CODE:
		RETVAL = sm_get_nodes_by_attribute_value(node, tree, case_insensitive, key, value, out_status, myhtml_get_nodes_by_attribute_value_contain);
		
	OUTPUT:
		RETVAL

SV*
get_nodes_by_attribute_value_hyphen_separated(node, tree, case_insensitive, key, value, out_status = &PL_sv_undef)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	SV* case_insensitive;
	SV* key;
	SV* value;
	SV* out_status;
	
	CODE:
		RETVAL = sm_get_nodes_by_attribute_value(node, tree, case_insensitive, key, value, out_status, myhtml_get_nodes_by_attribute_value_hyphen_separated);
		
	OUTPUT:
		RETVAL

SV*
get_nodes_by_tag_id(node, tree, tag_id, out_status = &PL_sv_undef)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	myhtml_tag_id_t tag_id;
	SV* out_status;
	
	CODE:
		myhtml_status_t status;
		myhtml_collection_t* collection = myhtml_get_nodes_by_tag_id_in_scope(tree, NULL, node, tag_id, &status);
		sm_set_out_status(out_status, status);
		
		if(status == MyHTML_STATUS_OK) {
			RETVAL = newRV_noinc((SV *)sm_get_elements_by_collections(collection));
		}
		else {
			RETVAL = &PL_sv_undef;
		}
		
	OUTPUT:
		RETVAL

#=sort 7

void
free(node, tree)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	
	CODE:
		myhtml_node_free(tree, node);

#=sort 8

HTML::MyHTML::Tree::Node
remove(node, tree)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_node_remove(tree, node);
	OUTPUT:
		RETVAL

#=sort 9

void
delete(node, tree)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	
	CODE:
		myhtml_node_delete(tree, node);

#=sort 10

void
delete_recursive(node, tree)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	
	CODE:
		myhtml_node_delete_recursive(tree, node);

#=sort 11

myhtml_tag_id_t
tag_id(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_tag_id(node);
	OUTPUT:
		RETVAL

#=sort 12

enum myhtml_namespace
namespace(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_namespace(node);
	OUTPUT:
		RETVAL

#=sort 13

SV*
tag_name(node, tree)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	
	CODE:
		size_t length;
		const char* name = myhtml_tag_name_by_id(tree, myhtml_node_tag_id(node), &length);
		RETVAL = newSVpv(name, length);
	OUTPUT:
		RETVAL

#=sort 14

bool
is_close_self(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_is_close_self(node);
	OUTPUT:
		RETVAL

#=sort 15

HTML::MyHTML::Tree::Attr
attr_first(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_attribute_first(node);
	OUTPUT:
		RETVAL

#=sort 16

HTML::MyHTML::Tree::Attr
attr_last(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_attribute_last(node);
	OUTPUT:
		RETVAL

#=sort 17

HTML::MyHTML::Tree::Attr
attr_add(node, tree, key, value, encoding)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	SV* key;
	SV* value;
	myhtml_encoding_t encoding;
	
	PREINIT:
		STRLEN key_len;
		STRLEN value_len;
	CODE:
		const char *char_key   = SvPV(key, key_len);
		const char *char_value = SvPV(key, value_len);
		
		RETVAL = myhtml_attribute_add(tree, node, char_key, key_len, char_value, value_len, encoding);
	OUTPUT:
		RETVAL

#=sort 18

HTML::MyHTML::Tree::Attr
attr_remove_by_key(node, key)
	myhtml_tree_node_t *node;
	SV* key;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_key = SvPV(key, len);
		RETVAL = myhtml_attribute_remove_by_key(node, char_key, len);
	OUTPUT:
		RETVAL

#=sort 19

HTML::MyHTML::Tree::Attr
attr_by_key(node, key)
	myhtml_tree_node_t *node;
	SV* key;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_key = SvPV(key, len);
		RETVAL = myhtml_attribute_by_key(node, char_key, len);
	OUTPUT:
		RETVAL

#=sort 20

SV*
text(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		size_t length;
		const char* text = myhtml_node_text(node, &length);
		RETVAL = newSVpv(text, length);
	OUTPUT:
		RETVAL

#=sort 21

HTML::MyHTML::String
string(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_string(node);
	OUTPUT:
		RETVAL

#=sort 22

void
print(node, tree, fh, inc)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	FILE* fh;
	size_t inc;
	
	CODE:
		myhtml_tree_print_by_node(tree, node, fh, inc);

#=sort 23

void
print_children(node, tree, fh, inc)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	FILE* fh;
	size_t inc;
	
	CODE:
		myhtml_tree_print_node_children(tree, node, fh, inc);

#=sort 24

void
print_all(node, tree, fh)
	HTML::MyHTML::Tree::Node node;
	HTML::MyHTML::Tree tree;
	FILE* fh;
	
	CODE:
		myhtml_tree_print_node(tree, node, fh);

