package Hazy::Cosmic::Jive;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/float_to_string/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
our $VERSION = '0.02';
require XSLoader;
XSLoader::load ('Hazy::Cosmic::Jive', $VERSION);
1;
