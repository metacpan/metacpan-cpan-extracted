#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <string.h>
#include <strings.h>
#include <stdlib.h>
#include <ctype.h>

/* uncomment to enable debugging output */
/* #define DEBUG 1 */

/* ****************************************************************************
 * CHARACTER CLASS METHODS
 * ****************************************************************************
 */
bool charIsSpace(char ch) {
    if (ch == ' ')  return 1;
    if (ch == '\t') return 1;
    return 0;
}
bool charIsEndspace(char ch) {
    if (ch == '\n') return 1;
    if (ch == '\r') return 1;
    if (ch == '\f') return 1;
    return 0;
}
bool charIsWhitespace(char ch) {
    return charIsSpace(ch) || charIsEndspace(ch);
}
bool charIsIdentifier(char ch) {
    if ((ch >= 'a') && (ch <= 'z')) return 1;
    if ((ch >= 'A') && (ch <= 'Z')) return 1;
    if ((ch >= '0') && (ch <= '9')) return 1;
    if (ch == '_')  return 1;
    if (ch == '$')  return 1;
    if (ch == '\\') return 1;
    if (ch > 126)   return 1;
    return 0;
}
bool charIsInfix(char ch) {
    /* EOL characters before+after these characters can be removed */
    if (ch == ',')  return 1;
    if (ch == ';')  return 1;
    if (ch == ':')  return 1;
    if (ch == '=')  return 1;
    if (ch == '&')  return 1;
    if (ch == '%')  return 1;
    if (ch == '*')  return 1;
    if (ch == '<')  return 1;
    if (ch == '>')  return 1;
    if (ch == '?')  return 1;
    if (ch == '|')  return 1;
    if (ch == '\n') return 1;
    return 0;
}
bool charIsPrefix(char ch) {
    /* EOL characters after these characters can be removed */
    if (ch == '{')  return 1;
    if (ch == '(')  return 1;
    if (ch == '[')  return 1;
    if (ch == '!')  return 1;
    return charIsInfix(ch);
}
bool charIsPostfix(char ch) {
    /* EOL characters before these characters can be removed */
    if (ch == '}')  return 1;
    if (ch == ')')  return 1;
    if (ch == ']')  return 1;
    return charIsInfix(ch);
}

/* ****************************************************************************
 * TYPE DEFINITIONS
 * ****************************************************************************
 */
typedef enum {
    NODE_EMPTY,
    NODE_WHITESPACE,
    NODE_BLOCKCOMMENT,
    NODE_LINECOMMENT,
    NODE_IDENTIFIER,
    NODE_LITERAL,
    NODE_SIGIL
} NodeType;
#ifdef DEBUG
static char* strNodeTypes[] = {
    "empty",
    "whitespace",
    "block comment",
    "line comment",
    "identifier",
    "literal",
    "sigil"
    };
#endif

struct _Node;
typedef struct _Node Node;
struct _Node {
    /* linked list pointers */
    Node*       prev;
    Node*       next;
    /* node internals */
    char*       contents;
    size_t      length;
    NodeType    type;
};

#define NODE_SET_SIZE 50000

struct _NodeSet;
typedef struct _NodeSet NodeSet;
struct _NodeSet {
    /* link to next NodeSet */
    NodeSet*    next;
    /* Nodes in this Set */
    Node        nodes[NODE_SET_SIZE];
    size_t      next_node;
};

typedef struct {
    /* singly linked list of NodeSets */
    NodeSet*    head_set;
    NodeSet*    tail_set;
    /* linked list pointers */
    Node*       head;
    Node*       tail;
    /* doc internals */
    const char* buffer;
    size_t      length;
    size_t      offset;
} JsDoc;


/* ****************************************************************************
 * NODE CHECKING MACROS/FUNCTIONS
 * ****************************************************************************
 */

/* checks to see if the node is the given string, case INSENSITIVELY */
bool nodeEquals(Node* node, const char* string) {
    return (strcasecmp(node->contents, string) == 0);
}

/* checks to see if the node contains the given string, case INSENSITIVELY */
bool nodeContains(Node* node, const char* string) {
    const char* haystack = node->contents;
    size_t len = strlen(string);
    char ul_start[2] = { tolower(*string), toupper(*string) };

    /* if node is shorter we know we're not going to have a match */
    if (len > node->length)
        return 0;

    /* find the needle in the haystack */
    while (haystack && *haystack) {
        /* find first char of needle */
        haystack = strpbrk( haystack, ul_start );
        if (haystack == NULL)
            return 0;
        /* check if the rest matches */
        if (strncasecmp(haystack, string, len) == 0)
            return 1;
        /* nope, move onto next character in the haystack */
        haystack ++;
    }

    /* no match */
    return 0;
}

/* checks to see if the node begins with the given string, case INSENSITIVELY
 */
bool nodeBeginsWith(Node* node, const char* string) {
    size_t len = strlen(string);
    if (len > node->length)
        return 0;
    return (strncasecmp(node->contents, string, len) == 0);
}

/* checks to see if the node ends with the given string, case INSENSITIVELY */
bool nodeEndsWith(Node* node, const char* string) {
    size_t len = strlen(string);
    size_t off = node->length - len;
    if (len > node->length)
        return 0;
    return (strncasecmp(node->contents+off, string, len) == 0);
}

/* macros to help see what kind of node we've got */
#define nodeIsWHITESPACE(node)                  ((node->type == NODE_WHITESPACE))
#define nodeIsBLOCKCOMMENT(node)                ((node->type == NODE_BLOCKCOMMENT))
#define nodeIsLINECOMMENT(node)                 ((node->type == NODE_LINECOMMENT))
#define nodeIsIDENTIFIER(node)                  ((node->type == NODE_IDENTIFIER))
#define nodeIsLITERAL(node)                     ((node->type == NODE_LITERAL))
#define nodeIsSIGIL(node)                       ((node->type == NODE_SIGIL))

#define nodeIsEMPTY(node)                       ((node->type == NODE_EMPTY) || (node->length==0) || (node->contents=NULL))
#define nodeIsCOMMENT(node)                     (nodeIsBLOCKCOMMENT(node) || nodeIsLINECOMMENT(node))
#define nodeIsIECONDITIONALBLOCKCOMMENT(node)   (nodeIsBLOCKCOMMENT(node) && nodeBeginsWith(node,"/*@") && nodeEndsWith(node,"@*/"))
#define nodeIsIECONDITIONALLINECOMMENT(node)    (nodeIsLINECOMMENT(node) && nodeBeginsWith(node,"//@"))
#define nodeIsIECONDITIONALCOMMENT(node)        (nodeIsIECONDITIONALBLOCKCOMMENT(node) || nodeIsIECONDITIONALLINECOMMENT(node))
#define nodeIsPREFIXSIGIL(node)                 (nodeIsSIGIL(node) && charIsPrefix(node->contents[0]))
#define nodeIsPOSTFIXSIGIL(node)                (nodeIsSIGIL(node) && charIsPostfix(node->contents[0]))
#define nodeIsENDSPACE(node)                    (nodeIsWHITESPACE(node) && charIsEndspace(node->contents[0]))
#define nodeIsCHAR(node,ch)                     ((node->contents[0]==ch) && (node->length==1))

/* ****************************************************************************
 * NODE MANIPULATION FUNCTIONS
 * ****************************************************************************
 */
/* allocates a new node */
Node* JsAllocNode(JsDoc* doc) {
    Node* node;
    NodeSet* set = doc->tail_set;

    /* if our current NodeSet is full, allocate a new NodeSet */
    if (set->next_node >= NODE_SET_SIZE) {
        NodeSet* next_set;
        Newz(0, next_set, 1, NodeSet);
        set->next = next_set;
        doc->tail_set = next_set;
        set = next_set;
    }

    /* grab the next Node out of the NodeSet */
    node = set->nodes + set->next_node;
    set->next_node ++;

    /* initialize the node */
    node->prev = NULL;
    node->next = NULL;
    node->contents = NULL;
    node->length = 0;
    node->type = NODE_EMPTY;
    return node;
}

/* clears the contents of a node */
void JsClearNodeContents(Node* node) {
    if (node->contents)
        Safefree(node->contents);
    node->contents = NULL;
    node->length = 0;
}

/* sets the contents of a node */
void JsSetNodeContents(Node* node, const char* string, size_t len) {
    /* if the buffer is already big enough, just overwrite it */
    if (node->length >= len) {
        memcpy( node->contents, string, len );
        node->contents[len] = '\0';
        node->length = len;
    }
    /* otherwise free the buffer, allocate a new one, and copy it in */
    else {
        JsClearNodeContents(node);
        node->length = len;
        /* allocate string, fill with NULLs, and copy */
        Newz(0, node->contents, (len+1), char);
        memcpy( node->contents, string, len );
    }
}

/* removes the node from the list and discards it entirely */
void JsDiscardNode(Node* node) {
    if (node->prev)
        node->prev->next = node->next;
    if (node->next)
        node->next->prev = node->prev;
}

/* appends the node to the given element */
void JsAppendNode(Node* element, Node* node) {
    if (element->next)
        element->next->prev = node;
    node->next = element->next;
    node->prev = element;
    element->next = node;
}

/* collapses a node to a single whitespace character */
void JsCollapseNodeToWhitespace(Node* node) {
    if (node->contents) {
        node->length = 1;
        node->contents[1] = '\0';
    }
}

/* ****************************************************************************
 * TOKENIZING FUNCTIONS
 * ****************************************************************************
 */

/* extracts a quoted literal string */
void _JsExtractLiteral(JsDoc* doc, Node* node) {
    const char* buf = doc->buffer;
    size_t offset   = doc->offset;
    char delimiter  = buf[offset];
    bool in_char_class = 0;
    /* skip start of literal */
    offset ++;
    /* search for end of literal */
    while (offset < doc->length) {
        if (buf[offset] == '\\') {
            /* escaped character; skip */
            offset ++;
        }
        else {
            /* if in a regex, track if we're in a character class */
            if (delimiter == '/') {
                if ((buf[offset] == '[') && !in_char_class) {
                    in_char_class = 1;
                }
                if ((buf[offset] == ']') && in_char_class) {
                    in_char_class = 0;
                }
            }
            /* if we have found the end of the literal, store it */
            if ((buf[offset] == delimiter) && !in_char_class) {
                const char* start = buf + doc->offset;
                size_t length     = offset - doc->offset + 1;
                JsSetNodeContents(node, start, length);
                node->type = NODE_LITERAL;
                return;
            }
        }
        /* move onto next character */
        offset ++;
    }
    croak( "unterminated quoted string literal" );
}

/* extracts a block comment */
void _JsExtractBlockComment(JsDoc* doc, Node* node) {
    const char* buf = doc->buffer;
    size_t offset   = doc->offset;

    /* skip start of comment */
    offset ++;  /* skip "/" */
    offset ++;  /* skip "*" */

    /* search for end of comment block */
    while (offset < doc->length) {
        if (buf[offset] == '*') {
            if (buf[offset+1] == '/') {
                const char* start = buf + doc->offset;
                size_t length     = offset - doc->offset + 2;
                JsSetNodeContents(node, start, length);
                node->type = NODE_BLOCKCOMMENT;
                return;
            }
        }
        /* move onto next character */
        offset ++;
    }

    croak( "unterminated block comment" );
}

/* extracts a line comment */
void _JsExtractLineComment(JsDoc* doc, Node* node) {
    const char* buf = doc->buffer;
    size_t offset   = doc->offset;

    /* skip start of comment */
    offset ++;  /* skip "/" */
    offset ++;  /* skip "/" */

    /* search for end of line */
    while ((offset < doc->length) && !charIsEndspace(buf[offset]))
        offset ++;

    /* found it ! */
    {
        const char* start = buf + doc->offset;
        size_t length = offset - doc->offset;
        JsSetNodeContents(node, start, length);
        node->type = NODE_LINECOMMENT;
    }
}

/* extracts a run of whitespace characters */
void _JsExtractWhitespace(JsDoc* doc, Node* node) {
    const char* buf = doc->buffer;
    size_t offset   = doc->offset;
    while ((offset < doc->length) && charIsWhitespace(buf[offset]))
        offset ++;
    JsSetNodeContents(node, doc->buffer+doc->offset, offset-doc->offset);
    node->type = NODE_WHITESPACE;
}

/* extracts an identifier */
void _JsExtractIdentifier(JsDoc* doc, Node* node) {
    const char* buf = doc->buffer;
    size_t offset   = doc->offset;
    while ((offset < doc->length) && charIsIdentifier(buf[offset]))
        offset ++;
    JsSetNodeContents(node, doc->buffer+doc->offset, offset-doc->offset);
    node->type = NODE_IDENTIFIER;
}

/* extracts a -single- symbol/sigil */
void _JsExtractSigil(JsDoc* doc, Node* node) {
    JsSetNodeContents(node, doc->buffer+doc->offset, 1);
    node->type = NODE_SIGIL;
}

/* tokenizes the given string and returns the list of nodes */
Node* JsTokenizeString(JsDoc* doc, const char* string) {
    /* parse the JS */
    while ((doc->offset < doc->length) && (doc->buffer[doc->offset])) {
        /* allocate a new node */
        Node* node = JsAllocNode(doc);
        if (!doc->head)
            doc->head = node;
        if (!doc->tail)
            doc->tail = node;

        /* parse the next node out of the JS */
        if (doc->buffer[doc->offset] == '/') {
            if (doc->buffer[doc->offset+1] == '*')
                _JsExtractBlockComment(doc, node);
            else if (doc->buffer[doc->offset+1] == '/')
                _JsExtractLineComment(doc, node);
            else {
                /* could be "division" or "regexp", but need to know more about
                 * our context...
                 */
                Node* last = doc->tail;
                char ch = 0;

                /* find last non-whitespace, non-comment node */
                while (nodeIsWHITESPACE(last) || nodeIsCOMMENT(last))
                    last = last->prev;

                ch = last->contents[last->length-1];

                /* see if we're "division" or "regexp" */
                if (nodeIsIDENTIFIER(last) && nodeEquals(last, "return")) {
                    /* returning a regexp from a function */
                    _JsExtractLiteral(doc, node);
                }
                else if (ch && ((ch == ')') || (ch == '.') || (ch == ']') || (charIsIdentifier(ch)))) {
                    /* looks like an identifier; guess its division */
                    _JsExtractSigil(doc, node);
                }
                else {
                    /* presume its a regexp */
                    _JsExtractLiteral(doc, node);
                }
            }
        }
        else if ((doc->buffer[doc->offset] == '"') || (doc->buffer[doc->offset] == '\'')  || (doc->buffer[doc->offset] == '`'))
            _JsExtractLiteral(doc, node);
        else if (charIsWhitespace(doc->buffer[doc->offset]))
            _JsExtractWhitespace(doc, node);
        else if (charIsIdentifier(doc->buffer[doc->offset]))
            _JsExtractIdentifier(doc, node);
        else
            _JsExtractSigil(doc, node);

        /* move ahead to the end of the parsed node */
        doc->offset += node->length;

        /* add the node to our list of nodes */
        if (node != doc->tail)
            JsAppendNode(doc->tail, node);
        doc->tail = node;

        /* some debugging info */
#ifdef DEBUG
        {
            int idx;
            printf("----------------------------------------------------------------\n");
            printf("%s: [%s]\n", strNodeTypes[node->type], node->contents);
            printf("next: [");
            for (idx=0; idx<=10; idx++) {
                if ((doc->offset+idx) >= doc->length) break;
                if (!doc->buffer[doc->offset+idx])    break;
                printf("%c", doc->buffer[doc->offset+idx]);
            }
            printf("]\n");
        }
#endif
    }

    /* return the node list */
    return doc->head;
}

/* ****************************************************************************
 * MINIFICATION FUNCTIONS
 * ****************************************************************************
 */

/* collapses all of the nodes to their shortest possible representation */
void JsCollapseNodes(Node* curr) {
    while (curr) {
        Node* next = curr->next;
        switch (curr->type) {
            case NODE_WHITESPACE:
                /* all WS gets collapsed */
                JsCollapseNodeToWhitespace(curr);
                break;
            case NODE_BLOCKCOMMENT:
                /* IE Conditional Compilation comments do not get collapsed */
                if (nodeIsIECONDITIONALBLOCKCOMMENT(curr)) {
                  break;
                }
                /* block comments get collapsed to WS if that's a side-affect
                 * of their placement in the JS document.
                 */
                {
                    bool convert_to_ws = 0;
                    /* find surrounding non-WS nodes */
                    Node* nonws_prev = curr->prev;
                    Node* nonws_next = curr->next;
                    while (nonws_prev && nodeIsWHITESPACE(nonws_prev))
                        nonws_prev = nonws_prev->prev;
                    while (nonws_next && nodeIsWHITESPACE(nonws_next))
                        nonws_next = nonws_next->next;
                    /* check what we're between... */
                    if (nonws_prev && nonws_next) {
                        /* between identifiers? convert to WS */
                        if (nodeIsIDENTIFIER(nonws_prev) && nodeIsIDENTIFIER(nonws_next))
                            convert_to_ws = 1;
                        /* between possible pre/post increment? convert to WS */
                        if (nodeIsCHAR(nonws_prev,'-') && nodeIsCHAR(nonws_next,'-'))
                            convert_to_ws = 1;
                        if (nodeIsCHAR(nonws_prev,'+') && nodeIsCHAR(nonws_next,'+'))
                            convert_to_ws = 1;
                    }
                    /* convert to WS */
                    if (convert_to_ws) {
                        JsSetNodeContents(curr," ",1);
                        curr->type = NODE_WHITESPACE;
                    }
                }
                break;
            default:
                break;
        }
        curr = next;
    }
}

/* checks to see whether we can prune the given node from the list.
 *
 * THIS is the function that controls the bulk of the minification process.
 */
enum {
    PRUNE_NO,
    PRUNE_PREVIOUS,
    PRUNE_CURRENT,
    PRUNE_NEXT
};
int JsCanPrune(Node* node) {
    Node* prev = node->prev;
    Node* next = node->next;

    switch (node->type) {
        case NODE_EMPTY:
            /* prune empty nodes */
            return PRUNE_CURRENT;
        case NODE_WHITESPACE:
            /* multiple whitespace gets pruned to preserve endspace */
            if (prev && nodeIsENDSPACE(prev))
                return PRUNE_CURRENT;
            if (prev && nodeIsWHITESPACE(prev))
                return PRUNE_PREVIOUS;
            /* leading whitespace gets pruned */
            if (!prev)
                return PRUNE_CURRENT;
            /* trailing whitespace gets pruned */
            if (!next)
                return PRUNE_CURRENT;
            /* keep all other whitespace */
            return PRUNE_NO;
        case NODE_BLOCKCOMMENT:
            /* keep comments that contain the word "copyright" */
            if (nodeContains(node, "copyright"))
                return PRUNE_NO;
            /* keep comments that are for IE Conditional Compilation */
            if (nodeIsIECONDITIONALBLOCKCOMMENT(node))
                return PRUNE_NO;
            /* block comments get pruned */
            return PRUNE_CURRENT;
        case NODE_LINECOMMENT:
            /* keep comments that contain the word "copyright" */
            if (nodeContains(node, "copyright"))
                return PRUNE_NO;
            /* keep comments that are for IE Conditional Compilation */
            if (nodeIsIECONDITIONALLINECOMMENT(node))
                return PRUNE_NO;
            /* line comments get pruned */
            return PRUNE_CURRENT;
        case NODE_IDENTIFIER:
            /* remove whitespace (but NOT endspace) after identifiers, provided
             * that next thing is -NOT- another identifier
             */
            if (next && nodeIsWHITESPACE(next) && !nodeIsENDSPACE(next) && next->next && !nodeIsIDENTIFIER(next->next))
                return PRUNE_NEXT;
            /* keep all identifiers */
            return PRUNE_NO;
        case NODE_LITERAL:
            /* keep all literals */
            return PRUNE_NO;
        case NODE_SIGIL:
            /* remove whitespace after "prefix" sigils */
            if (nodeIsPREFIXSIGIL(node) && next && nodeIsWHITESPACE(next))
                return PRUNE_NEXT;
            /* remove whitespace before "postfix" sigils */
            if (nodeIsPOSTFIXSIGIL(node) && prev && nodeIsWHITESPACE(prev) && prev->prev && !nodeIsLINECOMMENT(prev->prev))
                return PRUNE_PREVIOUS;
            /* remove whitespace (but NOT endspace) after closing brackets */
            if (next && nodeIsWHITESPACE(next) && !nodeIsENDSPACE(next) && (nodeIsCHAR(node,')') || nodeIsCHAR(node,'}') || nodeIsCHAR(node,']')))
                return PRUNE_NEXT;
            /* remove whitespace surrounding "/", EXCEPT where it'd cause "//" */
            if (nodeIsCHAR(node,'/') && prev && nodeIsWHITESPACE(prev) && prev->prev && !nodeEndsWith(prev->prev,"/"))
                return PRUNE_PREVIOUS;
            if (nodeIsCHAR(node,'/') && next && nodeIsWHITESPACE(next) && next->next && !nodeBeginsWith(next->next,"/"))
                return PRUNE_NEXT;
            /* remove whitespace (but NOT endspace) surrounding "-", EXCEPT where it'd cause "--" */
            if (nodeIsCHAR(node,'-') && prev && nodeIsWHITESPACE(prev) && !nodeIsENDSPACE(prev) && prev->prev && !nodeIsCHAR(prev->prev,'-'))
                return PRUNE_PREVIOUS;
            if (nodeIsCHAR(node,'-') && next && nodeIsWHITESPACE(next) && !nodeIsENDSPACE(next) && next->next && !nodeIsCHAR(next->next,'-'))
                return PRUNE_NEXT;
            /* remove whitespace (but NOT endspace) surrounding "+", EXCEPT where it'd cause "++" */
            if (nodeIsCHAR(node,'+') && prev && nodeIsWHITESPACE(prev) && !nodeIsENDSPACE(prev) && prev->prev && !nodeIsCHAR(prev->prev,'+'))
                return PRUNE_PREVIOUS;
            if (nodeIsCHAR(node,'+') && next && nodeIsWHITESPACE(next) && !nodeIsENDSPACE(next) && next->next && !nodeIsCHAR(next->next,'+'))
                return PRUNE_NEXT;
            /* keep all other sigils */
            return PRUNE_NO;
    }
    /* keep anything else */
    return PRUNE_NO;
}

/* prune nodes from the list */
Node* JsPruneNodes(Node *head) {
    Node* curr = head;
    while (curr) {
        /* see if/howe we can prune this node */
        int prune = JsCanPrune(curr);
        /* prune.  each block is responsible for moving onto the next node */
        Node* prev = curr->prev;
        Node* next = curr->next;
        switch (prune) {
            case PRUNE_PREVIOUS:
                /* discard previous node */
                JsDiscardNode(prev);
                /* reset "head" if that's what got pruned */
                if (prev == head)
                    prev = curr;
                break;
            case PRUNE_CURRENT:
                /* discard current node */
                JsDiscardNode(curr);
                /* reset "head" if that's what got pruned */
                if (curr == head)
                    head = prev ? prev : next;
                /* backup and try again if possible */
                curr = prev ? prev : next;
                break;
            case PRUNE_NEXT:
                /* discard next node */
                JsDiscardNode(next);
                /* stay on current node, and try again */
                break;
            default:
                /* move ahead to next node */
                curr = next;
                break;
        }
    }

    /* return the (possibly new) head node back to the caller */
    return head;
}

/* ****************************************************************************
 * Minifies the given JavaScript, returning a newly allocated string back to
 * the caller (YOU'RE responsible for freeing its memory).
 * ****************************************************************************
 */
char* JsMinify(const char* string) {
    char* results;
    JsDoc doc;

    /* initialize our JS document object */
    doc.head = NULL;
    doc.tail = NULL;
    doc.buffer = string;
    doc.length = strlen(string);
    doc.offset = 0;
    Newz(0, doc.head_set, 1, NodeSet);
    doc.tail_set = doc.head_set;

    /* PASS 1: tokenize JS into a list of nodes */
    Node* head = JsTokenizeString(&doc, string);
    if (!head) return NULL;
    /* PASS 2: collapse nodes */
    JsCollapseNodes(head);
    /* PASS 3: prune nodes */
    head = JsPruneNodes(head);
    if (!head) return NULL;
    /* PASS 4: re-assemble JS into single string */
    {
        Node* curr;
        char* ptr;
        /* allocate the result buffer to the same size as the original JS; in a
         * worst case scenario that's how much memory we'll need for it.
         */
        Newz(0, results, (strlen(string)+1), char);
        ptr = results;
        /* copy node contents into result buffer */
        curr = head;
        while (curr) {
            memcpy(ptr, curr->contents, curr->length);
            ptr += curr->length;
            curr = curr->next;
        }
        *ptr = 0;
    }
    /* free memory used by the NodeSets */
    {
        NodeSet* curr = doc.head_set;
        while (curr) {
            NodeSet* next = curr->next;
            Safefree(curr);
            curr = next;
        }
    }
    /* return resulting minified JS back to caller */
    return results;
}



MODULE = JavaScript::Minifier::XS       PACKAGE = JavaScript::Minifier::XS

PROTOTYPES: disable

SV*
minify(string)
    SV* string
    INIT:
        char* buffer = NULL;
        RETVAL = &PL_sv_undef;
    CODE:
        /* minify the JavaScript */
        buffer = JsMinify( SvPVX(string) );
        /* hand back the minified JS (if we had any) */
        if (buffer != NULL) {
            RETVAL = newSVpv(buffer, 0);
            Safefree( buffer );
        }
    OUTPUT:
        RETVAL
