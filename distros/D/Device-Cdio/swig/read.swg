/* -*- c -*-
  Copyright (C) 2006, 2008, 2011 Rocky Bernstein <rocky@cpan.org>

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
/* See <cdio/read.h> for more extensive documentation. */

%constant long int READ_MODE_AUDIO = CDIO_READ_MODE_AUDIO;
%constant long int READ_MODE_M1F1  = CDIO_READ_MODE_M1F1;
%constant long int READ_MODE_M1F2  = CDIO_READ_MODE_M1F2;
%constant long int READ_MODE_M2F1  = CDIO_READ_MODE_M2F1;
%constant long int READ_MODE_M2F2  = CDIO_READ_MODE_M2F2;

typedef int cdio_read_mode_t;
%inline %{
  typedef long int my_ssize_t;
%}
%apply my_ssize_t *OUTPUT { my_ssize_t *pi_size };

%rename cdio_lseek lseek;
off_t cdio_lseek(const CdIo_t *p_cdio, off_t offset, int whence=SEEK_SET);

%newobject read_cd; // free malloc'd return value
char *read_cd(const CdIo_t *p_cdio, my_ssize_t i_size, 
	      /*out*/ my_ssize_t *pi_size);

%inline %{
char *
read_cd(const CdIo_t *p_cdio, my_ssize_t i_size, 
	/*out*/ my_ssize_t *pi_size) {
  char *p_buf = calloc(1, i_size);
  *pi_size = cdio_read(p_cdio, p_buf, i_size);
  return p_buf;
}
%}

typedef char * buf_t;
%typemap(out) buf_t {   
  /* $1 is of type buf_t */
  ST(argvi) = sv_newmortal();
  if (result) {
    /* I don't yet know how to pick up arg4 another way.
       THIS MEANS ARG4 MUST ALWAYS BE THE SIZE.  */
    sv_setpvn((SV*)ST(argvi++), (char *) result, arg4);
    /* Don't leak memory. return value was malloc'd by libcdio. */
    free(result);  
  } else {
    sv_setsv((SV*)ST(argvi++), &PL_sv_undef);
  }
}

%apply long int *OUTPUT { long int *drc };
/* NOTE: arg 4 *must* be the size of the buf for the buf_t typemap. */
buf_t read_sectors(const CdIo_t *p_cdio, lsn_t i_lsn, 
		       cdio_read_mode_t read_mode, my_ssize_t i_size, 
		       /*out*/ my_ssize_t *pi_size, 
		       /*out*/ long int *drc);

%inline %{
typedef char *buf_t;
/* NOTE: arg 4 *must* be the size of the buf for the buf_t typemap. */
buf_t
read_sectors(const CdIo_t *p_cdio, lsn_t i_lsn, 
	     cdio_read_mode_t read_mode,  my_ssize_t i_size, 
	     /*out*/ my_ssize_t *pi_size, 
	     /*out*/ long int *drc)
{

  char *p_buf;
  uint32_t i_blocks;
  uint16_t i_blocksize;
  switch (read_mode) {
  case CDIO_READ_MODE_AUDIO: 
    i_blocksize = CDIO_CD_FRAMESIZE_RAW;
    break;
  case CDIO_READ_MODE_M1F1: 
    i_blocksize = M2RAW_SECTOR_SIZE;
    break;
  case CDIO_READ_MODE_M1F2: 
    i_blocksize = M2RAW_SECTOR_SIZE;
    break;
  case CDIO_READ_MODE_M2F1: 
    i_blocksize = CDIO_CD_FRAMESIZE;
    break;
  case CDIO_READ_MODE_M2F2: 
    i_blocksize = M2F2_SECTOR_SIZE;
    break;
  default: 
    pi_size = NULL;
    *drc = DRIVER_OP_BAD_PARAMETER;
    return NULL;
  }
  p_buf = calloc(1, i_size);
  
  i_blocks = i_size / i_blocksize;
  *drc = cdio_read_sectors(p_cdio, p_buf, i_lsn, read_mode, i_blocks);
  if (*drc < 0) {
    pi_size = NULL;
    return NULL;
  }
  *pi_size = i_size;
  return p_buf;
}
 %}

/* NOTE: arg 4 *must* be the size of the buf for the buf_t typemap. */
buf_t
read_data_bytes(const CdIo_t *p_cdio, lsn_t i_lsn, int16_t i_blocksize, 
		my_ssize_t i_size, 
		/*out*/ my_ssize_t *pi_size,
		long int *drc);

%inline %{
/* NOTE: arg 4 *must* be the size of the buf for the buf_t typemap. */
buf_t
read_data_bytes(const CdIo_t *p_cdio, lsn_t i_lsn, 
		int16_t i_blocksize, my_ssize_t i_size, 
		/*out*/ my_ssize_t *pi_size,
		/*out*/ long int *drc) {
  uint32_t i_blocks = i_size / i_blocksize;
  char *p_buf;

  switch (i_blocksize) {
  case CDIO_CD_FRAMESIZE:
  case CDIO_CD_FRAMESIZE_RAW:
  case M2F2_SECTOR_SIZE:
  case M2RAW_SECTOR_SIZE:
    break;
  default:
    /* Don't know about these block sizes */
    pi_size = NULL;
    *drc = DRIVER_OP_BAD_PARAMETER;
    return NULL;
  }
  p_buf = calloc(1, i_size);

#if DEBUGGING  
  printf("p_cdio: %x, i_size: %d, lsn: %d, blocksize %d, blocks %d\n",
	 p_cdio, i_size, i_lsn, i_blocksize, i_blocks);
#endif
  *drc = cdio_read_data_sectors (p_cdio, p_buf, i_lsn, 
				 i_blocksize, i_blocks);
#if DEBUGGING  
  printf("drc: %d\n", drc);
#endif
  if (*drc < 0) {
    pi_size = NULL;
    return NULL;
  }
  *pi_size = i_size;
  return p_buf;
}
%}

iso9660_pvd_t *cdio_read_pvd ( const CdIo_t *p_cdio );
%inline %{
iso9660_pvd_t *cdio_read_pvd ( const CdIo_t *p_cdio ) {
  static iso9660_pvd_t pvd;
  int rc = cdio_read_data_sectors( p_cdio, &pvd, ISO_PVD_SECTOR,
                ISO_BLOCKSIZE, 1);
  if (rc < 0) return NULL;
  return &pvd;
 }
%}

