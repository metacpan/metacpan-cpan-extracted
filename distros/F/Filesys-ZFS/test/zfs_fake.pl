#!/usr/bin/perl

my %list = (
test2 => 
qq{test2	type	filesystem	-
test2	creation	Thu Aug 28 17:28 2014	-
test2	used	3.16G	-
test2	available	2.67G	-
test2	referenced	3.16G	-
test2	compressratio	1.00x	-
test2	mounted	yes	-
test2	quota	none	default
test2	reservation	none	default
test2	recordsize	128K	default
test2	mountpoint	/test2	default
test2	sharenfs	off	default
test2	checksum	on	default
test2	compression	off	default
test2	atime	on	default
test2	devices	on	default
test2	exec	on	default
test2	setuid	on	default
test2	readonly	off	default
test2	zoned	off	default
test2	snapdir	hidden	default
test2	aclinherit	restricted	default
test2	canmount	on	default
test2	xattr	on	default
test2	copies	1	default
test2	version	5	-
test2	utf8only	off	-
test2	normalization	none	-
test2	casesensitivity	sensitive	-
test2	vscan	off	default
test2	nbmand	off	default
test2	sharesmb	off	default
test2	refquota	none	default
test2	refreservation	none	default
test2	primarycache	all	default
test2	secondarycache	all	default
test2	usedbysnapshots	0	-
test2	usedbydataset	3.16G	-
test2	usedbychildren	386K	-
test2	usedbyrefreservation	0	-
test2	logbias	latency	default
test2	dedup	off	default
test2	mlslabel	none	default
test2	sync	standard	default
test2	refcompressratio	1.00x	-
test2	written	3.16G	-
test2	logicalused	3.16G	-
test2	logicalreferenced	3.16G	-
test2	snapdev	hidden	default
test2	acltype	off	default
test2	context	none	default
test2	fscontext	none	default
test2	defcontext	none	default
test2	rootcontext	none	default
test2	relatime	off	default
test2	redundant_metadata	all	default
},

test3 =>
qq{test3	type	filesystem	-
test3	creation	Thu Aug 28 17:29 2014	-
test3	used	712M	-
test3	available	5.16G	-
test3	referenced	712M	-
test3	compressratio	1.00x	-
test3	mounted	no	-
test3	quota	none	default
test3	reservation	none	default
test3	recordsize	128K	default
test3	mountpoint	/test3	default
test3	sharenfs	off	default
test3	checksum	on	default
test3	compression	off	default
test3	atime	on	default
test3	devices	on	default
test3	exec	on	default
test3	setuid	on	default
test3	readonly	off	default
test3	zoned	off	default
test3	snapdir	hidden	default
test3	aclinherit	restricted	default
test3	canmount	on	default
test3	xattr	on	default
test3	copies	1	default
test3	version	5	-
test3	utf8only	off	-
test3	normalization	none	-
test3	casesensitivity	sensitive	-
test3	vscan	off	default
test3	nbmand	off	default
test3	sharesmb	off	default
test3	refquota	none	default
test3	refreservation	none	default
test3	primarycache	all	default
test3	secondarycache	all	default
test3	usedbysnapshots	0	-
test3	usedbydataset	712M	-
test3	usedbychildren	176K	-
test3	usedbyrefreservation	0	-
test3	logbias	latency	default
test3	dedup	off	default
test3	mlslabel	none	default
test3	sync	standard	default
test3	refcompressratio	1.00x	-
test3	written	712M	-
test3	logicalused	712M	-
test3	logicalreferenced	712M	-
test3	snapdev	hidden	default
test3	acltype	off	default
test3	context	none	default
test3	fscontext	none	default
test3	defcontext	none	default
test3	rootcontext	none	default
test3	relatime	off	default
test3	redundant_metadata	all	default
},

test4 =>
qq{test4	type	filesystem	-
test4	creation	Thu Aug 28 18:29 2014	-
test4	used	7.81G	-
test4	available	0	-
test4	referenced	7.81G	-
test4	compressratio	1.00x	-
test4	mounted	no	-
test4	quota	none	default
test4	reservation	none	default
test4	recordsize	128K	default
test4	mountpoint	/test4	default
test4	sharenfs	off	default
test4	checksum	on	default
test4	compression	off	default
test4	atime	on	default
test4	devices	on	default
test4	exec	on	default
test4	setuid	on	default
test4	readonly	off	default
test4	zoned	off	default
test4	snapdir	hidden	default
test4	aclinherit	restricted	default
test4	canmount	on	default
test4	xattr	on	default
test4	copies	1	default
test4	version	5	-
test4	utf8only	off	-
test4	normalization	none	-
test4	casesensitivity	sensitive	-
test4	vscan	off	default
test4	nbmand	off	default
test4	sharesmb	off	default
test4	refquota	none	default
test4	refreservation	none	default
test4	primarycache	all	default
test4	secondarycache	all	default
test4	usedbysnapshots	0	-
test4	usedbydataset	7.81G	-
test4	usedbychildren	1020K	-
test4	usedbyrefreservation	0	-
test4	logbias	latency	default
test4	dedup	off	default
test4	mlslabel	none	default
test4	sync	standard	default
test4	refcompressratio	1.00x	-
test4	written	7.81G	-
test4	logicalused	7.81G	-
test4	logicalreferenced	7.81G	-
test4	snapdev	hidden	default
test4	acltype	off	default
test4	context	none	default
test4	fscontext	none	default
test4	defcontext	none	default
test4	rootcontext	none	default
test4	relatime	off	default
test4	redundant_metadata	all	default
},

test =>
qq{test	type	filesystem	-
test	creation	Thu Aug 28 17:26 2014	-
test	used	82K	-
test	available	1.95G	-
test	referenced	25K	-
test	compressratio	1.00x	-
test	mounted	yes	-
test	quota	none	default
test	reservation	none	default
test	recordsize	128K	default
test	mountpoint	/test	default
test	sharenfs	off	default
test	checksum	on	default
test	compression	off	default
test	atime	on	default
test	devices	on	default
test	exec	on	default
test	setuid	on	default
test	readonly	off	default
test	zoned	off	default
test	snapdir	hidden	default
test	aclinherit	restricted	default
test	canmount	on	default
test	xattr	on	default
test	copies	1	default
test	version	5	-
test	utf8only	off	-
test	normalization	none	-
test	casesensitivity	sensitive	-
test	vscan	off	default
test	nbmand	off	default
test	sharesmb	off	default
test	refquota	none	default
test	refreservation	none	default
test	primarycache	all	default
test	secondarycache	all	default
test	usedbysnapshots	0	-
test	usedbydataset	25K	-
test	usedbychildren	57K	-
test	usedbyrefreservation	0	-
test	logbias	latency	default
test	dedup	off	default
test	mlslabel	none	default
test	sync	standard	default
test	refcompressratio	1.00x	-
test	written	25K	-
test	logicalused	31.5K	-
test	logicalreferenced	12.5K	-
test	snapdev	hidden	default
test	acltype	off	default
test	context	none	default
test	fscontext	none	default
test	defcontext	none	default
test	rootcontext	none	default
test	relatime	off	default
test	redundant_metadata	all	default
});

if($ARGV[4] eq 'filesystem'){
print qq{test	83968	2097068032	25600	/test
test2	3391140060	2865878820	3390744780	/test2
test3	746918400	5545324032	746738688	/test3
test4	8389660672	0	8388616192	/test4
};
} else {
	print $list{ $ARGV[3] };
}
