#ifndef LINUX_NETFILTER_LOG_H
#define LINUX_NETFILTER_LOG_H

#include <sys/types.h>
#include <libnetfilter_log/libnetfilter_log.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

struct perl_nflog_group
{
	SV                    *handle;
	struct nflog_g_handle *g_handle;

	CV *callback;
}; 

#endif /* !LINUX_NETFILTER_LOG_H */
