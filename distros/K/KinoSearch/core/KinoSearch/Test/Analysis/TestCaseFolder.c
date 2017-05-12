#define C_KINO_TESTCASEFOLDER
#include "KinoSearch/Util/ToolSet.h"

#include "KinoSearch/Test.h"
#include "KinoSearch/Test/TestUtils.h"
#include "KinoSearch/Test/Analysis/TestCaseFolder.h"
#include "KinoSearch/Analysis/CaseFolder.h"

static void
test_Dump_Load_and_Equals(TestBatch *batch)
{
    CaseFolder *case_folder = CaseFolder_new();
    CaseFolder *other       = CaseFolder_new();
    Obj        *dump        = (Obj*)CaseFolder_Dump(case_folder);
    CaseFolder *clone       = (CaseFolder*)CaseFolder_Load(other, dump);

    TEST_TRUE(batch, CaseFolder_Equals(case_folder, (Obj*)other), "Equals");
    TEST_FALSE(batch, CaseFolder_Equals(case_folder, (Obj*)&EMPTY), "Not Equals");
    TEST_TRUE(batch, CaseFolder_Equals(case_folder, (Obj*)clone), 
        "Dump => Load round trip");

    DECREF(case_folder);
    DECREF(other);
    DECREF(dump);
    DECREF(clone);
}

static void
test_analysis(TestBatch *batch)
{
    CaseFolder *case_folder = CaseFolder_new();
    CharBuf *source = CB_newf("caPiTal ofFensE");
    VArray *wanted = VA_new(1);
    VA_Push(wanted, (Obj*)CB_newf("capital offense"));
    TestUtils_test_analyzer(batch, (Analyzer*)case_folder, source, wanted, 
        "lowercase plain text");
    DECREF(wanted);
    DECREF(source);
    DECREF(case_folder);
}

void
TestCaseFolder_run_tests()
{
    TestBatch *batch = TestBatch_new(6);

    TestBatch_Plan(batch);

    test_Dump_Load_and_Equals(batch);
    test_analysis(batch);

    DECREF(batch);
}


/* Copyright 2005-2011 Marvin Humphrey
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

