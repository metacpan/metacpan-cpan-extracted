#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <stdlib.h>

#include <parser.h>

struct stringbuffer {
	struct stringbuffer *next;
	struct stringbuffer *cur;
	char *data;
	int len;
	int depth;

};

struct parseinfo {
	int in_title;
	int in_text;
	int do_char;
	xmlParserCtxtPtr parser;
	struct stringbuffer *buffer;
};

void * safe_malloc(size_t);
struct stringbuffer * stringbuffer_new(void);
void char_on(struct parseinfo *info);
void char_off(struct parseinfo *info);

/* parseinfo functions */

struct parseinfo * parseinfo_new(void) {
	struct parseinfo *new = safe_malloc(sizeof(struct parseinfo));

	new->in_title = 0;
	new->in_text = 0;
	new->do_char = 0;
	new->buffer = NULL;
	new->parser = NULL;

	return new;
}

/* end parseinfo functions */

/* string buffering functions */

struct stringbuffer * stringbuffer_new(void) {
	struct stringbuffer *new = safe_malloc(sizeof(struct stringbuffer));

	new->cur = new;
	new->next = NULL;
	new->data = NULL;
	new->len = 0;
	new->depth = 0;

	return new;
}

void stringbuffer_free(struct stringbuffer *buffer) {
	struct stringbuffer *p1 = buffer;
	struct stringbuffer *p2;

	while(p1) {
		p2 = p1->next;

		if (p1->data) {
			free(p1->data);
		}

		free(p1);

		p1 = p2;
	}

	return;
}

int stringbuffer_length(struct stringbuffer *buffer) {
	int length = 0;
	struct stringbuffer *cur;

	for(cur = buffer; cur; cur = cur->next) {
		length += cur->len;
	}

	return length;
}

void stringbuffer_append(struct stringbuffer *buffer, char *newstring, int len) {
	char *copy = safe_malloc(len);

	strncpy(copy, newstring, len);

	buffer->cur->data = copy;
	buffer->cur->len = len;
	buffer->cur->next = stringbuffer_new();
	buffer->cur = buffer->cur->next;
	buffer->depth++;
}

char * stringbuffer_string(struct stringbuffer *buffer) {
	int length = stringbuffer_length(buffer);
	char *new = safe_malloc(length + 1);
	char *p = new;
	int copied = 0;
	struct stringbuffer *cur;

	for(cur = buffer;cur;cur = cur->next) {
		if (! cur->data) {
			continue;
		}

		if ((copied = copied + cur->len) > length) {
			fprintf(stderr, "string overflow\n");
			abort();
		}

		strncpy(p, cur->data, cur->len);
		p += cur->len;
	}

	new[length] = '\0';

//	fprintf(stderr, "append depth: %i\n", buffer->depth);

	return new;
}

/* end string buffering functions */

/* expat handlers */

void
charh(void *user, const xmlChar *s, int len) {
	struct parseinfo *info = (struct parseinfo *)user;

	if (info->do_char) {
		stringbuffer_append(info->buffer, (char *)s, len);
	}
}

void
starth(void *user, const xmlChar *el, const xmlChar **attr) {
	struct parseinfo *info = (struct parseinfo *)user;

	if (strcmp(el, "title") == 0) {
		info->in_title = 1;
		char_on(info);
	} else if (strcmp(el, "text") == 0) {
		info->in_text = 1;
		char_on(info);
	}
}

void
endh(void *user, const xmlChar *el) {
	struct parseinfo *info = (struct parseinfo *)user;

	if (info->in_text && strcmp(el, "text") == 0) {
		char *string = stringbuffer_string(info->buffer);
		info->in_text = 0;

		printf("%s\n", string);

		free(string);

		char_off(info);
	} else if (info->in_title && strcmp(el, "title") == 0) {
		char *string = stringbuffer_string(info->buffer);

		info->in_title = 0;

		printf("Title: %s\n", string);
//		fprintf(stderr, "Title: %s\n", string);

		free(string);

		char_off(info);
	}
}

/* end of expat handlers */

xmlParserCtxtPtr new_libxml(struct parseinfo *parseinfo) {
	xmlSAXHandler *saxHandler = safe_malloc(sizeof(xmlSAXHandler));
	xmlParserCtxtPtr p;

	LIBXML_TEST_VERSION

    memset(saxHandler, 0, sizeof(saxHandler));

	saxHandler->startElement = starth;
	saxHandler->endElement = endh;
	saxHandler->characters = charh;

	p = xmlCreatePushParserCtxt(saxHandler, parseinfo, NULL, 0, NULL);

	return p;
}

int
main(int argc, char **argv) {
  struct parseinfo *info = parseinfo_new();
  xmlParserCtxtPtr p = new_libxml(info);
  char *buf = safe_malloc(BUFSIZ);

  for (;;) {
    int done;
    int len;

    len = fread(buf, 1, BUFSIZ, stdin);
    if (ferror(stdin)) {
      fprintf(stderr, "Read error\n");
      exit(-1);
    }
    done = feof(stdin);

    if (xmlParseChunk(p, buf, len, done)) {
    	fprintf(stderr, "XML parse failed\n");
    	exit(1);
    }

    if (done)
      break;
  }

  exit(0);
}

void * safe_malloc(size_t size) {
	void *new = malloc(size);

	if (! new) {
		fprintf(stderr, "could not malloc\n");
		exit(1);
	}

	return new;
}

void char_on(struct parseinfo *info) {
	info->do_char = 1;
	info->buffer = stringbuffer_new();
}

void char_off(struct parseinfo *info) {
	info->do_char = 0;
	stringbuffer_free(info->buffer);
	info->buffer = NULL;
}
