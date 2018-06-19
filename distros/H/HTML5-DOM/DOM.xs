#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "ppport.h"

#include <modest/finder/finder.h>
#include <myhtml/myhtml.h>
#include <myhtml/serialization.h>
#include <mycss/mycss.h>
#include <mycss/selectors/init.h>
#include <mycss/selectors/serialization.h>

#define MyENCODING_AUTO 1

//#define DOM_GC_TRACE(msg, ...) fprintf(stderr, "[GC] " msg "\n", ##__VA_ARGS__);
#define DOM_GC_TRACE(...)

// HACK: sv_derived_from_pvn faster than sv_derived_from
#if PERL_BCDVERSION > 0x5015004
	#undef sv_derived_from
	#define sv_derived_from(sv, name) sv_derived_from_pvn(sv, name, sizeof(name) - 1, 0)
#else
	#define sv_derived_from_pvn(sv, name, len) sv_derived_from(sv, name)
#endif

#define node_is_element(node) (node->tag_id != MyHTML_TAG__UNDEF && node->tag_id != MyHTML_TAG__TEXT && node->tag_id != MyHTML_TAG__COMMENT && node->tag_id != MyHTML_TAG__DOCTYPE)
#define node_is_document(node) (!node->parent && node == node->tree->document)
#define node_is_root(node) (node->tree->node_html && node->tree->node_html == node)

#define sub_croak(cv, msg, ...) do { \
	const GV *const __gv = CvGV(cv); \
	if (__gv) { \
		const char *__gvname = GvNAME(__gv); \
		const HV *__stash = GvSTASH(__gv); \
		const char *__hvname = __stash ? HvNAME(__stash) : NULL; \
		croak("%s%s%s(): " msg, __hvname ? __hvname : __gvname, __hvname ? "::" : "", __hvname ? __gvname : "", ##__VA_ARGS__); \
	} \
} while (0);

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

typedef struct {
	long threads;
	bool async;
	bool ignore_whitespace;
	bool ignore_doctype;
	bool scripts;
	myencoding_t encoding;
	myencoding_t default_encoding;
	bool encoding_use_meta;
	bool encoding_use_bom;
	long encoding_prescan_limit;
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
	SV *parent;
	SV *sv;
	myhtml_tree_t *tree;
	html5_dom_parser_t *parser;
	myhtml_tag_id_t fragment_tag_id;
} html5_dom_tree_t;

typedef struct {
	mycss_t *mycss;
	mycss_entry_t *entry;
	myencoding_t encoding;
} html5_css_parser_t;

typedef struct {
	html5_css_parser_t *parser;
	mycss_selectors_list_t *list;
	SV *parent;
} html5_css_selector_t;

typedef struct {
	html5_css_selector_t *selector;
	mycss_selectors_entries_list_t *list;
	SV *parent;
} html5_css_selector_entry_t;

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

typedef html5_dom_parser_t *			HTML5__DOM;
typedef myhtml_collection_t *			HTML5__DOM__Collection;
typedef myhtml_tree_node_t *			HTML5__DOM__Node;
typedef myhtml_tree_node_t *			HTML5__DOM__Element;
typedef myhtml_tree_node_t *			HTML5__DOM__Text;
typedef myhtml_tree_node_t *			HTML5__DOM__Comment;
typedef myhtml_tree_node_t *			HTML5__DOM__Document;
typedef myhtml_tree_node_t *			HTML5__DOM__Fragment;
typedef myhtml_tree_node_t *			HTML5__DOM__DocType;
typedef html5_dom_tree_t *				HTML5__DOM__Tree;
typedef html5_css_parser_t *			HTML5__DOM__CSS;
typedef html5_css_selector_t *			HTML5__DOM__CSS__Selector;
typedef html5_css_selector_entry_t *	HTML5__DOM__CSS__Selector__Entry;

static inline bool html5_dom_is_fragment(myhtml_tree_node_t *node) {
	html5_dom_tree_t *context = (html5_dom_tree_t *) node->tree->context;
	return context->fragment_tag_id && node->tag_id == context->fragment_tag_id;
}

static const char *modest_strerror(mystatus_t status) {
	switch (status) {
		#include "gen/modest_errors.c"	
	}
	return status ? "UNKNOWN" : "";
}

static void html5_dom_wait_for_tree_done(myhtml_tree_t *tree) {
	#ifndef MyCORE_BUILD_WITHOUT_THREADS
		myhtml_t *myhtml = myhtml_tree_get_myhtml(tree);
		if (myhtml->thread_stream) {
			mythread_queue_list_t* queue_list = myhtml->thread_stream->context;
			if (queue_list)
				mythread_queue_list_wait_for_done(myhtml->thread_stream, queue_list);
		}
	#endif
}

static void html5_dom_wait_for_done(myhtml_tree_node_t *node, bool deep) {
	#ifndef MyCORE_BUILD_WITHOUT_THREADS
		if (node->token)
			myhtml_token_node_wait_for_done(node->tree->token, node->token);
		if (deep) {
			myhtml_tree_node_t *child = myhtml_node_child(node);
			while (child) {
				html5_dom_wait_for_done(child, deep);
				child = myhtml_node_next(child);
			}
		}
	#endif
}

static bool html5_dom_tree_is_done(myhtml_tree_t *tree) {
	#ifndef MyCORE_BUILD_WITHOUT_THREADS
		myhtml_t *myhtml = myhtml_tree_get_myhtml(tree);
		if (myhtml->thread_stream) {
			mythread_queue_list_t* queue_list = myhtml->thread_stream->context;
			return mythread_queue_list_see_for_done(myhtml->thread_stream, queue_list);
		}
	#endif
	return true;
}

static bool html5_dom_is_done(myhtml_tree_node_t *node, bool deep) {
	#ifndef MyCORE_BUILD_WITHOUT_THREADS
		if (node->token) {
			if ((node->token->type & MyHTML_TOKEN_TYPE_DONE) == 0)
				return false;
		}
		if (deep) {
			myhtml_tree_node_t *child = myhtml_node_child(node);
			while (child) {
				if (!html5_dom_is_done(child, deep))
					return false;
				child = myhtml_node_next(child);
			}
		}
	#endif
	return true;
}

static void html5_dom_parser_free(html5_dom_parser_t *self) {
	if (self->myhtml) {
		myhtml_destroy(self->myhtml);
		self->myhtml = NULL;
	}
	
	if (self->mycss_entry) {
		mycss_entry_destroy(self->mycss_entry, 1);
		self->mycss_entry = NULL;
	}
	
	if (self->mycss) {
		mycss_destroy(self->mycss, 1);
		self->mycss = NULL;
	}
	
	if (self->finder) {
		modest_finder_destroy(self->finder, 1);
		self->finder = NULL;
	}
}

static mystatus_t sv_serialization_callback(const char *data, size_t len, void *ctx) {
	sv_catpvn((SV *) ctx, data, len);
	return MyCORE_STATUS_OK;
}

static inline SV *pack_pointer(const char *clazz, void *ptr) {
	SV *sv = newSV(0);
	sv_setref_pv(sv, clazz, ptr);
	return sv;
}

static int html5_dom_get_ua_display_prop(myhtml_tree_node_t *node) {
	switch (node->tag_id) {
		#include "gen/tags_ua_style.c"	
	}
	return TAG_UA_STYLE_INLINE;
}

static void html5_dom_recursive_node_text(myhtml_tree_node_t *node, SV *sv) {
	node = myhtml_node_child(node);
	while (node) {
		if (node->tag_id == MyHTML_TAG__TEXT) {
			size_t text_len = 0;
			const char *text = myhtml_node_text(node, &text_len);
			if (text_len)
				sv_catpvn(sv, text, text_len);
		} else if (node_is_element(node)) {
			html5_dom_recursive_node_text(node, sv);
		}
		node = myhtml_node_next(node);
	}
}

static void html5_dom_rtrim_mystring(mycore_string_t *str, char c) {
	size_t i = str->length;
	while (i > 0) {
		--i;
		
		if (str->data[i] != c)
			break;
		
		str->data[i] = '\0';
		--str->length;
	}
}

// Try to implements https://html.spec.whatwg.org/multipage/dom.html#the-innertext-idl-attribute
// Using default user-agent box model types for tags instead of real css.
static void html5_dom_recursive_node_inner_text(myhtml_tree_node_t *node, html5_dom_inner_text_state_t *state) {
	if (node->tag_id == MyHTML_TAG__TEXT) {
		size_t text_len = 0;
		const char *text = myhtml_node_text(node, &text_len);
		
		bool is_empty = true;
		for (size_t i = 0; i < text_len; ++i) {
			// skip CR
			if (text[i] == '\r')
				continue;
			
			// collapse spaces
			if (isspace(text[i])) {
				bool skip_spaces = (state->value.length > 0 && state->value.data[state->value.length - 1] == ' ') || state->new_line;
				if (skip_spaces)
					continue;
				mycore_string_append_one(&state->value, ' ');
			}
			// save other chars
			else {
				mycore_string_append_one(&state->value, text[i]);
				is_empty = false;
				state->new_line = false;
			}
		}
		
		if (!is_empty)
			state->last_br = false;
	} else if (node_is_element(node)) {
		// get default box model type for tag
		int display = html5_dom_get_ua_display_prop(node);
		
		// skip hidden nodes
		if (display == TAG_UA_STYLE_NONE)
			return;
		
		// skip some special nodes
		switch (node->tag_id) {
			case MyHTML_TAG_TEXTAREA:
			case MyHTML_TAG_INPUT:
			case MyHTML_TAG_AUDIO:
			case MyHTML_TAG_VIDEO:
				return;
		}
		
		// <br> always inserts \n
		if (node->tag_id == MyHTML_TAG_BR) {
			mycore_string_append_one(&state->value, '\n');
			state->new_line = true;
			state->last_br = true;
		} else {
			switch (display) {
				case TAG_UA_STYLE_BLOCK:
				case TAG_UA_STYLE_TABLE:
				case TAG_UA_STYLE_TABLE_CAPTION:
					// if last token - line break, then collapse
					// if last token - text, then insert new line break
					if (!state->last_br) {
						html5_dom_rtrim_mystring(&state->value, ' ');
						mycore_string_append_one(&state->value, '\n');
						state->new_line = true;
						state->last_br = true;
					}
				break;
			}
			
			myhtml_tree_node_t *child = myhtml_node_child(node);
			while (child) {
				html5_dom_recursive_node_inner_text(child, state);
				child = myhtml_node_next(child);
			}
			
			switch (display) {
				case TAG_UA_STYLE_BLOCK:
				case TAG_UA_STYLE_TABLE:
				case TAG_UA_STYLE_TABLE_CAPTION:
					// if last token - line break, then collapse
					// if last token - text, then insert new line break
					if (!state->last_br) {
						html5_dom_rtrim_mystring(&state->value, ' ');
						if (node->tag_id == MyHTML_TAG_P) {
							// chrome inserts two \n after <p>
							mycore_string_append_one(&state->value, '\n');
							mycore_string_append_one(&state->value, '\n');
						} else {
							mycore_string_append_one(&state->value, '\n');
						}
						state->new_line = true;
						state->last_br = true;
					}
				break;
				
				case TAG_UA_STYLE_TABLE_CELL:
				{
					bool is_last_cell = false;
					myhtml_tree_node_t *cell = myhtml_node_last_child(myhtml_node_parent(node));
					while (cell) {
						if (html5_dom_get_ua_display_prop(cell) == TAG_UA_STYLE_TABLE_CELL) {
							is_last_cell = cell == node;
							break;
						}
						cell = myhtml_node_prev(cell);
					}
					
					if (!is_last_cell) {
						html5_dom_rtrim_mystring(&state->value, ' ');
						mycore_string_append_one(&state->value, '\t');
					}
					
					state->new_line = true;
				}
				break;
				
				case TAG_UA_STYLE_TABLE_ROW:
				{
					bool is_last_row = false;
					myhtml_tree_node_t *row = myhtml_node_last_child(myhtml_node_parent(node));
					while (row) {
						if (html5_dom_get_ua_display_prop(row) == TAG_UA_STYLE_TABLE_ROW) {
							is_last_row = (row == node);
							break;
						}
						row = myhtml_node_prev(row);
					}
					
					if (!is_last_row) {
						html5_dom_rtrim_mystring(&state->value, ' ');
						mycore_string_append_one(&state->value, '\n');
						state->last_br = true;
					}
					
					state->new_line = true;
				}
				break;
			}
		}
	}
}

static SV *create_tree_object(myhtml_tree_t *tree, SV *parent, html5_dom_parser_t *parser) {
	tree->context = safemalloc(sizeof(html5_dom_tree_t));
	
	html5_dom_tree_t *tree_obj = (html5_dom_tree_t *) tree->context;
	tree_obj->tree = tree;
	tree_obj->parent = parent;
	tree_obj->parser = parser;
	tree_obj->fragment_tag_id = MyHTML_TAG__UNDEF;
	
	SvREFCNT_inc(parent);
	
	SV *sv = pack_pointer("HTML5::DOM::Tree", tree_obj);
	tree_obj->sv = SvRV(sv);
	
	DOM_GC_TRACE("DOM::Tree::NEW (refcnt=%d)", SvREFCNT(sv));
	
	return sv;
}

static inline const char *get_node_class(myhtml_tree_node_t *node) {
	html5_dom_tree_t *context = (html5_dom_tree_t *) node->tree->context;
	
	if (node->tag_id != MyHTML_TAG__UNDEF) {
		if (node->tag_id == MyHTML_TAG__TEXT) {
			return "HTML5::DOM::Text";
		} else if (node->tag_id == MyHTML_TAG__COMMENT) {
			return "HTML5::DOM::Comment";
		} else if (node->tag_id == MyHTML_TAG__DOCTYPE) {
			return "HTML5::DOM::DocType";
		} else if (context->fragment_tag_id && node->tag_id == context->fragment_tag_id) {
			return "HTML5::DOM::Fragment";
		}
		return "HTML5::DOM::Element";
	}
	
	// Modest myhtml bug - document node has tag_id == MyHTML_TAG__UNDEF
	if (node_is_document(node))
		return "HTML5::DOM::Document";
	
	return "HTML5::DOM::Node";
}

static myhtml_tag_id_t html5_dom_tag_id_by_name(myhtml_tree_t *tree, const char *tag_str, size_t tag_len, bool allow_create) {
	const myhtml_tag_context_t *tag_ctx = myhtml_tag_get_by_name(tree->tags, tag_str, tag_len);
	if (tag_ctx) {
		return tag_ctx->id;
	} else if (allow_create) {
		// add custom tag
		return myhtml_tag_add(tree->tags, tag_str, tag_len, MyHTML_TOKENIZER_STATE_DATA, true);
	}
	return MyHTML_TAG__UNDEF;
}

// Safe copy node from native or foreign tree
static myhtml_tree_node_t *html5_dom_copy_foreign_node(myhtml_tree_t *tree, myhtml_tree_node_t *node) {
	// Create new node
	myhtml_tree_node_t *new_node = myhtml_tree_node_create(tree);
	new_node->tag_id		= node->tag_id;
	new_node->ns			= node->ns;
	
	// Copy custom tag
	if (tree != node->tree && node->tag_id >= MyHTML_TAG_LAST_ENTRY) {
		new_node->tag_id = MyHTML_TAG__UNDEF;
		
		// Get tag name in foreign tree
		const myhtml_tag_context_t *tag_ctx = myhtml_tag_get_by_id(node->tree->tags, node->tag_id);
		if (tag_ctx) {
			// Get same tag in native tree
			new_node->tag_id = html5_dom_tag_id_by_name(tree, tag_ctx->name, tag_ctx->name_length, true);
		}
	}
	
	if (node->token) {
		// Wait, if node not yet done
		myhtml_token_node_wait_for_done(node->tree->token, node->token);
		
		// Copy node token
		new_node->token = myhtml_token_node_create(tree->token, tree->mcasync_rules_token_id);
		if (!new_node->token) {
			myhtml_tree_node_delete(new_node);
			return NULL;
		}
		
		new_node->token->tag_id			= node->token->tag_id;
		new_node->token->type			= node->token->type;
		new_node->token->attr_first		= NULL;
		new_node->token->attr_last		= NULL;
		new_node->token->raw_begin		= tree != node->tree ? 0 : node->token->raw_begin;
		new_node->token->raw_length		= tree != node->tree ? 0 : node->token->raw_length;
		new_node->token->element_begin	= tree != node->tree ? 0 : node->token->element_begin;
		new_node->token->element_length	= tree != node->tree ? 0 : node->token->element_length;
		new_node->token->type			= new_node->token->type | MyHTML_TOKEN_TYPE_DONE;
		
		// Copy text data
		if (node->token->str.length) {
			mycore_string_init(tree->mchar, tree->mchar_node_id, &new_node->token->str, node->token->str.length + 1);
			mycore_string_append(&new_node->token->str, node->token->str.data, node->token->str.length);
		} else {
			mycore_string_clean_all(&new_node->token->str);
		}
		
		// Copy node attributes
		myhtml_token_attr_t *attr = node->token->attr_first;
		while (attr) {
			myhtml_token_attr_copy(tree->token, attr, new_node->token, tree->mcasync_rules_attr_id);
			attr = attr->next;
		}
	}
	
	return new_node;
}

static SV *tree_to_sv(myhtml_tree_t *tree) {
	html5_dom_tree_t *context = (html5_dom_tree_t *) tree->context;
	return newRV(context->sv);
}

static SV *myhtml_to_sv(myhtml_tree_t *tree) {
	html5_dom_tree_t *context = (html5_dom_tree_t *) tree->context;
	return newRV(context->parent);
}

static SV *node_to_sv(myhtml_tree_node_t *node) {
	if (!node)
		return &PL_sv_undef;
	
	SV *sv = (SV *) myhtml_node_get_data(node);
	if (!sv) {
		SV *node_ref = pack_pointer(get_node_class(node), (void *) node);
		sv = SvRV(node_ref);
		myhtml_node_set_data(node, (void *) sv);
		
		DOM_GC_TRACE("DOM::Node::NEW (new refcnt=%d)", SvREFCNT(sv));
		
		html5_dom_tree_t *tree = (html5_dom_tree_t *) node->tree->context;
		SvREFCNT_inc(tree->sv);
		
		return node_ref;
	} else {
		SV *node_ref = newRV(sv);
		DOM_GC_TRACE("DOM::Node::NEW (reuse refcnt=%d)", SvREFCNT(sv));
		return node_ref;
	}
}

static SV *collection_to_blessed_array(myhtml_collection_t *collection) {
	AV *arr = newAV();
	if (collection) {
		for (int i = 0; i < collection->length; ++i)
			av_push(arr, node_to_sv(collection->list[i]));
	}
	return sv_bless(newRV_noinc((SV *) arr), gv_stashpv("HTML5::DOM::Collection", 0));
}

static SV *sv_stringify(SV *sv) {
	if (SvROK(sv)) {
		SV *tmp_sv = SvRV(sv);
		if (SvOBJECT(tmp_sv)) {
			HV *stash = SvSTASH(tmp_sv);
			GV *to_string = gv_fetchmethod_autoload(stash, "\x28\x22\x22", 0);
			
			if (to_string) {
				dSP;
				ENTER; SAVETMPS; PUSHMARK(SP);
				XPUSHs(sv_bless(sv_2mortal(newRV_inc(tmp_sv)), stash));
				PUTBACK;
				call_sv((SV *) GvCV(to_string), G_SCALAR);
				SPAGAIN;
				
				SV *new_sv = POPs;
				
				PUTBACK;
				FREETMPS; LEAVE;
				
				return new_sv;
			}
		}
	}
	return sv;
}

static mystatus_t html5_dom_init_css(html5_dom_parser_t *parser) {
	mystatus_t status = MyCSS_STATUS_OK;
	
	if (!parser->mycss) {
		parser->mycss = mycss_create();
		status = mycss_init(parser->mycss);
		if (status) {
			mycss_destroy(parser->mycss, 1);
			parser->mycss = NULL;
			return status;
		}
	}
	
	if (!parser->mycss_entry) {
		parser->mycss_entry = mycss_entry_create();
		status = mycss_entry_init(parser->mycss, parser->mycss_entry);
		if (status) {
			mycss_entry_destroy(parser->mycss_entry, 1);
			mycss_destroy(parser->mycss, 1);
			parser->mycss = NULL;
			parser->mycss_entry = NULL;
			return status;
		}
	}
	
	return status;
}

static mycss_selectors_list_t *html5_parse_selector(mycss_entry_t *entry, const char *query, size_t query_len, mystatus_t *status_out) {
	mystatus_t status;
	
	*status_out = MyCSS_STATUS_OK;
	
	mycss_selectors_list_t *list = mycss_selectors_parse(mycss_entry_selectors(entry), MyENCODING_UTF_8, query, query_len, &status);
	if (status || list == NULL || (list->flags & MyCSS_SELECTORS_FLAGS_SELECTOR_BAD)) {
		if (list)
			mycss_selectors_list_destroy(mycss_entry_selectors(entry), list, true);
		*status_out = status;
		return NULL;
	}
	
	return list;
}

static void _modest_finder_callback_found_with_one_node(modest_finder_t *finder, myhtml_tree_node_t *node, 
	mycss_selectors_list_t *selector_list, mycss_selectors_entry_t *selector, mycss_selectors_specificity_t *spec, void *ctx)
{
	myhtml_tree_node_t **result_node = (myhtml_tree_node_t **) ctx;
	if (!*result_node)
		*result_node = node;
}

static void *html5_node_finder(html5_dom_parser_t *parser, modest_finder_selector_combinator_f func, 
		myhtml_tree_node_t *scope, mycss_selectors_entries_list_t *list, size_t list_size, mystatus_t *status_out, bool one)
{
	*status_out = MODEST_STATUS_OK;
	
	if (!scope)
		return NULL;
	
	// Init finder
	mystatus_t status;
	if (parser->finder) {
		parser->finder = modest_finder_create();
		status = modest_finder_init(parser->finder);
		if (status) {
			*status_out = status;
			modest_finder_destroy(parser->finder, 1);
			return NULL;
		}
	}
	
	if (one) {
		// Process selector entries
		myhtml_tree_node_t *node = NULL;
		for (size_t i = 0; i < list_size; ++i) {
			func(parser->finder, scope, NULL, list[i].entry, &list[i].specificity, 
				_modest_finder_callback_found_with_one_node, &node);
			
			if (node)
				break;
		}
		
		return (void *) node;
	} else {
		// Init collection for results
		myhtml_collection_t *collection = myhtml_collection_create(4096, &status);
		if (status) {
			*status_out = MODEST_STATUS_ERROR_MEMORY_ALLOCATION;
			return NULL;
		}
		
		// Process selector entries
		for (size_t i = 0; i < list_size; ++i) {
			func(parser->finder, scope, NULL, list[i].entry, &list[i].specificity, 
				modest_finder_callback_found_with_collection, collection);
		}
		
		return (void *) collection;
	}
}

static modest_finder_selector_combinator_f html5_find_selector_func(const char *c, int combo_len) {
	if (combo_len == 2) {
		if (c[0] == '|' && c[1] == '|')
			return modest_finder_node_combinator_column;
		if ((c[0] == '>' && c[1] == '>'))
			return modest_finder_node_combinator_descendant;
	} else if (combo_len == 1) {
		if (c[0] == '>')
			return modest_finder_node_combinator_child;
		if (c[0] == '+')
			return modest_finder_node_combinator_next_sibling;
		if (c[0] == '~')
			return modest_finder_node_combinator_following_sibling;
		if (c[0] == '^')
			return modest_finder_node_combinator_begin;
	}
	return modest_finder_node_combinator_descendant;
}

static SV *html5_node_find(CV *cv, html5_dom_parser_t *parser, myhtml_tree_node_t *scope, SV *query, SV *combinator, bool one) {
	mystatus_t status;
	mycss_selectors_entries_list_t *list = NULL;
	size_t list_size = 0;
	mycss_selectors_list_t *selector = NULL;
	modest_finder_selector_combinator_f selector_func = modest_finder_node_combinator_descendant;
	SV *result = &PL_sv_undef;
	
	// Custom combinator as args
	if (combinator) {
		query = sv_stringify(query);
		
		STRLEN combo_len;
		const char *combo = SvPV_const(combinator, combo_len);
		
		if (combo_len > 0)
			selector_func = html5_find_selector_func(combo, combo_len);
	}
	
	if (SvROK(query)) {
		if (sv_derived_from(query, "HTML5::DOM::CSS::Selector")) { // Precompiler selectors
			html5_css_selector_t *selector = INT2PTR(html5_css_selector_t *, SvIV((SV*)SvRV(query)));
			list = selector->list->entries_list;
			list_size = selector->list->entries_list_length;
		} else if (sv_derived_from(query, "HTML5::DOM::CSS::Selector::Entry")) { // One precompiled selector
			html5_css_selector_entry_t *selector = INT2PTR(html5_css_selector_entry_t *, SvIV((SV*)SvRV(query)));
			list = selector->list;
			list_size = 1;
		} else {
			sub_croak(cv, "%s: %s is not of type %s or %s", "HTML5::DOM::Tree::find", "query", "HTML5::DOM::CSS::Selector", "HTML5::DOM::CSS::Selector::Entry");
		}
	} else {
		// String selector, compile it
		query = sv_stringify(query);
		
		STRLEN query_len;
		const char *query_str = SvPV_const(query, query_len);
		
		status = html5_dom_init_css(parser);
		if (status)
			sub_croak(cv, "mycss_init failed: %d (%s)", status, modest_strerror(status));
		
		selector = html5_parse_selector(parser->mycss_entry, query_str, query_len, &status);
		
		if (!selector)
			sub_croak(cv, "bad selector: %s", query_str);
		
		list = selector->entries_list;
		list_size = selector->entries_list_length;
	}
	
	if (one) { // search one element
		myhtml_tree_node_t *node = (myhtml_tree_node_t *) html5_node_finder(parser, selector_func, scope, list, list_size, &status, 1);
		result = node_to_sv(node);
	} else { // search multiple elements
		myhtml_collection_t *collection = (myhtml_collection_t *) html5_node_finder(parser, selector_func, scope, list, list_size, &status, 0);
		result = collection_to_blessed_array(collection);
		if (collection)
			myhtml_collection_destroy(collection);
	}
	
	// destroy parsed selector
	if (selector)
		mycss_selectors_list_destroy(mycss_entry_selectors(parser->mycss_entry), selector, true);
	
	return result;
}

static SV *html5_node_simple_find(CV *cv, myhtml_tree_node_t *self, SV *key, SV *val, SV *cmp, bool icase, int ix) {
	if (!self)
		return collection_to_blessed_array(NULL);
	
	SV *result = &PL_sv_undef;
	key = sv_stringify(key);
	
	STRLEN key_len;
	const char *key_str = SvPV_const(key, key_len);
	
	myhtml_collection_t *collection = NULL;
	switch (ix) {
		case 0: case 1: // tag name
			collection = myhtml_get_nodes_by_name_in_scope(self->tree, NULL, self, key_str, key_len, NULL);
			result = collection_to_blessed_array(collection);
		break;
		case 2: case 3: // class
			collection = myhtml_get_nodes_by_attribute_value_whitespace_separated(self->tree, NULL, self, false, "class", 5, key_str, key_len, NULL);
			result = collection_to_blessed_array(collection);
		break;
		case 4: case 5: // id (first)
			collection = myhtml_get_nodes_by_attribute_value(self->tree, NULL, self, false, "id", 2, key_str, key_len, NULL);
			if (collection && collection->length)
				result = node_to_sv(collection->list[0]);
		break;
		case 6: case 7: // attribute
			if (val) {
				STRLEN val_len;
				const char *val_str = SvPV_const(val, val_len);
				
				char cmp_type = '=';
				if (cmp) {
					cmp = sv_stringify(cmp);
					STRLEN cmp_len;
					const char *cmp_str = SvPV_const(cmp, cmp_len);
					
					if (cmp_len)
						cmp_type = cmp_str[0];
				}
				
				if (cmp_type == '=') {
					// [key=val]
					collection = myhtml_get_nodes_by_attribute_value(self->tree, NULL, self, icase, key_str, key_len, val_str, val_len, NULL);
				} else if (cmp_type == '~') {
					// [key~=val]
					collection = myhtml_get_nodes_by_attribute_value_whitespace_separated(self->tree, NULL, self, icase, key_str, key_len, val_str, val_len, NULL);
				} else if (cmp_type == '^') {
					// [key^=val]
					collection = myhtml_get_nodes_by_attribute_value_begin(self->tree, NULL, self, icase, key_str, key_len, val_str, val_len, NULL);
				} else if (cmp_type == '$') {
					// [key$=val]
					collection = myhtml_get_nodes_by_attribute_value_end(self->tree, NULL, self, icase, key_str, key_len, val_str, val_len, NULL);
				} else if (cmp_type == '*') {
					// [key*=val]
					collection = myhtml_get_nodes_by_attribute_value_contain(self->tree, NULL, self, icase, key_str, key_len, val_str, val_len, NULL);
				} else if (cmp_type == '|') {
					// [key|=val]
					collection = myhtml_get_nodes_by_attribute_value_hyphen_separated(self->tree, NULL, self, icase, key_str, key_len, val_str, val_len, NULL);
				} else {
					sub_croak(cv, "unknown cmp type: %c", cmp_type);
				}
			} else {
				// [key]
				collection = myhtml_get_nodes_by_attribute_key(self->tree, NULL, self, key_str, key_len, NULL);
			}
			result = collection_to_blessed_array(collection);
		break;
	}
	
	if (collection)
		myhtml_collection_destroy(collection);
	
	return result;
}

static myhtml_tree_node_t *html5_dom_recursive_clone_node(myhtml_tree_t *tree, myhtml_tree_node_t *node, html5_fragment_parts_t *parts) {
	myhtml_tree_node_t *new_node = html5_dom_copy_foreign_node(tree, node);
	myhtml_tree_node_t *child = myhtml_node_child(node);
	
	if (parts) {
		if (node == node->tree->node_html)
			parts->node_html = new_node;
		else if (node == node->tree->node_head)
			parts->node_head = new_node;
		else if (node == node->tree->node_body)
			parts->node_body = new_node;
		else if (node == node->tree->document)
			parts->document = new_node;
	}
	
	while (child) {
		myhtml_tree_node_add_child(new_node, html5_dom_recursive_clone_node(tree, child, parts));
		child = myhtml_node_next(child);
	}
	
	return new_node;
}

// Safe delete nodes only if it has not perl object representation
static void html5_tree_node_delete_recursive(myhtml_tree_node_t *node) {
	if (!myhtml_node_get_data(node)) {
		myhtml_tree_node_t *child = myhtml_node_child(node);
		if (child) {
			while (child) {
				myhtml_tree_node_t *next = myhtml_node_next(child);
				myhtml_tree_node_remove(child);
				html5_tree_node_delete_recursive(child);
				child = next;
			}
		}
		myhtml_tree_node_delete(node);
	}
}

void html5_dom_replace_attr_value(myhtml_tree_node_t *node, const char *key, size_t key_len, const char *val, size_t val_len, myencoding_t encoding) {
	myhtml_tree_attr_t *attr = myhtml_attribute_by_key(node, key, key_len);
	if (attr) { // edit
		// destroy original value
		mycore_string_destroy(&attr->value, 0);
		
		// set new value
		mycore_string_init(node->tree->mchar, node->tree->mchar_node_id, &attr->value, (val_len + 1));
		
		// apply encoding
		if (encoding == MyENCODING_UTF_8) {
			mycore_string_append(&attr->value, val, val_len);
		} else {
			myencoding_string_append(&attr->value, val, val_len, encoding);
		}
	} else { // add new
		myhtml_attribute_add(node, key, key_len, val, val_len, encoding);
	}
}

myencoding_t html5_dom_auto_encoding(html5_dom_options_t *opts, const char **html_str, size_t *html_length) {
	// Try to determine encoding
	myencoding_t encoding;
	if (opts->encoding == MyENCODING_AUTO) {
		encoding = MyENCODING_NOT_DETERMINED;
		if (*html_length) {
			// Search encoding in meta-tags
			if (opts->encoding_use_meta) {
				size_t size = opts->encoding_prescan_limit < *html_length ? opts->encoding_prescan_limit : *html_length;
				encoding = myencoding_prescan_stream_to_determine_encoding(*html_str, size);
			}
			
			if (encoding == MyENCODING_NOT_DETERMINED) {
				// Check BOM
				if (!opts->encoding_use_bom || !myencoding_detect_and_cut_bom(*html_str, *html_length, &encoding, html_str, html_length)) {
					// Check heuristic
					if (!myencoding_detect(*html_str, *html_length, &encoding)) {
						// Can't determine encoding, use default
						encoding = opts->default_encoding;
					}
				}
			}
		} else {
			encoding = opts->default_encoding;
		}
	} else {
		encoding = opts->encoding;
	}
	return encoding;
}

void html5_dom_apply_tree_options(myhtml_tree_t *tree, html5_dom_options_t *opts);

static myhtml_tree_node_t *html5_dom_parse_fragment(html5_dom_options_t *opts, myhtml_tree_t *tree, myhtml_tag_id_t tag_id, myhtml_namespace_t ns, 
	const char *text, size_t length, html5_fragment_parts_t *parts, mystatus_t *status_out)
{
	mystatus_t status;
	
	myhtml_t *parser = myhtml_tree_get_myhtml(tree);
	
	// cteate temorary tree
	myhtml_tree_t *fragment_tree = myhtml_tree_create();
	status = myhtml_tree_init(fragment_tree, parser);
	if (status) {
		*status_out = status;
		myhtml_tree_destroy(tree);
		return NULL;
	}
	
	html5_dom_apply_tree_options(fragment_tree, opts);
	
	myencoding_t encoding = html5_dom_auto_encoding(opts, &text, &length);
	
	// parse fragment from text
	status = myhtml_parse_fragment(fragment_tree, encoding, text, length, tag_id, ns);
	if (status) {
		*status_out = status;
		myhtml_tree_destroy(tree);
		return NULL;
	}
	
	// clone fragment from temporary tree to persistent tree
	myhtml_tree_node_t *node = html5_dom_recursive_clone_node(tree, myhtml_tree_get_node_html(fragment_tree), parts);
	
	if (node) {
		html5_dom_tree_t *context = (html5_dom_tree_t *) node->tree->context;
		if (!context->fragment_tag_id)
			context->fragment_tag_id = html5_dom_tag_id_by_name(tree, "-fragment", 9, true);
		node->tag_id = context->fragment_tag_id;
	}
	
	myhtml_tree_destroy(fragment_tree);
	
	*status_out = status;
	
	return node;
}

long hv_get_int_value(HV *hv, const char *key, int length, long def) {
	if (hv) {
		SV **sv = hv_fetch(hv, key, length, 0);
		if (sv && *sv)
			return SvIV(*sv);
	}
	return def;
}

myencoding_t hv_get_encoding_value(HV *hv, const char *key, int length, myencoding_t def) {
	if (hv) {
		SV **sv = hv_fetch(hv, key, length, 0);
		if (sv && *sv) {
			SV *encoding = sv_stringify(*sv);
			
			STRLEN enc_length;
			const char *enc_str = SvPV_const(encoding, enc_length);
			
			if (enc_length > 0) {
				myencoding_t enc_id;
				if (isdigit(enc_str[0])) { // May be encoding id
					enc_id = SvIV(encoding);
					if (enc_id == MyENCODING_AUTO || enc_id == MyENCODING_DEFAULT || enc_id == MyENCODING_NOT_DETERMINED)
						return enc_id;
					if (!myencoding_name_by_id(enc_id, NULL))
						return MyENCODING_NOT_DETERMINED;
				} else { // May be encoding name
					if (!myencoding_by_name(key, length, &enc_id)) {
						if (length == 4 && strcasecmp(key, "auto") == 0)
							return MyENCODING_AUTO;
						if (length == 7 && strcasecmp(key, "default") == 0)
							return MyENCODING_DEFAULT;
						return MyENCODING_NOT_DETERMINED;
					}
				}
				return enc_id;
			}
		}
	}
	return def;
}

void html5_dom_parse_options(html5_dom_options_t *opts, html5_dom_options_t *extend, HV *options) {
	opts->threads					= hv_get_int_value(options, "threads", 7, extend ? extend->threads : 2);
	opts->async						= hv_get_int_value(options, "async", 5, extend ? extend->async : 0) > 0;
	opts->ignore_whitespace			= hv_get_int_value(options, "ignore_whitespace", 17, extend ? extend->ignore_whitespace : 0) > 0;
	opts->ignore_doctype			= hv_get_int_value(options, "ignore_doctype", 14, extend ? extend->ignore_doctype : 0) > 0;
	opts->scripts					= hv_get_int_value(options, "scripts", 7, extend ? extend->scripts : 0) > 0;
	opts->encoding					= hv_get_encoding_value(options, "encoding", 8, extend ? extend->encoding : MyENCODING_AUTO);
	opts->default_encoding			= hv_get_encoding_value(options, "default_encoding", 16, extend ? extend->default_encoding : MyENCODING_DEFAULT);
	opts->encoding_use_meta			= hv_get_int_value(options, "encoding_use_meta", 17, extend ? extend->encoding_use_meta : 1) > 0;
	opts->encoding_use_bom			= hv_get_int_value(options, "encoding_use_bom", 16, extend ? extend->encoding_use_bom : 1) > 0;
	opts->encoding_prescan_limit	= hv_get_int_value(options, "encoding_prescan_limit", 22, extend ? extend->encoding_prescan_limit : 1024);
	
	#ifdef MyCORE_BUILD_WITHOUT_THREADS
		opts->threads = 0;
	#endif
}

void html5_dom_check_options(CV *cv, html5_dom_options_t *opts) {
	if (opts->encoding == MyENCODING_NOT_DETERMINED)
		sub_croak(cv, "invalid encoding value");
	if (opts->default_encoding == MyENCODING_NOT_DETERMINED || opts->default_encoding == MyENCODING_AUTO)
		sub_croak(cv, "invalid default_encoding value");
	if (opts->threads < 0)
		sub_croak(cv, "invalid threads count");
	if (opts->encoding_prescan_limit < 0)
		sub_croak(cv, "invalid encoding_prescan_limit value");
}

void html5_dom_apply_tree_options(myhtml_tree_t *tree, html5_dom_options_t *opts) {
	if (opts->scripts) {
		tree->flags |= MyHTML_TREE_FLAGS_SCRIPT;
	} else {
		tree->flags &= ~MyHTML_TREE_FLAGS_SCRIPT;
	}
	
	if (opts->ignore_doctype)
		tree->parse_flags |= MyHTML_TREE_PARSE_FLAGS_WITHOUT_DOCTYPE_IN_TREE;
	
	if (opts->ignore_whitespace)
		tree->parse_flags |= MyHTML_TREE_PARSE_FLAGS_SKIP_WHITESPACE_TOKEN;
}

// selectors to AST serialization
void html5_dom_css_serialize_entry(mycss_selectors_list_t *selector, mycss_selectors_entry_t *entry, AV *result);

void html5_dom_css_serialize_selector(mycss_selectors_list_t *selector, AV *result) {
	while (selector) {
		for (size_t i = 0; i < selector->entries_list_length; ++i) {
			mycss_selectors_entries_list_t *entries = &selector->entries_list[i];
			AV *chain = newAV();
			html5_dom_css_serialize_entry(selector, entries->entry, chain);
			av_push(result, newRV_noinc((SV *) chain));
		}
		selector = selector->next;
	}
}

void html5_dom_css_serialize_entry(mycss_selectors_list_t *selector, mycss_selectors_entry_t *entry, AV *result) {
	// combinators names
	static const struct {
		const char name[16];
		size_t len;
	} combinators[] = {
		{"", 0}, 
		{"descendant", 10},	// >>
		{"child", 5},		// >
		{"sibling", 7},		// +
		{"adjacent", 8},	// ~
		{"column", 6}		// ||
	};
	
	// attribute eq names
	static const struct {
		const char name[16];
		size_t len;
	} attr_match_names[] = {
		{"equal", 5},		// =
		{"include", 7},		// ~=
		{"dash", 4},		// |=
		{"prefix", 6},		// ^=
		{"suffix", 6},		// $=
		{"substring", 9}	// *=
	};
	
	while (entry) {
		if (entry->combinator != MyCSS_SELECTORS_COMBINATOR_UNDEF) {
			HV *data = newHV();
			hv_store_ent(data, sv_2mortal(newSVpv("type", 4)), newSVpv("combinator", 10), 0);
			hv_store_ent(data, sv_2mortal(newSVpv("value", 5)), newSVpv(combinators[entry->combinator].name, combinators[entry->combinator].len), 0);
			av_push(result, newRV_noinc((SV *) data));
		}
		
		HV *data = newHV();
		
		if ((selector->flags) & MyCSS_SELECTORS_FLAGS_SELECTOR_BAD)
			hv_store_ent(data, sv_2mortal(newSVpv("invalid", 7)), newSViv(1), 0);
		
		switch (entry->type) {
			case MyCSS_SELECTORS_TYPE_ID:
			case MyCSS_SELECTORS_TYPE_CLASS:
			case MyCSS_SELECTORS_TYPE_ELEMENT:
			case MyCSS_SELECTORS_TYPE_PSEUDO_CLASS:
			case MyCSS_SELECTORS_TYPE_PSEUDO_ELEMENT:
			{
				switch (entry->type) {
					case MyCSS_SELECTORS_TYPE_ELEMENT:
						hv_store_ent(data, sv_2mortal(newSVpv("type", 4)), newSVpv("tag", 3), 0);
					break;
					case MyCSS_SELECTORS_TYPE_ID:
						hv_store_ent(data, sv_2mortal(newSVpv("type", 4)), newSVpv("id", 2), 0);
					break;
					case MyCSS_SELECTORS_TYPE_CLASS:
						hv_store_ent(data, sv_2mortal(newSVpv("type", 4)), newSVpv("class", 5), 0);
					break;
					case MyCSS_SELECTORS_TYPE_PSEUDO_CLASS:
						hv_store_ent(data, sv_2mortal(newSVpv("type", 4)), newSVpv("pseudo-class", 12), 0);
					break;
					case MyCSS_SELECTORS_TYPE_PSEUDO_ELEMENT:
						hv_store_ent(data, sv_2mortal(newSVpv("type", 4)), newSVpv("pseudo-element", 14), 0);
					break;
				}
				
				if (entry->key)
					hv_store_ent(data, sv_2mortal(newSVpv("value", 5)), newSVpv(entry->key->data ? entry->key->data : "", entry->key->length), 0);
			}
			break;
			case MyCSS_SELECTORS_TYPE_ATTRIBUTE:
			{
				hv_store_ent(data, sv_2mortal(newSVpv("type", 4)), newSVpv("attribute", 9), 0);
				
				/* key */
				if (entry->key)
					hv_store_ent(data, sv_2mortal(newSVpv("name", 4)), newSVpv(entry->key->data ? entry->key->data : "", entry->key->length), 0);
				
				/* value */
				if (mycss_selector_value_attribute(entry->value)->value) {
					mycore_string_t *str_value = mycss_selector_value_attribute(entry->value)->value;
					hv_store_ent(data, sv_2mortal(newSVpv("value", 5)), newSVpv(str_value->data ? str_value->data : "", str_value->length), 0);
				} else {
					hv_store_ent(data, sv_2mortal(newSVpv("value", 5)), newSVpv("", 0), 0);
				}
				
				/* match */
				int match = mycss_selector_value_attribute(entry->value)->match;
				hv_store_ent(data, sv_2mortal(newSVpv("match", 5)), newSVpv(attr_match_names[match].name, attr_match_names[match].len), 0);
				
				/* modificator */
				if (mycss_selector_value_attribute(entry->value)->mod & MyCSS_SELECTORS_MOD_I) {
					hv_store_ent(data, sv_2mortal(newSVpv("ignoreCase", 10)), newSViv(1), 0);
				} else {
					hv_store_ent(data, sv_2mortal(newSVpv("ignoreCase", 10)), newSViv(0), 0);
				}
			}
			break;
			case MyCSS_SELECTORS_TYPE_PSEUDO_CLASS_FUNCTION:
			{
				hv_store_ent(data, sv_2mortal(newSVpv("type", 4)), newSVpv("function", 8), 0);
				
				switch (entry->sub_type) {
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_CONTAINS:
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_HAS:
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_NOT:
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_MATCHES:
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_CURRENT:
					{
						switch (entry->sub_type) {
							case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_CONTAINS:
								hv_store_ent(data, sv_2mortal(newSVpv("name", 4)), newSVpv("contains", 8), 0);
							break;
							case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_HAS:
								hv_store_ent(data, sv_2mortal(newSVpv("name", 4)), newSVpv("has", 3), 0);
							break;
							case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_NOT:
								hv_store_ent(data, sv_2mortal(newSVpv("name", 4)), newSVpv("not", 3), 0);
							break;
							case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_MATCHES:
								hv_store_ent(data, sv_2mortal(newSVpv("name", 4)), newSVpv("matches", 7), 0);
							break;
							case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_CURRENT:
								hv_store_ent(data, sv_2mortal(newSVpv("name", 4)), newSVpv("current", 7), 0);
							break;
						}
						
						AV *value = newAV();
						html5_dom_css_serialize_selector(entry->value, value);
						hv_store_ent(data, sv_2mortal(newSVpv("value", 5)), newRV_noinc((SV *) value), 0);
					}
					break;
					
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_NTH_CHILD:
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_NTH_LAST_CHILD:
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_NTH_COLUMN:
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_NTH_LAST_COLUMN:
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_NTH_OF_TYPE:
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_NTH_LAST_OF_TYPE:
					{
						mycss_an_plus_b_entry_t *a_plus_b = mycss_selector_value_an_plus_b(entry->value);
						hv_store_ent(data, sv_2mortal(newSVpv("name", 4)), newSVpv("nth-child", 9), 0);
						hv_store_ent(data, sv_2mortal(newSVpv("a", 1)), newSViv(a_plus_b->a), 0);
						hv_store_ent(data, sv_2mortal(newSVpv("b", 1)), newSViv(a_plus_b->b), 0);
						
						if (a_plus_b->of) {
							AV *of = newAV();
							html5_dom_css_serialize_selector(a_plus_b->of, of);
							hv_store_ent(data, sv_2mortal(newSVpv("of", 2)), newRV_noinc((SV *) of), 0);
						}
					}
					break;
					
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_DIR:
					{
						hv_store_ent(data, sv_2mortal(newSVpv("name", 4)), newSVpv("dir", 3), 0);
						if (entry->value) {
							mycore_string_t *str_fname = mycss_selector_value_string(entry->value);
							hv_store_ent(data, sv_2mortal(newSVpv("value", 5)), newSVpv(str_fname->data ? str_fname->data : "", str_fname->length), 0);
						} else {
							hv_store_ent(data, sv_2mortal(newSVpv("value", 5)), newSVpv("", 0), 0);
						}
					}
					break;
					
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_DROP:
					{
						hv_store_ent(data, sv_2mortal(newSVpv("name", 4)), newSVpv("drop", 4), 0);
						mycss_selectors_function_drop_type_t drop_val = mycss_selector_value_drop(entry->value);
						
						AV *langs = newAV();
						if (drop_val & MyCSS_SELECTORS_FUNCTION_DROP_TYPE_ACTIVE)
							av_push(langs, newSVpv("active", 6));
						if (drop_val & MyCSS_SELECTORS_FUNCTION_DROP_TYPE_VALID)
							av_push(langs, newSVpv("valid", 5));
						if (drop_val & MyCSS_SELECTORS_FUNCTION_DROP_TYPE_INVALID)
							av_push(langs, newSVpv("invalid", 7));
						hv_store_ent(data, sv_2mortal(newSVpv("value", 5)), newRV_noinc((SV *) langs), 0);
					}
					break;
					
					case MyCSS_SELECTORS_SUB_TYPE_PSEUDO_CLASS_FUNCTION_LANG:
					{
						hv_store_ent(data, sv_2mortal(newSVpv("name", 4)), newSVpv("lang", 4), 0);
						AV *langs = newAV();
						if (entry->value) {
							mycss_selectors_value_lang_t *lang = mycss_selector_value_lang(entry->value);
							while (lang) {
								av_push(langs, newSVpv(lang->str.data ? lang->str.data : "", lang->str.length));
								lang = lang->next;
							}
						}
						hv_store_ent(data, sv_2mortal(newSVpv("value", 5)), newRV_noinc((SV *) langs), 0);
					}
					break;
					
					default:
						hv_store_ent(data, sv_2mortal(newSVpv("name", 4)), newSVpv("unknown", 7), 0);
					break;
				}
			}
			break;
			
			default:
				hv_store_ent(data, sv_2mortal(newSVpv("type", 4)), newSVpv("unknown", 7), 0);
			break;
		}
		
		av_push(result, newRV_noinc((SV *) data));
		
		entry = entry->next;
	}
}

MODULE = HTML5::DOM  PACKAGE = HTML5::DOM

#################################################################
# HTML5::DOM (Parser)
#################################################################
HTML5::DOM
new(SV *CLASS, HV *options = NULL)
CODE:
	DOM_GC_TRACE("DOM::new");
	mystatus_t status;
	
	html5_dom_options_t opts = {0};
	html5_dom_parse_options(&opts, NULL, options);
	html5_dom_check_options(cv, &opts);
	
	html5_dom_parser_t *self = (html5_dom_parser_t *) safemalloc(sizeof(html5_dom_parser_t));
	memset(self, 0, sizeof(html5_dom_parser_t));
	memcpy(&self->opts, &opts, sizeof(opts));
	
	self->myhtml = myhtml_create();
	
	if (self->opts.threads <= 0) {
		status = myhtml_init(self->myhtml, MyHTML_OPTIONS_PARSE_MODE_SINGLE, 1, 0);
	} else if (self->opts.threads == 1) {
		status = myhtml_init(self->myhtml, MyHTML_OPTIONS_PARSE_MODE_ALL_IN_ONE, 1, 0);
	} else {
		status = myhtml_init(self->myhtml, MyHTML_OPTIONS_PARSE_MODE_SEPARATELY, self->opts.threads, 0);
	}
	
	if (status) {
		html5_dom_parser_free(self);
		sub_croak(cv, "myhtml_init failed: %d (%s)", status, modest_strerror(status));
	}
	
	RETVAL = self;
OUTPUT:
	RETVAL

# Init html chunk parser
SV *
parseChunkStart(HTML5::DOM self, HV *options = NULL)
CODE:
	mystatus_t status;
	
	html5_dom_parse_options(&self->chunk_opts, &self->opts, options);
	html5_dom_check_options(cv, &self->chunk_opts);
	
	if (self->tree) {
		myhtml_tree_destroy(self->tree);
		self->tree = NULL;
	}
	
	self->tree = myhtml_tree_create();
	status = myhtml_tree_init(self->tree, self->myhtml);
	if (status) {
		myhtml_tree_destroy(self->tree);
		sub_croak(cv, "myhtml_tree_init failed: %d (%s)", status, modest_strerror(status));
	}
	
	self->chunks = 0;
	myhtml_encoding_set(self->tree, self->chunk_opts.encoding == MyENCODING_AUTO ? self->chunk_opts.default_encoding : self->chunk_opts.encoding);
	
	RETVAL = SvREFCNT_inc(ST(0));
OUTPUT:
	RETVAL

# Parse html chunk
SV *
parseChunk(HTML5::DOM self, SV *html, HV *options = NULL)
CODE:
	mystatus_t status;
	
	if (!self->tree) {
		self->tree = myhtml_tree_create();
		status = myhtml_tree_init(self->tree, self->myhtml);
		if (status) {
			myhtml_tree_destroy(self->tree);
			sub_croak(cv, "myhtml_tree_init failed: %d (%s)", status, modest_strerror(status));
		}
		memcpy(&self->opts, &self->chunk_opts, sizeof(html5_dom_options_t));
		myhtml_encoding_set(self->tree, self->chunk_opts.encoding == MyENCODING_AUTO ? self->chunk_opts.default_encoding : self->chunk_opts.encoding);
		self->chunks = 0;
	}
	
	STRLEN html_length;
	const char *html_str = SvPV_const(html, html_length);
	
	// Try detect encoding only in first chunk
	if (!self->chunks) {
		myhtml_encoding_set(self->tree, html5_dom_auto_encoding(&self->chunk_opts, &html_str, &html_length));
		html5_dom_apply_tree_options(self->tree, &self->chunk_opts);
	}
	
	++self->chunks;
	
	status = myhtml_parse_chunk(self->tree, html_str, html_length);
	if (status) {
		myhtml_tree_destroy(self->tree);
		sub_croak(cv, "myhtml_parse_chunk failed: %d (%s)", status, modest_strerror(status));
	}
	
	RETVAL = SvREFCNT_inc(ST(0));
OUTPUT:
	RETVAL

# End of parse chunks (return Tree)
SV *
parseChunkEnd(HTML5::DOM self)
CODE:
	mystatus_t status;
	
	if (!self->tree)
		sub_croak(cv, "call parseChunk first");
	
	status = myhtml_parse_chunk_end(self->tree);
	if (status) {
		myhtml_tree_destroy(self->tree);
		sub_croak(cv, "myhtml_parse_chunk failed:%d (%s)", status, modest_strerror(status));
	}
	
	if (!self->chunk_opts.async)
		html5_dom_wait_for_tree_done(self->tree);
	
	RETVAL = create_tree_object(self->tree, SvRV(ST(0)), self);
	self->tree = NULL;
OUTPUT:
	RETVAL

# Parse full html
SV *
parse(HTML5::DOM self, SV *html, HV *options = NULL)
CODE:
	mystatus_t status;
	html5_dom_options_t opts = {0};
	
	html5_dom_parse_options(&opts, &self->opts, options);
	html5_dom_check_options(cv, &opts);
	
	myhtml_tree_t *tree = myhtml_tree_create();
	status = myhtml_tree_init(tree, self->myhtml);
	if (status) {
		myhtml_tree_destroy(tree);
		sub_croak(cv, "myhtml_tree_init failed: %d (%s)", status, modest_strerror(status));
	}
	
	STRLEN html_length;
	const char *html_str = SvPV_const(html, html_length);
	
	myencoding_t encoding = html5_dom_auto_encoding(&opts, &html_str, &html_length);
	html5_dom_apply_tree_options(tree, &opts);
	
	status = myhtml_parse(tree, encoding, html_str, html_length);
	if (status) {
		myhtml_tree_destroy(tree);
		sub_croak(cv, "myhtml_parse failed: %d (%s)", status, modest_strerror(status));
	}
	
	if (!opts.async)
		html5_dom_wait_for_tree_done(tree);
	
	RETVAL = create_tree_object(tree, SvRV(ST(0)), self);
OUTPUT:
	RETVAL

void
DESTROY(HTML5::DOM self)
CODE:
	DOM_GC_TRACE("DOM::DESTROY (refs=%d)", SvREFCNT(SvRV(ST(0))));
	html5_dom_parser_free(self);
	safefree(self);



#################################################################
# HTML5::DOM::Tree
#################################################################
MODULE = HTML5::DOM  PACKAGE = HTML5::DOM::Tree

SV *
body(HTML5::DOM::Tree self)
CODE:
	RETVAL = node_to_sv(myhtml_tree_get_node_body(self->tree));
OUTPUT:
	RETVAL

SV *
createElement(HTML5::DOM::Tree self, SV *tag, SV *ns_name = NULL)
CODE:
	// Get namespace id by name
	myhtml_namespace_t ns = MyHTML_NAMESPACE_HTML;
	if (ns_name) {
		ns_name = sv_stringify(ns_name);
		STRLEN ns_name_len;
		const char *ns_name_str = SvPV_const(ns_name, ns_name_len);
		if (!myhtml_namespace_id_by_name(ns_name_str, ns_name_len, &ns))
			sub_croak(cv, "unknown namespace: %s", ns_name_str);
	}
	
	// Get tag id by name
	tag = sv_stringify(tag);
	STRLEN tag_len;
	const char *tag_str = SvPV_const(tag, tag_len);
	myhtml_tag_id_t tag_id = html5_dom_tag_id_by_name(self->tree, tag_str, tag_len, true);
	
	// create new node
	myhtml_tree_node_t *node = myhtml_node_create(self->tree, tag_id, ns);
	
	// if void - mark self-closed
	if (myhtml_node_is_void_element(node)) {
		if (!node->token) {
			node->token = myhtml_token_node_create(node->tree->token, self->tree->mcasync_rules_token_id);
			if (!node->token) {
				myhtml_tree_node_delete(node);
				sub_croak(cv, "myhtml_token_node_create failed");
			}
		}
		node->token->type |= MyHTML_TOKEN_TYPE_CLOSE_SELF | MyHTML_TOKEN_TYPE_DONE;
	}
	
	RETVAL = node_to_sv(node);
OUTPUT:
	RETVAL

SV *
createComment(HTML5::DOM::Tree self, SV *text)
CODE:
	text = sv_stringify(text);
	STRLEN text_len;
	const char *text_str = SvPV_const(text, text_len);
	myhtml_tree_node_t *node = myhtml_node_create(self->tree, MyHTML_TAG__COMMENT, MyHTML_NAMESPACE_HTML);
	myhtml_node_text_set(node, text_str, text_len, MyENCODING_DEFAULT);
	RETVAL = node_to_sv(node);
OUTPUT:
	RETVAL

SV *
createTextNode(HTML5::DOM::Tree self, SV *text)
CODE:
	text = sv_stringify(text);
	STRLEN text_len;
	const char *text_str = SvPV_const(text, text_len);
	myhtml_tree_node_t *node = myhtml_node_create(self->tree, MyHTML_TAG__TEXT, MyHTML_NAMESPACE_HTML);
	myhtml_node_text_set(node, text_str, text_len, MyENCODING_DEFAULT);
	RETVAL = node_to_sv(node);
OUTPUT:
	RETVAL

# Parse fragment
SV *parseFragment(HTML5::DOM::Tree self, SV *text, SV *tag = NULL, SV *ns = NULL, HV *options = NULL)
CODE:
	text = sv_stringify(text);
	STRLEN text_len;
	const char *text_str = SvPV_const(text, text_len);
	
	mystatus_t status;
	myhtml_namespace_t ns_id = MyHTML_NAMESPACE_HTML;
	myhtml_tag_id_t tag_id = MyHTML_TAG_DIV;
	
	if (ns) {
		ns = sv_stringify(ns);
		STRLEN ns_len;
		const char *ns_str = SvPV_const(ns, ns_len);
		
		if (!myhtml_namespace_id_by_name(ns_str, ns_len, &ns_id))
			sub_croak(cv, "unknown namespace: %s", ns_str);
	}
	
	if (tag) {
		tag = sv_stringify(tag);
		STRLEN tag_len;
		const char *tag_str = SvPV_const(tag, tag_len);
		tag_id = html5_dom_tag_id_by_name(self->tree, tag_str, tag_len, true);
	}
	
	html5_dom_options_t opts = {0};
	html5_dom_parse_options(&opts, &self->parser->opts, options);
	html5_dom_check_options(cv, &opts);
	
	myhtml_tree_node_t *node = html5_dom_parse_fragment(&opts, self->tree, tag_id, ns_id, text_str, text_len, NULL, &status);
	if (status)
		sub_croak(cv, "myhtml_parse_fragment failed: %d (%s)", status, modest_strerror(status));
	
	RETVAL = node_to_sv(node);
OUTPUT:
	RETVAL

SV *
head(HTML5::DOM::Tree self)
CODE:
	RETVAL = node_to_sv(myhtml_tree_get_node_head(self->tree));
OUTPUT:
	RETVAL

SV *
root(HTML5::DOM::Tree self)
CODE:
	RETVAL = node_to_sv(myhtml_tree_get_node_html(self->tree));
OUTPUT:
	RETVAL

SV *
document(HTML5::DOM::Tree self)
CODE:
	RETVAL = node_to_sv(myhtml_tree_get_document(self->tree));
OUTPUT:
	RETVAL

SV *
find(HTML5::DOM::Tree self, SV *query, SV *combinator = NULL)
ALIAS:
	at					= 1
	querySelector		= 2
	querySelectorAll	= 3
CODE:
	myhtml_tree_node_t *scope = myhtml_tree_get_document(self->tree);
	if (scope) {
		RETVAL = html5_node_find(cv, self->parser, scope, query, combinator, ix == 1 || ix == 2);
	} else {
		RETVAL = &PL_sv_undef;
	}
OUTPUT:
	RETVAL

# Wait for parsing done (when async mode)
SV *
wait(HTML5::DOM::Tree self)
CODE:
	html5_dom_wait_for_tree_done(self->tree);
	RETVAL = SvREFCNT_inc(ST(0));
OUTPUT:
	RETVAL

# True if parsing done (when async mode)
int
parsed(HTML5::DOM::Tree self)
CODE:
	RETVAL = html5_dom_tree_is_done(self->tree);
OUTPUT:
	RETVAL

# findTag(val), getElementsByTagName(val)									- get nodes by tag name
# findClass(val), getElementsByClassName(val)								- get nodes by class name
# findId(val), getElementById(val)											- get node by id
# findAttr(key), getElementByAttribute(key)									- get nodes by attribute key
# findAttr(key, val, case, cmp), getElementByAttribute(key, val, case, cmp)	- get nodes by attribute value
SV *
findTag(HTML5::DOM::Tree self, SV *key, SV *val = NULL, bool icase = false, SV *cmp = NULL)
ALIAS:
	getElementsByTagName	= 1
	findClass				= 2
	getElementsByClassName	= 3
	findId					= 4
	getElementById			= 5
	findAttr				= 6
	getElementByAttribute	= 7
CODE:
	RETVAL = html5_node_simple_find(cv, myhtml_tree_get_document(self->tree), key, val, cmp, icase, ix);
OUTPUT:
	RETVAL

# Get compat node
SV *
compatMode(HTML5::DOM::Tree self)
CODE:
	if (self->tree->compat_mode == MyHTML_TREE_COMPAT_MODE_QUIRKS) {
		// if the document is in quirks mode.
		RETVAL = newSVpv("BackCompat", 10);
	} else {
		// if the document is in no-quirks (also known as "standards") mode or limited-quirks (also known as "almost standards") mode.
		RETVAL = newSVpv("CSS1Compat", 10);
	}
OUTPUT:
	RETVAL

# Get current tree encoding name
SV *
encoding(HTML5::DOM::Tree self)
CODE:
	size_t length = 0;
	const char *name = myencoding_name_by_id(self->tree->encoding, &length);
	RETVAL = newSVpv(name ? name : "", length);
OUTPUT:
	RETVAL

# Get current tree encoding id
SV *
encodingId(HTML5::DOM::Tree self)
CODE:
	RETVAL = newSViv(self->tree->encoding);
OUTPUT:
	RETVAL

# Tag id by tag name
SV *
tag2id(HTML5::DOM::Tree self, SV *tag)
CODE:
	tag = sv_stringify(tag);
	STRLEN tag_len;
	const char *tag_str = SvPV_const(tag, tag_len);
	RETVAL = newSViv(html5_dom_tag_id_by_name(self->tree, tag_str, tag_len, false));
OUTPUT:
	RETVAL

# Tag name by tag id
SV *
id2tag(HTML5::DOM::Tree self, int tag_id)
CODE:
	RETVAL = &PL_sv_undef;
	const myhtml_tag_context_t *tag_ctx = myhtml_tag_get_by_id(self->tree->tags, tag_id);
	if (tag_ctx)
		RETVAL = newSVpv(tag_ctx->name ? tag_ctx->name : "", tag_ctx->name_length);
OUTPUT:
	RETVAL

# Namespace id by namepsace name
SV *
namespace2id(HTML5::DOM::Tree self, SV *ns)
CODE:
	ns = sv_stringify(ns);
	STRLEN ns_len;
	const char *ns_str = SvPV_const(ns, ns_len);
	
	myhtml_namespace_t ns_id;
	if (!myhtml_namespace_id_by_name(ns_str, ns_len, &ns_id))
		ns_id = MyHTML_NAMESPACE_UNDEF;
	
	RETVAL = newSViv(ns_id);
OUTPUT:
	RETVAL

# Namespace name by namepsace id
SV *
id2namespace(HTML5::DOM::Tree self, int ns_id)
CODE:
	size_t ns_len = 0;
	const char *ns_name = myhtml_namespace_name_by_id(ns_id, &ns_len);
	RETVAL = ns_name ? newSVpv(ns_name, ns_len) : &PL_sv_undef;
OUTPUT:
	RETVAL

# Return tree parent parser
SV *
parser(HTML5::DOM::Tree self)
CODE:
	RETVAL = myhtml_to_sv(self->tree);
OUTPUT:
	RETVAL

# Some bad idea to get "uniq id"
SV *
hash(HTML5::DOM::Node self)
CODE:
	RETVAL = newSViv(PTR2IV(self));
OUTPUT:
	RETVAL

# Compare tree reference
bool
isSameTree(HTML5::DOM::Tree self, SV *other_tree)
CODE:
	RETVAL = false;
	if (sv_derived_from(other_tree, "HTML5::DOM::Tree")) {
		html5_dom_tree_t *tree = INT2PTR(html5_dom_tree_t *, SvIV((SV*)SvRV(other_tree)));
		if (tree == self)
			RETVAL = true;
	}
OUTPUT:
	RETVAL

void
DESTROY(HTML5::DOM::Tree self)
CODE:
	DOM_GC_TRACE("DOM::Tree::DESTROY (refs=%d)", SvREFCNT(SvRV(ST(0))));
	void *context = self->tree->context;
	myhtml_tree_destroy(self->tree);
	SvREFCNT_dec(self->parent);
	safefree(context);



#################################################################
# HTML5::DOM::Node
#################################################################
MODULE = HTML5::DOM  PACKAGE = HTML5::DOM::Node
# Tag id
SV *
tagId(HTML5::DOM::Node self, SV *new_tag_id = NULL)
CODE:
	if (new_tag_id) {
		const myhtml_tag_context_t *tag_ctx = myhtml_tag_get_by_id(self->tree->tags, SvIV(new_tag_id));
		if (tag_ctx) {
			self->tag_id = SvIV(new_tag_id);
		} else {
			sub_croak(cv, "unknown tag id %ld", SvIV(new_tag_id));
		}
		
		RETVAL = SvREFCNT_inc(ST(0));
	} else {
		RETVAL = newSViv(self->tag_id);
	}
OUTPUT:
	RETVAL

# Namespace id
SV *
namespaceId(HTML5::DOM::Node self, SV *new_ns_id = NULL)
CODE:
	if (new_ns_id) {
		if (!myhtml_namespace_name_by_id(SvIV(new_ns_id), NULL)) {
			sub_croak(cv, "unknown namespace id %ld", SvIV(new_ns_id));
		} else {
			myhtml_node_namespace_set(self, SvIV(new_ns_id));
		}
		RETVAL = SvREFCNT_inc(ST(0));
	} else {
		RETVAL = newSViv(myhtml_node_namespace(self));
	}
OUTPUT:
	RETVAL

# Tag name
SV *
tag(HTML5::DOM::Node self, SV *new_tag_name = NULL)
ALIAS:
	nodeName	= 1
	tagName		= 2
CODE:
	myhtml_tree_t *tree = self->tree;
	
	// Set new tag name
	if (new_tag_name) {
		new_tag_name = sv_stringify(new_tag_name);
		STRLEN new_tag_name_len;
		const char *new_tag_name_str = SvPV_const(new_tag_name, new_tag_name_len);
		
		if (!new_tag_name_len)
			sub_croak(cv, "empty tag name not allowed.");
		
		myhtml_tag_id_t tag_id = html5_dom_tag_id_by_name(self->tree, new_tag_name_str, new_tag_name_len, true);
		self->tag_id = tag_id;
		
		RETVAL = SvREFCNT_inc(ST(0));
	}
	// Get tag name
	else {
		RETVAL = &PL_sv_undef;
		
		if (tree && tree->tags) {
			const myhtml_tag_context_t *tag_ctx = myhtml_tag_get_by_id(tree->tags, self->tag_id);
			if (tag_ctx) {
				RETVAL = newSVpv(tag_ctx->name, tag_ctx->name_length);
				if (ix == 1 || ix == 2) {
					STRLEN value_len;
					char *value = SvPV(RETVAL, value_len);
					for (size_t i = 0; i < value_len; ++i)
						value[i] = toupper(value[i]);
				}
			}
		}
	}
OUTPUT:
	RETVAL

# Namespace name
SV *
namespace(HTML5::DOM::Node self, SV *new_ns = NULL)
CODE:
	myhtml_tree_t *tree = self->tree;
	
	// Set new tag namespace
	if (new_ns) {
		new_ns = sv_stringify(new_ns);
		STRLEN new_ns_len;
		const char *new_ns_str = SvPV_const(new_ns, new_ns_len);
		
		myhtml_namespace_t ns;
		if (!myhtml_namespace_id_by_name(new_ns_str, new_ns_len, &ns))
			sub_croak(cv, "unknown namespace: %s", new_ns_str);
		myhtml_node_namespace_set(self, ns);
		
		RETVAL = SvREFCNT_inc(ST(0));
	}
	// Get namespace name
	else {
		size_t ns_name_len;
		const char *ns_name = myhtml_namespace_name_by_id(myhtml_node_namespace(self), &ns_name_len);
		RETVAL = newSVpv(ns_name ? ns_name : "", ns_name_len);
	}
OUTPUT:
	RETVAL

# Return node parent tree
SV *
tree(HTML5::DOM::Node self)
CODE:
	RETVAL = tree_to_sv(self->tree);
OUTPUT:
	RETVAL

# Non-recursive html serialization (example: <div id="some_id">)
SV *
nodeHtml(HTML5::DOM::Node self)
CODE:
	RETVAL = newSVpv("", 0);
	myhtml_serialization_node_callback(self, sv_serialization_callback, RETVAL);
OUTPUT:
	RETVAL

# Return node type
int
nodeType(HTML5::DOM::Node self)
CODE:
	html5_dom_tree_t *context = (html5_dom_tree_t *) self->tree->context;
	RETVAL = 0;
	if (self->tag_id != MyHTML_TAG__UNDEF) {
		if (self->tag_id == MyHTML_TAG__TEXT) {
			RETVAL = TEXT_NODE;
		} else if (self->tag_id == MyHTML_TAG__COMMENT) {
			RETVAL = COMMENT_NODE;
		} else if (self->tag_id == MyHTML_TAG__DOCTYPE) {
			RETVAL = DOCUMENT_TYPE_NODE;
		} else if (context->fragment_tag_id && self->tag_id == context->fragment_tag_id) {
			RETVAL = DOCUMENT_FRAGMENT_NODE;
		} else {
			RETVAL = ELEMENT_NODE;
		}
	} else {
		// Modest myhtml bug - document node has tag_id == MyHTML_TAG__UNDEF
		if (node_is_document(self))
			RETVAL = DOCUMENT_NODE;
	}
OUTPUT:
	RETVAL

# Node::html()			- Serialize text/comment node to html
# Node::html(text)		- Same as Node::nodeValue(text)
# Element::html(text)	- Remove all children nodes and add parsed fragment, return self
SV *
html(HTML5::DOM::Node self, SV *text = NULL)
ALIAS:
	innerHTML	= 1
	outerHTML	= 2
CODE:
	if (text) {
		if (ix == 2 && !myhtml_node_parent(self)) // outerHTML
			sub_croak(cv, "This element has no parent node.");
		
		text = sv_stringify(text);
		STRLEN text_len;
		const char *text_str = SvPV_const(text, text_len);
		
		if (node_is_element(self) || node_is_document(self)) { // parse fragment and replace all node childrens with it
			// parse fragment
			mystatus_t status;
			html5_fragment_parts_t parts = {0};
			myhtml_tree_node_t *context_node = ix == 2 ? myhtml_node_parent(self) : self;
			myhtml_tag_id_t context_tag_id = context_node->tag_id;
			
			// hack for document node
			if (node_is_document(context_node))
				context_tag_id = MyHTML_TAG_HTML;
			
			html5_dom_tree_t *tree_context = (html5_dom_tree_t *) self->tree->context;
			html5_dom_options_t opts = {0};
			html5_dom_parse_options(&opts, &tree_context->parser->opts, NULL);
			
			// force set encoding to UTF-8
			opts.encoding			= MyENCODING_DEFAULT;
			opts.default_encoding	= MyENCODING_DEFAULT;
			opts.async				= false;
			
			myhtml_tree_node_t *fragment = html5_dom_parse_fragment(&opts, self->tree, context_tag_id, myhtml_node_namespace(context_node), text_str, text_len, &parts, &status);
			if (status)
				sub_croak(cv, "myhtml_parse_fragment failed: %d (%s)", status, modest_strerror(status));
			
			// remove all child nodes
			myhtml_tree_node_t *node = myhtml_node_child(self);
			while (node) {
				myhtml_tree_node_t *next = myhtml_node_next(node);
				myhtml_tree_node_remove(node);
				html5_tree_node_delete_recursive(node);
				node = next;
			}
			
			// cleanup references in tree
			if (node_is_root(self)) {
				self->tree->node_body = parts.node_body;
				self->tree->node_head = parts.node_head;
			} else if (node_is_document(self)) {
				self->tree->node_html = parts.node_html;
				self->tree->node_body = parts.node_body;
				self->tree->node_head = parts.node_head;
			}
			
			if (fragment != self->tree->node_html) {
				// add fragment
				node = myhtml_node_child(fragment);
				while (node) {
					myhtml_tree_node_t *next = myhtml_node_next(node);
					myhtml_tree_node_remove(node);
					if (ix == 2) { // outerHTML
						myhtml_tree_node_insert_before(self, node);
					} else { // innerHTML
						myhtml_tree_node_add_child(self, node);
					}
					node = next;
				}
				
				// remove self if outerHTML
				if (ix == 2)
					myhtml_tree_node_remove(self);
				
				// free fragment
				html5_tree_node_delete_recursive(fragment);
			} else {
				// fragment now is html node, why not?
				fragment->tag_id = MyHTML_TAG_HTML;
				myhtml_tree_node_remove(fragment);
				myhtml_tree_node_add_child(self, fragment);
			}
		} else { // same as nodeValue, for user friendly API
			myhtml_node_text_set(self, text_str, text_len, MyENCODING_DEFAULT);
		}
		RETVAL = SvREFCNT_inc(ST(0));
	} else {
		RETVAL = newSVpv("", 0);
		if (self->tag_id == MyHTML_TAG__UNDEF || ix == 1 || html5_dom_is_fragment(self)) { // innerHTML
			myhtml_tree_node_t *node = myhtml_node_child(self);
			while (node) {
				myhtml_serialization_tree_callback(node, sv_serialization_callback, RETVAL);
				node = myhtml_node_next(node);
			}
		} else { // outerHTML
			myhtml_serialization_tree_callback(self, sv_serialization_callback, RETVAL);
		}
	}
OUTPUT:
	RETVAL

# Node::text()			- Serialize tree to text
# Node::text(text)		- Set node value, return self
# Element::text(text)	- Remove all children nodes and add text node, return self
SV *
text(HTML5::DOM::Node self, SV *text = NULL)
ALIAS:
	nodeValue		= 1
	innerText		= 2
	textContent		= 3
	data			= 4
	outerText		= 5
CODE:
	static const char names[][16] = {
		"text", "nodeValue", "innerText", "textContent", "data", "outerText"
	};
	
	myhtml_tree_t *tree = self->tree;
	if (!node_is_element(self)) {
		if (ix == 2 || ix == 3 || ix == 5) {
			if (text) {
				sub_croak(cv, "%s unsupported in %s", names[ix], get_node_class(self));
			} else {
				RETVAL = &PL_sv_undef;
			}
		} else if (text) { // set node value
			text = sv_stringify(text);
			STRLEN text_len;
			const char *text_str = SvPV_const(text, text_len);
			
			myhtml_node_text_set(self, text_str, text_len, MyENCODING_DEFAULT);
			RETVAL = SvREFCNT_inc(ST(0));
		} else { // get node value
			size_t text_len = 0;
			const char *text = myhtml_node_text(self, &text_len);
			RETVAL = newSVpv(text ? text : "", text_len);
		}
	} else {
		if (ix == 1 || ix == 4) {
			if (text) {
				sub_croak(cv, "%s unsupported in %s", names[ix], get_node_class(self));
			} else {
				RETVAL = &PL_sv_undef;
			}
		} else if (text) { // remove all childrens and add text node
			text = sv_stringify(text);
			STRLEN text_len;
			const char *text_str = SvPV_const(text, text_len);
			
			// remove all children nodes
			myhtml_tree_node_t *node = myhtml_node_child(self);
			while (node) {
				myhtml_tree_node_t *next = myhtml_node_next(node);
				myhtml_tree_node_remove(node);
				html5_tree_node_delete_recursive(node);
				node = next;
			}
			
			// cleanup references in tree
			if (node_is_root(self)) {
				self->tree->node_body = NULL;
				self->tree->node_head = NULL;
			} else if (node_is_document(self)) {
				self->tree->node_html = NULL;
				self->tree->node_body = NULL;
				self->tree->node_head = NULL;
			}
			
			// innerText, outerText
			if (ix == 2 || ix == 5) {
				size_t last_pos = 0;
				for (size_t i = 0; i < text_len; ++i) {
					bool is_end = (i >= text_len - 1);
					bool is_new_line = (text_str[i] == '\n' || text_str[i] == '\r');
					if (is_end || is_new_line) {
						if (is_end && !is_new_line)
							++i;
						
						// insert new text node
						if (i - last_pos) {
							myhtml_tree_node_t *text_node = myhtml_node_create(self->tree, MyHTML_TAG__TEXT, myhtml_node_namespace(self));
							myhtml_node_text_set(text_node, &text_str[last_pos], i - last_pos, MyENCODING_DEFAULT);
							if (ix == 5) { // outerText
								myhtml_tree_node_insert_before(self, text_node);
							} else { // innerText
								myhtml_tree_node_add_child(self, text_node);
							}
						}
						
						// insert new br
						if (is_new_line) {
							myhtml_tree_node_t *text_node = myhtml_node_create(self->tree, MyHTML_TAG_BR, myhtml_node_namespace(self));
							if (!text_node->token) {
								text_node->token = myhtml_token_node_create(self->tree->token, self->tree->mcasync_rules_token_id);
								if (!text_node->token) {
									myhtml_tree_node_delete(text_node);
									sub_croak(cv, "myhtml_token_node_create failed");
								}
								text_node->token->type |= MyHTML_TOKEN_TYPE_CLOSE_SELF | MyHTML_TOKEN_TYPE_DONE;
							}
							
							if (ix == 5) { // outerText
								myhtml_tree_node_insert_before(self, text_node);
							} else { // innerText
								myhtml_tree_node_add_child(self, text_node);
							}
						}
						
						if (!is_end) {
							if (text_str[i] == '\r' && text_str[i + 1] == '\n')
								++i;
							last_pos = i + 1;
						}
					}
				}
			}
			// text, textContent
			else {
				myhtml_tree_node_t *text_node = myhtml_node_create(self->tree, MyHTML_TAG__TEXT, myhtml_node_namespace(self));
				myhtml_node_text_set(text_node, text_str, text_len, MyENCODING_DEFAULT);
				myhtml_tree_node_add_child(self, text_node);
			}
			
			RETVAL = SvREFCNT_inc(ST(0));
			
			if (ix == 5) {
				// remove self, if outerText
				myhtml_tree_node_remove(self);
			}
		} else { // recursive serialize node to text
			// innerText, outerText
			if (ix == 2 || ix == 5) {
				html5_dom_inner_text_state_t state = {0};
				state.last_br = true;
				state.new_line = true;
				
				mycore_string_init(self->tree->mchar, self->tree->mchar_node_id, &state.value, 1);
				
				myhtml_tree_node_t *next = myhtml_node_child(self);
				while (next) {
					html5_dom_recursive_node_inner_text(next, &state);
					next = myhtml_node_next(next);
				}
				html5_dom_rtrim_mystring(&state.value, ' ');
				
				RETVAL = newSVpv(state.value.data ? state.value.data : "", state.value.length);
				mycore_string_destroy(&state.value, 0);
			}
			// text, textContent
			else {
				RETVAL = newSVpv("", 0);
				html5_dom_recursive_node_text(self, RETVAL);
			}
		}
	}
OUTPUT:
	RETVAL

# Wait for node parsing done (when async mode)
SV *
wait(HTML5::DOM::Node self, bool deep = false)
CODE:
	html5_dom_wait_for_done(self, deep);
	RETVAL = SvREFCNT_inc(ST(0));
OUTPUT:
	RETVAL

# True if node parsing done (when async mode)
int
parsed(HTML5::DOM::Node self, bool deep = false)
CODE:
	RETVAL = html5_dom_is_done(self, deep);
OUTPUT:
	RETVAL

# Next element
SV *
next(HTML5::DOM::Node self)
ALIAS:
	nextElementSibling	= 1
CODE:
	myhtml_tree_node_t *node = myhtml_node_next(self);
	while (node && !node_is_element(node))
		node = myhtml_node_next(node);
	RETVAL = node_to_sv(node);
OUTPUT:
	RETVAL

# Next node
SV *
nextNode(HTML5::DOM::Node self)
ALIAS:
	nextSibling	= 1
CODE:
	RETVAL = node_to_sv(myhtml_node_next(self));
OUTPUT:
	RETVAL

# Prev element
SV *
prev(HTML5::DOM::Node self)
ALIAS:
	previousElementSibling	= 1
CODE:
	myhtml_tree_node_t *node = myhtml_node_prev(self);
	while (node && !node_is_element(node))
		node = myhtml_node_prev(node);
	RETVAL = node_to_sv(node);
OUTPUT:
	RETVAL

# Prev node
SV *
prevNode(HTML5::DOM::Node self)
ALIAS:
	previousSibling	= 1
CODE:
	RETVAL = node_to_sv(myhtml_node_prev(self));
OUTPUT:
	RETVAL

# Parent node
SV *
parent(HTML5::DOM::Node self)
ALIAS:
	isConnected		= 1
	parentNode		= 2
	parentElement	= 3
CODE:
	RETVAL = ix == 1 ? newSViv(myhtml_node_parent(self) ? 1 : 0) : node_to_sv(myhtml_node_parent(self));
OUTPUT:
	RETVAL

# Owner document
SV *
document(HTML5::DOM::Node self)
ALIAS:
	ownerDocument	= 1
CODE:
	RETVAL = node_to_sv(myhtml_tree_get_document(self->tree));
OUTPUT:
	RETVAL

# Remove node from tree
SV *
remove(HTML5::DOM::Node self, HTML5::DOM::Node node = NULL)
ALIAS:
	removeChild	= 1
CODE:
	if (ix == 1) {
		if (!node)
			sub_croak(cv, "%s is not of type %s", "node", "HTML5::DOM::Node");
		if (node->parent != self)
			sub_croak(cv, "The node to be removed is not a child of this node.");
		RETVAL = node_to_sv(myhtml_tree_node_remove(node));
	} else {
		RETVAL = node_to_sv(myhtml_tree_node_remove(self));
	}
OUTPUT:
	RETVAL

# Append child to parent before current node
SV *
before(HTML5::DOM::Node self, HTML5::DOM::Node a, HTML5::DOM::Node b = NULL)
ALIAS:
	insertBefore	= 1
CODE:
	myhtml_tree_node_t *reference_node, *new_node;
	
	if (ix == 1) {
		new_node = a;
		reference_node = b;
		
		if (!reference_node)
			sub_croak(cv, "%s is not of type %s", "reference_node", "HTML5::DOM::Node");
		if (reference_node->parent != self)
			sub_croak(cv, "The node before which the new node is to be inserted is not a child of this node.");
	} else {
		new_node = a;
		reference_node = self;
	}
	
	if (!myhtml_node_parent(reference_node))
		sub_croak(cv, "can't insert before detached node");
	
	if (reference_node->tree != new_node->tree) {
		myhtml_tree_node_remove(new_node);
		new_node = html5_dom_recursive_clone_node(reference_node->tree, new_node, NULL);
		if (!new_node)
			sub_croak(cv, "node copying internal error");
	}
	
	if (html5_dom_is_fragment(new_node)) {
		myhtml_tree_node_t *fragment_child = myhtml_node_child(new_node);
		while (fragment_child) {
			myhtml_tree_node_t *next = myhtml_node_next(fragment_child);
			myhtml_tree_node_remove(fragment_child);
			myhtml_tree_node_insert_before(reference_node, fragment_child);
			fragment_child = next;
		}
	} else {
		myhtml_tree_node_remove(new_node);
		myhtml_tree_node_insert_before(reference_node, new_node);
	}
	
	if (ix == 1) {
		RETVAL = node_to_sv(new_node);
	} else {
		RETVAL = SvREFCNT_inc(ST(0));
	}
OUTPUT:
	RETVAL

# Append child to parent after current node
SV *
after(HTML5::DOM::Node self, HTML5::DOM::Node a, HTML5::DOM::Node b = NULL)
ALIAS:
	insertAfter	= 1
CODE:
	myhtml_tree_node_t *reference_node, *new_node;
	
	if (ix == 1) {
		new_node = a;
		reference_node = b;
		
		if (!reference_node)
			sub_croak(cv, "%s is not of type %s", "reference_node", "HTML5::DOM::Node");
		if (reference_node->parent != self)
			sub_croak(cv, "The node after which the new node is to be inserted is not a child of this node.");
	} else {
		new_node = a;
		reference_node = self;
	}
	
	if (!myhtml_node_parent(reference_node))
		sub_croak(cv, "can't insert before detached node");
	
	if (reference_node->tree != new_node->tree) {
		myhtml_tree_node_remove(new_node);
		new_node = html5_dom_recursive_clone_node(reference_node->tree, new_node, NULL);
		if (!new_node)
			sub_croak(cv, "node copying internal error");
	}
	
	if (html5_dom_is_fragment(new_node)) {
		myhtml_tree_node_t *fragment_child = myhtml_node_last_child(new_node);
		while (fragment_child) {
			myhtml_tree_node_t *next = myhtml_node_prev(fragment_child);
			myhtml_tree_node_remove(fragment_child);
			myhtml_tree_node_insert_after(reference_node, fragment_child);
			fragment_child = next;
		}
	} else {
		myhtml_tree_node_remove(new_node);
		myhtml_tree_node_insert_after(reference_node, new_node);
	}
	
	if (ix == 1) {
		RETVAL = node_to_sv(new_node);
	} else {
		RETVAL = SvREFCNT_inc(ST(0));
	}
OUTPUT:
	RETVAL

# Append node child
SV *
append(HTML5::DOM::Node self, HTML5::DOM::Node child)
ALIAS:
	appendChild	= 1
CODE:
	if (!node_is_element(self))
		sub_croak(cv, "can't append children to non-element node");
	
	if (self->tree != child->tree) {
		myhtml_tree_node_remove(child);
		child = html5_dom_recursive_clone_node(self->tree, child, NULL);
		if (!child)
			sub_croak(cv, "node copying internal error");
	}
	
	if (html5_dom_is_fragment(child)) {
		myhtml_tree_node_t *fragment_child = myhtml_node_child(child);
		while (fragment_child) {
			myhtml_tree_node_t *next = myhtml_node_next(fragment_child);
			myhtml_tree_node_remove(fragment_child);
			myhtml_tree_node_add_child(self, fragment_child);
			fragment_child = next;
		}
	} else {
		myhtml_tree_node_remove(child);
		myhtml_tree_node_add_child(self, child);
	}
	
	if (ix == 1) {
		RETVAL = node_to_sv(child);
	} else {
		RETVAL = SvREFCNT_inc(ST(0));
	}
OUTPUT:
	RETVAL

# Prepend node child
SV *
prepend(HTML5::DOM::Node self, HTML5::DOM::Node child)
ALIAS:
	prependChild	= 1
CODE:
	if (!node_is_element(self))
		sub_croak(cv, "can't prepend children to non-element node");
	
	if (self->tree != child->tree) {
		myhtml_tree_node_remove(child);
		child = html5_dom_recursive_clone_node(self->tree, child, NULL);
		if (!child)
			sub_croak(cv, "node copying internal error");
	}
	
	myhtml_tree_node_t *first_node = myhtml_node_child(self);
	if (html5_dom_is_fragment(child)) {
		myhtml_tree_node_t *fragment_child = myhtml_node_child(child);
		while (fragment_child) {
			myhtml_tree_node_t *next = myhtml_node_next(fragment_child);
			myhtml_tree_node_remove(fragment_child);
			if (first_node) {
				myhtml_tree_node_insert_before(first_node, fragment_child);
			} else {
				myhtml_tree_node_add_child(self, fragment_child);
			}
			fragment_child = next;
		}
	} else {
		myhtml_tree_node_remove(child);
		if (first_node) {
			myhtml_tree_node_insert_before(first_node, child);
		} else {
			myhtml_tree_node_add_child(self, child);
		}
	}
	
	if (ix == 1) {
		RETVAL = node_to_sv(child);
	} else {
		RETVAL = SvREFCNT_inc(ST(0));
	}
OUTPUT:
	RETVAL

# Replace node with child
SV *
replace(HTML5::DOM::Node self, HTML5::DOM::Node a, HTML5::DOM::Node b = NULL)
ALIAS:
	replaceChild	= 1
CODE:
	myhtml_tree_node_t *old_node, *new_node;
	
	if (ix == 1) {
		new_node = a;
		old_node = b;
		
		if (!old_node)
			sub_croak(cv, "%s is not of type %s", "old_node", "HTML5::DOM::Node");
		if (old_node->parent != self)
			sub_croak(cv, "The node to be replaced is not a child of this node.");
	} else {
		new_node = a;
		old_node = self;
	}
	
	if (old_node->tree != new_node->tree) {
		myhtml_tree_node_remove(new_node);
		new_node = html5_dom_recursive_clone_node(old_node->tree, new_node, NULL);
		if (!new_node)
			sub_croak(cv, "node copying internal error");
	}
	
	if (html5_dom_is_fragment(new_node)) {
		myhtml_tree_node_t *fragment_child = myhtml_node_child(new_node);
		while (fragment_child) {
			myhtml_tree_node_t *fragment_child = myhtml_node_child(new_node);
			while (fragment_child) {
				myhtml_tree_node_t *next = myhtml_node_next(fragment_child);
				myhtml_tree_node_remove(fragment_child);
				myhtml_tree_node_insert_before(old_node, fragment_child);
				fragment_child = next;
			}
		}
	} else {
		myhtml_tree_node_remove(new_node);
		myhtml_tree_node_insert_before(old_node, new_node);
	}
	
	myhtml_tree_node_remove(old_node);
	
	RETVAL = (ix == 1 ? node_to_sv(old_node) : SvREFCNT_inc(ST(0)));
OUTPUT:
	RETVAL

# Clone node
SV *
clone(HTML5::DOM::Node self, bool deep = false, HTML5::DOM::Tree new_tree = NULL)
ALIAS:
	cloneNode	= 1
CODE:
	myhtml_tree_t *tree = new_tree ? new_tree->tree : self->tree;
	if (deep) {
		RETVAL = node_to_sv(html5_dom_recursive_clone_node(tree, self, NULL));
	} else {
		RETVAL = node_to_sv(html5_dom_copy_foreign_node(tree, self));
	}
OUTPUT:
	RETVAL

# True if node is void
bool
void(HTML5::DOM::Node self)
CODE:
	RETVAL = myhtml_node_is_void_element(self);
OUTPUT:
	RETVAL

# True if node is self-closed
bool
selfClosed(HTML5::DOM::Node self)
CODE:
	RETVAL = myhtml_node_is_close_self(self);
OUTPUT:
	RETVAL

# Node position in text input
SV *
position(HTML5::DOM::Node self)
CODE:
	HV *hash = newHV();
	hv_store_ent(hash, sv_2mortal(newSVpv("raw_begin", 9)), newSViv(self->token ? self->token->raw_begin : 0), 0);
	hv_store_ent(hash, sv_2mortal(newSVpv("raw_length", 10)), newSViv(self->token ? self->token->raw_length : 0), 0);
	hv_store_ent(hash, sv_2mortal(newSVpv("element_begin", 13)), newSViv(self->token ? self->token->element_begin : 0), 0);
	hv_store_ent(hash, sv_2mortal(newSVpv("element_length", 14)), newSViv(self->token ? self->token->element_length : 0), 0);
	RETVAL = newRV_noinc((SV *) hash);
OUTPUT:
	RETVAL

# Some bad idea to get "uniq id"
SV *
hash(HTML5::DOM::Node self)
CODE:
	RETVAL = newSViv(PTR2IV(self));
OUTPUT:
	RETVAL

# Compare node reference
bool
isSameNode(HTML5::DOM::Node self, SV *other_node)
CODE:
	RETVAL = false;
	if (sv_derived_from(other_node, "HTML5::DOM::Node")) {
		myhtml_tree_node_t *node = INT2PTR(myhtml_tree_node_t *, SvIV((SV*)SvRV(other_node)));
		if (node == self)
			RETVAL = true;
	}
OUTPUT:
	RETVAL

void
DESTROY(HTML5::DOM::Node self)
CODE:
	SV *sv = (SV *) myhtml_node_get_data(self);
	
	DOM_GC_TRACE("DOM::Node::DESTROY (refcnt=%d)", sv ? SvREFCNT(sv) : -666);
	
	if (sv) {
		html5_dom_tree_t *tree = (html5_dom_tree_t *) self->tree->context;
		myhtml_node_set_data(self, NULL);
		// detached node, can be deleted
		if (!myhtml_node_parent(self) && self != myhtml_tree_get_document(self->tree)) {
			if (self == self->tree->node_html) {
				self->tree->node_html = NULL;
			} else if (self == self->tree->node_body) {
				self->tree->node_body = NULL;
			} else if (self == self->tree->node_head) {
				self->tree->node_head = NULL;
			} else if (self == self->tree->node_form) {
				self->tree->node_form = NULL;
			} else if (self == self->tree->fragment) {
				self->tree->fragment = NULL;
			} else if (self == self->tree->document) {
				self->tree->document = NULL;
			}
			DOM_GC_TRACE("=> DOM::Node::FREE");
			html5_tree_node_delete_recursive(self);
		}
		SvREFCNT_dec(tree->sv);
	}

#################################################################
# HTML5::DOM::Element (extends Node)
#################################################################
MODULE = HTML5::DOM  PACKAGE = HTML5::DOM::Element
# Find by css query
SV *
find(HTML5::DOM::Element self, SV *query, SV *combinator = NULL)
ALIAS:
	at					= 1
	querySelector		= 2
	querySelectorAll	= 3
CODE:
	html5_dom_tree_t *tree_context = (html5_dom_tree_t *) self->tree->context;
	RETVAL = html5_node_find(cv, tree_context->parser, self, query, combinator, ix == 1 || ix == 2);
OUTPUT:
	RETVAL

# findTag(val), getElementsByTagName(val)									- get nodes by tag name
# findClass(val), getElementsByClassName(val)								- get nodes by class name
# findId(val), getElementById(val)											- get node by id
# findAttr(key), getElementByAttribute(key)									- get nodes by attribute key
# findAttr(key, val, case, cmp), getElementByAttribute(key, val, case, cmp)	- get nodes by attribute value
SV *
findTag(HTML5::DOM::Element self, SV *key, SV *val = NULL, bool icase = false, SV *cmp = NULL)
ALIAS:
	getElementsByTagName	= 1
	findClass				= 2
	getElementsByClassName	= 3
	findId					= 4
	getElementById			= 5
	findAttr				= 6
	getElementByAttribute	= 7
CODE:
	RETVAL = html5_node_simple_find(cv, self, key, val, cmp, icase, ix);
OUTPUT:
	RETVAL

# First child element
SV *
first(HTML5::DOM::Element self)
ALIAS:
	firstElementChild	= 1
CODE:
	myhtml_tree_node_t *node = myhtml_node_child(self);
	while (node && !node_is_element(node))
		node = myhtml_node_next(node);
	RETVAL = node_to_sv(node);
OUTPUT:
	RETVAL

# First child node
SV *
firstNode(HTML5::DOM::Element self)
ALIAS:
	firstChild	= 1
CODE:
	RETVAL = node_to_sv(myhtml_node_child(self));
OUTPUT:
	RETVAL

# Last child element
SV *
last(HTML5::DOM::Element self)
ALIAS:
	lastElementChild	= 1
CODE:
	myhtml_tree_node_t *node = myhtml_node_last_child(self);
	while (node && !node_is_element(node))
		node = myhtml_node_prev(node);
	RETVAL = node_to_sv(node);
OUTPUT:
	RETVAL

# Last child node
SV *
lastNode(HTML5::DOM::Element self)
ALIAS:
	lastChild	= 1
CODE:
	RETVAL = node_to_sv(myhtml_node_last_child(self));
OUTPUT:
	RETVAL

# return all attributes in a array
SV *
attrArray(HTML5::DOM::Element self)
CODE:
	AV *array = newAV();
	
	myhtml_tree_attr_t *attr = myhtml_node_attribute_first(self);
	while (attr) {
		HV *hash = newHV();
		
		size_t attr_key_len = 0;
		const char *attr_key = myhtml_attribute_key(attr, &attr_key_len);
		
		size_t attr_val_len = 0;
		const char *attr_val = myhtml_attribute_value(attr, &attr_val_len);
		
		size_t ns_len = 0;
		const char *ns_name = myhtml_namespace_name_by_id(myhtml_attribute_namespace(attr), &ns_len);
		
		hv_store_ent(hash, sv_2mortal(newSVpv("name", 4)), newSVpv(attr_key ? attr_key : "", attr_key_len), 0);
		hv_store_ent(hash, sv_2mortal(newSVpv("value", 5)), newSVpv(attr_val ? attr_val : "", attr_val_len), 0);
		hv_store_ent(hash, sv_2mortal(newSVpv("namespace", 9)), newSVpv(ns_name ? ns_name : "", ns_len), 0);
		
		av_push(array, newRV_noinc((SV *) hash));
		
		attr = myhtml_attribute_next(attr);
	}
	
	RETVAL = newRV_noinc((SV *) array);
OUTPUT:
	RETVAL

# attr()					- return all attributes in a hash
# attr("key")				- return value of attribute "key" (undef is not exists)
# attr("key", "value")		- set value for attribute "key" (return this)
# attr({"key" => "value"})	- bulk set value for attribute "key" (return this)
SV *
attr(HTML5::DOM::Element self, SV *key = NULL, SV *value = NULL)
ALIAS:
	setAttribute	= 1
	getAttribute	= 2
CODE:
	RETVAL = &PL_sv_undef;
	
	if (ix == 1) { // setAttribute
		if (!key)
			sub_croak(cv, "attribute key required for setAttribute");
		
		if (!value)
			sub_croak(cv, "attribute value required for setAttribute");
	} else if (ix == 2) { // getAttribute
		if (!key)
			sub_croak(cv, "attribute key required for getAttribute");
		
		key = sv_stringify(key);
		value = NULL;
	}
	
	if (key && value) { // Set value by key or delete by key
		key = sv_stringify(key);
		value = sv_stringify(value);
		
		STRLEN key_len = 0;
		const char *key_str = SvPV_const(key, key_len);
		
		if (key_len) {
			// if value is undef - only remove attribute
			if (SvTYPE(value) != SVt_NULL) {
				STRLEN val_len = 0;
				const char *val_str = SvPV_const(value, val_len);
				html5_dom_replace_attr_value(self, key_str, key_len, val_str, val_len, MyENCODING_DEFAULT);
			} else {
				myhtml_attribute_remove_by_key(self, key_str, key_len);
			}
		}
		
		// return self
		RETVAL = SvREFCNT_inc(ST(0));
	} else if (key && !value) {
		// Bulk attr set
		if (SvROK(key) && SvTYPE(SvRV(key)) == SVt_PVHV) {
			HE *entry;
			HV *hash = (HV *) SvRV(key);
			
			while ((entry = hv_iternext(hash)) != NULL) {
				SV *value = hv_iterval(hash, entry);
				I32 key_len;
				const char *key_name = hv_iterkey(entry, &key_len);
				if (value && key_len) {
					value = sv_stringify(value);
					
					// if value is undef - only remove attribute
					if (SvTYPE(value) != SVt_NULL) {
						STRLEN val_len = 0;
						const char *val_str = SvPV_const(value, val_len);
						html5_dom_replace_attr_value(self, key_name, key_len, val_str, val_len, MyENCODING_DEFAULT);
					} else {
						myhtml_attribute_remove_by_key(self, key_name, key_len);
					}
				}
			}
			
			RETVAL = SvREFCNT_inc(ST(0));
		}
		// Get attribute by key
		else {
			key = sv_stringify(key);
			
			STRLEN key_len = 0;
			const char *key_str = SvPV_const(key, key_len);
			
			if (key_len) {
				myhtml_tree_attr_t *attr = myhtml_attribute_by_key(self, key_str, key_len);
				if (attr) {
					size_t attr_val_len = 0;
					const char *attr_val = myhtml_attribute_value(attr, &attr_val_len);
					RETVAL = newSVpv(attr_val ? attr_val : "", attr_val_len);
				}
			}
		}
	} else { // Return all attributes in hash
		HV *hash = newHV();
		
		myhtml_tree_attr_t *attr = myhtml_node_attribute_first(self);
		while (attr) {
			size_t attr_key_len = 0;
			const char *attr_key = myhtml_attribute_key(attr, &attr_key_len);
			
			size_t attr_val_len = 0;
			const char *attr_val = myhtml_attribute_value(attr, &attr_val_len);
			
			hv_store_ent(hash, sv_2mortal(newSVpv(attr_key ? attr_key : "", attr_key_len)), newSVpv(attr_val ? attr_val : "", attr_val_len), 0);
			
			attr = myhtml_attribute_next(attr);
		}
		
		RETVAL = newRV_noinc((SV *) hash);
	}
OUTPUT:
	RETVAL

# Remove attribute by key
SV *
removeAttr(HTML5::DOM::Element self, SV *key = NULL)
ALIAS:
	removeAttribute	= 1
CODE:
	key = sv_stringify(key);
	
	STRLEN key_len = 0;
	const char *key_str = SvPV_const(key, key_len);
	
	if (key_len)
		myhtml_attribute_remove_by_key(self, key_str, key_len);
	
	RETVAL = SvREFCNT_inc(ST(0));
OUTPUT:
	RETVAL

# Return collection with children elements
SV *
children(HTML5::DOM::Element self)
CODE:
	myhtml_tree_node_t *child = myhtml_node_child(self);
	AV *arr = newAV();
	
	while (child) {
		if (node_is_element(child))
			av_push(arr, node_to_sv(child));
		child = myhtml_node_next(child);
	}
	
	RETVAL = sv_bless(newRV_noinc((SV *) arr), gv_stashpv("HTML5::DOM::Collection", 0));
OUTPUT:
	RETVAL

# Return collection with children nodes
SV *
childrenNode(HTML5::DOM::Element self)
ALIAS:
	childNodes	= 1
CODE:
	myhtml_tree_node_t *child = myhtml_node_child(self);
	AV *arr = newAV();
	
	while (child) {
		av_push(arr, node_to_sv(child));
		child = myhtml_node_next(child);
	}
	
	RETVAL = sv_bless(newRV_noinc((SV *) arr), gv_stashpv("HTML5::DOM::Collection", 0));
OUTPUT:
	RETVAL

# Return default display property for tag
SV *
getDefaultBoxType(HTML5::DOM::Element self)
CODE:
	const char *ret = NULL;
	switch (html5_dom_get_ua_display_prop(self)) {
		case TAG_UA_STYLE_NONE:
			ret = "none";
		break;
		case TAG_UA_STYLE_INLINE:
			ret = "inline";
		break;
		case TAG_UA_STYLE_BLOCK:
			ret = "block";
		break;
		case TAG_UA_STYLE_INLINE_BLOCK:
			ret = "inline-block";
		break;
		case TAG_UA_STYLE_LIST_ITEM:
			ret = "list-item";
		break;
		case TAG_UA_STYLE_TABLE:
			ret = "table";
		break;
		case TAG_UA_STYLE_TABLE_CAPTION:
			ret = "table-caption";
		break;
		case TAG_UA_STYLE_TABLE_CELL:
			ret = "table-cell";
		break;
		case TAG_UA_STYLE_TABLE_COLUMN:
			ret = "table-column";
		break;
		case TAG_UA_STYLE_TABLE_COLUMN_GROUP:
			ret = "table-column-group";
		break;
		case TAG_UA_STYLE_TABLE_HEADER_GROUP:
			ret = "table-header-group";
		break;
		case TAG_UA_STYLE_TABLE_FOOTER_GROUP:
			ret = "table-footer-group";
		break;
		case TAG_UA_STYLE_TABLE_ROW:
			ret = "table-row";
		break;
		case TAG_UA_STYLE_TABLE_ROW_GROUP:
			ret = "table-row-group";
		break;
		case TAG_UA_STYLE_RUBY:
			ret = "ruby";
		break;
		case TAG_UA_STYLE_RUBY_BASE:
			ret = "ruby-base";
		break;
		case TAG_UA_STYLE_RUBY_TEXT:
			ret = "ruby-text";
		break;
		case TAG_UA_STYLE_RUBY_TEXT_CONTAINER:
			ret = "ruby-text-container";
		break;
	}
	
	RETVAL = ret ? newSVpv(ret, strlen(ret)) : &PL_sv_undef;
OUTPUT:
	RETVAL

#################################################################
# HTML5::DOM::DocType (extends Node)
#################################################################
MODULE = HTML5::DOM  PACKAGE = HTML5::DOM::DocType
SV *name(HTML5::DOM::DocType self, SV *value = NULL)
ALIAS:
	publicId		= 1
	systemId		= 2
CODE:
	static const char *TYPE_SYSTEM = "SYSTEM";
	static const char *TYPE_PUBLIC = "PUBLIC";
	
	myhtml_tree_attr_t *root_name = self->token ? self->token->attr_first : NULL;
	myhtml_tree_attr_t *restrict_type = root_name ? root_name->next : NULL;
	myhtml_tree_attr_t *public_id = restrict_type ? restrict_type->next : NULL;
	myhtml_tree_attr_t *system_id = public_id ? public_id->next : NULL;
	
	if (restrict_type && restrict_type->value.length == 6) {
		if (mycore_strcasecmp(restrict_type->value.data, "SYSTEM") == 0) {
			system_id = public_id;
			public_id = NULL;
		}
	}
	
	if (value) {
		value = sv_stringify(value);
		
		myhtml_tree_attr_t *attr_first = self->token ? self->token->attr_first : NULL;
		myhtml_tree_attr_t *attr_last = self->token ? self->token->attr_last : NULL;
		
		STRLEN val_len = 0;
		const char *val_str = SvPV_const(value, val_len);
		
		// root element name
		if (ix == 0) {
			myhtml_attribute_add(self, val_str, val_len, "", 0, MyENCODING_DEFAULT);
		} else {
			myhtml_attribute_add(self, root_name && root_name->key.data ? root_name->key.data : "", root_name ? root_name->key.length : 0, "", 0, MyENCODING_DEFAULT);
		}
		
		const char *restrict_type_str = NULL;
		
		if ((ix == 2 && val_len) || (system_id && system_id->value.length))
			restrict_type_str = TYPE_SYSTEM;
		
		if ((ix == 1 && val_len) || (public_id && public_id->value.length))
			restrict_type_str = TYPE_PUBLIC;
		
		if (restrict_type_str) {
			// SYSTEM or PUBLIC
			myhtml_attribute_add(self, "", 0, restrict_type_str, 6, MyENCODING_DEFAULT);
			
			if (restrict_type_str == TYPE_PUBLIC) {
				// publicId
				if (ix == 1) {
					myhtml_attribute_add(self, "", 0, val_str, val_len, MyENCODING_DEFAULT);
				} else {
					myhtml_attribute_add(self, "", 0, public_id && public_id->value.data ? public_id->value.data : "", public_id ? public_id->value.length : 0, MyENCODING_DEFAULT);
				}
			}
			
			// systemId
			if (ix == 2) {
				myhtml_attribute_add(self, "", 0, val_str, val_len, MyENCODING_DEFAULT);
			} else {
				myhtml_attribute_add(self, "", 0, system_id && system_id->value.data ? system_id->value.data : "", system_id ? system_id->value.length : 0, MyENCODING_DEFAULT);
			}
		}
		
		// remove old
		while (attr_last && attr_first) {
			myhtml_tree_attr_t *next = attr_first->next;
			myhtml_attribute_delete(self->tree, self, attr_first);
			
			if (attr_first == attr_last)
				break;
			
			attr_first = next;
		}
		
		RETVAL = SvREFCNT_inc(ST(0));
	} else {
		RETVAL = &PL_sv_undef;
		
		switch (ix) {
			case 0: /* name */
				RETVAL = newSVpv(root_name && root_name->key.data ? root_name->key.data : "", root_name ? root_name->key.length : 0);
			break;
			
			case 1: /* publicId */
				RETVAL = newSVpv(public_id && public_id->value.data ? public_id->value.data : "", public_id ? public_id->value.length : 0);
			break;
			
			case 2: /* systemId */
				RETVAL = newSVpv(system_id && system_id->value.data ? system_id->value.data : "", system_id ? system_id->value.length : 0);
			break;
		}
	}
OUTPUT:
	RETVAL

#################################################################
# HTML5::DOM::CSS (Parser)
#################################################################
MODULE = HTML5::DOM  PACKAGE = HTML5::DOM::CSS
HTML5::DOM::CSS
new(SV *CLASS)
CODE:
	DOM_GC_TRACE("DOM::CSS::new");
	mystatus_t status;
	
	mycss_t *mycss = mycss_create();
	status = mycss_init(mycss);
	if (status) {
		mycss_destroy(mycss, 1);
		sub_croak(cv, "mycss_init failed: %d (%s)", status, modest_strerror(status));
	}
	
	mycss_entry_t *entry = mycss_entry_create();
	status = mycss_entry_init(mycss, entry);
	if (status) {
		mycss_destroy(mycss, 1);
		mycss_entry_destroy(entry, 1);
		sub_croak(cv, "mycss_entry_init failed: %d (%s)", status, modest_strerror(status));
	}
	
	html5_css_parser_t *self = (html5_css_parser_t *) safemalloc(sizeof(html5_css_parser_t));
	self->mycss = mycss;
	self->entry = entry;
	self->encoding = MyENCODING_UTF_8;
	RETVAL = self;
OUTPUT:
	RETVAL

# Parse css selector
SV *
parseSelector(HTML5::DOM::CSS self, SV *query)
CODE:
	mystatus_t status;
	
	query = sv_stringify(query);
	
	STRLEN query_len;
	const char *query_str = SvPV_const(query, query_len);
	
	mycss_selectors_list_t *list = mycss_selectors_parse(mycss_entry_selectors(self->entry), MyENCODING_UTF_8, query_str, query_len, &status);
	
	DOM_GC_TRACE("DOM::CSS::Selector::NEW");
	html5_css_selector_t *selector = (html5_css_selector_t *) safemalloc(sizeof(html5_css_selector_t));
	selector->parent = SvRV(ST(0));
	selector->list = list;
	selector->parser = self;
	SvREFCNT_inc(selector->parent);
	RETVAL = pack_pointer("HTML5::DOM::CSS::Selector", selector);
OUTPUT:
	RETVAL

void
DESTROY(HTML5::DOM::CSS self)
CODE:
	DOM_GC_TRACE("DOM::CSS::DESTROY (refs=%d)", SvREFCNT(SvRV(ST(0))));
	mycss_entry_destroy(self->entry, 1);
	mycss_destroy(self->mycss, 1);
	safefree(self);


#################################################################
# HTML5::DOM::CSS::Selector
#################################################################
MODULE = HTML5::DOM  PACKAGE = HTML5::DOM::CSS::Selector

# Serialize selector to text
SV *
text(HTML5::DOM::CSS::Selector self)
CODE:
	RETVAL = newSVpv("", 0);
	if (self->list)
		mycss_selectors_serialization_list(mycss_entry_selectors(self->parser->entry), self->list, sv_serialization_callback, RETVAL);
OUTPUT:
	RETVAL

# True, if selector is valid
bool
valid(HTML5::DOM::CSS::Selector self)
CODE:
	RETVAL = self->list ? !(self->list->flags & MyCSS_SELECTORS_FLAGS_SELECTOR_BAD) : 0;
OUTPUT:
	RETVAL

# Return AST tree
SV *
ast(HTML5::DOM::CSS::Selector self)
CODE:
	AV *result = newAV();
	if (self->list)
		html5_dom_css_serialize_selector(self->list, result);
	RETVAL = newRV_noinc((SV *) result);
OUTPUT:
	RETVAL

# Get count of selector entries
int
length(HTML5::DOM::CSS::Selector self)
CODE:
	RETVAL = self->list ? self->list->entries_list_length : 0;
OUTPUT:
	RETVAL

# Get selector entry by index
SV *
entry(HTML5::DOM::CSS::Selector self, int index)
CODE:
	if (!self->list || index < 0 || index >= self->list->entries_list_length) {
		RETVAL = &PL_sv_undef;
	} else {
		DOM_GC_TRACE("DOM::CSS::Selector::Entry::NEW");
		html5_css_selector_entry_t *entry = (html5_css_selector_entry_t *) safemalloc(sizeof(html5_css_selector_entry_t));
		entry->parent = SvRV(ST(0));
		entry->selector = self;
		entry->list = &self->list->entries_list[index];
		SvREFCNT_inc(entry->parent);
		RETVAL = pack_pointer("HTML5::DOM::CSS::Selector::Entry", entry);
	}
OUTPUT:
	RETVAL

void
DESTROY(HTML5::DOM::CSS::Selector self)
CODE:
	DOM_GC_TRACE("DOM::CSS::Selector::DESTROY (refs=%d)", SvREFCNT(SvRV(ST(0))));
	if (self->list)
		mycss_selectors_list_destroy(mycss_entry_selectors(self->parser->entry), self->list, true);
	SvREFCNT_dec(self->parent);
	safefree(self);


#################################################################
# HTML5::DOM::CSS::Selector::Entry
#################################################################
MODULE = HTML5::DOM  PACKAGE = HTML5::DOM::CSS::Selector::Entry

# Serialize selector to text
SV *
text(HTML5::DOM::CSS::Selector::Entry self)
CODE:
	RETVAL = newSVpv("", 0);
	mycss_selectors_serialization_chain(mycss_entry_selectors(self->selector->parser->entry), self->list->entry, sv_serialization_callback, RETVAL);
OUTPUT:
	RETVAL

# Return AST tree
SV *
ast(HTML5::DOM::CSS::Selector::Entry self)
CODE:
	AV *result = newAV();
	html5_dom_css_serialize_entry(self->selector->list, self->list->entry, result);
	RETVAL = newRV_noinc((SV *) result);
OUTPUT:
	RETVAL

# Return pseudo-element name
SV *
pseudoElement(HTML5::DOM::CSS::Selector::Entry self)
CODE:
	mycss_selectors_entry_t *entry = self->list->entry;
	RETVAL = &PL_sv_undef;
	while (entry) {
		if (entry->type == MyCSS_SELECTORS_TYPE_PSEUDO_ELEMENT) {
			RETVAL = newSVpv(entry->key->data ? entry->key->data : "", entry->key->length);
			break;
		}
		entry = entry->next;
	}
OUTPUT:
	RETVAL

# True, if selector is valid
bool
valid(HTML5::DOM::CSS::Selector::Entry self)
CODE:
	RETVAL = !(self->selector->list->flags & MyCSS_SELECTORS_FLAGS_SELECTOR_BAD);
OUTPUT:
	RETVAL

# Return selector specificity in hash {a, b, c}
SV *
specificity(HTML5::DOM::CSS::Selector::Entry self)
CODE:
	HV *hash = newHV();
	hv_store_ent(hash, sv_2mortal(newSVpv("a", 1)), newSViv(self->list->specificity.a), 0);
	hv_store_ent(hash, sv_2mortal(newSVpv("b", 1)), newSViv(self->list->specificity.b), 0);
	hv_store_ent(hash, sv_2mortal(newSVpv("c", 1)), newSViv(self->list->specificity.c), 0);
	RETVAL = newRV_noinc((SV *) hash);
OUTPUT:
	RETVAL

# Return selector specificity in array [a, b, c]
SV *
specificityArray(HTML5::DOM::CSS::Selector::Entry self)
CODE:
	AV *arr = newAV();
	av_push(arr, newSViv(self->list->specificity.a));
	av_push(arr, newSViv(self->list->specificity.b));
	av_push(arr, newSViv(self->list->specificity.c));
	RETVAL = newRV_noinc((SV *) arr);
OUTPUT:
	RETVAL

void
DESTROY(HTML5::DOM::CSS::Selector::Entry self)
CODE:
	DOM_GC_TRACE("DOM::CSS::Selector::Entry::DESTROY (refs=%d)", SvREFCNT(SvRV(ST(0))));
	SvREFCNT_dec(self->parent);
	safefree(self);

#################################################################
# HTML5::DOM::Encoding
#################################################################
MODULE = HTML5::DOM  PACKAGE = HTML5::DOM::Encoding

SV *
id2name(int id)
CODE:
	size_t len = 0;
	const char *name = myencoding_name_by_id(id, &len);
	RETVAL = name ? newSVpv(name, len) : &PL_sv_undef;
OUTPUT:
	RETVAL

SV *
name2id(SV *text)
CODE:
	text = sv_stringify(text);
	
	STRLEN text_len;
	const char *text_str = SvPV_const(text, text_len);
	
	myencoding_t encoding = MyENCODING_NOT_DETERMINED;
	myencoding_by_name(text_str, text_len, &encoding);
	RETVAL =  encoding != MyENCODING_NOT_DETERMINED ? newSViv(encoding) : &PL_sv_undef;
OUTPUT:
	RETVAL

int
detect(SV *text, long max_len = 0)
ALIAS:
	detectByPrescanStream	= 1
	detectRussian			= 2
	detectUnicode			= 3
	detectBom				= 4
	detectByCharset			= 5
CODE:
	text = sv_stringify(text);
	
	STRLEN text_len;
	const char *text_str = SvPV_const(text, text_len);
	
	if (max_len > 0 && max_len < text_len)
		text_len = max_len;
	
	myencoding_t encoding;
	
	switch (ix) {
		case 0:
			if (!myencoding_detect(text_str, text_len, &encoding))
				encoding = MyENCODING_NOT_DETERMINED;
		break;
		case 1:
			encoding = myencoding_prescan_stream_to_determine_encoding(text_str, text_len);
		break;
		case 2:
			if (!myencoding_detect_russian(text_str, text_len, &encoding))
				encoding = MyENCODING_NOT_DETERMINED;
		break;
		case 3:
			if (!myencoding_detect_unicode(text_str, text_len, &encoding))
				encoding = MyENCODING_NOT_DETERMINED;
		break;
		case 4:
			if (!myencoding_detect_bom(text_str, text_len, &encoding))
				encoding = MyENCODING_NOT_DETERMINED;
		break;
		case 5:
			if (!myencoding_extracting_character_encoding_from_charset(text_str, text_len, &encoding))
				encoding = MyENCODING_NOT_DETERMINED;
		break;
	}
	
	RETVAL = encoding;
OUTPUT:
	RETVAL

void
detectBomAndCut(SV *text, long max_len = 0)
CODE:
	text = sv_stringify(text);
	
	STRLEN text_len;
	const char *text_str = SvPV_const(text, text_len);
	
	if (max_len > 0 && max_len < text_len)
		text_len = max_len;
	
	myencoding_t encoding;
	
	if (!myencoding_detect_and_cut_bom(text_str, text_len, &encoding, &text_str, &text_len))
		encoding = MyENCODING_NOT_DETERMINED;

	ST(0) = newSViv(encoding);
	ST(1) = newSVpv(text_str, text_len);
	
	sv_2mortal(ST(0));
	sv_2mortal(ST(1));
	
	XSRETURN(2);

void
detectAuto(SV *text, long max_len = 0, HV *options = NULL)
CODE:
	text = sv_stringify(text);
	
	STRLEN text_len;
	const char *text_str = SvPV_const(text, text_len);
	
	if (max_len > 0 && max_len < text_len)
		text_len = max_len;
	
	html5_dom_options_t opts = {0};
	html5_dom_parse_options(&opts, NULL, options);
	
	opts.encoding				= MyENCODING_AUTO;
	opts.default_encoding		= MyENCODING_NOT_DETERMINED;
	opts.encoding_prescan_limit	= text_len;
	
	myencoding_t encoding = html5_dom_auto_encoding(&opts, &text_str, &text_len);
	
	ST(0) = newSViv(encoding);
	ST(1) = newSVpv(text_str, text_len);
	
	sv_2mortal(ST(0));
	sv_2mortal(ST(1));
	
	XSRETURN(2);
