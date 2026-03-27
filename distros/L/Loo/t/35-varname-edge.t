use strict;
use warnings;
use Test::More;
use Loo;

# Basic custom varname
{
    my $dd = Loo->new([1, 2]);
    $dd->{use_colour} = 0;
    $dd->Varname('DATA');
    my $out = $dd->Dump;
    like($out, qr/^\$DATA1 = 1;/m, 'varname DATA first');
    like($out, qr/^\$DATA2 = 2;/m, 'varname DATA second');
}

# Numeric varname
{
    my $dd = Loo->new([1]);
    $dd->{use_colour} = 0;
    $dd->Varname('123');
    my $out = $dd->Dump;
    like($out, qr/^\$1231 = 1;/m, 'numeric varname accepted verbatim');
}

# Varname with underscore
{
    my $dd = Loo->new([1]);
    $dd->{use_colour} = 0;
    $dd->Varname('foo_bar');
    my $out = $dd->Dump;
    like($out, qr/^\$foo_bar1 = 1;/m, 'underscore varname');
}

# Varname long string
{
    my $name = 'VERY_LONG_VARIABLE_PREFIX';
    my $dd = Loo->new([1]);
    $dd->{use_colour} = 0;
    $dd->Varname($name);
    my $out = $dd->Dump;
    like($out, qr/^\$VERY_LONG_VARIABLE_PREFIX1 = 1;/m, 'long varname');
}

done_testing;
