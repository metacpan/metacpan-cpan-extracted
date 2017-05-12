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
Nfull_by_sum(k) = sum(i=1,k, F(i+1));
check_equal(Nfull_by_sum(1), 1);
check_equal(Nfull_by_sum(2), 3, "Nfull_by_sum(2)");
check_equal(Nfull_by_sum(3), 6);
check_equal(Nfull_by_sum(4), 11);

Nfull(k) = F(k+3)-2;
check_equal(vector(100,k,k--; Nfull(k)), vector(100,k,k--; Nfull_by_sum(k)));

Dfull_recurrence(k) =
{
  if(k==0,0, k==1,0,
     Dfull_recurrence(k-1) + Nfull(k-1)     \\ left
     + Dfull_recurrence(k-2) + 2*Nfull(k-2)   \\ right
     + 1);
}
Dfull_recurrence=memoize(Dfull_recurrence);
check_equal(Dfull_recurrence(0), 0, "Dfull(0)");
check_equal(Dfull_recurrence(1), 0, "Dfull(1)");
check_equal(Dfull_recurrence(2), 2, "Dfull(2)");
check_equal(Dfull_recurrence(3), 1+2+2 + 1+2, "Dfull(3)");
check_equal(Dfull_recurrence(4), 1+2+3+3+2+3 + 1+2+3+3);
print("Dfull ",vector(10,k,k--;Dfull_recurrence(k)));  \\ A178523

recurrence_guess(vector(20,k,k--; Dfull_recurrence(k)))

gDfull(x) =
{
  5/(1 - x)
  + (-8 - 4*x)/(1 - x - x^2)
  + (3 + x)/(1 - x - x^2)^2
  ;
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
  lindep([gDfull(x),
          gKtimesF(x), gKtimesFnext(x),
          gF(x), 1/x*gF(x),
          1/(1-x)          
         ]
         * (1 - x) * (1 - x - x^2)^2
         )
}
\\ [-1, 1, 2, -3, -5, 5]~

Dfull(k) =
{
  +   k*F(k)
  + 2*k*F(k+1)
  - 3*F(k)
  - 5*F(k+1)
  + 5
  ;
}
check_equal(vector(10,k,k--; Dfull(k)), vector(10,k,k--; Dfull_recurrence(k)), \
           "Dfull_recurrence()");
Dfull(k) =
{
  +   k*F(k)
  + 2*k*F(k+1)
  - (3*F(k+2)
     + 2*F(k+1)
    )
  + 5
  ;
}
check_equal(vector(10,k,k--; Dfull(k)), vector(10,k,k--; Dfull_recurrence(k)), \
           "Dfull_recurrence()");
Dfull(k) =
{
   (k-2)*F(k+3) - F(k+2) + 5;
}
check_equal(vector(10,k,k--; Dfull(k)), vector(10,k,k--; Dfull_recurrence(k)), \
           "Dfull_recurrence()");

Dfull(k) =
{
   (k-1)*F(k+3) - F(k+4) + 5;
}
check_equal(vector(10,k,k--; Dfull(k)), vector(10,k,k--; Dfull_recurrence(k)), \
           "Dfull_recurrence()");

Wfull(k) =
{
  if(k==0,0, k==1,0,
     Wfull(k-1) + Wfull(k-2) 
     + (Dfull(k-1) + 3*Nfull(k-1) )*Nfull(k-2)   \\ left to right root
     + Dfull(k-2) *Nfull(k-1)                    \\ right root down
     + Dfull(k-1)+Nfull(k-1)    \\ new 1 to left
     + Dfull(k-1)+2*Nfull(k-1)  \\ new 3 to left
     + Dfull(k-2)+2*Nfull(k-2) \\ new 1 to right
     + Dfull(k-2)+Nfull(k-2)   \\ new 3 to right
     + 1);
}
Wfull=memoize(Wfull);

{
  my(v=[0,0,4,32,174,744,2834,9946,33088,105802]);
  check_equal(vector(#v,k,k--; Wfull(k)), v);
}

\\       1
\\     /   \          height => 3
\\   2       3
\\  / \      |
\\ 4   5     6

\\            1
\\          /   \          height => 4
\\        2       3
\\       / \      |
\\      4   5     6
\\     / \  |    / \
\\    7  8  9  10   11


print("Wfull ",vector(10,k,k--;Wfull(k)));  \\ 

recurrence_guess(vector(100,k,k--; Wfull(k)))

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

gKtimesFtimesFnext(x) = 
{
  1/5/(1 + x)
  - 1/5/(1 + x)^2
  + (-1 - 1/5*x)/(1 - 3*x + x^2)
  + (1 - 2*x)/(1 - 3*x + x^2)^2;
}
check_equal(gf_terms(gKtimesFtimesFnext(x),100), vector(100,k,k--; k*fibonacci(k)*fibonacci(k+1)));


gWfull(x) =
{
  -1/(1 - x)
  - 7/5/(1 + x)
  + 2/5/(1 + x)^2
  + (-35/2 + 69/10*x)/(1 - 3*x + x^2)
  + (3 - x)/(1 - 3*x + x^2)^2
  + (25/2 + 13/2*x)/(1 - x - x^2)
  + (4 + 2*x)/(1 - x - x^2)^2
  ;
}

{
  my(e=0);
  lindep([gWfull(x),
          1/x^e*gKtimesFsquared(x),
          1/x^e*gKtimesFsquaredPlus1(x),
          1/x^(e+0)*gFsquared(x),
          1/x^(e+1)*gFsquared(x),

          1/x^(e+0)*gKtimesF(x),
          1/x^(e+0)*gKtimesFnext(x),
          1/x^(e+0)*gF(x),
          1/x^(e+1)*gF(x),

          1/x^e*gKtimesAlternating(x),
          1/x^e*gAlternating(x),
          \\ 1/x^(e+1)*gKtimesAlternating(x),
          \\ 1/x^(e+1)*gAlternating(x),

          1/(1-x)
         ]
         * ( (x+1)^2 * (x^2-3*x+1)^2 * (x^2+x-1)^2 )
         * (1-x))
}
\\ [-10, -30, 80, 125, -325, 16, 28, 81, 165, -40, 170, -10]~

Wfull_by_F(k) =
{
  1/10 * (
          -30 * k*F(k)^2
          + 80 * k*F(k+1)^2
          + 125 * F(k)^2 
          - 325 * F(k+1)^2
          + 16 * k*F(k)
          + 28 * k*F(k+1)
          + 81 * F(k)
          + 165 * F(k+1)
          - 40 * k * (-1)^k
          + 170 * (-1)^k
          - 10
         );
}
check_equal(vector(100,k,k--; Wfull_by_F(k)), vector(100,k,k--; Wfull(k)));

Wfull_by_F(k) =
{
  1/10 * (
          -30 * k*F(k)^2
          + 80 * k*F(k+1)^2
          + 125 * F(k)^2 
          - 325 * F(k+1)^2
          + 16 * k*F(k)
          + 28 * k*F(k+1)
          + 81 * F(k)
          + 165 * F(k+1)
          - 40 * k * (-1)^k
          + 170 * (-1)^k
          - 10
         );
}
check_equal(vector(100,k,k--; Wfull_by_F(k)), vector(100,k,k--; Wfull(k)));

Wfull_by_F(k) =
{
  1/10 * (
          k*( -30 * (F(k+1)-F(k))*F(k+1)
             + 10 * F(k)*(F(k+1)+F(k))
             + 70 * F(k+1)^2
             + 8 * F(k+3)
             + 4 * F(k+4)
             )

          + 125 * F(k)^2 
          - 325 * F(k+1)^2
          + 81 * F(k)
          + 165 * F(k+1)
          + 170 * (-1)^k
          - 10
         );
}
check_equal(vector(100,k,k--; Wfull_by_F(k)), vector(100,k,k--; Wfull(k)));

\\ a^2 + 4*a*b + 4*b^2 == (a+2*b)^2
          \\ + 125 * (2*F(k+4) - 3*F(k+3) )^2 
\\ subst(subst(-45*a^2 - 170*a*b - 155*b^2 + 81*a+165*b, 'b, 2*x-y), 'a, -3*x+2*y)
check_equal(vector(100,k, F(k)), vector(100,k, -3*F(k+3)+2*F(k+4)));
check_equal(vector(10,k, F(k+1)), vector(10,k, 2*F(k+3)-F(k+4)));
\\ F(k) = 

Wfull_by_F(k) =
{
  my(a=F(k),
     b=F(k+1),
     x=F(k+3),
     y=F(k+4));
  1/10 * (
          k*(
             + 10 * F(k+3)^2
             + 4 * (2*F(k+3) + F(k+4))
             )

          \\ -45*a^2 - 170*a*b - 155*b^2 + 81*a+165*b
          -5*x^2 + (-30*y + 87)*x + (5*y^2 - 3*y)

          \\ - 45 * F(k)*F(k)
          \\ - 170 * F(k)*F(k+1)
          \\ - 155 * F(k+1)^2
          \\ + 81 * F(k)
          \\ + 165 * F(k+1)

          - 10
         );
}
check_equal(vector(100,k,k--; Wfull_by_F(k)), vector(100,k,k--; Wfull(k)));

Wfull_by_F(k) =
{
  1/10 * (
          (2*k-1)*(
             + 5 * F(k+3)^2
             + 2 * (2*F(k+3) + F(k+4))
             )

          -30 * F(k+4)*F(k+3) 
          + 5 * F(k+4)^2
          + 87 * F(k+3) 
          - 3 * F(k+4)
          + 2 * (2*F(k+3) + F(k+4))

          - 10
         );
}
check_equal(vector(100,k,k--; Wfull_by_F(k)), vector(100,k,k--; Wfull(k)));

check_equal(vector(100,k,k--; F(k+4)^2-F(k+3)^2), vector(100,k,k--; F(k+3)*F(k+4) - (-1)^k));

Wfull_by_F(k) =
{
  1/10 * ( 2*k * ( 5*F(k+3)^2
                   + 2*( 2*F(k+3) + F(k+4)) )

          - 25*F(k+3)*F(k+4)

          - 3*F(k+4)
          + 87*F(k+3)
          - 10
          - 5*(-1)^k
         );
}
check_equal(vector(100,k,k--; Wfull_by_F(k)), vector(100,k,k--; Wfull(k)));

Wfull_by_F(k) =
{
  1/10 * ( (2*k-1)*( 5*F(k+3)^2 + 2*( 2*F(k+3) + F(k+4)) )
           + 5*( F(k+4) - 6*F(k+3) + 18 )*F(k+4)  - 91*F(k+2) - 10  );
}
check_equal(vector(100,k,k--; Wfull_by_F(k)), vector(100,k,k--; Wfull(k)));


Diameter(k) = 2*k-2;
MeanDist(k) = Wfull_by_F(k) / binomial(Nfull(k),2);

MeanDist_over_Diameter(k) =
{
  MeanDist(k) / Diameter(k);
}
MeanDist_over_Diameter(1000)*1.0

MeanDist_over_Diameter_simplified(k) =
{
  1/10 * ( (2*k-1)*( 5*F(k+3)^2 + 2*( 2*F(k+3) + F(k+4)) )
           + 5*( F(k+4) - 6*F(k+3) + 18 )*F(k+4)  - 91*F(k+2) - 10  )

  / (2*k-2)   / (F(k+3)-2) / (F(k+3)-3 ) * 2;
}
check_equal(vector(100,k,k++; MeanDist_over_Diameter_simplified(k)), \
            vector(100,k,k++; MeanDist_over_Diameter(k)));


MeanDist_over_Diameter_limit_some(k) =
{
  1/5 * 2*k*( 5*F(k+3)^2 + 2*( 2*F(k+3) + F(k+4)) )
  / (2*k)   / (F(k+3)-2) / (F(k+3)-3 );
}
MeanDist_over_Diameter_limit_some(k) =
{
  1/5 * ( 5*F(k+3)^2 + 2*( 2*F(k+3) + F(k+4)) )
         /  F(k+3)^2;
}
MeanDist_over_Diameter_limit_some(k) =
{
  1
}
print("limit");
MeanDist_over_Diameter_limit_some(1000)*1.0
MeanDist_over_Diameter(10000000)*1.0


