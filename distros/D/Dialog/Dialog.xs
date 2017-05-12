/* $Id: Dialog.xs,v 1.1 2000/06/06 07:05:36 mike_s Exp $ */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/*#include "dialog.h"*/
#include <stdlib.h>
#define instr ncurses_instr
#include <dialog.h>

#define uchar unsigned char

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'A':
	if (strEQ(name, "ATTRIBUTE_COUNT"))
	    return ATTRIBUTE_COUNT;
    case 'D':
	if (strEQ(name, "DIALOG_VERSION"))
	    return atof(VERSION);
    case 'F':
	if (strEQ(name, "FALSE"))
	    return FALSE;
    case 'H':
	if (strEQ(name, "HAVE_NCURSES"))
	    return HAVE_NCURSES;
    case 'M':
	if (strEQ(name, "MAX_LEN"))
	    return MAX_LEN;
    case 'T':
	if (strEQ(name, "TRUE"))
	    return TRUE;
    case 'b':
	if (strEQ(name, "border_attr"))
	    return border_attr;
	if (strEQ(name, "button_active_attr"))
	    return button_active_attr;
	if (strEQ(name, "button_inactive_attr"))
	    return button_inactive_attr;
	if (strEQ(name, "button_key_active_attr"))
	    return button_key_active_attr;
	if (strEQ(name, "button_key_inactive_attr"))
	    return button_key_inactive_attr;
	if (strEQ(name, "button_label_active_attr"))
	    return button_label_active_attr;
	if (strEQ(name, "button_label_inactive_attr"))
	    return button_label_inactive_attr;
    case 'c':
	if (strEQ(name, "check_attr"))
	    return check_attr;
	if (strEQ(name, "check_selected_attr"))
	    return check_selected_attr;
    case 'd':
	if (strEQ(name, "darrow_attr"))
	    return darrow_attr;
	if (strEQ(name, "dialog_attr"))
	    return dialog_attr;
    case 'i':
	if (strEQ(name, "inputbox_attr"))
	    return inputbox_attr;
	if (strEQ(name, "inputbox_border_attr"))
	    return inputbox_border_attr;
	if (strEQ(name, "item_attr"))
	    return item_attr;
	if (strEQ(name, "item_selected_attr"))
	    return item_selected_attr;
    case 'm':
	if (strEQ(name, "menubox_attr"))
	    return menubox_attr;
	if (strEQ(name, "menubox_border_attr"))
	    return menubox_border_attr;
    case 'p':
	if (strEQ(name, "position_indicator_attr"))
	    return position_indicator_attr;
    case 's':
	if (strEQ(name, "screen_attr"))
	    return screen_attr;
	if (strEQ(name, "searchbox_attr"))
	    return searchbox_attr;
	if (strEQ(name, "searchbox_border_attr"))
	    return searchbox_border_attr;
	if (strEQ(name, "searchbox_title_attr"))
	    return searchbox_title_attr;
	if (strEQ(name, "shadow_attr"))
	    return shadow_attr;
    case 't':
	if (strEQ(name, "tag_attr"))
	    return tag_attr;
	if (strEQ(name, "tag_key_attr"))
	    return tag_key_attr;
	if (strEQ(name, "tag_key_selected_attr"))
	    return tag_key_selected_attr;
	if (strEQ(name, "tag_selected_attr"))
	    return tag_selected_attr;
	if (strEQ(name, "title_attr"))
	    return title_attr;
    case 'u':
	if (strEQ(name, "uarrow_attr"))
	    return uarrow_attr;
    }
    errno = EINVAL;
    return 0;
}

MODULE = Dialog			PACKAGE = Dialog


double
constant(name,arg)
	char *		name
	int		arg

void
Init()
	PROTOTYPE:
	CODE:
	init_dialog();

void
Exit()
	PROTOTYPE:
	CODE:
	end_dialog();

void
draw_shadow(y, x, h, w, win = stdscr)
int		y
int		x
int		h
int		w
WINDOW *	win
	PROTOTYPE: $$$$;$
	CODE:
	draw_shadow(win, y, x, h, w);

void
draw_box(y, x, h, w, box, border, win = stdscr)
int		y
int		x
int		h
int		w
chtype		box
chtype		border
WINDOW *	win
	PROTOTYPE: $$$$$$;$
	CODE:
	draw_box(win, y, x, h, w, box, border);

int
line_edit(box_y, box_x, box_width, result, win = stdscr)
int		box_y
int		box_x
int		box_width
char *		result
WINDOW *	win
	PROTOTYPE: $$$$;$
	PREINIT:
	char *tmps;
	CODE:
	New(0,tmps,MAX_LEN,char);
	strncpy(tmps, result, MAX_LEN-1);
	RETVAL = line_edit(win, box_y, box_x, MAX_LEN-1, box_width,
	  dialog_attr, 1, tmps, 0);
	result = tmps;
	OUTPUT:
	result
	RETVAL

WINDOW *
stdscr()
	PROTOTYPE:
	CODE:
	RETVAL = stdscr;
	OUTPUT:
	RETVAL

void
refresh()
	PROTOTYPE:

void
Update()
	PROTOTYPE:
	CODE:
	dialog_update();

int
ungetch(ch)
int	ch
	PROTOTYPE: $

void
attrset(attr)
chtype	attr
	PROTOTYPE: $

void
mvprintw(y, x, s)
int	y
int	x
char *	s
	PROTOTYPE: $$$
	CODE:
	mvprintw(y, x, s);

void
gotoyx(y, x)
int		y
int		x
	PROTOTYPE: $$
	PREINIT:
	int yy, xx;
	CODE:
	getyx(stdscr, yy, xx);
	mvcur(yy, xx, y, x);

int
getch()
	PROTOTYPE:

void
Clear()
	PROTOTYPE:
	CODE:
	dialog_clear();

int
YesNo(title, prompt, height, width)
char *	title
char *	prompt
int	height
int	width
	PROTOTYPE: $$$$
	CODE:
	RETVAL = ! dialog_yesno(title, prompt, height, width);
	OUTPUT:
	RETVAL

int
PrgBox(title, line, height, width, pause=1, use_shell=1)
char *	title
char *	line
int	height
int	width
int	pause
int	use_shell
	PROTOTYPE: $$$$;$$
	CODE:
	RETVAL = dialog_prgbox(title, line, height, width, pause, use_shell);
	OUTPUT:
	RETVAL

int
MsgBox(title, prompt, height, width, pause=1)
char *	title
char *	prompt
int	height
int	width
int	pause
	PROTOTYPE: $$$$;$
	CODE:
	RETVAL = dialog_msgbox(title, prompt, height, width, pause);
	OUTPUT:
	RETVAL

int
TextBox(title, file, height, width)
char *	title
char *	file
int	height
int	width
	PROTOTYPE: $$$$
	CODE:
	RETVAL = dialog_textbox(title, file, height, width);
	OUTPUT:
	RETVAL

void
Menu(title, prompt, height, width, menu_height, menu_item1, ...)
char *		title
char *		prompt
int		height
int		width
int		menu_height
SV *		menu_item1 = NO_INIT
	PROTOTYPE: $$$$$@
	PREINIT:
	int item_no, i, cancel, zero = 0;
	uchar **item_list, **item_ptr, *item;
	uchar *result;
	size_t size = 0, tmpsz, len;
	PPCODE:
	item_no = items - 5;
	New(0,item_list,2 * item_no,uchar*);
	item_ptr = item_list;
	for(i=0; i<item_no; i++) {
	  *(item_ptr++) = item = SvPV(ST(i+5), na);
	  tmpsz = na + 1;
	  if(tmpsz > size) size = tmpsz;
	  len = strlen(item);
	  *(item_ptr++) = item + len + (len < na);
	}
	New(0,result,size,char);
	cancel = dialog_menu(title, prompt, height, width, menu_height,
	  item_no, item_list, result, &zero, &zero);
	if(!cancel) XPUSHs(sv_2mortal(newSVpv(result, 0)));
	Safefree(result);
	Safefree(item_list);

void
CheckList(title, prompt, height, width, list_height, menu_item1, ...)
char *		title
char *		prompt
int		height
int		width
int		list_height
SV *		menu_item1 = NO_INIT
	PROTOTYPE: $$$$$@
	PREINIT:
	int item_no, i, cancel;
	uchar **item_list, **item_ptr, *item;
	uchar *result, *strb, *stre;
	size_t size = 1, len;
	PPCODE:
	item_no = items - 5;
	New(0,item_list,3 * item_no,uchar*);
	item_ptr = item_list;
	for(i=0; i<item_no; i++) {
	  *(item_ptr++) = item = SvPV(ST(i+5), na);
	  size += na + 1;
	  len = strlen(item);
	  *(item_ptr++) = item + len + (len < na);
	  *(item_ptr++) = item + len;
	}
	New(0,result,size,char);
	cancel = dialog_checklist(title, prompt, height, width, list_height,
	  item_no, item_list, result);
	if(!cancel) {
	  if(*result == '\0') XPUSHs(sv_2mortal(newSVpv("", 0)));
	  else {
	    for(strb = result; *strb; strb = stre+1) {
	      *(stre = strchr(strb, '\n')) = '\0';
	      XPUSHs(sv_2mortal(newSVpv(strb, 0)));
	    }
	  }
	}
	Safefree(result);
	Safefree(item_list);

void
RadioList(title, prompt, height, width, list_height, menu_item1, ...)
char *		title
char *		prompt
int		height
int		width
int		list_height
SV *		menu_item1 = NO_INIT
	PROTOTYPE: $$$$$@
	PREINIT:
	int item_no, i, cancel;
	uchar **item_list, **item_ptr, *item;
	uchar *result;
	size_t size = 0, tmpsz, len;
	PPCODE:
	item_no = items - 5;
	New(0,item_list,3 * item_no,uchar*);
	item_ptr = item_list;
	for(i=0; i<item_no; i++) {
	  *(item_ptr++) = item = SvPV(ST(i+5), na);
	  size += na + 1;
	  len = strlen(item);
	  *(item_ptr++) = item + len + (len < na);
	  *(item_ptr++) = item + len;
	}
	New(0,result,size,char);
	cancel = dialog_radiolist(title, prompt, height, width, list_height,
	  item_no, item_list, result);
	if(!cancel) XPUSHs(sv_2mortal(newSVpv(result, 0)));
	Safefree(result);
	Safefree(item_list);

void
InputBox(title, prompt, height, width, line)
char *		title
char *		prompt
int		height
int		width
char *		line
	PROTOTYPE: $$$$$
	PREINIT:
	int cancel;
	uchar *result;
	PPCODE:
	New(0,result,MAX_LEN,char);
	strncpy(result, line, MAX_LEN);
	cancel = dialog_inputbox(title, prompt, height, width, result);
	if(!cancel) XPUSHs(sv_2mortal(newSVpv(result, 0)));
	Safefree(result);

int
Y()
	PREINIT:
	int x;
	CODE:
	getsyx(RETVAL, x);
	OUTPUT:
	RETVAL

int
X()
	PREINIT:
	int y;
	CODE:
	getsyx(y, RETVAL);
	OUTPUT:
	RETVAL
