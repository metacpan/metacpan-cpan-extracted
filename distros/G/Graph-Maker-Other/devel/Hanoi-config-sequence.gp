\\ Copyright 2020, 2021, 2022 Kevin Ryde
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
read("OEIS-data.gp");
read("OEIS-data-wip.gp");
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
     if(name=="",print("ok"),print("ok ",name)));
}

gf_terms(g,n) = \
  my(x = variable(g), \
     zeros = min(n,valuation(g,x)), \
     v = Vec(g + O(x^n))); \
  if(zeros>=0, concat(vector(zeros,i,0), v), \
               v[-zeros+1 .. #v]);

to_binary(n)=fromdigits(binary(n))*sign(n);
from_binary(n)=fromdigits(digits(n),2);

\\-----------------------------------------------------------------------------
\\ Generic

A001511(n) = valuation(n,2) + 1;
{
  OEIS_check_func("A001511");
}

flip12(n) = {
  n>=0 || error();
  fromdigits(apply(t->if(t,3-t),digits(n,3)),3); 
}
A004488(n) = flip12(n);
{
  OEIS_check_func("A004488");
}


\\-----------------------------------------------------------------------------
\\ Hamiltonian Path - 3-Valuation Moves

\\ A128173 Numbers in ternary reflected Gray code order.
\\ A128173 ,0,1,2,5,4,3,6,7,8
\\ apply(to_ternary,OEIS_data("A128173"))

\\ Refs in Hinz et al book:
\\ [290] Scorer, Grundy, Smith, "Some Binary Games", Mathematics Magazine 280
\\ (1944) 96103.  Page 99 brief
\\ [204] X. Lu, "Towers of Hanoi Graphs", International Journal of Computer
\\ Mathematics 19 (1986) 2338.

\\ vector(20,n,valuation(n,3))
\\ A007949 Greatest k such that 3^k divides n.  Or, 3-adic valuation of n.
\\ A007949 ,0,0,1,0,0,1,0,0,2,0

Hamiltonian_step(v,n) =
{
  my(d=valuation(n,3)+1);
  while(#v<d,v=concat(v,[0]));
  my(from=v[d],to);
  to=from + (-1)^vecsum(v[d+1..#v]);
  for(i=1,d-1,
     if(v[i]==from||v[i]==to,error(v" move d="d" from="from" to="to)));
  v[d] = to;
  v;
}
{
  if(0,
     my(v=[],seen=Map(),S=List([]));
     for(n=1,20,
        v=Hamiltonian_step(v,n);
        printf("%2d  %s moved %d\n", n, v, valuation(n,3)+1);
        my(s=fromdigits(apply(t->if(t==0,0,t), Vecrev(v)),3));
        s=to_ternary(s);
        listput(S,s);
     );
     print(S);
     quit);
}


\\-----------------------------------------------------------------------------
\\ A055662 configs of optimal paths, in decimal digits starting from 1
\\   ternary digit k = which spindle number holds a disc
\\
\\ 0,1, 21,22, 122,120,110,111, 2111,2112,2102,2100,2200,2201,2221,2222
\\
\\ low digit: 0, 1, 1, 2, 2, 0
\\ 2nd digit: 0, 0, 2, 2, 2, 2, 1, 1, 1, 1, 0, 0
\\ 6 periodic, 12 periodic, etc 6*2^k, opposite ways

\\ 0, 1, 1, 2, 2, 0,0, 1, 1, 2, 2, 0,0, 1, 1, 2, 2, 0,0, 1, 1, 2, 2, 0
\\ A131555
\\ not in OEIS: 0, 0, 2, 2, 2, 2, 1, 1, 1, 1, 0, 0,0, 0, 2, 2, 2, 2, 1, 1, 1, 1, 0, 0,0, 0, 2, 2, 2, 2, 1, 1, 1, 1, 0, 0
\\ vector(20,n,n--; A055662(n)%10)
\\ vector(20,n,n--; A055662(n)\10%10)
\\ vector(20,n,n--; A055662(n)\100%10)

\\ formula in A055662
A055662(n) =
{
  n>=0 || error();
  sum(j=0,if(n,logint(n,2)),
      10^j * (floor((n/2^j + 1)/2)*(-1)^j % 3));
}
{
  OEIS_check_func("A055662");
}
\\ 
\\ x x x . x x
\\    +1
\\    |floor
\\ vector(20,n,hammingweight(n)%2)
{
  check_equal(vector(20,k, (2^k)%3),
              vector(20,k, k%2 + 1));

  check_equal(vector(3^5,n,n--; A055662(n)%10),
              vector(3^5,n,n--; [0,1,1,2,2,0][n%6+1]),
              "A055662 low digit 6-periodic");

}
{
  my(n=from_binary(1111000111));
  check_equal(A055662(n), 2222000111);
}

{
  if(0,
     print(concat(vector(12,n, digits(A055662(n)))));
     print(concat(vector(12,n, Vecrev(digits(A055662(n))))));
     quit);
  \\ not in OEIS: 1,2,1,2,2,1,2,2,1,2,0,1,1,0,1,1,1,2,1,1,1,2,1,1,2,2,1,0,2,2,1,0,0,2,2,0,0
  \\ not in OEIS: 1,1,2,2,2,2,2,1,0,2,1,0,1,1,1,1,1,1,1,1,2,2,1,1,2,2,0,1,2,0,0,1,2,0,0,2,2
}

\\-----------------------------------------------------------------------------
\\ discs on spindles by runs

\\        1, 1,  2,   1
\\ discs  5  4  2,3   1            4 prefer occupied
\\ peg       X   Y    X

bit_runs(n) =
{
  my(v=binary(n),pos=0,prev=0);
  for(i=1,#v, if(v[i]==prev, v[pos]++, prev=v[i];pos++;v[pos]=1));
  v[1..pos];
}
check_equal(bit_runs(0), []);
check_equal(bit_runs(22), [1,1,2,1]);
check_equal(bit_runs(from_binary(110000101)), [2,4,1,1,1]);

other_pegs(peg) = setminus([1,2,3],[peg]);
other1(peg) = other_pegs(peg)[1];
other2(peg) = other_pegs(peg)[2];
pegallocs(runs) =
{
  my(ret=vector(vecsum(runs)),
     pos=#ret+1,
     seen=[0,0,0],
     peg=2);
  forstep(i=#runs,1,-1,
     my(new_peg=other1(peg));
     if(!seen[new_peg] && seen[other2(peg)], new_peg=other2(peg));
     peg=new_peg;
     for(j=1,runs[i], ret[pos--] = peg; seen[peg]++));
  ret;     
}
pegallocs_of_n(n) = pegallocs(bit_runs(n));
\\ pegallocs([1,1,2,1])

{
  if(0,
     my(n=from_binary(1111000011111));
     print(binary(n)," binary");
     print(pegallocs_of_n(n)," pegallocs");
     print(digits(A055662(n)), " A055662"));
}

\\ parity how far from end, and the bit value
LtoH(n) =
{
  my(v=binary(n),
     prev=if(#v,v[#v]),
     peg=(n\/2)%3);
  forstep(i=#v,1,-1,
     if(v[i]!=prev, peg = (peg + (-1)^(#v-i + v[i]))%3);
     prev=v[i];
     v[i]=peg);
  v;     
}
\\ print(LtoH(n), " LtoH");
{
  for(n=0,2000,
     \\ print(binary(n)," binary ",(n\2)%3);
     \\ print(digits(A055662(n)), " A055662");
     \\ print(LtoH(n), " LtoH\n");
     my(want=digits(A055662(n)));
     my(got=LtoH(n));
     want==got || error());
}

{
  \\ X  YY X  when Y run even length
  \\ X YYY Z  when Y run odd length
  for(n=0,3^8,
     my(v=digits(A055662(n)),
        X='none,
        Y='none, Ycount=0);
     for(i=1,#v,
        if(X!='none && Y!='none && v[i]!=Y,
           X!=Y || error();
           my(want=if(Ycount%2==0, X, setminus([0,1,2], Set([X,Y]))[1]));
           v[i] == want  || error(v" at i="i" want="want));
        
        if(v[i]!=Y,
           X=Y; Ycount=1; Y=v[i],
           Ycount++)));
}
     

\\-----------------------------------------------------------------------------
\\ A055662 configs by M. C. Er, as given in:
\\
\\ Hinz et al, "Myths and Maths" page 81 algorithm 7 method of
\\ M. C. Er, "The Towers of Hanoi and Binary Numerals", Journal of
\\ Information & Optimization Sciences, volume 6, 1985, pages 147-152.
\\
\\ Auxiliary variable i.


swap12(t) = if(t==1,2,t==2,1, t);
ternary_swap12(n) = fromdigits(apply(swap12,digits(n,3)),3);
decimal_swap12(n) = fromdigits(apply(swap12,digits(n)));

p0pa(n,l) =
{
  my(i=0,s=vector(n));
  forstep(d=n,2,-1,
     my(ld = bittest(l,d-1));
     s[d] = (i - ld*((n-d)%2 + 1)) % 3;
     i = (i + ld*(i-s[d])) % 3);
  s[1] = (i + bittest(l,0)*(n%2 + 1)) % 3;
  fromdigits(Vecrev(s));
}

{
  my(num_discs=10);
  check_equal(vector(2^10,n,n--; p0pa(num_discs,n)),
              vector(2^10,n,n--; A055662(n)),
              "p0pa() vs A055662");

}
\\ n=6;
\\ vector(16,l,l--; p0pa(n,l))
\\ quit


\\-----------------------------------------------------------------------------
\\ A055662 configs by state machine

\\ digit      0,1,2
\\ prev bit   0,1
\\ num diffs and pos parity  0,1
\\ 3*2*2 == 12 \\ states
\\ 
\\ in a matrix
{ my(table=[7,8, 2,12, 1, 12, 1,2, 7,8,6, 6;
            3,4, 9,10,11, 10,11,9, 3,4,5, 5]);
  A055662_by_states_matrix(n) =
    my(v=binary(n), state=if(#v%2,6,12));
    for(i=1,#v,
      state=table[1+v[i],state];
      v[i]=state%3);
    fromdigits(v);
}
{
  check_equal(vector(2^14,n, A055662_by_states_matrix(n)),
              vector(2^14,n, A055662(n)),
              "A055662_by_states_matrix()");
}
\\ in a flat vector
{
  my(table=[13,9,15,11,17,7,3,19,5,21,1,23,
            1,23,3,19,5,21,17,7,13,9,15,11]);
  A055662_by_states_flat(n) =
    my(v=binary(n), state=if(#v%2,15,3));
    for(i=1,#v, state=table[state+v[i]]; v[i]=state%3);
    fromdigits(v);
}
{
  check_equal(vector(2^14,n, A055662_by_states_flat(n)),
              vector(2^14,n, A055662(n)),
              "A055662_by_states_flat()");
}

\\ for(n=16,32, printf("%7d\n%7d\n%7d\n\n", to_binary(n), A055662(n), by_transitions(n)));
\\ by_transitions(0)
\\ by_transitions(1)
my(n=from_binary(11111100001111001110110000001111000011110000111000111000)); \
  printf("%7d\n%7d\n%7d\n\n", to_binary(n), A055662(n), A055662_by_states_flat(n));


\\-----------------------------------------------------------------------------
\\ Sunic automaton OH going high to low.

\\ odd are 12 is +1 mod 3
\\
OH_map={Map([ ["01",0 ], ["02",0];   \\ odd
              [ "01",1], ["21",1];
              ["02",0 ], ["01",0];   \\    even    02 from 01-0 or 12-2  this 0,2
              [ "02",1], ["12",2];
              ["12",0 ], ["10",1];   \\ odd
              [ "12",1], ["02",2];
              ["10",0 ], ["12",1];   \\    even    10 from 12-1 or 20-0  this 1,0
              [ "10",1], ["20",0];
              ["20",0 ], ["21",2];   \\ odd
              [ "20",1], ["10",0];
              ["21",0 ], ["20",2];   \\    even    21 from 20-2 or 01-1  this 2,1
              [ "21",1], ["01",1] ])};
\\ state is a string like "01", v is a vector of bits
\\ return new state
OH_transitions(state,v) =
{
  for(i=1,#v,
    [state,v[i]]=mapget(OH_map,[state,v[i]]));
  v;
}
check_equal(OH_transitions("01",[1,0,0]), [1,2,2]);
\\ OH_transitions("01",[1,1,1]) 
check_equal(from_ternary(122), 17);

OH_value(n,odd) = {
  my(v=binary(n));
  if((#v+odd)%2, v=concat(0,v));
  fromdigits(OH_transitions("01",v),3);
}
{
  check_equal(vector(8,n,n--; OH_value(n,1)), [0, 1, 7, 8, 17, 15, 12, 13],
             "OH_value(n,1)");
  check_equal(vector(8,n,n--; OH_value(n,0)), [0, 2, 5, 4, 22, 21, 24, 26],
             "OH_value(n,1)");
}


\\-----------------------------------------------------------------------------
\\ A055662 configs by arithmetic
\\   decimal digits of configurations of discs on spindles

\\ # matrix(80,8,n,j,j--; (floor((n/2^j + 1)/2)*(-1)^j % 3)) == \
\\ # matrix(80,8,n,j,j--; n>>=j; ( -(-1)^j * ( n + bittest(n,0) ) % 3))
\\ # row(n) = Vecrev(vector(12,j,j--; my(n=n>>j); ( -(-1)^j * ( n + bittest(n,0) ) % 3)))
\\ # R(n) = my(v=binary(n),t=0); while(#v<12,v=concat(0,v)); \
\\ #   for(i=1,#v, [t,v[i]] = [ t=v[i]+2*t, (2*v[i]+2*t)*(-1)^(#v-i) % 3 ] ); v;
\\ # R(n) = my(v=binary(n),t=Mod(0,3)); \
\\ #   while(#v<12,v=concat(0,v)); \
\\ #   my(s=-Mod(-1,3)^#v, T=s*t); \
\\ #   for(i=1,#v, t=-t-v[i]; T-=s*v[i]; v[i] = lift(T - s*v[i]); s=-s ); v;
\\ # R(n) = my(v=binary(n),T=Mod(0,3)); \
\\ #   while(#v<12,v=concat(0,v)); \
\\ #   my(s=Mod(-1,3)^#v); \
\\ #   for(i=1,#v, T += s*v[i]; v[i] = lift(T + s*v[i]); s=-s ); v;
\\ # R(n) = my(v=binary(n)); \
\\ #   while(#v<12,v=concat(0,v)); \
\\ #   my(t=Mod(0,3), s=Mod(-1,3)^#v); \
\\ #   for(i=1,#v, t=v[i]-t; v[i]=lift((t+v[i])*s); s=-s); v;
\\ # R(340)
\\ # row(340)
\\ # R(140)
\\ # row(140)
\\ # vector(1000,n,R(n)) == \
\\ # vector(1000,n,row(n))
\\ # binary(350)
\\ # n=350; n>>=7; [n, n+bittest(n,0), (n+bittest(n,0))%3, ( -(-1)^j * ( n + bittest(n,0) ) % 3)]

\\ # GP-Test  vector(16,n,n--; A055662(n)) 
\\ # GP-Test  vector(16,n,n--; \
\\ # GP-Test    my(v=binary(n)); my(t=0, s=-(-1)^#v); \
\\ # GP-Test    for(i=1,#v, v[i]=t=(-t+v[i]*s)%3; s=-s); \
\\ # GP-Test    fromdigits(v))

{
  \\ change ternary at each bit transition, parity of how many transitions,
  \\ parity of position
  check_equal(vector(1024,n,n--; A055662(n)),
              vector(1024,n,n--; 
   my(k=if(n,logint(n,2)+1),d=0);
   fromdigits(vector(k,i, if(bittest(n,k)!=bittest(n,k--),d-=(-1)^(bittest(n,k)+k)); d%=3))),
              "A055662 bit diffs");

  check_equal(vector(1064,n,n--; A055662(n)),
              vector(1064,n,n--; 
                     my(k=if(n,logint(n,2)+1),s=(-1)^k,d=0);
                     fromdigits(vector(k,i, if(bittest(n,k)==bittest(n,k--),s=-s,d=(d-s)%3); d))),
              "A055662 bit diffs");
    
  check_equal(vector(64,n,n--; 
                my(k=if(n,logint(n,2)+1),s=k,d=0);
                fromdigits(vector(k,i, if(bittest(n,k-i)==bittest(n,k-i+1),s++,d=(d-(-1)^s)%3); d))),
              vector(64,n,n--; A055662(n)),
              "A055662 bit diffs, s as bit");
    
  check_equal(vector(64,n,n--;
                my(k=if(n,logint(n,2)+1),s=k,d=0);
                n=bitxor(n,n>>1);
                fromdigits(vector(k,i, if(bittest(n,k-i),d=(d-(-1)^s)%3,s++); d))),
              vector(64,n,n--; A055662(n)),
              "A055662 bit xor, s as bit");
    
  check_equal(vector(64,n,n--;
                my(v=binary(bitxor(n,n>>1)),s=(-1)^#v,d=0);
                fromdigits([if(b,d=(d-s)%3,s=-s;d) | b<-v])),
              vector(64,n,n--; A055662(n)),
              "A055662 bit xor, s as bit");
    
  check_equal(vector(2^14,n,n--; A055662(n)),
              vector(2^14,n,n--; 
                     my(v=binary(n)); my(t=0, s=(-1)^#v); 
                     for(i=1,#v, my(b=v[i]); s=-s; v[i]=s*(b+t)%3; t=b-t); 
                     fromdigits(v)),
              "A055662 b+t");
    
  check_equal(vector(10000,n,n--; A055662(n)),
              vector(10000,n,n--; 
                     my(v=binary(n)); my(t=0, s=(-1)^#v); 
                     for(i=1,#v, t=v[i]-t; v[i]=s*(t+v[i])%3; s=-s); 
                     fromdigits(v)),
              "A055662 t neg");

  check_equal(vector(10000,n,n--; A055662(n)),
              vector(10000,n,n--; my(v=binary(n)); 
                     my(t=Mod(0,3), s=(-1)^#v); 
                     for(i=1,#v, t=v[i]-t; v[i]=lift((t+v[i])*s); s=-s); 
                     fromdigits(v)),
              "A055662 lift");
}
\\ vector(10,n,n--; A055662(2*n))
\\ vector(10,n,n--; (10^(#digits(A055662(n))+1)-1)/3 - 10*A055662(n))
\\ 
\\ # vector(100,n,n--; valuation(A055662(n+1) - A055662(n),10))
\\ # vector(10,n,n--; A055662(n+1) - A055662(n))
\\ # vector(10,n,n--; my(d=A055662(n+1) - A055662(n)); \
\\ #                  if(d<0, d+=3*10^logint(abs(d),10)); d)
\\ 

{
  \\ +1 or -1 as bit position and num transitions so far
  check_equal(vector(2^12,n,n--; A055662(n)),
              vector(2^12,n,n--; 
                     my(v=binary(bitxor(n,n>>1))); \
                     my(t=0, c=#v); \
                     for(i=1,#v, if(v[i], t-=(-1)^(i+(c--))); v[i]=t%3); \
                     fromdigits(v)),
              "A055662 Gray");

  \\ arithmetic, alternating digits
  check_equal(vector(2^12,n,n--; A055662(n)),
              vector(2^12,n,n--; \
                     my(v=binary(bitxor(n,n>>1)), t=Mod(0,3), c=(-1)^#v); \
                     for(i=1,#v, if(v[i],t-=c,c=-c); v[i]=lift(t)); \
                     fromdigits(v)),
              "A055662 Gray and lift");

  check_equal(vector(2^12,n,n--; A055662(n)),
              vector(2^12,n,n--; \
                     my(v=binary(bitxor(n,n>>1)),s=(-1)^#v,d=0); \
                     for(i=1,#v, if(v[i],d-=s,s=-s); v[i]=d%3); \
                     fromdigits(v)),
              "A055662 Gray and s,d");
}
\\ 
\\ # vector(30,n,n--; A055662(n+1) - A055662(n))


\\-----------------------------------------------------------------------------
\\ A060571  source of n'th move

A060571(n) = ((-1)^valuation(n,2) - n)%3;
{
  OEIS_check_func("A060571");
}
extract_digit(n,p) = (n\10^p)%10;
{
  \\ Donald Sampson in A060571,  a(2n) with 1<->2 reversed
  check_equal(vector(1024,n, A060571(n)),
              vector(1024,n, (-A060571(2*n))%3),
              "A060571 source, by A060571(2n)");

  \\ digit of configuration
  check_equal(vector(1024,n, A060571(n)),
              vector(1024,n, extract_digit(A055662(n-1), valuation(n,2))),
              "A060571 source, by digit of configuration");
}

\\-----------------------------------------------------------------------------
\\ A060572  destination of n'th move

\\ my line of code in A060572
A060572(n) = (- (-1)^valuation(n,2) - n)%3;
{
  OEIS_check_func("A060572");
}
extract_digit(n,p) = (n\10^p)%10;
{
  \\ Donald Sampson in A060572,  a(2n) with 1<->2 reversed
  check_equal(vector(1024,n, A060572(n)),
              vector(1024,n, (-A060572(2*n))%3),
              "A060572 destination, by A060572(2n)");

  \\ digit of configuration
  check_equal(vector(1024,n, A060572(n)),
              vector(1024,n, extract_digit(A055662(n), valuation(n,2))),
              "A060572 destination, by digit of configuration");

  check_equal(vector(1024,n, A060572(n)),
              vector(1024,n, (A060571(n) - (-1)^A001511(n)) % 3),
              "A060572 destination related to source");

  check_equal(A060572(1), 1, "2^k even to peg 1");
  check_equal(vector(64,k,k--; A060572(2^k)),
              vector(64,k,k--; if(k%2==0,1,2)),
              "A060572 n=2^k move of largest disc to target 2,1");

  my(a=A060572);

  \\ Donald Sampson in A060572
  check_equal(vector(1024,n, a(2*n)),
              vector(1024,n, (-a(n))%3),
              "A060572(2n) by reversal");

  check_equal(vector(1024,n, a(n)),
              vector(1024,n, my(p=2^A001511(n));
                     if(n>p, (a(n-p) - (-1)^A001511(n)) % 3,
                             (       - (-1)^A001511(n)) % 3)),
              "A060572 destination recurrence");

  \\ c = A003602 Kimberling's paraphrases: if n = (2k-1)*2^m then a(n) = k.
  check_equal(vector(124,n, a(n)),
              vector(124,n, my(ret=0,c=0);
                     while(1, my(p=2^A001511(n)); c++;
                           ret += -(-1)^A001511(n); if(n>p,n-=p,break));
                     ret%3),
              "A060572 destination quotient, counting one by one");

  \\ first formula in A060572
  check_equal(vector(1024,n, a(n)),
              vector(1024,n, (A060571(n) - (-1)^A001511(n)) % 3),
              "A060572 destination related to source");
  \\ Donald Sampson in A060572
  check_equal(vector(1024,n, a(5*n)),
              vector(1024,n, (-A060571(n))%3),
              "A060572(5n) by source reversed");
}

\\-----------------------------------------------------------------------------
\\ A055661  ternary first move peg 1

A055661(n) = from_ternary(A055662(n));
{
  OEIS_check_func("A055662");
  check_equal(A055661(0), 0);
  check_equal(A055661(1), 1, "A055661 first move to peg 1");
}

\\-----------------------------------------------------------------------------
\\ A128202  ternary first move peg 2

A128202(n) =
{
  my(v=binary(bitxor(n,n>>1)),s=(-1)^#v,d=0); for(i=1,#v, if(v[i],d=(d+s)%3,s=-s); v[i]=d); fromdigits(v,3);
}
{
  my(want=[0, 2, 5, 4, 22, 21, 24, 26]);
  check_equal(vector(#want,n,n--; A128202(n)), want,
              "A128202 Sunic samples");
}
{
\\  OEIS_check_func("A128202");
}
{
  check_equal(A128202(0), 0);
  check_equal(A128202(1), 2);

  check_equal(vector(3^8,n,n--; A128202(n)),
              vector(3^8,n,n--; A004488(A055661(n))),
              "A128202 samples");

  my(n=from_binary(111000011100011));
  check_equal(n,28899);
  check_equal(A128202(n), 14086228);
  check_equal(to_binary(n),           111000011100011);
  check_equal(to_ternary(A128202(n)), 222111122200011);

}
{
  \\ DATA section
  if(0,
     for(n=0,55,print1(A128202(n),",");if(n==21||n==38,print()));
     print();
     quit);

  my(want=[
0,2,5,4,22,21,24,26,53,52,46,45,36,38,41,40,202,201,204,206,197,196,
190,189,216,218,221,220,238,237,240,242,485,484,478,477,468,470,473,
472,418,417,420,422,413,412,406,405,324,326,329,328,346,345,348,350
           ]);
  check_equal(vector(#want,n,n--; A128202(n)), want,
              "A128202 samples");
}


\\-----------------------------------------------------------------------------
\\ vacant peg choice ?

conf_first_peg(c) = c%3;
\\ print(vector(20,n,conf_first_peg(A055661(n))));quit
\\ A131555 Period 6: repeat [0, 0, 1, 1, 2, 2].

conf_second_peg(n) = {
  my(f=n%3);
  n\=3;
  if(n==0 && f==0, return('none));
  while(n%3==f, n\=3);
  n%3;
}
{
  \\ A055662
  check_equal(conf_second_peg(from_ternary(1)), 0);
  check_equal(vector(14,n,n--; conf_second_peg(A055661(n))),
              ['none, 0, 2, 0, 1, 2, 1, 0, 2, 1, 0, 1, 2, 0]);
}
\\ print(vector(20,n,conf_second_peg(A055661(n))));quit
\\ not in OEIS: 0, 2, 0, 1, 2, 1, 0, 2, 1, 0, 1, 2, 0, 2, 0, 1, 2, 1, 2, 0

conf_second_len(n) = {
  my(f=n%3);
  n\=3;
  if(n==0 && f==0, return('none));
  while(n%3==f, n\=3);
  my(s=n%3,len=0);
  if(n==0 && s==0, return('none));
  while(n%3==s, n\=3; len++);
  len;
}
\\ print(vector(40,n,conf_second_len(A055661(n))));quit
\\ not in OEIS: 1, 3, 1, 2, 1, 1, 2, 1, 2, 2, 1, 1, 3, 1, 4

conf_nth_peg(n,i) =
{
  i>=1 || error();
  while(i-->0,
        my(p=n%3);
        n\=3;
        if(n==0 && p==0, return('none));
        while(n%3==p, n\=3));
  n%3;
}
{ my(c=from_ternary(2112));
  check_equal(conf_nth_peg(c,1),2, "peg 1");
  check_equal(conf_nth_peg(c,2),1, "peg 2");
  check_equal(conf_nth_peg(c,3),2, "peg 3");
  check_equal(conf_nth_peg(c,4),0, "peg 4");
  check_equal(conf_nth_peg(c,5),'none, "peg 5");
}
{
  \\ A055662
  check_equal(conf_nth_peg(1,1),1,     "1 peg 1");
  check_equal(conf_nth_peg(1,2),0,     "1 peg 2");
  check_equal(conf_nth_peg(1,3),'none, "1 peg 3");
  check_equal(vector(14,n,n--; conf_nth_peg(A055661(n),3)),
              ['none, 'none, 0, 'none, 0, 1, 0, 'none, 0, 2, 1, 2, 0, 2],
              "conf_nth_peg 3");

  check_equal(vector(100,n,n--; my(c=A055661(n)); conf_nth_peg(c,1)),
              vector(100,n,n--; my(c=A055661(n)); conf_first_peg(c)));
  check_equal(vector(100,n,n--; my(c=A055661(n)); conf_nth_peg(c,2)),
              vector(100,n,n--; my(c=A055661(n)); conf_second_peg(c)));

  \\ A055661 style
  check_equal(vector(100,n,n--; my(c=A055661(n)); if(conf_nth_peg(c,3)=='none,'x,
                                                     conf_nth_peg(c,1) == conf_nth_peg(c,3))),
              vector(100,n,n--; my(c=A055661(n)); if(conf_nth_peg(c,3)=='none,'x,
                                                     conf_second_len(c)%2==0)));

  check_equal(vector(100,n,n--; my(c=A055661(n)); if(conf_nth_peg(c,3)=='none,'x,
                                                     conf_nth_peg(c,1) != conf_nth_peg(c,3))),
              vector(100,n,n--; my(c=A055661(n)); if(conf_nth_peg(c,3)=='none,'x,
                                                     conf_second_len(c)%2==1)));

  \\ A128202 style
  check_equal(vector(100,n,n--; my(c=A128202(n)); if(conf_nth_peg(c,3)=='none,'x,
                                                     conf_nth_peg(c,1) == conf_nth_peg(c,3))),
              vector(100,n,n--; my(c=A128202(n)); if(conf_nth_peg(c,3)=='none,'x,
                                                     conf_second_len(c)%2==0)));

  check_equal(vector(100,n,n--; my(c=A128202(n)); if(conf_nth_peg(c,3)=='none,'x,
                                                     conf_nth_peg(c,1) != conf_nth_peg(c,3))),
              vector(100,n,n--; my(c=A128202(n)); if(conf_nth_peg(c,3)=='none,'x,
                                                     conf_second_len(c)%2==1)));
}
{
  \\ run lengths   1  2  1 1
  my(n=from_binary(1 0 0 1 1),
     c=A055661(n));
  check_equal(A055662(n), 12211);
  check_equal(to_ternary(A055661(n)), 12211);  
  check_equal(to_ternary(A128202(n)), 21122);
}
{
  \\ run lengths   1 1  2  1
  my(n=from_binary(1 0 1 1 0));
  check_equal(A055662(n), 12002);  
  check_equal(to_ternary(A055661(n)), 12002);  
  check_equal(to_ternary(A128202(n)), 21001);
  \\ peg 1:   4     1       4 choose occupied
  \\ peg 2:     2/3
  \\ peg 3: 5            

  \\ occupied/vacant follows from parity rule that adjacent discs on a given
  \\ peg must be opposite parity
}
     

\\-----------------------------------------------------------------------------
check_equal(d,'d);
check_equal(i,'i);
check_equal(h,'h);
check_equal(k,'k);
check_equal(m,'m);
check_equal(mdash,'mdash);
check_equal(n,'n, "global variable n");
check_equal(p,'p);
check_equal(t,'t);
check_equal(ret,'ret);
print("end");
