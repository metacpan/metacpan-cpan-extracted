
###############################################################################
# environment setup

PS1='\$ '

INIT_HAS_RESCUE=nonempty


###############################################################################
# drop to a rescue shell

rescue_shell() {
	echo
	echo "RESCUE SHELL:"
	setsid -c /bin/bash
	rc=$?
	echo
	echo "rescue shell returned $rc"
	echo
}


###############################################################################
# make the user mount the rootfs manually

rootfs_not_found() {

	while [[ 1 ]]
	do
		echo
		echo "Root filesystem not mounted."
		echo "Mount it to /mnt/rootfs manually, then exit this shell."
		echo

		rescue_shell

		if is_rootfs_mounted
		then
			break
		fi

		mount_rootfs

		if is_rootfs_mounted
		then
			break
		fi

	done

	return 0
}

