
###############################################################################
# make the user mount the rootfs manually

ROOTFS_NOT_FOUND=rootfs_not_found_rescue

rootfs_not_found_rescue() {

	while true
	do
		echo
		echo
		echo '*** ERROR ***'
		echo
		echo 'Root filesystem not found.'
		echo
		echo 'Mount it to /mnt/rootfs manually, then exit this shell.'
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

}

