/* --8<--8<--8<--8<--
 *
 * Copyright (C) 2000-2009 Smithsonian Astrophysical Observatory
 *
 * This file is part of IPC-XPA
 *
 * IPC-XPA is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * -->8-->8-->8-->8-- */

char*	hash2str( HV* hash );
HV*	cdata2hash_Get( char *buf, int len, char *name, char *message );
HV *	cdata2hash_Set( char *name, char *message );
HV *	cdata2hash_Lookup( char *class, char *name, char *method, char
			   *info );
