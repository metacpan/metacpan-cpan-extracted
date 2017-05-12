#!/usr/bin/env perl

package My_Test_Base;

use Moo::Lax;

extends 'Medical::Growth::NHANES_2000::Base';

__PACKAGE__->_declare_params_LMS;

1;

__DATA__

1    0    1    1
2    2    2    2
3    3    3    3
