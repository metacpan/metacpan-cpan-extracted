/* fifo.c
 *
 * Copyright 2003-9, Michael Robinton <michael@bizsystems.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>

/*
 *  struct stat {
 *	dev_t         st_dev;      	device 
 *	ino_t         st_ino;      	inode 
 *	mode_t        st_mode;     	protection 
 *	nlink_t       st_nlink;    	number of hard links 
 *	uid_t         st_uid;      	user ID of owner 
 *	gid_t         st_gid;      	group ID of owner 
 *	dev_t         st_rdev;     	device type (if inode device) 
 *	off_t         st_size;     	total size, in bytes 
 *	unsigned long st_blksize;  	blocksize for filesystem I/O 
 *	unsigned long st_blocks;   	number of blocks allocated 
 *	time_t        st_atime;    	time of last access 
 *	time_t        st_mtime;    	time of last modification 
 *	time_t        st_ctime;    	time of last change 
 *  };
 *
 *  The following POSIX macros are defined to check the file type:
 *  S_ISFIFO(m) fifo?
 *
 *  int stat(const char *file_name, struct stat *buf);
 *    On success, zero is returned.  On error, -1 is returned,
 *    and errno is set appropriately.
 *
 *  int mkfifo ( const char *pathname, mode_t mode );
 *    The normal, successful return value from mkfifo is 0.  In the
 *    case of an error, -1 is returned (in  which  case, errno is 
 *    set appropriately).
 */

/*	create a fifo if it does not exist.
 *	return 0 on success, else the errno.
 */
int
make_fifo(char * fifo_path)
{
  struct stat fifostat;
  int mask;
  
  if (stat(fifo_path,&fifostat)) {
    if (errno != ENOENT)
	return(errno);

    mask = umask(027);
    if (mkfifo(fifo_path,0777)) {
        umask(mask);
	return(errno);
    }
    umask(mask);
  }
  else {
    if ((fifostat.st_mode & S_IFMT) == S_IFIFO)		/* check for FIFO	*/
	 return(errno = 0);
    return(errno = EEXIST);
  }
  return(errno = 0);
}

/*	open a fifo for write, non-blocking, if it is not already open.
 *	returns 0 on success, else the errno.
 */
int
open_fifo(int * fd, char * fifo_path)
{
  if (*fd > 0)	/*	already open ?	*/
      return(errno =0);

  if ((*fd = open(fifo_path, O_NONBLOCK | O_WRONLY)) > 0)
      return(errno = 0);

  return(errno);
}

/*	write string to fifo, returns 0 on success or errno
 *	this is a write to a non-blocking file handle and
 *	is unreliable (like UDP)
 */
int
write_fifo(int fd, char * message)
{
  int status, len;

  len = strlen(message);

  if((status = (int)write(fd,message,len)) == len)
  	return(errno = 0);

  if (status < 0)	/* real error	*/
  	return(errno);

  /* short write	*/
  return(errno = ENOSPC);
}

