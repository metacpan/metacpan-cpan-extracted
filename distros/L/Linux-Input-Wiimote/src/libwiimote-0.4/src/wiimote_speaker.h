/* $Id: wiimote_speaker.h 15 2007-01-09 01:19:31Z bja $ 
 *
 * Copyright (C) 2007, Joel Andersson <bja@kth.se>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#ifndef _WIIMOTE_SPEAKER_H_
#define _WIIMOTE_SPEAKER_H_

#include <stdint.h>

#define WIIMOTE_FMT_S4	0x00
#define WIIMOTE_FMT_S8	0x40

#define WIIMOTE_FREQ_44800HZ 0x0a
#define WIIMOTE_FREQ_33600HZ 0x0e
#define WIIMOTE_FREQ_22400HZ 0x16
#define WIIMOTE_FREQ_11200HZ 0x1a

int wiimote_speaker_init(wiimote_t *wiimote, uint8_t fmt, uint8_t freq);
int wiimote_speaker_free(wiimote_t *wiimote);

int wiimote_speaker_mute(wiimote_t *wiimote);
int wiimote_speaker_unmute(wiimote_t *wiimote);

int wiimote_speaker_enable(wiimote_t *wiimote);
int wiimote_speaker_disable(wiimote_t *wiimote);

int wiimote_speaker_freq(wiimote_t *wiimote, uint8_t freq);
int wiimote_speaker_volume(wiimote_t *wiimote, uint8_t volume);
int wiimote_speaker_play(wiimote_t *wiimote, uint8_t *buf, uint32_t size);

#endif /* WIIMOTE_SPEAKER_H_ */
