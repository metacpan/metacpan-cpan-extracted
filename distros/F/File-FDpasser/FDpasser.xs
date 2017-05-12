#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "FDpasser.h"


MODULE = File::FDpasser		PACKAGE = File::FDpasser		

PROTOTYPES: ENABLE


int
my_send_fd(clifd,fd)
	int	clifd
	int	fd

int
my_recv_fd(servfd)
		int	 servfd


int
my_serv_accept(listenfd,uidptr)
		int	 listenfd
		uid_t	&uidptr

int
cli_conn(name)
		char	*name	      

int
bind_to_fs(fd,name)
		int	fd
		char	*name	      

int
my_isastream(fd)
		int	fd

int
my_getfl(fd)
		int	fd







