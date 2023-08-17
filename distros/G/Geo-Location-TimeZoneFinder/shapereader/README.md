# shapereader

A C library for reading ESRI shapefiles.  The shapefile format is a geospatial
vector data format for geographic information system software.

The library supports the shp, shx and dbf formats.

## DEPENDENCIES

Requires a C compiler that supports the C99 standard and CMake.

## INSTALLATION

Run the following commands to install the library:

    mkdir build
    cd build
    cmake ..
    make
    make test
    make install

See Makefile.PL for information on how to add the library to a Perl XS module.

## EXAMPLES

```c
#include "shapereader/shapereader.h"

void print_field(const dbf_record_t *record, const dbf_field_t *field) {
  char *s;
  double d;

  switch (field->type) {
  case DBF_TYPE_CHARACTER:
    s = dbf_record_strdup(record, field);
    if (s != NULL) {
      puts(s);
      free(s);
    }
    break;
  case DBF_TYPE_FLOAT:
  case DBF_TYPE_NUMBER:
    if (dbf_record_strtod(record, field, &d)) {
      printf("%lf\n", d);
    }
    break;
  }
}

int read_dbf(const char *filename) {
  int rc = -1;
  FILE *stream;
  dbf_file_t fh;
  dbf_header_t *header;
  dbf_record_t *record;
  dbf_field_t *field;

  stream = fopen(filename, "rb");
  if (stream != NULL) {
    dbf_init_file(&fh, stream, NULL);
    if ((rc = dbf_read_header(&fh, &header)) > 0) {
      while ((rc = dbf_read_record(&fh, &record)) > 0) {
        if (!dbf_record_is_deleted(record)) {
          field = header->fields;
          while (field != NULL) {
            print_field(record, field);
            field = field->next;
          }
        }
        free(record);
      }
      free(header);
    }
    if (rc < 0) {
      fprintf(stderr, "%s\n", fh.error);
    }
    fclose(stream);
  }
  return rc;
}

void print_shape(const shp_record_t *record) {
  double x, y;

  switch (record->type) {
  case SHP_TYPE_POINT:
    x = record->shape.point.x;
    y = record->shape.point.y;
    printf("[%lf, %lf]\n", x, y);
    break;
  }
}

int read_shp(const char *filename) {
  int rc = -1;
  FILE *stream;
  shp_file_t fh;
  shp_header_t header;
  shp_record_t *record;

  stream = fopen(filename, "rb");
  if (stream != NULL) {
    shp_init_file(&fh, stream, NULL);
    if ((rc = shp_read_header(&fh, &header)) > 0) {
      while ((rc = shp_read_record(&fh, &record)) > 0) {
        print_shape(record);
        free(record);
      }
    }
    if (rc < 0) {
      fprintf(stderr, "%s\n", fh.error);
    }
    fclose(stream);
  }
  return rc;
}

int main(int argc, char *argv[]) {
  read_dbf("file.dbf");
  read_shp("file.shp");
  return 0;
}
```

## LICENSE AND COPYRIGHT

Copyright (C) 2023 Andreas Vögele

This library is free software; you can redistribute it and/or modify it under
either the terms of the ISC License or the same terms as Perl.
