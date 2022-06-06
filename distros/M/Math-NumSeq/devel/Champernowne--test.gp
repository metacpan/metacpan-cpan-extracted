\\ Copyright 2021 Kevin Ryde
\\
\\ This file is part of Math-NumSeq.
\\
\\ Math-NumSeq is free software; you can redistribute it and/or modify
\\ it under the terms of the GNU General Public License as published by the
\\ Free Software Foundation; either version 3, or (at your option) any later
\\ version.
\\
\\ Math-NumSeq is distributed in the hope that it will be useful, but
\\ WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
\\ or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
\\ for more details.
\\
\\ You should have received a copy of the GNU General Public License along
\\ with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

default(recover,0);
default(strictargs,1);
default(parisizemax,1500*10^6);
default(parisize,1500*10^6);
read("OEIS-data.gp");

OEIS_check_verbose = 1;

check_count = 0;
check_equal(got,want,name="") =
{
  check_count++;
  if(got != want,
     print("wrong "name);
     print("got  "got);
     print("want "want);
     quit(1));
  print("ok "check_count" "name);
}

nearly_equal_epsilon = 1e-15;
nearly_equal(x,y, epsilon=nearly_equal_epsilon) = abs(x-y) < epsilon;


\\-----------------------------------------------------------------------------
\\ A350208 steps throgh Champernowne

\\ A033307  OFFSET=0 and 0 as no digits
A033307_Champernowne(limit) = concat(apply(digits,[1..limit]));
{
  my(want=OEIS_data("A033307"),
     got=A033307_Champernowne(#want)[1..#want]);
  check_equal(got,want,
              "A033307_Champernowne() vs DATA");
}

A350208_gap(n) = if(n==0,10,n);

A350208_extract_from(v) =
{
  my(l=List([]),p=1);
  while(p<=#v,
        listput(l,v[p]);
        p += A350208_gap(v[p]));
  Vec(l);
}

histogram(v) =
{
  my(offset=vecmin(v)-1,
     len=vecmax(v) - offset,
     h=vector(len));
  for(i=1,#v, h[v[i]-offset]++); 
  h;
}
check_equal(histogram([5,6,6,7]), [1,2,1]);

{
  my(want=[1, 2, 4, 8, 1, 3, 1, 5, 1, 8, 2, 3, 2, 2, 2, 2, 2, 3, 1, 3, 3, 3, 6, 9, 4, 4, 4, 5, 2, 3, 5, 7, 6, 6, 6, 7, 3, 7, 8, 2, 3, 8, 8, 9, 7, 0, 1, 0, 7, 1, 1, 0, 1, 1, 4, 1, 1, 6, 8, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 1, 1, 4, 3, 4, 1, 4],
     cham=A033307_Champernowne(10*#want),
     got=A350208_extract_from(cham));
  check_equal(got[1..#want],want);
}
{
  for(k=3,6,
     my(cham=A033307_Champernowne(10^k-1),
        got=A350208_extract_from(cham),
        h=histogram(got),
        pos,m=vecmax(h,&pos));
     \\ print(got);
     \\ #Set(hist)==#hist || error();
     print("k="k" len ",#got," cham ",#cham",   max ",m," at "pos"     "h);
);
  quit;
}

\\-----------------------------------------------------------------------------

check_equal(a,'a, "global variable a");
check_equal(b,'b, "global variable b");
check_equal(c,'c, "global variable c");
check_equal(d,'d, "global variable d");
check_equal(f,'f, "global variable f");
check_equal(g,'g, "global variable g");
check_equal(r,'r, "global variable r");
check_equal(s,'s, "global variable s");
check_equal(ot,'ot, "global variable ot");
check_equal(to,'to, "global variable to");
print("end");
