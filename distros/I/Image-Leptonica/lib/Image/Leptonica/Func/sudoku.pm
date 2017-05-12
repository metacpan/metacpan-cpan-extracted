package Image::Leptonica::Func::sudoku;
$Image::Leptonica::Func::sudoku::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::sudoku

=head1 VERSION

version 0.04

=head1 C<sudoku.c>

  sudoku.c

      Solve a sudoku by brute force search

      Read input data from file or string
          l_int32         *sudokuReadFile()
          l_int32         *sudokuReadString()

      Create/destroy
          L_SUDOKU        *sudokuCreate()
          void             sudokuDestroy()

      Solve the puzzle
          l_int32          sudokuSolve()
          static l_int32   sudokuValidState()
          static l_int32   sudokuNewGuess()
          static l_int32   sudokuTestState()

      Test for uniqueness
          l_int32          sudokuTestUniqueness()
          static l_int32   sudokuCompareState()
          static l_int32  *sudokuRotateArray()

      Generation
          L_SUDOKU        *sudokuGenerate()

      Output
          l_int32          sudokuOutput()

  Solving sudokus is a somewhat addictive pastime.  The rules are
  simple but it takes just enough concentration to make it rewarding
  when you find a number.  And you get 50 to 60 such rewards each time
  you complete one.  The downside is that you could have been doing
  something more creative, like keying out a new plant, staining
  the deck, or even writing a computer program to discourage your
  wife from doing sudokus.

  My original plan for the sudoku solver was somewhat grandiose.
  The program would model the way a person solves the problem.
  It would examine each empty position and determine how many possible
  numbers could fit.  The empty positions would be entered in a priority
  queue keyed on the number of possible numbers that could fit.
  If there existed a position where only a single number would work,
  it would greedily take it.  Otherwise it would consider a
  positions that could accept two and make a guess, with backtracking
  if an impossible state were reached.  And so on.

  Then one of my colleagues announced she had solved the problem
  by brute force and it was fast.  At that point the original plan was
  dead in the water, because the two top requirements for a leptonica
  algorithm are (1) as simple as possible and (2) fast.  The brute
  force approach starts at the UL corner, and in succession at each
  blank position it finds the first valid number (testing in
  sequence from 1 to 9).  When no number will fit a blank position
  it backtracks, choosing the next valid number in the previous
  blank position.

  This is an inefficient method for pruning the space of solutions
  (imagine backtracking from the LR corner back to the UL corner
  and starting over with a new guess), but it nevertheless gets
  the job done quickly.  I have made no effort to optimize
  it, because it is fast: a 5-star (highest difficulty) sudoku might
  require a million guesses and take 0.05 sec.  (This BF implementation
  does about 20M guesses/sec at 3 GHz.)

  Proving uniqueness of a sudoku solution is tricker than finding
  a solution (or showing that no solution exists).  A good indication
  that a solution is unique is if we get the same result solving
  by brute force when the puzzle is also rotated by 90, 180 and 270
  degrees.  If there are multiple solutions, it seems unlikely
  that you would get the same solution four times in a row, using a
  brute force method that increments guesses and scans LR/TB.
  The function sudokuTestUniqueness() does this.

  And given a function that can determine uniqueness, it is
  easy to generate valid sudokus.  We provide sudokuGenerate(),
  which starts with some valid initial solution, and randomly
  removes numbers, stopping either when a minimum number of non-zero
  elements are left, or when it becomes difficult to remove another
  element without destroying the uniqueness of the solution.

  For further reading, see the Wikipedia articles:
     (1) http://en.wikipedia.org/wiki/Algorithmics_of_sudoku
     (2) http://en.wikipedia.org/wiki/Sudoku

  How many 9x9 sudokus are there?  Here are the numbers.
   - From ref(1), there are about 6 x 10^27 "latin squares", where
     each row and column has all 9 digits.
   - There are 7.2 x 10^21 actual solutions, having the added
     constraint in each of the 9 3x3 squares.  (The constraint
     reduced the number by the fraction 1.2 x 10^(-6).)
   - There are a mere 5.5 billion essentially different solutions (EDS),
     when symmetries (rotation, reflection, permutation and relabelling)
     are removed.
   - Thus there are 1.3 x 10^12 solutions that can be derived by
     symmetry from each EDS.  Can we account for these?
   - Sort-of.  From an EDS, you can derive (3!)^8 = 1.7 million solutions
     by simply permuting rows and columns.  (Do you see why it is
     not (3!)^6 ?)
   - Also from an EDS, you can derive 9! solutions by relabelling,
     and 4 solutions by rotation, for a total of 1.45 million solutions
     by relabelling and rotation.  Then taking the product, by symmetry
     we can derive 1.7M x 1.45M = 2.45 trillion solutions from each EDS.
     (Something is off by about a factor of 2 -- close enough.)

  Another interesting fact is that there are apparently 48K EDS sudokus
  (with unique solutions) that have only 17 givens.  No sudokus are known
  with less than 17, but there exists no proof that this is the minimum.

=head1 FUNCTIONS

=head2 sudokuCreate

L_SUDOKU * sudokuCreate ( l_int32 *array )

  sudokuCreate()

      Input:  array (of 81 numbers, 9 rows of 9 numbers each)
      Return: l_sudoku, or null on error

  Notes:
      (1) The input array has 0 for the unknown values, and 1-9
          for the known initial values.  It is generated from
          a file using sudokuReadInput(), which checks that the file
          data has 81 numbers in 9 rows.

=head2 sudokuDestroy

void sudokuDestroy ( L_SUDOKU **psud )

  sudokuDestroy()

      Input:  &l_sudoku (<to be nulled>)
      Return: void

=head2 sudokuGenerate

L_SUDOKU * sudokuGenerate ( l_int32 *array, l_int32 seed, l_int32 minelems, l_int32 maxtries )

  sudokuGenerate()

      Input:  array (of 81 numbers, 9 rows of 9 numbers each)
              seed (random number)
              minelems (min non-zero elements allowed; <= 80)
              maxtries (max tries to remove a number and get a valid sudoku)
      Return: l_sudoku, or null on error

  Notes:
      (1) This is a brute force generator.  It starts with a completed
          sudoku solution and, by removing elements (setting them to 0),
          generates a valid (unique) sudoku initial condition.
      (2) The process stops when either @minelems, the minimum
          number of non-zero elements, is reached, or when the
          number of attempts to remove the next element exceeds @maxtries.
      (3) No sudoku is known with less than 17 nonzero elements.

=head2 sudokuOutput

l_int32 sudokuOutput ( L_SUDOKU *sud, l_int32 arraytype )

  sudokuOutput()

      Input:  l_sudoku (at any stage)
              arraytype (L_SUDOKU_INIT, L_SUDOKU_STATE)
      Return: void

  Notes:
      (1) Prints either the initial array or the current state
          of the solution.

=head2 sudokuReadFile

l_int32 * sudokuReadFile ( const char *filename )

  sudokuReadFile()

      Input:  filename (of formatted sudoku file)
      Return: array (of 81 numbers), or null on error

  Notes:
      (1) The file format has:
          * any number of comment lines beginning with '#'
          * a set of 9 lines, each having 9 digits (0-9) separated
            by a space

=head2 sudokuReadString

l_int32 * sudokuReadString ( const char *str )

  sudokuReadString()

      Input:  str (of input data)
      Return: array (of 81 numbers), or null on error

  Notes:
      (1) The string is formatted as 81 single digits, each separated
          by 81 spaces.

=head2 sudokuSolve

l_int32 sudokuSolve ( L_SUDOKU *sud )

  sudokuSolve()

      Input:  l_sudoku (starting in initial state)
      Return: 1 on success, 0 on failure to solve (note reversal of
              typical unix returns)

=head2 sudokuTestUniqueness

l_int32 sudokuTestUniqueness ( l_int32 *array, l_int32 *punique )

  sudokuTestUniqueness()

      Input:  array (of 81 numbers, 9 lines of 9 numbers each)
              &punique (<return> 1 if unique, 0 if not)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This applies the brute force method to all four 90 degree
          rotations.  If there is more than one solution, it is highly
          unlikely that all four results will be the same;
          consequently, if they are the same, the solution is
          most likely to be unique.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
