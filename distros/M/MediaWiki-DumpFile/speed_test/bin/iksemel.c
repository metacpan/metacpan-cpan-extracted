/* Iksemel does not seem to support xpath */

#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <stdlib.h>

#include <iksemel.h>


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
	iksparser *parser;
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

/* SAX handlers */

int
charh(void *p, char *s, size_t len) {
	struct parseinfo *info = (struct parseinfo *)p;

	if (info->do_char) {
		stringbuffer_append(info->buffer, (char *)s, (int)len);
	}

	return IKS_OK;
}

void
starth(struct parseinfo *info, char *el, char **attr) {

	if (strcmp(el, "title") == 0) {
		info->in_title = 1;
		char_on(info);
	} else if (strcmp(el, "text") == 0) {
		info->in_text = 1;
		char_on(info);
	}
}

void
endh(struct parseinfo *info, char *el) {

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

int ikshandler(void *p, char *name, char **attributes, int type) {
	struct parseinfo *userdata = (struct parseinfo *)p;

	if (type == IKS_OPEN) {
		starth(userdata, name, attributes);
	} else if (type == IKS_CLOSE) {
		endh(userdata, name);
	} else if (type == IKS_SINGLE) {
		starth(userdata, name, attributes);
		endh(userdata, name);
	} else {
		fprintf(stderr, "invalid iks type: %i\n", type);
		exit(1);
	}

	return IKS_OK;
}

iksparser * new_iksemel(struct parseinfo *parseinfo) {
	iksparser *p = iks_sax_new(parseinfo, ikshandler, charh);

	return p;
}

int
main(int argc, char **argv) {
  struct parseinfo *info = parseinfo_new();
  iksparser *p = new_iksemel(info);
  char *buf = safe_malloc(BUFSIZ);
  int result;

  for (;;) {
    int done;
    int len;

    len = fread(buf, 1, BUFSIZ, stdin);
    if (ferror(stdin)) {
      fprintf(stderr, "Read error\n");
      exit(-1);
    }
    done = feof(stdin);

    if ((result = iks_parse(p, buf, len, done)) != IKS_OK) {
    	fprintf(stderr, "IKS_OK:%i IKS_NOMEM:%i IKS_BADXML:%i IKS_HOOK:%i - error number: %i\n", IKS_OK, IKS_NOMEM, IKS_BADXML, IKS_HOOK, result);
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
