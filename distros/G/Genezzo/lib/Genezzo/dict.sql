REM  $Header: /Users/claude/fuzz/lib/Genezzo/RCS/dict.sql,v 1.15 2007/11/20 08:30:45 claude Exp claude $
REM
REM $Revision: 1.15 $
REM
REM copyright (c) 2005-2007 Jeffrey I Cohen, all rights reserved, worldwide
REM
REM dict.sql - additional dictionary objects
REM 
REM   Contains recursive SQL to construct additional dictionary objects in 
REM   "phase three" during database creation.
REM
REM   Note: end all commands 
REM   (even Feeble commands (with the exception of _REMarks_)) 
REM   with semicolon
REM

REM ct dict_test_1 a=c b=c     ;
REM i  dict_test_1 a 1 b 2 c 3 ;

alter table _tspace add constraint tspace_tsname_uk unique (tsname);

create table dual (dummy varchar(1));
insert into dual values ('X');

REM load initial havok modules
select HavokUse('Genezzo::Havok') from dual;
select HavokUse('Genezzo::Havok::UserFunctions') from dual;
select HavokUse('Genezzo::Havok::Utils') from dual;

REM reload the userfunctions to load the new utils functions
select HavokUse('Genezzo::Havok::UserFunctions', 'reload') from dual;

REM load the help system
select HavokUse('Genezzo::Havok::SysHelp') from dual;

REM load sql scalar functions and comparison functions
select HavokUse('Genezzo::Havok::SQLScalar') from dual;
select HavokUse('Genezzo::Havok::SQLCompare') from dual;

REM load the space management hooks
select HavokUse('Genezzo::SpaceMan::SMHook') from dual;

REM always commit changes!!
commit ;
