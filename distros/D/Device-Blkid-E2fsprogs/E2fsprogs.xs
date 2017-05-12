/*
 * Ray Mroz - mroz@cpan.org
 *
 * Copyright (C) 2010
 * E2fsprogs.xs
 * December 2010
 *
 * Version: 0.40
 */


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <blkid/blkid.h>
#include <assert.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>


#include "ppport.h"

/*
 *
 * Typedefs - see the typemap file found at the top level of this module
 * package where all types are mapped against the proper PerlAPI types
 *
 */
typedef struct blkid_struct_cache       *Cache;
typedef struct blkid_struct_dev         *Device;
typedef struct blkid_struct_tag_iterate *TagIter;
typedef struct blkid_struct_dev_iterate *DevIter;

/*
 *
 * VERSION 1.33
 *
 * - 17 total calls (original release)
 *
 */

#ifdef __API_1_33
/* extern void blkid_put_cache(blkid_cache cache) */
void _blkid_put_cache(Cache cache)
{
    assert(cache);
    
    blkid_put_cache(cache);
}

/* extern int blkid_get_cache(blkid_cache cache) */
Cache _blkid_get_cache(const char *filename)
{    
    Cache cache;

    assert(filename);
    
    if ( blkid_get_cache( &cache, filename ) )
        croak("Error retrieving cache object: %s\n", strerror(errno));

    return cache;
}

/* extern const char *blkid_dev_devname(blkid_dev dev) */
const char *_blkid_dev_devname(Device device)
{
    const char *devname = NULL;

    assert(device);
    
    devname = blkid_dev_devname(device);
    if (devname == NULL)
        return NULL;

    return devname;
}

/* extern blkid_iterate blkid_iterate_begin(blkid_cache cache) */
DevIter _blkid_dev_iterate_begin(Cache cache)
{
    DevIter iter = NULL;

    assert(cache);

    iter = blkid_dev_iterate_begin(cache);
    if (iter == NULL)
        croak("Error retrieving device iterator object: %s\n", strerror(errno));

    return iter;
}

/* extern int blkid_dev_next(blkid_iterate iterate, blkid_dev *dev) */
Device _blkid_dev_next(DevIter iter)
{
    Device device = NULL;

    assert(iter);
    
    if ( blkid_dev_next(iter, &device) != 0 )
        return NULL;

    return device;
}

/* extern void blkid_iterate_end(blkid_iterate iterate) */
void _blkid_dev_iterate_end(DevIter iter)
{
    assert(iter);
    
    blkid_dev_iterate_end(iter);
}

/* extern char *blkid_devno_to_devname(dev_t devno) */
char *_blkid_devno_to_devname(dev_t devno)
{
    assert(devno);
    
    return blkid_devno_to_devname(devno);
}

/* extern int blkid_probe_all(blkid_cache cache) */
Cache _blkid_probe_all(Cache cache)
{
    assert(cache);
    
    if ( blkid_probe_all(cache) != 0 )
        return NULL;
    else
        return cache;
}


/* extern blkid_dev blkid_get_dev(blkid_cache cache, const char *devname, int flags) */
Device _blkid_get_dev(Cache cache, const char *devname, int flags)
{
    Device device = NULL;

    assert(cache);
    assert(devname);
    assert(flags);
    
    device = blkid_get_dev(cache, devname, flags);
    if (device == NULL)
        croak("Error retrieving device object: %s\n", strerror(errno));
    
    return device;
}


/* extern blkid_loff_t blkid_get_dev_size(int fd) */
SV *_blkid_get_dev_size(const char *devname)
{
    int fd      = 0;
    IV iv_size  = 0;
    SV *sv_size = NULL;

    assert(devname);
    
    fd = open(devname, O_RDONLY);
    if (fd == -1)
        croak("File descriptor allocation : %s", strerror(errno));

    iv_size = blkid_get_dev_size(fd);

    if (iv_size == 1)
        return &PL_sv_undef;

    if ( close(fd) == -1 )
        croak("File descriptor close : %s", strerror(errno));

    sv_size = newSViv(iv_size);    
    
    return sv_size;
}


/* extern char *blkid_get_tag_value(blkid_cache cache, const char *tagname, const char *devname) */
char *_blkid_get_tag_value(Cache cache, const char *tagname, const char *devname)
{   
    char *tag_value = NULL;

    assert(cache);
    assert(tagname);
    assert(devname);
    
    tag_value = blkid_get_tag_value(cache, tagname, devname);
    if (tag_value == NULL)
        return NULL;

    return tag_value;    
}

/* extern char *blkid_get_devname(blkid_cache cache, const char *token, const char *value) */
char *_blkid_get_devname(Cache cache, const char *token, const char *value)
{
    char *devname = NULL;

    assert(cache);
    assert(token);
    assert(value);
    
    devname = blkid_get_devname(cache, token, value);
    if (devname == NULL)
        return NULL;

    return devname;    
}

/* extern blkid_iterate blkid_tag_iterate_begin(blkid_dev dev) */
TagIter _blkid_tag_iterate_begin(Device device)
{
    TagIter iter = NULL;

    assert(device);
    
    iter = blkid_tag_iterate_begin(device);
    if (iter == NULL)
        croak("Error retrieving tag iterator object: %s\n", strerror(errno));

    return iter;
}

/* extern int blkid_tag_next(blkid_iterate iterate, const char **type, const char **value) */
HV *_blkid_tag_next(TagIter iter)
{
    int rc            = 0;
    const char *type  = NULL;
    const char *value = NULL;
    HV *tag_hash      = NULL;
    SV *sv_type       = NULL;
    SV *sv_value      = NULL;

    assert(iter);
    
    rc = blkid_tag_next(iter, &type, &value);
    if ( type && value && (rc == 0) )
    {
        tag_hash = (HV *)sv_2mortal((SV *)newHV());

        sv_type  = (SV *)hv_store(tag_hash, "type",  4, newSVpv(type,  0), 0);
        sv_value = (SV *)hv_store(tag_hash, "value", 5, newSVpv(value, 0), 0);
        if ( !sv_type || !sv_value )
            return NULL;

        return tag_hash;
    }
    else
        return NULL;
}

/* extern void blkid_tag_iterate_end(blkid_iterate iterate) */
void _blkid_tag_iterate_end(TagIter iter)
{
    assert(iter);
    
    blkid_tag_iterate_end(iter);
}


/* extern blkid_dev blkid_find_dev_with_tag(blkid_cache cache, const char *type, const char *value) */
Device _blkid_find_dev_with_tag(Cache cache, const char *type, const char *value)
{
    Device device = NULL;

    assert(cache);
    assert(type);
    assert(value);
    
    device = blkid_find_dev_with_tag(cache, type, value);
    if (device == NULL)
        return NULL;

    return device;
}

/* extern int blkid_parse_tag_string(const char *token, char **ret_type, char **ret_val) */
HV *_blkid_parse_tag_string(const char *token)
{
    int rc          = 0;
    char *type      = NULL;
    char *value     = NULL;
    HV *token_hash  = NULL;
    SV *sv_type     = NULL;
    SV *sv_value    = NULL;

    assert(token);
    
    rc = blkid_parse_tag_string(token, &type, &value);
    if ( type && value && (rc == 0) )
    {
        token_hash = (HV *)sv_2mortal((SV *)newHV());

        sv_type  = (SV *)hv_store(token_hash, "type",  4, newSVpv(type,  0), 0);
        sv_value = (SV *)hv_store(token_hash, "value", 5, newSVpv(value, 0), 0);
        if ( !sv_type || !sv_value )
            return NULL;

        return token_hash;
    }
    else
        return NULL;
}

/*
 * VERSION 1.34 begins here, adds 1 new call from v1.33
 * coupled with v1.33 to provide baseline default build target
 */

/* int blkid_known_fstype(const char *fstype) */
const char *_blkid_known_fstype(const char *fstype)
{
    int rc = 0;

    assert(fstype);
    
    rc = blkid_known_fstype(fstype);
    if (rc == 0)
        return NULL;

    return fstype;
}
#endif /* VERSION 1.33 baseline */

/*
 *
 * VERSION 1.36
 *
 * - 21 total calls
 *
 */

#ifdef __API_1_36
/* extern blkid_dev blkid_verify(blkid_cache cache, blkid_dev dev) */
Device _blkid_verify(Cache cache, Device device)
{
    Device tmp_device = NULL;

    assert(cache);
    assert(device);
    
    tmp_device = blkid_verify(cache, device);
    if (tmp_device == NULL)
        return NULL;

    return device;
}

/* extern int blkid_parse_version_string(const char *ver_string) */
int _blkid_parse_version_string(const char *ver_string)
{
    assert(ver_string);
    
    return blkid_parse_version_string(ver_string);
}

/* extern int blkid_get_library_version(const char **ver_string, const char **date_string) */
HV *_blkid_get_library_version(void)
{
    int rc              = 0;
    const char *version = NULL;
    const char *date    = NULL;
    HV *version_hash    = NULL;
    SV *sv_version      = NULL;
    SV *sv_date         = NULL;
    SV *sv_raw          = NULL;
    
    rc = blkid_get_library_version(&version, &date);
    if ( version && date && (rc > 0) )
    {
        version_hash = (HV *)sv_2mortal( (SV *)newHV() );

        sv_version  = (SV *)hv_store( version_hash, "version",  7, newSVpv(version, 0), 0 );
        sv_date     = (SV *)hv_store( version_hash, "date",     4, newSVpv(date,    0), 0 );
        sv_raw      = (SV *)hv_store( version_hash, "raw",      3, newSViv(rc),         0 );
        if (!sv_version || !sv_date || !sv_raw)
            return NULL;

        return version_hash;
    }
    else
        return NULL;
}
#endif /* __API_1_36 */

/*
 *
 * VERSION 1.38
 *
 * - 24 API calls
 *
 */

#ifdef __API_1_38
/* extern int blkid_dev_set_search(blkid_iterate iter, char *search_type, char *search_value) */
DevIter _blkid_dev_set_search(DevIter iter, char *search_type, char *search_value)
{
    int rc = 0;

    assert(iter);
    assert(search_type);
    assert(search_value);
    
    rc = blkid_dev_set_search(iter, search_type, search_value);
    if (rc != 0)
        return NULL;

    return iter;
}

/* extern int blkid_probe_all_new(blkid_cache cache) */
Cache _blkid_probe_all_new(Cache cache)
{
    assert(cache);
    
    if ( blkid_probe_all_new(cache) != 0 )
        return NULL;
    
    return cache;   
}

/* extern int blkid_dev_has_tag(blkid_dev dev, const char *type, const char *value) */
Device _blkid_dev_has_tag(Device device, const char *type, const char *value)
{
    int rc = 0;

    assert(device);
    assert(type);
    assert(value);
    
    rc = blkid_dev_has_tag(device, type, value);
    if (rc == 0)
        return NULL;

    return device;
}
#endif /* __API_1_38 */

/*
 *
 * VERSION 1.40
 * 
 * - 25 API calls
 *
 */

#ifdef __API_1_40
/* extern void blkid_gc_cache(blkid_cache cache) */
void _blkid_gc_cache(Cache cache)
{
    assert(cache);
    
    blkid_gc_cache(cache);
}
#endif /* __API_1_40 */

MODULE = Device::Blkid::E2fsprogs    PACKAGE = Device::Blkid::E2fsprogs        PREFIX = _blkid_

PROTOTYPES: DISABLE


 # XSUB glue prototypes

 # VERSION 1.33 baseline
    
#ifdef __API_1_33
    
void _blkid_put_cache(cache)
                       Cache          cache


Cache _blkid_get_cache(filename)
                       const char *   filename 


const char *_blkid_dev_devname(device)
                       Device         device


DevIter _blkid_dev_iterate_begin(cache)
                       Cache          cache


Device _blkid_dev_next(iter)
                       DevIter        iter


void _blkid_dev_iterate_end(iter)
                       DevIter        iter


char *_blkid_devno_to_devname(devno)
                       dev_t          devno


Cache _blkid_probe_all(cache)
                       Cache          cache


Device _blkid_get_dev(cache, devname, flags)
                       Cache          cache
                       const char *   devname
                       int            flags


SV *_blkid_get_dev_size(devname)
                       const char *   devname


const char *_blkid_known_fstype(fstype)
                       const char *   fstype


char *_blkid_get_tag_value(cache, tagname, devname)
                       Cache          cache
                       const char *   tagname
                       const char *   devname


char *_blkid_get_devname(cache, token, value)
                       Cache          cache
                       const char *   token
                       const char *   value


TagIter _blkid_tag_iterate_begin(device)
                       Device         device


HV *_blkid_tag_next(iter)
                       TagIter        iter


void _blkid_tag_iterate_end(iter)
                       TagIter        iter


Device _blkid_find_dev_with_tag(cache, type, value)
                       Cache          cache
                       const char *   type
                       const char *   value


HV *_blkid_parse_tag_string(token)
                       const char *   token

#endif


 # VERSION 1.36 or 1.37


#ifdef __API_1_36

Device _blkid_verify(cache, device)
                       Cache          cache
                       Device         device


int _blkid_parse_version_string(ver_string)
                       const char *   ver_string


HV *_blkid_get_library_version()

#endif
    

 # VERSION 1.38 or 1.39


#ifdef __API_1_38

DevIter _blkid_dev_set_search(iter, search_type, search_value)
                       DevIter        iter
                       char *         search_type
                       char *         search_value


Cache _blkid_probe_all_new(cache)
                       Cache          cache


Device _blkid_dev_has_tag(device, type, value)
                       Device         device
                       const char *   type
                       const char *   value

#endif
    

 # VERSION 1.40 or better


#ifdef __API_1_40

void _blkid_gc_cache(cache)
                       Cache          cache

#endif



MODULE = Device::Blkid::E2fsprogs    PACKAGE = Device::Blkid::E2fsprogs::Cache            PREFIX = _blkid_

void _blkid_DESTROY(cache)
                       Cache          cache
                   CODE:
                       Safefree(cache);


MODULE = Device::Blkid::E2fsprogs    PACKAGE = Device::Blkid::E2fsprogs::Device           PREFIX = _blkid_

void _blkid_DESTROY(device)
                       Device         device
                   CODE:
                       Safefree(device);


MODULE = Device::Blkid::E2fsprogs    PACKAGE = Device::Blkid::E2fsprogs::DevIter          PREFIX = _blkid_

void _blkid_DESTROY(iter)
                       DevIter        iter
                   CODE:
                       Safefree(iter);


MODULE = Device::Blkid::E2fsprogs    PACKAGE = Device::Blkid::E2fsprogs::TagIter          PREFIX = _blkid_

void _blkid_DESTROY(iter)
                       TagIter        iter
                   CODE:
                       Safefree(iter);
