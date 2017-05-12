#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* Perl #define's instr in embed.h, but so does ncurses, in all honesty I have
   no idea the consequences of #undef'ing this */
#undef instr

#include <dialog.h>

#include "const-c.inc"

/* stolen from menu.c */
static int
dlg_dummy_menutext(DIALOG_LISTITEM * items, int current, char *newtext)
{
    (void) items;
    (void) current;
    (void) newtext;
    return DLG_EXIT_ERROR;
}

/* stolen from menu.c */
static int
dlg_renamed_menutext(DIALOG_LISTITEM * items, int current, char *newtext)
{
    if (dialog_vars.input_result)
	dialog_vars.input_result[0] = '\0';
    dlg_add_result("RENAMED ");
    dlg_add_string(items[current].name);
    dlg_add_result(" ");
    dlg_add_string(newtext);
    return DLG_EXIT_EXTRA;
}

SV * _get_hash_key_sv_from_array(SV *items, I32 index, char *key) {
    SV **name_hash = av_fetch((AV *)SvRV(items), index, 0);

    if (!name_hash) {
        croak("item from av_fetch is NULL");
    }

    SV **name_key = hv_fetch((HV *)SvRV(*name_hash), key, strlen(key), NULL);

    if (!name_key) {
        croak("item from hv_fetch is NULL");
    }

    return *name_key;
}

MODULE = Hobocamp::Dialog        PACKAGE = Hobocamp::Dialog

INCLUDE: const-xs.inc

# -------- util --------

void
init(in = stdin, out = stderr)
    FILE *in
    FILE *out
    PROTOTYPE: $$
    CODE:
        init_dialog(in, out);

void
end_dialog();

void
destroy()
    PROTOTYPE:
    CODE:
        end_dialog();

void
dlg_put_backtitle()

void
dlg_clr_result()

const char *
dialog_version()

void
dlg_clear()

void
_set_ascii_lines_state(int state = 1)
     PROTOTYPE: $
     CODE:
         if (state) {
             dialog_vars.ascii_lines = TRUE;
             dialog_vars.no_lines = FALSE;
         }
         else {
             dialog_vars.ascii_lines = FALSE;
             dialog_vars.no_lines = TRUE;
        }

# -------- widgets --------

int
dialog_calendar(const char *title, const char *subtitle, int height, int width, int day = 1, int month = 1, int year = 1970)

int
dialog_checklist(title, prompt, height, width, list_height = 1, items_list, checklist_or_radio_flag = 1)
    const char *title
    const char *prompt
    int height
    int width
    int list_height
    SV *items_list
    int checklist_or_radio_flag
    PROTOTYPE: $$$$$$$
    PREINIT:
        I32 i;
        I32 items_amount = 0;
        int current_item = 0;
        DIALOG_LISTITEM *listitems;
        int dialog_return_code;
    INIT:
        items_amount = av_len((AV *)SvRV(items_list)) + 1;
    PPCODE:
        listitems = dlg_calloc(DIALOG_LISTITEM, (size_t) items_amount);

        for (i = 0; i < items_amount; i++) {
            listitems[i].name = SvPV_nolen(_get_hash_key_sv_from_array(items_list, i, "name"));
            listitems[i].text = SvPV_nolen(_get_hash_key_sv_from_array(items_list, i, "text"));

            if (dialog_vars.item_help) {
                listitems[i].help = SvPV_nolen(_get_hash_key_sv_from_array(items_list, i, "help"));
            }
            else {
                listitems[i].help = dlg_strempty();
            }
            listitems[i].state = hv_exists((HV *)SvRV(*av_fetch((AV *)SvRV(items_list), i, 0)),
                                           "on",
                                           strlen("on")) ? 1 : 0;
        }

        dlg_align_columns(&listitems[0].text, sizeof(DIALOG_LISTITEM), items_amount);

	dialog_return_code = dlg_checklist(title,
                                           prompt,
                                           height,
                                           width,
                                           list_height,
                                           items_amount,
                                           listitems,
                                           NULL,
                                           checklist_or_radio_flag,
                                           &current_item);


        dlg_free_columns(&listitems[0].text, sizeof(DIALOG_LISTITEM), items_amount);
        free(listitems);

        if (G_ARRAY) {
            mXPUSHi(dialog_return_code);
            for (i = 0; i < items_amount; i++) {
                if (listitems[i].state) {
                    mXPUSHi(i);
                }
            }
        }
        else if (G_SCALAR) {
            mXPUSHi(dialog_return_code);
        }

int
dialog_dselect(const char *title, const char *path, int height, int width)

int
dialog_editbox(const char *title, const char *file, int height, int width)

# TODO dialog_form

int
dialog_fselect(const char *title, const char *path, int height, int width)

# TODO int
# dialog_gauge(const char *title, const char *prompt, int height, int width, int percent)

int
dialog_inputbox(const char *title, const char *prompt, int height, int width, const char *init, int password = 0)

void
dialog_menu(title, prompt, height, width, menu_height = 1, items_menu)
    const char *title
    const char *prompt
    int height
    int width
    int menu_height
    SV *items_menu
    PROTOTYPE: $$$$$$
    PREINIT:
        I32 i;
        I32 items_amount = 0;
        int current_item = 0;
        DIALOG_LISTITEM *listitems;
        int dialog_return_code;
    INIT:
        items_amount = av_len((AV *)SvRV(items_menu)) + 1;
    PPCODE:
        listitems = dlg_calloc(DIALOG_LISTITEM, (size_t) items_amount);

        for (i = 0; i < items_amount; i++) {
            listitems[i].name = SvPV_nolen(_get_hash_key_sv_from_array(items_menu, i, "name"));
            listitems[i].text = SvPV_nolen(_get_hash_key_sv_from_array(items_menu, i, "text"));

            if (dialog_vars.item_help) {
                listitems[i].help = SvPV_nolen(_get_hash_key_sv_from_array(items_menu, i, "help"));
            }
            else {
                listitems[i].help = dlg_strempty();
            }
        }

        dlg_align_columns(&listitems[0].text, sizeof(DIALOG_LISTITEM), items_amount);

	dialog_return_code = dlg_menu(title,
                                      prompt,
                                      height,
                                      width,
                                      menu_height,
                                      items_amount,
                                      listitems,
                                      &current_item,
                                      dialog_vars.input_menu ? dlg_renamed_menutext : dlg_dummy_menutext);

        dlg_free_columns(&listitems[0].text, sizeof(DIALOG_LISTITEM), items_amount);
        free(listitems);

        if (G_ARRAY) {
            mXPUSHi(dialog_return_code);
            mXPUSHi(current_item);
        }
        else if (G_SCALAR) {
            mXPUSHi(dialog_return_code);
        }

# TODO dialog_mixedform
# TODO dialog_mixedgauge

int
dialog_msgbox(const char *title, const char *prompt, int height, int width, int pause=1)

int
dialog_pause(const char *title, const char *prompt, int height, int width, int seconds = 10)

# TODO dialog_progressbox
# TODO dialog_tailbox

int
dialog_textbox(const char *title, const char *file, int height, int width)

int
dialog_timebox(const char *title, const char *subtitle, int height, int width, int hour = 12, int minute = 0 , int second = 0)

int
dialog_yesno(const char *title, const char *prompt, int height, int width)

# -------- extra --------

void
_dialog_result()
    PROTOTYPE:
    PPCODE:
        mXPUSHs(newSVpv(dialog_vars.input_result, 0));
        dlg_clr_result();

void
_dialog_set_backtitle(title)
    char *title
    PROTOTYPE: $
    CODE:
        if (dialog_vars.backtitle != NULL) {
            free(dialog_vars.backtitle);
        }
        dialog_vars.backtitle = title;
