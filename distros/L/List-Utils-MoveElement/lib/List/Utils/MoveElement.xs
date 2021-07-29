#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = List::Utils::MoveElement   PACKAGE = List::Utils::MoveElement

void
to_beginning(idx, ...)
    int    idx;
    CODE:
    {
        int  tmp_idx;
        SV   *tmp;

        /* If the index is > items - 2, it's an error */
        if (idx > items - 2) {
            croak("Index out of range for array");
        }

        /* Shift everything left 1 place, because first argument was idx */
        for (tmp_idx = 0; tmp_idx < items; tmp_idx++) {
          ST(tmp_idx) = ST(tmp_idx + 1);
        }

        /* Check for no-ops */
        if (idx == 0 || items == 2) {
            XSRETURN(items - 1);
        }

        /* Swap element tmp_idx with the one to its left then continue swapping until tmp_idx = 1 */
        for (tmp_idx = idx; tmp_idx >= 1; tmp_idx--) {
            tmp             = ST(tmp_idx - 1);
            ST(tmp_idx - 1) = ST(tmp_idx);
            ST(tmp_idx)     = tmp;
        }
        XSRETURN(items - 1);
    }


void
to_end(idx, ...)
    int    idx;
    CODE:
    {
        int  end_idx;
        int  tmp_idx;
        SV   *tmp;

        end_idx = items - 2;

        /* Index out of range? */
        if (idx > end_idx) {
            croak("Index out of range for array");
        }

        /* Shift everything left 1 place, dropping the first element */
        for (tmp_idx = 0; tmp_idx < items; tmp_idx++) {
          ST(tmp_idx) = ST(tmp_idx + 1);
        }

        /* Check for no-ops */
        if (idx == end_idx || items == 2) {
            XSRETURN(items - 1);
        }

        /* Move element to beginning, reposition remaining */
        for (tmp_idx = idx; tmp_idx <= end_idx-1; tmp_idx++) {
            tmp             = ST(tmp_idx + 1);
            ST(tmp_idx + 1) = ST(tmp_idx);
            ST(tmp_idx)     = tmp;
        }
        XSRETURN(items - 1);
    }


void
left(idx, ...)
    int    idx;
    CODE:
    {
        int  end_idx;
        int  tmp_idx;
        SV   *tmp;

        end_idx = items - 2;

        /* If the index is > items - 2, it's an error */
        if (idx > end_idx) {
            croak("Index out of range for array");
        }

        /* Shift everything left 1 place, dropping the first element */
        for (tmp_idx = 0; tmp_idx < items; tmp_idx++) {
          ST(tmp_idx) = ST(tmp_idx + 1);
        }

        /* Check for no-ops */
        if (idx == 0 || items == 2) {
            XSRETURN(items - 1);
        }

        /* Swap the element with the one to its left */
        tmp         = ST(idx - 1);
        ST(idx - 1) = ST(idx);
        ST(idx)     = tmp;

        XSRETURN(items - 1);
    }


void
right(idx, ...)
    int    idx;
    CODE:
    {
        int  end_idx;
        int  tmp_idx;
        SV   *tmp;

        end_idx = items - 2;

        /* If the index is > items - 2, it's an error */
        if (idx > end_idx) {
            croak("Index out of range for array");
        }

        /* Shift everything left 1 place, dropping the first element */
        for (tmp_idx = 0; tmp_idx < items; tmp_idx++) {
          ST(tmp_idx) = ST(tmp_idx + 1);
        }

        /* Check for no-ops */
        if (idx == end_idx || items == 2) {
            XSRETURN(items - 1);
        }

        /* Swap the element with the one to its right */
        tmp         = ST(idx + 1);
        ST(idx + 1) = ST(idx);
        ST(idx)     = tmp;

        XSRETURN(items - 1);
    }

