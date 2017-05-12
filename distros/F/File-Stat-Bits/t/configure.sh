#!/bin/sh

# $1 - compiler


cat > .conftest.c << EOF
#include <sys/sysmacros.h>
int main() { return 0; }
EOF

if $1 .conftest.c 1>/dev/null 2>/dev/null
then sysmacros="-D_HAVE_SYS_SYSMACROS_H"; echo "<sys/sysmacros.h> present" 1>&2
else sysmacros="-U_HAVE_SYS_SYSMACROS_H"; echo "<sys/sysmacros.h> absent"  1>&2
fi

rm -f .conftest* a.out


cat > .conftest.c << EOF
#include <sys/stat.h>
#include <sys/types.h>
#ifdef _HAVE_SYS_SYSMACROS_H
# include <sys/sysmacros.h>
#endif

int main()
{
	int dev = major(0177000) | minor(0377);
	(void)dev;
	return 0;
}
EOF

if $1 .conftest.c $sysmacros 1>/dev/null 2>/dev/null
then majorminor="-D_HAVE_MAJOR_MINOR"; echo "major/minor present" 1>&2
else majorminor="-U_HAVE_MAJOR_MINOR"; echo "major/minor absent"  1>&2
fi

rm -f .conftest* a.out

echo "$sysmacros $majorminor"
