#ifndef HTML5_DOM_UTILS_H
#define HTML5_DOM_UTILS_H
#pragma once

// Portable utils for ports to other languages
// Contains only code who independent of perl 

#define MyENCODING_AUTO 1

#define node_is_element(node) (node->tag_id != MyHTML_TAG__UNDEF && node->tag_id != MyHTML_TAG__TEXT && node->tag_id != MyHTML_TAG__COMMENT && node->tag_id != MyHTML_TAG__DOCTYPE)
#define node_is_document(node) (!node->parent && node == node->tree->document)
#define node_is_root(node) (node->tree->node_html && node->tree->node_html == node)
#define html5_dom_is_fragment(node) (((html5_dom_tree_t *) node->tree->context)->fragment_tag_id && node->tag_id == ((html5_dom_tree_t *) node->tree->context)->fragment_tag_id)

#if (defined(_WIN32) || defined(_WIN64))
	#define MyCORE_OS_WINDOWS_NT
#endif

#include <stdio.h>
#include <ctype.h>

#ifdef MyCORE_OS_WINDOWS_NT
	// for _write
	#include <io.h>
#else
	// for write
	#include <unistd.h>
#endif

#include <modest/finder/finder.h>
#include <myhtml/myhtml.h>
#include <myhtml/serialization.h>
#include <mycss/mycss.h>
#include <mycss/selectors/init.h>
#include <mycss/selectors/serialization.h>

typedef struct {
	long threads;
	bool ignore_whitespace;
	bool ignore_doctype;
	bool scripts;
	myencoding_t encoding;
	myencoding_t default_encoding;
	bool encoding_use_meta;
	bool encoding_use_bom;
	long encoding_prescan_limit;
	int utf8; // 0 - off, 1 - on, 2 - auto (detect by input)
} html5_dom_options_t;

typedef struct {
	myhtml_t *myhtml;
	myhtml_tree_t *tree;
	mycss_t *mycss;
	mycss_entry_t *mycss_entry;
	modest_finder_t *finder;
	html5_dom_options_t opts; // base options
	html5_dom_options_t chunk_opts; // for parseChunk
	size_t chunks;
} html5_dom_parser_t;

typedef struct {
	void *parent;
	void *sv;
	myhtml_tree_t *tree;
	html5_dom_parser_t *parser;
	myhtml_tag_id_t fragment_tag_id;
	bool utf8;
	bool used;
} html5_dom_tree_t;

typedef struct {
	mycss_t *mycss;
	mycss_entry_t *entry;
	myencoding_t encoding;
	int utf8; // 0 - off, 1 - on, 2 - auto (detect by input)
	html5_dom_options_t opts;
} html5_css_parser_t;

typedef struct {
	html5_css_parser_t *parser;
	mycss_selectors_list_t *list;
	void *parent;
	bool utf8;
} html5_css_selector_t;

typedef struct {
	html5_css_selector_t *selector;
	mycss_selectors_entries_list_t *list;
	void *parent;
} html5_css_selector_entry_t;

typedef struct {
	mythread_t *thread;
	int fd;
	
	// output tree
	myhtml_tree_t *tree;
	html5_dom_parser_t *parser;
	void *tree_sv;
	
	// status
	mystatus_t status;
	bool done;
	
	// input html
	char *html;
	size_t length;
	
	html5_dom_options_t opts;
} html5_dom_async_result;

typedef struct {
	myhtml_tree_node_t *node_html;
	myhtml_tree_node_t *node_body;
	myhtml_tree_node_t *node_head;
	myhtml_tree_node_t *document;
} html5_fragment_parts_t;

typedef struct {
	bool new_line;
	bool last_br;
	mycore_string_t value;
} html5_dom_inner_text_state_t;

// https://developer.mozilla.org/pl/docs/Web/API/Element/nodeType
enum {
	ELEMENT_NODE					= 1, 
	ATTRIBUTE_NODE					= 2, 
	TEXT_NODE						= 3, 
	CDATA_SECTION_NODE				= 4, 
	ENTITY_REFERENCE_NODE			= 5, 
	ENTITY_NODE						= 6, 
	PROCESSING_INSTRUCTION_NODE		= 7, 
	COMMENT_NODE					= 8, 
	DOCUMENT_NODE					= 9, 
	DOCUMENT_TYPE_NODE				= 10, 
	DOCUMENT_FRAGMENT_NODE			= 11, 
	NOTATION_NODE					= 12
};

enum {
	TAG_UA_STYLE_NONE					= 0, 
	TAG_UA_STYLE_INLINE					= 1, 
	TAG_UA_STYLE_BLOCK					= 2, 
	TAG_UA_STYLE_INLINE_BLOCK			= 3, 
	TAG_UA_STYLE_LIST_ITEM				= 4, 
	TAG_UA_STYLE_TABLE					= 5, 
	TAG_UA_STYLE_TABLE_CAPTION			= 6, 
	TAG_UA_STYLE_TABLE_CELL				= 7, 
	TAG_UA_STYLE_TABLE_COLUMN			= 8, 
	TAG_UA_STYLE_TABLE_COLUMN_GROUP		= 9, 
	TAG_UA_STYLE_TABLE_FOOTER_GROUP		= 10, 
	TAG_UA_STYLE_TABLE_HEADER_GROUP		= 11, 
	TAG_UA_STYLE_TABLE_ROW				= 12, 
	TAG_UA_STYLE_TABLE_ROW_GROUP		= 13, 
	TAG_UA_STYLE_RUBY					= 14, 
	TAG_UA_STYLE_RUBY_BASE				= 15, 
	TAG_UA_STYLE_RUBY_TEXT				= 16, 
	TAG_UA_STYLE_RUBY_TEXT_CONTAINER	= 17, 
};

// async parsing
void *html5_dom_mythread_function(void *arg);
void html5_dom_async_parse_worker(mythread_id_t thread_id, void *arg);
int html5_dom_async_parse(html5_dom_async_result *result);

// parser
html5_dom_parser_t *html5_dom_parser_new(html5_dom_options_t *options);
void *html5_dom_parser_free(html5_dom_parser_t *self);
mystatus_t html5_dom_init_css(html5_dom_parser_t *parser);
myhtml_tree_node_t *html5_dom_parse_fragment(html5_dom_options_t *opts, myhtml_tree_t *tree, myhtml_tag_id_t tag_id, myhtml_namespace_t ns, 
	const char *text, size_t length, html5_fragment_parts_t *parts, mystatus_t *status_out);
void html5_dom_apply_tree_options(myhtml_tree_t *tree, html5_dom_options_t *opts);

// misc
const char *modest_strerror(mystatus_t status);
int html5_dom_get_ua_display_prop(myhtml_tree_node_t *node);
void html5_dom_rtrim_mystring(mycore_string_t *str, char c);

// finders & css
void _modest_finder_callback_found_with_one_node(modest_finder_t *finder, myhtml_tree_node_t *node, 
	mycss_selectors_list_t *selector_list, mycss_selectors_entry_t *selector, mycss_selectors_specificity_t *spec, void *ctx);
void *html5_node_finder(html5_dom_parser_t *parser, modest_finder_selector_combinator_f func, 
		myhtml_tree_node_t *scope, mycss_selectors_entries_list_t *list, size_t list_size, mystatus_t *status_out, bool one);
modest_finder_selector_combinator_f html5_find_selector_func(const char *c, int combo_len);
mycss_selectors_list_t *html5_parse_selector(mycss_entry_t *entry, const char *query, size_t query_len, mystatus_t *status_out);
myhtml_tag_id_t html5_dom_tag_id_by_name(myhtml_tree_t *tree, const char *tag_str, size_t tag_len, bool allow_create);
myhtml_tree_node_t *html5_dom_copy_foreign_node(myhtml_tree_t *tree, myhtml_tree_node_t *node);
myhtml_tree_node_t *html5_dom_recursive_clone_node(myhtml_tree_t *tree, myhtml_tree_node_t *node, html5_fragment_parts_t *parts);
void html5_dom_recursive_node_inner_text(myhtml_tree_node_t *node, html5_dom_inner_text_state_t *state);
void html5_tree_node_delete_recursive(myhtml_tree_node_t *node);

// attrs
void html5_dom_replace_attr_value(myhtml_tree_node_t *node, const char *key, size_t key_len, const char *val, size_t val_len, myencoding_t encoding);

// encoding
myencoding_t html5_dom_auto_encoding(html5_dom_options_t *opts, const char **html_str, size_t *html_length);

#endif /* HTML5_DOM_UTILS_H */
