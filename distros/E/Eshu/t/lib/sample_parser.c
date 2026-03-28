/*
 * sample_parser.c — A toy recursive-descent expression parser
 */

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

typedef enum {
	TOK_NUM,
	TOK_PLUS,
	TOK_MINUS,
	TOK_STAR,
	TOK_SLASH,
	TOK_LPAREN,
	TOK_RPAREN,
	TOK_EOF
} token_type_t;

typedef struct {
	token_type_t type;
	double value;
} token_t;

typedef struct {
	const char *input;
	size_t pos;
	token_t current;
} parser_t;

static void parser_next(parser_t *p) {
	while (p->input[p->pos] == ' ')
		p->pos++;

	char c = p->input[p->pos];

	if (c == '\0') {
		p->current.type = TOK_EOF;
		return;
	}

	if (isdigit(c) || c == '.') {
		char *end;
		p->current.type = TOK_NUM;
		p->current.value = strtod(p->input + p->pos, &end);
		p->pos = end - p->input;
		return;
	}

	p->pos++;
	switch (c) {
		case '+': p->current.type = TOK_PLUS;   break;
		case '-': p->current.type = TOK_MINUS;  break;
		case '*': p->current.type = TOK_STAR;   break;
		case '/': p->current.type = TOK_SLASH;  break;
		case '(': p->current.type = TOK_LPAREN; break;
		case ')': p->current.type = TOK_RPAREN; break;
		default:
			fprintf(stderr, "Unexpected char: '%c'\n", c);
			exit(1);
	}
}

static double parse_expr(parser_t *p);

static double parse_primary(parser_t *p) {
	if (p->current.type == TOK_NUM) {
		double val = p->current.value;
		parser_next(p);
		return val;
	}
	if (p->current.type == TOK_LPAREN) {
		parser_next(p);
		double val = parse_expr(p);
		if (p->current.type != TOK_RPAREN) {
			fprintf(stderr, "Expected ')'\n");
			exit(1);
		}
		parser_next(p);
		return val;
	}
	if (p->current.type == TOK_MINUS) {
		parser_next(p);
		return -parse_primary(p);
	}
	fprintf(stderr, "Unexpected token\n");
	exit(1);
}

static double parse_term(parser_t *p) {
	double left = parse_primary(p);
	while (p->current.type == TOK_STAR || p->current.type == TOK_SLASH) {
		token_type_t op = p->current.type;
		parser_next(p);
		double right = parse_primary(p);
		if (op == TOK_STAR) {
			left *= right;
		} else {
			if (right == 0.0) {
				fprintf(stderr, "Division by zero\n");
				exit(1);
			}
			left /= right;
		}
	}
	return left;
}

static double parse_expr(parser_t *p) {
	double left = parse_term(p);
	while (p->current.type == TOK_PLUS || p->current.type == TOK_MINUS) {
		token_type_t op = p->current.type;
		parser_next(p);
		double right = parse_term(p);
		if (op == TOK_PLUS)
			left += right;
		else
			left -= right;
	}
	return left;
}

#ifdef PARSER_MAIN
int main(int argc, char **argv) {
	if (argc < 2) {
		fprintf(stderr, "Usage: %s <expression>\n", argv[0]);
		return 1;
	}
	parser_t p;
	p.input = argv[1];
	p.pos = 0;
	parser_next(&p);
	double result = parse_expr(&p);
	printf("%g\n", result);
	return 0;
}
#endif
