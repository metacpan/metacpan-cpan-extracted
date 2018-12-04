
###############################################################################
# halt the system if we cannot find the rootfs

ROOTFS_NOT_FOUND=rootfs_not_found_halt

rootfs_not_found_halt() {

	echo
	echo
	echo '*** FATAL ***'
	echo
	echo 'Unable to locate root filesystem' $ROOTDEV
	echo
	echo 'Halting.'
	echo
	echo

	halt -f

}

