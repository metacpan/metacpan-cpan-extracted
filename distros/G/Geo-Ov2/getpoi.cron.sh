#!/bin/sh

# Nastaveni promennych
TMPDIR="/tmp/ov2_new"
ZIPFILE="/home/public/ov2.zip"
DATADIR="/home/public/POI/data"
TODEVICEDIR="/home/public/POI/todevice"
export PATH=$PATH:/usr/local/bin:/usr/local/sbin
export PGUSER=postgres

# Stazeni bodu z poi.cz
cd /home/public
/usr/local/bin/getpoi.sh 2> /var/log/getpoi.err > /var/log/getpoi.out

# Rozbaleni bodu
[ -e "$TMPDIR" ] && rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"
cd "$TMPDIR"
unzip "$ZIPFILE"

# Smazani souboru nezmenenych od posledniho stazeni
md5sum "$DATADIR"/*.ov2 | sed "s#$DATADIR##" | LINGUAS=en LANG=en LC_ALL=en LANGUAGE=en md5sum -c | sed -n 's/: OK$//p' | while read i; do
	rm "$i"
done

# Presun souboru do datadiru
mv *.ov2 "$DATADIR"/

# Procisteni cloveho adresare
rm -rf "$TODEVICEDIR"/*

# Slouceni kategorii a vyrvoreni poi.dat
ttn2device "$DATADIR"/ "$TODEVICEDIR"

# Zapakovani ciloveho adresare
zip "$TODEVICEDIR".zip "$TODEVICEDIR"/*
tar cvfz "$TODEVICEDIR".tgz "$TODEVICEDIR"/*

# Import bodu do databaze
[ -e /tmp/getpoi ] && rm -rf /tmp/getpoi
mkdir -p /tmp/getpoi
cd /tmp/getpoi
unzip /home/public/CSV.zip
/usr/local/bin/loadPOIs
rm -rf /tmp/getpoi

# Refresh databaze
/usr/bin/vacuumdb --analyze --full --all
echo -n "Celkovy pocet bodu: "
/usr/bin/psql -A -t -c 'SELECT COUNT(*) FROM poi;' POI
