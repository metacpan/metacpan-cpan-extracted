#define C_KINO_NOMATCHQUERY
#include "KinoSearch/Util/ToolSet.h"

#include "KinoSearch/Search/NoMatchQuery.h"
#include "KinoSearch/Index/SegReader.h"
#include "KinoSearch/Index/Similarity.h"
#include "KinoSearch/Plan/Schema.h"
#include "KinoSearch/Search/NoMatchScorer.h"
#include "KinoSearch/Search/Searcher.h"
#include "KinoSearch/Store/InStream.h"
#include "KinoSearch/Store/OutStream.h"
#include "KinoSearch/Util/Freezer.h"

NoMatchQuery*
NoMatchQuery_new()
{
    NoMatchQuery *self = (NoMatchQuery*)VTable_Make_Obj(NOMATCHQUERY);
    return NoMatchQuery_init(self);
}

NoMatchQuery*
NoMatchQuery_init(NoMatchQuery *self)
{
    Query_init((Query*)self, 0.0f);
    self->fails_to_match = true;
    return self;
}

bool_t
NoMatchQuery_equals(NoMatchQuery *self, Obj *other)
{
    NoMatchQuery *evil_twin = (NoMatchQuery*)other;
    if (!Obj_Is_A(other, NOMATCHQUERY)) return false;
    if (self->boost != evil_twin->boost) return false;
    if (!!self->fails_to_match != !!evil_twin->fails_to_match) return false;
    return true;
}

CharBuf*
NoMatchQuery_to_string(NoMatchQuery *self)
{
    UNUSED_VAR(self);
    return CB_new_from_trusted_utf8("[NOMATCH]", 9);
}

Compiler*
NoMatchQuery_make_compiler(NoMatchQuery *self, Searcher *searcher, 
                            float boost)
{
    return (Compiler*)NoMatchCompiler_new(self, searcher, boost);
}

void
NoMatchQuery_set_fails_to_match(NoMatchQuery *self, bool_t fails_to_match)
    { self->fails_to_match = fails_to_match; }
bool_t
NoMatchQuery_get_fails_to_match(NoMatchQuery *self) 
    { return self->fails_to_match; }

Obj*
NoMatchQuery_dump(NoMatchQuery *self)
{
    NoMatchQuery_dump_t super_dump
        = (NoMatchQuery_dump_t)SUPER_METHOD(NOMATCHQUERY, NoMatchQuery, Dump);
    Hash *dump = (Hash*)CERTIFY(super_dump(self), HASH);
    Hash_Store_Str(dump, "fails_to_match", 14, (Obj*)CB_newf("%i64",
        (int64_t)self->fails_to_match));
    return (Obj*)dump;
}

NoMatchQuery*
NoMatchQuery_load(NoMatchQuery *self, Obj *dump)
{
    Hash *source = (Hash*)CERTIFY(dump, HASH);
    NoMatchQuery_load_t super_load 
        = (NoMatchQuery_load_t)SUPER_METHOD(NOMATCHQUERY, NoMatchQuery, Load);
    NoMatchQuery *loaded = super_load(self, dump);
    Obj *fails = Cfish_Hash_Fetch_Str(source, "fails_to_match", 14);
    if (fails) {
        loaded->fails_to_match = (bool_t)!!Obj_To_I64(fails);
    }
    else {
        loaded->fails_to_match = true;
    }
    return loaded;
}

void
NoMatchQuery_serialize(NoMatchQuery *self, OutStream *outstream)
{
    OutStream_Write_I8(outstream, !!self->fails_to_match);
}

NoMatchQuery*
NoMatchQuery_deserialize(NoMatchQuery *self, InStream *instream)
{
    self = self ? self : (NoMatchQuery*)VTable_Make_Obj(NOMATCHQUERY);
    NoMatchQuery_init(self);
    self->fails_to_match = !!InStream_Read_I8(instream);
    return self;
}

/**********************************************************************/

NoMatchCompiler*
NoMatchCompiler_new(NoMatchQuery *parent, Searcher *searcher, 
                     float boost)
{
    NoMatchCompiler *self 
        = (NoMatchCompiler*)VTable_Make_Obj(NOMATCHCOMPILER);
    return NoMatchCompiler_init(self, parent, searcher, boost);
}

NoMatchCompiler*
NoMatchCompiler_init(NoMatchCompiler *self, NoMatchQuery *parent, 
                      Searcher *searcher, float boost)
{
    return (NoMatchCompiler*)Compiler_init((Compiler*)self, 
        (Query*)parent, searcher, NULL, boost);
}

NoMatchCompiler*
NoMatchCompiler_deserialize(NoMatchCompiler *self, InStream *instream)
{
    self = self ? self : (NoMatchCompiler*)VTable_Make_Obj(NOMATCHCOMPILER);
    return (NoMatchCompiler*)Compiler_deserialize((Compiler*)self, instream);
}

Matcher*
NoMatchCompiler_make_matcher(NoMatchCompiler *self, SegReader *reader, 
                             bool_t need_score)
{
    UNUSED_VAR(self);
    UNUSED_VAR(reader);
    UNUSED_VAR(need_score);
    return (Matcher*)NoMatchScorer_new();
}

/* Copyright 2008-2011 Marvin Humphrey
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

