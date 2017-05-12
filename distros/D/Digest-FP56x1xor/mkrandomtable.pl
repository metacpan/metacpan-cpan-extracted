#! /usr/bin/perl -w
#
#
# wget http://www.random.org/files/2007/2007-10-03.bin
# mkrandomtable.pl > random56x256.h
# This table must never change.
#
# From the FAQ:
# It's not just the software you'd need, but also three radios (or one, at any
# rate), which must be carefully adjusted to pick up atmospheric noise at the
# right volume. It's not completely trivial to set up.
# RANDOM.ORG uses radio receivers to pick up atmospheric noise, which is then
# used to generate random numbers. The radios are tuned between stations. A
# possible attack on the generator is therefore to broadcast on the frequencies
# that the RANDOM.ORG radios use in order to affect the generator. However,
# radio frequency attacks of this type would be difficult for a variety of
# reasons. First, the frequencies that the radios use are not published, so an
# attacker would have to broadcast across the entire FM band. Second, this is
# not an attack that can be launched from anywhere in the world, only
# reasonably close to the generator, meaning an attacker would have to be in
# Dublin. Third, if an attacker actually did succeed at broadcasting a very
# regular signal (e.g., a perfect sine wave) at the right frequency, then the
# RANDOM.ORG real-time statistics would pick up the drop in quality very
# rapidly.
# The RANDOM.ORG setup uses an array of radios that pick up atmospheric noise.
# Each radio generates approximately 3,000 bits per second. The random bits
# produced by the radios are used as the raw material for all the different
# generators you see on RANDOM.ORG 
# The generator doesn't produce a constant stream of numbers (...) but works in
# a kind of start-and-stop mode, depending on whether the numbers are needed or
# not. For this reason, there are periods of time (at least on most days) where
# the generator is not producing numbers.
#
# See also 
# http://www.random.org/analysis/dilbert.jpg
# http://imgs.xkcd.com/comics/random_number.png

open IN, "<2007-10-03.bin";

for my $i (0..255)
  {
    my $col = $i % 4;

    print "0x";
    for (0..6)
      {
        printf "%02x", ord getc(IN);
      }

    # Add suffix LL to assure the compiler grocks 64bit per int.
    # If you still get many warnings: 
    # "integer constant is too large for ‘long’ type'" then your
    # compiler cannot do 64bit at all. Try a recent GCC.
    print "LL";		
    print "," unless $i == 255;
    print $col==3 ? "\n" : ' ';
  }
close IN;
