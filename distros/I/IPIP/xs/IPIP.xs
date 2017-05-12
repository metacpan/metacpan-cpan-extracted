#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "ip_core.h"

//http://my.huhoo.net/archives/2009/09/perlxs-1.html
//http://perldoc.perl.org/perlxs.html
MODULE = IPIP		PACKAGE = IPIP	

SV *init(char *classname,char *path_info)
CODE:
	int n=ip_init(path_info);
	RETVAL=newSVnv(n);
OUTPUT:
	RETVAL
	
SV* find(char *classname,char *str_ip)  
CODE:
	char buffer[512];
	ip_dat_find(str_ip,buffer,sizeof(buffer));
    //printf("void function %s\n",str_ip);
	RETVAL=newSVpv(buffer,0);
OUTPUT:
	RETVAL
	
SV* find_ex(char *classname,char *str_ip)  
CODE:
	char buffer[512]={0};
	ip_datx_find(str_ip,buffer,sizeof(buffer));
	RETVAL=newSVpv(buffer,0);
OUTPUT:
	RETVAL	
	


