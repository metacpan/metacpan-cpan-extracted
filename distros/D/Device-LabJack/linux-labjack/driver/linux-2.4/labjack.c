/*
 * Labjack USB driver - 0.2
 *
 * Copyright (c) 2003 Eric Sorton <erics@cfl.rr.com>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 2 of the License, or (at your option)
 * any later version.
 *
 * derived from Lego Tower USB driver - 0.52
 * 	Copyright (c) 2001 Juergen Stuber <stuber@loria.fr>
 * derived from USB Skeleton driver - 0.5
 * 	Copyright (c) 2001 Greg Kroah-Hartman (greg@kroah.com)
 *
 * History:
 *
 * 2004-06-15 - 0.2
 * - made changes from the Lego USB driver .54
 * - works only with the 2.4 kernel
 * 2004-07-27 - 0.21
 * - added labjack_get_feature function
 * - labjack_get_feature called when 128 bytes (count == 128) want 
 *   to be read from labjack_read
 */

#include <linux/config.h>
#include <linux/kernel.h>
#include <linux/sched.h>
#include <linux/signal.h>
#include <linux/errno.h>
#include <linux/poll.h>
#include <linux/init.h>
#include <linux/slab.h>
#include <linux/fcntl.h>
#include <linux/module.h>
#include <linux/spinlock.h>
#include <linux/list.h>
#include <linux/smp_lock.h>
#include <linux/devfs_fs_kernel.h>
#include <linux/usb.h>


#ifndef USB_DIR_MASK
#define USB_DIR_MASK 0x80       /* should be in usb.h */
#endif

#ifdef CONFIG_USB_DEBUG
	static int debug = 0;
#else
	static int debug = 0;
#endif


#undef dbg
#define dbg(lvl, format, arg...) do { if (debug >= lvl) printk(KERN_DEBUG  __FILE__ " : " format " \n", ## arg); } while (0)


#define DRIVER_VERSION "v0.2"
#define DRIVER_AUTHOR ""
#define DRIVER_DESC "Labjack USB Driver <http://www.labjack.com/>"


MODULE_PARM(debug, "i");
MODULE_PARM_DESC(debug, "Debug enabled or not");


#define LABJACK_USB_VENDOR_ID		0x0cd5
#define LABJACK_USB_PRODUCT_ID	0x0001


static struct usb_device_id labjack_table [] = {
	{ USB_DEVICE(LABJACK_USB_VENDOR_ID, LABJACK_USB_PRODUCT_ID) },
	{ }
};

MODULE_DEVICE_TABLE (usb, labjack_table);

/* :TODO: Get a minor range for your devices from the usb maintainer */
#define LABJACK_USB_MINOR_BASE	0xf0

#define MAX_DEVICES		16

#define MAX_CONFIGURATION	4

#define COMMAND_TIMEOUT         (2*HZ)  /* 60 second timeout for a command */

struct labjack_usb {
	struct semaphore	sem;		/* locks this structure */
	struct usb_device* 	udev;		/* save off the usb device pointer */
	devfs_handle_t		devfs;		/* devfs device node */
	unsigned char		minor;		/* the starting minor number for this device */

	int			open_count;	/* number of times this port has been opened */
	
	char*			read_buffer;
    int			    read_buffer_length;

	wait_queue_head_t	read_wait;
	wait_queue_head_t	write_wait;

	char*			interrupt_in_buffer;
	struct usb_endpoint_descriptor* interrupt_in_endpoint;
	struct urb*		interrupt_in_urb;

	char*			interrupt_out_buffer;
	struct usb_endpoint_descriptor* interrupt_out_endpoint;
	struct urb*		interrupt_out_urb;
	
	int                     read_timeout;
	int                     write_timeout;
};

/* Note that no locking is needed:
 * read_buffer is arbitrated by read_buffer_length == 0
 * interrupt_out_buffer is arbitrated by interrupt_out_urb->status == -EINPROGRESS
 * interrupt_in_buffer belongs to urb alone and is overwritten on overflow
 */

extern devfs_handle_t usb_devfs_handle;

static ssize_t labjack_read(struct file *file, char *buffer, size_t count, loff_t *ppos);
static ssize_t labjack_get_feature(struct file *file, char *buffer, size_t count, loff_t *ppos);
static ssize_t labjack_write(struct file *file, const char *buffer, size_t count, loff_t *ppos);
static int labjack_ioctl(struct inode *inode, struct file *file, unsigned int cmd, unsigned long arg);
static inline void labjack_delete (struct labjack_usb *dev);
static int labjack_open	(struct inode *inode, struct file *file);
static int labjack_release(struct inode *inode, struct file *file);
static int labjack_release_internal (struct labjack_usb *dev);
static void labjack_abort_transfers (struct labjack_usb *dev);
static void labjack_interrupt_in_callback (struct urb *urb);
static void labjack_interrupt_out_callback (struct urb *urb);
static void* labjack_probe(struct usb_device *dev, unsigned int ifnum, const struct usb_device_id *id);
static void labjack_disconnect(struct usb_device *dev, void *ptr);

/* array of pointers to our devices that are currently connected */
static struct labjack_usb *minor_table[MAX_DEVICES];

/* lock to protect the minor_table structure */
static DECLARE_MUTEX (minor_table_mutex);

static struct file_operations labjack_fops = {
	owner:		THIS_MODULE,
	read:		labjack_read,
	write:		labjack_write,
	ioctl:		labjack_ioctl,
	open:		labjack_open,
	release:	labjack_release,
};

static struct usb_driver labjack_driver = {
	name:		"labjack",
	probe:		labjack_probe,
	disconnect:	labjack_disconnect,
	fops:		&labjack_fops,
	minor:		LABJACK_USB_MINOR_BASE,
	id_table:	labjack_table,
};


static inline void usb_labjack_debug_data (int level, const char *function, int toggle, int size, const unsigned char *data)
{
	int i;

	if (debug < level)
		return; 
	
	printk (KERN_DEBUG __FILE__": %s - toggle = %d, length = %d, data = ", function, toggle, size);

	for (i = 0; i < size; ++i) {
		printk ("%.2x ", data[i]);
	}
	printk ("\n");
}


static inline void labjack_delete (struct labjack_usb *dev)
{
	dbg(2, "%s enter", __func__);

	minor_table[dev->minor] = NULL;
        labjack_abort_transfers (dev);

	if (dev->interrupt_in_urb != NULL) {
		usb_free_urb (dev->interrupt_in_urb);
       }
	if (dev->interrupt_out_urb != NULL) {
		usb_free_urb (dev->interrupt_out_urb);
        }
	if (dev->read_buffer != NULL) {
		kfree (dev->read_buffer);
        }
	if (dev->interrupt_in_buffer != NULL) {
		kfree (dev->interrupt_in_buffer);
        }
	if (dev->interrupt_out_buffer != NULL) {
		kfree (dev->interrupt_out_buffer);
        }
	kfree (dev);

	dbg(2, "%s : leave", __func__);
}


static int labjack_open (struct inode *inode, struct file *file)
{
	struct labjack_usb *dev = NULL;
	int subminor;
	int retval = 0;
	
	dbg(2,"%s : enter", __func__);

	subminor = MINOR (inode->i_rdev) - LABJACK_USB_MINOR_BASE;
	if ((subminor < 0) ||
	    (subminor >= MAX_DEVICES)) {
		retval = -ENODEV;
                goto exit;
	}

	MOD_INC_USE_COUNT;

	down (&minor_table_mutex);
	dev = minor_table[subminor];
	if (dev == NULL) {
		retval = -ENODEV;
                goto unlock_minor_table_exit;
	}

	down (&dev->sem);

    if (dev->open_count == 0) {
        dev->read_timeout = COMMAND_TIMEOUT;
        dev->write_timeout = COMMAND_TIMEOUT;
    }
    
	++dev->open_count;

        if (dev->open_count > 1) {
                retval = -EBUSY;
                goto error;
        }
	file->private_data = dev;
        
        dev->read_buffer_length = 0;
        FILL_INT_URB(
                dev->interrupt_in_urb,
                dev->udev,
                usb_rcvintpipe(dev->udev, dev->interrupt_in_endpoint->bEndpointAddress),
                dev->interrupt_in_buffer,
                dev->interrupt_in_endpoint->wMaxPacketSize,
                labjack_interrupt_in_callback,
                dev,
                dev->interrupt_in_endpoint->bInterval);
        retval = usb_submit_urb (dev->interrupt_in_urb);
        if (retval != 0) {
                err("Couldn't submit interrupt_in_urb");
                goto error;
        }

        goto unlock_exit;

 error:
        labjack_release_internal (dev);

 unlock_exit:
	up (&dev->sem);

 unlock_minor_table_exit:
	up (&minor_table_mutex);
        if (retval != 0) {
                MOD_DEC_USE_COUNT;
        }

 exit:
	dbg(2,"%s : leave, return value %d ", __func__, retval);

	return retval;
}


static int labjack_release (struct inode *inode, struct file *file)
{
	struct labjack_usb *dev;
	int retval = 0;

	dbg(2," %s : enter", __func__);

	dev = (struct labjack_usb *)file->private_data;

	if (dev == NULL) {
	        dbg(1," %s : object is NULL", __func__);
		retval = -ENODEV;
                goto exit;
	}

	down (&minor_table_mutex);

	down (&dev->sem);

 	if (dev->open_count <= 0) {
        	dbg(1," %s : device not opened", __func__);
                up (&dev->sem);
                up (&minor_table_mutex);
		retval = -ENODEV;
		goto exit;
	}

        retval = labjack_release_internal (dev);

	up (&dev->sem);
	up (&minor_table_mutex);

	MOD_DEC_USE_COUNT;

 exit:
	dbg(2," %s : leave, return value %d", __func__, retval);
	return retval;
}


/*
 * NOTE: assumes minor_table and device are locked
 */
static int labjack_release_internal (struct labjack_usb *dev)
{
	int retval = 0;

	dbg(2," %s : enter", __func__);

	if (dev->udev == NULL) {
		/* the device was unplugged before the file was released */
		labjack_delete (dev);
		goto exit;
	}

	--dev->open_count;
	if (dev->open_count <= 0) {
                labjack_abort_transfers (dev);
		dev->open_count = 0;
	}

 exit:
	dbg(2," %s : leave", __func__);

	return retval;
}


static void labjack_abort_transfers (struct labjack_usb *dev)
{
	dbg(2," %s : enter", __func__);

        if (dev == NULL) {
        	dbg(1," %s : dev is null", __func__);
                goto exit;
        }

	if (dev->interrupt_in_urb != NULL) {
                usb_unlink_urb (dev->interrupt_in_urb);
        }
	if (dev->interrupt_out_urb != NULL) {
                usb_unlink_urb (dev->interrupt_out_urb);
        }

 exit:
	dbg(2," %s : leave", __func__);
}


static ssize_t labjack_read (struct file *file, char *buffer, size_t count, loff_t *ppos)
{
        struct labjack_usb *dev;
        size_t bytes_read = 0;
        size_t bytes_to_read;
        int i;
        int retval = 0;
	int timeout = 0;
	
	//printf("Before debug\n");

	dbg(2," %s : enter, count = %d", __func__, count);

	dev = (struct labjack_usb *)file->private_data;
	
	if(count == 128) {
		retval = labjack_get_feature(file, buffer, count, ppos);		
		goto exit;
	}

	down (&dev->sem);

	if (dev->udev == NULL) {
		retval = -ENODEV;
		up (&dev->sem);
		err("No device or device unplugged %d", retval);
		return retval;
	}
	
	if (count == 0) {
          	dbg(1," %s : read request of 0 bytes", __func__);
        	goto exit;
	}

	timeout = dev->read_timeout;

	while (1) {
		if (dev->read_buffer_length == 0) {

			if (timeout <= 0) {
			        retval = -ETIMEDOUT;
			        goto exit;
			}

			if (signal_pending(current)) {

				retval = -EINTR;
				goto exit;
			}

			up (&dev->sem);
			timeout = interruptible_sleep_on_timeout (&dev->read_wait, timeout);
			down (&dev->sem);

                } else {
                        /* copy the data from read_buffer into userspace */
                        bytes_to_read = count > dev->read_buffer_length ? dev->read_buffer_length : count;
                        if (copy_to_user (buffer, dev->read_buffer, bytes_to_read) != 0) {
                                retval = -EFAULT;
                                goto exit;
                        }
                        dev->read_buffer_length -= bytes_to_read;
                        for (i=0; i<dev->read_buffer_length; i++) {
                                dev->read_buffer[i] = dev->read_buffer[i+bytes_to_read];
                        }

                        buffer += bytes_to_read;
                        count -= bytes_to_read;
                        bytes_read += bytes_to_read;
			if (count == 0) {
				break;
			}
                }


        }

        retval = bytes_read;
 exit:
	up (&dev->sem);

	dbg(2," %s : leave, return value %d", __func__, retval);
	return retval;
}


static ssize_t labjack_write (struct file *file, const char *buffer, size_t count, loff_t *ppos)
{
	struct labjack_usb *dev;
	size_t bytes_written = 0;
	size_t bytes_to_write;
    size_t buffer_size;
	int retval = 0;
	int timeout = 0;

	dbg(2," %s : enter, count = %d", __func__, count);

	dev = (struct labjack_usb *)file->private_data;

	down (&dev->sem);

	if (dev->udev == NULL) {
		retval = -ENODEV;
		up (&dev->sem);
		err("No device or device unplugged %d", retval);
		return retval;
	}

	if (count == 0) {
        	dbg(1," %s : write request of 0 bytes", __func__);
		goto exit;
	}

	while (count > 0) {
                if (dev->interrupt_out_urb->status == -EINPROGRESS) {
		        timeout = dev->write_timeout;
			dbg(1," %s : enter timeout: %d", __func__, timeout);
			while (timeout > 0) {
				if (signal_pending(current)) {
					dbg(1," %s : interrupted", __func__);
					return -EINTR;
				}
				up (&dev->sem);
				timeout = interruptible_sleep_on_timeout (&dev->write_wait, timeout);
				down (&dev->sem);
				if (timeout > 0) {
					break;
				}
				dbg(1," %s : interrupted timeout: %d", __func__, timeout);
			}

			dbg(1," %s : final timeout: %d", __func__, timeout);
			if (timeout == 0) {
				dbg(1, "%s - command timed out.", __func__);
				retval = -ETIMEDOUT;
				goto exit;
			}

                	dbg(4," %s : in progress, count = %d", __func__, count);

                } else {
		                dbg(4," %s : sending, count = %d", __func__, count);

                        /* write the data into interrupt_out_buffer from userspace */
                        buffer_size = dev->interrupt_out_endpoint->wMaxPacketSize;
                        bytes_to_write = count > buffer_size ? buffer_size : count;
			dbg(4," %s : buffer_size = %d, count = %d, bytes_to_write = %d", __func__, buffer_size, count, bytes_to_write);

                        if (copy_from_user (dev->interrupt_out_buffer, buffer, bytes_to_write) != 0) {
                                retval = -EFAULT;
                                goto exit;
                        }

                        /* send off the urb */
                        FILL_INT_URB(
                                dev->interrupt_out_urb,
                                dev->udev, 
                                usb_sndintpipe(dev->udev, dev->interrupt_out_endpoint->bEndpointAddress),
                                dev->interrupt_out_buffer,
                                bytes_to_write,
                                labjack_interrupt_out_callback,
                                dev,
                                0);

                        dev->interrupt_out_urb->actual_length = bytes_to_write;
                        retval = usb_submit_urb (dev->interrupt_out_urb);

                        if (retval != 0) {
                                err("Couldn't submit interrupt_out_urb");
                                goto exit;
                        }

                        buffer += bytes_to_write;
                        count -= bytes_to_write;

                        bytes_written += bytes_to_write;
                }
        }

        retval = bytes_written;
 exit:
	up (&dev->sem);

	dbg(2," %s : leave, return value %d", __func__, retval);

	return retval;
}


static ssize_t labjack_get_feature(struct file *file, char *buffer, size_t count, loff_t *ppos) 
{
	struct labjack_usb *dev;
    	int retval = 0;
	
	dbg(2," %s : enter, count = %Zd", __func__, count);
		
	dev = (struct labjack_usb *)file->private_data;
	
	down (&dev->sem);

	if (dev->udev == NULL) {
		retval = -ENODEV;
		err("No device or device unplugged %d", retval);
		goto unlock_exit;
	}
	
	if (count == 0) {
        	dbg(1," %s : read request of 0 bytes", __func__);
        	goto unlock_exit;
	}
		
	retval = usb_control_msg(dev->udev, usb_rcvctrlpipe(dev->udev, 0),
	  	0x01, USB_DIR_IN | USB_TYPE_CLASS | USB_RECIP_INTERFACE,
		(0x03 << 8) + 0x00, 0, (void *)dev->read_buffer, count, HZ * 5);

	if (retval < 0) {
		goto unlock_exit;
        }

	if (copy_to_user (buffer, dev->read_buffer, count)) {
		retval = -EFAULT;
		goto unlock_exit;
	}
	
	goto unlock_exit;
	
unlock_exit:
	up (&dev->sem);
	dbg(2," %s : leave, return value %d", __func__, retval);
	return retval;
}


static int labjack_ioctl (struct inode *inode, struct file *file, unsigned int cmd, unsigned long arg)
{
	struct labjack_usb *dev;
	
	
        int retval =  -ENOTTY;  /* default: we don't understand ioctl */

	dbg(2," %s : enter, cmd 0x%.4x, arg %ld", __func__, cmd, arg);

	dev = (struct labjack_usb *)file->private_data;

	down (&dev->sem);

	if (dev->udev == NULL) {
		retval = -ENODEV;
                goto unlock_exit;
	}
	
        switch (cmd) {
		/* :TODO: add ioctl commands as needed */
	}
 unlock_exit:
	up (&dev->sem);

	dbg(2," %s : leave, return value %d", __func__, retval);

	return retval;
}


static void labjack_interrupt_in_callback (struct urb *urb)
{
	struct labjack_usb *dev = (struct labjack_usb *)urb->context;

	dbg(4," %s : enter, status %d", __func__, urb->status);

        usb_labjack_debug_data(5,__func__, usb_pipedata(urb->pipe), urb->actual_length, urb->transfer_buffer);

        if (urb->status != 0) {
                if ((urb->status != -ENOENT) && (urb->status != -ECONNRESET)) {
		        dbg(1," %s : nonzero status received: %d", __func__, urb->status);
                }
                goto exit;
        }

        down (&dev->sem);

        if (urb->actual_length > 0) {
                if (dev->read_buffer_length <
                    (4 * dev->interrupt_in_endpoint->wMaxPacketSize) - (urb->actual_length)) {
                        memcpy (dev->read_buffer+dev->read_buffer_length, dev->interrupt_in_buffer, urb->actual_length);
                        dev->read_buffer_length += urb->actual_length;
                        wake_up_interruptible (&dev->read_wait);
                } else {
		        dbg(1," %s : read_buffer overflow", __func__);
                }
        }

        up (&dev->sem);

 exit:
        usb_labjack_debug_data(5,__func__, usb_pipedata(urb->pipe), urb->actual_length, urb->transfer_buffer);
	dbg(4," %s : leave, status %d", __func__, urb->status);
}


static void labjack_interrupt_out_callback (struct urb *urb)
{
	struct labjack_usb *dev = (struct labjack_usb *)urb->context;

	dbg(4," %s : enter, status %d", __func__, urb->status);

        usb_labjack_debug_data(5,__func__, usb_pipedata(urb->pipe), urb->actual_length, urb->transfer_buffer);

        if (urb->status != 0) {
                if ((urb->status != -ENOENT) && 
                    (urb->status != -ECONNRESET)) {
                        dbg(1, " %s :nonzero status received: %d", __func__, urb->status);
                }
                goto exit;
        }                        
        wake_up_interruptible(&dev->write_wait);
 exit:
        usb_labjack_debug_data(5,__func__, usb_pipedata(urb->pipe), urb->actual_length, urb->transfer_buffer);

	dbg(4," %s : leave, status %d", __func__, urb->status);
}


static void * labjack_probe (struct usb_device *udev, unsigned int ifnum, const struct usb_device_id *id)
{
	struct labjack_usb *dev = NULL;
	int minor;
	struct usb_interface* interface;
	struct usb_interface_descriptor *iface_desc;
    struct usb_endpoint_descriptor* endpoint;
	int i;
	char name[32];
    void *retval = NULL;

	dbg(2," %s : enter", __func__);

        if (udev == NULL) {
		info ("udev is NULL.");
        }
	
	if ((udev->descriptor.idVendor != LABJACK_USB_VENDOR_ID) ||
	    (udev->descriptor.idProduct != LABJACK_USB_PRODUCT_ID)) {
		goto exit;
	}

        if( ifnum != 0 ) {
		info ("Strange interface number %d.", ifnum);
		goto exit;
        }

	down (&minor_table_mutex);
	for (minor = 0; minor < MAX_DEVICES; ++minor) {
		if (minor_table[minor] == NULL)
			break;
	}
	if (minor >= MAX_DEVICES) {
		info ("Too many devices plugged in, can not handle this device.");
		goto unlock_exit;
	}

	dev = kmalloc (sizeof(struct labjack_usb), GFP_KERNEL);
	if (dev == NULL) {
		err ("Out of memory");
		goto unlock_minor_exit;
	}
	init_MUTEX (&dev->sem);
        down (&dev->sem);
	dev->udev = udev;
	dev->minor = minor;
        dev->open_count = 0;

        dev->read_buffer = NULL;
        dev->read_buffer_length = 0;

        init_waitqueue_head (&dev->read_wait);
        init_waitqueue_head (&dev->write_wait);

        dev->interrupt_in_buffer = NULL;
        dev->interrupt_in_endpoint = NULL;
        dev->interrupt_in_urb = NULL;

        dev->interrupt_out_buffer = NULL;
        dev->interrupt_out_endpoint = NULL;
        dev->interrupt_out_urb = NULL;

        /*
	 * It seems slightly dubious to set up endpoints here, as we may
	 * change the configuration before calling open.  But the endpoints
	 * should be the same in all configurations.
	 */
	interface = &dev->udev->actconfig->interface[0];
	iface_desc = &interface->altsetting[0];

	for (i = 0; i < iface_desc->bNumEndpoints; ++i) {
		endpoint = &iface_desc->endpoint[i];

		if (((endpoint->bEndpointAddress & USB_DIR_MASK) == USB_DIR_IN) &&
		    ((endpoint->bmAttributes & USB_ENDPOINT_XFERTYPE_MASK) == USB_ENDPOINT_XFER_INT)) {
			/* we found an interrupt in endpoint */
                        dev->interrupt_in_endpoint = endpoint;
		}
		
		if (((endpoint->bEndpointAddress & USB_DIR_MASK) == USB_DIR_OUT) &&
		    ((endpoint->bmAttributes & USB_ENDPOINT_XFERTYPE_MASK) == USB_ENDPOINT_XFER_INT)) {
			/* we found an interrupt out endpoint */
                        dev->interrupt_out_endpoint = endpoint;
		}
	}
        if(dev->interrupt_in_endpoint == NULL) {
                err("interrupt in endpoint not found");
                retval = NULL;
                goto unlock_exit;
        }
        if (dev->interrupt_out_endpoint == NULL) {
                err("interrupt out endpoint not found");
                retval = NULL;
                goto unlock_exit;
        }

        dev->read_buffer = kmalloc ((4*dev->interrupt_in_endpoint->wMaxPacketSize), GFP_KERNEL);
        if (!dev->read_buffer) {
                err("Couldn't allocate read_buffer");
                retval = NULL;
                goto unlock_exit;
        }
        dev->interrupt_in_buffer = kmalloc (dev->interrupt_in_endpoint->wMaxPacketSize, GFP_KERNEL);
        if (!dev->interrupt_in_buffer) {
                err("Couldn't allocate interrupt_in_buffer");
                retval = NULL;
                goto unlock_exit;
        }
        dev->interrupt_in_urb = usb_alloc_urb(0);
        if (!dev->interrupt_in_urb) {
                err("Couldn't allocate interrupt_in_urb");
                retval = NULL;
                goto unlock_exit;
        }
        dev->interrupt_out_buffer = kmalloc (dev->interrupt_out_endpoint->wMaxPacketSize, GFP_KERNEL);
        if (!dev->interrupt_out_buffer) {
                err("Couldn't allocate interrupt_out_buffer");
                retval = NULL;
                goto unlock_exit;
        }
        dev->interrupt_out_urb = usb_alloc_urb(0);
        if (!dev->interrupt_out_urb) {
                err("Couldn't allocate interrupt_out_urb");
                retval = NULL;
                goto unlock_exit;
        }                

	udev->actconfig->interface[0].private_data = dev;

	minor_table[minor] = dev;

	sprintf(name, "labjack%d", dev->minor);
	
	dev->devfs = devfs_register (usb_devfs_handle, name,
				     DEVFS_FL_DEFAULT, USB_MAJOR,
				     LABJACK_USB_MINOR_BASE + dev->minor,
				     S_IFCHR | S_IRUSR | S_IWUSR | 
				     S_IRGRP | S_IWGRP | S_IROTH, 
				     &labjack_fops, NULL);

	info ("Labjack USB device now attached to labjack%d", dev->minor);

        retval = dev;

//take out later
	long serial;
	int z =0;
	printk("open: number of configurations: %d\n", dev->udev->descriptor.bNumConfigurations);
		printk("	bDeviceClass %d\n", dev->udev->descriptor.bDeviceClass);
		printk("	bDeviceSubClass %d\n", dev->udev->descriptor.bDeviceSubClass);
		printk("	dDeviceProtocol %d\n", dev->udev->descriptor.bDeviceProtocol);
		printk("	bMaxPacketSize %d\n", dev->udev->descriptor.bMaxPacketSize0);
        printk("    iSerialNumber %d\n", dev->udev->descriptor.iSerialNumber);
        printk("    iManufacturer %d\n", dev->udev->descriptor.iManufacturer);
        printk("    iProduct %d\n", dev->udev->descriptor.iProduct);
        printk("    bcdDevice %d\n", dev->udev->descriptor.bcdDevice);
	serial = ((long)dev->udev->descriptor.bcdDevice)*65536;
	printk("    serial %ld", serial);
		for(z = 0; z < dev->udev->descriptor.bNumConfigurations; z++) {
			struct usb_config_descriptor cfg = dev->udev->config[z];//.desc;
			printk("	Config # %d \n", z);
			printk("	bLength %d\n", cfg.bLength);
			printk("	bDescriptorType %d\n", cfg.bDescriptorType);
			printk("	wTotalLength %d\n", cfg.wTotalLength);
			printk("	bNumInterfaces %d\n", cfg.bNumInterfaces);
			printk("	bConfigurationValue %d\n", cfg.bConfigurationValue);
			printk("	iConfiguration %d\n", cfg.iConfiguration);
			printk("	bmAttributes %d\n", cfg.bmAttributes);
			printk("	MaxPower %d\n", cfg.MaxPower);//bMaxPower);

			//printk("	interface descriptor %d\n",
		}
//take out ends here

 unlock_exit:
        up (&dev->sem);

 unlock_minor_exit:
	up (&minor_table_mutex);

 exit:
	dbg(2," %s : leave, return value 0x%.8lx (dev)", __func__, (long) dev);

	return retval;
}


static void labjack_disconnect (struct usb_device *udev, void *ptr)
{
	struct labjack_usb *dev;
	int minor;

	dbg(2," %s : enter", __func__);

	dev = (struct labjack_usb *)ptr;
	
	down (&minor_table_mutex);
	down (&dev->sem);

	minor = dev->minor;

	devfs_unregister(dev->devfs);

	if (!dev->open_count) {
		up (&dev->sem);
		labjack_delete (dev);
	} else {
		dev->udev = NULL;
		up (&dev->sem);
	}

	info("Labjack USB #%d now disconnected", minor);
	up (&minor_table_mutex);

	dbg(2," %s : leave", __func__);
}


static int __init usb_labjack_init(void)
{
	int result;
        int retval = 0;

	dbg(2," %s : enter", __func__);

	result = usb_register(&labjack_driver);
	if (result < 0) {
		err("usb_register failed for the "__FILE__" driver. Error number %d", result);
		retval = -1;
                goto exit;
	}

	info(DRIVER_DESC " " DRIVER_VERSION);

 exit:
	dbg(2," %s : leave, return value %d", __func__, retval);

	return retval;
}


static void __exit usb_labjack_exit(void)
{
	dbg(2," %s : enter", __func__);

	usb_deregister (&labjack_driver);

	dbg(2," %s : leave", __func__);
}

module_init (usb_labjack_init);
module_exit (usb_labjack_exit);

MODULE_AUTHOR(DRIVER_AUTHOR);
MODULE_DESCRIPTION(DRIVER_DESC);
#ifdef MODULE_LICENSE
MODULE_LICENSE("GPL");
#endif

