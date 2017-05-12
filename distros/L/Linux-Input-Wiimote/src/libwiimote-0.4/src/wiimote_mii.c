/* $Id: wiimote_mii.c 28 2007-02-07 19:15:15Z bja $
 *
 * Copyright (C) 2007, Chad Phillips <chad@chadphillips.org>
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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "wiimote.h"
#include "wiimote_mii.h"
#include "wiimote_error.h"
#include "wiimote_io.h"

//-----------------------------------------------------------------------------
// Save Data Defines
#define WIIMOTE_SAVEDATA_BEGIN				0x0000
#define WIIMOTE_SAVEDATA_SIZE				5888

//-----------------------------------------------------------------------------
// MII Data Defines
#define WIIMOTE_MII_DATA_BEGIN_ADDR			0x0FCA
#define WIIMOTE_MII_DATA_BEGIN_1			0x0FD2
#define WIIMOTE_MII_SLOT_SIZE				74
#define WIIMOTE_MII_SLOT_NUM				10

#define WIIMOTE_MII_SECTION1_BEGIN_ADDR			0x0FCA
#define WIIMOTE_MII_SECTION2_BEGIN_ADDR			0x12BA
#define WIIMOTE_MII_SECTION_SIZE			750	// Size in bytes

#define WIIMOTE_MII_CHECKSUM1_ADDR			0x12B8
#define WIIMOTE_MII_CHECKSUM2_ADDR			0x15A8
#define WIIMOTE_MII_CHECKSUM_SIZE			2	// Size in bytes

#define WIIMOTE_MII_PARADESLOTS_ADDR			0x0FCE
#define WIIMOTE_MII_PARADESLOTS_SIZE			2

//-----------------------------------------------------------------------------
// MII CRC16 Defines
#define WIIMOTE_MII_CRC16_POLY				0x1021
#define WIIMOTE_MII_CRC16_INITIAL			0xFFFF
#define WIIMOTE_MII_CRC16_POSTXOR			0xEF4C

//-----------------------------------------------------------------------------
// MII Data Structure Defines
#define MII_NAME_LENGTH					10
#define MII_CREATOR_NAME_LENGTH				10

#define MII_HEIGHT_MIN					0x00
#define MII_HEIGHT_MAX					0x7F

#define MII_WEIGHT_MIN					0x00
#define MII_WEIGHT_MAX					0x7F

//------------------------------------------------------------------------------
//  Function:   wiimote_mii_dump_all
//  Purpose:    Read all save data from the wiimote and write it to the given file
//  Parameters: wiimote, filename
//  Returns: -1 on error, 0 on success
//------------------------------------------------------------------------------
int wiimote_mii_dump_all(wiimote_t *wiimote, const char *filename)
{
    FILE *file;
    uint8_t data[WIIMOTE_SAVEDATA_SIZE];
    uint32_t offset = WIIMOTE_SAVEDATA_BEGIN;
    uint32_t dlen = WIIMOTE_SAVEDATA_SIZE;

    if (wiimote_read(wiimote, offset, data, dlen)) {
	wiimote_error("wiimote_mii_dump_all(): wiimote_read");
	return WIIMOTE_ERROR;
    }

    file = fopen(filename, "wb");
    if (!file) {
	wiimote_error("wiimote_mii_dump_all(): fopen: %m");
	return WIIMOTE_ERROR;
    }

    if (fwrite(data, 1, WIIMOTE_SAVEDATA_SIZE, file) < 0) {
	wiimote_error("wiimote_mii_dump_all(): fwrite: %m");
	fclose(file);
	return WIIMOTE_ERROR;
    }

    if (fclose(file) < 0) {
	wiimote_error("wiimote_mii_dump_all(): fclose: %m");
	return WIIMOTE_ERROR;
    }

    return WIIMOTE_OK;
}

//------------------------------------------------------------------------------
//  Function:   wiimote_mii_dump
//  Purpose:    Reads one Mii slot from wiimote and writes it to the given file
//  Parameters: wiimote, filename, slot number
//  Returns: -1 on error, 0 on success
//------------------------------------------------------------------------------
int wiimote_mii_dump(wiimote_t *wiimote, const char *filename, int slot)
{
    FILE *file;
    uint8_t data[WIIMOTE_MII_SLOT_SIZE];

    if (wiimote_mii_read(wiimote, data, slot) < 0) {
	wiimote_error("wiimote_mii_dump_slot(): wiimote_mii_read_slot");
	return WIIMOTE_ERROR;
    }

    file = fopen(filename, "wb");
    if (!file) {
	wiimote_error("wiimote_mii_dump_slot(): fopen: %m");
	return WIIMOTE_ERROR;
    }

    if (fwrite(data, 1, WIIMOTE_MII_SLOT_SIZE, file) < 0) {
	wiimote_error("wiimote_mii_dump_slot(): fwrite: %m");
	return WIIMOTE_ERROR;
    }

    if (fclose(file) < 0) {
	wiimote_error("wiimote_mii_dump_slot(): fclose: %m");
	return WIIMOTE_ERROR;
    }

    return WIIMOTE_OK;
}

//------------------------------------------------------------------------------
//  Function:   wiimote_mii_slot_state
//  Purpose:    Reads one Mii slot from wiimote and checks if it is empty 
//  Parameters: wiimote, slot number
//  Returns: 1 if slot has data, 0 if not 
//------------------------------------------------------------------------------
int wiimote_mii_slot_state(wiimote_t *wiimote, int slot)
{
    uint8_t data[WIIMOTE_MII_SLOT_SIZE];

    if (wiimote_mii_read(wiimote, data, slot) < 0) {
	wiimote_error("wiimote_mii_slot_state(): wiimote_mii_read");
	return WIIMOTE_ERROR;
    }

    // Check to see if mii has an id.  If yes, then the slot is in use
    if (data[24]) {
	return 1;
    }

    return 0;
}

//------------------------------------------------------------------------------
//  Function:   wiimote_mii_write
//  Purpose:    Writes one Mii slot to wiimote  
//  Parameters: wiimote, mii slot, data area 
//  Returns: 0 if successful, otherwise -1.
//------------------------------------------------------------------------------
int wiimote_mii_write(wiimote_t *wiimote, uint8_t *data, int slot)
{
    uint32_t offset = (slot * WIIMOTE_MII_SLOT_SIZE) + WIIMOTE_MII_DATA_BEGIN_1;

    if (wiimote_write(wiimote, offset, data, WIIMOTE_MII_SLOT_SIZE) < 0) {
	wiimote_error("wiimote_mii_write(): wiimote_write");
	return WIIMOTE_ERROR;
    }

    return WIIMOTE_OK;
}

//------------------------------------------------------------------------------
//  Function:   wiimote_mii_read
//  Purpose:    Reads one Mii slot from wiimote  
//  Parameters: wiimote, mii slot, data area 
//  Returns: 
//------------------------------------------------------------------------------
int wiimote_mii_read(wiimote_t *wiimote, uint8_t *data, int slot)
{
    // The Mii is only 74 bytes long, but we can only read blocks that are
    // multiples of 16.  So make a data block of 80 which is a multiple of 16.
    uint16_t MII_DATA_BLOCK = 80;
    uint8_t buf[MII_DATA_BLOCK];
    uint32_t offset = (slot * WIIMOTE_MII_SLOT_SIZE) + WIIMOTE_MII_DATA_BEGIN_1;

    if (wiimote_read(wiimote, offset, buf, MII_DATA_BLOCK) < 0) {
	wiimote_error("wiimote_mii_read(): wiimote_read");
	return WIIMOTE_ERROR;
    }

    // Copy the first 74 bytes of our data read, discard the rest
    memcpy(data, buf, WIIMOTE_MII_SLOT_SIZE);

    return WIIMOTE_OK;
}
