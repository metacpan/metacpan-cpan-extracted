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

MODULE = HTML::MyHTML::Tree  PACKAGE = HTML::MyHTML::Tree
PROTOTYPES: DISABLE

#=sort 1

myhtml_status_t
init(tree, myhtml)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML myhtml;
	
	CODE:
		RETVAL = myhtml_tree_init(tree, myhtml);
	OUTPUT:
		RETVAL

#=sort 2

void
parse_flags_set(tree, parse_flags)
	HTML::MyHTML::Tree tree;
	myhtml_tree_parse_flags_t parse_flags;
	
	CODE:
		myhtml_tree_parse_flags_set(tree, parse_flags);

#=sort 2

myhtml_tree_parse_flags_t
parse_flags(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_parse_flags(tree);
	OUTPUT:
		RETVAL

#=sort 2

void
clean(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		myhtml_tree_clean(tree);

#=sort 3

HTML::MyHTML::Tree
destroy(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_destroy(tree);
	OUTPUT:
		RETVAL

#=sort 4

HTML::MyHTML
get_myhtml(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_myhtml(tree);
	OUTPUT:
		RETVAL

#=sort 5

HTML::MyHTML::Tag
get_tag(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_tag(tree);
	OUTPUT:
		RETVAL

#=sort 6

HTML::MyHTML::Tag::Index
get_tag_index(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_tag_index(tree);
	OUTPUT:
		RETVAL

#=sort 7

HTML::MyHTML::Tree::Node
document(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_document(tree);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
html(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_node_html(tree);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
head(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_node_head(tree);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
body(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_node_body(tree);
	OUTPUT:
		RETVAL


#=sort 8

mchar_async_t*
get_mchar(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_mchar(tree);
	OUTPUT:
		RETVAL

#=sort 9

size_t
get_mchar_node_id(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_mchar_node_id(tree);
	OUTPUT:
		RETVAL

#=sort 10

SV*
get_elements_by_tag_id(tree, tag_id)
	HTML::MyHTML::Tree tree;
	myhtml_tag_id_t tag_id;
	
	CODE:
		RETVAL = newRV_noinc((SV *)sm_get_elements_by_tag_id(tree, tag_id));
	OUTPUT:
		RETVAL

#=sort 11

SV*
get_elements_by_tag_name(tree, tag_name)
	HTML::MyHTML::Tree tree;
	SV* tag_name;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_tag_name = SvPV(tag_name, len);
		
		myhtml_tag_id_t tag_id = myhtml_tag_id_by_name(tree, char_tag_name, len);
		RETVAL = newRV_noinc((SV *)sm_get_elements_by_tag_id(tree, tag_id));
	OUTPUT:
		RETVAL

HTML::Incoming::Buffer
incoming_buffer_first(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_incoming_buffer_first(tree);
	OUTPUT:
		RETVAL


