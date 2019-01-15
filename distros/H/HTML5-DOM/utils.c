#include "utils.h"

/*
	async parsing
*/
void *html5_dom_mythread_function(void *arg) {
	mythread_context_t *ctx = (mythread_context_t *) arg;
	mythread_t *mythread = ctx->mythread;
	
	mythread_mutex_wait(mythread, ctx->mutex);
	ctx->func(ctx->id, ctx);
	mythread_nanosleep_destroy(ctx->timespec);
	ctx->opt = MyTHREAD_OPT_QUIT;
	mythread_mutex_close(mythread, ctx->mutex);
	
    return NULL;
}

static int html5_dom_fd_write(int fd, const char *data, int size) {
	if (fd > -1) {
		#ifdef MyCORE_OS_WINDOWS_NT
			return _write(fd, data, size);
		#else
			return write(fd, data, size);
		#endif
	}
	return 0;
}

int html5_dom_async_parse(html5_dom_async_result *result) {
	mystatus_t status;
	
	// create parser
	html5_dom_parser_t *self = html5_dom_parser_new(&result->opts);
	
	// init myhtml
	self->myhtml = myhtml_create();
	
	if (self->opts.threads <= 1) {
		status = myhtml_init(self->myhtml, MyHTML_OPTIONS_PARSE_MODE_SINGLE, 1, 0);
	} else {
		status = myhtml_init(self->myhtml, MyHTML_OPTIONS_DEFAULT, self->opts.threads, 0);
	}
	
	if (status) {
		html5_dom_parser_free(self);
		result->status = status;
		result->done = true;
		return html5_dom_fd_write(result->fd, "0", 1);
	}
	
	// init myhtml tree
	myhtml_tree_t *tree = myhtml_tree_create();
	status = myhtml_tree_init(tree, self->myhtml);
	if (status) {
		myhtml_tree_destroy(tree);
		html5_dom_parser_free(self);
		result->status = status;
		result->done = true;
		return html5_dom_fd_write(result->fd, "0", 1);
	}
	
	// detect encoding
	myencoding_t encoding = html5_dom_auto_encoding(&result->opts, (const char **) &result->html, &result->length);
	
	// apply options to tree
	html5_dom_apply_tree_options(tree, &result->opts);
	
	// try parse
	status = myhtml_parse(tree, encoding, result->html, result->length);
	
	if (status) {
		myhtml_tree_destroy(tree);
		html5_dom_parser_free(self);
		result->status = status;
		result->done = true;
		return html5_dom_fd_write(result->fd, "0", 1);
	}
	
	result->done = true;
	result->tree = tree;
	result->parser = self;
	
	// trigger event
	return html5_dom_fd_write(result->fd, "1", 1);
}

void html5_dom_async_parse_worker(mythread_id_t thread_id, void *arg) {
	mythread_context_t *ctx = (mythread_context_t *) arg;
	html5_dom_async_result *result = (html5_dom_async_result *) ctx->mythread->context;
	html5_dom_async_parse(result);
}

/*
	parser
*/
html5_dom_parser_t *html5_dom_parser_new(html5_dom_options_t *options) {
	html5_dom_parser_t *self = (html5_dom_parser_t *) malloc(sizeof(html5_dom_parser_t));
	memset(self, 0, sizeof(html5_dom_parser_t));
	memcpy(&self->opts, options, sizeof(html5_dom_options_t));
	return self;
}

void *html5_dom_parser_free(html5_dom_parser_t *self) {
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
	
	free(self);
}

mystatus_t html5_dom_init_css(html5_dom_parser_t *parser) {
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

myhtml_tree_node_t *html5_dom_parse_fragment(html5_dom_options_t *opts, myhtml_tree_t *tree, myhtml_tag_id_t tag_id, myhtml_namespace_t ns, 
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

/*
	misc
*/
const char *modest_strerror(mystatus_t status) {
	switch (status) {
		#include "gen/modest_errors.c"	
	}
	return status ? "UNKNOWN" : "";
}

int html5_dom_get_ua_display_prop(myhtml_tree_node_t *node) {
	switch (node->tag_id) {
		#include "gen/tags_ua_style.c"	
	}
	return TAG_UA_STYLE_INLINE;
}

void html5_dom_rtrim_mystring(mycore_string_t *str, char c) {
	size_t i = str->length;
	while (i > 0) {
		--i;
		
		if (str->data[i] != c)
			break;
		
		str->data[i] = '\0';
		--str->length;
	}
}

/*
	finders & css
*/
void _modest_finder_callback_found_with_one_node(modest_finder_t *finder, myhtml_tree_node_t *node, 
	mycss_selectors_list_t *selector_list, mycss_selectors_entry_t *selector, mycss_selectors_specificity_t *spec, void *ctx)
{
	myhtml_tree_node_t **result_node = (myhtml_tree_node_t **) ctx;
	if (!*result_node)
		*result_node = node;
}

void *html5_node_finder(html5_dom_parser_t *parser, modest_finder_selector_combinator_f func, 
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

modest_finder_selector_combinator_f html5_find_selector_func(const char *c, int combo_len) {
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

mycss_selectors_list_t *html5_parse_selector(mycss_entry_t *entry, const char *query, size_t query_len, mystatus_t *status_out) {
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

/*
	nodes
*/
myhtml_tag_id_t html5_dom_tag_id_by_name(myhtml_tree_t *tree, const char *tag_str, size_t tag_len, bool allow_create) {
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
myhtml_tree_node_t *html5_dom_copy_foreign_node(myhtml_tree_t *tree, myhtml_tree_node_t *node) {
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

myhtml_tree_node_t *html5_dom_recursive_clone_node(myhtml_tree_t *tree, myhtml_tree_node_t *node, html5_fragment_parts_t *parts) {
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

// Try to implements https://html.spec.whatwg.org/multipage/dom.html#the-innertext-idl-attribute
// Using default user-agent box model types for tags instead of real css.
void html5_dom_recursive_node_inner_text(myhtml_tree_node_t *node, html5_dom_inner_text_state_t *state) {
	if (node->tag_id == MyHTML_TAG__TEXT) {
		size_t text_len = 0;
		const char *text = myhtml_node_text(node, &text_len);
		
		bool is_empty = true;
		for (size_t i = 0; i < text_len; ++i) {
			// skip CR
			if (text[i] == '\r')
				continue;
			
			// collapse spaces
			if (isspace(text[i]) && (text[i] != '\xA0' || !i || text[i - 1] != '\xC2') && text[i] != '\xC2') {
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

// Safe delete nodes only if it has not perl object representation
void html5_tree_node_delete_recursive(myhtml_tree_node_t *node) {
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

/*
	attrs
*/
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

/*
	encoding
*/
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
