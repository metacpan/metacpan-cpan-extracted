
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "PerlGtkInt.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"
#include "GdkImlibTypes.h"

MODULE = Gnome::Animator		PACKAGE = Gnome::Animator		PREFIX = gnome_animator_

#ifdef GNOME_ANIMATOR


Gnome::Animator_Sink
new_with_size (Class, width, height)
	SV *	Class
	unsigned int	width
	unsigned int	height
	CODE:
	RETVAL = (GnomeAnimator*)(gnome_animator_new_with_size(width, height));
	OUTPUT:
	RETVAL

void
gnome_animator_set_loop_type (animator, loop_type)
	Gnome::Animator	animator
	Gnome::AnimatorLoopType	loop_type

Gnome::AnimatorLoopType
gnome_animator_get_loop_type (animator)
	Gnome::Animator	animator

void
gnome_animator_set_playback_direction (animator, direction)
	Gnome::Animator	animator
	int	direction

int
gnome_animator_get_playback_direction (animator)
	Gnome::Animator	animator

bool
gnome_animator_append_frame_from_imlib_at_size (animator, image, x_offset, y_offset, interval, width, height)
	Gnome::Animator	animator
	Gtk::Gdk::ImlibImage	image
	int x_offset
	int y_offset
	unsigned int interval
	unsigned int width
	unsigned int height

bool
gnome_animator_append_frame_from_imlib (animator, image, x_offset, y_offset, interval)
	Gnome::Animator	animator
	Gtk::Gdk::ImlibImage	image
	int x_offset
	int y_offset
	unsigned int interval

bool
gnome_animator_append_frame_from_file_at_size (animator, filename, x_offset, y_offset, interval, width, height)
	Gnome::Animator	animator
	char *	filename
	int x_offset
	int y_offset
	unsigned int interval
	unsigned int width
	unsigned int height

bool
gnome_animator_append_frame_from_file (animator, filename, x_offset, y_offset, interval)
	Gnome::Animator	animator
	char *	filename
	int x_offset
	int y_offset
	unsigned int interval

bool
gnome_animator_append_frames_from_imlib_at_size (animator, image, x_offset, y_offset, interval, x_unit, width, height)
	Gnome::Animator	animator
	Gtk::Gdk::ImlibImage	image
	int x_offset
	int y_offset
	unsigned int interval
	int	x_unit
	unsigned int width
	unsigned int height

bool
gnome_animator_append_frames_from_imlib (animator, image, x_offset, y_offset, interval, x_unit)
	Gnome::Animator	animator
	Gtk::Gdk::ImlibImage	image
	int x_offset
	int y_offset
	unsigned int interval
	int	x_unit

bool
gnome_animator_append_frames_from_file_at_size (animator, filename, x_offset, y_offset, interval, x_unit, width, height)
	Gnome::Animator	animator
	char *	filename
	int x_offset
	int y_offset
	unsigned int interval
	int	x_unit
	unsigned int width
	unsigned int height

bool
gnome_animator_append_frames_from_file (animator, filename, x_offset, y_offset, interval, x_unit)
	Gnome::Animator	animator
	char *	filename
	int x_offset
	int y_offset
	unsigned int interval
	int	x_unit

bool
gnome_animator_append_frame_from_gnome_pixmap (animator, pixmap, x_offset, y_offset, interval)
	Gnome::Animator	animator
	Gnome::Pixmap	pixmap
	int x_offset
	int y_offset
	unsigned int interval

void
gnome_animator_start (animator)
	Gnome::Animator	animator

void
gnome_animator_stop (animator)
	Gnome::Animator	animator

bool
gnome_animator_advance (animator, num)
	Gnome::Animator	animator
	int	num

void
gnome_animator_goto_frame (animator, frame)
	Gnome::Animator	animator
	unsigned int	frame

unsigned int
gnome_animator_get_current_frame_number (animator)
	Gnome::Animator	animator

Gnome::AnimatorStatus
gnome_animator_get_status (animator)
	Gnome::Animator	animator

void
gnome_animator_set_playback_speed (animator, speed)
	Gnome::Animator	animator
	double speed

double
gnome_animator_get_playback_speed (animator)
	Gnome::Animator	animator


#endif

