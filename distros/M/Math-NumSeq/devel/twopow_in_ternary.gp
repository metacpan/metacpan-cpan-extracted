\\ Copyright 2015, 2018 Kevin Ryde
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


\\ A260683 number of 2s in ternary of 2^n
\\ A265157 number of 2s in ternary of 2^n-1

vector_any_10(v) = for(i=1,#v-1, if(v[i]==1 && v[i+1]==0, return(i))); 0;

\\ middle
{
  for(n=0,200,
     my(v = digits(2^n,3));
     my(pos = vector_any_10(v));
     my(pstr = if(pos,"10","  "));
     v = apply(d->Str(d),v);
     if(p, v = concat([ v[1..pos], ["---"], v[pos+1..#v]]));
     printf("%60s  %s\n",
            concat(v),
            pstr);
  );
  quit();
}

\\-----------------------------------------------------------------------------

{
  for(n=0,200,
     my(v = digits(2^n,3));
     my(pos = vector_any_10(v));
     my(pstr = if(pos,"10","  "));
     v = apply(d->Str(d),v);
     if(p, v = concat([ v[1..pos], ["---"], v[pos+1..#v]]));
     printf("%60s  %s\n",
            concat(v),
            pstr);
  );
  quit();
}

\\-----------------------------------------------------------------------------

count_2s(n) =
{
  my(v = digits(2^n,3));
  sum(i=1,#v, v[i]==2);
}
digits_below_lowest_2(n) =
{
  my(count=0);
  n = 2^n;
  while((n%3) != 2 && n, n \= 3; count++);
  count;
}
digits_above_highest_2(n) =
{
  my(v = digits(2^n,3));
  for(i=1,#v, if(v[i]==2, return(i-1)));
  -1;
}
any_2(n) =
{
  my(v = digits(2^n,3));
  for(i=1,#v, if(v[i]==2, return(1)));
  0;
}

\\ vector(50,n, lowest_2_pos(n))
{
  print("count 2s");
  my(limit = 1000,
     v = vector(limit,n, count_2s(n)),
     len = length(digits(2^limit,3)));
   print(v[1..10]);
  print("min ",vecmin(v[100..#v])," max ",vecmax(v)," / total " len);
}

print("digits above highest 2");
vector(50,n,n+=10; digits_above_highest_2(n)+1)

print("digits below lowest 2");
vector(50,n,n+=10; digits_below_lowest_2(n)+1)

\\ print("highest pos");
\\ {
\\ for(m=19,19,
\\ print(m);
\\   for(n=0,5000,
\\      my(d = digits_above_highest_2(n));
\\      printf(" %2s", if(d==0,"",d));
\\      if(n%m == 0,print(""))
\\   );
\\    print("");
\\   );
\\ }
\\ print("");
\\ quit();

\\ print("");
\\ v = vector(5000,n, digits_above_highest_2(n));
\\ \\v = vector(5000,n, digits_below_lowest_2(n));
\\ ploth(i=1,#v, v[floor(i)])

\\ select(n->!any_2(n), [1..5000])

length(digits(2^5000,3))

{
  my(hi = 0);
  for(n=1,1000000000,
     my(d = digits_below_lowest_2(n));
     if(d > hi,
        my(len = length(digits(2^n,3)));
        print(d" at n="n" (" len " digits)");
        hi = d;
        );
  );
}

\\ below lowest 2
\\ 1 3 4 7 10 11 13 15 21
\\ at n= 4 6 18 20 24 72 186 332 1134
