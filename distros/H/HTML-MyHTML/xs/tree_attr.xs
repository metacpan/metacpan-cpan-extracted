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

MODULE = HTML::MyHTML::Tree::Attr  PACKAGE = HTML::MyHTML::Tree::Attr
PROTOTYPES: DISABLE

SV*
info(attr)
	HTML::MyHTML::Tree::Attr attr;
	
	CODE:
		RETVAL = newRV_noinc((SV *)sm_get_attr_info(attr));
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Attr
next(attr)
	HTML::MyHTML::Tree::Attr attr;
	
	CODE:
		RETVAL = myhtml_attribute_next(attr);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Attr
prev(attr)
	HTML::MyHTML::Tree::Attr attr;
	
	CODE:
		RETVAL = myhtml_attribute_prev(attr);
	OUTPUT:
		RETVAL

enum myhtml_namespace
namespace(attr)
	HTML::MyHTML::Tree::Attr attr;
	
	CODE:
		RETVAL = myhtml_attribute_namespace(attr);
	OUTPUT:
		RETVAL

SV*
name(attr)
	HTML::MyHTML::Tree::Attr attr;
	
	CODE:
		size_t length;
		const char* name = myhtml_attribute_key(attr, &length);
		RETVAL = newSVpv(name, length);
	OUTPUT:
		RETVAL

SV*
value(attr)
	HTML::MyHTML::Tree::Attr attr;
	
	CODE:
		size_t length;
		const char* value = myhtml_attribute_value(attr, &length);
		RETVAL = newSVpv(value, length);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Attr
remove(attr, node)
	myhtml_tree_attr_t *attr;
	myhtml_tree_node_t *node;
	
	CODE:
		RETVAL = myhtml_attribute_remove(node, attr);
	OUTPUT:
		RETVAL

void
delete(attr, tree, node)
	myhtml_tree_attr_t *attr;
	myhtml_tree_t *tree;
	myhtml_tree_node_t *node;
	
	CODE:
		myhtml_attribute_delete(tree, node, attr);

void
free(attr, tree)
	myhtml_tree_attr_t *attr;
	myhtml_tree_t *tree;
	
	CODE:
		myhtml_attribute_free(tree, attr);



