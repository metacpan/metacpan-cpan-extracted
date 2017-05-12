#!/usr/bin/perl -w

use Linux::stat;
use Data::VarPrint;

VarPrint(Linux::stat::stat());
