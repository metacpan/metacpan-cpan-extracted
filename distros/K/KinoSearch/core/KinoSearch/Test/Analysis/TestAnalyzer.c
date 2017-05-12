#include "KinoSearch/Util/ToolSet.h"

#include "KinoSearch/Test.h"
#include "KinoSearch/Test/TestUtils.h"
#include "KinoSearch/Test/Analysis/TestAnalyzer.h"
#include "KinoSearch/Analysis/Analyzer.h"
#include "KinoSearch/Analysis/Inversion.h"

DummyAnalyzer*
DummyAnalyzer_new()
{
    DummyAnalyzer *self = (DummyAnalyzer*)VTable_Make_Obj(DUMMYANALYZER);
    return DummyAnalyzer_init(self);
}

DummyAnalyzer*
DummyAnalyzer_init(DummyAnalyzer *self)
{
    return (DummyAnalyzer*)Analyzer_init((Analyzer*)self);
}

Inversion*
DummyAnalyzer_transform(DummyAnalyzer *self, Inversion *inversion)
{
    UNUSED_VAR(self);
    return (Inversion*)INCREF(inversion);
}

static void
test_analysis(TestBatch *batch)
{
    DummyAnalyzer *analyzer = DummyAnalyzer_new();
    CharBuf *source = CB_newf("foo bar baz");
    VArray *wanted = VA_new(1);
    VA_Push(wanted, (Obj*)CB_newf("foo bar baz"));
    TestUtils_test_analyzer(batch, (Analyzer*)analyzer, source, wanted, 
        "test basic analysis");
    DECREF(wanted);
    DECREF(source);
    DECREF(analyzer);
}

void
TestAnalyzer_run_tests()
{
    TestBatch *batch = TestBatch_new(3);

    TestBatch_Plan(batch);

    test_analysis(batch);

    DECREF(batch);
}

/* Copyright 2005-2011 Marvin Humphrey
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

