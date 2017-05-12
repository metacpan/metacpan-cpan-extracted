#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "link-includes.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

MODULE = Lingua::LinkParser		PACKAGE = Lingua::LinkParser		


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

Dictionary
dictionary_create_lang(lang)
	const char * lang

Dictionary
dictionary_create_default_lang()

int
dictionary_delete(dict)
	Dictionary	dict

int
dictionary_get_max_cost(dict)
	Dictionary	dict

int
linkage_and_cost(linkage)
	Linkage	linkage

int
linkage_compute_union(linkage)
	Linkage	linkage

Linkage
linkage_create(index, sent, opts)
	int	index
	Sentence	sent
	Parse_Options	opts

void
linkage_delete(linkage)
	Linkage	linkage

int
linkage_disjunct_cost(linkage)
	Linkage	linkage

void
call_linkage_get_link_domain_names(linkage, index)
        Linkage linkage
        int     index
    PREINIT:
        int j;
        const char **names;
    PPCODE:
        names = linkage_get_link_domain_names(linkage, index);
        for (j=0; j<linkage_get_link_num_domains(linkage, index); ++j) {
            XPUSHs(newSVpv(names[j],0));
        }

const char **
linkage_get_link_domain_names(linkage, index)
        Linkage linkage
        int     index

const char *
linkage_get_link_label(linkage, index)
	Linkage	linkage
	int	index

int
linkage_get_link_length(linkage, index)
	Linkage	linkage
	int	index

const char *
linkage_get_link_llabel(linkage, index)
	Linkage	linkage
	int	index

int
linkage_get_link_lword(linkage, index)
	Linkage	linkage
	int	index

int
linkage_get_link_num_domains(linkage, index)
	Linkage	linkage
	int	index

const char *
linkage_get_link_rlabel(linkage, index)
	Linkage	linkage
	int	index

int
linkage_get_link_rword(linkage, index)
	Linkage	linkage
	int	index

int
linkage_get_num_links(linkage)
	Linkage	linkage

int
linkage_get_num_sublinkages(linkage)
	Linkage	linkage

int
linkage_get_num_words(linkage)
	Linkage	linkage

Sentence
linkage_get_sentence(linkage)
	Linkage	linkage

const char *
linkage_get_violation_name(linkage)
	Linkage	linkage

const char *
linkage_get_word(linkage, w)
	Linkage	linkage
	int	w

void
call_linkage_get_words(linkage)
        Linkage linkage
    PREINIT:
        int j;
        const char **words;
    PPCODE:
        words = linkage_get_words(linkage);
        for (j=0; j<linkage_get_num_words(linkage); ++j) {
            XPUSHs(newSVpv(words[j],0));
        }

const char **
linkage_get_words(linkage)
	Linkage	linkage

int
linkage_has_inconsistent_domains(linkage)
	Linkage	linkage

int
linkage_is_canonical(linkage)
	Linkage	linkage

int
linkage_is_improper(linkage)
	Linkage	linkage

int
linkage_link_cost(linkage)
	Linkage	linkage

void
linkage_post_process(linkage, postprocessor)
	Linkage	linkage
	PostProcessor *	postprocessor

char *
linkage_print_diagram(linkage)
	Linkage	linkage

char *
linkage_print_links_and_domains(linkage)
	Linkage	linkage

char *
linkage_print_postscript(linkage, mode)
	Linkage	linkage
	int	mode

int
linkage_set_current_sublinkage(linkage, index)
	Linkage	linkage
	int	index

int
linkage_unused_word_cost(linkage)
	Linkage	linkage

Parse_Options
parse_options_create()

int
parse_options_delete(opts)
	Parse_Options	opts

int
parse_options_get_all_short_connectors(opts)
	Parse_Options	opts

int
parse_options_get_allow_null(opts)
	Parse_Options	opts

int
parse_options_get_batch_mode(opts)
	Parse_Options	opts

int
parse_options_get_disjunct_cost(opts)
	Parse_Options	opts

int
parse_options_get_display_bad(opts)
	Parse_Options	opts

int
parse_options_get_display_links(opts)
	Parse_Options	opts

int
parse_options_get_display_on(opts)
	Parse_Options	opts

int
parse_options_get_display_postscript(opts)
	Parse_Options	opts

int
parse_options_get_display_union(opts)
	Parse_Options	opts

int
parse_options_get_display_walls(opts)
	Parse_Options	opts

int
parse_options_get_echo_on(opts)
	Parse_Options	opts

int
parse_options_get_islands_ok(opts)
	Parse_Options	opts

int
parse_options_get_linkage_limit(opts)
	Parse_Options	opts

int
parse_options_get_max_memory(opts)
	Parse_Options	opts

int
parse_options_get_max_null_count(opts)
	Parse_Options	opts

int
parse_options_get_max_parse_time(opts)
	Parse_Options	opts

int
parse_options_get_min_null_count(opts)
	Parse_Options	opts

int
parse_options_get_null_block(opts)
	Parse_Options	opts

int
parse_options_get_panic_mode(opts)
	Parse_Options	opts

int
parse_options_get_screen_width(opts)
	Parse_Options	opts

int
parse_options_get_short_length(opts)
	Parse_Options	opts

int
parse_options_get_verbosity(opts)
	Parse_Options	opts

int
parse_options_memory_exhausted(opts)
	Parse_Options	opts

void
parse_options_reset_resources(opts)
	Parse_Options	opts

int
parse_options_resources_exhausted(opts)
	Parse_Options	opts

void
parse_options_set_max_sentence_length(opts, val)
        Parse_Options   opts
        int     val

int
parse_options_get_max_sentence_length(opts)
        Parse_Options   opts

void
parse_options_set_all_short_connectors(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_allow_null(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_batch_mode(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_cost_model_type(opts, cm)
	Parse_Options	opts
	int	cm

void
parse_options_set_disjunct_cost(opts, disjunct_cost)
	Parse_Options	opts
	int	disjunct_cost

void
parse_options_set_display_bad(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_display_links(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_display_on(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_display_postscript(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_display_union(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_display_walls(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_echo_on(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_islands_ok(opts, islands_ok)
	Parse_Options	opts
	int	islands_ok

void
parse_options_set_linkage_limit(opts, linkage_limit)
	Parse_Options	opts
	int	linkage_limit

void
parse_options_set_max_memory(opts, mem)
	Parse_Options	opts
	int	mem

void
parse_options_set_max_null_count(opts, null_count)
	Parse_Options	opts
	int	null_count

void
parse_options_set_max_parse_time(opts, secs)
	Parse_Options	opts
	int	secs

void
parse_options_set_min_null_count(opts, null_count)
	Parse_Options	opts
	int	null_count

void
parse_options_set_null_block(opts, null_block)
	Parse_Options	opts
	int	null_block

void
parse_options_set_panic_mode(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_screen_width(opts, val)
	Parse_Options	opts
	int	val

void
parse_options_set_short_length(opts, short_length)
	Parse_Options	opts
	int	short_length

void
parse_options_set_verbosity(opts, verbosity)
	Parse_Options	opts
	int	verbosity

int
parse_options_timer_expired(opts)
	Parse_Options	opts

void
post_process_close(postprocessor)
	PostProcessor *	postprocessor

PostProcessor *
post_process_open(dictname)
	char *	dictname

Sentence
sentence_create(input_string, dict)
	char *	input_string
	Dictionary	dict

void
sentence_delete(sent)
	Sentence	sent

int
sentence_disjunct_cost(sent, i)
	Sentence	sent
	int	i

const char *
sentence_get_word(sent, wordnum)
	Sentence	sent
	int	wordnum

int
sentence_length(sent)
	Sentence	sent

int
sentence_null_count(sent)
	Sentence	sent

int
sentence_num_linkages_found(sent)
	Sentence	sent

int
sentence_num_linkages_post_processed(sent)
	Sentence	sent

int
sentence_num_valid_linkages(sent)
	Sentence	sent

int
sentence_num_violations(sent, i)
	Sentence	sent
	int	i

int
sentence_parse(sent, opts)
	Sentence	sent
	Parse_Options	opts

const char *
linkage_constituent_node_get_label(cnode)
	const CNode * cnode

CNode *
linkage_constituent_node_get_child(cnode)
	const CNode * cnode

CNode *
linkage_constituent_node_get_next(cnode)
        const CNode * cnode

int
linkage_constituent_node_get_start(cnode)
        const CNode * cnode

int
linkage_constituent_node_get_end(cnode)
	const CNode * cnode

CNode *
linkage_constituent_tree(linkage)
	Linkage		linkage

void
linkage_free_constituent_tree(cnode)
	CNode * 	cnode

char *
linkage_print_constituent_tree(linkage, mode)
	Linkage linkage
	int     mode

void
linkage_free_constituent_tree_str(str)
        char *  str

