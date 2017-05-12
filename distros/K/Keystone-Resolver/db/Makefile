# $Id: Makefile,v 1.8 2008-04-25 16:58:23 mike Exp $

all: build

new: clean build

build: db.ok tables.ok data.ok

db.ok: create_db.mysql
	mysql -u root -p < create_db.mysql
	touch db.ok

tables.ok: create_tables.mysql db.ok
	mysql -u'kr_admin' -p'kr_adm_3636' kr <create_tables.mysql
	touch tables.ok

data.ok: simple.mysql tables.ok
	mysql -u'kr_admin' -p'kr_adm_3636' kr < $<
	touch data.ok

simple.mysql: simple.d2m data2mysql.pl
	rm -f $@
	./data2mysql.pl $< > $@
	chmod 400 $@

simple.oracle: simple.d2m data2mysql.pl
	rm -f $@
	./data2mysql.pl -o $< > $@
	chmod 400 $@

simple.d2m: head.d2m sample.d2m tail.d2m
	rm -f $@
	cat head.d2m sample.d2m tail.d2m > $@
	chmod 400 $@

cufts.d2m: cufts2d2m.pl
	rm -f $@
	./$< ../../archive/samples/data/cufts/CUFTS-indexdata > $@
	chmod 400 $@

clean:
	rm -f tables.ok data.ok simple.mysql simple.d2m cufts.d2m

realclean: clean
	rm -f db.ok

