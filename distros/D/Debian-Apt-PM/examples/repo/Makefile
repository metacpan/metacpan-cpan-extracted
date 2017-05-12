all: repository

repository:
	dpkg-scanpackages unstable /dev/null > unstable/Packages
	dpkg-scansources  unstable /dev/null > unstable/Sources
	
	bzip2 -c9 unstable/Packages > unstable/Packages.bz2
	gzip -c9 unstable/Packages > unstable/Packages.gz
	bzip2 -c9 unstable/Sources  > unstable/Sources.bz2
	gzip -c9 unstable/Sources  > unstable/Sources.gz
	
	dpkg-scanpmpackages
	
	apt-ftparchive -c=Release.conf release unstable > unstable/Release
	-rm unstable/Release.gpg
	gpg -abs -o unstable/Release.gpg unstable/Release

move-new-packages:
	mv *.deb *.udeb *.gz *.bz2 *.changes *.dsc unstable/unsorted/ || /bin/true

clean:
	rm -f unstable/Packages* unstable/Sources* unstable/Release* unstable/PerlPackages*
