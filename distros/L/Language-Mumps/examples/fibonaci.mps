	w "Printing fibonaci series:",!
	s a=1
	s b=0
loop	w a," "
	i a>20 g theend
	s c=a+b s b=a s a=c
	g loop
theend	w !,"Good bye!"