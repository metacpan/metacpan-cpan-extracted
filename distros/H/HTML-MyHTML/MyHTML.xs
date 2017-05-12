/*
 Copyright 2015-2016 Alexander Borisov
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 Author: lex.borisov@gmail.com (Alexander Borisov)
*/

#include "EXTERN.h"
#include "perl.h"

#include "source/myhtml/callback.c"
#include "source/myhtml/charef.c"
#include "source/myhtml/data_process.c"
#include "source/myhtml/encoding.c"
#include "source/myhtml/encoding_detect.c"
#include "source/myhtml/incoming.c"
#include "source/myhtml/myhtml.c"
#include "source/myhtml/mynamespace.c"
#include "source/myhtml/myosi.c"
#include "source/myhtml/mystring.c"
#include "source/myhtml/parser.c"
#include "source/myhtml/perf.c"
#include "source/myhtml/rules.c"
#include "source/myhtml/stream.c"
#include "source/myhtml/tag.c"
#include "source/myhtml/tag_init.c"
#include "source/myhtml/thread.c"
#include "source/myhtml/token.c"
#include "source/myhtml/tokenizer.c"
#include "source/myhtml/tokenizer_doctype.c"
#include "source/myhtml/tokenizer_end.c"
#include "source/myhtml/tokenizer_script.c"
#include "source/myhtml/tree.c"
#include "source/myhtml/utils/mchar_async.c"
#include "source/myhtml/utils/mcobject.c"
#include "source/myhtml/utils/mcobject_async.c"
#include "source/myhtml/utils/mcsimple.c"
#include "source/myhtml/utils/mcsync.c"
#include "source/myhtml/utils/mctree.c"
#include "source/myhtml/utils.c"

#include "XSUB.h"

typedef myhtml_t * HTML__MyHTML;
typedef myhtml_tree_t * HTML__MyHTML__Tree;
typedef myhtml_tree_node_t * HTML__MyHTML__Tree__Node;
typedef myhtml_tree_attr_t * HTML__MyHTML__Tree__Attr;
typedef myhtml_tag_t * HTML__MyHTML__Tag;
typedef myhtml_tag_index_t * HTML__MyHTML__Tag__Index;
typedef myhtml_tag_index_node_t * HTML__MyHTML__Tag__Index__Node;
typedef myhtml_collection_t * HTML__MyHTML__Collection;
typedef myhtml_string_t * HTML__MyHTML__String;
typedef myhtml_token_node_t * HTML__MyHTML__Token__Node;
typedef myhtml_incoming_buffer_t * HTML__Incoming__Buffer;

struct myhtml_perl_callback_ctx {
	SV* callback;
	SV* ctx;
}
typedef myhtml_perl_callback_ctx_t;

typedef myhtml_collection_t* (*myhtml_perl_get_attr_by_val_f)(myhtml_tree_t *tree, myhtml_collection_t* collection, myhtml_tree_node_t* node, bool case_insensitive,
                                    const char* key, size_t key_len, const char* value, size_t value_len, myhtml_status_t* status);

HV * sm_get_attr_info(myhtml_tree_attr_t* attr)
{
	HV* hash = newHV();
	
	size_t name_len, value_len;
	const char* attr_name = myhtml_attribute_key(attr, &name_len);
	const char* attr_value = myhtml_attribute_value(attr, &value_len);
	
	hv_store(hash, "key", 3, newSVpv(attr_name, name_len), 0);
	
	if(value_len) {
		hv_store(hash, "value", 5, newSVpv(attr_value, value_len), 0);
	}
	else {
		hv_store(hash, "value", 5, &PL_sv_undef, 0);
	}
	
	switch (myhtml_attribute_namespace(attr)) {
		case MyHTML_NAMESPACE_SVG:
			hv_store(hash, "namespace", 9, newSVpv("svg", 3), 0);
			break;
		case MyHTML_NAMESPACE_MATHML:
			hv_store(hash, "namespace", 9, newSVpv("math", 4), 0);
			break;
		case MyHTML_NAMESPACE_XLINK:
			hv_store(hash, "namespace", 9, newSVpv("xlink", 5), 0);
			break;
		case MyHTML_NAMESPACE_XML:
			hv_store(hash, "namespace", 9, newSVpv("xml", 3), 0);
			break;
		case MyHTML_NAMESPACE_XMLNS:
			hv_store(hash, "namespace", 9, newSVpv("xmlns", 5), 0);
			break;
		default:
			hv_store(hash, "namespace", 9, newSVpv("html", 4), 0);
			break;
	}
	
	return hash;
}

HV * sm_get_node_attr_info(myhtml_tree_attr_t* attr)
{
	HV* hash = newHV();
	
    while(attr)
    {
		size_t name_len, value_len;
		const char* attr_name = myhtml_attribute_key(attr, &name_len);
		const char* attr_value = myhtml_attribute_value(attr, &value_len);
		
		if(value_len) {
			hv_store(hash, attr_name, name_len, newSVpv(attr_value, value_len), 0);
		}
		else {
			hv_store(hash, attr_name, name_len, &PL_sv_undef, 0);
		}
		
		//switch (myhtml_attribute_namespace(attr)) {
		//	case MyHTML_NAMESPACE_SVG:
		//		fprintf(out, ":svg");
		//		hv_store(hash, "namespace", 9, newSVpv("svg", 3), 0);
		//		break;
		//	case MyHTML_NAMESPACE_MATHML:
		//		fprintf(out, ":math");
		//		break;
		//	case MyHTML_NAMESPACE_XLINK:
		//		fprintf(out, ":xlink");
		//		break;
		//	case MyHTML_NAMESPACE_XML:
		//		fprintf(out, ":xml");
		//		break;
		//	case MyHTML_NAMESPACE_XMLNS:
		//		fprintf(out, ":xmlns");
		//		break;
		//	default:
		//		fprintf(out, ":UNDEF");
		//		break;
		//}
		
        attr = myhtml_attribute_next(attr);
    }
	
	return hash;
}

HV * sm_get_node_info(myhtml_tree_t *tree, myhtml_tree_node_t *node)
{
	HV* hash = newHV();
	SV **ha;
	
	size_t length;
	const char* tag_name = myhtml_tag_name_by_id(tree, myhtml_node_tag_id(node), &length);
	
	myhtml_position_t element_pos = myhtml_node_element_pasition(node);
	myhtml_position_t raw_pos = myhtml_node_raw_pasition(node);
	
	ha = hv_store(hash, "tag", 3, newSVpv(tag_name, length), 0);
	ha = hv_store(hash, "tag_id", 6, newSViv(myhtml_node_tag_id(node)), 0);
	
	ha = hv_store(hash, "element_begin", 13, newSViv(element_pos.begin), 0);
	ha = hv_store(hash, "element_length", 14, newSViv(element_pos.length), 0);
	
	ha = hv_store(hash, "raw_begin", 9, newSViv(raw_pos.begin), 0);
	ha = hv_store(hash, "raw_length", 10, newSViv(raw_pos.length), 0);
	
	switch (myhtml_node_namespace(node))
	{
		case MyHTML_NAMESPACE_SVG:
			hv_store(hash, "namespace", 9, newSVpv("svg", 3), 0);
			break;
		case MyHTML_NAMESPACE_MATHML:
			hv_store(hash, "namespace", 9, newSVpv("math", 4), 0);
			break;
		default:
			hv_store(hash, "namespace", 9, newSVpv("html", 4), 0);
			break;
	}
	
	hv_store(hash, "namespace_id", 12, newSViv(myhtml_node_namespace(node)), 0);
	
	hv_store(hash, "attr", 4, newRV_noinc((SV *)sm_get_node_attr_info( myhtml_node_attribute_first(node) )), 0);
	
	return hash;
}

HV * sm_get_token_node_info(myhtml_tree_t *tree, myhtml_token_node_t *token_node)
{
	HV* hash = newHV();
	SV **ha;
	
	size_t length;
	const char* tag_name = myhtml_tag_name_by_id(tree, myhtml_token_node_tag_id(token_node), &length);
	
	myhtml_position_t element_pos = myhtml_token_node_element_pasition(token_node);
	myhtml_position_t raw_pos = myhtml_token_node_raw_pasition(token_node);
	
	ha = hv_store(hash, "tag", 3, newSVpv(tag_name, length), 0);
	ha = hv_store(hash, "tag_id", 6, newSViv(myhtml_token_node_tag_id(token_node)), 0);
	
	ha = hv_store(hash, "element_begin", 13, newSViv(element_pos.begin), 0);
	ha = hv_store(hash, "element_length", 14, newSViv(element_pos.length), 0);
	
	ha = hv_store(hash, "raw_begin", 9, newSViv(raw_pos.begin), 0);
	ha = hv_store(hash, "raw_length", 10, newSViv(raw_pos.length), 0);
	
	hv_store(hash, "attr", 4, newRV_noinc((SV *)sm_get_node_attr_info( myhtml_token_node_attribute_first(token_node) )), 0);
	
	return hash;
}

AV * sm_get_elements_by_tag_id(myhtml_tree_t *tree, myhtml_tag_id_t tag_id)
{
	AV* array_list = newAV();
	
	myhtml_tag_index_t* tag_index = myhtml_tree_get_tag_index(tree);
	myhtml_tag_index_node_t* index_node = myhtml_tag_index_first(tag_index, tag_id);
	
	while (index_node) {
		SV* node = newSV(0);
		sv_setref_pv(node, "HTML::MyHTML::Tree::Node", myhtml_tag_index_tree_node(index_node));
		
		av_push(array_list, node);
		
		index_node = myhtml_tag_index_next(index_node);
	}
	
	return array_list;
}

AV * sm_get_elements_by_collections(myhtml_collection_t* collection)
{
	AV* array_list = newAV();
	
	for(size_t i = 0; i < collection->length; i++) {
		SV* node = newSV(0);
		sv_setref_pv(node, "HTML::MyHTML::Tree::Node", collection->list[i]);
		
		av_push(array_list, node);
	}
	
	return array_list;
}

void sm_set_out_status(SV* out_status, myhtml_status_t status)
{
	if(SvOK(out_status)) {
		sv_setiv(out_status, status);
	}
}

SV* sm_get_nodes_by_attribute_value(myhtml_tree_node_t* node, myhtml_tree_t* tree, SV* case_insensitive, SV* key, SV* value, SV* out_status, myhtml_perl_get_attr_by_val_f func_get)
{
	STRLEN key_len;
	STRLEN value_len;
	
	const char *char_key = NULL;
	const char *char_value = NULL;
	
	if(SvOK(key)) {
		char_key = SvPV(key, key_len);
	}
	
	if(SvOK(value)) {
		char_value = SvPV(value, value_len);
	}
	
	myhtml_status_t status;
	myhtml_collection_t *collection = func_get(tree, NULL, node, SvIV(case_insensitive),
								char_key, key_len, char_value, value_len, &status);
	
	sm_set_out_status(out_status, status);
	
	if(status == MyHTML_STATUS_OK) {
		return newRV_noinc((SV *)sm_get_elements_by_collections(collection));
	}
	
	return &PL_sv_undef;
}

void * myhtml_perl_callback_token_done(myhtml_tree_t* tree, myhtml_token_node_t* token, void* ctx)
{
	myhtml_perl_callback_ctx_t *perl_ctx = (myhtml_perl_callback_ctx_t *)ctx;
	
	{
		dSP;
		
		ENTER;
		SAVETMPS;
		
		SV *perl_tree = sv_newmortal();
		sv_setref_pv(perl_tree, "HTML::MyHTML::Tree", (void*)tree);
		
		SV *perl_token = sv_newmortal();
		sv_setref_pv(perl_token, "HTML::MyHTML::Token::Node", (void*)token);
		
		PUSHMARK(sp);
			XPUSHs(perl_tree);
			XPUSHs(perl_token);
			
			if(perl_ctx->ctx) {
				XPUSHs(perl_ctx->ctx);
			}
		PUTBACK;
		
		call_sv((SV *)perl_ctx->callback, G_SCALAR);
		
		FREETMPS;
		LEAVE;
	}
	
	return ctx;
}

void myhtml_perl_callback_node(myhtml_tree_t* tree, myhtml_tree_node_t* node, void* ctx)
{
	myhtml_perl_callback_ctx_t *perl_ctx = (myhtml_perl_callback_ctx_t *)ctx;
	
	{
		dSP;
		
		ENTER;
		SAVETMPS;
		
		SV *perl_tree = sv_newmortal();
		sv_setref_pv(perl_tree, "HTML::MyHTML::Tree", (void*)tree);
		
		SV *perl_node = sv_newmortal();
		sv_setref_pv(perl_node, "HTML::MyHTML::Tree::Node", (void*)node);
		
		PUSHMARK(sp);
			XPUSHs(perl_tree);
			XPUSHs(perl_node);
			
			if(perl_ctx->ctx) {
				XPUSHs(perl_ctx->ctx);
			}
		PUTBACK;
		
		call_sv((SV *)perl_ctx->callback, G_SCALAR);
		
		FREETMPS;
		LEAVE;
	}
}

//####
//#
//# Simple api
//#
//####

MODULE = HTML::MyHTML  PACKAGE = HTML::MyHTML
PROTOTYPES: DISABLE

HTML::MyHTML
new(class_name, opt, thread_count, out_status = &PL_sv_undef)
	char* class_name;
	enum myhtml_options opt;
	size_t thread_count;
	SV* out_status;
	
	CODE:
		myhtml_t *myhtml = myhtml_create();
		
		if(myhtml) {
			myhtml_status_t status = myhtml_init(myhtml, opt, thread_count, 0);
			sm_set_out_status(out_status, status);
			
			if(status == MyHTML_STATUS_OK) {
				RETVAL = myhtml;
			}
			else {
				RETVAL = NULL;
			}
		}
		else {
			sm_set_out_status(out_status, MyHTML_STATUS_ERROR_MEMORY_ALLOCATION);
			RETVAL = NULL;
		}
		
	OUTPUT:
		RETVAL
	POSTCALL:
	  if(RETVAL == NULL)
		XSRETURN_UNDEF;

HTML::MyHTML::Tree
new_tree(myhtml, out_status = &PL_sv_undef)
	HTML::MyHTML myhtml;
	SV* out_status;
	
	CODE:
		myhtml_tree_t *tree = myhtml_tree_create();
		
		if(tree) {
			myhtml_status_t status = myhtml_tree_init(tree, myhtml);
			sm_set_out_status(out_status, status);
			
			if(status == MyHTML_STATUS_OK) {
				RETVAL = tree;
			}
			else {
				RETVAL = NULL;
			}
		}
		else {
			sm_set_out_status(out_status, MyHTML_STATUS_ERROR_MEMORY_ALLOCATION);
			RETVAL = NULL;
		}
		
	OUTPUT:
		RETVAL
	POSTCALL:
	  if(RETVAL == NULL)
		XSRETURN_UNDEF;

####
#
# Includes
#
####
INCLUDE: xs/tree.xs
INCLUDE: xs/tree_node.xs
INCLUDE: xs/tree_attr.xs
INCLUDE: xs/token_node.xs
INCLUDE: xs/incoming_buffer.xs

####
#
# Base api
#
####

#************************************************************************************
#
# MyHTML
#
#************************************************************************************

MODULE = HTML::MyHTML  PACKAGE = HTML::MyHTML
PROTOTYPES: DISABLE

HTML::MyHTML
create(class_name)
	char* class_name;
	
	CODE:
		RETVAL = myhtml_create();
	OUTPUT:
		RETVAL

myhtml_status_t
init(myhtml, opt, thread_count, queue_size)
	HTML::MyHTML myhtml;
	enum myhtml_options opt;
	size_t thread_count;
	size_t queue_size;
	
	CODE:
		RETVAL = myhtml_init(myhtml, opt, thread_count, queue_size);
	OUTPUT:
		RETVAL

void
clean(myhtml)
	HTML::MyHTML myhtml;
	
	CODE:
		myhtml_clean(myhtml);

void
DESTROY(myhtml)
	HTML::MyHTML myhtml;
	
	CODE:
		if(myhtml)
			myhtml_destroy(myhtml);

myhtml_status_t
parse(myhtml, tree, encoding, html)
	HTML::MyHTML myhtml;
	HTML::MyHTML::Tree tree;
	myhtml_encoding_t encoding;
	SV* html;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_html = SvPV(html, len);
		RETVAL = myhtml_parse(tree, encoding, char_html, len);
	OUTPUT:
		RETVAL

myhtml_status_t
parse_fragment(myhtml, tree, encoding, html, tag_id, my_namespace)
	HTML::MyHTML myhtml;
	HTML::MyHTML::Tree tree;
	myhtml_encoding_t encoding;
	SV* html;
	myhtml_tag_id_t tag_id;
	enum myhtml_namespace my_namespace;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_html = SvPV(html, len);
		RETVAL = myhtml_parse_fragment(tree, encoding, char_html, len, tag_id, my_namespace);
	OUTPUT:
		RETVAL

myhtml_status_t
parse_single(myhtml, tree, encoding, html)
	HTML::MyHTML myhtml;
	HTML::MyHTML::Tree tree;
	myhtml_encoding_t encoding;
	SV* html;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_html = SvPV(html, len);
		RETVAL = myhtml_parse_single(tree, encoding, char_html, len);
	OUTPUT:
		RETVAL

myhtml_status_t
parse_fragment_single(myhtml, tree, encoding, html, tag_id, my_namespace)
	HTML::MyHTML myhtml;
	HTML::MyHTML::Tree tree;
	myhtml_encoding_t encoding;
	SV* html;
	myhtml_tag_id_t tag_id;
	enum myhtml_namespace my_namespace;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_html = SvPV(html, len);
		RETVAL = myhtml_parse_fragment_single(tree, encoding, char_html, len, tag_id, my_namespace);
	OUTPUT:
		RETVAL

myhtml_status_t
parse_chunk(myhtml, tree, html)
	HTML::MyHTML myhtml;
	HTML::MyHTML::Tree tree;
	SV* html;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_html = SvPV(html, len);
		RETVAL = myhtml_parse_chunk(tree, char_html, len);
	OUTPUT:
		RETVAL

myhtml_status_t
parse_chunk_fragment(myhtml, tree, html, tag_id, my_namespace)
	HTML::MyHTML myhtml;
	HTML::MyHTML::Tree tree;
	SV* html;
	myhtml_tag_id_t tag_id;
	enum myhtml_namespace my_namespace;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_html = SvPV(html, len);
		RETVAL = myhtml_parse_chunk_fragment(tree, char_html, len, tag_id, my_namespace);
	OUTPUT:
		RETVAL

myhtml_status_t
parse_chunk_single(myhtml, tree, html)
	HTML::MyHTML myhtml;
	HTML::MyHTML::Tree tree;
	SV* html;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_html = SvPV(html, len);
		RETVAL = myhtml_parse_chunk_single(tree, char_html, len);
	OUTPUT:
		RETVAL

myhtml_status_t
parse_chunk_fragment_single(myhtml, tree, html, tag_id, my_namespace)
	HTML::MyHTML myhtml;
	HTML::MyHTML::Tree tree;
	SV* html;
	myhtml_tag_id_t tag_id;
	enum myhtml_namespace my_namespace;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_html = SvPV(html, len);
		RETVAL = myhtml_parse_chunk_fragment_single(tree, char_html, len, tag_id, my_namespace);
	OUTPUT:
		RETVAL

myhtml_status_t
parse_chunk_end(myhtml, tree)
	HTML::MyHTML myhtml;
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_parse_chunk_end(tree);
	OUTPUT:
		RETVAL


#************************************************************************************
#
# MyHTML_TREE
#
#************************************************************************************

HTML::MyHTML::Tree
tree_create(myhtml)
	HTML::MyHTML myhtml;
	
	CODE:
		RETVAL = myhtml_tree_create();
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tree  PACKAGE = HTML::MyHTML::Tree
PROTOTYPES: DISABLE

myhtml_status_t
tree_init(tree, myhtml)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML myhtml;
	
	CODE:
		RETVAL = myhtml_tree_init(tree, myhtml);
	OUTPUT:
		RETVAL

void
tree_clean(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		myhtml_tree_clean(tree);

void
tree_node_add_child(tree, root, node)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node root;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		myhtml_tree_node_add_child(tree, root, node);

void
tree_node_insert_before(tree, root, node)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node root;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		myhtml_tree_node_insert_before(tree, root, node);

void
tree_node_insert_after(tree, root, node)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node root;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		myhtml_tree_node_insert_after(tree, root, node);

HTML::MyHTML::Tree
tree_destroy(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		if(tree) {
			if(tree->callback_before_token_ctx)
				free(tree->callback_before_token_ctx);
			
			if(tree->callback_after_token_ctx)
				free(tree->callback_after_token_ctx);
			
			if(tree->callback_tree_node_insert_ctx)
				free(tree->callback_tree_node_insert_ctx);
			
			if(tree->callback_tree_node_remove_ctx)
				free(tree->callback_tree_node_remove_ctx);
		}
		
		RETVAL = myhtml_tree_destroy(tree);
	OUTPUT:
		RETVAL

myhtml_t*
tree_get_myhtml(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_myhtml(tree);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tag
tree_get_tag(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_tag(tree);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tag::Index
tree_get_tag_index(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_tag_index(tree);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
tree_get_document(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_document(tree);
	OUTPUT:
		RETVAL

mchar_async_t*
tree_get_mchar(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_mchar(tree);
	OUTPUT:
		RETVAL

size_t
tree_get_mchar_node_id(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_tree_get_mchar_node_id(tree);
	OUTPUT:
		RETVAL

void
tree_print_by_node(tree, node, fh, inc)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node node;
	FILE* fh;
	size_t inc;
	
	CODE:
		myhtml_tree_print_by_node(tree, node, fh, inc);

void
tree_print_node_childs(tree, node, fh, inc)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node node;
	FILE* fh;
	size_t inc;
	
	CODE:
		myhtml_tree_print_node_children(tree, node, fh, inc);

void
tree_print_node(tree, node, fh)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node node;
	FILE* fh;
	
	CODE:
		myhtml_tree_print_node(tree, node, fh);

void
callback_before_token_done_set(tree, callback, ctx = &PL_sv_undef)
	HTML::MyHTML::Tree tree;
	SV* callback;
	SV* ctx;
	
	CODE:
		if(SvOK(callback)) {
			myhtml_perl_callback_ctx_t *perl_ctx;
			
			if(tree->callback_before_token_ctx) {
				perl_ctx = (myhtml_perl_callback_ctx_t*)tree->callback_before_token_ctx;
			}
			else {
				perl_ctx = (myhtml_perl_callback_ctx_t*)calloc(1, sizeof(myhtml_perl_callback_ctx_t));
			}
			
			setbuf(stdout, NULL);
			
			if(perl_ctx)
			{
				perl_ctx->callback = newSVsv(callback);
				perl_ctx->ctx = newSVsv(ctx);
				
				tree->callback_before_token = myhtml_perl_callback_token_done;
				tree->callback_before_token_ctx = perl_ctx;
			}
		}
		else {
			if(tree->callback_before_token_ctx)
				free(tree->callback_before_token_ctx);
			
			tree->callback_before_token = NULL;
			tree->callback_before_token_ctx = NULL;
		}

void
callback_after_token_done_set(tree, callback, ctx = &PL_sv_undef)
	HTML::MyHTML::Tree tree;
	SV* callback;
	SV* ctx;
	
	CODE:
		if(SvOK(callback)) {
			myhtml_perl_callback_ctx_t *perl_ctx;
			
			if(tree->callback_after_token_ctx) {
				perl_ctx = (myhtml_perl_callback_ctx_t*)tree->callback_after_token_ctx;
			}
			else {
				perl_ctx = (myhtml_perl_callback_ctx_t*)calloc(1, sizeof(myhtml_perl_callback_ctx_t));
			}
			
			if(perl_ctx)
			{
				perl_ctx->callback = newSVsv(callback);
				perl_ctx->ctx = newSVsv(ctx);
				
				tree->callback_after_token = myhtml_perl_callback_token_done;
				tree->callback_after_token_ctx = perl_ctx;
			}
		}
		else {
			if(tree->callback_after_token_ctx)
				free(tree->callback_after_token_ctx);
			
			tree->callback_after_token = NULL;
			tree->callback_after_token_ctx = NULL;
		}

void
callback_node_insert_set(tree, callback, ctx = &PL_sv_undef)
	HTML::MyHTML::Tree tree;
	SV* callback;
	SV* ctx;
	
	CODE:
		if(SvOK(callback)) {
			myhtml_perl_callback_ctx_t *perl_ctx;
			
			if(tree->callback_tree_node_insert_ctx) {
				perl_ctx = (myhtml_perl_callback_ctx_t*)tree->callback_tree_node_insert_ctx;
			}
			else {
				perl_ctx = (myhtml_perl_callback_ctx_t*)calloc(1, sizeof(myhtml_perl_callback_ctx_t));
			}
			
			if(perl_ctx)
			{
				perl_ctx->callback = newSVsv(callback);
				perl_ctx->ctx = newSVsv(ctx);
				
				tree->callback_tree_node_insert = myhtml_perl_callback_node;
				tree->callback_tree_node_insert_ctx = perl_ctx;
			}
		}
		else {
			if(tree->callback_tree_node_insert_ctx)
				free(tree->callback_tree_node_insert_ctx);
			
			tree->callback_tree_node_insert = NULL;
			tree->callback_tree_node_insert_ctx = NULL;
		}

void
callback_node_remove_set(tree, callback, ctx = &PL_sv_undef)
	HTML::MyHTML::Tree tree;
	SV* callback;
	SV* ctx;
	
	CODE:
		if(SvOK(callback)) {
			myhtml_perl_callback_ctx_t *perl_ctx;
			
			if(tree->callback_tree_node_remove_ctx) {
				perl_ctx = (myhtml_perl_callback_ctx_t*)tree->callback_tree_node_remove_ctx;
			}
			else {
				perl_ctx = (myhtml_perl_callback_ctx_t*)calloc(1, sizeof(myhtml_perl_callback_ctx_t));
			}
			
			if(perl_ctx)
			{
				perl_ctx->callback = newSVsv(callback);
				perl_ctx->ctx = newSVsv(ctx);
				
				tree->callback_tree_node_remove = myhtml_perl_callback_node;
				tree->callback_tree_node_remove_ctx = perl_ctx;
			}
		}
		else {
			if(tree->callback_tree_node_remove_ctx)
				free(tree->callback_tree_node_remove_ctx);
			
			tree->callback_tree_node_remove = NULL;
			tree->callback_tree_node_remove_ctx = NULL;
		}


#************************************************************************************
#
# MyHTML_NODE
#
#************************************************************************************

HTML::MyHTML::Tree::Node
node_first(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_node_first(tree);
	OUTPUT:
		RETVAL

HTML::MyHTML::Collection
get_nodes_by_tag_id(tree, collection, tag_id, out_status)
	HTML::MyHTML::Tree tree;
	myhtml_collection_t *collection;
	myhtml_tag_id_t tag_id;
	SV *out_status;
	
	CODE:
		myhtml_status_t status;
		RETVAL = myhtml_get_nodes_by_tag_id(tree, collection, tag_id, &status);
		sv_setiv(out_status, status);
	OUTPUT:
		RETVAL

HTML::MyHTML::Collection
get_nodes_by_name(tree, collection, tag_name, out_status)
	HTML::MyHTML::Tree tree;
	myhtml_collection_t *collection;
	SV* tag_name;
	SV* out_status;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_tag_name = SvPV(tag_name, len);
		myhtml_status_t status;
		
		RETVAL = myhtml_get_nodes_by_name(tree, collection, char_tag_name, len, &status);
		
		sv_setiv(out_status, status);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tree::Node  PACKAGE = HTML::MyHTML::Tree::Node
PROTOTYPES: DISABLE

HTML::MyHTML::Tree::Node
node_next(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_next(node);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
node_prev(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_prev(node);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
node_parent(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_parent(node);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
node_child(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_child(node);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
node_last_child(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_last_child(node);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tree  PACKAGE = HTML::MyHTML::Tree
PROTOTYPES: DISABLE

HTML::MyHTML::Tree::Node
node_create(tree, tag_id, my_namespace)
	HTML::MyHTML::Tree tree;
	myhtml_tag_id_t tag_id;
	enum myhtml_namespace my_namespace;
	
	CODE:
		RETVAL = myhtml_node_create(tree, tag_id, my_namespace);
	OUTPUT:
		RETVAL

void
node_free(tree, node)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		myhtml_node_free(tree, node);

MODULE = HTML::MyHTML::Tree::Node  PACKAGE = HTML::MyHTML::Tree::Node
PROTOTYPES: DISABLE

HTML::MyHTML::Tree::Node
node_remove(tree, node)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_remove(tree, node);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tree  PACKAGE = HTML::MyHTML::Tree
PROTOTYPES: DISABLE

void
node_delete(tree, node)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		myhtml_node_delete(tree, node);

void
node_delete_recursive(tree, node)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		myhtml_node_delete_recursive(tree, node);

HTML::MyHTML::Tree::Node
node_insert_to_appropriate_place(tree, target, node)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node target;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_insert_to_appropriate_place(tree, target, node);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
node_insert_append_child(tree, target, node)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node target;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_append_child(tree, target, node);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
node_insert_after(tree, target, node)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node target;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_insert_after(tree, target, node);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
node_insert_before(tree, target, node)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node target;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_insert_before(tree, target, node);
	OUTPUT:
		RETVAL

HTML::MyHTML::String
node_text_set(tree, node, text, encoding)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node node;
	SV* text;
	myhtml_encoding_t encoding;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_text = SvPV(text, len);
		RETVAL = myhtml_node_text_set(tree, node, char_text, len, encoding);
	OUTPUT:
		RETVAL

HTML::MyHTML::String
node_text_set_with_charef(tree, node, text, encoding)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node node;
	SV* text;
	myhtml_encoding_t encoding;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_text = SvPV(text, len);
		RETVAL = myhtml_node_text_set_with_charef(tree, node, char_text, len, encoding);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tree::Node  PACKAGE = HTML::MyHTML::Tree::Node
PROTOTYPES: DISABLE

enum myhtml_namespace
node_namespace(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_namespace(node);
	OUTPUT:
		RETVAL

myhtml_tag_id_t
node_tag_id(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_tag_id(node);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tree  PACKAGE = HTML::MyHTML::Tree
PROTOTYPES: DISABLE

SV*
tag_name_by_id(tree, tag_id)
	HTML::MyHTML::Tree tree;
	myhtml_tag_id_t tag_id;
	
	CODE:
		size_t length;
		const char* name = myhtml_tag_name_by_id(tree, tag_id, &length);
		RETVAL = newSVpv(name, length);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tree::Node  PACKAGE = HTML::MyHTML::Tree::Node
PROTOTYPES: DISABLE

bool
node_is_close_self(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_is_close_self(node);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Attr
node_attribute_first(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_attribute_first(node);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Attr
node_attribute_last(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_attribute_last(node);
	OUTPUT:
		RETVAL

SV*
node_text(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		size_t length;
		const char* text = myhtml_node_text(node, &length);
		RETVAL = newSVpv(text, length);
	OUTPUT:
		RETVAL

HTML::MyHTML::String
node_string(node)
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_node_string(node);
	OUTPUT:
		RETVAL

#************************************************************************************
#
# MyHTML_ATTRIBUTE
#
#************************************************************************************

MODULE = HTML::MyHTML::Tree::Attr  PACKAGE = HTML::MyHTML::Tree::Attr
PROTOTYPES: DISABLE

HTML::MyHTML::Tree::Attr
attribute_next(attr)
	HTML::MyHTML::Tree::Attr attr;
	
	CODE:
		RETVAL = myhtml_attribute_next(attr);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Attr
attribute_prev(attr)
	HTML::MyHTML::Tree::Attr attr;
	
	CODE:
		RETVAL = myhtml_attribute_prev(attr);
	OUTPUT:
		RETVAL

enum myhtml_namespace
attribute_namespace(attr)
	HTML::MyHTML::Tree::Attr attr;
	
	CODE:
		RETVAL = myhtml_attribute_namespace(attr);
	OUTPUT:
		RETVAL

SV*
attribute_name(attr)
	HTML::MyHTML::Tree::Attr attr;
	
	CODE:
		size_t length;
		const char* name = myhtml_attribute_key(attr, &length);
		RETVAL = newSVpv(name, length);
	OUTPUT:
		RETVAL

SV*
attribute_value(attr)
	HTML::MyHTML::Tree::Attr attr;
	
	CODE:
		size_t length;
		const char* value = myhtml_attribute_value(attr, &length);
		RETVAL = newSVpv(value, length);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tree::Node  PACKAGE = HTML::MyHTML::Tree::Node
PROTOTYPES: DISABLE

HTML::MyHTML::Tree::Attr
attribute_by_key(node, key)
	myhtml_tree_node_t *node;
	SV* key;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_key = SvPV(key, len);
		RETVAL = myhtml_attribute_by_key(node, char_key, len);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tree  PACKAGE = HTML::MyHTML::Tree
PROTOTYPES: DISABLE

HTML::MyHTML::Tree::Attr
attribute_add(tree, node, key, value, encoding)
	HTML::MyHTML::Tree tree;
	HTML::MyHTML::Tree::Node node;
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

MODULE = HTML::MyHTML::Tree::Node  PACKAGE = HTML::MyHTML::Tree::Node
PROTOTYPES: DISABLE

HTML::MyHTML::Tree::Attr
attribute_remove(node, attr)
	myhtml_tree_node_t *node;
	myhtml_tree_attr_t *attr;
	
	CODE:
		RETVAL = myhtml_attribute_remove(node, attr);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Attr
attribute_remove_by_key(node, key)
	myhtml_tree_node_t *node;
	SV* key;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_key = SvPV(key, len);
		RETVAL = myhtml_attribute_remove_by_key(node, char_key, len);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tree  PACKAGE = HTML::MyHTML::Tree
PROTOTYPES: DISABLE

void
attribute_delete(tree, node, attr)
	myhtml_tree_t *tree;
	myhtml_tree_node_t *node;
	myhtml_tree_attr_t *attr;
	
	CODE:
		myhtml_attribute_delete(tree, node, attr);

void
attribute_free(tree, attr)
	myhtml_tree_t *tree;
	myhtml_tree_attr_t *attr;
	
	CODE:
		myhtml_attribute_free(tree, attr);

#************************************************************************************
#
# MyHTML_TAG_INDEX
#
#************************************************************************************

MODULE = HTML::MyHTML::Tag  PACKAGE = HTML::MyHTML::Tag
PROTOTYPES: DISABLE

HTML::MyHTML::Tag::Index
tag_index_create(void)
	
	CODE:
		RETVAL = myhtml_tag_index_create();
	OUTPUT:
		RETVAL

myhtml_status_t
tag_index_init(tag, tag_index)
	HTML::MyHTML::Tag tag;
	HTML::MyHTML::Tag::Index tag_index;
	
	CODE:
		RETVAL = myhtml_tag_index_init(tag, tag_index);
	OUTPUT:
		RETVAL

void
tag_index_clean(tag, tag_index)
	HTML::MyHTML::Tag tag;
	HTML::MyHTML::Tag::Index tag_index;
	
	CODE:
		myhtml_tag_index_clean(tag, tag_index);

HTML::MyHTML::Tag::Index
tag_index_destroy(tag, tag_index)
	HTML::MyHTML::Tag tag;
	HTML::MyHTML::Tag::Index tag_index;
	
	CODE:
		RETVAL = myhtml_tag_index_destroy(tag, tag_index);
	OUTPUT:
		RETVAL

myhtml_status_t
tag_index_add(tag, tag_index, node)
	HTML::MyHTML::Tag tag;
	HTML::MyHTML::Tag::Index tag_index;
	HTML::MyHTML::Tree::Node node;
	
	CODE:
		RETVAL = myhtml_tag_index_add(tag, tag_index, node);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tag::Index  PACKAGE = HTML::MyHTML::Tag::Index
PROTOTYPES: DISABLE

myhtml_tag_index_entry_t*
tag_index_entry(tag_index, tag_id)
	HTML::MyHTML::Tag::Index tag_index;
	myhtml_tag_id_t tag_id;
	
	CODE:
		RETVAL = myhtml_tag_index_entry(tag_index, tag_id);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tag::Index::Node
tag_index_first(tag_index, tag_id)
	HTML::MyHTML::Tag::Index tag_index;
	myhtml_tag_id_t tag_id;
	
	CODE:
		RETVAL = myhtml_tag_index_first(tag_index, tag_id);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tag::Index::Node
tag_index_last(tag_index, tag_id)
	HTML::MyHTML::Tag::Index tag_index;
	myhtml_tag_id_t tag_id;
	
	CODE:
		RETVAL = myhtml_tag_index_last(tag_index, tag_id);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tag::Index::Node  PACKAGE = HTML::MyHTML::Tag::Index::Node
PROTOTYPES: DISABLE

HTML::MyHTML::Tag::Index::Node
tag_index_next(tag_index_node)
	HTML::MyHTML::Tag::Index::Node tag_index_node;
	
	CODE:
		RETVAL = myhtml_tag_index_next(tag_index_node);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tag::Index::Node
tag_index_prev(tag_index_node)
	HTML::MyHTML::Tag::Index::Node tag_index_node;
	
	CODE:
		RETVAL = myhtml_tag_index_prev(tag_index_node);
	OUTPUT:
		RETVAL

HTML::MyHTML::Tree::Node
tag_index_tree_node(index_node)
	myhtml_tag_index_node_t *index_node;
	
	CODE:
		RETVAL = myhtml_tag_index_tree_node(index_node);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Tag::Index  PACKAGE = HTML::MyHTML::Tag::Index
PROTOTYPES: DISABLE

size_t
tag_index_entry_count(tag_index, tag_id)
	HTML::MyHTML::Tag::Index tag_index;
	myhtml_tag_id_t tag_id;
	
	CODE:
		RETVAL = myhtml_tag_index_entry_count(tag_index, tag_id);
	OUTPUT:
		RETVAL

#************************************************************************************
#
# MyHTML_COLLECTION
#
#************************************************************************************

MODULE = HTML::MyHTML PACKAGE = HTML::MyHTML
PROTOTYPES: DISABLE

HTML::MyHTML::Collection
collection_create(myhtml, size, out_status)
	HTML::MyHTML myhtml;
	SV* size;
	SV* out_status;
	
	CODE:
		myhtml_status_t status;
		RETVAL = myhtml_collection_create(SvIV(size), &status);
		sv_setiv(out_status, status);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML::Collection PACKAGE = HTML::MyHTML::Collection
PROTOTYPES: DISABLE

void
collection_clen(collection)
	myhtml_collection_t *collection;
	
	CODE:
		myhtml_collection_clean(collection);

HTML::MyHTML::Collection
collection_destroy(collection)
	myhtml_collection_t *collection;
	
	CODE:
		RETVAL = myhtml_collection_destroy(collection);
	OUTPUT:
		RETVAL

myhtml_status_t
collection_check_size(collection, need, up_to_length)
	HTML::MyHTML::Collection collection;
	SV* need;
	SV* up_to_length;
	
	CODE:
		RETVAL = myhtml_collection_check_size(collection, SvIV(need), SvIV(up_to_length));
	OUTPUT:
		RETVAL

#************************************************************************************
#
# MyHTML_ENCODING
#
#************************************************************************************

MODULE = HTML::MyHTML::Tree  PACKAGE = HTML::MyHTML::Tree
PROTOTYPES: DISABLE

void
encoding_set(tree, encoding)
	HTML::MyHTML::Tree tree;
	myhtml_encoding_t encoding;
	
	CODE:
		myhtml_encoding_set(tree, encoding);

myhtml_encoding_t
encoding_get(tree)
	HTML::MyHTML::Tree tree;
	
	CODE:
		RETVAL = myhtml_encoding_get(tree);
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML  PACKAGE = HTML::MyHTML
PROTOTYPES: DISABLE

SV*
encoding_codepoint_to_ascii_utf_8(myhtml, codepoint)
	HTML::MyHTML myhtml;
	SV* codepoint;
	
	PREINIT:
		STRLEN len;
	CODE:
		SV* todata = newSVpv("\0\0\0\0", 4);
		char* char_todata = SvPV(todata, len);
		
		size_t len_of = myhtml_encoding_codepoint_to_ascii_utf_8(SvIV(codepoint), char_todata);
		sv_setpvn(todata, char_todata, len_of);
		
		RETVAL = todata;
	OUTPUT:
		RETVAL

SV*
encoding_codepoint_to_ascii_utf_16(myhtml, codepoint)
	HTML::MyHTML myhtml;
	SV* codepoint;
	
	PREINIT:
		STRLEN len;
	CODE:
		SV* todata = newSVpv("\0\0\0\0", 4);
		char* char_todata = SvPV(todata, len);
		
		size_t len_of = myhtml_encoding_codepoint_to_ascii_utf_16(SvIV(codepoint), char_todata);
		sv_setpvn(todata, char_todata, len_of);
		
		RETVAL = todata;
	OUTPUT:
		RETVAL

bool
encoding_detect(myhtml, text, out_encoding)
	HTML::MyHTML myhtml;
	SV* text;
	SV* out_encoding;
	
	PREINIT:
		STRLEN text_len;
	CODE:
		char* char_todata = SvPV(text, text_len);
		myhtml_encoding_t encoding;
		
		RETVAL = myhtml_encoding_detect(char_todata, text_len, &encoding);
		
		sv_setiv(out_encoding, encoding);
	OUTPUT:
		RETVAL

bool
encoding_detect_russian(myhtml, text, out_encoding)
	HTML::MyHTML myhtml;
	SV* text;
	SV* out_encoding;
	
	PREINIT:
		STRLEN text_len;
	CODE:
		char* char_todata = SvPV(text, text_len);
		myhtml_encoding_t encoding;
		
		RETVAL = myhtml_encoding_detect_russian(char_todata, text_len, &encoding);
		
		sv_setiv(out_encoding, encoding);
	OUTPUT:
		RETVAL

bool
encoding_detect_unicode(myhtml, text, out_encoding)
	HTML::MyHTML myhtml;
	SV* text;
	SV* out_encoding;
	
	PREINIT:
		STRLEN text_len;
	CODE:
		char* char_todata = SvPV(text, text_len);
		myhtml_encoding_t encoding;
		
		RETVAL = myhtml_encoding_detect_unicode(char_todata, text_len, &encoding);
		
		sv_setiv(out_encoding, encoding);
	OUTPUT:
		RETVAL

bool
encoding_detect_bom(myhtml, text, out_encoding)
	HTML::MyHTML myhtml;
	SV* text;
	SV* out_encoding;
	
	PREINIT:
		STRLEN text_len;
	CODE:
		char* char_todata = SvPV(text, text_len);
		myhtml_encoding_t encoding;
		
		RETVAL = myhtml_encoding_detect_bom(char_todata, text_len, &encoding);
		
		sv_setiv(out_encoding, encoding);
	OUTPUT:
		RETVAL

#************************************************************************************
#
# MyHTML_STRING
#
#************************************************************************************

MODULE = HTML::MyHTML::String  PACKAGE = HTML::MyHTML::String
PROTOTYPES: DISABLE

SV*
string_data(str)
	myhtml_string_t *str;
	
	CODE:
		char* char_str = myhtml_string_data(str);
		size_t len = myhtml_string_length(str);
		
		RETVAL = newSVpv(char_str, len);
	OUTPUT:
		RETVAL

SV*
string_length(str)
	myhtml_string_t *str;
	
	CODE:
		RETVAL = newSViv( myhtml_string_length(str) );
	OUTPUT:
		RETVAL

MODULE = HTML::MyHTML  PACKAGE = HTML::MyHTML
PROTOTYPES: DISABLE

#************************************************************************************
#
# MyHTML_NAMESPACE
#
#************************************************************************************

SV*
namespace_name_by_id(ns)
	SV* ns;
	
	CODE:
		size_t length = 0;
		const char *ns_name = myhtml_namespace_name_by_id(SvIV(ns), &length);
		
		if(ns_name == NULL || length == 0) {
			RETVAL = newSVpv("", 0);
		}
		else {
			RETVAL = newSVpv(ns_name, length);
		}
	OUTPUT:
		RETVAL

SV*
namespace_id_by_name(name)
	SV* name;
	
	PREINIT:
		STRLEN len;
	CODE:
		const char *char_name = NULL;
		myhtml_namespace_t ns = MyHTML_NAMESPACE_UNDEF;
		
		if(SvOK(name)) {
			char_name = SvPV(name, len);
			myhtml_namespace_id_by_name(char_name, len, &ns);
		}
		
		RETVAL = newSViv(ns);
	OUTPUT:
		RETVAL


#************************************************************************************
#
# MyHTML_PARSE_FLAGS constants
#
#************************************************************************************

SV*
MyHTML_TREE_PARSE_FLAGS_CLEAN()
	CODE:
		RETVAL = newSViv( MyHTML_TREE_PARSE_FLAGS_CLEAN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TREE_PARSE_FLAGS_WITHOUT_BUILD_TREE()
	CODE:
		RETVAL = newSViv( MyHTML_TREE_PARSE_FLAGS_WITHOUT_BUILD_TREE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TREE_PARSE_FLAGS_WITHOUT_PROCESS_TOKEN()
	CODE:
		RETVAL = newSViv( MyHTML_TREE_PARSE_FLAGS_WITHOUT_PROCESS_TOKEN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TREE_PARSE_FLAGS_SKIP_WHITESPACE_TOKEN()
	CODE:
		RETVAL = newSViv( MyHTML_TREE_PARSE_FLAGS_SKIP_WHITESPACE_TOKEN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TREE_PARSE_FLAGS_WITHOUT_DOCTYPE_IN_TREE()
	CODE:
		RETVAL = newSViv( MyHTML_TREE_PARSE_FLAGS_WITHOUT_DOCTYPE_IN_TREE );
	OUTPUT:
		RETVAL


#************************************************************************************
#
# MyHTML_STATUS constants
#
#************************************************************************************

SV*
MyHTML_STATUS_OK()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_OK );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_ERROR_MEMORY_ALLOCATION()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_ERROR_MEMORY_ALLOCATION );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_MEMORY_ALLOCATION()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_MEMORY_ALLOCATION );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_LIST_INIT()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_LIST_INIT );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_ATTR_MALLOC()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_ATTR_MALLOC );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_ATTR_INIT()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_ATTR_INIT );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_ATTR_SET()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_ATTR_SET );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_ATTR_DESTROY()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_ATTR_DESTROY );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_NO_SLOTS()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_NO_SLOTS );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_BATCH_INIT()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_BATCH_INIT );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_WORKER_MALLOC()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_WORKER_MALLOC );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_WORKER_SEM_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_WORKER_SEM_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_WORKER_THREAD_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_WORKER_THREAD_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_MASTER_THREAD_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_MASTER_THREAD_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_SEM_PREFIX_MALLOC()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_SEM_PREFIX_MALLOC );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_SEM_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_SEM_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_QUEUE_MALLOC()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_QUEUE_MALLOC );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_QUEUE_NODES_MALLOC()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_QUEUE_NODES_MALLOC );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_QUEUE_NODE_MALLOC()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_QUEUE_NODE_MALLOC );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_MUTEX_MALLOC()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_MUTEX_MALLOC );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_MUTEX_INIT()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_MUTEX_INIT );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_MUTEX_LOCK()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_MUTEX_LOCK );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_THREAD_ERROR_MUTEX_UNLOCK()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_THREAD_ERROR_MUTEX_UNLOCK );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_RULES_ERROR_MEMORY_ALLOCATION()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_RULES_ERROR_MEMORY_ALLOCATION );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_PERF_ERROR_COMPILED_WITHOUT_PERF()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_PERF_ERROR_COMPILED_WITHOUT_PERF );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_PERF_ERROR_FIND_CPU_CLOCK()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_PERF_ERROR_FIND_CPU_CLOCK );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TOKENIZER_ERROR_MEMORY_ALLOCATION()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TOKENIZER_ERROR_MEMORY_ALLOCATION );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TOKENIZER_ERROR_FRAGMENT_INIT()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TOKENIZER_ERROR_FRAGMENT_INIT );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TAGS_ERROR_MEMORY_ALLOCATION()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TAGS_ERROR_MEMORY_ALLOCATION );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TAGS_ERROR_MCOBJECT_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TAGS_ERROR_MCOBJECT_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TAGS_ERROR_MCOBJECT_MALLOC()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TAGS_ERROR_MCOBJECT_MALLOC );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TAGS_ERROR_MCOBJECT_CREATE_NODE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TAGS_ERROR_MCOBJECT_CREATE_NODE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TAGS_ERROR_CACHE_MEMORY_ALLOCATION()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TAGS_ERROR_CACHE_MEMORY_ALLOCATION );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TAGS_ERROR_INDEX_MEMORY_ALLOCATION()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TAGS_ERROR_INDEX_MEMORY_ALLOCATION );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TREE_ERROR_MEMORY_ALLOCATION()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TREE_ERROR_MEMORY_ALLOCATION );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TREE_ERROR_MCOBJECT_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TREE_ERROR_MCOBJECT_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TREE_ERROR_MCOBJECT_INIT()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TREE_ERROR_MCOBJECT_INIT );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TREE_ERROR_MCOBJECT_CREATE_NODE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TREE_ERROR_MCOBJECT_CREATE_NODE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_TREE_ERROR_INCOMING_BUFFER_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_TREE_ERROR_INCOMING_BUFFER_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_ATTR_ERROR_ALLOCATION()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_ATTR_ERROR_ALLOCATION );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_ATTR_ERROR_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_ATTR_ERROR_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_STREAM_BUFFER_ERROR_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_STREAM_BUFFER_ERROR_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_STREAM_BUFFER_ERROR_INIT()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_STREAM_BUFFER_ERROR_INIT );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_STREAM_BUFFER_ENTRY_ERROR_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_STREAM_BUFFER_ENTRY_ERROR_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_STREAM_BUFFER_ENTRY_ERROR_INIT()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_STREAM_BUFFER_ENTRY_ERROR_INIT );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_STREAM_BUFFER_ERROR_ADD_ENTRY()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_STREAM_BUFFER_ERROR_ADD_ENTRY );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_MCOBJECT_ERROR_CACHE_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_MCOBJECT_ERROR_CACHE_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_MCOBJECT_ERROR_CHUNK_CREATE()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_MCOBJECT_ERROR_CHUNK_CREATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_MCOBJECT_ERROR_CHUNK_INIT()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_MCOBJECT_ERROR_CHUNK_INIT );
	OUTPUT:
		RETVAL

SV*
MyHTML_STATUS_MCOBJECT_ERROR_CACHE_REALLOC()
	CODE:
		RETVAL = newSViv( MyHTML_STATUS_MCOBJECT_ERROR_CACHE_REALLOC );
	OUTPUT:
		RETVAL


#************************************************************************************
#
# MyHTML_OPTIONS constants
#
#************************************************************************************

SV*
MyHTML_OPTIONS_DEFAULT()
	CODE:
		RETVAL = newSViv( MyHTML_OPTIONS_DEFAULT );
	OUTPUT:
		RETVAL

SV*
MyHTML_OPTIONS_PARSE_MODE_SINGLE()
	CODE:
		RETVAL = newSViv( MyHTML_OPTIONS_PARSE_MODE_SINGLE );
	OUTPUT:
		RETVAL

SV*
MyHTML_OPTIONS_PARSE_MODE_ALL_IN_ONE()
	CODE:
		RETVAL = newSViv( MyHTML_OPTIONS_PARSE_MODE_ALL_IN_ONE );
	OUTPUT:
		RETVAL

SV*
MyHTML_OPTIONS_PARSE_MODE_SEPARATELY()
	CODE:
		RETVAL = newSViv( MyHTML_OPTIONS_PARSE_MODE_SEPARATELY );
	OUTPUT:
		RETVAL


#************************************************************************************
#
# MyHTML_NAMESPACE constants
#
#************************************************************************************

SV*
MyHTML_NAMESPACE_UNDEF()
	CODE:
		RETVAL = newSViv( MyHTML_NAMESPACE_UNDEF );
	OUTPUT:
		RETVAL

SV*
MyHTML_NAMESPACE_HTML()
	CODE:
		RETVAL = newSViv( MyHTML_NAMESPACE_HTML );
	OUTPUT:
		RETVAL

SV*
MyHTML_NAMESPACE_MATHML()
	CODE:
		RETVAL = newSViv( MyHTML_NAMESPACE_MATHML );
	OUTPUT:
		RETVAL

SV*
MyHTML_NAMESPACE_SVG()
	CODE:
		RETVAL = newSViv( MyHTML_NAMESPACE_SVG );
	OUTPUT:
		RETVAL

SV*
MyHTML_NAMESPACE_XLINK()
	CODE:
		RETVAL = newSViv( MyHTML_NAMESPACE_XLINK );
	OUTPUT:
		RETVAL

SV*
MyHTML_NAMESPACE_XML()
	CODE:
		RETVAL = newSViv( MyHTML_NAMESPACE_XML );
	OUTPUT:
		RETVAL

SV*
MyHTML_NAMESPACE_XMLNS()
	CODE:
		RETVAL = newSViv( MyHTML_NAMESPACE_XMLNS );
	OUTPUT:
		RETVAL

SV*
MyHTML_NAMESPACE_LAST_ENTRY()
	CODE:
		RETVAL = newSViv( MyHTML_NAMESPACE_LAST_ENTRY );
	OUTPUT:
		RETVAL

#************************************************************************************
#
# MyHTML_TAG constants
#
#************************************************************************************

SV*
MyHTML_TAG__UNDEF()
	CODE:
		RETVAL = newSViv( MyHTML_TAG__UNDEF );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG__TEXT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG__TEXT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG__COMMENT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG__COMMENT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG__DOCTYPE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG__DOCTYPE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_A()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_A );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ABBR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ABBR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ACRONYM()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ACRONYM );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ADDRESS()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ADDRESS );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ANNOTATION_XML()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ANNOTATION_XML );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_APPLET()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_APPLET );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_AREA()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_AREA );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ARTICLE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ARTICLE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ASIDE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ASIDE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_AUDIO()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_AUDIO );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_B()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_B );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_BASE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_BASE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_BASEFONT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_BASEFONT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_BDI()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_BDI );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_BDO()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_BDO );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_BGSOUND()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_BGSOUND );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_BIG()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_BIG );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_BLINK()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_BLINK );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_BLOCKQUOTE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_BLOCKQUOTE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_BODY()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_BODY );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_BR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_BR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_BUTTON()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_BUTTON );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_CANVAS()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_CANVAS );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_CAPTION()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_CAPTION );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_CENTER()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_CENTER );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_CITE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_CITE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_CODE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_CODE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_COL()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_COL );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_COLGROUP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_COLGROUP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_COMMAND()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_COMMAND );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_COMMENT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_COMMENT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DATALIST()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DATALIST );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DD()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DD );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DEL()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DEL );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DETAILS()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DETAILS );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DFN()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DFN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DIALOG()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DIALOG );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DIR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DIR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DIV()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DIV );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DL()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DL );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_EM()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_EM );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_EMBED()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_EMBED );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FIELDSET()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FIELDSET );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FIGCAPTION()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FIGCAPTION );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FIGURE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FIGURE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FONT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FONT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FOOTER()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FOOTER );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FORM()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FORM );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FRAME()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FRAME );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FRAMESET()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FRAMESET );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_H1()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_H1 );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_H2()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_H2 );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_H3()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_H3 );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_H4()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_H4 );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_H5()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_H5 );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_H6()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_H6 );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_HEAD()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_HEAD );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_HEADER()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_HEADER );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_HGROUP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_HGROUP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_HR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_HR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_HTML()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_HTML );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_I()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_I );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_IFRAME()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_IFRAME );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_IMAGE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_IMAGE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_IMG()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_IMG );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_INPUT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_INPUT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_INS()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_INS );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ISINDEX()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ISINDEX );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_KBD()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_KBD );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_KEYGEN()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_KEYGEN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_LABEL()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_LABEL );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_LEGEND()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_LEGEND );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_LI()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_LI );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_LINK()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_LINK );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_LISTING()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_LISTING );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MAIN()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MAIN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MAP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MAP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MARK()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MARK );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MARQUEE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MARQUEE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MENU()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MENU );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MENUITEM()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MENUITEM );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_META()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_META );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_METER()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_METER );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MTEXT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MTEXT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_NAV()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_NAV );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_NOBR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_NOBR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_NOEMBED()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_NOEMBED );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_NOFRAMES()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_NOFRAMES );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_NOSCRIPT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_NOSCRIPT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_OBJECT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_OBJECT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_OL()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_OL );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_OPTGROUP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_OPTGROUP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_OPTION()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_OPTION );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_OUTPUT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_OUTPUT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_P()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_P );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_PARAM()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_PARAM );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_PLAINTEXT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_PLAINTEXT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_PRE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_PRE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_PROGRESS()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_PROGRESS );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_Q()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_Q );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_RB()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_RB );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_RP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_RP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_RT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_RT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_RTC()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_RTC );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_RUBY()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_RUBY );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_S()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_S );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SAMP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SAMP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SCRIPT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SCRIPT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SECTION()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SECTION );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SELECT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SELECT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SMALL()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SMALL );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SOURCE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SOURCE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SPAN()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SPAN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_STRIKE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_STRIKE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_STRONG()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_STRONG );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_STYLE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_STYLE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SUB()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SUB );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SUMMARY()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SUMMARY );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SUP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SUP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SVG()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SVG );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TABLE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TABLE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TBODY()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TBODY );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TD()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TD );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TEMPLATE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TEMPLATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TEXTAREA()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TEXTAREA );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TFOOT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TFOOT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TH()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TH );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_THEAD()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_THEAD );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TIME()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TIME );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TITLE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TITLE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TRACK()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TRACK );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_U()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_U );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_UL()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_UL );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_VAR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_VAR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_VIDEO()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_VIDEO );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_WBR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_WBR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_XMP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_XMP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ALTGLYPH()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ALTGLYPH );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ALTGLYPHDEF()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ALTGLYPHDEF );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ALTGLYPHITEM()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ALTGLYPHITEM );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ANIMATE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ANIMATE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ANIMATECOLOR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ANIMATECOLOR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ANIMATEMOTION()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ANIMATEMOTION );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ANIMATETRANSFORM()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ANIMATETRANSFORM );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_CIRCLE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_CIRCLE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_CLIPPATH()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_CLIPPATH );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_COLOR_PROFILE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_COLOR_PROFILE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_CURSOR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_CURSOR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DEFS()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DEFS );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_DESC()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_DESC );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_ELLIPSE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_ELLIPSE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEBLEND()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEBLEND );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FECOLORMATRIX()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FECOLORMATRIX );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FECOMPONENTTRANSFER()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FECOMPONENTTRANSFER );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FECOMPOSITE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FECOMPOSITE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FECONVOLVEMATRIX()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FECONVOLVEMATRIX );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEDIFFUSELIGHTING()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEDIFFUSELIGHTING );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEDISPLACEMENTMAP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEDISPLACEMENTMAP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEDISTANTLIGHT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEDISTANTLIGHT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEDROPSHADOW()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEDROPSHADOW );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEFLOOD()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEFLOOD );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEFUNCA()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEFUNCA );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEFUNCB()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEFUNCB );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEFUNCG()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEFUNCG );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEFUNCR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEFUNCR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEGAUSSIANBLUR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEGAUSSIANBLUR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEIMAGE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEIMAGE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEMERGE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEMERGE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEMERGENODE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEMERGENODE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEMORPHOLOGY()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEMORPHOLOGY );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEOFFSET()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEOFFSET );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FEPOINTLIGHT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FEPOINTLIGHT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FESPECULARLIGHTING()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FESPECULARLIGHTING );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FESPOTLIGHT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FESPOTLIGHT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FETILE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FETILE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FETURBULENCE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FETURBULENCE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FILTER()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FILTER );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FONT_FACE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FONT_FACE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FONT_FACE_FORMAT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FONT_FACE_FORMAT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FONT_FACE_NAME()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FONT_FACE_NAME );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FONT_FACE_SRC()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FONT_FACE_SRC );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FONT_FACE_URI()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FONT_FACE_URI );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FOREIGNOBJECT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FOREIGNOBJECT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_G()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_G );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_GLYPH()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_GLYPH );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_GLYPHREF()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_GLYPHREF );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_HKERN()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_HKERN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_LINE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_LINE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_LINEARGRADIENT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_LINEARGRADIENT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MARKER()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MARKER );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MASK()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MASK );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_METADATA()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_METADATA );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MISSING_GLYPH()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MISSING_GLYPH );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MPATH()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MPATH );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_PATH()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_PATH );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_PATTERN()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_PATTERN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_POLYGON()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_POLYGON );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_POLYLINE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_POLYLINE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_RADIALGRADIENT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_RADIALGRADIENT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_RECT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_RECT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SET()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SET );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_STOP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_STOP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SWITCH()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SWITCH );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_SYMBOL()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_SYMBOL );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TEXT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TEXT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TEXTPATH()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TEXTPATH );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TREF()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TREF );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_TSPAN()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_TSPAN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_USE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_USE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_VIEW()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_VIEW );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_VKERN()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_VKERN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MATH()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MATH );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MACTION()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MACTION );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MALIGNGROUP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MALIGNGROUP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MALIGNMARK()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MALIGNMARK );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MENCLOSE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MENCLOSE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MERROR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MERROR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MFENCED()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MFENCED );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MFRAC()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MFRAC );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MGLYPH()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MGLYPH );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MI()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MI );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MLABELEDTR()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MLABELEDTR );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MLONGDIV()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MLONGDIV );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MMULTISCRIPTS()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MMULTISCRIPTS );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MN()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MN );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MO()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MO );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MOVER()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MOVER );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MPADDED()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MPADDED );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MPHANTOM()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MPHANTOM );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MROOT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MROOT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MROW()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MROW );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MS()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MS );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSCARRIES()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSCARRIES );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSCARRY()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSCARRY );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSGROUP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSGROUP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSLINE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSLINE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSPACE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSPACE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSQRT()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSQRT );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSROW()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSROW );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSTACK()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSTACK );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSTYLE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSTYLE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSUB()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSUB );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSUP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSUP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_MSUBSUP()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_MSUBSUP );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG__END_OF_FILE()
	CODE:
		RETVAL = newSViv( MyHTML_TAG__END_OF_FILE );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_FIRST_ENTRY()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_FIRST_ENTRY );
	OUTPUT:
		RETVAL

SV*
MyHTML_TAG_LAST_ENTRY()
	CODE:
		RETVAL = newSViv( MyHTML_TAG_LAST_ENTRY );
	OUTPUT:
		RETVAL

#************************************************************************************
#
# MyHTML constants
#
#************************************************************************************
SV*
MyHTML_ENCODING_DEFAULT()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_DEFAULT );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_UTF_8()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_UTF_8 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_UTF_16LE()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_UTF_16LE );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_UTF_16BE()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_UTF_16BE );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_X_USER_DEFINED()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_X_USER_DEFINED );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_BIG5()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_BIG5 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_EUC_KR()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_EUC_KR );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_GB18030()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_GB18030 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_IBM866()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_IBM866 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_10()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_10 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_13()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_13 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_14()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_14 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_15()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_15 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_16()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_16 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_2()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_2 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_3()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_3 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_4()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_4 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_5()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_5 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_6()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_6 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_7()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_7 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_8()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_8 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_KOI8_R()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_KOI8_R );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_KOI8_U()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_KOI8_U );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_MACINTOSH()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_MACINTOSH );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_WINDOWS_1250()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_WINDOWS_1250 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_WINDOWS_1251()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_WINDOWS_1251 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_WINDOWS_1252()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_WINDOWS_1252 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_WINDOWS_1253()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_WINDOWS_1253 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_WINDOWS_1254()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_WINDOWS_1254 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_WINDOWS_1255()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_WINDOWS_1255 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_WINDOWS_1256()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_WINDOWS_1256 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_WINDOWS_1257()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_WINDOWS_1257 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_WINDOWS_1258()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_WINDOWS_1258 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_WINDOWS_874()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_WINDOWS_874 );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_X_MAC_CYRILLIC()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_X_MAC_CYRILLIC );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_2022_JP()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_2022_JP );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_GBK()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_GBK );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_SHIFT_JIS()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_SHIFT_JIS );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_EUC_JP()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_EUC_JP );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_ISO_8859_8_I()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_ISO_8859_8_I );
	OUTPUT:
		RETVAL

SV*
MyHTML_ENCODING_LAST_ENTRY()
	CODE:
		RETVAL = newSViv( MyHTML_ENCODING_LAST_ENTRY );
	OUTPUT:
		RETVAL

