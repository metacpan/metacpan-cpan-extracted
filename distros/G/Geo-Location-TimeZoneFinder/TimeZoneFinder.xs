/*
 * Map geographic coordinates to time zone names
 *
 * Copyright (C) 2023 Andreas Vögele
 *
 * This module is free software; you can redistribute it and/or modify it
 * under the same terms as Perl itself.
 */

/* SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#define NO_XSLOCKS
#include "XSUB.h"

#ifdef MULTIPLICITY
#define storeTHX(var) (var) = aTHX
#define dTHXfield(var) tTHX var;
#else
#define storeTHX(var) dNOOP
#define dTHXfield(var)
#endif

#include "shapereader/shapereader.h"
#include <stdio.h>
#include <stdlib.h>

/* Index the shapes by their bounding box. */
struct index_entry {
    double bbox[4] ;    /* Bounding box from the shp file */
    size_t file_offset; /* File position of the corresponding polygon */
    SV *time_zone;      /* Time zone name from the dbf file */
};

struct index {
    size_t num_entries;
    struct index_entry *entries;
    struct index_entry **matches; /* Entries that match a location */
};

typedef struct geo_location_timezonefinder {
    SV *dbf_filename;
    SV *shp_filename;
    FILE *dbf_stream;
    FILE *shp_stream;
    size_t dbf_num;
    size_t shp_num;
    struct index index;
    dbf_file_t dbf_fh;
    shp_file_t shp_fh;
    dTHXfield(perl)
} *Geo__Location__TimeZoneFinder;

static void
init_index(Geo__Location__TimeZoneFinder self, size_t num_entries)
{
    dTHXa(self->perl);
    struct index *index;

    index = &self->index;
    Newxz(index->entries, num_entries, struct index_entry);
    Newxz(index->matches, num_entries, struct index_entry *);
    index->num_entries = num_entries;
}

static void
free_index(Geo__Location__TimeZoneFinder self)
{
    dTHXa(self->perl);
    struct index *index;
    struct index_entry *entry;
    size_t n, i;

    index = &self->index;
    if (index->entries != NULL) {
        n = index->num_entries;
        for (i = 0; i < n; ++i) {
            entry = &index->entries[i];
            SvREFCNT_dec(entry->time_zone);
        }
        Safefree(index->entries);
        index->entries = NULL;
    }
    if (index->matches != NULL) {
        Safefree(index->matches);
        index->matches = NULL;
    }
}

static void
free_self(Geo__Location__TimeZoneFinder self)
{
    dTHXa(self->perl);

    free_index(self);
    if (self->dbf_stream != NULL) {
        (void) fclose(self->dbf_stream);
        self->dbf_stream = NULL;
    }
    if (self->shp_stream != NULL) {
        (void) fclose(self->shp_stream);
        self->shp_stream = NULL;
    }
    if (self->dbf_filename != NULL) {
        SvREFCNT_dec(self->dbf_filename);
    }
    if (self->shp_filename != NULL) {
        SvREFCNT_dec(self->shp_filename);
    }
    Safefree(self);
}

static int
is_tzid(const dbf_field_t *field)
{
    return field->type == DBF_TYPE_CHARACTER;
}

static int
handle_dbf_header(dbf_file_t *fh, const dbf_header_t *header)
{
    Geo__Location__TimeZoneFinder self =
      (Geo__Location__TimeZoneFinder) fh->user_data;
    const dbf_field_t *field;
    int has_tzid;

    self->dbf_num = 0;

    has_tzid = 0;

    field = header->fields;
    while (field != NULL) {
        if (is_tzid(field)) {
            has_tzid = 1;
            break;
        }
        field = field->next;
    }

    if (!has_tzid) {
        dbf_set_error(fh, "No tzid field");
        return -1;
    }

    if (header->num_records == 0) {
        dbf_set_error(fh, "No records");
        return -1;
    }

    init_index(self, header->num_records);

    return 1;
}

static int
handle_dbf_record(dbf_file_t *fh, const dbf_header_t *header,
                  const dbf_record_t *record, size_t file_offset)
{
    Geo__Location__TimeZoneFinder self =
       (Geo__Location__TimeZoneFinder) fh->user_data;
    dTHXa(self->perl);
    struct index *index;
    struct index_entry *entry;
    const dbf_field_t *field;
    const char *s;
    size_t len;

    PERL_UNUSED_ARG(file_offset);

    index = &self->index;

    if (dbf_record_is_deleted(record)) {
        return 1;
    }

    if (self->dbf_num >= index->num_entries) {
        dbf_set_error(fh, "Expected %zu records, got %zu", index->num_entries,
                      self->dbf_num);
        return -1;
    }

    entry = &index->entries[self->dbf_num];
    field = header->fields;
    while (field != NULL) {
        if (is_tzid(field)) {
            /* Time zone names are plain ASCII. */
            dbf_record_string(record, field, &s, &len);
            entry->time_zone = newSVpv(s, len);
            ++self->dbf_num;
            break;
        }
        field = field->next;
    }

    return 1;
}

static int
handle_shp_header(shp_file_t *fh, const shp_header_t *header)
{
    Geo__Location__TimeZoneFinder self =
       (Geo__Location__TimeZoneFinder) fh->user_data;

    PERL_UNUSED_ARG(header);

    self->shp_num = 0;

    return 1;
}

static int
handle_shp_record(shp_file_t *fh, const shp_header_t *header,
                  const shp_record_t *record, size_t file_offset)
{
    Geo__Location__TimeZoneFinder self =
       (Geo__Location__TimeZoneFinder) fh->user_data;
    struct index *index;
    struct index_entry *entry;

    PERL_UNUSED_ARG(header);

    index = &self->index;

    if (self->shp_num >= index->num_entries) {
        shp_set_error(fh, "Expected %zu records, got %zu", index->num_entries,
                      self->shp_num);
        return -1;
    }

    entry = &index->entries[self->shp_num];
    if (record->type == SHP_TYPE_POLYGON) {
        entry->bbox[0] = record->shape.polygon.x_min;
        entry->bbox[1] = record->shape.polygon.y_min;
        entry->bbox[2] = record->shape.polygon.x_max;
        entry->bbox[3] = record->shape.polygon.y_max;
        entry->file_offset = file_offset;
        ++self->shp_num;
    }

    return 1;
}

struct ocean_zone {
    const char *tzid;
    double left;
    double right;
};

static const struct ocean_zone ocean_zones[25] = {
    {"Etc/GMT-12", 172.5, 180.0},
    {"Etc/GMT-11", 157.5, 172.5},
    {"Etc/GMT-10", 142.5, 157.5},
    {"Etc/GMT-9", 127.5, 142.5},
    {"Etc/GMT-8", 112.5, 127.5},
    {"Etc/GMT-7", 97.5, 112.5},
    {"Etc/GMT-6", 82.5, 97.5},
    {"Etc/GMT-5", 67.5, 82.5},
    {"Etc/GMT-4", 52.5, 67.5},
    {"Etc/GMT-3", 37.5, 52.5},
    {"Etc/GMT-2", 22.5, 37.5},
    {"Etc/GMT-1", 7.5, 22.5},
    {"Etc/GMT", -7.5, 7.5},
    {"Etc/GMT+1", -22.5, -7.5},
    {"Etc/GMT+2", -37.5, -22.5},
    {"Etc/GMT+3", -52.5, -37.5},
    {"Etc/GMT+4", -67.5, -52.5},
    {"Etc/GMT+5", -82.5, -67.5},
    {"Etc/GMT+6", -97.5, -82.5},
    {"Etc/GMT+7", -112.5, -97.5},
    {"Etc/GMT+8", -127.5, -112.5},
    {"Etc/GMT+9", -142.5, -127.5},
    {"Etc/GMT+10", -157.5, -142.5},
    {"Etc/GMT+11", -172.5, -157.5},
    {"Etc/GMT+12", -180.0, -172.5}
};

static void
get_special_time_zones(Geo__Location__TimeZoneFinder self,
                       const shp_point_t *location, AV *time_zones)
{
    dTHXa(self->perl);
    SV *time_zone;
    double lat, lon;
    int i;

    lon = location->x;
    lat = location->y;
    if (lat == 90.0) {
        /* North Pole */
        for (i = 0; i < 25; ++i) {
            time_zone = newSVpv(ocean_zones[i].tzid, 0);
            av_push(time_zones, time_zone);
        }
    }
    else if (lon == -180.0 || lon == 180.0) {
        /* International Date Line */
        time_zone = newSVpv(ocean_zones[0].tzid, 0);
        av_push(time_zones, time_zone);
        time_zone = newSVpv(ocean_zones[24].tzid, 0);
        av_push(time_zones, time_zone);
    }
}

static void
get_time_zones_at_sea(Geo__Location__TimeZoneFinder self,
                      const shp_point_t *location, AV *time_zones)
{
    dTHXa(self->perl);
    SV *time_zone;
    const struct ocean_zone *z;
    double lon;
    int i;

    lon = location->x;
    for (i = 0; i < 25; ++i) {
        z = &ocean_zones[i];
        if (lon >= z->left && lon <= z->right) {
            time_zone = newSVpv(z->tzid, 0);
            av_push(time_zones, time_zone);
        }
        if (lon >= z->right) {
            break;
        }
    }
}

static void
get_time_zones(Geo__Location__TimeZoneFinder self,
               const shp_point_t *location, AV *time_zones)
{
    dTHXa(self->perl);
    struct index *index;
    struct index_entry *entry;
    size_t n, m, i;
    shp_file_t *fh;
    shp_record_t *record;
    shp_polygon_t *polygon;

    index = &self->index;

    /* How many bounding boxes contain the location? */
    m = 0;
    n = index->num_entries;
    for (i = 0; i < n; ++i) {
        entry = &index->entries[i];
        if (shp_point_in_bounding_box(location, entry->bbox[0],
            entry->bbox[1], entry->bbox[2], entry->bbox[3]) != 0) {
            index->matches[m] = entry;
            ++m;
        }
    }

    /* If there is only one match, return immediately. */
    if (m == 1) {
        entry = index->matches[0];
        av_push(time_zones, SvREFCNT_inc(entry->time_zone));
        return;
    }

    /* Otherwise, check the polygons in the shp file. */
    fh = &self->shp_fh;
    for (i = 0; i < m; ++i) {
        entry = index->matches[i];

        record = NULL;

        if (shp_seek_record(fh, entry->file_offset, &record) < 0) {
            croak("Error reading \"%" SVf "\": %s",
                  SVfARG(self->shp_filename), fh->error);
        }

        if (record != NULL) {
            if (record->type == SHP_TYPE_POLYGON) {
                polygon = &record->shape.polygon;
                if (shp_point_in_polygon(location, polygon) != 0) {
                    av_push(time_zones, SvREFCNT_inc(entry->time_zone));
                }
            }
            free(record);
        }
    }
}

MODULE = Geo::Location::TimeZoneFinder PACKAGE = Geo::Location::TimeZoneFinder

PROTOTYPES: DISABLE

TYPEMAP: <<HERE
Geo::Location::TimeZoneFinder T_PTROBJ
HERE

SV *
new(klass, ...)
    SV *klass
  INIT:
    Geo__Location__TimeZoneFinder self;
    SV *file_base = NULL;
    I32 i;
    const char *key;
    SV *value;
    dbf_file_t *dbf_fh;
    shp_file_t *shp_fh;
    size_t expected_size;
  CODE:
    dXCPT;

    if ((items - 1) % 2 != 0) {
        warn("Odd-length list passed to %" SVf " constructor", SVfARG(klass));
    }

    for (i = 1; i < items; i += 2) {
        key = SvPV_nolen_const(ST(i));
        value = ST(i + 1);
        if (strEQ(key, "file_base")) {
            file_base = value;
        }
    }

    if (file_base == NULL) {
        croak("The \"file_base\" parameter is mandatory");
    }

    Newxz(self, 1, struct geo_location_timezonefinder);
    storeTHX(self->perl);

    XCPT_TRY_START {
        self->dbf_filename = newSVsv(file_base);
        sv_catpvs(self->dbf_filename, ".dbf");
        self->shp_filename = newSVsv(file_base);
        sv_catpvs(self->shp_filename, ".shp");

        /* Open the database file with the time zones. */
        self->dbf_stream = fopen(SvPV_nolen_const(self->dbf_filename), "rb");
        if (self->dbf_stream == NULL) {
            croak("Error opening \"%" SVf "\"", SVfARG(self->dbf_filename));
        }

        /* Open the main file with the shapes. */
        self->shp_stream = fopen(SvPV_nolen_const(self->shp_filename), "rb");
        if (self->shp_stream == NULL) {
            croak("Error opening \"%" SVf "\"", SVfARG(self->shp_filename));
        }

        /* Read the time zones. */
        dbf_fh = dbf_init_file(&self->dbf_fh, self->dbf_stream, self);
        if (dbf_read(dbf_fh, handle_dbf_header, handle_dbf_record) < 0) {
            croak("Error reading \"%" SVf "\": %s",
                  SVfARG(self->dbf_filename), dbf_fh->error);
        }

        /* The time zone file is no longer needed. */
        (void) fclose(self->dbf_stream);
        self->dbf_stream = NULL;

        expected_size = self->index.num_entries;

        if (self->dbf_num != expected_size) {
            croak("Expected %zu records, got %zu in \"%" SVf "\"",
                  expected_size, self->dbf_num, SVfARG(self->dbf_filename));
        }

        /* Index the shapes by their bounding boxes. */
        shp_fh = shp_init_file(&self->shp_fh, self->shp_stream, self);
        if (shp_read(shp_fh, handle_shp_header, handle_shp_record) < 0) {
            croak("Error reading \"%" SVf "\": %s",
                  SVfARG(self->shp_filename), shp_fh->error);
        }

        if (self->shp_num != expected_size) {
            croak("Expected %zu records, got %zu in \"%" SVf "\"",
                  expected_size, self->shp_num, SVfARG(self->shp_filename));
        }
    } XCPT_TRY_END

    XCPT_CATCH {
        free_self(self);
        XCPT_RETHROW;
    }

    RETVAL = sv_bless(newRV_noinc(newSViv(PTR2IV(self))),
                      gv_stashsv(klass, GV_ADD));
  OUTPUT:
    RETVAL

void
time_zones_at(self, ...)
    Geo::Location::TimeZoneFinder self
  ALIAS:
    time_zone_at = 1
  INIT:
    SV *latitude = NULL;
    SV *longitude = NULL;
    NV lat = 0.0;
    NV lon = 0.0;
    I32 i;
    const char *key;
    SV *value;
    shp_point_t location;
    AV *time_zones;
    SSize_t tz_count, tz_num;
    SV **svp;
    U8 gimme = GIMME_V;
  PPCODE:
    if ((items - 1) % 2 != 0) {
        warn("Odd-length list passed to %s method",
             (ix == 1) ? "time_zone_at" : "time_zones_at");
    }

    for (i = 1; i < items; i += 2) {
        key = SvPV_nolen_const(ST(i));
        value = ST(i + 1);
        if (strEQ(key, "lat") || strEQ(key, "latitude")) {
            latitude = value;
        }
        else if (strEQ(key, "lon") || strEQ(key, "longitude")) {
            longitude = value;
        }
    }

    if (latitude == NULL) {
        croak("The \"latitude\" parameter is mandatory");
    }

    if (longitude == NULL) {
        croak("The \"longitude\" parameter is mandatory");
    }

    if (!SvNIOK(latitude)) {
        croak("The \"latitude\" parameter %" SVf " is not a number between "
              "-90 and 90", SVfARG(latitude));
    }

    if (!SvNIOK(longitude)) {
        croak("The \"longitude\" parameter %" SVf " is not a number between "
              "-180 and 180", SVfARG(longitude));
    }

    lat = SvNV(latitude);
    lon = SvNV(longitude);

    if (Perl_isnan(lat) || lat < -90.0 || lat > 90.0) {
        croak("The \"latitude\" parameter %" SVf " is not a number between "
              "-90 and 90", SVfARG(latitude));
    }

    if (Perl_isnan(lon) || lon < -180.0 || lon > 180.0) {
        croak("The \"longitude\" parameter %" SVf " is not a number between "
              "-180 and 180", SVfARG(longitude));
    }

    time_zones = newAV();

    location.x = lon;
    location.y = lat;
    get_special_time_zones(self, &location, time_zones);
    if (av_len(time_zones) < 0) {
        get_time_zones(self, &location, time_zones);
        if (av_len(time_zones) < 0) {
            get_time_zones_at_sea(self, &location, time_zones);
        }
    }

    tz_count = av_len(time_zones) + 1;
    for (tz_num = 0; tz_num < tz_count; ++tz_num) {
        svp = av_fetch(time_zones, tz_num, 0);
        if (svp != NULL) {
            XPUSHs(SvREFCNT_inc(*svp));
            if (gimme == G_SCALAR || ix == 1) {
                break;
            }
        }
    }

    SvREFCNT_dec((SV *) time_zones);

SV *
index(self)
    Geo::Location::TimeZoneFinder self
  INIT:
    AV *results, *box;
    struct index *index;
    struct index_entry *entry;
    size_t n, i;
    HV *rh;
  CODE:
    results = (AV *) sv_2mortal((SV *) newAV());
    index = &self->index;
    n = index->num_entries;
    for (i = 0; i < n; ++i) {
        entry = &index->entries[i];
        rh = (HV *) sv_2mortal((SV *) newHV());
        box = (AV *) sv_2mortal((SV *) newAV());
        av_extend(box, 3);
        av_push(box, newSVnv(entry->bbox[0]));
        av_push(box, newSVnv(entry->bbox[1]));
        av_push(box, newSVnv(entry->bbox[2]));
        av_push(box, newSVnv(entry->bbox[3]));
        hv_store(rh, "bounding_box", 12, newRV_inc((SV *) box), 0);
        hv_store(rh, "file_offset", 11, newSViv(entry->file_offset), 0);
        hv_store(rh, "time_zone", 9, SvREFCNT_inc(entry->time_zone), 0);
        av_push(results, newRV_inc((SV *) rh));
    }
    RETVAL = newRV_inc((SV *) results);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    Geo::Location::TimeZoneFinder self;
  CODE:
    free_self(self);
