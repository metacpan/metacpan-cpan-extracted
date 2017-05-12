#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <dirent.h>
#include <string.h>
#include <sys/stat.h>
#include <errno.h>
#include <unistd.h>

#define PACKAGE_NAME  "Filesys::DiskUsage::Fast"

static char current_dir[MAXPATHLEN] = ".";
static char parent_dir[MAXPATHLEN] = "..";

static unsigned long long total = 0;
unsigned int debug = 0;
unsigned int show_warnings = 1;
unsigned int sector_size = 0;

unsigned long long get_file_size( char *filename ){
	struct stat stat_buf;
	char cwd[MAXPATHLEN];
	unsigned long long result;
	
	if( lstat( filename, &stat_buf ) == 0 ){
		// ok
		if( S_ISLNK( stat_buf.st_mode ) ){
			return 0;
		}
		else{
			if( sector_size > 1 ){
				// sector
				result = sector_size - 1 + (unsigned long long)stat_buf.st_size;
				result -= result % sector_size;
				
				return result;
			}
			else{
				// real
				return (unsigned long long)stat_buf.st_size;
			}
		}
	}
	else{
		// not ok
		if( show_warnings ){
			memset( cwd, '\0', MAXPATHLEN );
			getcwd( cwd, MAXPATHLEN );
			warn( "could not read file %s%s (%s)", cwd, filename, strerror( errno ) );
		}
		return 0;
	}
}

void get_dir_size( char *dirname ){
	DIR *dir;
	struct dirent *dp;
	char newfile[MAXPATHLEN];
	unsigned long long count = 0;
	char cwd[MAXPATHLEN];
#if defined (__SVR4) && defined (__sun)
	struct stat s;
#endif
	
	// open dir
	if( ( dir = opendir( dirname ) ) == NULL ){
		if( show_warnings ){
			memset( cwd, '\0', MAXPATHLEN ); 
			getcwd( cwd, MAXPATHLEN );
			warn( "could not open dir  %s%s (%s)", cwd, dirname, strerror( errno ) );
		}
		return;
	}
	
	if( chdir( dirname ) == -1 ){
		if( show_warnings )
			warn( "could not chdir     %s (%s)", dirname, strerror( errno ) );
		return;
	}
	
	for( dp = readdir( dir ); dp != NULL; dp = readdir( dir ) ){
#if defined (__SVR4) && defined (__sun)
		stat( dp->d_name, &s );
		if( S_ISDIR( s.st_mode ) ){
#else
		if( dp->d_type == DT_DIR ){
#endif
			// dir
			
			// omit . and ..
			if( strcmp( dp->d_name, current_dir ) == 0 || strcmp( dp->d_name, parent_dir ) == 0 ){
				continue;
			}
			
			get_dir_size( dp->d_name );
		}
		else{
			// file (or fifo, symlink etc.)
			count = get_file_size( dp->d_name );
			
			if( debug )
				fprintf( stderr, "%s: %lld\n", dp->d_name, count );
			
			total += count;
		}
	}
	closedir( dir );
	
	free( dp );
	
	if( chdir("..") == -1 ){
		if( show_warnings )
			warn( "could not chdir to  %s (%s)", "..", strerror( errno ) );
		return;
	}
}

MODULE = Filesys::DiskUsage::Fast		PACKAGE = Filesys::DiskUsage::Fast		

PROTOTYPES: ENABLE

UV
du(...)
	PROTOTYPE: @
	CODE:
		int index;
		char *filepath;
		struct stat stat_buf;
		// char string[25];
		// STRLEN length;
		
		if( ! items ){
			// RETVAL = SvUV( newSVpv("0", 1) );
			RETVAL = PTR2UV(0);
		}
		else{
			total = 0;
			debug = SvTRUE(GvSV(gv_fetchpv(form("%s::Debug", PACKAGE_NAME), TRUE, SVt_PV))) ? 1 : 0;
			show_warnings = SvTRUE(GvSV(gv_fetchpv(form("%s::ShowWarnings", PACKAGE_NAME), TRUE, SVt_PV))) ? 1 : 0;
			sector_size = SvUV(GvSV(gv_fetchpv(form("%s::SectorSize", PACKAGE_NAME), TRUE, SVt_PV)));
			
			for( index = 0 ; index < items ; index++ ){
				SV *stacksv = ST(index);
				filepath = SvPV_nolen(stacksv);
				
				if( stat( filepath, &stat_buf ) == 0 ){
					if( S_ISDIR( stat_buf.st_mode ) ){
						get_dir_size( filepath );
					}
					// else if( S_ISLNK( stat_buf.st_mode ) ){
					// 	;
					// }
					else{
						total += get_file_size( filepath );
					}
				}
			}
			
			// see: http://groups.google.com/group/perl.xs/browse_thread/thread/27e7881105eb4329
			// length = sprintf(string, "%llu", total);
			// RETVAL = SvUV( newSVpv(string, length) );
			RETVAL = PTR2UV(total);
		}
	OUTPUT:
		RETVAL
