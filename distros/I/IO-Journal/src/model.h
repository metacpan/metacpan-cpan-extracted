/* model.h: Headers containing a module-specific data model
 *
 * This defines some structs and convenient types that are useful for working
 * with libjio in the context of Perl. In particular, it provides a container
 * struct for the underlying journal, so we can store things.
 *
 * This package and its contents are released by the author into the Public
 * Domain, to the full extent permissible by law. For additional information,
 * please see the included `LICENSE' file.
 *
 * $Id: model.h 7351 2009-06-02 14:20:21Z FREQUENCY@cpan.org $
 */

#ifndef _MODEL_H
#define _MODEL_H 1

/* For dealing with the main journal */
struct journal
{
  int fd;
  struct jfs jfs;
};
typedef  struct journal  journal;
typedef  journal  * IO__Journal;

/* For dealing with individual transactions */
struct transaction
{
  journal *journal;
  struct jtrans jtrans;
  int complete;
};
typedef  struct transaction  transaction;
typedef  transaction  * IO__Journal__Transaction;

#endif
