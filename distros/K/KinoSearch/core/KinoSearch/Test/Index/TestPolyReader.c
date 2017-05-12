#define C_KINO_TESTPOLYREADER
#include "KinoSearch/Util/ToolSet.h"

#include "KinoSearch/Test.h"
#include "KinoSearch/Test/Index/TestPolyReader.h"
#include "KinoSearch/Index/PolyReader.h"

static void
test_sub_tick(TestBatch *batch)
{
  size_t num_segs = 255;
  int32_t *ints = (int32_t*)MALLOCATE(num_segs * sizeof(int32_t));
  size_t i;
  for (i = 0; i < num_segs; i++) {
    ints[i] = i;
  }
  I32Array *offsets = I32Arr_new(ints, num_segs);
  for (i = 1; i < num_segs; i++) {
    if (PolyReader_sub_tick(offsets, i) != i - 1) { break; }
  }
  TEST_INT_EQ(batch, i, num_segs, "got all sub_tick() calls right");
  DECREF(offsets);
}

void
TestPolyReader_run_tests()
{
    TestBatch *batch = TestBatch_new(1);
    TestBatch_Plan(batch);

    test_sub_tick(batch);

    DECREF(batch);
}

/* Copyright 2010-2011 Marvin Humphrey
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

