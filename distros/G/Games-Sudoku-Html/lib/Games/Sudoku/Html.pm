package Games::Sudoku::Html;

use strict;
use warnings;

our $VERSION = '0.07';

use HTML::Template;

our @ISA = qw( Exporter );
our @EXPORT_OK = qw( sudoku_html_page );

###########################################################

sub sudoku_html_page {
  my ($puzzles) = @_;

  my $template = HTML::Template->new(
    scalarref         => page(),
    loop_context_vars => 1,
  );

  my @puzzle_list = map {
    my $puzzle_string = $_->[0];
    $puzzle_string =~ s/[^\.1-9]/\./g;
    my $puzzle_parameter = $puzzle_string;
    $puzzle_parameter =~ s/\./0/g;
    {
      strPuzzle  => $puzzle_string,
      properties => $_->[1],
      paramBoard => $puzzle_parameter,
    }
  } @$puzzles;

  $template->param(
    puzzleCount => ($#puzzle_list + 1),
    puzzles     => \@puzzle_list,
    grid        => [({sudokuBand => [({sudokuRow => [(+{}) x 9]}) x 3]}) x 3]
  );

  return $template->output()
}

sub page {
  return \<<'PAGE_TEMPLATE'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Created with Perl-written sudoku generator Games::Sudoku::PatternSolver, available from https://metacpan.org/pod/Games::Sudoku::PatternSolver">

    <title><TMPL_VAR puzzleCount> Sudoku generated with PatternSolver</title>
    <style>
      #puzzlelist {
        font-family: arial, sans-serif;
        border-collapse: collapse;
      }

      #puzzlelist td, th {
        border: 1px solid #dddddd;
        text-align: left;
        padding: 8px;
      }

      #puzzlelist tr:nth-child(even) {
        background-color: #dddddd;
      }

      .gridstring {
        user-select: all;
      }
    </style>
  </head>
  <body>

    <script>
      $ = function(id) {
        return document.getElementById(id);
      }

      /* timer display */
      var timerVar;
      var min = '00';
      var sec = 0;

      function myTimer() {
        sec++;
        if (sec == 60) {
          sec = 0;
          min++;
          if (min < 10) {
            min = '0'+parseInt(min);
          }
        }
        if (sec < 10) {
          sec = '0'+sec;
        }
        $('timer').innerHTML = min+':'+sec;
      }

      var hide = function(e, id) {
        e.stopPropagation();
        e.preventDefault();
        $(id).style.display = 'none';
        if (timerVar) clearInterval(timerVar);
      }
    </script>
    
    <h2><TMPL_VAR puzzleCount> Sudoku generated with PatternSolver</h2>

    <p>Playing it on <a href="https://metacpan.org/author/GRANTM" target="_blank">Grant McLean&apos;s</a> web site offers thorough step-by-step help and a well-founded, 
    much better difficulty rating (after a click on the light bulb).<br/>
    *However, playing puzzles with less than 8 different givens on sudokuexchenge, produces a warning and may even bring the javascript hint feature to crash.</p>
    <p>The cursor can be moved around with the arrow keys, a stepwise undo is achieved with either escape or the backspace key.</p>

    <table id="puzzlelist">
      <tr>
        <th>#</th>
        <th>Puzzle string</th>
        <th>Properties</th>
        <th>Play it</th>
      </tr>
      <TMPL_LOOP puzzles><tr id="row-<TMPL_VAR __counter__>">
        <td><TMPL_VAR __counter__></td>
        <td class="gridstring"><TMPL_VAR strPuzzle></td>
        <td><TMPL_VAR properties ESCAPE="html"></td>
        <td><a href="#" onclick="play(event, 'row-<TMPL_VAR __counter__>')">open here</a>, <a href="https://www.sudokuexchange.com/play/?s=<TMPL_VAR paramBoard>" target="_blank">play online</a></td>
      </tr></TMPL_LOOP>
    </table>

    <div class="popup" id="popup1">
      <div id="popup1header" style="text-align:center;"><span id="timer" style="float:left;"></span><span id="puzzleid">Click here to move</span>&nbsp;&nbsp;&nbsp;&nbsp;<a href="#" onclick="continueOnline(event)">continue online</a><a href="#" onclick="hide(event, 'popup1')" style="float: right;">close</a></div>

      <script type="text/javascript">
        /* partially based on Spreadsheet::HTML::Presets::Sudoku, Copyright 2017 Jeff Anderson */

        var MATRIX;
        var STEPS;
        var fillingivens = function(rowid, grid, playable) {
          var board = $(rowid).querySelector('.gridstring').textContent;
          var cells = grid.getElementsByTagName('td');
          if (playable) {
            MATRIX = new Array();
            STEPS = new Array();
            $('puzzleid').textContent = '# ' + rowid.match( /row-(\d+)/ )[1];
          }
          var i = 0;
          for (var r = 0; r < 9; r++) {
            var row = new Array();
            for (var c = 0; c < 9; c++) {
              var char = board.charAt(i);
              var cell = cells[i];
              cell.innerHTML = '';

              if (char == '.') {
                char = '';
                if (playable) {
                  const input = document.createElement('input');
                  input.setAttribute('id', 'input-' + r + '-' + c);
                  input.setAttribute('class', 'sudokuinput');
                  input.setAttribute('type', 'text');
                  input.setAttribute('size', '1');
                  input.setAttribute('maxLength', '1');
                  cell.appendChild(input);
                }
              } else {
                cell.textContent = char;
              }
              row.push( char ); 
              i++;
            }
            if (playable) {
              MATRIX.push( row );
            }
          }
        }

        function inputByCoords(row, col) {
          var element = document.getElementById('input-'+row+'-'+col);
          if (typeof(element) != 'undefined' && element != null) return element;

          return false;
        }

        function puzzlecomplete() {
          for (var r = 0; r < 9; r++) {
            for (var c = 0; c < 9; c++) {
              if (! MATRIX[r][c]) return false;
            }
          }
          return true;
        }

        // reverse input stepwise if ESC gets pressed
        document.getElementById('popup1').addEventListener('keydown', function (event) {
          var key = event.key;
          if (key == 'Escape' || key == 'Backspace') {
            var target = STEPS.pop();
            if (! target) return 0;         

            var targetid = target.id;
            var result = targetid.match(/input-(\d)-(\d)/);

            target.value = '';
            MATRIX[result[1]][result[2]] = '';
          }
        });
        var play = function(e, rowid) {
          e = e || window.event;
          e.preventDefault();
          if (timerVar) clearInterval(timerVar);

          fillingivens(rowid, $('sudoku'), true);
          $('popup1').style.display ='block';

          var inputs = $('sudoku').getElementsByClassName('sudokuinput');
          for (var i=0; i<inputs.length; i++) {
            var input = inputs[i];

            input.addEventListener('keydown', function (event) {
              var matches = this.id.match( /(\d+)-(\d+)/ );
              var id_r = matches[1];
              var id_c = matches[2];

              var key = event.key;
              var target;

              if (key == 'ArrowRight') {
                var c = parseInt(id_c) + 1;
                while ((! target) && (c != id_c)) {
                  if (c > 8) c = 0;
                  target = inputByCoords(id_r, c);
                  c++;
                }
              } else if (key == 'ArrowDown') {
                var r = parseInt(id_r) + 1;
                while ((! target) && (r != id_r)) {
                  if (r > 8) r = 0;
                  target = inputByCoords(r, id_c);
                  r++;
                }
              } else if (key == 'ArrowLeft') {
                var c = parseInt(id_c) - 1;
                while ((! target) && (c != id_c)) {
                  if (c < 0) c = 8;
                  target = inputByCoords(id_r, c);
                  c--;
                }
              } else if (key == 'ArrowUp') {
                var r = parseInt(id_r) - 1;
                while ((! target) && (r != id_r)) {
                  if (r < 0) r = 8;
                  target = inputByCoords(r, id_c);
                  r--;
                }
              } else {
                return;
              }

              if (target) {
                target.focus();
                target.setSelectionRange(1, 1);
              }
            });

            input.addEventListener('keyup', function (event) { 
              this.value = this.value.replace( /[^1-9]/g, '' ).slice(0, 1);
              var matches = this.id.match( /(\d+)-(\d+)/ );
              var id_r = matches[1];
              var id_c = matches[2];

              if (MATRIX[id_r][id_c] == this.value) return;

              if (this.value.length == 1) {              
                var boxstart_r = parseInt(id_r / 3) * 3;
                var boxstart_c = parseInt(id_c / 3) * 3;

                var seen= {};

                for (var r = boxstart_r; r < boxstart_r + 3; r++) {
                  for (var c = boxstart_c; c < boxstart_c + 3; c++) {
                    seen[ MATRIX[r][c] ] = true;
                  }
                }

                for (var i = 0; i < 9; i++) {
                  seen[ MATRIX[id_r][i] ] = true;
                  seen[ MATRIX[i][id_c] ] = true;
                }

                if (seen[this.value]) {
                  this.value = '';
                }

                if (MATRIX[id_r][id_c] != this.value) {
                  MATRIX[id_r][id_c] = this.value;
                  if (this.value) {
                    STEPS.push( this );
                  }
                }

                if (puzzlecomplete()) {
                  $('timer').style.color = 'green';
                  if (timerVar) {
                    clearInterval(timerVar);
                    timerVar = null;
                  }
                }
              }
            });
          }

          min = '00';
          sec = 0;
          $('timer').style.color = '';
          $('timer').innerHTML = '00:00';
          timerVar = setInterval(myTimer, 1000);
        }

        /* draggable code from w3schools.com */
        dragElement(document.getElementById('popup1'));

        function dragElement(elmnt) {
          var pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;

          if (document.getElementById(elmnt.id + 'header')) {
            document.getElementById(elmnt.id + 'header').onmousedown = dragMouseDown;
          } else {
            elmnt.onmousedown = dragMouseDown;
          }

          function dragMouseDown(e) {
            e = e || window.event;
            if (e.target !== e.currentTarget) {
              return;
            }
            e.preventDefault();
            // get the mouse cursor position at start
            pos3 = e.clientX;
            pos4 = e.clientY;
            document.onmouseup = closeDragElement;
            document.onmousemove = elementDrag;
          }

          function elementDrag(e) {
            e = e || window.event;
            e.preventDefault();
            pos1 = pos3 - e.clientX;
            pos2 = pos4 - e.clientY;
            pos3 = e.clientX;
            pos4 = e.clientY;
            elmnt.style.top = (elmnt.offsetTop - pos2) + "px";
            elmnt.style.left = (elmnt.offsetLeft - pos1) + "px";
          }

          function closeDragElement() {
            // stop moving when button is released
            document.onmouseup = null;
            document.onmousemove = null;
          }
        }

        function continueOnline(e) {
          e = e || window.event;
          e.preventDefault();
          var url = 'https://www.sudokuexchange.com/play/?s=';
          for (var r = 0; r < 9; r++) {
            var row = new Array();
            for (var c = 0; c < 9; c++) {
              url = url + (MATRIX[r][c] || '0');
            }
          }
          window.open(url);
        }
      </script>

      <style>
        .popup {
          padding: 10px;
          background: #fff;
          z-index: 20;
        }

        #popup1 {
          -webkit-box-shadow:  0px 0px 0px 9999px rgba(0, 0, 0, 0.5);
          box-shadow:  0px 0px 0px 9999px rgba(0, 0, 0, 0.5);
          display: none;
          position: fixed;
          left: 65%;
          top: 10%;
        }
        #popup1header {
          padding: 10px;
          cursor: move;
          z-index: 10;
          background-color: #aaa;
          color: #fff;
        }
        #popup1 table {
          border-collapse: collapse;
          font-family: arial, sans-serif;
          font-weight: bold;
          font-size: xx-large;
          text-align: center;
        }
        #popup1 colgroup {
          border: solid medium;
        }
        #popup1 tbody {
          border: solid medium;
        }
        #popup1 td {
          border: solid thin;
          width: 50px;
          height: 50px;
          color: #aaa;
        }
        #popup1 input {
          border: 0px;
          max-width: 35px;
          font-family: arial, sans-serif;
          font-weight: bold;
          font-size: xx-large;
          text-align: center;
        }
      </style>

      <table id="sudoku">
        <colgroup><col/><col/><col/></colgroup>
        <colgroup><col/><col/><col/></colgroup>
        <colgroup><col/><col/><col/></colgroup>
        <TMPL_LOOP grid><tbody>
          <TMPL_LOOP sudokuBand><tr><TMPL_LOOP sudokuRow><td/></TMPL_LOOP></tr>
        </TMPL_LOOP></tbody></TMPL_LOOP>
      </table>
    </div>  

    <div class="popup" id="popup2">
      <script type="text/javascript">
        const puzzlecells = document.querySelectorAll('.gridstring');
        puzzlecells.forEach(cell => {
          cell.addEventListener('mouseenter', function (e) {showgrid(e, cell.parentElement.id)});
          cell.addEventListener('mouseleave', function (e) {$('popup2').style.display = 'none';});
        });

        function showgrid(e, rowid) {
          e = e || window.event;
          if (e.target !== e.currentTarget) {
            return;
          }
          e.preventDefault();
          fillingivens(rowid, $('grid'), false);
          $('popup2').style.display = 'block';
        }
      </script>
      <style>
        #popup2 {
          padding: 3px;
          background: #fff;
          /* -webkit-box-shadow:  0px 0px 0px 9999px rgba(0, 0, 0, 0.5);
          box-shadow:  0px 0px 0px 9999px rgba(0, 0, 0, 0.5); */
          display: none;
          position: fixed;
          left: 35%;
          top: 10%;
          z-index: 15;
        }
        #popup2 table {
          border-collapse: collapse;
          font-family: arial, sans-serif;
          font-weight: bold;
          font-size: large;
          text-align: center;
        }
        #popup2 colgroup {
          border: solid 2px;
        }
        #popup2 tbody {
          border: solid 2px;
        }
        #popup2 td {
          border: solid thin;
          width: 20px;
          height: 20px;
          color: #aaa;
        }
      </style>

      <table id="grid">
        <colgroup><col/><col/><col/></colgroup>
        <colgroup><col/><col/><col/></colgroup>
        <colgroup><col/><col/><col/></colgroup>
        <TMPL_LOOP grid><tbody>
          <TMPL_LOOP sudokuBand><tr><TMPL_LOOP sudokuRow><td/></TMPL_LOOP></tr>
        </TMPL_LOOP></tbody></TMPL_LOOP>
      </table>
    </div>  
  </body>
</html>
PAGE_TEMPLATE
}

1;

=encoding UTF-8

=head1 NAME

Games::Sudoku::Html - Visualize and play collections of standard 9x9 Sudoku in your browser.

=head1 DESCRIPTION

A very simple Module which converts an array with sudoku puzzles into a static html page.
Thus, long lists of your digital (text format) sudoku can be revised and played in a browser.

Currently only the standard sudoku are supported, no variants.

=head1 SYNOPSIS

  use Games::Sudoku::PatternSolver::Html qw( sudoku_html_page );

  @list = ( [$sudokuHash->{strPuzzle}, "<descriptive text with properties, rating, source, etc.>"], ... )
  $htmlpage = sudoku_html_page( \@list )

=head2 sudoku_html_page( arrayref ) 

Returns a scalar with a static html page, playable in a browser

Its only parameter is an array of arrays, each entry consisting of 2 items: an 81 character puzzle string and any descriptive text for the puzzle.
You may put as many puzzles as you like into the array, they can all be played from the one, javascript-driven static page.
Can also be used to play lists with numerous 9x9 Sudoku from various sources.

=head1 SCRIPTS

=head2 sudoku2html

After installation of Games::Sudoku::Html this command line script should be in your path.
Flexible input options are available. Invoke C<E<gt>sudoku2html -h> for details.

=head1 DEPENDENCIES

=over 4

=item * L<HTML::Template>

=back

=head1 SEE ALSO

L<Games::Sudoku::PatternSolver::Generator>, L<Games::Sudoku::Pdf>

=head1 COPYRIGHT AND LICENSE

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

This software is copyright (c) 2024 by Steffen Heinrich

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
