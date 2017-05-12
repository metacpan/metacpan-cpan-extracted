/*
 * Copyright (C) 2003, 2013 by the gtk2-perl team (see the file AUTHORS)
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the LICENSE file in the top level of this distribution
 * for the complete license terms.
 *
 */

#include "gnome2perl.h"

MODULE = Gnome2::UIDefs	PACKAGE = Gnome2::UIDefs

SV *
pad (class)
    ALIAS:
	pad_small = 1
	pad_big = 2
	key_name_quit = 4
	key_mod_quit = 5
	key_name_close = 8
	key_mod_close = 9
	key_name_cut = 10
	key_mod_cut = 11
	key_name_copy = 12
	key_mod_copy = 13
	key_name_paste = 14
	key_mod_paste = 15
	key_name_select_all = 16
	key_mod_select_all = 17
	key_name_clear = 18
	key_mod_clear = 19
	key_name_undo = 20
	key_mod_undo = 21
	key_name_redo = 22
	key_mod_redo = 23
	key_name_save = 24
	key_mod_save = 25
	key_name_open = 26
	key_mod_open = 27
	key_name_save_as = 28
	key_mod_save_as = 29
	key_name_new = 30
	key_mod_new = 31
	key_name_print = 32
	key_mod_print = 33
	key_name_print_setup = 34
	key_mod_print_setup = 35
	key_name_find = 36
	key_mod_find = 37
	key_name_find_again = 38
	key_mod_find_again = 39
	key_name_replace = 40
	key_mod_replace = 41
	key_name_new_window = 42
	key_mod_new_window = 43
	key_name_close_window = 44
	key_mod_close_window = 45
	key_name_redo_move = 46
	key_mod_redo_move = 47
	key_name_undo_move = 48
	key_mod_undo_move = 49
	key_name_pause_game = 50
	key_mod_pause_game = 51
	key_name_new_game = 52
	key_mod_new_game = 53
    PREINIT:
	char key[] = "_";
    CODE:
	switch (ix) {
		case 0: RETVAL = newSViv (GNOME_PAD); break;
		case 1: RETVAL = newSViv (GNOME_PAD_SMALL); break;
		case 2: RETVAL = newSViv (GNOME_PAD_BIG); break;

		case 4: key[0] = GNOME_KEY_NAME_QUIT; RETVAL = newSVpv (key, 0); break;
		case 5: RETVAL = newSViv (GNOME_KEY_MOD_QUIT); break;

		case 8: key[0] = GNOME_KEY_NAME_CLOSE; RETVAL = newSVpv (key, 0); break;
		case 9: RETVAL = newSViv (GNOME_KEY_MOD_CLOSE); break;

		case 10: key[0] = GNOME_KEY_NAME_CUT; RETVAL = newSVpv (key, 0); break;
		case 11: RETVAL = newSViv (GNOME_KEY_MOD_CUT); break;

		case 12: key[0] = GNOME_KEY_NAME_COPY; RETVAL = newSVpv (key, 0); break;
		case 13: RETVAL = newSViv (GNOME_KEY_MOD_COPY); break;

		case 14: key[0] = GNOME_KEY_NAME_PASTE; RETVAL = newSVpv (key, 0); break;
		case 15: RETVAL = newSViv (GNOME_KEY_MOD_PASTE); break;

		case 16: key[0] = GNOME_KEY_NAME_SELECT_ALL; RETVAL = newSVpv (key, 0); break;
		case 17: RETVAL = newSViv (GNOME_KEY_MOD_SELECT_ALL); break;

		case 18: key[0] = GNOME_KEY_NAME_CLEAR; RETVAL = newSVpv (key, 0); break;
		case 19: RETVAL = newSViv (GNOME_KEY_MOD_CLEAR); break;

		case 20: key[0] = GNOME_KEY_NAME_UNDO; RETVAL = newSVpv (key, 0); break;
		case 21: RETVAL = newSViv (GNOME_KEY_MOD_UNDO); break;

		case 22: key[0] = GNOME_KEY_NAME_REDO; RETVAL = newSVpv (key, 0); break;
		case 23: RETVAL = newSViv (GNOME_KEY_MOD_REDO); break;

		case 24: key[0] = GNOME_KEY_NAME_SAVE; RETVAL = newSVpv (key, 0); break;
		case 25: RETVAL = newSViv (GNOME_KEY_MOD_SAVE); break;

		case 26: key[0] = GNOME_KEY_NAME_OPEN; RETVAL = newSVpv (key, 0); break;
		case 27: RETVAL = newSViv (GNOME_KEY_MOD_OPEN); break;

		case 28: key[0] = GNOME_KEY_NAME_SAVE_AS; RETVAL = newSVpv (key, 0); break;
		case 29: RETVAL = newSViv (GNOME_KEY_MOD_SAVE_AS); break;

		case 30: key[0] = GNOME_KEY_NAME_NEW; RETVAL = newSVpv (key, 0); break;
		case 31: RETVAL = newSViv (GNOME_KEY_MOD_NEW); break;

		case 32: key[0] = GNOME_KEY_NAME_PRINT; RETVAL = newSVpv (key, 0); break;
		case 33: RETVAL = newSViv (GNOME_KEY_MOD_PRINT); break;

		case 34: key[0] = GNOME_KEY_NAME_PRINT_SETUP; RETVAL = newSVpv (key, 0); break;
		case 35: RETVAL = newSViv (GNOME_KEY_MOD_PRINT_SETUP); break;

		case 36: key[0] = GNOME_KEY_NAME_FIND; RETVAL = newSVpv (key, 0); break;
		case 37: RETVAL = newSViv (GNOME_KEY_MOD_FIND); break;

		case 38: key[0] = GNOME_KEY_NAME_FIND_AGAIN; RETVAL = newSVpv (key, 0); break;
		case 39: RETVAL = newSViv (GNOME_KEY_MOD_FIND_AGAIN); break;

		case 40: key[0] = GNOME_KEY_NAME_REPLACE; RETVAL = newSVpv (key, 0); break;
		case 41: RETVAL = newSViv (GNOME_KEY_MOD_REPLACE); break;

		case 42: key[0] = GNOME_KEY_NAME_NEW_WINDOW; RETVAL = newSVpv (key, 0); break;
		case 43: RETVAL = newSViv (GNOME_KEY_MOD_NEW_WINDOW); break;

		case 44: key[0] = GNOME_KEY_NAME_CLOSE_WINDOW; RETVAL = newSVpv (key, 0); break;
		case 45: RETVAL = newSViv (GNOME_KEY_MOD_CLOSE_WINDOW); break;

		case 46: key[0] = GNOME_KEY_NAME_REDO_MOVE; RETVAL = newSVpv (key, 0); break;
		case 47: RETVAL = newSViv (GNOME_KEY_MOD_REDO_MOVE); break;

		case 48: key[0] = GNOME_KEY_NAME_UNDO_MOVE; RETVAL = newSVpv (key, 0); break;
		case 49: RETVAL = newSViv (GNOME_KEY_MOD_UNDO_MOVE); break;

		case 50: RETVAL = newSViv (GNOME_KEY_NAME_PAUSE_GAME); break;
		case 51: RETVAL = newSViv (GNOME_KEY_MOD_PAUSE_GAME); break;

		case 52: key[0] = GNOME_KEY_NAME_NEW_GAME; RETVAL = newSVpv (key, 0); break;
		case 53: RETVAL = newSViv (GNOME_KEY_MOD_NEW_GAME); break;

		default: RETVAL = &PL_sv_undef;
	}
    OUTPUT:
	RETVAL
