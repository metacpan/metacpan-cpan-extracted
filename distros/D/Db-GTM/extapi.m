extapi	; MUMPS-to-C/PERL external API functions
	; These are very raw functions and they provide unrestricted
	; direct access to every part of the M database.  

get(glvn,exist)		s exist=$d(@glvn) q $g(@glvn,"")
order(glvn,dir)		q $o(@glvn,dir)
query(glvn)		q $q(@glvn)
set(glvn,val)	s @glvn=val q
kill(glvn) 	k @glvn q
killval(glvn)	zwithdraw @glvn q 
copy(gl1,gl2) 	m @gl2=@gl1 q
clobber(gl1,gl2)	n tmp m tmp=@gl1 k @gl2 m @gl2=tmp q
killsub(glvn)	; Kill subscripts of global only 
	n save,d s d=$D(@glvn) 
	if (d=1)!(d=11) s d=1,save=@glvn 
	k @glvn s:d=1 @glvn=save q
txcommit(id)		tstart 
			n i,cmd,p1,p2 
			s i="" f  s i=$O(GTTXNCMD(id,i)) q:i=""  d
			. s cmd=GTTXNCMD(id,i)
			. s p1=GTTXNCMD(id,i,1),p2=GTTXNCMD(id,i,2)
			. i cmd="s" d set(p1,p2)
			. e  i cmd="k" d kill(p1)
			. e  i cmd="kv" d killval(p1)
			. e  i cmd="ks" d killsub(p1)
			. e  i cmd="cp" d copy(p1,p2)
			. e  i cmd="cb" d clobber(p1,p2)
			tcommit  d txclear(id) q
txset(glvn,val,id)	d txaddcmd(id,"s",glvn,val) q
txkill(glvn,id)		d txaddcmd(id,"k",glvn) q
txkval(glvn,id)		d txaddcmd(id,"kv",glvn) q
txksub(glvn,id)		d txaddcmd(id,"ks",glvn) q
txcopy(gl1,gl2,id)	d txaddcmd(id,"cp",gl1,gl2) q
txclob(gl1,gl2,id)	d txaddcmd(id,"cb",gl1,gl2) q
txaddcmd(id,cmd,p1,p2)	n cmdno s cmdno=$O(GTTXNCMD(id,""),-1)+1
			s GTTXNCMD(id,cmdno)=cmd
			s GTTXNCMD(id,cmdno,1)=p1,GTTXNCMD(id,cmdno,2)=$G(p2)
			q
txclear(id)		k GTTXNCMD(id) q
lock(glvn,timeout)	i timeout>-1 lock +@glvn:timeout q $TEST
			e  lock +@glvn q $TEST
unlock(glvn)		lock -@glvn q
