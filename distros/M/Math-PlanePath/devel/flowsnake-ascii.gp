\\ Copyright 2015 Kevin Ryde

\\ This file is part of Math-PlanePath.
\\
\\ Math-PlanePath is free software; you can redistribute it and/or modify it
\\ under the terms of the GNU General Public License as published by the Free
\\ Software Foundation; either version 3, or (at your option) any later
\\ version.
\\
\\ Math-PlanePath is distributed in the hope that it will be useful, but
\\ WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
\\ or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
\\ for more details.
\\
\\ You should have received a copy of the GNU General Public License along
\\ with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

default(strictargs,1)
sqrt3i = quadgen(4*-3);
w = 1/2 + 1/2*sqrt3i;
b = 2 + w;

{
  \\ rot 1,8,15 through state table
  rot = [0,0,1, 0,0,1,2];
  perm = Vecsmall([1,3,5,7,2,4,6]);
  v = [6, 6];
  r = 0;
  forstep(i=#v,1, -1,
         d = (perm^r)[v[i]];
         r = (r + rot[d]) % 3;
         print("new r="r);
  );
  print(r);
  \\         
  table = 7*[0, 0, 1, 0, 0, 1, 2, 1, 2, 1, 0, 1, 1, 2, 2, 2, 2, 0, 0, 1, 2];
  r = 0;
  forstep(i=#v,1, -1, r = table[r+v[i]];
         print("new r="r);
  );
  print(r/7);

  d=7;r=2;
  d = (perm^r)[d];
  r = (r + rot[d]) % 3;
  print("d perm "d" to r="r);

  d=7;r=2*7;
  print("table entry ",r+d);
  r = table[r+d];
  print("to r="r);


  quit;
}
{
  \\ rot high to low by state table
  rot = [0, 0, 1, 0, 0, 1, 2];
  perm = Vecsmall([1,3,5,7,2,4,6]);
  table = vector(3*7,i,-1);
  for(r=0,2,
     for(d=1,7,
        dperm = (perm^r)[d];
        new_r = (r + rot[dperm]) % 3;
        table[7*r + d] = new_r;
        print("table entry ",7*r+d," is ",7*new_r," for r="r" d="d" perm d="dperm);
     ));
  print(table);
  quit;
}

{
  \\ when b^k is an X maximum
  pos  = [0, w^2, 1, w, w^4, w^3, w^5];
  for(k=0,50,
     X = sum(i=0,k-1, vecmax(real(b^i*pos)));
     Xbk = real(b^(k-1) + 1);
     diff = abs(Xbk) - X;
     if(diff >= 0,
        angle = arg(b^k) *180/Pi;
        print("k="k" diff="diff"  X="X" Xbk="Xbk"  angle "angle),
       print("k="k"  not"));
  );
  print();
  quit;
}

{
  \\ extents
  pos  = [0, w^2, 1, w, w^4, w^3, w^5];
  for(k=0,500,
     X = 2*sum(i=0,k-1, vecmax(real(b^i*pos)));
     Y = 2*sum(i=0,k-1, vecmax(imag(b^i*pos)));
     print1(X,",");
  );
  print();
  quit;
}






k=2;

digit_to_rot  = [0, 0, 1, 0, 0, 1, 2];
digit_permute_inv = [0, 4, 1, 5, 2, 6, 3];
digit_permute = [0, 2, 4, 6, 1, 3, 5];
digit_to_new_rot = matrix(3,7);
print(digit_to_new_rot);
{
  for(d=0,6,
     for(rot=0,2,
        my(p=d);
        for(j=1,rot, p=digit_permute[p+1]);
        new_rot = (rot+digit_to_rot[p+1]) % 3;
        digit_to_new_rot[rot+1,d+1] = new_rot;
     );
  );
  print("digit_to_new_rot");
  for(d=0,6,
     for(rot=0,2,
        print1(digit_to_new_rot[rot+1,d+1],", "));
     print());
  print(digit_to_new_rot);
  print();
}



z_to_low_digit(z) = 2*real(z) + 4*imag(z);
digit_to_pos = [0, 1, w, w^2, w^3, w^4, w^5];
vector(#digit_to_pos,i, my(z=digit_to_pos[i]); z_to_low_digit(z))
vector(#digit_to_pos,i, my(z=digit_to_pos[i]); z_to_low_digit(z) % 7)

digit_to_pos = [0, w^2, 1, w, w^4, w^3, w^5];
vector(#digit_to_pos,i, my(z=digit_to_pos[i]); z_to_low_digit(z) % 7)

\\                  0  1  2  3  4  5  6
digit_to_reverse = [1, 0, 0, 0, 0, 0, 1];

z_to_digits(z) =
{
  my(v = vector(k,i,
                my(d = z_to_low_digit(z) % 7);
                \\ print("z=",z," low ", d);
                z = (z - digit_to_pos[d+1]);
                \\ print("sub to "z);
                z /= b;
                d));
  if(z,return(-1));
  \\ my(rev=0);
  \\ forstep(i=#v,1, -1,
  \\         if(rev%2, v[i]=6-v[i]);
  \\         rev += digit_to_reverse[v[i]+1]);
  v;
}

vector(#digit_to_pos,i, my(z=digit_to_pos[i]); (3*imag(z) + real(z)) % 7)

z_to_digits(0)
print("z_to_digits(1) = ",z_to_digits(1));
z_to_digits(-1)
z_to_digits(-w)
z_to_digits(2)
z_to_digits(b)

{
  x_max=0;
  x_min=0;
  y_max=0;
  y_min=0;
  for(n=0,7^k-1,
     z = subst(Pol(apply((d)->digit_to_pos[d+1],digits(n,7))), 'x, b);
     \\ print("subst  "z);
     x_min = min(x_min,real(z));
     x_max = max(x_max,real(z));
     y_min = min(y_min,imag(z));
     y_max = max(y_max,imag(z)));
  print("extents X "x_min" "x_max"   Y "y_min" "y_max);
}

{
  x_max=0;
  y_max=0;
  for(i=1,k-1,
     my(v = vector(6,d, b^i*w^d));
     y_max += vecmax(apply(imag,v));
     x_max += vecmax(apply(real,v)));
  x_min=-x_max;
  y_min=-y_min;
  print("extents X "x_min" "x_max"   Y "y_min" "y_max);
}

{
  x_max = sum(i=0,k-1,vecmax(apply(real,vector(6,d, b^i*w^d))));
  y_max = sum(i=0,k-1,vecmax(apply(imag,vector(6,d, b^i*w^d))));
  x_min=-x_max;
  y_min=-y_min;
  print("extents X "x_min" "x_max"   Y "y_min" "y_max);
}
{
  x_max = sum(i=0,k-1,vecmax(real(vector(6,d, b^i*w^d))));
  y_max = sum(i=0,k-1,vecmax(imag(vector(6,d, b^i*w^d))));
  x_min=-x_max;
  y_min=-y_min;
  print("extents X "x_min" "x_max"   Y "y_min" "y_max);
}

\\               0  1  2  3  4  5  6
digit_to_rot  = [0, 0, 1, 0, 0, 1, 2];
digit_permute_inv = [0, 4, 1, 5, 2, 6, 3];
digit_permute = [0, 2, 4, 6, 1, 3, 5];
small = Vecsmall([1, 3, 5, 7, 2, 4, 6]);
small*small
\\               1    2      3   4    5   6  7
small_to_rot  = [0, "/ ", "__", 0, " \\", 1, 2];

print("permute twice ", vector(7,d, digit_permute[digit_permute[d]+1]));

perform_rotation(v) =
{
  \\ high to low
  my(rot = 0);
  forstep(i=#v,1, -1,
         rot = digit_to_new_rot[rot+1,v[i]+1];
  );
  return(rot);

  \\ low to high
  my(rot = 0);
  for(i=1,#v,
     rot = digit_to_new_rot[rot+1,v[i]+1];
  );
  return(rot);

}
{
  for(n=0,7^2-1,
     my(v=digits(n,7));
     my(h = perform_rotation(v));
     my(l = perform_rotation(Vecrev(v)));
     if(l!=h, print(v," h=",h," l=",l));
     );
}
{
  for(n=0,7^2-1,
     my(v=digits(n,7));
     \\ print1(perform_rotation(v));
     print(v,"   ",perform_rotation(v));
     );
  print();
}
print(perform_rotation([0,6,2]))
quit

rot_to_chars = ["__", " \\", "/ "];
{
  forstep(y=2*y_max,-2*y_max, -1,
         if(y%2,print1("|"));
         for(x=-ceil(x_max),ceil(x_max),
            my(v = z_to_digits(x+(y%2)/2 + y/2*sqrt3i));
            if(v==-1, print1(".."); next());

            \\ my(d = prod(i=1,#v,small^digit_to_rot[v[i]+1],small)[2]);
            \\ print1(small_to_rot[d]);

            my(rot = perform_rotation(v));
            print1(rot_to_chars[(rot%3)+1]);

            \\ my(rot = 0);
            \\ forstep(i=#v,1, -1,
            \\        my(d = v[i]);
            \\        for(j=1,rot, d=digit_permute[d+1]);
            \\        rot += digit_to_rot[d+1]);
            \\ print1(rot_to_chars[(rot%3)+1]);

               \\ print1(v[1]," ");
               \\print1(rot);
         );
         print());
}



















quit
default(strictargs,1)
w = quadgen(-3); \\ sixth root of unity e^(I*Pi/3)

digit_to_pos = [0, 1, w, w^2, w^3, w^4, w^5];
vector(#digit_to_pos,i, my(z=digit_to_pos[i]); (3*imag(z) + real(z)) % 7)

digit_to_pos = [0, 1, w^2, w, w^4, w^5, w^3];
vector(#digit_to_pos,i, my(z=digit_to_pos[i]); (3*imag(z) + real(z)) % 7)

k=2;
z_to_digits(z) =
{
  my(v = vector(k,i,
                my(d = (3*imag(z) + real(z)) % 7);
                z -= digit_to_pos[d+1];
                d));
  if(z,-1,v);
}

vector(#digit_to_pos,i, my(z=digit_to_pos[i]); (3*imag(z) + real(z)) % 7)

z_to_digits(0)
z_to_digits(1)
z_to_digits(-1)
z_to_digits(-w)

\\              0  1  2  3  4  5  6
digit_to_rot = [0, 1, 0, 0, 0, 2, 1];

rot_to_chars = ["__"," \\","/ "];
{
  forstep(y=2,-2, -1,
         if(y%2,print1("|"));
         for(x=-2,5,
            my(v = z_to_digits(x+floor(x/2) + y*w));
            if(v==-1,print1(".."),
               my(rot = sum(i=1,#v, digit_to_rot[v[i]+1]));
               \\ print1(rot_to_chars[(rot%3)+1]);
                print1(v[1]," ");
               \\print1(rot);
              ));
         print());
}


quit
for(k=0,3,\\
);
  char = Vecsmall("__.\\/...");
      printf("%c",char[2*r+o+1])

\\-----------------------------------------------------------------------------
\\ working
for(k=0,3,\
{
  sqrt3i = quadgen(-12);  \\ sqrt(-3)
  w = 1/2 + 1/2*sqrt3i;   \\ sixth root of unity
  b = 2 + w;

  pos  = [0, w^2, 1, w, w^4, w^3, w^5];
  rot  = [0, 0, 1, 0, 0, 1, 2];
  perm = Vecsmall([1,3,5,7,2,4,6]);
  char = ["_","_",  " ","\\",  "/"," ",  " "," "];

  \\ extents
  X = 2*sum(i=0,k-1, vecmax(real(b^i*pos)));
  Y = 2*sum(i=0,k-1, vecmax(imag(b^i*pos)));

  for(y = -Y, Y,
     for(x = -X+(k>0), X+(k<3),
  \\ for(y = -Y, -Y+10,
  \\    for(x = -30, 170,
        o = (x+y)%2;
        z = (x-o - y*sqrt3i)/2;
        v = vector(k,i,
                   d = (2*real(z) + 4*imag(z)) % 7 + 1;
                   z = (z - pos[d]) / b;
                   d);
        if(z, r = 3,
           r = 0;
           forstep(i=#v,1, -1,
                  d = (perm^r)[v[i]];
                  r = (r + rot[d]) % 3));
        print1(char[2*r+o+1]));
     print())
}\
);
quit



\\-----------------------------------------------------------------------------
\\ working
{
  sqrt3i = quadgen(-12);  \\ sqrt(-3)
  w = 1/2 + 1/2*sqrt3i;   \\ sixth root of unity
  b = 2 + w;

  pos  = [0, w^2, 1, w, w^4, w^3, w^5];
  rot  = [0, 0, 1, 0, 0, 1, 2];
  perm = [1,2,3,4,5,6,7;
          1,3,5,7,2,4,6;
          1,5,2,6,3,7,4];
  chars = ["__", ".\\", "/ ",".."];

  \\ extents
  X = ceil(sum(i=0,k-1, vecmax(real(b^i*pos))));
  Y = 2*   sum(i=0,k-1, vecmax(imag(b^i*pos)));

  for(y = -Y, Y,
     if(y%2,print1(" "));
     for(x = -X, X-(y%2),
        z = x+(y%2)/2 - y/2*sqrt3i;
        v = vector(k,i,
                   d = (2*real(z) + 4*imag(z)) % 7 + 1;
                   z = (z - pos[d]) / b;
                   d);
        if(z, r = 3,
           r = 0;
           forstep(i=#v,1, -1,
                  d = perm[r+1,v[i]];
                  r = (r + rot[d]) % 3));
        print1(chars[r+1]));
     print())
}

quit

\\-----------------------------------------------------------------------------
{
  sqrt3i = quadgen(-12);
  w = 1/2 + 1/2*sqrt3i;
  b = 2 + w;
  x_max = sum(i=0,k-1,vecmax(apply(real,vector(6,d, b^i*w^d))));
  y_max = sum(i=0,k-1,vecmax(apply(imag,vector(6,d, b^i*w^d))));
  digit_to_pos  = [0, w^2, 1, w, w^4, w^3, w^5];
  digit_to_rot  = [0, 0, 1, 0, 0, 1, 2];
  digit_permute = [1,2,3,4,5,6,7; 1,3,5,7,2,4,6; 1,5,2,6,3,7,4];
  rot_to_chars = ["__", " \\", "/ "];

  forstep(y=2*y_max,-2*y_max, -1,
         if(y%2,print1("|"));
         for(x=-ceil(x_max),ceil(x_max),
            z = x+(y%2)/2 + y/2*sqrt3i;
            v = vector(k,i,
                       d = (2*real(z) + 4*imag(z)) % 7 + 1;
                       z = (z - digit_to_pos[d]) / b;
                       d);
            if(z, print1(".."); next());

            rot = 0;
            forstep(i=#v,1, -1,
                   d = digit_permute[rot+1,v[i]];
                   rot = (rot + digit_to_rot[d]) % 3);
            print1(rot_to_chars[rot%3+1]));
         print());
}


  \\ M = sum(i=0,k-1,
  \\           v = vector(6,d, b^i*w^d);
  \\           vecmax(real(v)) + vecmax(imag(v))*S);
  \\ X = ceil(real(M));
  \\ Y = 2*imag(M);


