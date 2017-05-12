/*
 * Author: Paul.Russell@rustcorp.com.au and mneuling@radlogic.com.au
 *
 * Based on the ipchains code by Paul Russell and Michael Neuling
 *
 * (C) 2000-2002 by the netfilter coreteam <coreteam@netfilter.org>:
 * 		    Paul 'Rusty' Russell <rusty@rustcorp.com.au>
 * 		    Marc Boucher <marc+nf@mbsi.ca>
 * 		    James Morris <jmorris@intercode.com.au>
 * 		    Harald Welte <laforge@gnumonks.org>
 * 		    Jozsef Kadlecsik <kadlec@blackhole.kfki.hu>
 *
 *	iptables -- IP firewall administration for kernels with
 *	firewall table (aimed for the 2.3 kernels)
 *
 *	See the accompanying manual page iptables(8) for information
 *	about proper usage of this program.
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; either version 2 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program; if not, write to the Free Software
 *	Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <iptables.h>
#include "iptables-multi.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/file.h>

#define LOCK_FILE "/var/lock/iptables_cmd_lock"

#ifdef IPTABLES_MULTI
int
iptables_blocking(int argc, char *argv[])
#else
int
main(int argc, char *argv[])
#endif
{
        int fd;
	int ret;
	char *table = "filter";
	struct iptc_handle *handle = NULL;

	iptables_globals.program_name = "iptables";
	//iptables_globals.program_version = XTABLES_VERSION;

	ret = xtables_init_all(&iptables_globals, NFPROTO_IPV4);
	if (ret < 0) {
		fprintf(stderr, "%s/%s Failed to initialize xtables\n",
				iptables_globals.program_name,
				iptables_globals.program_version);
				exit(1);
	}
#ifdef NO_SHARED_LIBS
	init_extensions();
#endif

	fd = open(LOCK_FILE, O_CREAT|O_WRONLY|O_TRUNC, S_IRWXU|S_IRGRP);
	if (fd < 0) {
		fprintf(stderr, "iptables: Cannot open lock file %s (strerr:%s)\n",
			LOCK_FILE, strerror(errno));
		exit(errno);
	}
	flock(fd, LOCK_EX);

	ret = do_command(argc, argv, &table, &handle);
	if (ret) {
		ret = iptc_commit(handle);
		if (errno == EAGAIN) {
			fprintf(stderr, "iptc_commit: %s\n", strerror(errno));
			exit(RESOURCE_PROBLEM);
		}
		iptc_free(handle);
	}

	flock(fd, LOCK_UN);


	if (!ret) {
		fprintf(stderr, "fall-through(errno:%d) iptables: %s\n",
			errno, iptc_strerror(errno));
		/* Test: Try to get the errno... */
		/* exit(errno); */
	}

	exit(!ret);
}
