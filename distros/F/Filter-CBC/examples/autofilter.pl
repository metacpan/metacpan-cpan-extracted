#!/usr/bin/perl

# Please don't encrypt me!
  
use Filter::CBC "Rijndael","my secret key";

# This file will be encrypted and overwritten.
# Make backups, damnit!
# Autofilter example
print "Don't try this at home, kids !";