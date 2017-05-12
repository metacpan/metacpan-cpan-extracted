# $Id: Makefile.PL,v 1.9 2004/11/11 08:59:20 roel Exp $

use inc::Module::Install;

name            ('FrameMaker-MifTree');
abstract        ('A MIF Parser');
author          ('Roel van der Steen <roel-perl@st2x.net>');
version_from    ('lib/FrameMaker/MifTree.pm');
license         ('perl');
requires        ('perl' => 5.008_001);
requires        ('File::Temp');
requires        ('IO::Scalar');
requires        ('IO::Tokenized');
requires        ('IO::Tokenized::File');
#requires        ('IO::Tokenized::Scalar');
requires        ('Test::More');
requires        ('Tree::DAG_Node');

include('ExtUtils::AutoInstall');
auto_install();

&WriteAll;
