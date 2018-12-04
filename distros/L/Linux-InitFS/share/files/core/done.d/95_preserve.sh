
if [ -d /mnt/rootfs/mnt/initfs ]
then
	mount -o bind / /mnt/rootfs/mnt/initfs
	mount -o ro,remount /mnt/rootfs/mnt/initfs
fi

