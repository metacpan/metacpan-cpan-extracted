use strict; use warnings;

use TestML1::Runtime;

package TestML1::Util;

use Exporter 'import';
our @EXPORT = qw( runtime list str num bool none native );

sub runtime { $TestML1::Runtime::Singleton }

sub list { TestML1::List->new(value => $_[0]) }
sub str { TestML1::Str->new(value => $_[0]) }
sub num { TestML1::Num->new(value => $_[0]) }
sub bool { TestML1::Bool->new(value => $_[0]) }
sub none { TestML1::None->new(value => $_[0]) }
sub native { TestML1::Native->new(value => $_[0]) }

1;
