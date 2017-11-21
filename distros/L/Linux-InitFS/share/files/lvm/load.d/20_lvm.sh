

numpvs=$(pvs --noheading 2>/dev/null | wc -l)

if [[ $numpvs -gt 0 ]]
then
	vgchange -a y 2>/dev/null
fi

unset numpvs

