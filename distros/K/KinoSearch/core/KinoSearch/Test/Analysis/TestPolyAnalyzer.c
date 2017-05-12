#define C_KINO_TESTPOLYANALYZER
#include "KinoSearch/Util/ToolSet.h"

#include "KinoSearch/Test.h"
#include "KinoSearch/Test/TestUtils.h"
#include "KinoSearch/Test/Analysis/TestPolyAnalyzer.h"
#include "KinoSearch/Analysis/PolyAnalyzer.h"
#include "KinoSearch/Analysis/CaseFolder.h"
#include "KinoSearch/Analysis/Stopalizer.h"
#include "KinoSearch/Analysis/Stemmer.h"
#include "KinoSearch/Analysis/Tokenizer.h"

static void
test_Dump_Load_and_Equals(TestBatch *batch)
{
    CharBuf      *EN          = (CharBuf*)ZCB_WRAP_STR("en", 2);
    CharBuf      *ES          = (CharBuf*)ZCB_WRAP_STR("es", 2);
    PolyAnalyzer *analyzer    = PolyAnalyzer_new(EN, NULL);
    PolyAnalyzer *other       = PolyAnalyzer_new(ES, NULL);
    Obj          *dump        = (Obj*)PolyAnalyzer_Dump(analyzer);
    Obj          *other_dump  = (Obj*)PolyAnalyzer_Dump(other);
    PolyAnalyzer *clone       = (PolyAnalyzer*)PolyAnalyzer_Load(other, dump);
    PolyAnalyzer *other_clone 
        = (PolyAnalyzer*)PolyAnalyzer_Load(other, other_dump);

    TEST_FALSE(batch, PolyAnalyzer_Equals(analyzer,
        (Obj*)other), "Equals() false with different language");
    TEST_TRUE(batch, PolyAnalyzer_Equals(analyzer,
        (Obj*)clone), "Dump => Load round trip");
    TEST_TRUE(batch, PolyAnalyzer_Equals(other,
        (Obj*)other_clone), "Dump => Load round trip");

    DECREF(analyzer);
    DECREF(dump);
    DECREF(clone);
    DECREF(other);
    DECREF(other_dump);
    DECREF(other_clone);
}

static void
test_analysis(TestBatch *batch)
{
    CharBuf      *EN          = (CharBuf*)ZCB_WRAP_STR("en", 2);
    CharBuf      *source_text = CB_newf("Eats, shoots and leaves.");
    CaseFolder   *case_folder = CaseFolder_new();
    Tokenizer    *tokenizer   = Tokenizer_new(NULL);
    Stopalizer   *stopalizer  = Stopalizer_new(EN, NULL);
    Stemmer      *stemmer     = Stemmer_new(EN);

    {
        VArray       *analyzers    = VA_new(0);
        PolyAnalyzer *polyanalyzer = PolyAnalyzer_new(NULL, analyzers);
        VArray       *expected     = VA_new(1);
        VA_Push(expected, INCREF(source_text));
        TestUtils_test_analyzer(batch, (Analyzer*)polyanalyzer, source_text,
            expected, "No sub analyzers");
        DECREF(expected);
        DECREF(polyanalyzer);
        DECREF(analyzers);
    }

    {
        VArray       *analyzers    = VA_new(0);
        VA_Push(analyzers, INCREF(case_folder)); 
        PolyAnalyzer *polyanalyzer = PolyAnalyzer_new(NULL, analyzers);
        VArray       *expected     = VA_new(1);
        VA_Push(expected, (Obj*)CB_newf("eats, shoots and leaves."));
        TestUtils_test_analyzer(batch, (Analyzer*)polyanalyzer, source_text,
            expected, "With CaseFolder");
        DECREF(expected);
        DECREF(polyanalyzer);
        DECREF(analyzers);
    }

    {
        VArray       *analyzers    = VA_new(0);
        VA_Push(analyzers, INCREF(case_folder)); 
        VA_Push(analyzers, INCREF(tokenizer)); 
        PolyAnalyzer *polyanalyzer = PolyAnalyzer_new(NULL, analyzers);
        VArray       *expected     = VA_new(1);
        VA_Push(expected, (Obj*)CB_newf("eats"));
        VA_Push(expected, (Obj*)CB_newf("shoots"));
        VA_Push(expected, (Obj*)CB_newf("and"));
        VA_Push(expected, (Obj*)CB_newf("leaves"));
        TestUtils_test_analyzer(batch, (Analyzer*)polyanalyzer, source_text,
            expected, "With Tokenizer");
        DECREF(expected);
        DECREF(polyanalyzer);
        DECREF(analyzers);
    }

    {
        VArray       *analyzers    = VA_new(0);
        VA_Push(analyzers, INCREF(case_folder)); 
        VA_Push(analyzers, INCREF(tokenizer)); 
        VA_Push(analyzers, INCREF(stopalizer)); 
        PolyAnalyzer *polyanalyzer = PolyAnalyzer_new(NULL, analyzers);
        VArray       *expected     = VA_new(1);
        VA_Push(expected, (Obj*)CB_newf("eats"));
        VA_Push(expected, (Obj*)CB_newf("shoots"));
        VA_Push(expected, (Obj*)CB_newf("leaves"));
        TestUtils_test_analyzer(batch, (Analyzer*)polyanalyzer, source_text,
            expected, "With Stopalizer");
        DECREF(expected);
        DECREF(polyanalyzer);
        DECREF(analyzers);
    }

    {
        VArray       *analyzers    = VA_new(0);
        VA_Push(analyzers, INCREF(case_folder)); 
        VA_Push(analyzers, INCREF(tokenizer)); 
        VA_Push(analyzers, INCREF(stopalizer)); 
        VA_Push(analyzers, INCREF(stemmer)); 
        PolyAnalyzer *polyanalyzer = PolyAnalyzer_new(NULL, analyzers);
        VArray       *expected     = VA_new(1);
        VA_Push(expected, (Obj*)CB_newf("eat"));
        VA_Push(expected, (Obj*)CB_newf("shoot"));
        VA_Push(expected, (Obj*)CB_newf("leav"));
        TestUtils_test_analyzer(batch, (Analyzer*)polyanalyzer, source_text,
            expected, "With Stemmer");
        DECREF(expected);
        DECREF(polyanalyzer);
        DECREF(analyzers);
    }

    DECREF(stemmer);
    DECREF(stopalizer);
    DECREF(tokenizer);
    DECREF(case_folder);
    DECREF(source_text);
}

static void
test_Get_Analyzers(TestBatch *batch)
{
    VArray *analyzers = VA_new(0);
    PolyAnalyzer *analyzer = PolyAnalyzer_new(NULL, analyzers);
    TEST_TRUE(batch, PolyAnalyzer_Get_Analyzers(analyzer) == analyzers,
        "Get_Analyzers()");
    DECREF(analyzer);
    DECREF(analyzers);
}

void
TestPolyAnalyzer_run_tests()
{
    TestBatch *batch = TestBatch_new(19);

    TestBatch_Plan(batch);

    test_Dump_Load_and_Equals(batch);
    test_analysis(batch);
    test_Get_Analyzers(batch);

    DECREF(batch);
}


/* Copyright 2005-2011 Marvin Humphrey
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

