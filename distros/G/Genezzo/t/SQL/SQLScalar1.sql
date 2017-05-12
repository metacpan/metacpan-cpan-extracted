REM test.sql

create table test1 (col1 char, col2 number, col3 char, col4 char);

insert into test1 values ('aa', 1, 'I have trailing spaces       ', 'AAA',
        'bb', 2, '     and many leading spaces too ', 'BBB',
        'cc', 3,  '   and special chars like %^&*()  ' , 'CCC' );

select * from test1;

REM perl functions

select  chomp(col1)||chomp(col3)||col1 from test1;

select  chop(col1)||chop(col3)||col1 from test1;

select  chr(65) from dual;

REM FIX
select  crypt(col3, col1) from test1;

select  index('defabc', 'abc') from dual;
select  index('abc', 'def') from dual;

select  lc(col4) from test1;

select  lcfirst(col4) from test1;

select  length(col1) from test1;

rem reverse of chr
select  ord(col1) from test1;

select quurl( pack('n/A*',col1)) from test1;

select  reverse(col3) from test1;

REM FIX
REM select  rindex(col1) from test1;
select  rindex('defabc', 'abc') from dual;
select  rindex('abc', 'def') from dual;

select  sprintf('number: %d',col2) from test1;

select  substr(col1, 1, 1) from test1;
select  substr(col1, -1) from test1;

select  uc(col3) from test1;

select  ucfirst(col1) from test1;

select  abs(col2) from test1;

REM FIX
select  atan2(2,1) from dual;

select  cos(col2) from test1;

select  exp(col2) from test1;

select  hex(col1) from test1;

REM FIX 
select  int(234.25) from dual;

select  log10(col2) from test1;

REM FIX
select  oct('0xAE') from dual;

REM need to test rand
REM select  rand(col2) from test1;

select  sin(col2) from test1;

select  sqrt(col2) from test1;

select  srand(col2) from test1;

select  perl_join('howdy', col1, col4, col3) from test1;

REM  SQL string functions


select  concat(col1, col2, col3) from test1;

select  greatest(col1, col3) from test1;

select  initcap(col3) from test1;

select initcap('aaaa bbbb aaa bbb aa bb a b') from dual;

select initcap('hi man how are you,dude,kk*ll123gg&ff') from dual;

select initcap('hi man how are you,dude,kk.*()()ll123gg&ff') from dual;

select  least(col1, col3) from test1;

select  lower(col3) from test1;

select  'XX'||lpad(col1, 11, 'zz')||'XX' from test1;
select  'XX'||ltrim(col3)||'XX' from test1;
select  ltrim('abababcdcddceeeeabababcdcddc', 'abcd') from dual;
select  replace(col3, 'a', 'REPLACE') from test1;
select  'XX'||rpad(col1, 11, 'zz')||'XX' from test1;
select  'XX'||rtrim(col3)||'XX' from test1;
select  rtrim('abababcdcddceeeeabababcdcddc', 'abcd') from dual;
select  soundex(col3) from test1;
select  translate(col3, 'abcdefghijklmnopqrstuvwxyz', 
                        '~!@#$%^&*()--+=[]{};:<>012') 
from test1;

select  upper(col1) from test1;

REM SQL math functions

select  cosh(col2) from test1;

select  ceil(col2) from test1;

select  floor(col2) from test1;

select  ln(col2) from test1;
select  logN(10, 100) from dual;
select  mod(22, col2) from test1;
select  power(col2, 10) from test1;
select  round(col2*1.253) from test1;
select  round(col2*1.253, 1) from test1;
select  round(col2*10.253, -1) from test1;
select  sign(col2) from test1;
select  sign(0) from test1;
select  sign(col2*(-5)) from test1;

select  sinh(col2) from test1;

select  tan(col2) from test1;

select  tanh(col2) from test1;

select  trunc(col2*1.243) from test1;
select  trunc(col2*1.243,2) from test1;
select  trunc(col2*11.243, -1) from test1;


REM  SQL conversion functions

select  ascii(col1) from test1;

REM FIX
REM select  instr(col1) from test1;
select  instr('abc', 'defabc') from dual;
select  instr('abc', 'def') from dual;

select  nvl(col1) from test1;


REM  Genezzo functions


select  quurl(col3) from test1;

select  quurl2(col3) from test1;

select  unquurl(col3) from test1;



drop table test1;

commit;
