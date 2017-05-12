/*
 * Warning: This file is to generate the base C wrapper and Perl module
 * using Swig 2.0.x with the command: `swig -perl -const foundationdb.i`
 *
 * Should you wish to modify it (assuming you know what you're doing),
 * you *MUST* manually merge the changes from the C and Perl output files
 * into their respective Fdb.c and lib/Fdb.pm files.
 * 
 * Much manual work has been or will be done, especially in the lib/Fdb.pm
 * file. It's not expected that anyone will be crazy enough to modify the
 * generated C wrapper file, but better safe than sorry.
 * You've been warned.
 *
 */

%module Fdb
%{
#define FDB_API_VERSION 21
#include <foundationdb/fdb_c.h>
%}

%include typemaps.i

%rename("%(regex:/fdb_(.*)/\\1/)s") ""; // fdb_some_func -> some_func

// Try to get rid of as many inputs of the form (key, key_length)
// Perl doesn't need to known anything about length!
%typemap(in) (uint8_t const* value, int value_length) {
  $1 = (uint8_t *)SvPV_nolen($input);
  $2 = (int)sv_len($input);
}
%typemap(in) (uint8_t const* key_name, int key_name_length) = (uint8_t const* value, int value_length);
%typemap(in) (uint8_t const* begin_key_name, int begin_key_name_length) = (uint8_t const* value, int value_length);
%typemap(in) (uint8_t const* end_key_name, int end_key_name_length) = (uint8_t const* value, int value_length);
%typemap(in) (uint8_t const* db_name, int db_name_length) = (uint8_t const* value, int value_length);

// The following typemaps are to handle the output parameters
// of the type FDBxxxx** : We don't bother Perl with passing
// them in as inputs. Instead we push a new variable on the
// output stack with the result of the function

%typemap (in,numinputs=0) FDBCluster** (FDBCluster *temp) {
    $1 = &temp;
}

%typemap(argout) (FDBCluster** out_cluster) {
  if (argvi >= items) {
    EXTEND(sp,1);
  }
  SV *sv = sv_newmortal();
  SWIG_MakePtr(sv, temp$argnum, SWIGTYPE_p_cluster, 0);
  $result = sv;
  argvi++;
}

%typemap (in,numinputs=0) FDBDatabase** (FDBDatabase *temp) {
    $1 = &temp;
}

%typemap(argout) (FDBDatabase** out_database) {
  if (argvi >= items) {
    EXTEND(sp,1);
  }
  SV *sv = sv_newmortal();
  SWIG_MakePtr(sv, temp$argnum, SWIGTYPE_p_database, 0);
  $result = sv;
  argvi++;
}

%typemap (in,numinputs=0) FDBTransaction** (FDBTransaction *temp) {
  $1 = &temp;
}

%typemap(argout) (FDBTransaction** out_transaction) {
  if (argvi >= items) {
    EXTEND(sp,1);
  }
  SV *sv = sv_newmortal();
  SWIG_MakePtr(sv, temp$argnum, SWIGTYPE_p_transaction, 0);
  $result = sv;
  argvi++;
}

%typemap (in,numinputs=0) const char** (char *temp) {
  $1 = &temp;
}

%typemap(argout) (const char** out_description) {
  if (argvi >= items) {
    EXTEND(sp,1);
  }
  SV *sv = sv_newmortal();
  SWIG_MakePtr(sv, temp$argnum, SWIGTYPE_p_char, 0);
  $result = sv;
  argvi++;
}

// Get methods that return output value+value_length, e.g.:
//    fdb_future_get_value( FDBFuture* f, fdb_bool_t *out_present,
//                          uint8_t const** out_value,
//                          int* out_value_length );

// first do the "in" typemaps to, as above, get rid of those useless pointers
%typemap (in,numinputs=0) fdb_bool_t* (fdb_bool_t temp) {
 $1 = &temp;
}
%typemap (in,numinputs=0) uint8_t const** (uint8_t *temp) {
 $1 = &temp;
}
%typemap (in,numinputs=0) int* (int temp) {
 $1 = &temp;
}
// Now add to the output the BOOL out_present
%typemap(argout) fdb_bool_t * {
  if (argvi >= items) {
    EXTEND(sp,1);
  }
  SV *sv = newSViv(temp$argnum);
  sv_2mortal(sv);
  $result = sv;
  argvi++;
}
// Finally add to the output the string value, discarding the length
// TODO: FDB outputs a uint8_t pointer, which we convert to a char pointer
// Check how problematic that is
%typemap(argout) (uint8_t const** out_value, int* out_value_length) {
  if (argvi >= items) {
    EXTEND(sp,1);
  }
  SV *sv = newSVpv((char *)*$1, *$2);
  sv_2mortal(sv);
  $result = sv;
  argvi++;
}

// Now handle the get_key:
// fdb_error_t fdb_future_get_key(FDBFuture* future, uint8_t const** out_key, int* out_key_length)
%typemap(argout) (uint8_t const** out_key, int* out_key_length) = (uint8_t const** out_value, int* out_value_length);

// And the get_keyvalue_array:
// fdb_error_t fdb_future_get_keyvalue_array(FDBFuture* future, FDBKeyValue const** out_kv, int* out_count, fdb_bool_t* out_more)
// the last 2 input params are already handled in the typemaps above
// and the last output param (fdb_bool_t*) is also already handled above
%typemap (in,numinputs=0) FDBKeyValue const** (FDBKeyValue* temp) {
  $1 = &temp;
}
%typemap(argout) (FDBKeyValue const** out_kv, int* out_count) {
  // create a perl AV (array) and map all the FDBKeyValues into HVs (hashes) within the AV
  // the result is an arrayref of hashrefs
  AV *av = newAV();
  HV *hv;
  FDBKeyValue *kv;
  for(int i=0;i<*$2;i++) {
    kv = $1[i];
    hv = newHV();
    hv_store(hv, kv->key, kv->key_length, newSVpv(kv->value, kv->value_length), 0);
    av_push(av, newRV_inc((SV *)hv));
  }
  if (argvi >= items) {
    EXTEND(sp,1);
  }
  $result = newRV_inc((SV *)av);
  argvi++;
}

#define FDB_API_VERSION 21
%include </usr/local/include/foundationdb/fdb_c_options.g.h>
%include </usr/local/include/foundationdb/fdb_c.h>

