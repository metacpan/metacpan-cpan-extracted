#ifndef HEADER_H_
#define HEADER_H_

/*
 * A definition of a header, useful for:
 * 1. Storing a list of standardised headers, sorted in the "proper" order.
 * 2. Quickly determining if a header is of a given type, or a standard one.
 * 3. Adding user-defined headers, respecting the proper order.
 *
 * See static array standard_headers[] in header.c for the definition of all
 * standard headers.
 */

#define HEADER_TYPE_NONE     999 /* should be greater than all other types */
#define HEADER_TYPE_GENERAL  100
#define HEADER_TYPE_REQUEST  200
#define HEADER_TYPE_RESPONSE 300
#define HEADER_TYPE_ENTITY   400

typedef struct Header {
  int order;   /* the order / grouping of the header */
  char* name;  /* the header name */
} Header;

/*
 * Create a Header object.
 */
Header* header_create(const char* name);

/*
 * Clone a given Header object.
 */
Header* header_clone(Header* header);

/*
 * Destroy a Header object.
 *
 * If header's type is not HEADER_TYPE_NONE, do nothing.
 */
void header_destroy(Header* header);

/*
 * Compare two strings as if they were header names.  Return results similar
 * to strcmp().
 */
int header_compare(const char* n1, const char* n2);

/*
 * Return true if header matches a specific type, or if it matches the given
 * name.
 */
int header_matches_type_or_name(const Header* h, int type, const char* name);

/*
 * Search standard headers for a given type / name.
 */
Header* header_lookup_standard(int type, const char* name);

/*
 * Dump Header object to an output stream.
 */
void header_dump(const Header* h, FILE* fp);

/*
 * Return true if this header is an entity header.
 */
int header_is_entity(const Header* h);

#endif
