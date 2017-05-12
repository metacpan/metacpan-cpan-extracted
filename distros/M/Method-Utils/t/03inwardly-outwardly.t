#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Method::Utils qw( inwardly outwardly );

my @packages;

undef @packages;
TopLevel->${inwardly 'mth'}( \@packages );
is_deeply( \@packages, [qw( TopLevel Main1 Base1 Main2 Base2 Base3 )], 'Packages for inwardly' );

undef @packages;
TopLevel->${outwardly 'mth'}( \@packages );
is_deeply( \@packages, [qw( Base3 Base2 Main2 Base1 Main1 TopLevel )], 'Packages for outwardly' );

undef @packages;
Sparse->${inwardly 'mth'}( \@packages );
is_deeply( \@packages, [qw( Main1 Base1 Base2 )], 'Sparse methods not invoked multiple times' );

done_testing;

package Base1;
sub mth { push @{$_[1]}, "Base1" }

package Base2;
sub mth { push @{$_[1]}, "Base2" }

package Base3;
sub mth { push @{$_[1]}, "Base3" }

package Main1;
use base qw( Base1 Base2 );
sub mth { push @{$_[1]}, "Main1" }

package Main2;
use base qw( Base2 Base3 );
sub mth { push @{$_[1]}, "Main2" }

package TopLevel;
use mro 'c3';
use base qw( Main1 Main2 );
sub mth { push @{$_[1]}, "TopLevel" }

package SparseSub;
use base qw( Base2 );

package Sparse;
use mro 'c3';
use base qw( Main1 SparseSub );
