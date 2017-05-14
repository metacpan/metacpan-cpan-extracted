package Games::Rezrov::FontVectors;
# see spec section 16; vectors describing the character graphics
# of "font 3", used heavily in Beyond Zork.
#
# UNFINISHED!!!

use strict;

%Games::Rezrov::FontVectors::vecs = (
	       32 => [],
	       # space
	       
	       33 => [
		      [ 1,4 => 7,4],
		      [ 5,2 => 7,4],
		      [ 5,6 => 7,4],
		     ],
	       # left arrow
	       
	       34 => [
		      [ 7,4 => 1,4],
		      [ 3,2 => 1,4],
		      [ 3,6 => 1,4],
		     ],
	       # right arrow
	       
	       35 => [
		      [ 7,7 => 0,0 ],
		     ],
	       # line: lower left to upper right
	       
	       36 => [
		      [ 7,0 => 0,7 ],
		     ],
	       # line: upper left to lower right
	       
	       37 => [],
	       # blank
	       
	       38 => [
		      [0,4 => 7,4]
		     ],
	       # horizontal line
	       
	       39 => [
		      [0,3 => 7,3]
		     ],
	       # horizontal line
	       
	       40 => [
		      [3,0 => 3,7]
		     ],
	       # vertical line
	       
	       41 => [
		      [4,0 => 4,7]
		     ],
	       # vertical line
	       
	       42 => [
		      [0,3 => 7,3],
		      [3,3 => 3,0],
		     ],
	       
	       43 => [
		      [7,4 => 0,4],
		      [3,4 => 3,7],
		     ],
	       # junction: e,w,s
	       
	       44 => [
		      [3,0 => 3,7],
		      [3,4 => 0,4],
		     ],
	       # junction: n,s,e
	       
	       45 => [
		      [4,0 => 4,7],
		      [4,4 => 7,4],
		     ],
	       # junction: n,s,w
	       
	       46 => [
		      [4,0 => 4,4 => 0,4],
		     ],
	       # lower-left corner
	       
	       47 => [
		      [0,3 => 4,3 => 4,7],
		     ],
	       # upper-left corner
	       
	       48 => [
		      [7,3 => 3,3 => 3,7],
		     ],
	       # upper-right corner
	       
	       49 => [
		      [7,4 => 3,4 => 3,0],
		     ],
	       # lower-right corner
	       
	       50 => [
		      [4,0 => 4,4 => 0,4],
		      [4,4 => 7,7],
		     ],
	       # junction: n,e,sw
	       
	       51 => [
		      [ 7,0 => 4,3 => 0, 3],
		      [ 4,3 => 4,7],
		     ],
	       # junction: nw, e, s
	       
	       52 => [
		      [7,3 => 3,3 => 0,0],
		      [3,3 => 3,7],
		     ],
	       # junction: w,s,ne
	       
	       53 => [
		      [ 3,0 => 3,4 => 7,4],
		      [ 3,4 => 0,7],
		     ],
	       # junction: nw, e, s
	       
	       54 => [
		      ["R" => 0,0 => 7,7 ],
		     ],
	       # completely solid fill
	       
	       55 => [
		      ["R" => 0,0 => 7,4 ],
		     ],
	       # thick horizontal chunk, n-aligned
	       
	       
	       56 => [
		      ["R" => 0,3 => 7,7 ],
		     ],
	       # thick horizontal block, s-aligned
	       
	       57 => [
		      ["R" => 7,0 => 3,7 ],
		     ],
	       # thick vertical line, left-aligned
	       
	       58 => [
		      ["R" => 0,0 => 4,7 ],
		     ],
	       # thick vertical line, right-aligned
	       
	       59 => [
		      [ "R" => 7,3 => 0,7],
		      [ 3,3 => 3,0 ],
		     ],
	       # thick h chunk, s-aligned, line to N
	       
	       60 => [
		      [ "R" => 0,0 => 7,4 ],
		      [ 3,4 => 3,7],
		     ],
	       # thick H block aligned N with line to s
	       
	       61 => [
		      [ "R" => 3,0 => 7,7 ],
		      [ 0,4 => 7,4 ],
		     ],
	       # thick horizontal line, w-aligned, line to e
	       
	       62 => [
		      ["R" => 0,0 => 4,7 ],
		      [ 4,4 => 7,4 ],
		     ],
	       # thick H line, e-aligned, line to w
	       
	       
	       63 => [
		      [ "R" => 0,0 => 4,4 ],
		     ],
	       # small rectangle in ne
	       
	       64 => [
		      [ "R" => 0,3 => 4,7 ],
		     ],
	       # small rectangle in se
	       
	       65 => [
		      ["R" => 3,3 => 7,7 ],
		     ],
	       # small rectangle in sw
	       
	       66 => [
		      ["R" => 7,0 => 3,4 ],
		     ],
	       # small rectangle in ne
	       
	       67 => [
		      ["R" => 0,0 => 4,4 ],
		      [ 4,4 => 7,7],
		     ],
	       
	       68 => [
		      ["R" => 0,3 => 4,7 ],
		      [ 4,3 => 7,0 ]
		     ],
	       # small rectangle in se, line to ne
	       
	       69 => [
		      ["R" => 3,3 => 7,7 ],
		      [ 3,3 => 0,0 ],
		     ],
	       # small rectangle in sw, line to ne
	       
	       70 => [
		      ["R" => 7,0 => 3,4 ],
		      [3,4 => 0,7],
		     ],
	       # small rect in nw, line to se
	       
	       79 => [
		      [0,1 => 7,1],
			 [0,6 => 7,6],
			],
		  # 2 horizontal lines

		  80 => [
			 [ 0,1 => 7,1 => 7,6 => 0,6],
			],
		  # cutout

		  81 => [
			 [ "R" => 6,2 => 7,5],
			 [ 0,1 => 7,1],
			 [ 0,6 => 7,6],
			 ],

		  82 => [
			 [ "R" => 5,2 => 7,5],
			 [ 0,1 => 7,1],
			 [ 0,6 => 7,6],
			 ],

		  83 => [
			 [ "R" => 4,2 => 7,5],
			 [ 0,1 => 7,1],
			 [ 0,6 => 7,6],
			 ],

		  84 => [
			 [ "R" => 3,2 => 7,5],
			 [ 0,1 => 7,1],
			 [ 0,6 => 7,6],
			 ],

		  85 => [
			 [ "R" => 2,2 => 7,5],
			 [ 0,1 => 7,1],
			 [ 0,6 => 7,6],
			],

		  86 => [
			 [ 0,1 => 7,1],
			 [ 0,6 => 7,6],
			 [ "R" => 1,2 => 7,5],
			 ],
		  
		  87 => [
			 [ "R" => 0,1 => 7,6 ],
			],
		  # thick block

		  88 => [
			 [ 0,1 => 0,6],
			],
		  # v line, e-aligned
		  
		  89 => [
			 [7,1 => 7,6],
			],
		  # horizontal line, w-aligned

		  92 => [
			 [ 4,6 => 4,0 ],
			 [ "P" => 1,2 => 4,0 => 7,2],
			],

		  93 => [
			 [ 4,0 => 4,6 ],
			 [ "P" => 1,4 => 4,6 => 7,4],
			],
		  # down arrow

		 );

1;
