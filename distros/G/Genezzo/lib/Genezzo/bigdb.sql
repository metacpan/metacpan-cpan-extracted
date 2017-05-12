REM Copyright (c) 2004, 2005, 2006 Jeffrey I Cohen.  All rights reserved.
REM
REM 
select * from _pref1 where pref_key='bc_size';
update  _pref1 set pref_value=1000 where pref_key='bc_size';

REM set tablespace to grow and acquire new datafiles
select * from _tspace where tsname='SYSTEM';
update  _tspace set addfile='filesize=10M increase_by=50%' where tsname='SYSTEM';

REM update default tablespace file to grow 
select * from _tsfiles where filename =~ m/default/ ;
update  _tsfiles set increase_by='50%' where filename =~ m/default/ ;
commit
shutdown
startup

