use IO::Prompt;

# The input is taken from the __PROMPT__ section below
#
# Hitting <return> immediately after the prompt will cause the next
# __PROMPT__ line to be typed in for you.
# Useful for pretending to type without bothering with the keyboard.
#
# Hitting any other key immediately after the prompt will put you into
# "smart typing" mode: the next __PROMPT__ line will be typed in
# for you, one letter for every key you hit (no matter what key you hit)
# Useful for pretending to type without looking at the keyboard.
#
# Hitting <escape> immediately after the prompt will escape from the
# automated input process and allow you to type whatever you like
#
# Because the __PROMPT__ section ends with a line containing only <ctrl>-D,
# input terminates when that line is reached. If the last line *didn't*
# contain the <ctrl>-D (or <ctrl>-Z if you prefer) then input would
# continue from the keyboard after all the __PROMPT__ lines were used
#

while (prompt -line, "\nNext line: ") {
    print "Input was: $_";
    while (<DATA>) {
        print "Datum was: $_";
        last;
    }
}

print "\n";
while (<DATA>) {
    print "Datum was: $_";
}

__DATA__
This is data line 1
This is data line 2
This is data line 3



This is data last line
__PROMPT__   
This is input line 1
This is input line 2

