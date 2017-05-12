\\ Copyright 2016 Kevin Ryde
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

allocatemem(200*10^6);
default(strictargs,1);
default(recover,0);
read("memoize.gp");
read("recurrence-guess.gp");

verbose = 1;
test_count = 0;
check_equal_noprint(got,want,name="") =
{
  test_count++;
  \\ print("got  ",got);
  \\ print("want ",got);
  if(got!=want,
     if(name!="",print1(name,": "));
     print("oops\ngot =",got,"\nwant=",want);
     quit(1));
}
check_equal(got,want,name="") =
{
  check_equal_noprint(got,want,name);
  if(verbose,
     if(name=="",print("ok"),print(name,"  ok")));
}

gf_terms(g,n) = \
  my(x = variable(g), \
     zeros = min(n,valuation(g,x)), \
     v = Vec(g + O(x^n))); \
  if(zeros>=0, concat(vector(zeros,i,0), v), \
               v[-zeros+1 .. #v]);

\\-----------------------------------------------------------------------------

\\  connect roots per Iyer and Reddy plain (not "b" binary)
\\ A165910 Wiener of Fibonacci tree 1, 4, 18, 62, 210 
\\         T(-1)=T(0)=node
\\         T(k) by T(k-1) root edge to T(k-2) root
\\         root degree k
\\         children degrees F(0)..F(k-1) so on recursively

\\ ---------
\\ series_reduced=>1
\\        F(-1)=F(0)=single node
\\ A180567 Wiener of Fibonacci tree 0, 0, 4, 18, 96 
\\         T(0)=T(1)=node, left T(k-1) right T(k-2)
\\         is series_reduced=>1
\\
\\ ---------
\\ series_reduced=>1, leaf_reduced=>1
\\   F(0) = empty   F(1) = single node
\\ A192019 Wiener of binary Fibonacci tree
\\         1, 10, 50, 214
\\ A192018 num nodes at distance
\\
\\ W Fibonacci tree = W(k-1) + W(k-2) + F(k+1)*D(k-2) + F(k)*D(k-1) + F(k+1)F(k)
\\
\\ num vertices
NTb(k) = F(k+2)-1;
vector(10,k,k--; NTb(k))
check_equal(NTb(1), 1);
check_equal(NTb(4), 7);

\\ distance root to all others per Iyer and Reddy
DTb(k) = 1/5*(k-3)*F(k+3) + 2/5*(k-2)*F(k+2) + 2;
vector(10,k,k--; DTb(k))  \\ A002940
check_equal(DTb(4), 1+2+2+3+1+2);

WTb(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WP(k-1) + WTb(k-2) 
     + DP(k-1)*NTb(k-2)  + NP(k-1)*DTb(k-2) 
     + NP(k-1)*NTb(k-2));
}
WTb=memoize(WTb);

\\ with extra root vertex
\\
\\             root
\\            /    \
\\         T(k-1)  T(k-2)
\\
NP(k) = NTb(k)+1;
DP(k) = DTb(k)+NTb(k);    \\ total root to all others
check_equal(DP(4), 2+3+3+4+2+3 + 1);
check_equal(DP(3), 1+2+3+2);
WP(k) = WTb(k) + DP(k);
check_equal(WP(1), 1);
check_equal(WP(3), 1+2+3+3 + 1+2+2 + 1+2 + 1);

print("WTb ",vector(10,k,k--;WTb(k)));  \\ A002940
check_equal(WTb(3), 1+2+3+1+2+1);
check_equal(WTb(4), 50);
\\
\\ k=4; WTb(k)
\\ WP(k-1)
\\ WTb(k-2)
\\ DP(k-1)*DTb(k-2)    \\ left reach root
\\  NP(k-1)*DTb(k-2)    \\ paths into right
\\  DTb(k-2)
\\ NP(k-1)*NTb(k-2)     \\ across new edge
\\  NP(k-1)
\\  NTb(k-2)
\\ DP(3) ==3+2+2+1
\\  
\\ 1+2+3+3+4+5 + 1+2+2+3+4 + 1+1+2+3 + 2+3+4 + 1+2 + 1 == 50
\\ 18 + 1 + 8 + 5 + 10
\\ 18+1 + 4+5 + 3+4 + 3+4 + 2+3 + 1+2
\\ 18+1 + (3+2+2+1+0)*2+5*(1+2) 
\\ k=3; WTb(k)
\\ k=3; WP(k-1) + WTb(k-2)
\\ DP(k-1)              \\ left reach root
\\  NP(k-1)*DTb(k-2)    \\ paths into right
\\ NP(k-1)*NTb(k-2)     \\ across new edge
\\ 1+2+3+1+2+1
\\ 4 + 3 + 3
\\

sqrt5=quadgen(20);
check_equal(sqrt5^2, 5);
phi=(1+sqrt5)/2;
check_equal((2*phi-1)^2, 5);
phi
1/phi

w=sqrt5;
{
g = 
  \\ + (111/20 - 247/100*w) /(1 - (3/2 - 1/2*w)*x)
  \\ + (-111/20 - 247/100*w)/(1 - (3/2 + 1/2*w)*x)
  \\ + (-11/10 + 1/2*w)     /(1 - (3/2 - 1/2*w)*x)^2
  \\ + (11/10 + 1/2*w)      /(1 - (3/2 + 1/2*w)*x)^2
  + 1 /(1 - (3/2 - 1/2*w)*x)
  + 1 /(1 - (3/2 + 1/2*w)*x)
}
gf_terms(g,10)

gFsquared(x) = 
{
  -2/5 / (1 + x)
  + 1/5 /(1 - (3/2 - 1/2*w)*x)
  + 1/5 /(1 - (3/2 + 1/2*w)*x);
}
check_equal(gf_terms(gFsquared(x),100), vector(100,k,k--; fibonacci(k)^2));
gFsquared(x) = 
{
  -2/5/(1 + x)
  + (2/5 - 3/5*x)/(1 - 3*x + x^2);
}
check_equal(gf_terms(gFsquared(x),100), vector(100,k,k--; fibonacci(k)^2));

gFtimesFnext(x) = 
{
  -1/5/(1 + x)
  + (1/10 - 1/10*w)/(1 - (3/2 - 1/2*w)*x)
  + (1/10 + 1/10*w)/(1 - (3/2 + 1/2*w)*x);
}
check_equal(gf_terms(gFtimesFnext(x),100), vector(100,k,k--; fibonacci(k)*fibonacci(k+1)));
gFtimesFnext(x) = 
{
  -1/5/(1 + x)
  + (1/5 + 1/5*x)/(1 - 3*x + x^2);
}
check_equal(gf_terms(gFtimesFnext(x),100), vector(100,k,k--; fibonacci(k)*fibonacci(k+1)));

gKtimesFsquared(x) = 
{
  2/5/(1 + x)
  - 2/5 /(1 + x)^2
  - 1/5 /(1 - (3/2 - 1/2*w)*x)
  - 1/5 /(1 - (3/2 + 1/2*w)*x)
  + 1/5 /(1 - (3/2 - 1/2*w)*x)^2
  + 1/5 /(1 - (3/2 + 1/2*w)*x)^2;
}
check_equal(gf_terms(gKtimesFsquared(x),100), vector(100,k,k--; k*fibonacci(k)^2));
gKtimesFsquared(x) = 
{
  2/5/(1 + x)
  - 2/5/(1 + x)^2
  + (1 + 3/5*x)/(1 - 3*x + x^2)
  + (-1 + 3*x)/(1 - 3*x + x^2)^2;
}
check_equal(gf_terms(gKtimesFsquared(x),100), vector(100,k,k--; k*fibonacci(k)^2));

gKtimesFsquaredPlus1(x) = 
{
  -2/5/(1 + x)
  + 2/5/(1 + x)^2
  + 2/5*x/(1 - 3*x + x^2)
  + x/(1 - 3*x + x^2)^2
}
check_equal(gf_terms(gKtimesFsquaredPlus1(x),100), vector(100,k,k--; k*fibonacci(k+1)^2));

gKtimesFtimesFnext(x) = 
{
  1/5/(1 + x)
  - 1/5/(1 + x)^2
  + (-1 - 1/5*x)/(1 - 3*x + x^2)
  + (1 - 2*x)/(1 - 3*x + x^2)^2;
}
check_equal(gf_terms(gKtimesFtimesFnext(x),100), vector(100,k,k--; k*fibonacci(k)*fibonacci(k+1)));

gF(x) = x/(1 - x - x^2);
check_equal(gf_terms(gF(x),100), vector(100,k,k--; fibonacci(k)));

gKtimesF(x) =       (1 - x)/(1 - x - x^2) \
               + (-1 + 3*x)/(1 - x - x^2)^2
check_equal(gf_terms(gKtimesF(x),100), vector(100,k,k--; k*fibonacci(k)));

gKtimesFnext(x) =   -2/(1 - x - x^2) \
  + (2 - x)/(1 - x - x^2)^2;
check_equal(gf_terms(gKtimesFnext(x),100), vector(100,k,k--; k*fibonacci(k+1)));

gKtimesFprev(x) =   (-3 + x)/(1 - x - x^2) \
                  + (3 - 4*x)/(1 - x - x^2)^2
check_equal(gf_terms(gKtimesFprev(x),100), vector(100,k,k--; k*fibonacci(k-1)));


\\-----------------------------------------------------------------------------

gWTb(x) = 
{
  16/25/(1 + x)
  - 1/5/(1 + x)^2

  + (1/2 - 11/50*w)  /(1 - (3/2 - 1/2*w)*x)^2
  + (1/2 + 11/50*w)  /(1 - (3/2 + 1/2*w)*x)^2

  + (-247/100 - 111/100*w) /(1 - (3/2 + 1/2*w)*x) 
  + (-247/100 + 111/100*w) /(1 - (3/2 - 1/2*w)*x)

  + (27/20 + 77/100*w) /(1 - (1/2 + 1/2*w)*x)
  + (27/20 - 77/100*w) /(1 - (1/2 - 1/2*w)*x)

  + (2/5 + 1/5*w) /(1 - (1/2 + 1/2*w)*x)^2 
  + (2/5 - 1/5*w) /(1 - (1/2 - 1/2*w)*x)^2;
}
check_equal(gf_terms(gWTb(x),100), vector(100,k,k--; WTb(k)));
gWTb(x) = 
{
  16/25/(1 + x)
  - 1/5/(1 + x)^2
  + (-237/50 + 93/50*x)/(1 - 3*x + x^2)
  + (4/5 - 1/5*x)/(1 - 3*x + x^2)^2
  + (5/2 + 5/2*x)/(1 - x - x^2)
  + (1 + x)/(1 - x - x^2)^2;
}
check_equal(gf_terms(gWTb(x),100), vector(100,k,k--; WTb(k)));

matsolve(mattranspose([-1,3; 1,-2]), [4/5; -1/5])
matsolve(mattranspose([2/5,-3/5; 1/5,1/5]), [-197/50; 73/50])
matsolve(mattranspose([-1,3; 3,-4]), [1;1])

{ recurrence_guess(gf_terms(gWTb(x)
                            - 7/5*gKtimesFsquared(x) - 11/5*gKtimesFtimesFnext(x)
                            - (-27/5) * gFsquared(x) - (-89/10) * gFtimesFnext(x)
                            - 7/5 * gKtimesF(x) - 4/5 * gKtimesFprev(x)
                            - 31/10*gF(x) - 7/2*1/x*gF(x)
                            ,100)
);
}
{
pol_ascending_print(
pol_partial_fractions(gWTb(x)
                      - 7/5*gKtimesFsquared(x) - 11/5*gKtimesFtimesFnext(x)
                      - (-27/5) * gFsquared(x) - (-89/10) * gFtimesFnext(x)
                      - 7/5 * gKtimesF(x) - 4/5 * gKtimesFprev(x)
\\ \\                      - 7/2*gF(x)
));
}

{
  check_equal(gWTb(x),
              7/5*gKtimesFsquared(x) + 11/5*gKtimesFtimesFnext(x)
              + (-27/5) * gFsquared(x) + (-89/10) * gFtimesFnext(x)
              + 7/5 * gKtimesF(x) + 4/5 * gKtimesFprev(x)
              + 31/10*gF(x) + 7/2*1/x*gF(x)
              - 43/10/(1 + x)
              + 4/5/(1 + x)^2
);
}

WTb_by_F(k) =
{
  7/5*k*F(k)^2 + 11/5*k*F(k)*F(k+1)
  - 27/5 * F(k)^2 
  - 89/10 * F(k)*F(k+1)
  + 7/5 * k*F(k)
  + 4/5 * k*F(k-1)
  + 31/10*F(k)
  + 7/2*F(k+1)
  - 43/10 * (-1)^k
  + 4/5 * (k+1) * (-1)^k
  ;
}
check_equal(vector(100,k,k--; WTb_by_F(k)), vector(100,k,k--; WTb(k)));

WTb_by_F(k) =
{
  1/10 * (
          14 * k*F(k)^2
          + 22 * k*F(k)*F(k+1)
          - 54 * F(k)^2 
          - 89 * F(k)*F(k+1)
          + 6 * k*F(k)
          + 8 * k*F(k+1)
          + 31 * F(k)
          + 35 * F(k+1)
          + 8 * k * (-1)^k
          - 35 * (-1)^k
         );
}
check_equal(vector(100,k,k--; WTb_by_F(k)), vector(100,k,k--; WTb(k)));

\\ 7,11 -> 4,7 -> 3,4 -> 1,3 -> 2,1   Lucas
\\ 54,89 -> 35,54 -> 19,35 -> 16,19 -> 3,16 -> 13,3
\\ 3,4 -> 1,3 -> 2,1  Lucas numbers
\\ 31,35 -> 4,31 -> 27,4 -> 

\\ Colin Barker in A192019
{
  check_equal(gWTb(x), x^2 * (x^4 - 3*x^2 + 4*x + 1)
              / ( (x+1)^2 * (x^2-3*x+1)^2 * (x^2+x-1)^2 ));
}


WTb_expanded(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2) 
     + DTb(k-1)
     + NTb(k-1)
     + DP(k-1) * NTb(k-2)
     + NP(k-1) * DTb(k-2) 
     + NP(k-1) * NTb(k-2));
}
check_equal(vector(100,k,k--; WTb_expanded(k)), vector(100,k,k--; WTb(k)));

WTb_expanded(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2) 
     + DTb(k-1)
     + NTb(k-1)
     + (DTb(k-1)+NTb(k-1)) * NTb(k-2)
     + (NTb(k-1)+1) * DTb(k-2) 
     + (NTb(k-1)+1) * NTb(k-2));
}
check_equal(vector(100,k,k--; WTb_expanded(k)), vector(100,k,k--; WTb(k)));

WTb_expanded(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2) 
     + DTb(k-1)
     + NTb(k-1)
     + DTb(k-1) * NTb(k-2)
     + F(k+1) * DTb(k-2) 
     + NTb(k-1) * NTb(k-2)
     + F(k+1) * (F(k) - 1));
}
check_equal(vector(100,k,k--; WTb_expanded(k)), vector(100,k,k--; WTb(k)));

WTb_expanded(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2) 
     + NTb(k-1)
     + DTb(k-1) * F(k)
     + F(k+1) * DTb(k-2) 
     + (F(k+1)-1) * (F(k) - 1)
     +  F(k+1)    * (F(k) - 1));
}
check_equal(vector(100,k,k--; WTb_expanded(k)), vector(100,k,k--; WTb(k)));

WTb_expanded(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2)     + F(k+1) * DTb(k-2) 
     + F(k) * DTb(k-1)
     + F(k+1) * F(k)-1 * F(k)
     +  ( F(k+1)    *F(k) -  F(k+1)    *1)
    );
}
check_equal(vector(100,k,k--; WTb_expanded(k)), vector(100,k,k--; WTb(k)));

WTb_expanded(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2)     + F(k+1) * DTb(k-2) 
     + F(k) * DTb(k-1)
     + F(k+1)*(F(k) - 1)

     + F(k+1)*F(k) - F(k)
    );
}
check_equal(vector(100,k,k--; WTb_expanded(k)), vector(100,k,k--; WTb(k)));

WTb_expanded(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2)     + F(k+1) * DTb(k-2) 
     + (F(k)-1) * DTb(k-1)
     + F(k+1)*(F(k) - 1)

     + F(k+1)*F(k) - F(k) + DTb(k-1)
    );
}
check_equal(vector(100,k,k--; WTb_expanded(k)), vector(100,k,k--; WTb(k)));

matsolve(mattranspose([-1,3; 3,-4]), [0; 1])

gDTb_diff(x) = 
{
  -x/(1 - x - x^2)
  + x/(1 - x - x^2)^2;
}
{
pol_ascending_print(
pol_partial_fractions(gDTb_diff(x)
                      - 3/5*gKtimesF(x) - 1/5*gKtimesFprev(x)
                      + 3/5*gF(x)
));
}
{
  check_equal(3/5*gKtimesF(x) + 1/5*gKtimesFprev(x) - 3/5*gF(x),
              gDTb_diff(x));
}

check_equal(vector(100,k,k--; 1/5*( 3*k*F(k) + k*F(k-1) - 3*F(k) )), \
            vector(100,k,k--; DTb(k)-DTb(k-1)));

check_equal(vector(100,k,k--; 1/5*( k*(F(k+1) + 2*F(k)) - 3*F(k) )), \
            vector(100,k,k--; DTb(k)-DTb(k-1)));

\\ Lucas numbers k*L() ...
check_equal(vector(100,k,k--; 1/5*( k*(2*F(k+2)-F(k+1)) - 3*F(k) )), \
            vector(100,k,k--; DTb(k)-DTb(k-1)));

\\ recurrence_guess(vector(20,k,k--; DTb(k)-DTb(k-1)))
\\ vector(20,k,k--; 1/5*k*F(k) + 3/5*k*F(k-1) - 3/5*F(k))
\\ vector(20,k,k--; F(k+1)*F(k) - F(k) + DTb(k-1))

WTb_simplified(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2)
     + F(k+1) * DTb(k-2) 
     + F(k)   * DTb(k-1)

     + 2*F(k+1)*F(k) - F(k+2)
    );
}
check_equal(vector(100,k,k--; WTb_simplified(k)), vector(100,k,k--; WTb(k)));

WTb_simplified(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2)
     + F(k+1) * DTb(k-2) 
     + F(k)   * DTb(k-1)

     + 2*F(k)*F(k)+ 2*F(k-1)*F(k) - F(k+2)
    );
}
check_equal(vector(100,k,k--; WTb_simplified(k)), vector(100,k,k--; WTb(k)));

WTb_simplified(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2)
     + F(k+1) * DTb(k-2) 
     + F(k)   * DTb(k-1)

     + 2*F(k+1)*F(k) - F(k+1) - F(k)
    );
}
check_equal(vector(100,k,k--; WTb_simplified(k)), vector(100,k,k--; WTb(k)));

WTb_simplified(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2)
     + F(k+1) * DTb(k-2) 
     + F(k)   * DTb(k-1)

     + 2*( F(k+1)*F(k) - 1/2*F(k+1) - 1/2*F(k) + 1/4 ) -1/2
    );
}
check_equal(vector(100,k,k--; WTb_simplified(k)), vector(100,k,k--; WTb(k)));

WTb_simplified(k) =
{
  if(k==0,0, k==1,0, k==2,1, 
     WTb(k-1) + WTb(k-2)
     + F(k+1) * DTb(k-2) 
     + F(k)   * DTb(k-1)

     + (2*F(k+1)-1)*(F(k)-1/2) - 1/2
    );
}
check_equal(vector(100,k,k--; WTb_simplified(k)), vector(100,k,k--; WTb(k)));

WTb_by_IR(k) =
{
  if(k==0,0, k==1,0, k==2,1,
     WTb(k-1) + WTb(k-2)
     + F(k+1) * DTb(k-2)
     + (F(k)-1) * DTb(k-1) 
     + F(k+1) * (F(k) - 1));
}
\\ check_equal(vector(10,k,k--; WTb_by_IR(k)), vector(10,k,k--; WTb(k)));

WTb_IR_diff(k) =
{
  (   2*F(k+1)*F(k) - F(k+1) - F(k) )
  - (  -1 * DTb(k-1)   + F(k+1) * (F(k) - 1)  );
}
check_equal(vector(10,k,k+=2; WTb_IR_diff(k)), vector(10,k,k+=2; WTb(k)-WTb_by_IR(k)))

WTb_IR_diff(k) =
{
  2*F(k+1)*F(k)
  - F(k+1)
  - F(k)
  + 1/5*(k-4)*F(k+2)
  + 2/5*(k-3)*F(k+1)
  + 2
  - F(k+1) * F(k) + F(k+1)
  ;
}
check_equal(vector(10,k,k+=2; WTb_IR_diff(k)), vector(10,k,k+=2; WTb(k)-WTb_by_IR(k)))

\\ has a term in k
WTb_IR_diff(k) =
{
  F(k+1)*F(k)
  - F(k)
  - 1/5*F(k+2)
  + 1/5*(k-3)*F(k+2)
  + 2/5*(k-3)*F(k+1)
  + 2
  ;
}
check_equal(vector(10,k,k+=2; WTb_IR_diff(k)), vector(10,k,k+=2; WTb(k)-WTb_by_IR(k)))


WTb_by_F(k) =
{
  1/10 * (
          k* ( 14*F(k-1)*F(k+1) + 22*F(k)*F(k+1)
              - 14 * (-1)^k 
              - 14 * (-1)^k    + 22 * (-1)^k
              + 6 * F(k)
              + 8 * F(k+1)
             )
          - 54 * F(k)^2 
          - 89 * F(k)*F(k+1)
          + 31 * F(k)
          + 35 * F(k+1)
          - 35 * (-1)^k
         );
}
check_equal(vector(100,k,k--; WTb_by_F(k)), vector(100,k,k--; WTb(k)));

WTb_by_F(k) =
{
  1/10 * (
          14 * k*F(k)^2
          + 22 * k*F(k)*F(k+1)
          - 54 * F(k)^2 
          - 89 * F(k)*F(k+1)
          + 6 * k*F(k)
          + 8 * k*F(k+1)
          + 31 * F(k)
          + 35 * F(k+1)
          + 8 * k * (-1)^k
          - 35 * (-1)^k
         );
}
check_equal(vector(100,k,k--; WTb_by_F(k)), vector(100,k,k--; WTb(k)));

gAlternating(x) = 1/(1+x);
gKtimesAlternating(x) = -x/(1 + x)^2;
{
  lindep([gWTb(x),
          gKtimesFsquared(x),
          gKtimesFtimesFnext(x),
          gFsquared(x),
          gFtimesFnext(x),
          gKtimesF(x),
          gKtimesFprev(x),
          gF(x),
          1/x*gF(x),
          gAlternating(x),
          gKtimesAlternating(x)
         ]
         * ( (x+1)^2 * (x^2-3*x+1)^2 * (x^2+x-1)^2 ))
}
{
  my(e=2);
  lindep([gWTb(x),
          1/x^e*gKtimesFsquared(x),
          1/x^e*gKtimesFsquaredPlus1(x),
          1/x^(e+0)*gFsquared(x),
          1/x^(e+1)*gFsquared(x),

          1/x^(e+0)*gKtimesF(x),
          1/x^(e+0)*gKtimesFnext(x),
          1/x^(e+0)*gF(x),
          1/x^(e+1)*gF(x),

          1/x^e*gAlternating(x),
          1/x^e*gKtimesAlternating(x),
          1/x^(e+1)*gAlternating(x),
          1/x^(e+1)*gKtimesAlternating(x),
          1/(1-x)
         ]
         * ( (x+1)^2 * (x^2-3*x+1)^2 * (x^2+x-1)^2 )
         * (1-x))
}
\\ [-10, 2, 2, 9, -20, 4, 2, 19, 0, 20, -2, 0, 0, 0]

WTb_by_F(k) =
{
  1/10 * (
          (2*k+13) * (F(k+2) + 1)*(F(k+2) + F(k+4))
          
          - 29*F(k+2)*F(k+4)
          + 10*F(k+2)
          - 9*F(k+4)
         );
}
check_equal(vector(100,k,k--; WTb_by_F(k)), vector(100,k,k--; WTb(k)));

WTb_by_F(k) =
{
  1/10 * (
          (2*k+13) * (F(k+2) + 1)*(F(k+2) + F(k+4))
          
          + F(k+2)*(10 - 29*F(k+4)) 
          - 9*F(k+4)
         );
}
check_equal(vector(100,k,k--; WTb_by_F(k)), vector(100,k,k--; WTb(k)));

WTb_by_F(k) =
{
  1/10 * (
          (2*k-16) * (F(k+2) + 1)*(F(k+2) + F(k+4))
          
          + F(k+2)*(29*F(k+2) + 39) + 20*F(k+4)
         );
}
check_equal(vector(100,k,k--; WTb_by_F(k)), vector(100,k,k--; WTb(k)));

WTb_by_F(k) =
{
  1/10 * (
          (2*k-3) * (F(k+2) + 1)*(F(k+2) + F(k+4))

          + 16*F(k+2)*F(k+2)
          - 13*F(k+2)*F(k+4)
          + 26*F(k+2)
          + 7*F(k+4)
         );
}
check_equal(vector(100,k,k--; WTb_by_F(k)), vector(100,k,k--; WTb(k)));



MeanDist(k) = WTb(k) / binomial(NTb(k),2);

MeanDist_simplified(k) =
{
  1/5 * (
          14 * k*F(k)^2
          + 22 * k*F(k)*F(k+1)
          - 54 * F(k)^2 
          - 89 * F(k)*F(k+1)
          + 6 * k*F(k)
          + 8 * k*F(k+1)
          + 31 * F(k)
          + 35 * F(k+1)
          + 8 * k * (-1)^k
          - 35 * (-1)^k
         )
  / (F(k+2)-1) / (F(k+2) - 2);
}
check_equal(vector(100,k,k+=2; MeanDist_simplified(k)), vector(100,k,k+=2; MeanDist(k)));

MeanDist_over_Diameter_inexact(k) =
{
          7/5 / phi^2 / phi^2
          + 11/5 / phi^(3)
  ;
}

Diameter(k) = if(k<2,0, 2*k-3);
MeanDist_over_Diameter(k) =
{
  MeanDist_simplified(k) / Diameter(k);
}
MeanDist_over_Diameter(1000)*1.0
MeanDist_over_Diameter_inexact(1000)*1.0

\\ A023610 DTb diff
\\ A002940 DTb
\\ A192018 num nodes

print("limit");
MeanDist_limit = 7/5 / phi^4 + 11/5 / phi^3
check_equal(1/2 + 1/10*sqrt5, MeanDist_limit);
check_equal(1/2 + 1/10*(2*phi-1), MeanDist_limit);
check_equal(1/5*phi + 2/5, MeanDist_limit);
check_equal(1/(5/2-1/2*(2*phi-1)), MeanDist_limit);
check_equal(1/(3-phi), MeanDist_limit);
\\ A242671 1/(3+phi)

MeanDist_limit*1.0
MeanDist_over_Diameter(5000000)*1.0


quit

