#!/bin/sh

if [ `id -u` -ne 0  ]; then
	echo "You will root priviledges for installation"
	exit;
fi

if [ $1 ] && [ $1 = '-u' ] ; then
	rm -rf /etc/OpenEAFDSS /var/spool/eafdss /var/spool/eafdss-db /usr/lib/cups/filter/texteafdss /usr/local/bin/OpenEAFDSS-TypeA.pl
else
	install -o lp -g lp -m 775 -d	/var/spool/eafdss
	install -o lp -g lp -m 775 -d	/var/spool/eafdss-db

	install -o lp -g lp -m 775 -d	/etc/OpenEAFDSS

	install -o lp -g lp -m 774	OpenEAFDSS-TypeA-Filter.pl	/usr/lib/cups/filter/texteafdss
	install -o lp -g lp -m 774	OpenEAFDSS-TypeA.ini		/etc/OpenEAFDSS/OpenEAFDSS-TypeA.ini
	install -o lp -g lp -m 775	OpenEAFDSS-TypeA.pl		/usr/local/bin/OpenEAFDSS-TypeA.pl
fi
