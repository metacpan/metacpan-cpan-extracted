REM Generated by Genezzo::Havok version 7.19 on 2007-11-20T00:22:20
REM
REM Copyright (c) 2004-2007 Jeffrey I Cohen.  All rights reserved.
REM
REM 
select HavokUse('Genezzo::Havok') from dual;

REM HAVOK_EXAMPLE
REM select * from tab1 where Genezzo::Havok::Examples::isRedGreen(col1);
REM note that UserExtend usage is deprecated, please use UserFunctions
select HavokUse('Genezzo::Havok::UserExtend') from dual;
i user_extend 1 require Genezzo::Havok::Examples isRedGreen SYSTEM 2007-11-20T00:22:20 0
REM moved soundex to Genezzo::Havok::SQLScalar
REM i user_extend 2 require Text::Soundex soundex SYSTEM 2007-11-20T00:22:20 0



commit
shutdown
startup
