#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Date::Hijri',
    'AUTHOR'            => 'Alex Pleiner <alex@zeitform.de>',
    'ABSTRACT'          => 'Converter between Gregorian and Islamic (Hijri) Dates',
    'VERSION_FROM'	=> 'Hijri.pm',
    'PREREQ_PM'		=> {}, 
);
