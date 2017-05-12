OH NO! NIGHTMARISH EMBEDDED IF TEST!

?(1==1)
If
ok 8
?(1==0)
	Whoops 1
not ok 8
?else
	This
ok 9
?("A"=~/A/)
		works
ok 10
?("zeeee"=~/bah/)
		Whoops 2
not ok 11
?else
			then I
ok 11
?!$Doubtful
				will be
ok 12
?(1==1)
					Happy!
ok 13
?else
					Whoops 3
?end
?else
				Whoops 4
?end
?else
			Whoops 5
?end
?else
		Whoops 6
?end
?else
	Whoops 7
?end
?else
Whoops 8
?end

The End.


