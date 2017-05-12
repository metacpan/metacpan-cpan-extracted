#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libmtp.h>

typedef LIBMTP_album_t *           MLA_Album;
typedef LIBMTP_album_t *           MLA_AlbumList;   /* needs DESTROY */
typedef LIBMTP_allowed_values_t *  MLA_AllowedValues;
typedef LIBMTP_file_t *            MLA_File;
typedef LIBMTP_file_t *            MLA_FileList;    /* needs DESTROY */
typedef LIBMTP_filesampledata_t *  MLA_FileSampleData;
typedef LIBMTP_devicestorage_t *   MLA_DeviceStorage;
typedef LIBMTP_error_t *           MLA_Error;
typedef LIBMTP_folder_t *          MLA_Folder;
typedef LIBMTP_folder_t *          MLA_FolderList;  /* needs DESTROY */
typedef LIBMTP_mtpdevice_t *       MLA_MTPDevice;
typedef LIBMTP_mtpdevice_t *       MLA_MTPDeviceList;/* needs DESTROY */
typedef LIBMTP_playlist_t *        MLA_Playlist;
typedef LIBMTP_playlist_t *        MLA_PlaylistList;/* needs DESTROY */
typedef LIBMTP_raw_device_t *      MLA_RawDevice;
typedef LIBMTP_track_t *           MLA_Track;
typedef LIBMTP_track_t *           MLA_TrackList;   /* needs DESTROY */

typedef const char *               Utf8StringConst;
typedef char *                     Utf8String;
typedef char *                     Utf8String2Free;

struct MLA_raw_device_list {
  MLA_RawDevice  devices;
  int            numdevs;
};

typedef struct MLA_raw_device_list *  MLA_RawDeviceList;

#include "const-c.inc"

MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API  PREFIX = LIBMTP_

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

int
LIBMTP_Check_Specific_Device(busno, devno)
	int	busno
	int	devno

LIBMTP_error_number_t
LIBMTP_Detect_Raw_Devices(list)
	MLA_RawDeviceList	list = NO_INIT
   CODE:
	Newxz(list, 1, struct MLA_raw_device_list);
	RETVAL = LIBMTP_Detect_Raw_Devices(&list->devices, &list->numdevs);
   OUTPUT:
	RETVAL
	list

#//FIXME use AV* ???
#//  LIBMTP_error_number_t
#//  LIBMTP_Get_Connected_Devices(arg0)
#//  	MLA_MTPDevice *		arg0
#//

Utf8StringConst
LIBMTP_Get_Filetype_Description(arg0)
	LIBMTP_filetype_t	arg0

MLA_MTPDeviceList
LIBMTP_Get_First_Device()

Utf8StringConst
LIBMTP_Get_Property_Description(inproperty)
	LIBMTP_property_t	inproperty

#// FIXME
#// int
#// LIBMTP_Get_Supported_Devices_List(arg0, arg1)
#// 	LIBMTP_device_entry_t **	arg0
#// 	int *	arg1

void
LIBMTP_Init()

void
LIBMTP_Set_Debug(arg0)
	int	arg0

int
LIBMTP_FILETYPE_IS_AUDIO(filetype)
	LIBMTP_filetype_t	filetype

int
LIBMTP_FILETYPE_IS_VIDEO(filetype)
	LIBMTP_filetype_t	filetype

int
LIBMTP_FILETYPE_IS_AUDIOVIDEO(filetype)
	LIBMTP_filetype_t	filetype

int
LIBMTP_FILETYPE_IS_TRACK(filetype)
	LIBMTP_filetype_t	filetype

int
LIBMTP_FILETYPE_IS_IMAGE(filetype)
	LIBMTP_filetype_t	filetype

int
LIBMTP_FILETYPE_IS_ADDRESSBOOK(filetype)
	LIBMTP_filetype_t	filetype

int
LIBMTP_FILETYPE_IS_CALENDAR(filetype)
	LIBMTP_filetype_t	filetype


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::Album

MLA_AlbumList
new(class)
	SV *	class
   CODE:
	RETVAL = LIBMTP_new_album_t();
   OUTPUT:
	RETVAL

uint32_t
album_id(self, newValue = NO_INIT)
	MLA_Album	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->album_id = newValue;
	RETVAL = self->album_id;
   OUTPUT:
	RETVAL

uint32_t
parent_id(self, newValue = NO_INIT)
	MLA_Album	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->parent_id = newValue;
	RETVAL = self->parent_id;
   OUTPUT:
	RETVAL

uint32_t
storage_id(self, newValue = NO_INIT)
	MLA_Album	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->storage_id = newValue;
	RETVAL = self->storage_id;
   OUTPUT:
	RETVAL

Utf8String
name(self, newValue = NO_INIT)
	MLA_Album	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->name = strdup(newValue);
	RETVAL = self->name;
   OUTPUT:
	RETVAL

Utf8String
artist(self, newValue = NO_INIT)
	MLA_Album	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->artist = strdup(newValue);
	RETVAL = self->artist;
   OUTPUT:
	RETVAL

Utf8String
composer(self, newValue = NO_INIT)
	MLA_Album	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->composer = strdup(newValue);
	RETVAL = self->composer;
   OUTPUT:
	RETVAL

Utf8String
genre(self, newValue = NO_INIT)
	MLA_Album	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->genre = strdup(newValue);
	RETVAL = self->genre;
   OUTPUT:
	RETVAL

AV *
tracks(self, newValue = NO_INIT)
	MLA_Album	self
	AV *		newValue
   PREINIT:
	I32		i;
   CODE:
        if (items > 1) {
          if (self->tracks) Safefree(self->tracks);
          i = av_len(newValue);
          self->no_tracks = i + 1;
          Newx(self->tracks, self->no_tracks, uint32_t);
          for (; i >= 0; --i) {
            self->tracks[i] =
              SvUV(*av_fetch(newValue, i, 0));
          }
        }
	RETVAL = newAV();
	sv_2mortal((SV*)RETVAL);
	av_extend(RETVAL, self->no_tracks - 1);
        for (i = 0; i < self->no_tracks; ++i) {
          av_store(RETVAL, i, newSVuv(self->tracks[i]));
        }
   OUTPUT:
	RETVAL

uint32_t
no_tracks(self)
	MLA_Album	self
   CODE:
	RETVAL = self->no_tracks;
   OUTPUT:
	RETVAL

MLA_Album
_next(self)
	MLA_Album	self
   CODE:
	RETVAL = self->next;
   OUTPUT:
	RETVAL


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::AlbumList

void
DESTROY(self)
	MLA_Album	self
   CODE:
	LIBMTP_destroy_album_t(self);


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::AllowedValues

MLA_AllowedValues
new(class)
	SV *	class
   CODE:
	Newxz(RETVAL, 1, LIBMTP_allowed_values_t);
   OUTPUT:
	RETVAL

void
DESTROY(self)
	MLA_AllowedValues	self
   CODE:
	LIBMTP_destroy_allowed_values_t(self);
        Safefree(self);

uint8_t
u8max(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u8max;
   OUTPUT:
	RETVAL

uint8_t
u8min(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u8min;
   OUTPUT:
	RETVAL

uint8_t
u8step(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u8step;
   OUTPUT:
	RETVAL

int8_t
i8max(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i8max;
   OUTPUT:
	RETVAL

int8_t
i8min(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i8min;
   OUTPUT:
	RETVAL

int8_t
i8step(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i8step;
   OUTPUT:
	RETVAL

uint16_t
u16max(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u16max;
   OUTPUT:
	RETVAL

uint16_t
u16min(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u16min;
   OUTPUT:
	RETVAL

uint16_t
u16step(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u16step;
   OUTPUT:
	RETVAL

int16_t
i16max(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i16max;
   OUTPUT:
	RETVAL

int16_t
i16min(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i16min;
   OUTPUT:
	RETVAL

int16_t
i16step(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i16step;
   OUTPUT:
	RETVAL

uint32_t
u32max(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u32max;
   OUTPUT:
	RETVAL

uint32_t
u32min(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u32min;
   OUTPUT:
	RETVAL

uint32_t
u32step(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u32step;
   OUTPUT:
	RETVAL

int32_t
i32max(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i32max;
   OUTPUT:
	RETVAL

int32_t
i32min(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i32min;
   OUTPUT:
	RETVAL

int32_t
i32step(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i32step;
   OUTPUT:
	RETVAL

uint64_t
u64max(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u64max;
   OUTPUT:
	RETVAL

uint64_t
u64min(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u64min;
   OUTPUT:
	RETVAL

uint64_t
u64step(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->u64step;
   OUTPUT:
	RETVAL

int64_t
i64max(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i64max;
   OUTPUT:
	RETVAL

int64_t
i64min(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i64min;
   OUTPUT:
	RETVAL

int64_t
i64step(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->i64step;
   OUTPUT:
	RETVAL

uint16_t
num_entries(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->num_entries;
   OUTPUT:
	RETVAL

LIBMTP_datatype_t
datatype(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->datatype;
   OUTPUT:
	RETVAL

int
is_range(self)
	MLA_AllowedValues	self
   CODE:
	RETVAL = self->is_range;
   OUTPUT:
	RETVAL

int8_t *
i8vals(self)
	MLA_AllowedValues	self
   PREINIT:
	int size_RETVAL;
   CODE:
	size_RETVAL = self->num_entries;
	RETVAL = self->i8vals;
	if (!RETVAL) XSRETURN_EMPTY;
   OUTPUT:
	RETVAL
   CLEANUP:
	XSRETURN(size_RETVAL);

uint8_t *
u8vals(self)
	MLA_AllowedValues	self
   PREINIT:
	int size_RETVAL;
   CODE:
	size_RETVAL = self->num_entries;
	RETVAL = self->u8vals;
	if (!RETVAL) XSRETURN_EMPTY;
   OUTPUT:
	RETVAL
   CLEANUP:
	XSRETURN(size_RETVAL);

int16_t *
i16vals(self)
	MLA_AllowedValues	self
   PREINIT:
	int size_RETVAL;
   CODE:
	size_RETVAL = self->num_entries;
	RETVAL = self->i16vals;
	if (!RETVAL) XSRETURN_EMPTY;
   OUTPUT:
	RETVAL
   CLEANUP:
	XSRETURN(size_RETVAL);

uint16_t *
u16vals(self)
	MLA_AllowedValues	self
   PREINIT:
	int size_RETVAL;
   CODE:
	size_RETVAL = self->num_entries;
	RETVAL = self->u16vals;
	if (!RETVAL) XSRETURN_EMPTY;
   OUTPUT:
	RETVAL
   CLEANUP:
	XSRETURN(size_RETVAL);

int32_t *
i32vals(self)
	MLA_AllowedValues	self
   PREINIT:
	int size_RETVAL;
   CODE:
	size_RETVAL = self->num_entries;
	RETVAL = self->i32vals;
	if (!RETVAL) XSRETURN_EMPTY;
   OUTPUT:
	RETVAL
   CLEANUP:
	XSRETURN(size_RETVAL);

uint32_t *
u32vals(self)
	MLA_AllowedValues	self
   PREINIT:
	int size_RETVAL;
   CODE:
	size_RETVAL = self->num_entries;
	RETVAL = self->u32vals;
	if (!RETVAL) XSRETURN_EMPTY;
   OUTPUT:
	RETVAL
   CLEANUP:
	XSRETURN(size_RETVAL);

int64_t *
i64vals(self)
	MLA_AllowedValues	self
   PREINIT:
	int size_RETVAL;
   CODE:
	size_RETVAL = self->num_entries;
	RETVAL = self->i64vals;
	if (!RETVAL) XSRETURN_EMPTY;
   OUTPUT:
	RETVAL
   CLEANUP:
	XSRETURN(size_RETVAL);

uint64_t *
u64vals(self)
	MLA_AllowedValues	self
   PREINIT:
	int size_RETVAL;
   CODE:
	size_RETVAL = self->num_entries;
	RETVAL = self->u64vals;
	if (!RETVAL) XSRETURN_EMPTY;
   OUTPUT:
	RETVAL
   CLEANUP:
	XSRETURN(size_RETVAL);


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::MTPDevice

uint8_t
object_bitsize(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->object_bitsize;
   OUTPUT:
	RETVAL

uint8_t
maximum_battery_level(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->maximum_battery_level;
   OUTPUT:
	RETVAL

uint32_t
default_music_folder(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->default_music_folder;
   OUTPUT:
	RETVAL

uint32_t
default_playlist_folder(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->default_playlist_folder;
   OUTPUT:
	RETVAL

uint32_t
default_picture_folder(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->default_picture_folder;
   OUTPUT:
	RETVAL

uint32_t
default_video_folder(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->default_video_folder;
   OUTPUT:
	RETVAL

uint32_t
default_organizer_folder(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->default_organizer_folder;
   OUTPUT:
	RETVAL

uint32_t
default_zencast_folder(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->default_zencast_folder;
   OUTPUT:
	RETVAL

uint32_t
default_album_folder(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->default_album_folder;
   OUTPUT:
	RETVAL

uint32_t
default_text_folder(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->default_text_folder;
   OUTPUT:
	RETVAL

MLA_MTPDevice
_next(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->next;
   OUTPUT:
	RETVAL

MLA_DeviceStorage
_storage(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = self->storage;
   OUTPUT:
	RETVAL


MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::MTPDevice  PREFIX = LIBMTP_

void
LIBMTP_Clear_Errorstack(self)
	MLA_MTPDevice	self

uint32_t
LIBMTP_Create_Folder(self, arg1, arg2, arg3)
	MLA_MTPDevice	self
	Utf8String	arg1
	uint32_t	arg2
	uint32_t	arg3

int
LIBMTP_Create_New_Album(self, arg1)
	MLA_MTPDevice	self
	MLA_Album	arg1

int
LIBMTP_Create_New_Playlist(self, arg1)
	MLA_MTPDevice	self
	MLA_Playlist	arg1

int
LIBMTP_Delete_Object(self, arg1)
	MLA_MTPDevice	self
	uint32_t	arg1

void
LIBMTP_Dump_Device_Info(self)
	MLA_MTPDevice	self

void
LIBMTP_Dump_Errorstack(self)
	MLA_MTPDevice	self

int
LIBMTP_Format_Storage(self, storage)
	MLA_MTPDevice		self
	MLA_DeviceStorage	storage

MLA_AlbumList
LIBMTP_Get_Album(self, arg1)
	MLA_MTPDevice	self
	uint32_t	arg1

MLA_AlbumList
LIBMTP_Get_Album_List(self)
	MLA_MTPDevice	self

MLA_AlbumList
LIBMTP_Get_Album_List_For_Storage(self, arg1)
	MLA_MTPDevice	self
	uint32_t	arg1

int
LIBMTP_Get_Allowed_Property_Values(self, arg1, arg2, arg3)
	MLA_MTPDevice		self
	LIBMTP_property_t	arg1
	LIBMTP_filetype_t	arg2
	MLA_AllowedValues	arg3

int
LIBMTP_Get_Batterylevel(self, maximum_level, current_level)
	MLA_MTPDevice	self
	uint8_t		maximum_level = NO_INIT
	uint8_t		current_level = NO_INIT
   CODE:
	RETVAL = LIBMTP_Get_Batterylevel(
	  self, &maximum_level, &current_level
	);
   OUTPUT:
	RETVAL
	maximum_level
	current_level

int
LIBMTP_Get_Device_Certificate(self, devcert)
	MLA_MTPDevice	self
	Utf8String2Free	devcert = NO_INIT
   CODE:
	devcert = NULL;
	RETVAL = LIBMTP_Get_Device_Certificate(self, &devcert);
   OUTPUT:
	RETVAL
	devcert

Utf8String2Free
LIBMTP_Get_Deviceversion(self)
	MLA_MTPDevice	self

MLA_Error
LIBMTP_Get_Errorstack(self)
	MLA_MTPDevice	self

#// FIXME implement callback
int
LIBMTP_Get_File_To_File(device, id, path)
#//LIBMTP_Get_File_To_File(device, id, path, callback, data)
	MLA_MTPDevice	device
	uint32_t	id
	Utf8String	path
#//	void *		callback
#//	void const *	data
   CODE:
	RETVAL = LIBMTP_Get_File_To_File(device, id, path, NULL, NULL);
   OUTPUT:
	RETVAL

#// FIXME implement callback
int
LIBMTP_Get_File_To_File_Descriptor(device, id, fd)
#//LIBMTP_Get_File_To_File_Descriptor(device, id, fd, callback, data)
	MLA_MTPDevice	device
	uint32_t	id
	int		fd
#//	void *		arg3
#//	void const *	arg4
   CODE:
	RETVAL = LIBMTP_Get_File_To_File_Descriptor(device, id, fd, NULL, NULL);
   OUTPUT:
	RETVAL

#// FIXME
#// int
#// LIBMTP_Get_File_To_Handler(self, arg1, arg2, arg3, arg4, arg5)
#// 	MLA_MTPDevice	self
#// 	uint32_t	arg1
#// 	void *		arg2
#// 	void *		arg3
#// 	void *		arg4
#// 	void const *	arg5

MLA_FileList
LIBMTP_Get_Filelisting(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = LIBMTP_Get_Filelisting_With_Callback(self, NULL, NULL);
   OUTPUT:
	RETVAL

#//FIXME
#// MLA_File
#// LIBMTP_Get_Filelisting_With_Callback(self, arg1, arg2)
#// 	MLA_MTPDevice	self
#// 	void *		arg1
#// 	void const *	arg2

MLA_FileList
LIBMTP_Get_Filemetadata(self, arg1)
	MLA_MTPDevice	self
	uint32_t	arg1

MLA_FileList
LIBMTP_Get_Files_And_Folders(self, arg1, arg2)
	MLA_MTPDevice	self
	uint32_t	arg1
	uint32_t	arg2

MLA_FolderList
LIBMTP_Get_Folder_List(self)
	MLA_MTPDevice	self

MLA_FolderList
LIBMTP_Get_Folder_List_For_Storage(self, arg1)
	MLA_MTPDevice	self
	uint32_t	arg1

Utf8String2Free
LIBMTP_Get_Friendlyname(self)
	MLA_MTPDevice	self

Utf8String2Free
LIBMTP_Get_Manufacturername(self)
	MLA_MTPDevice	self

Utf8String2Free
LIBMTP_Get_Modelname(self)
	MLA_MTPDevice	self

MLA_PlaylistList
LIBMTP_Get_Playlist(self, arg1)
	MLA_MTPDevice	self
	uint32_t	arg1

MLA_PlaylistList
LIBMTP_Get_Playlist_List(self)
	MLA_MTPDevice	self

int
LIBMTP_Get_Representative_Sample(self, object_id, data)
	MLA_MTPDevice		self
	uint32_t		object_id
	MLA_FileSampleData	data

int
LIBMTP_Get_Representative_Sample_Format(self, filetype, sample)
	MLA_MTPDevice		self
	LIBMTP_filetype_t	filetype
	MLA_FileSampleData	sample = NO_INIT
   CODE:
	sample = NULL;
	RETVAL = LIBMTP_Get_Representative_Sample_Format(
	  self, filetype, &sample
	);
   OUTPUT:
	RETVAL
	sample

int
LIBMTP_Get_Secure_Time(self, sectime)
	MLA_MTPDevice	self
	Utf8String2Free	sectime = NO_INIT
   CODE:
	sectime = NULL;
	RETVAL = LIBMTP_Get_Secure_Time(self, &sectime);
   OUTPUT:
	RETVAL
	sectime

Utf8String2Free
LIBMTP_Get_Serialnumber(self)
	MLA_MTPDevice	self

int
LIBMTP_Get_Storage(self, sortby = LIBMTP_STORAGE_SORTBY_NOTSORTED)
	MLA_MTPDevice	self
	int		sortby

Utf8String2Free
LIBMTP_Get_String_From_Object(self, arg1, arg2)
	MLA_MTPDevice		self
	uint32_t		arg1
	LIBMTP_property_t	arg2

#// Return an arrayref, or undef on failure
AV *
LIBMTP_Get_Supported_Filetypes(self)
	MLA_MTPDevice	self
   PREINIT:
	uint16_t *	filetypes = NULL;
	uint16_t	length = 0;
	int		i;
   CODE:
	if (LIBMTP_Get_Supported_Filetypes(self, &filetypes, &length)) {
	  XSRETURN_UNDEF;
	} else {
	  RETVAL = newAV();
	  sv_2mortal((SV*)RETVAL);
	  av_extend(RETVAL, length - 1);
	  for (i = 0; i < length; ++i) {
	    av_store(RETVAL, i, newSVuv(filetypes[i]));
	  }
	  Safefree(filetypes);
	}
   OUTPUT:
	RETVAL

Utf8String2Free
LIBMTP_Get_Syncpartner(self)
	MLA_MTPDevice	self

#// FIXME implement callback
int
LIBMTP_Get_Track_To_File(device, id, path)
#// LIBMTP_Get_Track_To_File(device, id, path, callback, data)
	MLA_MTPDevice	device
	uint32_t	id
	Utf8String	path
#//	void *		callback
#//	void const *	data
   CODE:
	RETVAL = LIBMTP_Get_Track_To_File(device, id, path, NULL, NULL);
   OUTPUT:
	RETVAL

#// FIXME implement callback
int
LIBMTP_Get_Track_To_File_Descriptor(device, id, fd)
#//LIBMTP_Get_Track_To_File_Descriptor(device, id, fd, callback, data)
	MLA_MTPDevice	device
	uint32_t	id
	int		fd
#//	void *		callback
#//	void const *	data
   CODE:
	RETVAL = LIBMTP_Get_Track_To_File_Descriptor(device, id, fd, NULL, NULL);
   OUTPUT:
	RETVAL

#// FIXME
#// int
#// LIBMTP_Get_Track_To_Handler(self, arg1, arg2, arg3, arg4, arg5)
#// 	MLA_MTPDevice	self
#// 	uint32_t	arg1
#// 	void *		arg2
#// 	void *		arg3
#// 	void *		arg4
#// 	void const *	arg5

MLA_TrackList
LIBMTP_Get_Tracklisting(self)
	MLA_MTPDevice	self
   CODE:
	RETVAL = LIBMTP_Get_Tracklisting_With_Callback(self, NULL, NULL);
   OUTPUT:
	RETVAL

#// FIXME
#// MLA_Track
#// LIBMTP_Get_Tracklisting_With_Callback(self, arg1, arg2)
#// 	MLA_MTPDevice	self
#// 	void *		arg1
#// 	void const *	arg2
#//
#// MLA_Track
#// LIBMTP_Get_Tracklisting_With_Callback_For_Storage(self, arg1, arg2, arg3)
#// 	MLA_MTPDevice	self
#// 	uint32_t	arg1
#// 	void *		arg2
#// 	void const *	arg3

MLA_TrackList
LIBMTP_Get_Trackmetadata(self, arg1)
	MLA_MTPDevice	self
	uint32_t	arg1

uint16_t
LIBMTP_Get_u16_From_Object(self, arg1, arg2, arg3)
	MLA_MTPDevice		self
	uint32_t		arg1
	LIBMTP_property_t	arg2
	uint16_t		arg3

uint32_t
LIBMTP_Get_u32_From_Object(self, arg1, arg2, arg3)
	MLA_MTPDevice		self
	uint32_t		arg1
	LIBMTP_property_t	arg2
	uint32_t		arg3

uint64_t
LIBMTP_Get_u64_From_Object(self, arg1, arg2, arg3)
	MLA_MTPDevice		self
	uint32_t		arg1
	LIBMTP_property_t	arg2
	uint64_t		arg3

uint8_t
LIBMTP_Get_u8_From_Object(self, arg1, arg2, arg3)
	MLA_MTPDevice		self
	uint32_t		arg1
	LIBMTP_property_t	arg2
	uint8_t			arg3

int
LIBMTP_Is_Property_Supported(self, arg1, arg2)
	MLA_MTPDevice		self
	LIBMTP_property_t	arg1
	LIBMTP_filetype_t	arg2

uint32_t
LIBMTP_Number_Devices_In_List(self)
	MLA_MTPDevice	self

#// FIXME
#// int
#// LIBMTP_Read_Event(self, arg1)
#// 	MLA_MTPDevice		self
#// 	LIBMTP_event_t *	arg1

void
LIBMTP_Release_Device(self)
	MLA_MTPDevice	self

void
LIBMTP_Release_Device_List(self)
	MLA_MTPDevice	self

int
LIBMTP_Reset_Device(self)
	MLA_MTPDevice	self

#// FIXME implement callback
int
LIBMTP_Send_File_From_File(device, path, filedata)
#//LIBMTP_Send_File_From_File(device, path, filedata, callback, data)
	MLA_MTPDevice	device
	Utf8String	path
	MLA_File	filedata
#//	void *		callback
#//	void const *	data
   CODE:
	RETVAL = LIBMTP_Send_File_From_File(device, path, filedata, NULL, NULL);
   OUTPUT:
	RETVAL

#// FIXME implement callback
int
LIBMTP_Send_File_From_File_Descriptor(device, fd, filedata, callback, data)
#//LIBMTP_Send_File_From_File_Descriptor(device, fd, filedata, callback, data)
	MLA_MTPDevice	device
	int		fd
	MLA_File	filedata
#//	void *		callback
#//	void const *	data
   CODE:
	RETVAL = LIBMTP_Send_File_From_File_Descriptor(device, fd, filedata,
						       NULL, NULL);
   OUTPUT:
	RETVAL

#// FIXME
#// int
#// LIBMTP_Send_File_From_Handler(self, arg1, arg2, arg3, arg4, arg5)
#// 	MLA_MTPDevice	self
#// 	void *		arg1
#// 	void *		arg2
#// 	MLA_File	arg3
#// 	void *		arg4
#// 	void const *	arg5

int
LIBMTP_Send_Representative_Sample(self, arg1, arg2)
	MLA_MTPDevice		self
	uint32_t		arg1
	MLA_FileSampleData	arg2

#// FIXME implement callback
int
LIBMTP_Send_Track_From_File(device, path, metadata)
#//LIBMTP_Send_Track_From_File(device, path, metadata, callback, data)
	MLA_MTPDevice	device
	Utf8String	path
	MLA_Track	metadata
#//	void *		callback
#//	void const *	data
   CODE:
	RETVAL = LIBMTP_Send_Track_From_File(device, path, metadata, NULL, NULL);
   OUTPUT:
	RETVAL

#// FIXME implement callback
int
LIBMTP_Send_Track_From_File_Descriptor(device, fd, metadata)
#//LIBMTP_Send_Track_From_File_Descriptor(device, fd, metadata, callback, data)
	MLA_MTPDevice	device
	int		fd
	MLA_Track	metadata
#//	void *		callback
#//	void const *	data
   CODE:
	RETVAL = LIBMTP_Send_Track_From_File_Descriptor(device, fd, metadata,
							NULL, NULL);
   OUTPUT:
	RETVAL

#// FIXME
#// int
#// LIBMTP_Send_Track_From_Handler(self, arg1, arg2, arg3, arg4, arg5)
#// 	MLA_MTPDevice	self
#// 	void *		arg1
#// 	void *		arg2
#// 	MLA_Track	arg3
#// 	void *		arg4
#// 	void const *	arg5

int
LIBMTP_Set_Album_Name(self, arg1, arg2)
	MLA_MTPDevice	self
	MLA_Album	arg1
	Utf8String	arg2

int
LIBMTP_Set_File_Name(self, arg1, arg2)
	MLA_MTPDevice	self
	MLA_File	arg1
	Utf8String	arg2

int
LIBMTP_Set_Folder_Name(self, arg1, arg2)
	MLA_MTPDevice	self
	MLA_Folder	arg1
	Utf8String	arg2

int
LIBMTP_Set_Friendlyname(self, arg1)
	MLA_MTPDevice	self
	Utf8String	arg1

int
LIBMTP_Set_Object_String(self, arg1, arg2, arg3)
	MLA_MTPDevice		self
	uint32_t		arg1
	LIBMTP_property_t	arg2
	Utf8String		arg3

int
LIBMTP_Set_Object_u16(self, arg1, arg2, arg3)
	MLA_MTPDevice		self
	uint32_t		arg1
	LIBMTP_property_t	arg2
	uint16_t		arg3

int
LIBMTP_Set_Object_u32(self, arg1, arg2, arg3)
	MLA_MTPDevice		self
	uint32_t		arg1
	LIBMTP_property_t	arg2
	uint32_t		arg3

int
LIBMTP_Set_Object_u8(self, arg1, arg2, arg3)
	MLA_MTPDevice		self
	uint32_t		arg1
	LIBMTP_property_t	arg2
	uint8_t			arg3

int
LIBMTP_Set_Playlist_Name(self, arg1, arg2)
	MLA_MTPDevice	self
	MLA_Playlist	arg1
	Utf8String	arg2

int
LIBMTP_Set_Syncpartner(self, arg1)
	MLA_MTPDevice	self
	Utf8String	arg1

int
LIBMTP_Set_Track_Name(self, arg1, arg2)
	MLA_MTPDevice	self
	MLA_Track	arg1
	Utf8String	arg2

int
LIBMTP_Track_Exists(self, arg1)
	MLA_MTPDevice	self
	uint32_t	arg1

int
LIBMTP_Update_Album(self, arg1)
	MLA_MTPDevice	self
	MLA_Album	arg1

int
LIBMTP_Update_Playlist(self, arg1)
	MLA_MTPDevice	self
	MLA_Playlist	arg1

int
LIBMTP_Update_Track_Metadata(self, arg1)
	MLA_MTPDevice	self
	MLA_Track	arg1


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::MTPDeviceList

void
DESTROY(self)
	MLA_MTPDevice	self
   CODE:
	LIBMTP_Release_Device_List(self);


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::DeviceStorage

uint32_t
id(self)
	MLA_DeviceStorage	self
   CODE:
	RETVAL = self->id;
   OUTPUT:
	RETVAL

uint16_t
StorageType(self)
	MLA_DeviceStorage	self
   CODE:
	RETVAL = self->StorageType;
   OUTPUT:
	RETVAL

uint16_t
FilesystemType(self)
	MLA_DeviceStorage	self
   CODE:
	RETVAL = self->FilesystemType;
   OUTPUT:
	RETVAL

uint16_t
AccessCapability(self)
	MLA_DeviceStorage	self
   CODE:
	RETVAL = self->AccessCapability;
   OUTPUT:
	RETVAL

uint64_t
MaxCapacity(self)
	MLA_DeviceStorage	self
   CODE:
	RETVAL = self->MaxCapacity;
   OUTPUT:
	RETVAL

uint64_t
FreeSpaceInBytes(self)
	MLA_DeviceStorage	self
   CODE:
	RETVAL = self->FreeSpaceInBytes;
   OUTPUT:
	RETVAL

uint64_t
FreeSpaceInObjects(self)
	MLA_DeviceStorage	self
   CODE:
	RETVAL = self->FreeSpaceInObjects;
   OUTPUT:
	RETVAL

Utf8String
StorageDescription(self)
	MLA_DeviceStorage	self
   CODE:
	RETVAL = self->StorageDescription;
   OUTPUT:
	RETVAL

Utf8String
VolumeIdentifier(self)
	MLA_DeviceStorage	self
   CODE:
	RETVAL = self->VolumeIdentifier;
   OUTPUT:
	RETVAL

MLA_DeviceStorage
_next(self)
	MLA_DeviceStorage	self
   CODE:
	RETVAL = self->next;
   OUTPUT:
	RETVAL

MLA_DeviceStorage
_prev(self)
	MLA_DeviceStorage	self
   CODE:
	RETVAL = self->prev;
   OUTPUT:
	RETVAL


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::Error

LIBMTP_error_number_t
errornumber(self)
	MLA_Error	self
   CODE:
	RETVAL = self->errornumber;
   OUTPUT:
	RETVAL

Utf8String
error_text(self)
	MLA_Error	self
   CODE:
	RETVAL = self->error_text;
   OUTPUT:
	RETVAL

MLA_Error
next(self)
	MLA_Error	self
   CODE:
	RETVAL = self->next;
   OUTPUT:
	RETVAL


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::File

MLA_FileList
new(class)
	SV *	class
   CODE:
	RETVAL = LIBMTP_new_file_t();
   OUTPUT:
	RETVAL

uint32_t
item_id(self, newValue = NO_INIT)
	MLA_File	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->item_id = newValue;
	RETVAL = self->item_id;
   OUTPUT:
	RETVAL

uint32_t
parent_id(self, newValue = NO_INIT)
	MLA_File	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->parent_id = newValue;
	RETVAL = self->parent_id;
   OUTPUT:
	RETVAL

uint32_t
storage_id(self, newValue = NO_INIT)
	MLA_File	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->storage_id = newValue;
	RETVAL = self->storage_id;
   OUTPUT:
	RETVAL

Utf8String
filename(self, newValue = NO_INIT)
	MLA_File	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->filename = strdup(newValue);
	RETVAL = self->filename;
   OUTPUT:
	RETVAL

uint64_t
filesize(self, newValue = NO_INIT)
	MLA_File	self
	uint64_t	newValue
   CODE:
	if (items > 1)
	  self->filesize = newValue;
	RETVAL = self->filesize;
   OUTPUT:
	RETVAL

time_t
modificationdate(self, newValue = NO_INIT)
	MLA_File	self
	time_t		newValue
   CODE:
	if (items > 1)
	  self->modificationdate = newValue;
	RETVAL = self->modificationdate;
   OUTPUT:
	RETVAL

LIBMTP_filetype_t
filetype(self, newValue = NO_INIT)
	MLA_File		self
	LIBMTP_filetype_t	newValue
   CODE:
	if (items > 1)
	  self->filetype = newValue;
	RETVAL = self->filetype;
   OUTPUT:
	RETVAL

MLA_File
_next(self)
	MLA_File	self
   CODE:
	RETVAL = self->next;
   OUTPUT:
	RETVAL


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::FileList

void
DESTROY(self)
	MLA_File	self
   CODE:
	LIBMTP_destroy_file_t(self);


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::FileSampleData

void
DESTROY(self)
	MLA_FileSampleData	self
   CODE:
	LIBMTP_destroy_filesampledata_t(self);

MLA_FileSampleData
new(class)
	SV *	class
   CODE:
	RETVAL = LIBMTP_new_filesampledata_t();
   OUTPUT:
	RETVAL

uint32_t
width(self, newValue = NO_INIT)
	MLA_FileSampleData	self
	uint32_t		newValue
   CODE:
	if (items > 1)
	  self->width = newValue;
	RETVAL = self->width;
   OUTPUT:
	RETVAL

uint32_t
height(self, newValue = NO_INIT)
	MLA_FileSampleData	self
	uint32_t		newValue
   CODE:
	if (items > 1)
	  self->height = newValue;
	RETVAL = self->height;
   OUTPUT:
	RETVAL

uint32_t
duration(self, newValue = NO_INIT)
	MLA_FileSampleData	self
	uint32_t		newValue
   CODE:
	if (items > 1)
	  self->duration = newValue;
	RETVAL = self->duration;
   OUTPUT:
	RETVAL

LIBMTP_filetype_t
filetype(self, newValue = NO_INIT)
	MLA_FileSampleData	self
	LIBMTP_filetype_t	newValue
   CODE:
	if (items > 1)
	  self->filetype = newValue;
	RETVAL = self->filetype;
   OUTPUT:
	RETVAL

uint64_t
size(self)
	MLA_FileSampleData	self
   CODE:
	RETVAL = self->size;
   OUTPUT:
	RETVAL

SV *
data(self, newValue = NO_INIT)
	MLA_FileSampleData	self
	SV *			newValue
   PREINIT:
	char *	data;
        STRLEN  size;
   CODE:
	if (items > 1) {
	  if (self->data) Safefree(self->data);
	  data = SvPVbyte(newValue, size);
	  Newx(self->data, size, char);
	  Copy(data, self->data, size, char);
	  self->size = size;
	}
	RETVAL = newSVpvn(self->data, self->size);
	SvUTF8_off(RETVAL);
   OUTPUT:
	RETVAL


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::Folder

MLA_FolderList
new(class)
	SV *	class
   CODE:
	RETVAL = LIBMTP_new_folder_t();
   OUTPUT:
	RETVAL

uint32_t
folder_id(self, newValue = NO_INIT)
	MLA_Folder	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->folder_id = newValue;
	RETVAL = self->folder_id;
   OUTPUT:
	RETVAL

uint32_t
parent_id(self, newValue = NO_INIT)
	MLA_Folder	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->parent_id = newValue;
	RETVAL = self->parent_id;
   OUTPUT:
	RETVAL

uint32_t
storage_id(self, newValue = NO_INIT)
	MLA_Folder	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->storage_id = newValue;
	RETVAL = self->storage_id;
   OUTPUT:
	RETVAL

Utf8String
name(self, newValue = NO_INIT)
	MLA_Folder	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->name = strdup(newValue);
	RETVAL = self->name;
   OUTPUT:
	RETVAL

MLA_Folder
_sibling(self)
	MLA_Folder	self
   CODE:
	RETVAL = self->sibling;
   OUTPUT:
	RETVAL

MLA_Folder
_child(self)
	MLA_Folder	self
   CODE:
	RETVAL = self->child;
   OUTPUT:
	RETVAL

MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::Folder  PREFIX = LIBMTP

MLA_Folder
LIBMTP_Find_Folder(arg0, arg1)
	MLA_Folder	arg0
	uint32_t	arg1


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::FolderList

void
DESTROY(self)
	MLA_Folder	self
   CODE:
	LIBMTP_destroy_folder_t(self);


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::Playlist

MLA_PlaylistList
new(class)
	SV *	class
   CODE:
	RETVAL = LIBMTP_new_playlist_t();
   OUTPUT:
	RETVAL

uint32_t
playlist_id(self, newValue = NO_INIT)
	MLA_Playlist	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->playlist_id = newValue;
	RETVAL = self->playlist_id;
   OUTPUT:
	RETVAL

uint32_t
parent_id(self, newValue = NO_INIT)
	MLA_Playlist	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->parent_id = newValue;
	RETVAL = self->parent_id;
   OUTPUT:
	RETVAL

uint32_t
storage_id(self, newValue = NO_INIT)
	MLA_Playlist	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->storage_id = newValue;
	RETVAL = self->storage_id;
   OUTPUT:
	RETVAL

Utf8String
name(self, newValue = NO_INIT)
	MLA_Playlist	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->name = strdup(newValue);
	RETVAL = self->name;
   OUTPUT:
	RETVAL

AV *
tracks(self, newValue = NO_INIT)
	MLA_Playlist	self
	AV *		newValue
   PREINIT:
	I32		i;
   CODE:
        if (items > 1) {
          if (self->tracks) Safefree(self->tracks);
          i = av_len(newValue);
          self->no_tracks = i + 1;
          Newx(self->tracks, self->no_tracks, uint32_t);
          for (; i >= 0; --i) {
            self->tracks[i] =
              SvUV(*av_fetch(newValue, i, 0));
          }
        }
	RETVAL = newAV();
	sv_2mortal((SV*)RETVAL);
	av_extend(RETVAL, self->no_tracks - 1);
        for (i = 0; i < self->no_tracks; ++i) {
          av_store(RETVAL, i, newSVuv(self->tracks[i]));
        }
   OUTPUT:
	RETVAL

uint32_t
no_tracks(self)
	MLA_Playlist	self
   CODE:
	RETVAL = self->no_tracks;
   OUTPUT:
	RETVAL

MLA_Playlist
_next(self)
	MLA_Playlist	self
   CODE:
	RETVAL = self->next;
   OUTPUT:
	RETVAL


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::PlaylistList

void
DESTROY(self)
	MLA_Playlist	self
   CODE:
	LIBMTP_destroy_playlist_t(self);


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::RawDevice

Utf8String
vendor(self)
	MLA_RawDevice	self
   CODE:
	RETVAL = self->device_entry.vendor;
   OUTPUT:
	RETVAL

uint16_t
vendor_id(self)
	MLA_RawDevice	self
   CODE:
	RETVAL = self->device_entry.vendor_id;
   OUTPUT:
	RETVAL

Utf8String
product(self)
	MLA_RawDevice	self
   CODE:
	RETVAL = self->device_entry.product;
   OUTPUT:
	RETVAL

uint16_t
product_id(self)
	MLA_RawDevice	self
   CODE:
	RETVAL = self->device_entry.product_id;
   OUTPUT:
	RETVAL

uint32_t
device_flags(self)
	MLA_RawDevice	self
   CODE:
	RETVAL = self->device_entry.device_flags;
   OUTPUT:
	RETVAL

uint32_t
bus_location(self)
	MLA_RawDevice	self
   CODE:
	RETVAL = self->bus_location;
   OUTPUT:
	RETVAL

uint8_t
devnum(self)
	MLA_RawDevice	self
   CODE:
	RETVAL = self->devnum;
   OUTPUT:
	RETVAL

MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::RawDevice  PREFIX = LIBMTP_

MLA_MTPDeviceList
LIBMTP_Open_Raw_Device(self)
	MLA_RawDevice	self

MLA_MTPDeviceList
LIBMTP_Open_Raw_Device_Uncached(self)
	MLA_RawDevice	self


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::RawDeviceList

void
DESTROY(self)
	MLA_RawDeviceList	self
   CODE:
	Safefree(self->devices);
	Safefree(self);

int
count(self)
	MLA_RawDeviceList	self
   CODE:
	RETVAL = self->numdevs;
   OUTPUT:
	RETVAL

MLA_RawDevice
_device(self, index)
	MLA_RawDeviceList	self
	int			index
   CODE:
	if (index >= 0 && index < self->numdevs) {
	  RETVAL = self->devices + index;
	} else {
	  RETVAL = NULL;
	}
   OUTPUT:
	RETVAL

void
_devices(self)
	MLA_RawDeviceList	self
   PREINIT:
	int i;
   PPCODE:
	EXTEND(SP, self->numdevs);
	for (i = 0; i < self->numdevs; ++i) {
	  SV* sv = sv_newmortal();
	  sv_setref_pv(sv, "Media::LibMTP::API::RawDevice",
		       (void*)(self->devices + i));
	  PUSHs(sv);
	}


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::Track

MLA_TrackList
new(class)
	SV *	class
   CODE:
	RETVAL = LIBMTP_new_track_t();
   OUTPUT:
	RETVAL

uint32_t
item_id(self, newValue = NO_INIT)
	MLA_Track	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->item_id = newValue;
	RETVAL = self->item_id;
   OUTPUT:
	RETVAL

uint32_t
parent_id(self, newValue = NO_INIT)
	MLA_Track	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->parent_id = newValue;
	RETVAL = self->parent_id;
   OUTPUT:
	RETVAL

uint32_t
storage_id(self, newValue = NO_INIT)
	MLA_Track	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->storage_id = newValue;
	RETVAL = self->storage_id;
   OUTPUT:
	RETVAL

Utf8String
title(self, newValue = NO_INIT)
	MLA_Track	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->title = strdup(newValue);
	RETVAL = self->title;
   OUTPUT:
	RETVAL

Utf8String
artist(self, newValue = NO_INIT)
	MLA_Track	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->artist = strdup(newValue);
	RETVAL = self->artist;
   OUTPUT:
	RETVAL

Utf8String
composer(self, newValue = NO_INIT)
	MLA_Track	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->composer = strdup(newValue);
	RETVAL = self->composer;
   OUTPUT:
	RETVAL

Utf8String
genre(self, newValue = NO_INIT)
	MLA_Track	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->genre = strdup(newValue);
	RETVAL = self->genre;
   OUTPUT:
	RETVAL

Utf8String
album(self, newValue = NO_INIT)
	MLA_Track	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->album = strdup(newValue);
	RETVAL = self->album;
   OUTPUT:
	RETVAL

Utf8String
date(self, newValue = NO_INIT)
	MLA_Track	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->date = strdup(newValue);
	RETVAL = self->date;
   OUTPUT:
	RETVAL

Utf8String
filename(self, newValue = NO_INIT)
	MLA_Track	self
	Utf8String	newValue
   CODE:
	if (items > 1)
	  self->filename = strdup(newValue);
	RETVAL = self->filename;
   OUTPUT:
	RETVAL

uint16_t
tracknumber(self, newValue = NO_INIT)
	MLA_Track	self
	uint16_t	newValue
   CODE:
	if (items > 1)
	  self->tracknumber = newValue;
	RETVAL = self->tracknumber;
   OUTPUT:
	RETVAL

uint32_t
duration(self, newValue = NO_INIT)
	MLA_Track	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->duration = newValue;
	RETVAL = self->duration;
   OUTPUT:
	RETVAL

uint32_t
samplerate(self, newValue = NO_INIT)
	MLA_Track	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->samplerate = newValue;
	RETVAL = self->samplerate;
   OUTPUT:
	RETVAL

uint16_t
nochannels(self, newValue = NO_INIT)
	MLA_Track	self
	uint16_t	newValue
   CODE:
	if (items > 1)
	  self->nochannels = newValue;
	RETVAL = self->nochannels;
   OUTPUT:
	RETVAL

uint32_t
wavecodec(self, newValue = NO_INIT)
	MLA_Track	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->wavecodec = newValue;
	RETVAL = self->wavecodec;
   OUTPUT:
	RETVAL

uint32_t
bitrate(self, newValue = NO_INIT)
	MLA_Track	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->bitrate = newValue;
	RETVAL = self->bitrate;
   OUTPUT:
	RETVAL

uint16_t
bitratetype(self, newValue = NO_INIT)
	MLA_Track	self
	uint16_t	newValue
   CODE:
	if (items > 1)
	  self->bitratetype = newValue;
	RETVAL = self->bitratetype;
   OUTPUT:
	RETVAL

uint16_t
rating(self, newValue = NO_INIT)
	MLA_Track	self
	uint16_t	newValue
   CODE:
	if (items > 1)
	  self->rating = newValue;
	RETVAL = self->rating;
   OUTPUT:
	RETVAL

uint32_t
usecount(self, newValue = NO_INIT)
	MLA_Track	self
	uint32_t	newValue
   CODE:
	if (items > 1)
	  self->usecount = newValue;
	RETVAL = self->usecount;
   OUTPUT:
	RETVAL

uint64_t
filesize(self, newValue = NO_INIT)
	MLA_Track	self
	uint64_t	newValue
   CODE:
	if (items > 1)
	  self->filesize = newValue;
	RETVAL = self->filesize;
   OUTPUT:
	RETVAL

time_t
modificationdate(self, newValue = NO_INIT)
	MLA_Track	self
	time_t	newValue
   CODE:
	if (items > 1)
	  self->modificationdate = newValue;
	RETVAL = self->modificationdate;
   OUTPUT:
	RETVAL

LIBMTP_filetype_t
filetype(self, newValue = NO_INIT)
	MLA_Track	self
	LIBMTP_filetype_t	newValue
   CODE:
	if (items > 1)
	  self->filetype = newValue;
	RETVAL = self->filetype;
   OUTPUT:
	RETVAL

MLA_Track
_next(self)
	MLA_Track	self
   CODE:
	RETVAL = self->next;
   OUTPUT:
	RETVAL


#--------------------------------------------------------------------
MODULE = Media::LibMTP::API  PACKAGE = Media::LibMTP::API::TrackList

void
DESTROY(self)
	MLA_Track	self
   CODE:
	LIBMTP_destroy_track_t(self);
