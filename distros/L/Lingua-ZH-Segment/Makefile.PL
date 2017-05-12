use inc::Module::Install;

name('Lingua-ZH-Segment');
author('Cheng-Lung Sung <clsung@tw.freebsd.org>');
abstract('Simple Segmentation of Chinese Text');
license('perl');
version_from('lib/Lingua/ZH/Segment.pm');

requires(qw(
    perl        5.8.1
    Test::More  0
));

WriteAll( );
