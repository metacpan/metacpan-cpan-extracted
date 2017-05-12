/*
 * Copyright (C) 2002 Uwe Ohse, uwe@ohse.de
 * This is free software, licensed under the terms of the GNU General 
 * Public License Version 2, of which a copy is stored at:
 *    http://www.ohse.de/uwe/licenses/GPL-2
 * Later versions may or may not apply, see 
 *    http://www.ohse.de/uwe/licenses/
 * for information after a newer version has been published.
 */
#include "utcdate2tai.h"

/* utc_mktime ... */
void 
utcdate2tai (struct tai *t, long year, unsigned short mon, unsigned short day,
  unsigned short hour, unsigned short min, unsigned long sec)
{
  int days;
  unsigned long ret;
  int schalt;
  static long days_to_month[] =
  {0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365};

  ret = 3600 * hour + 60 * min + sec;

  if (year % 4)
    schalt = 0;
  else if (year % 400 == 0)
    schalt = 1;
  else if (year % 100 != 0)
    schalt = 1;
  else
    schalt = 0;
  days = (year - 1970) * 365;
  days += ((year - 1969) / 4);
  days -= ((year - 2000) / 100);
  days += ((year - 2000) / 400);
  days += days_to_month[mon];
  days += day-1;
  if (schalt && mon > 1)
    days++;
  ret += 86400 * days;
  tai_unix(t,ret);
}
