#!/bin/sh
rsync -r -v --progress --rsh=ssh mailing-lists shlomif@iglu.org.il:/iglu/html/
