[![Build Status](https://travis-ci.org/bluescreen10/Math-FixedPoint.png)](https://travis-ci.org/bluescreen10/Math-FixedPoint)

# NAME

Math::FixedPoint - Fixed-Point calculations for Perl

# DESCRIPTION

This module brings fixed point calculations to the Perl world. Typically applications that require fixed point calculations, such as currency/money handling, are developed using either floating point numbers or Math::BigFloat (to increase the precision). The problem of using floating point numbers is that sooner or later the precision affect results, for example:

   > perl -e 'print int(37.73*100)'

   3772

In some applications this is unacceptable. To overcome these problems people usually switch to Math::BigFloat which can shield higher precision but scarifying performance.

On the other hand Math::FixedPoint address the problem using for most of it's calculations integer math, therefore not impacting precision. As a side benefit it's 5-10 times faster than Math::BigFloat as it doesn't need to deal with the complexity of floating point numbers.

# HOW TO INSTALL

To install this module using cpanm (preferred method)

  > cpanm Math::FixedPoint

or using Dist::Zilla

  > dzil test

  > dzil install


   