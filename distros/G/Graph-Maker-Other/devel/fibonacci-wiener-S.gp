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

\\ series_reduced=>1
\\        F(-1)=F(0)=single node
\\ A180567 Wiener of Fibonacci tree 0, 0, 4, 18, 96 
\\         T(0)=T(1)=node, left T(k-1) right T(k-2)
\\         is series_reduced=>1

\\ num vertices
NS(k) = 2*F(k+1)-1;
check_equal(NS(4), 9);

DS_recurrence(k) =
{
  if(k==0,0, k==1,0,
  DS_recurrence(k-1) + NS(k-1)     \\ left
  + DS_recurrence(k-2) + NS(k-2)   \\ right
);
}
DS_recurrence=memoize(DS_recurrence);
check_equal(DS_recurrence(0), 0, "DS(0)");
check_equal(DS_recurrence(1), 0, "DS(1)");
check_equal(DS_recurrence(2), 2, "DS(2)");
check_equal(DS_recurrence(4), 1+2+2+3+3 + 1+2+2);
print("DS ",vector(10,k,k--;DS_recurrence(k)));  \\ A178523

recurrence_guess(vector(20,k,k--; DS_recurrence(k)))

gDS(x) =
{
  2/(1 - x)
  + (-4 - 2*x)/(1 - x - x^2)
  + 2/(1 - x - x^2)^2
}

gAlternating(x) = 1/(1+x);
gF(x) = x/(1 - x - x^2);
check_equal(gf_terms(gF(x),100), vector(100,k,k--; fibonacci(k)));

gKtimesF(x) =       (1 - x)/(1 - x - x^2) \
               + (-1 + 3*x)/(1 - x - x^2)^2
check_equal(gf_terms(gKtimesF(x),100), vector(100,k,k--; k*fibonacci(k)));

gKtimesFnext(x) =   -2/(1 - x - x^2) \
  + (2 - x)/(1 - x - x^2)^2;
check_equal(gf_terms(gKtimesFnext(x),100), vector(100,k,k--; k*fibonacci(k+1)));

{
  lindep([gDS(x),
          gKtimesF(x), gKtimesFnext(x),
          gF(x), 1/x*gF(x),
          1/(1-x)          
         ]
         * (1 - x) * (1 - x - x^2)^2
         )
}

DS(k) =
{
 1/5* (
       2*k*F(k)
       + 6*k*F(k+1)
       - 8*F(k)
       - 10*F(k+1)
      )
        + 2
  ;
}
check_equal(vector(10,k,k--; DS(k)), vector(10,k,k--; DS_recurrence(k)), \
           "DS_recurrence()");
DS(k) =
{
 1/5* (
       + (4*k-2)*F(k+1)
       + (2*k-8)*F(k+2)
      )
  + 2;
}
check_equal(vector(10,k,k--; DS(k)), vector(10,k,k--; DS_recurrence(k)), \
           "DS_recurrence()");

WS(k) =
{
  if(k==0,0, k==1,0,
     WP(k-1) + WS(k-2) 
     + DP(k-1)*NS(k-2)  + NP(k-1)*DS(k-2) 
     + NP(k-1)*NS(k-2));
}
WS=memoize(WS);

NP(k) = NS(k)+1;
DP(k) = DS(k)+NS(k);    \\ total root to all others
WP(k) = WS(k) + DP(k);

print("WS ",vector(10,k,k--;WS(k)));  \\ A002940

recurrence_guess(vector(100,k,k--; WS(k)))

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

gFsquared(x) = 
{
  -2/5/(1 + x)
  + (2/5 - 3/5*x)/(1 - 3*x + x^2);
}
check_equal(gf_terms(gFsquared(x),100), vector(100,k,k--; fibonacci(k)^2));

gFtimesFnext(x) = 
{
  -1/5/(1 + x)
  + (1/5 + 1/5*x)/(1 - 3*x + x^2);
}
check_equal(gf_terms(gFtimesFnext(x),100), vector(100,k,k--; fibonacci(k)*fibonacci(k+1)));

gKtimesFtimesFnext(x) = 
{
  1/5/(1 + x)
  - 1/5/(1 + x)^2
  + (-1 - 1/5*x)/(1 - 3*x + x^2)
  + (1 - 2*x)/(1 - 3*x + x^2)^2;
}
check_equal(gf_terms(gKtimesFtimesFnext(x),100), vector(100,k,k--; k*fibonacci(k)*fibonacci(k+1)));

gKtimesAlternating(x) = -x/(1 + x)^2;


gWS(x) =
{
  (4*x^2 - 6*x^3 + 16*x^4 - 12*x^5 - 12*x^6 + 12*x^7 + 4*x^8 - 2*x^9)
  / (1 - 6*x + 7*x^2 + 16*x^3 - 27*x^4 - 18*x^5 + 29*x^6 + 12*x^7 - 9*x^8 - 2*x^9 + x^10);
}

{
  my(e=0);
  lindep([gWS(x),
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
\\ [-5, -4, 16, 36, -66, 2, 6, 12, 30, 36, -4, 0, 0, 0]~

WS_by_F(k) =
{
  1/5 * (
          - 4 * k*F(k)^2
          + 16 * k*F(k+1)^2
          + 36 * F(k)^2 
          - 66 * F(k+1)^2
          + 2 * k*F(k)
          + 6 * k*F(k+1)
          + 12 * F(k)
          + 30 * F(k+1)
          + 36 * (-1)^k
          -  4 * k * (-1)^k
         );
}
check_equal(vector(100,k,k--; WS_by_F(k)), vector(100,k,k--; WS(k)));

WS_by_F(k) =
{
  1/5 * (
         (2*k-66)* (2*F(k+1) + 1) * (2*F(k+1) + F(k+2))

         + 66*(2*F(k+1) + 1) * (2*F(k+1) + F(k+2))
          - 66 * F(k+1)^2
          + 36 * F(k-1)*F(k+1)
          + 12 * F(k)
          + 30 * F(k+1)
         );
}
check_equal(vector(100,k,k--; WS_by_F(k)), vector(100,k,k--; WS(k)));

WS_by_F(k) =
{
  1/5 * (
         (2*k)* (2*F(k+1) + 1) * (2*F(k+1) + F(k+2))

          - 66 * F(k+1)^2
          + 36 * 2*F(k+1)*F(k+1) 
         - 36 * F(k+2)*F(k+1)
          + 12 * F(k)
          + 30 * F(k+1)
         );
}
check_equal(vector(100,k,k--; WS_by_F(k)), vector(100,k,k--; WS(k)));

WS_by_F(k) =
{
  1/5 * (
         (2*k+18)* (2*F(k+1) + 1) * (2*F(k+1) + F(k+2))

          - 18*(2*F(k+1) + 1) * (2*F(k+1) + F(k+2))
          + 6 * F(k+1)^2
         - 36 * F(k+2)*F(k+1)
          + 12 * F(k+2)
          + 18 * F(k+1)
         );
}
check_equal(vector(100,k,k--; WS_by_F(k)), vector(100,k,k--; WS(k)));

WS_by_F(k) =
{
  1/5 * (
         (2*k-18)* (2*F(k+1) + 1) * (2*F(k+1) + F(k+2))
         + 78*F(k+1)^2 + 54*F(k+1) + 30*F(k+2)
         );
}
check_equal(vector(100,k,k--; WS_by_F(k)), vector(100,k,k--; WS(k)));


Diameter(k) = 2*k-3;
MeanDist(k) = WS_by_F(k) / binomial(NS(k),2);

MeanDist_over_Diameter(k) =
{
  MeanDist(k) / Diameter(k);
}
MeanDist_over_Diameter(1000)*1.0

MeanDist_limit_some(k) =
{
  2 * 1/5 * (
          (2*F(k+1) + F(k+2))
         )
   / (2*F(k+1)-2);
}
MeanDist_limit_some(1000)*1.0
MeanDist_over_Diameter(500000)*1.0

quit
print("limit");
MeanDist_limit = 7/5 / phi^4 + 11/5 / phi^3
MeanDist_limit*1.0

check_equal(1/2 + 1/10*sqrt5, MeanDist_limit);
check_equal(1/2 + 1/10*(2*phi-1), MeanDist_limit);
check_equal(1/5*phi + 2/5, MeanDist_limit);
check_equal(1/(5/2-1/2*(2*phi-1)), MeanDist_limit);
check_equal(1/(3-phi), MeanDist_limit);
\\ A242671 1/(3+phi)



quit

