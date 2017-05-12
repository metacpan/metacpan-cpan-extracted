#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

//----------------------------------------------------------------------
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#define _LINUX_TIME_H 1	/* to get things compile on kernel 2.6.x */
#include <linux/videodev2.h>
#include "pwc-ioctl.h"
//----------------------------------------------------------------------
#define SET_PAN		0
#define SET_TILT	1
//----------------------------------------------------------------------
int  fd	= -1;
char *device = "/dev/video0";
//======================================================================
void error_exit(char *what_ioctl)
{
	fprintf(stderr, "Error while doing ioctl %s: %s\n", what_ioctl, strerror(errno));

	/* commented out: some versions of the driver seem to return
	 * unexpected errors */
	/* exit(1); */
}
//======================================================================
void check_device(int *fd)
{
	if (*fd == -1)
	{
		/* open device */
		*fd = open(device, O_RDWR);
		if (*fd == -1)
		{
			fprintf(stderr, "Error while accessing device %s: %s\n", device, strerror(errno));
			exit(1);
		}
	}
}
//======================================================================
void not_supported(char *what)
{
	printf("%s is not supported by the combination\n", what);
	printf("of your webcam and the driver.\n");
}
//======================================================================
void dump_current_settings_ctrl( const char *prefix, int id )
{
	struct v4l2_control vctrl;
	struct v4l2_queryctrl qctrl;
	struct v4l2_querymenu qmenu;
	const char *flags[10];
	int flags_cnt = 0;
	memset(&vctrl, 0, sizeof(vctrl));
	memset(&qctrl, 0, sizeof(qctrl));
	vctrl.id = id;
	qctrl.id = id;
	if (ioctl(fd, VIDIOC_G_CTRL, &vctrl) == -1) {
		printf("%s: VIDIOC_G_CTRL failed: %s\n", prefix, strerror(errno));
		return;
	}
	if (ioctl(fd, VIDIOC_QUERYCTRL, &qctrl) == -1) {
		printf("%s: VIDIOC_QUERYCTRL failed: %s\n", prefix, strerror(errno));
		return;
	}
	if (qctrl.flags & V4L2_CTRL_FLAG_DISABLED)
		flags[flags_cnt++] = "disabled";
	if (qctrl.flags & V4L2_CTRL_FLAG_GRABBED)
		flags[flags_cnt++] = "grabbed";
	if (qctrl.flags & V4L2_CTRL_FLAG_READ_ONLY)
		flags[flags_cnt++] = "read-only";
	if (qctrl.flags & V4L2_CTRL_FLAG_UPDATE)
		flags[flags_cnt++] = "update";
	if (qctrl.flags & V4L2_CTRL_FLAG_INACTIVE)
		flags[flags_cnt++] = "inactive";
	if (qctrl.flags & V4L2_CTRL_FLAG_SLIDER)
		flags[flags_cnt++] = "slider";
	flags[flags_cnt] = NULL;
	switch (qctrl.type) {
	case V4L2_CTRL_TYPE_INTEGER:
		printf("%s: %s\n", prefix, qctrl.name);
		printf("  Value:   %d\n", vctrl.value);
		printf("  Minimum: %d\n", qctrl.minimum);
		printf("  Maximum: %d\n", qctrl.maximum);
		printf("  Step:    %d\n", qctrl.step);
		printf("  Default: %d\n", qctrl.default_value);
		printf("  Flags:   ");
		for (flags_cnt = 0; flags[flags_cnt]; flags_cnt++)
			printf("%s%s", flags_cnt ? "," : "", flags[flags_cnt]);
		printf("\n");
		break;
	case V4L2_CTRL_TYPE_BOOLEAN:
		printf("%s: %s\n", prefix, qctrl.name);
		printf("  Value:   %s\n", vctrl.value ? "enabled" : "disabled");
		printf("  Default: %s\n", qctrl.default_value ? "enabled" : "disabled");
		printf("  Flags:   ");
		for (flags_cnt = 0; flags[flags_cnt]; flags_cnt++)
			printf("%s%s", flags_cnt ? "," : "", flags[flags_cnt]);
		printf("\n");
		break;
	case V4L2_CTRL_TYPE_MENU:
		printf("%s: %s\n", prefix, qctrl.name);
		memset(&qmenu, 0, sizeof(qmenu));
		qmenu.id    = id;
		qmenu.index = vctrl.value;
		if (ioctl(fd, VIDIOC_QUERYMENU, &qmenu) == -1)
			printf("  Value:   ??? (%d)\n", vctrl.value);
		else
			printf("  Value:   %s (%d)\n", qmenu.name, vctrl.value);
		memset(&qmenu, 0, sizeof(qmenu));
		qmenu.id    = id;
		qmenu.index = qctrl.default_value;
		if (ioctl(fd, VIDIOC_QUERYMENU, &qmenu) == -1)
			printf("  Default: ??? (%d)\n", qctrl.default_value);
		else
			printf("  Default: %s (%d)\n", qmenu.name, qctrl.default_value);
		printf("  Flags:   ");
		for (flags_cnt = 0; flags[flags_cnt]; flags_cnt++)
			printf("%s%s", flags_cnt ? "," : "", flags[flags_cnt]);
		printf("\n");
		break;
	case V4L2_CTRL_TYPE_BUTTON:
		printf("%s: %s\n", prefix, qctrl.name);
		printf("  Unsupport type: button\n");
		printf("  Flags:   ");
		for (flags_cnt = 0; flags[flags_cnt]; flags_cnt++)
			printf("%s%s", flags_cnt ? "," : "", flags[flags_cnt]);
		printf("\n");
		break;
	case V4L2_CTRL_TYPE_INTEGER64:
		printf("%s: %s\n", prefix, qctrl.name);
		printf("  Unsupport type: integer64\n");
		printf("  Flags:   ");
		for (flags_cnt = 0; flags[flags_cnt]; flags_cnt++)
			printf("%s%s", flags_cnt ? "," : "", flags[flags_cnt]);
		printf("\n");
		break;
	case V4L2_CTRL_TYPE_CTRL_CLASS:
		printf("%s: %s\n", prefix, qctrl.name);
		printf("  Unsupport type: class\n");
		printf("  Flags:   ");
		for (flags_cnt = 0; flags[flags_cnt]; flags_cnt++)
			printf("%s%s", flags_cnt ? "," : "", flags[flags_cnt]);
		printf("\n");
		break;
	case V4L2_CTRL_TYPE_STRING:
		printf("%s: %s\n", prefix, qctrl.name);
		printf("  Unsupport type: string\n");
		printf("  Flags:   ");
		for (flags_cnt = 0; flags[flags_cnt]; flags_cnt++)
			printf("%s%s", flags_cnt ? "," : "", flags[flags_cnt]);
		printf("\n");
		break;
	}
}
//======================================================================
void dump_current_settings( SV * self )
{
	check_device(&fd);
	
	struct v4l2_capability vcap;
	struct v4l2_format pixfmt;
	struct pwc_probe pwcp;
	int dummy;
	struct pwc_whitebalance pwcwb;
	struct pwc_leds pwcl;
	struct pwc_mpt_range pmr;
	struct pwc_mpt_angles pma;
	struct pwc_serial ps;

	/* get name */
	if (ioctl(fd, VIDIOC_QUERYCAP, &vcap) == -1)
		error_exit("VIDIOC_QUERYCAP");
	printf("Current device: %s (%s @ %s)\n", (const char *)vcap.card, (const char *)vcap.driver, (const char *)vcap.bus_info);

	/* verify that it IS a Philips Webcam */
	if (ioctl(fd, VIDIOCPWCPROBE, &pwcp) == -1)
		error_exit("VIDIOCPWCPROBE");
	if (strcmp((const char *)vcap.card, pwcp.name) != 0)
		printf("Warning: this might not be a Philips compatible webcam!\n");
	printf("VIDIOCPWCPROBE returns: %s - %d\n", pwcp.name, pwcp.type);

	if (ioctl(fd, VIDIOCPWCGSERIAL, &ps) == -1)
		error_exit("VIDIOCPWCGSERIAL");
	printf("Serial number: %s\n", ps.serial);

	/* get resolution/framerate */
	memset(&pixfmt, 0, sizeof(pixfmt));
	pixfmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
	if (ioctl(fd, VIDIOC_G_FMT, &pixfmt) == -1)
		error_exit("VIDIOC_G_FMT");
	printf("Resolution (x, y): %d, %d\n", pixfmt.fmt.pix.width, pixfmt.fmt.pix.height);
	if (pixfmt.fmt.pix.priv & PWC_FPS_FRMASK)
		printf("Framerate: %d\n", (pixfmt.fmt.pix.priv & PWC_FPS_FRMASK) >> PWC_FPS_SHIFT);

	/* color (etc.) settings */
	dump_current_settings_ctrl("Brightness", V4L2_CID_BRIGHTNESS);
	dump_current_settings_ctrl("Hue", V4L2_CID_HUE);
	dump_current_settings_ctrl("Colour", V4L2_CID_SATURATION);
	dump_current_settings_ctrl("Contrast", V4L2_CID_CONTRAST);
	dump_current_settings_ctrl("Whiteness", V4L2_CID_WHITENESS);
	printf("Palette: ");
	switch(pixfmt.fmt.pix.pixelformat) {
	case V4L2_PIX_FMT_GREY:
		printf("Linear intensity grey scale (255 is brightest).\n");
		break;
	case V4L2_PIX_FMT_HI240:
		printf("The BT848 8bit colour cube.\n");
		break;
	case V4L2_PIX_FMT_RGB565:
		printf("RGB565 packed into 16 bit words.\n");
		break;
	case V4L2_PIX_FMT_RGB555:
		printf("RGV555 packed into 16 bit words, top bit undefined.\n");
		break;
	case V4L2_PIX_FMT_BGR24:
		printf("RGB888 packed into 24bit words.\n");
		break;
	case V4L2_PIX_FMT_BGR32:
		printf("RGB888 packed into the low 3 bytes of 32bit words. The top 8bits are undefined.\n");
		break;
	case V4L2_PIX_FMT_YUYV:
		printf("Video style YUV422 - 8bits packed 4bits Y 2bits U 2bits V\n");
		break;
	case V4L2_PIX_FMT_UYVY:
		printf("Describe me\n");
		break;
	case V4L2_PIX_FMT_Y41P:
		printf("YUV411 capture\n");
		break;
	case V4L2_PIX_FMT_YUV422P:
		printf("YUV 4:2:2 Planar\n");
		break;
	case V4L2_PIX_FMT_YUV411P:
		printf("YUV 4:1:1 Planar\n");
		break;
	case V4L2_PIX_FMT_YVU420:
		printf("YUV 4:2:0 Planar\n");
		break;
	case V4L2_PIX_FMT_YVU410:
		printf("YUV 4:1:0 Planar\n");
		break;
	default:
		printf("Unknown! (%d - %c%c%c%c)\n", pixfmt.fmt.pix.pixelformat, pixfmt.fmt.pix.pixelformat & 0xff, (pixfmt.fmt.pix.pixelformat >> 8) & 0xff, (pixfmt.fmt.pix.pixelformat >> 16) & 0xff, (pixfmt.fmt.pix.pixelformat >> 24) & 0xff);
	}

	if (ioctl(fd, VIDIOCPWCGCQUAL, &dummy) == -1)
		error_exit("VIDIOCPWCGCQUAL");
	printf("Compression preference: %d\n", dummy);

	if (ioctl(fd, VIDIOCPWCGAGC, &dummy) == -1)
		error_exit("VIDIOCPWCGAGC");
	printf("Automatic gain control: %d\n", dummy);

	if (ioctl(fd, VIDIOCPWCGAWB, &pwcwb) == -1)
		error_exit("VIDIOCPWCGAWB");
	printf("Whitebalance mode: ");
	if (pwcwb.mode == PWC_WB_AUTO)
		printf("auto\n");
	else if (pwcwb.mode == PWC_WB_MANUAL)
		printf("manual (red: %d, blue: %d)\n", pwcwb.manual_red, pwcwb.manual_blue);
	else if (pwcwb.mode == PWC_WB_INDOOR)
		printf("indoor\n");
	else if (pwcwb.mode == PWC_WB_OUTDOOR)
		printf("outdoor\n");
	else if (pwcwb.mode == PWC_WB_FL)
		printf("artificial lightning ('fl')\n");
	else
		printf("unknown!\n");

	if (ioctl(fd, VIDIOCPWCGLED, &pwcl) != -1)
	{
		printf("Led ON time: %d\n", pwcl.led_on);
		printf("Led OFF time: %d\n", pwcl.led_off);
	}
	else
	{
		not_supported("Blinking of LED");
	}

	if (ioctl(fd, VIDIOCPWCGCONTOUR, &dummy) == -1)
		error_exit("VIDIOCPWCGCONTOUR");
	printf("Sharpness: %d\n", dummy);

	if (ioctl(fd, VIDIOCPWCGBACKLIGHT, &dummy) == -1)
		error_exit("VIDIOCPWCGBACKLIGHT");
	printf("Backlight compensation mode: ");
	if (dummy == 0) printf("off\n"); else printf("on\n");

	if (ioctl(fd, VIDIOCPWCGFLICKER, &dummy) != -1)
	{
		printf("Anti-flicker mode: ");
		if (dummy == 0) printf("off\n"); else printf("on\n");
	}
	else
	{
		not_supported("Anti-flicker mode");
	}

	if (ioctl(fd, VIDIOCPWCGDYNNOISE, &dummy) != -1)
	{
		printf("Noise reduction mode: %d ", dummy);
		if (dummy == 0) printf("(none)");
		else if (dummy == 3) printf("(high)");
		printf("\n");
	}
	else
	{
		not_supported("Noise reduction mode");
	}

	if (ioctl(fd, VIDIOCPWCMPTGRANGE, &pmr) == -1)
	{
		not_supported("Pan/tilt range");
	}
	else
	{
		printf("Pan min. : %d, max.: %d\n", pmr.pan_min, pmr.pan_max);
		printf("Tilt min.: %d, max.: %d\n", pmr.tilt_min, pmr.tilt_max);
	}

	pma.absolute=1;
	if (ioctl(fd, VIDIOCPWCMPTGANGLE, &pma) == -1)
	{
		not_supported("Get pan/tilt position");
	}
	else
	{
		printf("Pan  (degrees * 100): %d\n", pma.pan);
		printf("Tilt (degrees * 100): %d\n", pma.tilt);
	}
}
//======================================================================
void query_pan_tilt_status( SV * self )
{
	check_device(&fd);
	
	struct pwc_mpt_status pms;

	if (ioctl(fd, VIDIOCPWCMPTSTATUS, &pms) == -1)
		error_exit("VIDIOCPWCMPTSTATUS");

	printf("Status: %d\n", pms.status);
	printf("Time pan: %d\n", pms.time_pan);
	printf("Time tilt: %d\n", pms.time_tilt);
}
//======================================================================
void reset_pan_tilt( SV * self, int what )
{
	check_device(&fd);
	
	if (ioctl(fd, VIDIOCPWCMPTRESET, &what) == -1)
		error_exit("VIDIOCPWCMPTRESET");
}
//======================================================================
void set_pan_or_tilt( SV * self, int what, int value)
{
	check_device(&fd);
	
	struct pwc_mpt_angles pma;

	pma.absolute=1;
	if (ioctl(fd, VIDIOCPWCMPTGANGLE, &pma) == -1)
		error_exit("VIDIOCPWCMPTGANGLE");

	if (what == SET_PAN)
		pma.pan = value;
	else if (what == SET_TILT)
		pma.tilt = value;

	if (ioctl(fd, VIDIOCPWCMPTSANGLE, &pma) == -1)
		error_exit("VIDIOCPWCMPTSANGLE");
}
//======================================================================
void set_dimensions_and_framerate( SV * self, int w, int h, int framerate)
{
	check_device(&fd);
	
	struct v4l2_format pixfmt;

	/* get resolution/framerate */
	if (ioctl(fd, VIDIOC_G_FMT, &pixfmt) == -1)
		error_exit("VIDIOC_G_FMT");

	if (w > 0 && h > 0)
	{
		pixfmt.fmt.pix.width = w;
		pixfmt.fmt.pix.height = h;
	}

	if (pixfmt.fmt.pix.priv & PWC_FPS_FRMASK)
	{
		/* set new framerate */
		pixfmt.fmt.pix.priv &= ~PWC_FPS_FRMASK;
		pixfmt.fmt.pix.priv |= (framerate << PWC_FPS_SHIFT);
   
		if (ioctl(fd, VIDIOC_S_FMT, &pixfmt) == -1)
			error_exit("VIDIOC_S_FMT");
	}
	else
	{
		fprintf(stderr, "This device doesn't support setting the framerate.\n");
		exit(1);
	}
}
//======================================================================
void flash_settings( SV * self )
{
	check_device(&fd);
	
	if (ioctl(fd, VIDIOCPWCSUSER) == -1)
		error_exit("VIDIOCPWCSUSER");
}
//======================================================================
void restore_settings( SV * self )
{
	check_device(&fd);
	
	if (ioctl(fd, VIDIOCPWCRUSER) == -1)
		error_exit("VIDIOCPWCRUSER");
}
//======================================================================
void restore_factory_settings( SV * self )
{
	check_device(&fd);
	
	if (ioctl(fd, VIDIOCPWCFACTORY) == -1)
		error_exit("VIDIOCPWCFACTORY");
}
//======================================================================
void set_compression_preference( SV * self, int pref )
{
	check_device(&fd);
	
	if (ioctl(fd, VIDIOCPWCSCQUAL, &pref) == -1)
		error_exit("VIDIOCPWCSCQUAL");
}
//======================================================================
void set_automatic_gain_control( SV * self, int pref )
{
	check_device(&fd);
	
	if (ioctl(fd, VIDIOCPWCSAGC, &pref) == -1)
		error_exit("VIDIOCPWCSAGC");
}
//======================================================================
void set_shutter_speed( SV * self, int pref )
{
	check_device(&fd);
	
	if (ioctl(fd, VIDIOCPWCSSHUTTER, &pref) == -1)
		error_exit("VIDIOCPWCSSHUTTER");
}
//======================================================================
void set_automatic_white_balance_mode( SV * self, char *mode)
{
	check_device(&fd);
	
	struct pwc_whitebalance pwcwb;

	if (ioctl(fd, VIDIOCPWCGAWB, &pwcwb) == -1)
		error_exit("VIDIOCPWCGAWB");

	if (strcasecmp(mode, "auto") == 0)
		pwcwb.mode = PWC_WB_AUTO;
	else if (strcasecmp(mode, "manual") == 0)
		pwcwb.mode = PWC_WB_MANUAL;
	else if (strcasecmp(mode, "indoor") == 0)
		pwcwb.mode = PWC_WB_INDOOR;
	else if (strcasecmp(mode, "outdoor") == 0)
		pwcwb.mode = PWC_WB_OUTDOOR;
	else if (strcasecmp(mode, "fl") == 0)
		pwcwb.mode = PWC_WB_FL;
	else
	{
		fprintf(stderr, "'%s' is not a known white balance mode.\n", mode);
		exit(1);
	}

	if (ioctl(fd, VIDIOCPWCSAWB, &pwcwb) == -1)
		error_exit("VIDIOCPWCSAWB");
}
//======================================================================
void set_automatic_white_balance_mode_red( SV * self, int val)
{
	check_device(&fd);
	
	struct pwc_whitebalance pwcwb;

	if (ioctl(fd, VIDIOCPWCGAWB, &pwcwb) == -1)
		error_exit("VIDIOCPWCGAWB");

	pwcwb.manual_red = val;

	if (ioctl(fd, VIDIOCPWCSAWB, &pwcwb) == -1)
		error_exit("VIDIOCPWCSAWB");
}
//======================================================================
void set_automatic_white_balance_mode_blue( SV * self, int val)
{
	check_device(&fd);
	
	struct pwc_whitebalance pwcwb;

	if (ioctl(fd, VIDIOCPWCGAWB, &pwcwb) == -1)
		error_exit("VIDIOCPWCGAWB");

	pwcwb.manual_blue = val;

	if (ioctl(fd, VIDIOCPWCSAWB, &pwcwb) == -1)
		error_exit("VIDIOCPWCSAWB");
}
//======================================================================
void set_automatic_white_balance_speed( SV * self, int val)
{
	check_device(&fd);
	
	struct pwc_wb_speed pwcwbs;

	if (ioctl(fd, VIDIOCPWCGAWBSPEED, &pwcwbs) == -1)
		error_exit("VIDIOCPWCGAWBSPEED");

	pwcwbs.control_speed = val;

	if (ioctl(fd, VIDIOCPWCSAWBSPEED, &pwcwbs) == -1)
		error_exit("VIDIOCPWCSAWBSPEED");
}
//======================================================================
void set_automatic_white_balance_delay( SV * self, int val)
{
	check_device(&fd);
	
	struct pwc_wb_speed pwcwbs;

	if (ioctl(fd, VIDIOCPWCGAWBSPEED, &pwcwbs) == -1)
		error_exit("VIDIOCPWCGAWBSPEED");

	pwcwbs.control_delay = val;

	if (ioctl(fd, VIDIOCPWCSAWBSPEED, &pwcwbs) == -1)
		error_exit("VIDIOCPWCSAWBSPEED");
}
//======================================================================
void set_led_on_time( SV * self, int val)
{
	check_device(&fd);
	
	struct pwc_leds pwcl;

	if (ioctl(fd, VIDIOCPWCGLED, &pwcl) == -1)
		error_exit("VIDIOCPWCGLED");

	pwcl.led_on = val;

	if (ioctl(fd, VIDIOCPWCSLED, &pwcl) == -1)
		error_exit("VIDIOCPWCSLED");
}
//======================================================================
void set_led_off_time( SV * self, int val)
{
	check_device(&fd);
	
	struct pwc_leds pwcl;

	if (ioctl(fd, VIDIOCPWCGLED, &pwcl) == -1)
		error_exit("VIDIOCPWCGLED");

	pwcl.led_off = val;

	if (ioctl(fd, VIDIOCPWCSLED, &pwcl) == -1)
		error_exit("VIDIOCPWCSLED");
}
//======================================================================
void set_sharpness( SV * self, int val)
{
	check_device(&fd);
	
	if (ioctl(fd, VIDIOCPWCSCONTOUR, &val) == -1)
		error_exit("VIDIOCPWCSCONTOUR");
}
//======================================================================
void set_backlight_compensation( SV * self, int val)
{
	check_device(&fd);
	
	if (ioctl(fd, VIDIOCPWCSBACKLIGHT, &val) == -1)
		error_exit("VIDIOCPWCSBACKLIGHT");
}
//======================================================================
void set_antiflicker_mode( SV * self, int val)
{
	check_device(&fd);
	
	if (ioctl(fd, VIDIOCPWCSFLICKER, &val) == -1)
		error_exit("VIDIOCPWCSFLICKER");
}
//======================================================================
void set_noise_reduction( SV * self, int val)
{
	check_device(&fd);
	
	if (ioctl(fd, VIDIOCPWCSDYNNOISE, &val) == -1)
		error_exit("VIDIOCPWCSDYNNOISE");
}
//======================================================================
//----------------------------------------------------------------------
//======================================================================
void set_device(SV * self, char * dev){
	device = dev;
	return;
}
//======================================================================
//----------------------------------------------------------------------
//======================================================================

MODULE = Device::Video::PWC   PACKAGE = Device::Video::PWC
PROTOTYPES: DISABLE

void set_device( self, dev )
	SV * self
	char * dev
	
void dump_current_settings( self )
	SV * self

void query_pan_tilt_status( self )
	SV * self

void reset_pan_tilt( self, what )
	SV * self
	int what

void set_pan_or_tilt( self, what, value )
	SV * self
	int what
	int value

void set_dimensions_and_framerate( self, w, h, framerate )
	SV * self
	int w 
	int h 
	int framerate

void flash_settings( self )
	SV * self

void restore_settings( self )
	SV * self

void restore_factory_settings( self )
	SV * self

void set_compression_preference( self, pref )
	SV * self
	int pref

void set_automatic_gain_control( self, pref )
	SV * self
	int pref

void set_shutter_speed( self, pref )
	SV * self
	int pref

void set_automatic_white_balance_mode( self, mode )
	SV * self
	char *mode

void set_automatic_white_balance_mode_red( self, val )
	SV * self
	int val

void set_automatic_white_balance_mode_blue( self, val )
	SV * self
	int val

void set_automatic_white_balance_speed( self, val )
	SV * self
	int val

void set_automatic_white_balance_delay( self, val )
	SV * self
	int val

void set_led_on_time( self, val )
	SV * self
	int val

void set_led_off_time( self, val )
	SV * self
	int val

void set_sharpness( self, val )
	SV * self
	int val

void set_backlight_compensation( self, val )
	SV * self
	int val

void set_antiflicker_mode( self, val )
	SV * self
	int val

void set_noise_reduction( self, val )
	SV * self
	int val






































