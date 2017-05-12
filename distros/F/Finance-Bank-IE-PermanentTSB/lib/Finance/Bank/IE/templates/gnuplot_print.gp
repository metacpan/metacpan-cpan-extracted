# Gnuplot script to graph the balance
# Expected format for data is 2 columns:
#
# Date Balance
#
# Each column data is separated by space or tabulation
# Date should be in format dd/mm/yyyy

set title '[% ACCOUNT %]'
set xlabel 'Date';
set ylabel 'Balance';
set xdata time;
set timefmt "%d/%m/%Y";
set grid
set terminal png
set output "[% OUTPUT %]"
plot '[% FILENAME %]' using 1:2 title "[% TITLE %]" with linespoints;

set terminal wxt
replot

set terminal dumb
replot

pause -1 "Hit return to exit"
