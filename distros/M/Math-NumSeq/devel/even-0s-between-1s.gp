\\ Copyright 2020 Kevin Ryde
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


\\ A336231 integers with even num 0-bits between each pair of 1-bits
\\

\\ Code by Michel Marcus in A336231
isok(n) =
{
  my(vpos = select(x->(x==1), binary(n), 1));
  for(i=1, #vpos-1, if((vpos[i+1]-vpos[i]-1) % 2, return(0)));
  return(1);
}

a_by_fibonacci(n) =
{
  my(k=0); while(n>=fibonacci(k+3),k++);
  k--;
  n-=fibonacci(k+3);
  my(ret=1<<k);
  while(k-->=0,
    if(n>=fibonacci(k+1),
      n-=fibonacci(k+1); ret+=1<<k,  /* 1-bit */
      k--));   /* or skip a second place when a 0-bit */
  ret;
}

n_from_an(an) =
{
  if(an==0,1,
     my(hi=if(an,logint(an,2)));
     sum(k=0,hi, bittest(an,k) * fibonacci(k+1 + if(k==hi,2))));
}

\\---------------

\\ vector(30,an,n_from_an(an))
\\ not in OEIS: 2, 3, 4, 5, 6, 6, 7, 8, 9, 9, 10, 10, 11, 11, 12, 13, 14, 14, 15, 15, 16, 16, 17, 16, 17, 17, 18, 18, 19, 19

\\ vector(30,an, sum(k=0,logint(an,2), bittest(an,k) * fibonacci(k+1)))
\\ not in OEIS: 1, 1, 2, 2, 3, 3, 4, 3, 4, 4, 5, 5, 6, 6, 7, 5, 6, 6, 7, 7, 8, 8, 9, 8, 9, 9, 10, 10, 11, 11

\\ vector(30,an, sum(k=0,logint(an,2), bittest(an,k) * fibonacci(k+2)))
{
  my(v=OEIS_samples("A022290"));
  v == vector(#v,n,n--;
              sum(k=0,if(n,logint(n,2)), bittest(n,k) * fibonacci(k+2)))
}

{
  my(v=select(isok,[0..2^16]));
  v == vector(#v,n, a_by_fibonacci(n))  || error();
}
{
  for(n=1,2^14,
     my(an=a_by_fibonacci(n));
     isok(an) || error();
     my(n_again=n_from_an(an));
     n_again == n || error(n));
}
{
  \\ OFFSET=1
  my(g=OEIS_bfile_gf("A336231")); \
  g==x*Polrev(vector(poldegree(g),n,a_by_fibonacci(n))) || error();
}


n_from_an_by_subtract(an) =
{
  if(a==0,1,
     my(hi=if(an,logint(an,2)));
     sum(k=0,hi,
         if(k==hi, fibonacci(k+4)*0,
            -bittest(an,k) * fibonacci(k+2))));
}
vector(20,n, my(an=a_by_fibonacci(n)); n_from_an(an)) -\
vector(20,n, my(an=a_by_fibonacci(n)); n_from_an_by_subtract(an))

print("end");







\\ v=select(isok,[0..128])
\\ for(i=1,#v, printf("%2d %3d  %8d\n", i,v[i],to_binary(v[i])))
\\ vector(#v\2,i,v[2*i+1])
\\ vector(#v\2,i,v[2*i])
\\ 
\\ fibonacci(10)
\\ A336231(n) = \
\\   my(k=0, debug=1); \
\\   while(n>=fibonacci(k),k++); \
\\   if(debug,print("top "k)); \
\\   k--; \
\\   my(ret=1<<(k-3)); \
\\   n -= fibonacci(k); \
\\   k-=2; \
\\   while(k-->0, \
\\     if(debug,print("k="k"  "n" cmp ",fibonacci(k))); \
\\     if(n>=fibonacci(k), \
\\       if(debug,print("bit "k)); \
\\       ret+=1<<(k-1); \
\\       n-= fibonacci(k); \
\\       , \
\\       k--)); \
\\   ret;
\\ 
\\ A336231(n) = \
\\   my(k=1,x=1,y=2,debug=0); \
\\   while(n>=y, [x,y]=[y,x+y];k++); \
\\   if(debug,print("top "k" xy "x" "y)); \
\\   n-=x; [x,y]=[2*x-y,y-x]; k-=2; \
\\   my(ret=1<<k); \
\\   while([x,y]=[y-x,x]; k-->=0, \
\\     if(debug,print("k="k"  "n" cmp x=",x," y="y)); \
\\     if(n>=x, \
\\       if(debug,print("bit "k)); \
\\       n-=x; ret+=1<<k; \
\\       , \
\\       if(debug,print("zero")); \
\\       [x,y]=[y-x,x]; k--;)); \
\\   ret;
\\ 
\\ v=select(isok,[0..2^16]);
\\ vector(#v,n,A336231(n))==v
\\ vector(20,n,n++;to_binary(A336231(n)))
\\ 
\\ to_binary(A336231(43))
\\ A336231(1)
\\ 
\\ A336231(n) = \
\\   my(k=0,x=1,y=1); \
\\   while(n>=x+y, [x,y]=[y,x+y];k++); \
\\   n-=y; [x,y]=[y-x,x]; k--; \
\\   my(ret=1<<k); \
\\   while([x,y]=[y-x,x]; k-- >= 0, \
\\     if(n>=x, n-=x;ret+=1<<k, [x,y]=[y-x,x];k--)); \
\\   ret;
\\ 
\\ my(v=OEIS_samples("A336231")); vector(#v,n, a(n)) == v  \\ OFFSET=1
\\ my(g=OEIS_bfile_gf("A336231")); g==x*Polrev(vector(poldegree(g),n,A336231(n)))
\\ poldegree(OEIS_bfile_gf("A336231"))
\\ ~/OEIS/b336231.txt
\\ 
\\ 
\\ A336231_zero(n) = \
\\   my(k=-1,x=0,y=1); \
\\   while(n>=x+y-1, [x,y]=[y,x+y];k++); \
\\   n-=y; [x,y]=[y-x,x]; k--; \
\\   my(ret=1<<k); \
\\   while([x,y]=[y-x,x]; k-- >= 0, \
\\     if(n+1>=x, n-=x;ret+=1<<k, [x,y]=[y-x,x];k--)); \
\\   ret;
\\ 
\\ vector(10,n,n--; A336231_zero(n))
\\ vector(10,n, A336231(n))
\\ fibonacci(2)
\\ fibonacci(3)
\\ fibonacci(12)
\\ fibbinary_to_n(a) = sum(i=0,if(a,logint(a,2)), fibonacci(i+2));
\\ vector(10,n, fibbinary_to_n(A336231(n)))
\\ A060142  
\\ 
\\ A336231_fibs(n) = \
\\   my(k=0,x=1,y=1,l=List([])); \
\\   while(n>=x+y, [x,y]=[y,x+y];k++); \
\\   n-=y; listput(l,y); [x,y]=[y-x,x]; k--; \
\\   my(ret=1<<k); \
\\   while([x,y]=[y-x,x]; k-- >= 0, \
\\     if(n>=x, n-=x;ret+=1<<k;listput(l,x), [x,y]=[y-x,x];k--)); \
\\   Vec(l);
\\ for(n=1,10, my(a=A336231(n)); printf("%2d %2d %5d  %s\n", n, a,to_binary(a), A336231_fibs(n)));
\\ for(n=30,60, my(a=A336231(n)); printf("%2d %2d %5d  %s\n", n, a,to_binary(a), A336231_fibs(n)));
