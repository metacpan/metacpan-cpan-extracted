/*
   Copyright (C) Andrew Tridgell 1996
   Copyright (C) Paul Mackerras 1996
   Copyright (C) 2002 by Martin Pool <mbp@samba.org>

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "rsync.h"

static int hlink_compare(struct file_struct **file1, struct file_struct **file2)
{
    struct file_struct *f1 = *file1;
    struct file_struct *f2 = *file2;

    if (f1->F_DEV != f2->F_DEV)
        return (int) (f1->F_DEV > f2->F_DEV ? 1 : -1);

    if (f1->F_INODE != f2->F_INODE)
        return (int) (f1->F_INODE > f2->F_INODE ? 1 : -1);

    return file_compare(file1, file2);
}

#define LINKED(p1,p2) ((p1)->F_DEV == (p2)->F_DEV \
		    && (p1)->F_INODE == (p2)->F_INODE)

/* Analyze the data in the hlink_list[], remove items that aren't multiply
 * linked, and replace the dev+inode data with the to+next linked list. */
static void link_idev_data(struct file_list *flist)
{
    struct file_struct *head;
    int from, start;

    alloc_pool_t hlink_pool;
    alloc_pool_t idev_pool = flist->hlink_pool;

    struct file_struct **hlink_list = flist->hlink_list;
    unsigned int hlink_count = flist->hlink_count;

    hlink_pool = pool_create(128 * 1024, sizeof (struct hlink),
        out_of_memory, POOL_INTERN);

    for (from = 0; from < hlink_count;) {
        start = from;
        head = hlink_list[start];
        from++;
        while (from < hlink_count && LINKED(head, hlink_list[from])) {
            pool_free(idev_pool, 0, hlink_list[from]->link_u.idev);
            hlink_list[from]->link_u.links = pool_talloc(hlink_pool,
                struct hlink, 1, "hlink_list");

            /*
            printf("setting %p->to (%s/%s) to %p (%s/%s)\n",
                hlink_list[from], hlink_list[from]->dirname,
                            hlink_list[from]->basename,
                head, head->dirname, head->basename);
            */
            hlink_list[from]->link_u.links->to   = head;
            hlink_list[from]->link_u.links->next = NULL;    /* not used */
            from++;
        }
        if (from > start) {
            /*
             * link to self
             */
            pool_free(idev_pool, 0, head->link_u.idev);
            head->link_u.links = pool_talloc(hlink_pool,
                struct hlink, 1, "hlink_list");
            head->link_u.links->to   = head;
            head->link_u.links->next = NULL;    /* not used */
        } else {
            pool_free(idev_pool, 0, head->link_u.idev);
            head->link_u.idev = NULL;
        }
    }
    free(flist->hlink_list);
    flist->hlink_list = NULL;
    flist->hlink_pool = hlink_pool;
    flist->link_idev_data_done = 1;
    pool_destroy(idev_pool);
}

void init_hard_links(struct file_list *flist)
{
    int i;

    struct file_struct **hlink_list;
    unsigned int hlink_count;

    if (flist->count < 2)
        return;

    if (flist->hlink_list)
        free(flist->hlink_list);

    if (!(flist->hlink_list = new_array(struct file_struct *, flist->count)))
        out_of_memory("init_hard_links");

    hlink_list = flist->hlink_list;

    hlink_count = 0;
    for (i = 0; i < flist->count; i++) {

        if (flist->files[i]->link_u.idev) {
            /*
            printf("init_hard_links: file %d has link %p\n", i,
                flist->files[i]->link_u.idev->inode);
            printf("setting hlink_list[%d] to %p (%s/%s)\n",
                hlink_count, flist->files[i],
                flist->files[i]->dirname, flist->files[i]->basename);
            */
            hlink_list[hlink_count++] = flist->files[i];
        }
    }

    qsort(hlink_list, hlink_count,
        sizeof hlink_list[0], (int (*)()) hlink_compare);

    if (!hlink_count) {
        free(hlink_list);
        hlink_list = NULL;
        flist->hlink_list = hlink_list;
        flist->hlink_count = hlink_count;
    } else {
        flist->hlink_list = hlink_list;
        flist->hlink_count = hlink_count;
        link_idev_data(flist);
    }
}
