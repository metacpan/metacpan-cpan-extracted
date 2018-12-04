

numpvs=$(pvs --noheading | wc -l)

if [ $numpvs -gt 0 ]
then
	vgchange -a y
fi

unset numpvs

