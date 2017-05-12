#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unistd.h>


MODULE = IO::SendFile		PACKAGE = IO::SendFile		


ssize_t
sendfile(out_fd, in_fd, offset, count)
	int		out_fd
	int		in_fd
	off_t *offset
	size_t	count 


