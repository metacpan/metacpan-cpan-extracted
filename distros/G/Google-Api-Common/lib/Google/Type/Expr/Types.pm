package Google::Type::Expr::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Expr',
    as InstanceOf['Google::Type::Expr::Expr'];

coerce 'Expr',
    from HashRef, via { 'Google::Type::Expr::Expr'->new($_) };

declare 'RepeatedExpr',
    as ArrayRef[Expr()];

coerce 'RepeatedExpr',
    from ArrayRef[HashRef], via { [ map { 'Google::Type::Expr::Expr'->new($_) } @$_ ] };

declare 'MapStringExpr',
    as HashRef[Expr()];

1;
