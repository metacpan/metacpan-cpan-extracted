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


\\ This is a bit of fun drawing the flowsnake in ascii art for
\\ http://codegolf.stackexchange.com/questions/50521/ascii-art-of-the-day-2-flow-snakes
\\                  ____                   
\\             ____ \__ \                  
\\             \__ \__/ / __               
\\             __/ ____ \ \ \    ____      
\\            / __ \__ \ \/ / __ \__ \     
\\       ____ \ \ \__/ / __ \/ / __/ / __  
\\  ____ \__ \ \/ ____ \/ / __/ / __ \ \ \ 
\\  \__ \__/ / __ \__ \__/ / __ \ \ \ \/   
\\  __/ ____ \ \ \__/ ____ \ \ \ \/ / __   
\\ / __ \__ \ \/ ____ \__ \ \/ / __ \/ /   
\\ \ \ \__/ / __ \__ \__/ / __ \ \ \__/    
\\  \/ ____ \/ / __/ ____ \ \ \ \/ ____    
\\     \__ \__/ / __ \__ \ \/ / __ \__ \   
\\     __/ ____ \ \ \__/ / __ \/ / __/ / __
\\    / __ \__ \ \/ ____ \/ / __/ / __ \/ /
\\    \/ / __/ / __ \__ \__/ / __ \/ / __/ 
\\    __/ / __ \ \ \__/ ____ \ \ \__/ / __ 
\\   / __ \ \ \ \/ ____ \__ \ \/ ____ \/ / 
\\   \ \ \ \/ / __ \__ \__/ / __ \__ \__/  
\\    \/ / __ \/ / __/ ____ \ \ \__/       
\\       \ \ \__/ / __ \__ \ \/            
\\        \/      \ \ \__/ / __            
\\                 \/ ____ \/ /            
\\                    \__ \__/             
\\                    __/                  
\\
\\ Each hexagon of the flowsnake is 2 characters and a line segment does
\\ across its corners either by __, / or \.  The loop goes over x,y and
\\ calculates which of these to show at each location.  Only moderate
\\ attempts at minimizing.
\\
\\ The code expresses a complex number z in base b=2+w and digits 0, 1, w^2,
\\ ..., w^5, where w=e^(2pi/6) sixth root of unity.  Those digits are kept
\\ just as a distinguishing 1 to 7 then taken high to low for net rotation.
\\
\\ This is in the style of Ed Shouten's http://80386.nl/projects/flowsnake/
\\ (xytoi) but only for net rotation, not making digits into an "N" index
\\ along the path.
\\
\\ The extents calculated are relative to an origin 0 at the centre of the
\\ shape (not the start of the curve as in Math::PlanePath::Flowsnake).  The
\\ vecmin()/vecmax() calculate with centre of the little hexagons.  Segments
\\ other than the start and end are always / or \ and so go only to that
\\ centre.  But if the curve start or end are the maximum or minimum then
\\ they are the whole hexagon so a +1 is needed.  This only occurs for k=0
\\ for X minimum and k<3 for the X maximum.
\\
\\ Pari has "quads" like sqrt(-3) builtin but the same can be done with real
\\ and imaginary parts separately.


k=3;
{
  S = quadgen(-12);  \\ sqrt(-3)
  w = (1 + S)/2;     \\ sixth root of unity
  b = 2 + w;         \\ base

  \\ base b low digit position under 2*Re+4*Im mod 7 index
  P = [0, w^2, 1, w, w^4, w^3, w^5];
  \\ rotation state table
  T = 7*[0,0,1,0,0,1,2, 1,2,1,0,1,1,2, 2,2,2,0,0,1,2];
  C = ["_","_",  " ","\\",  "/"," "];

  \\ extents
  X = 2*sum(i=0,k-1, vecmax(real(b^i*P)));
  Y = 2*sum(i=0,k-1, vecmax(imag(b^i*P)));

  for(y = -Y, Y,
     for(x = -X+!!k, X+(k<3),  \\ adjusted when endpoint is X limit
        z = (x- (o = (x+y)%2) - y*S)/2;
        v = vector(k,i,
                   z = (z - P[ d = (2*real(z) + 4*imag(z)) % 7 + 1 ])/b;
                   d);
        print1( C[if(z,3,
                     r = 0;
                     forstep(i=#v,1, -1, r = T[r+v[i]];);
                     r%5 + o + 1)]) );   \\ r=0,7,14 mod 5 is 0,2,4
     print())
}
