#!/usr/bin/perl

use strict;
use Carp;

# use Smart::Comments;

# Valores iniciales
our $text = 'Hola';
our $dinero = 3000.03;

### Texto: $text
### Dinero: $dinero

$text =~ s/Hola/Adios/;
$dinero /= 24;

### Texto: $text
### Dinero: $dinero

exit (0);
