**Math::Util::CalculatedValue** - 
Represents an adjustment to a value (which can contain additional adjustments).

[![Build Status](https://travis-ci.org/binary-com/perl-Math-Util-CalculatedValue.svg?branch=master)](https://travis-ci.org/binary-com/perl-Math-Util-CalculatedValue)
[![codecov](https://codecov.io/gh/binary-com/perl-Math-Util-CalculatedValue/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Math-Util-CalculatedValue)
[![Gitter chat](https://badges.gitter.im/binary-com/perl-Math-Util-CalculatedValue.png)](https://gitter.im/binary-com/perl-Math-Util-CalculatedValue)


**SYNOPSIS**

    my $tid = Math::Util::CalculatedValue->new({
        name        => 'time_in_days',
        description => 'Duration in days',
        set_by      => 'Contract',
        base_amount => 0,
    });

    my $tiy = Math::Util::CalculatedValue->new({
        name        => 'time_in_years',
        description => 'Duration in years',
        set_by      => 'Contract',
        base_amount => 1,
    });

    my $dpy = Math::Util::CalculatedValue->new({
        name        => 'days_per_year',
        description => 'days in a year',
        set_by      => 'Contract',
        base_amount => 365,
    });

    $tid->include_adjustment('reset', $tiy);
    $tid->include_adjustment('multiply', $dpy);

    print $tid->amount;

**ATTRIBUTES**


- **name**

    This is the name of the operation which called this module

- **description**

    This is the description of the operation which called this module

- **set_by**

    This is the name of the module which called this module

- **base_amount**

    This is the base amount on which the adjustments are to be made

- **metadata**

    Additional information that you wish to include.

- **minimum**

    The minimum value for amount

- **maximum**

    The maximum value for amount

**METHODS**

- **new**

    New instance method

- **amount**

    This is the final amount from this object, after applying all adjustments.

- **adjustments**

    The ordered adjustments (if any) applied to arrive at the final value.

- **include_adjustment**

    Creates the ordered adjustments as per the operation.

- **exclude_adjustment**

    Remove an adjustment by name.  Returns the number of instances found and excluded. Excluded items are changed into 'info' so that that still show up but are do not alter the parent value

    THis can be extremely dangerous, so make sure you know where and why you are doing it.

- **replace_adjustment**

    Replace all instances of the same named adjustment with the provided adjustment

    Returns the number of instances replaced.

- **peek**

    Peek at an included adjustment by name.

- **peek_amount**

    Peek at the value of an included adjustment by name.

**AUTHOR**

binary.com, C<< <rakesh at binary.com> >>

**SUPPORT**

You can find documentation for this module with the perldoc command.

    perldoc Math::Util::CalculatedValue


You can also look for information at:


RT: CPAN's request tracker (report bugs here)

<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Util-CalculatedValue>

AnnoCPAN: Annotated CPAN documentation

<http://annocpan.org/dist/Math-Util-CalculatedValue>

CPAN Ratings

<http://cpanratings.perl.org/d/Math-Util-CalculatedValue>

Search CPAN

<http://search.cpan.org/dist/Math-Util-CalculatedValue/>


