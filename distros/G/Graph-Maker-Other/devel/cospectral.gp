\\ Copyright 2018 Kevin Ryde
\\
\\ This file is free software; you can redistribute it and/or modify it
\\ under the terms of the GNU General Public License as published by the Free
\\ Software Foundation; either version 3, or (at your option) any later
\\ version.
\\
\\ This file is distributed in the hope that it will be useful, but
\\ WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
\\ or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
\\ for more details.
\\
\\ You should have received a copy of the GNU General Public License along
\\ with this file.  If not, see <http://www.gnu.org/licenses/>.

default(parisizemax,300*10^6);
default(strictargs,1);
default(recover,0);

\\ count>=2
\\ n = 6  7    8     9
\\     2,63,1353,46930
\\
\\ connected count=1
\\ 1, 1, 2, 6, 21, 110, 790, 9764
\\
\\ connected all A001349
\\ 1, 1, 2, 6, 21, 112, 853, 11117, 

\\ A099883 num cospectrals, connected or disconnected
\\    0, 0, 0, 0, 1, 10, 110, 1722, 51039
\\ n= 1  2  3  4  5   6    7     8      9
\\
\\ A099881 num cospectrals pairs, connected or disconnected, not part of triples
\\ 1,5,52,771,21025

\\ n=5 i=23  m=[0, 0, 0, 0, 1; 0, 0, 0, 0, 1; 0, 0, 0, 0, 1; 0, 0, 0, 0, 1; 1, 1, 1, 1, 0]
\\ n=5 i=31  m=[0, 0, 0, 0, 0; 0, 0, 1, 1, 0; 0, 1, 0, 0, 1; 0, 1, 0, 0, 1; 0, 0, 1, 1, 0]

\\ A082104 num distinct charpolys

\\-----------
\\ regular cospectrals, connected or disconnected
\\ n=10  
\\    8, 56, 4428
\\
\\ regular total connected or disconnected
\\ not in OEIS: 1, 1, 3, 2, 7, 5, 21, 25, 175, 545, 19001
\\ not in OEIS:                   21, 25, 175, 545, 19001

\\ regular cospectrals, connected
\\ n=10  
\\    8, 56, 4428
\\
\\ regular total connected
\\ 1, 1, 2, 2, 5, 4, 17, 22, 167, 539, 18979
\\ A005177

vec=readstr("/tmp/x.gp");
seen = Map();
prev_matsize=[];
n=0;

show() =
{
  n || return();
  seen=Mat(seen);
  c=seen[,2];
  my(total=vecsum(c));
  \\ c=select(count->count>1,c);
  c=select(count->count==2,c);
  my(count=vecsum(c));
  print("n="n"  count "count"  out of total="total);
  \\ print1(count", ");
}

{
  for(i=1,#vec,
     my(str=vec[i]);
     \\ print("str="str);
     my(m=Mat(eval(str)));
     \\ print("m="m);
     my(p=charpoly(m));

     if(matsize(m) != prev_matsize,
        show();
        prev_matsize=matsize(m);
        n=prev_matsize[1];
        seen=Map();
        \\ print("now n="n);
       );        

     my(count=0);
     mapisdefined(seen,p,&count);
     count++;
     mapput(seen,p,count);

     if(p==x^5 - 4*x^3,
        print("n="n" i="i"  m="m);

        );


     if(n<=6 && count>=2,
        print(factor(p));
       );
        \\ my(j=mapget(seen,p));
        \\ print("cospectral i="i" and "j);
        \\ print("  "p);
        \\ print("  "factor(p));
        \\ \\ print(">>graph6<<"graph6_list[i]);
        \\ \\ print(">>graph6<<"graph6_list[j]);
        \\ print();

       );
}
show();