
if ! is_rootfs_mounted
then

	if [ -n "$ROOTFS_NOT_FOUND" ]
	then
		$ROOTFS_NOT_FOUND
	else
		echo 'BUG: do not have a failure handler'
	fi

fi

if ! is_rootfs_mounted
then
	exit # panic
fi

