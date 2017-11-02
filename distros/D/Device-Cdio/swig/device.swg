/* -*- c -*-
  Copyright (C) 2006, 2008, 2011, 2012 Rocky Bernstein <rocky@cpan.org>

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
/* See <cdio/device.h> for more extensive documentation. */

%include "device_const.swg"

/* Set up to allow functions to return device lists of type "char
   *". We'll use a typedef so we can make sure to isolate this. I
   *don't think we need to in this program, but it I think it makes
   *thing clearer.
*/
%inline %{
typedef char ** DeviceList_t;
%}

%typemap(out) DeviceList_t {
    /* char ** to array SVp*/
    /*
    AV *myav;
    SV **svs;
    int i = 0,len = 0;
    */
     /* Figure out how many elements we have */
    /*
    while ($1[len])
        len++;
    svs = (SV **) malloc(len*sizeof(SV *));
    for (i = 0; i < len ; i++) {
        svs[i] = sv_newmortal();
        sv_setpv((SV*)svs[i],$1[i]);
        //svs[i] = sv_2mortal((SV*)newSVpv($1[i], 0));
    };
    myav =	av_make(len,svs);
    free(svs);
    $result = newRV_noinc((SV*)myav);
    sv_2mortal($result);
    */
    // or: shorter version
    AV *myav;
    int i =0;
    myav = newAV();
    char **p = $1;
    while (*p) {
        av_store(myav, i, (SV*)newSVpv(*p, 0));
        i++;p++;
    }
    $result = newRV_noinc((SV*)myav);
    sv_2mortal($result);
    argvi++;
    cdio_free_device_list($1);
}

/*
  close_tray(drive=undef, driver_id=DRIVER_UNKNOWN) -> [status, driver_id]

close media tray in CD drive if there is a routine to do so.
*/
%apply driver_id_t *OUTPUT { driver_id_t *p_out_driver_id };
driver_return_code_t close_tray(const char *psz_drive,
				driver_id_t p_driver_id,
				driver_id_t *p_out_driver_id);
%inline %{
driver_return_code_t
close_tray(const char *psz_drive, driver_id_t p_driver_id,
	     driver_id_t *p_out_driver_id)
{
  *p_out_driver_id = p_driver_id;
  return cdio_close_tray(psz_drive, p_out_driver_id);
}
%}


%rename cdio_destroy close;
/*
destroy(p_cdio)
ree resources associated with p_cdio.  Call this when done using
sing CD reading/control operations for the current device.
*/
void cdio_destroy(CdIo_t *p_cdio);

/* cdio_driver_errmsg first appears in 0.77 code
*/
%rename cdio_driver_errmsg driver_errmsg;
/*!
  @param drc the return code you want interpreted.
  @return the string information about drc
*/
const char *cdio_driver_errmsg(driver_return_code_t drc);
/*
eject_media(cdio)->return_code

Eject media in CD drive if there is a routine to do so.
*/
driver_return_code_t eject_media (CdIo_t *p_cdio);
%inline %{
 driver_return_code_t

eject_media (CdIo_t *p_cdio)
{
  /* libcdio routines uses a Cdio_t **p_cdio, so we have to pass in
     something it can clobber.
   */
  CdIo_t **pp_cdio = &p_cdio;
  return cdio_eject_media (pp_cdio);
}
%}


%rename cdio_eject_media_drive eject_media_drive;
/*
eject_media_drive(drive=None)->return_code
Eject media in CD drive if there is a routine to do so.

psz_drive: the name of the device to be acted upon.
The operation status is returned.
*/
driver_return_code_t cdio_eject_media_drive (const char *psz_drive=NULL);

%rename cdio_get_arg get_arg;
/*
get_arg(p_cdio, key)->string

 Get the value associatied with key.
*/
const char *cdio_get_arg (const CdIo_t *p_cdio, const char key[]);

%newobject cdio_get_default_device; // free malloc'd return value
%rename cdio_get_default_device get_device;
/*
get_device(cdio)->str

Get the CD device associated with cdio.
If cdio is NULL (we haven't initialized a specific device driver),
then find a suitable one and return the default device for that.

In some situations of drivers or OS's we can't find a CD device if
there is no media in it and it is possible for this routine to return
None even though there may be a hardware CD-ROM.
*/
char *cdio_get_default_device (const CdIo_t *p_cdio=NULL);

%newobject get_default_device_driver; // free malloc'd return value
/*
get_default_device_driver(driver_id=None)->[device, driver]
Return a string containing the default CD device if none is specified.
if p_driver_id is DRIVER_UNKNOWN or DRIVER_DEVICE then find a suitable
one set the default device for that.

undef is returned as the device if we couldn't get a default device.
*/
char *get_default_device_driver (driver_id_t p_driver_id,
				 driver_id_t *p_out_driver_id);
%inline %{
char *
get_default_device_driver(driver_id_t driver_id, driver_id_t *p_out_driver_id)
{
  *p_out_driver_id = driver_id;
  return cdio_get_default_device_driver(p_out_driver_id);
}
%}

//%rename cdio_get_devices get_devices;
/*! Return an array of device names. If you want a specific
  devices for a driver, give that device. If you want hardware
  devices, give DRIVER_DEVICE and if you want all possible devices,
  image drivers and hardware drivers give DRIVER_UNKNOWN.

  NULL is returned if we couldn't return a list of devices.

  In some situations of drivers or OS's we can't find a CD device if
  there is no media in it and it is possible for this routine to return
  NULL even though there may be a hardware CD-ROM.
*/
DeviceList_t cdio_get_devices (driver_id_t driver_id);

DeviceList_t get_devices(driver_id_t driver_id);


%inline %{
DeviceList_t get_devices(driver_id_t driver_id) {
    return cdio_get_devices(driver_id);
}
%}
/* Like cdio_get_devices, but we may change the p_driver_id if we
   were given DRIVER_DEVICE or DRIVER_UNKNOWN. This is because
   often one wants to get a drive name and then *open* it
   afterwards. Giving the driver back facilitates this, and speeds
   things up for libcdio as well.
*/

DeviceList_t get_devices_ret (driver_id_t driver_id,
			      driver_id_t *p_out_driver_id);
%inline %{
DeviceList_t get_devices_ret (driver_id_t driver_id,
			      driver_id_t *p_out_driver_id) {
  *p_out_driver_id = driver_id;
  return cdio_get_devices_ret (p_out_driver_id);
 }
%}

/*
Get an array of device names in search_devices that have at least
the capabilities listed by the capabities parameter.

If "b_any" is set false then every capability listed in the
extended portion of capabilities (i.e. not the basic filesystem)
must be satisfied. If "any" is set true, then if any of the
capabilities matches, we call that a success.

To find a CD-drive of any type, use the mask CDIO_FS_MATCH_ALL.

The array of device names is returned or NULL if we couldn't get a
default device.  It is also possible to return a non NULL but after
dereferencing the the value is NULL. This also means nothing was
found.
*/
DeviceList_t get_devices_with_cap (unsigned int capabilities, bool b_any);
%inline %{
DeviceList_t
get_devices_with_cap (unsigned int capabilities, bool b_any) {
  return cdio_get_devices_with_cap (NULL, (cdio_fs_anal_t) capabilities,
				    b_any);
 }
%}

%apply driver_id_t *OUTPUT { driver_id_t *p_out_driver_id };
/*
  Like cdio_get_devices_with_cap but we return the driver we found
  as well. This is because often one wants to search for kind of drive
  and then *open* it afterwards. Giving the driver back facilitates this,
  and speeds things up for libcdio as well.
*/
DeviceList_t get_devices_with_cap_ret (unsigned int capabilities, bool b_any,
				       driver_id_t *p_out_driver_id);
%inline %{
DeviceList_t
get_devices_with_cap_ret (unsigned int capabilities, bool b_any,
			  driver_id_t *p_out_driver_id) {
  return cdio_get_devices_with_cap_ret (NULL,
					(cdio_fs_anal_t) capabilities, b_any,
					p_out_driver_id);
 }
%}

%rename cdio_get_drive_cap get_drive_cap;
%feature("autodoc",
"get_drive_cap()->(read_cap, write_cap, misc_cap)

Get drive capabilities of device.

In some situations of drivers or OS's we can't find a CD device if
there is no media in it. In this situation capabilities will show up as
empty even though there is a hardware CD-ROM.");
%apply uint32_t *OUTPUT { uint32_t *p_read_cap,
			  uint32_t *p_write_cap,
			  uint32_t *p_misc_cap };
void cdio_get_drive_cap (const CdIo_t *p_cdio,
			 uint32_t *p_read_cap,
			 uint32_t *p_write_cap,
			 uint32_t *p_misc_cap);

%rename cdio_get_drive_cap_dev get_drive_cap;
%feature("autodoc",
"get_drive_cap_dev()->(read_cap, write_cap, misc_cap)

Get drive capabilities of device.

In some situations of drivers or OS's we can't find a CD device if
there is no media in it. In this situation capabilities will show up as
empty even though there is a hardware CD-ROM.");

void cdio_get_drive_cap_dev(const char *device=NULL,
			    uint32_t *p_read_cap,
			    uint32_t *p_write_cap,
			    uint32_t *p_misc_cap);

%rename cdio_get_driver_name get_driver_name;
%feature("autodoc",
"get_driver_name(cdio)-> string

return a string containing the name of the driver in use.
");
const char *cdio_get_driver_name (const CdIo_t *p_cdio);

%rename cdio_get_driver_id get_driver_id;
%feature("autodoc",
"get_driver_id(cdio)-> int

Return the driver id of the driver in use.
if cdio has not been initialized or is None,
return pycdio.DRIVER_UNKNOWN.");
driver_id_t cdio_get_driver_id (const CdIo_t *p_cdio);

%rename cdio_get_last_session get_last_session;
%apply int32_t *OUTPUT { lsn_t *i_last_session };
driver_return_code_t cdio_get_last_session (CdIo_t *p_cdio,
					    lsn_t *i_last_session);

%feature("autodoc",
"have_driver(driver_id) -> int

Return 1 if we have driver driver_id, 0 if not.");
%inline %{
int
have_driver (unsigned int driver_id)
{
  if (cdio_have_driver(driver_id)) return 1;
  return 0;
}
%}

%feature("autodoc",
"have_ATAPI(CdIo_t *p_cdio)->bool
return True if CD-ROM understand ATAPI commands.");
%inline %{
/*! True if CD-ROM understand ATAPI commands. */
bool
have_ATAPI (CdIo_t *p_cdio)
{
  return cdio_have_atapi(p_cdio) == yep;
}
%}

%newobject cdio_is_binfile; // free malloc'd return value
%rename cdio_is_binfile is_binfile;
char *cdio_is_binfile(const char *bin_name);

%newobject cdio_is_cuefile; // free malloc'd return value
%rename cdio_is_cuefile is_cuefile;
char *cdio_is_cuefile(const char *cue_name);

%rename cdio_is_device is_device;
bool cdio_is_device(const char *psz_source,
		    driver_id_t driver_id=DRIVER_UNKNOWN);

%rename cdio_is_nrg is_nrg;
bool cdio_is_nrg(const char *nrg_name);

%rename cdio_is_tocfile is_tocfile;
%feature("autodoc",
"is_tocfile(tocfile_name)->bool

Determine if tocfile_name is a cdrdao CD disc image");
bool cdio_is_tocfile(const char *tocfile_name);

%rename cdio_get_media_changed get_media_changed;
%feature("autodoc",
"get_media_changed(cdio) -> int

Find out if media has changed since the last call.
Return 1 if media has changed since last call, 0 if not. Error
return codes are the same as driver_return_code_t");
int cdio_get_media_changed(CdIo_t *p_cdio);

/* Set up to allow returning hardware info. We'll use a typedef so we
   can make sure to isolate this.
*/
%inline %{
typedef char ** HWInfo_t;
%}
%typemap(out) HWInfo_t {
    /* char ** to array SVp*/
    AV *myav;
    SV **svs;
    int i = 0,len = 0;
    /* no test
    if(!$1) {
        $result = newSV(0);
    }
    */
    /* Figure out how many elements we have */
    while ($1[len])
        len++;
    svs = (SV **) malloc(len*sizeof(SV *));
    for (i = 0; i < len ; i++) {
        svs[i] = sv_newmortal();
        sv_setpv((SV*)svs[i],$1[i]);
    };
    myav =	av_make(len,svs);
    free(svs);
    $result = newRV_noinc((SV*)myav);
    sv_2mortal($result);
    argvi++;
}

/*
get_hwinfo(p_cdio)->[vendor, model, release]
Get the CD-ROM hardware info via a SCSI MMC INQUIRY command.
An exception is raised if we had an error.
*/
%apply int *OUTPUT { int *drc };
const HWInfo_t get_hwinfo ( const CdIo_t *p_cdio, int *drc);

%inline %{
static cdio_hwinfo_t hw_info;
const
HWInfo_t get_hwinfo ( const CdIo_t *p_cdio, int *drc)
{
  static const char *hwinfo[4] = {
    hw_info.psz_vendor,
    hw_info.psz_model,
    hw_info.psz_revision,
    NULL
    };
  bool b_got_hwinfo = cdio_get_hwinfo(p_cdio, &hw_info);

  *drc = b_got_hwinfo;
  return (const HWInfo_t) hwinfo;
}
%}

#include <cdio/mmc.h>
%inline %{
extern int mmc_get_tray_status(const CdIo_t *p_cdio);
 %}
%rename mmc_get_tray_status get_tray_status;

%rename cdio_set_blocksize set_blocksize;
%feature("autodoc",
"set_blocksize(cdio, blocksize)->return_status

Set the blocksize for subsequent reads.");
driver_return_code_t cdio_set_blocksize ( const CdIo_t *p_cdio,
					  int i_blocksize );

%rename cdio_set_speed set_speed;
%feature("autodoc",
"cdio_set_speed(cdio, speed)->return_status
Set the drive speed.");
driver_return_code_t cdio_set_speed ( const CdIo_t *p_cdio, int i_speed );


/**** Using the name open() conflicts with some C routine.
      So we use open_cd() instead.
***/
%rename cdio_open_am open_cd;
%feature("autodoc",
"open_cd(source=NULL, driver_id=None, access_mode=None)

Sets up to read from place specified by source, driver_id and
access mode. This should be called before using any other routine
except those that act on a CD-ROM drive by name.

If None is given as the source, we'll use the default driver device.
If None is given as the driver_id, we'll find a suitable device driver.

Return the a pointer than can be used in subsequent operations or
None on error or no device.");
CdIo_t *cdio_open_am(const char *psz_source=NULL,
		     driver_id_t driver_id=DRIVER_UNKNOWN,
		     const char *psz_access_mode=NULL);
