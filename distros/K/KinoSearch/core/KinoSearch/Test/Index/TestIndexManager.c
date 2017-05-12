#include "KinoSearch/Util/ToolSet.h"

#include "KinoSearch/Test.h"
#include "KinoSearch/Test/Index/TestIndexManager.h"
#include "KinoSearch/Index/IndexManager.h"

static void
test_Choose_Sparse(TestBatch *batch)
{
    IndexManager *manager = IxManager_new(NULL, NULL);

    for (uint32_t num_segs = 2; num_segs < 20; num_segs++) {
        I32Array *doc_counts = I32Arr_new_blank(num_segs);
        for (uint32_t j = 0; j < num_segs; j++) { 
            I32Arr_Set(doc_counts, j, 1000); 
        }
        uint32_t threshold = IxManager_Choose_Sparse(manager, doc_counts);
        TEST_TRUE(batch, threshold != 1, 
            "Either don't merge, or merge two segments: %u segs, thresh %u", 
            (unsigned)num_segs, (unsigned)threshold);

        if (num_segs != 12 && num_segs != 13) {  // when 2 is correct
            I32Arr_Set(doc_counts, 0, 1);
            threshold = IxManager_Choose_Sparse(manager, doc_counts);
            TEST_TRUE(batch, threshold != 2, 
                "Don't include big next seg: %u segs, thresh %u", 
                (unsigned)num_segs, (unsigned)threshold);
        }

        DECREF(doc_counts);
    }

    DECREF(manager);
}

void
TestIxManager_run_tests()
{
    TestBatch *batch = TestBatch_new(34);
    TestBatch_Plan(batch);
    test_Choose_Sparse(batch);
    DECREF(batch);
}

/* Copyright 2005-2011 Marvin Humphrey
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

