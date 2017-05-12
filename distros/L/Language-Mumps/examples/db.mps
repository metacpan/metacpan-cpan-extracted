	w "Hello world",!
	s this=-1
loop	s this=$next(^db(this)) i this=-1 g done
	w this,"=",^db(this),! g loop
done	w "key: " r key 
	w "value: " r value
	s ^db(key)=value
