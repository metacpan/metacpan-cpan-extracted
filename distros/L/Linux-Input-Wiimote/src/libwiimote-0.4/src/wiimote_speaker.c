/* $Id: wiimote_speaker.c 15 2007-01-09 01:19:31Z bja $ 
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

#include <stdlib.h>
#include <string.h>

#include "wiimote.h"
#include "wiimote_speaker.h"
#include "wiimote_report.h"
#include "wiimote_error.h"
#include "wiimote_io.h"

#define SPK_REG_CFG		0x04a20001
#define SPK_REG_VOL		0x04a20005
#define SPK_REG_FREQ	0x04a20004

typedef union {
	struct {
		uint8_t byte0;
		uint8_t format;
		uint8_t byte2;
		uint8_t freq;
		uint8_t volume;
		uint8_t byte5;
		uint8_t byte6;
	};
	uint8_t data[7];
} __attribute__((packed)) speaker_config_t;

int wiimote_speaker_init(wiimote_t *wiimote, uint8_t fmt, uint8_t freq)
{
	speaker_config_t cfg = {{ 0 }};
	cfg.volume = 0x40;
	cfg.freq= freq;
	cfg.format = fmt;
	
	wiimote_send_byte(wiimote, WIIMOTE_RID_SPK_EN, 0x04);
	wiimote_send_byte(wiimote, WIIMOTE_RID_SPK_MUTE, 0x04);
	wiimote_write_byte(wiimote, 0x04a20009, 0x01);
	wiimote_write_byte(wiimote, 0x04a20001, 0x08);
	wiimote_write(wiimote, SPK_REG_CFG, cfg.data, sizeof (speaker_config_t));
	wiimote_write_byte(wiimote, 0x04a20008, 0x01);
	wiimote_send_byte(wiimote, WIIMOTE_RID_SPK_MUTE, 0x00);
	
	return WIIMOTE_OK;
}

int wiimote_speaker_free(wiimote_t *wiimote)
{
	wiimote_send_byte(wiimote, WIIMOTE_RID_SPK_MUTE, 0x04);
	wiimote_write_byte(wiimote, 0x04a20009, 0x00);
	wiimote_write_byte(wiimote, 0x04a20001, 0x00);
	wiimote_send_byte(wiimote, WIIMOTE_RID_SPK_EN, 0x00);
	return WIIMOTE_OK;	
}

int wiimote_speaker_freq(wiimote_t *wiimote, uint8_t freq)
{
	return wiimote_write_byte(wiimote, SPK_REG_FREQ, freq);
}

int wiimote_speaker_mute(wiimote_t *wiimote)
{
	return wiimote_send_byte(wiimote, WIIMOTE_RID_SPK_MUTE, 0x04);
}

int wiimote_speaker_unmute(wiimote_t *wiimote)
{
	return wiimote_send_byte(wiimote, WIIMOTE_RID_SPK_MUTE, 0x00);
}

int wiimote_speaker_enable(wiimote_t *wiimote)
{
	return wiimote_send_byte(wiimote, WIIMOTE_RID_SPK_EN, 0x04);
}

int wiimote_speaker_disable(wiimote_t *wiimote)
{
	return wiimote_send_byte(wiimote, WIIMOTE_RID_SPK_EN, 0x00);
}

int wiimote_speaker_volume(wiimote_t *wiimote, uint8_t volume)
{
	return wiimote_write_byte(wiimote, SPK_REG_VOL, volume);
}

int wiimote_speaker_play(wiimote_t *wiimote, uint8_t *buf, uint32_t size)
{
	wiimote_report_t r = WIIMOTE_REPORT_INIT;
	uint32_t offset = 0;
	
	r.channel = WIIMOTE_RID_SPK;
	
	while (offset < size) {
		r.speaker.size = (size-offset) > 20 ? 20 : (size-offset);
		memcpy(r.speaker.data, buf, r.speaker.size); 
		if (wiimote_report(wiimote, &r, sizeof(r.speaker)) < 0) {
			wiimote_error("wiimote_speaker_play(): report failed");
			return WIIMOTE_ERROR;
		}
		offset += r.speaker.size;
	}
	
	return WIIMOTE_OK;
}
