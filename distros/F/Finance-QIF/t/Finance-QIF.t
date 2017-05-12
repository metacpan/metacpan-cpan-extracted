#!/usr/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-IIF.t'

use strict;
use warnings;
use Test::More tests => 998;
use File::Temp qw(tempfile);

my $DOWARN;

BEGIN {

    BEGIN {
        $SIG{"__WARN__"} = sub { warn $_[0] if $DOWARN }
    }
    $DOWARN = 1;
    use_ok('Finance::QIF') or exit;
}

my $package  = "Finance::QIF";
my $testfile = "t/test.qif";

{    # new
    can_ok( $package, qw(new) );

    my $obj = $package->new;
    isa_ok( $obj, $package );

    is( $obj->{debug},            0,  "default debug value" );
    is( $obj->{autodetect},       0,  "default autodetect value" );
    is( $obj->{trim_white_space}, 0,  "default trim_white_space value" );
    is( $obj->record_separator,   $/, "default record separator" );

    $obj = $package->new(
        debug            => 1,
        record_separator => "X\rX\n",
    );

    is( $obj->{debug}, 1, "custom debug value" );
    is( $obj->record_separator, "X\rX\n", "custom record separator" );
}

{    # autodetect
    my ( $fh, $fn, $obj );

    ( $fh, $fn ) = tempfile();
    close($fh);

    $obj = $package->new( file => $fn, autodetect => 1 );
    is( $obj->record_separator, $/, "autodetect default record separator" );

    ( $fh, $fn ) = tempfile();
    print( $fh "Testing Windows\015\012" );
    close($fh);

    $obj = $package->new( file => $fn, autodetect => 1 );
    is( $obj->record_separator, "\015\012", "autodetect windows record separator" );

    ( $fh, $fn ) = tempfile();
    print( $fh "Testing Mac\015" );
    close($fh);

    $obj = $package->new( file => $fn, autodetect => 1 );
    is( $obj->record_separator, "\015", "autodetect mac record separator" );

    ( $fh, $fn ) = tempfile();
    print( $fh "Testing Unix\012" );
    close($fh);

    $obj = $package->new( file => $fn, autodetect => 1 );
    is( $obj->record_separator, "\012", "autodetect unix record separator" );
}

{    # trim_white_space

    my ( $fh, $fn ) = tempfile();
    print( $fh "!Type:Security\nNIntuit \nS INTU\nT Stock \nGHigh Risk\n^\n" );
    close($fh);

    my $obj = $package->new( file => $fn, autodetect => 1 );
    ok( $obj->{trim_white_space} == 0, "trim_white_space not set" );
    my $record = $obj->next();

    ok( $record->{security} eq "Intuit ", "trim_white_space trailing" );
    ok( $record->{symbol}   eq " INTU",   "trim_white_space leading" );
    ok( $record->{type}     eq " Stock ", "trim_white_space both" );

    $obj = $package->new(
        file             => $fn,
        autodetect       => 1,
        trim_white_space => 1
    );
    ok( $obj->{trim_white_space} == 1, "trim_white_space set" );
    $record = $obj->next();

    ok( $record->{security} eq "Intuit", "trim_white_space trailing" );
    ok( $record->{symbol}   eq "INTU",   "trim_white_space leading" );
    ok( $record->{type}     eq "Stock",  "trim_white_space both" );
}

{    # reset
    can_ok( $package, qw(reset) );

    my $obj = $package->new;
    eval { $obj->reset };
    like(
        $@,
        qr/^No filehandle available/,
        "reset without a filehandle croaks"
    );

    my ( $fh, $fn ) = tempfile();
    print( $fh "!Type:Security\nNIntuit\nSINTU\nTStock\nGHigh Risk\n^\n" );
    close($fh);

    $obj = $package->new( file => $fn, autodetect => 1 );
    my $record1 = $obj->next;
    $obj->reset;
    my $record2 = $obj->next;

    ok(
        $record1->{header}        eq $record2->{header}
          && $record1->{security} eq $record2->{security}
          && $record1->{symbol}   eq $record2->{symbol}
          && $record1->{type}     eq $record2->{type}
          && $record1->{goal}     eq $record2->{goal},
        "reset reads same record"
    );
}

{    # file
    can_ok( $package, qw(file) );

    my $obj = $package->new;

    is( $obj->file, undef, "file undef by default" );
    is( $obj->file($testfile), $testfile, "file with one arg" );
    is( $obj->file( $testfile, "<" ), $testfile, "file with two args" );

    $obj = $package->new( file => $testfile );
    is( $obj->file, $testfile, "new with scalar file argument" );

    SKIP: {
      skip "Perl 5.008 not installed", 1 if $]<5.008;
      $obj = $package->new( file => [ $testfile, "<:crlf" ] );
      is( $obj->file, $testfile, "new with arrayref file argument" );
    }

    is_deeply( [ $obj->file( 1, 2 ) ], [ 1, 2 ], "file returns list" );
}

{    # croak checks for: _filehandle next _getline close
    my @methods = qw(_filehandle next _getline close);
    can_ok( $package, @methods );

    foreach my $method (@methods) {
        my $obj = $package->new;
        eval { $obj->$method };
        like(
            $@,
            qr/^No filehandle available/,
            "$method without a filehandle croaks"
        );
    }
}

{    # open
    can_ok( $package, qw(open) );

    my $obj = $package->new;
    eval { $obj->open };
    like( $@, qr/^No file specified/, "open without a file croaks" );

    $obj = $package->new;
    eval { $obj->open($testfile) };
    is( $@, "", "open with file does not die" );
}

{    # _parseline
    can_ok( $package, qw(_parseline) );
}

{    # _warning
    can_ok( $package, qw(_warning) );
}

testfile( "Read ", $testfile );
my $in = $package->new(
    file       => $testfile,
    autodetect => 1
);

my ( $fh, $fn ) = tempfile();
close($fh);

my $tempfile = $fn;

my $out = $package->new(
    file             => ">" . $tempfile,
    record_separator => $in->record_separator
);

# Trap warning so we can validate message returned.
$DOWARN = 0;

# need to create a test that intentionally causes a warning so we can validate
# warnings are always working properly
# turn warnings back on
$DOWARN = 1;

my $header = "";
while ( my $record = $in->next ) {
    if ( $header ne $record->{header} ) {
        $out->header( $record->{header} );
        $header = $record->{header};
    }
    $out->write($record);
}

$in->close;
$out->close;
testfile( "Write ", $tempfile );

#test default write/write works
$out = $package->new( file => ">" . $tempfile, );
my $record = {
    header   => "Type:Security",
    security => "Intuit",
    symbol   => "INTU",
    type     => "Stock",
    goal     => "High Risk"
};
$out->header( $record->{header} );
$out->write($record);
$out->close;
$in = $package->new( file => $tempfile, );
$record = $in->next;
ok( $record->{header}   eq "Type:Security", "default write/read" );
ok( $record->{security} eq "Intuit",        "default write/read" );
ok( $record->{symbol}   eq "INTU",          "default write/read" );
ok( $record->{type}     eq "Stock",         "default write/read" );
ok( $record->{goal}     eq "High Risk",     "default write/read" );

# Need a test for confirming we don't interfere with other open files
# reading input with different line separator.

sub testfile {
    my $test = shift;
    my $file = shift;
    my $qif  = $package->new(
        file             => $file,
        record_separator => "\n"
    );

    # account tests
    {
        my $record;
        $record = $qif->next;
        ok( $record->{header}      eq "Account",       $test . "Account" );
        ok( $record->{name}        eq "Asset",         $test . "Account" );
        ok( $record->{description} eq "Sample Asset",  $test . "Account" );
        ok( $record->{tax}         eq "",              $test . "Account" );
        ok( $record->{note}        eq "Note on Asset", $test . "Account" );
        ok( $record->{type}        eq "Oth A",         $test . "Account" );
        ok( $record->{balance}     eq "25,000.00",     $test . "Account" );
        $record = $qif->next;
        ok( $record->{header}      eq "Account",         $test . "Account" );
        ok( $record->{name}        eq "Bank",            $test . "Account" );
        ok( $record->{description} eq "Sample Bank",     $test . "Account" );
        ok( $record->{tax}         eq "",                $test . "Account" );
        ok( $record->{note}        eq "Notes on Sample", $test . "Account" );
        ok( $record->{type}        eq "Bank",            $test . "Account" );
        ok( $record->{balance}     eq "1,465.00",        $test . "Account" );
        $record = $qif->next;
        ok( $record->{header}      eq "Account",      $test . "Account" );
        ok( $record->{name}        eq "Cash",         $test . "Account" );
        ok( $record->{description} eq "Sample Cash",  $test . "Account" );
        ok( $record->{tax}         eq "",             $test . "Account" );
        ok( $record->{note}        eq "Note on Cash", $test . "Account" );
        ok( $record->{type}        eq "Cash",         $test . "Account" );
        ok( $record->{balance}     eq "0.00",         $test . "Account" );
        $record = $qif->next;
        ok( $record->{header}      eq "Account",      $test . "Account" );
        ok( $record->{name}        eq "Credit Card",  $test . "Account" );
        ok( $record->{description} eq "Sample Card",  $test . "Account" );
        ok( $record->{limit}       eq "15,000.00",    $test . "Account" );
        ok( $record->{tax}         eq "",             $test . "Account" );
        ok( $record->{note}        eq "Note on Card", $test . "Account" );
        ok( $record->{type}        eq "CCard",        $test . "Account" );
        ok( $record->{balance}     eq "0.00",         $test . "Account" );
        $record = $qif->next;
        ok( $record->{header}      eq "Account",           $test . "Account" );
        ok( $record->{name}        eq "Liability",         $test . "Account" );
        ok( $record->{description} eq "Sample Liability",  $test . "Account" );
        ok( $record->{tax}         eq "",                  $test . "Account" );
        ok( $record->{note}        eq "Note on Liability", $test . "Account" );
        ok( $record->{type}        eq "Oth L",             $test . "Account" );
        ok( $record->{balance}     eq "50,000.00",         $test . "Account" );
        $record = $qif->next;
        ok( $record->{header}      eq "Account",      $test . "Account" );
        ok( $record->{name}        eq "Mutual Fund",  $test . "Account" );
        ok( $record->{description} eq "Sample Fund",  $test . "Account" );
        ok( $record->{tax}         eq "",             $test . "Account" );
        ok( $record->{note}        eq "Note on Fund", $test . "Account" );
        ok( $record->{type}        eq "Mutual",       $test . "Account" );
        ok( $record->{balance}     eq "672.87",       $test . "Account" );
        $record = $qif->next;
        ok( $record->{header}      eq "Account",           $test . "Account" );
        ok( $record->{name}        eq "Portfolio",         $test . "Account" );
        ok( $record->{description} eq "Sample Portfolio",  $test . "Account" );
        ok( $record->{tax}         eq "",                  $test . "Account" );
        ok( $record->{note}        eq "Note on portfolio", $test . "Account" );
        ok( $record->{type}        eq "Port",              $test . "Account" );
        ok( $record->{balance}     eq "2,651.00",          $test . "Account" );
    }

    # Added a trailing space to the !Clear:AutoSwitch line in data file.
    # We should test to make sure it is processed as a accepted header and
    # that no error message was generated during processing.

    # security tests
    {
        my $record = $qif->next;
        ok( $record->{header}   eq "Type:Security", $test . "Security" );
        ok( $record->{security} eq "Intuit",        $test . "Security" );
        ok( $record->{symbol}   eq "INTU",          $test . "Security" );
        ok( $record->{type}     eq "Stock",         $test . "Security" );
        ok( $record->{goal}     eq "High Risk",     $test . "Security" );
        $record = $qif->next;
        ok( $record->{header} eq "Type:Security", $test . "Security" );
    }

    # payee tests
    {

        my $record = $qif->next;
        ok( $record->{header}  eq "Type:Payee",          $test . "Payee" );
        ok( $record->{name}    eq "Safeway",             $test . "Payee" );
        ok( $record->{address} eq "Safeway Address\n\n", $test . "Payee" );
        ok( $record->{city}    eq "City",                $test . "Payee" );
        ok( $record->{state}   eq "SC",                  $test . "Payee" );
        ok( $record->{zip}     eq "99999     ",          $test . "Payee" );
        ok( $record->{country} eq "",                    $test . "Payee" );
        ok( $record->{phone}   eq "3333333333",          $test . "Payee" );
        ok( $record->{account} eq "123456789",           $test . "Payee" );
    }

    # category tests
    {
        my $record = $qif->next;
        ok( $record->{header} eq "Type:Cat", $test . "Category" );
        ok( $record->{name}   eq "Auto",     $test . "Category" );
        ok( $record->{description} eq "Automobile Expenses",
            $test . "Category" );
        ok( $record->{expense} eq "", $test . "Category" );
        for ( my $count = 0 ; $count < 21 ; $count++ ) {
            $record = $qif->next;
            ok( $record->{header} eq "Type:Cat", $test . "Category" );
        }
        $record = $qif->next;
        ok( $record->{header}      eq "Type:Cat",        $test . "Category" );
        ok( $record->{name}        eq "Interest Inc",    $test . "Category" );
        ok( $record->{description} eq "Interest Income", $test . "Category" );
        ok( $record->{income}      eq "",                $test . "Category" );
        ok( $record->{tax}         eq "",                $test . "Category" );
        ok( $record->{schedule}    eq "4592",            $test . "Category" );
        ok( $record->{budget}[0]   eq "1.00",            $test . "Category" );
        ok( $record->{budget}[1]   eq "0.00",            $test . "Category" );
        ok( $record->{budget}[2]   eq "0.00",            $test . "Category" );
        ok( $record->{budget}[3]   eq "1.00",            $test . "Category" );
        ok( $record->{budget}[4]   eq "0.00",            $test . "Category" );
        ok( $record->{budget}[5]   eq "0.00",            $test . "Category" );
        ok( $record->{budget}[6]   eq "1.00",            $test . "Category" );
        ok( $record->{budget}[7]   eq "0.00",            $test . "Category" );
        ok( $record->{budget}[8]   eq "0.00",            $test . "Category" );
        ok( $record->{budget}[9]   eq "0.00",            $test . "Category" );
        ok( $record->{budget}[10]  eq "0.00",            $test . "Category" );
        ok( $record->{budget}[11]  eq "1.00",            $test . "Category" );

        for ( my $count = 0 ; $count < 73 ; $count++ ) {
            $record = $qif->next;
            ok( $record->{header} eq "Type:Cat", $test . "Category" );
        }
    }

    # budget tests
    {
        for ( my $count = 0 ; $count < 17 ; $count++ ) {
            my $record = $qif->next;
            ok( $record->{header} eq "Type:Budget", $test . "Budget" );
        }
        my $record = $qif->next;
        ok( $record->{header}      eq "Type:Budget", $test . "Budget" );
        ok( $record->{name}        eq "Groceries",   $test . "Budget" );
        ok( $record->{description} eq "Groceries",   $test . "Budget" );
        ok( $record->{budget}[0]   eq "-100.00",     $test . "Budget" );
        ok( $record->{budget}[1]   eq "-100.00",     $test . "Budget" );
        ok( $record->{budget}[2]   eq "-100.00",     $test . "Budget" );
        ok( $record->{budget}[3]   eq "-100.00",     $test . "Budget" );
        ok( $record->{budget}[4]   eq "-100.00",     $test . "Budget" );
        ok( $record->{budget}[5]   eq "-100.00",     $test . "Budget" );
        ok( $record->{budget}[6]   eq "-100.00",     $test . "Budget" );
        ok( $record->{budget}[7]   eq "-100.00",     $test . "Budget" );
        ok( $record->{budget}[8]   eq "-100.00",     $test . "Budget" );
        ok( $record->{budget}[9]   eq "-100.00",     $test . "Budget" );
        ok( $record->{budget}[10]  eq "-100.00",     $test . "Budget" );
        ok( $record->{budget}[11]  eq "-100.00",     $test . "Budget" );
        for ( my $count = 0 ; $count < 78 ; $count++ ) {
            $record = $qif->next;
            ok( $record->{header} eq "Type:Budget", $test . "Budget" );
        }
    }

    # Class tests
    {
        my $record = $qif->next;
        ok( $record->{header}      eq "Type:Class",        $test . "Class" );
        ok( $record->{name}        eq "Class",             $test . "Class" );
        ok( $record->{description} eq "Class Description", $test . "Class" );
        $record = $qif->next;
        ok( $record->{header} eq "Type:Class", $test . "Class" );
    }

    # Oth A test
    {
        my $record = $qif->next;
        ok( $record->{header}  eq "Account",   $test . "Oth A" );
        ok( $record->{name}    eq "Asset",     $test . "Oth A" );
        ok( $record->{type}    eq "Oth A",     $test . "Oth A" );
        ok( $record->{balance} eq "25,000.00", $test . "Oth A" );
        for ( my $count = 0 ; $count < 2 ; $count++ ) {
            $record = $qif->next;
            ok( $record->{header} eq "Type:Oth A", $test . "Oth A" );
        }
    }

    # Bank test
    {
        my $record = $qif->next;
        ok( $record->{header}  eq "Account",  $test . "Bank" );
        ok( $record->{name}    eq "Bank",     $test . "Bank" );
        ok( $record->{type}    eq "Bank",     $test . "Bank" );
        ok( $record->{balance} eq "1,465.00", $test . "Bank" );
        $record = $qif->next;
        ok( $record->{header}   eq "Type:Bank",       $test . "Bank" );
        ok( $record->{date}     eq "1/10/06",         $test . "Bank" );
        ok( $record->{payee}    eq "Opening Balance", $test . "Bank" );
        ok( $record->{memo}     eq "",                $test . "Bank" );
        ok( $record->{transaction}   eq "0.00",            $test . "Bank" );
        ok( $record->{address}  eq "",                $test . "Bank" );
        ok( $record->{status}   eq "X",               $test . "Bank" );
        ok( $record->{category} eq "[Bank]",          $test . "Bank" );
        $record = $qif->next;
        ok( $record->{header}              eq "Type:Bank", $test . "Bank" );
        ok( $record->{date}                eq "1/10/06",   $test . "Bank" );
        ok( $record->{payee}               eq "Paycheck",  $test . "Bank" );
        ok( $record->{memo}                eq "",          $test . "Bank" );
        ok( $record->{transaction}              eq "1,690.00",  $test . "Bank" );
        ok( $record->{address}             eq "",          $test . "Bank" );
        ok( $record->{category}            eq "Salary",    $test . "Bank" );
        ok( $record->{splits}[0]{category} eq "Salary",    $test . "Bank" );
        ok( $record->{splits}[0]{memo}     eq "",          $test . "Bank" );
        ok( $record->{splits}[0]{amount}   eq "2,000.00",  $test . "Bank" );
        ok( $record->{splits}[1]{category} eq "Payroll Taxes, Self:Federal",
            $test . "Bank" );
        ok( $record->{splits}[1]{memo}   eq "",        $test . "Bank" );
        ok( $record->{splits}[1]{amount} eq "-250.00", $test . "Bank" );
        ok( $record->{splits}[2]{category} eq "Payroll Taxes, Self:Soc Sec",
            $test . "Bank" );
        ok( $record->{splits}[2]{amount} eq "-50.00", $test . "Bank" );
        ok( $record->{splits}[3]{category} eq "Payroll Taxes, Self:Medicare",
            $test . "Bank" );
        ok( $record->{splits}[3]{memo}   eq "",       $test . "Bank" );
        ok( $record->{splits}[3]{amount} eq "-10.00", $test . "Bank" );
        $record = $qif->next;
        ok( $record->{header}   eq "Type:Bank", $test . "Bank" );
        ok( $record->{date}     eq "1/17/06",   $test . "Bank" );
        ok( $record->{payee}    eq "Safeway",   $test . "Bank" );
        ok( $record->{memo}     eq "",          $test . "Bank" );
        ok( $record->{transaction}   eq "-100.00",   $test . "Bank" );
        ok( $record->{address}  eq "",          $test . "Bank" );
        ok( $record->{category} eq "Groceries", $test . "Bank" );
        $record = $qif->next;
        ok( $record->{header}              eq "Type:Bank", $test . "Bank" );
        ok( $record->{date}                eq "2/17/06",   $test . "Bank" );
        ok( $record->{payee}               eq "Safeway",   $test . "Bank" );
        ok( $record->{memo}                eq "",          $test . "Bank" );
        ok( $record->{transaction}              eq "-125.00",   $test . "Bank" );
        ok( $record->{address}             eq "",          $test . "Bank" );
        ok( $record->{number}              eq ">>>>>",     $test . "Bank" );
        ok( $record->{category}            eq "Groceries", $test . "Bank" );
        ok( $record->{splits}[0]{category} eq "Groceries", $test . "Bank" );
        ok( $record->{splits}[0]{memo}     eq "",          $test . "Bank" );
        ok( $record->{splits}[0]{amount}   eq "-100.00",   $test . "Bank" );
        ok( $record->{splits}[1]{category} eq "Misc",      $test . "Bank" );
        ok( $record->{splits}[1]{memo}     eq "",          $test . "Bank" );
        ok( $record->{splits}[1]{amount}   eq "-25.00",    $test . "Bank" );
        $record = $qif->next;
        ok( $record->{header}   eq "Type:Bank", $test . "Bank" );
        ok( $record->{date}     eq "3/17/06",   $test . "Bank" );
        ok( $record->{payee}    eq "Safeway",   $test . "Bank" );
        ok( $record->{memo}     eq "",          $test . "Bank" );
        ok( $record->{transaction}   eq "-100.00",   $test . "Bank" );
        ok( $record->{total}    eq "-100.00",   $test . "Bank" );
        ok( $record->{address}  eq "",          $test . "Bank" );
        ok( $record->{category} eq "Groceries", $test . "Bank" );
        $qif->{trim_white_space} = 1;
        $record = $qif->next;
        ok( $record->{header}   eq "Type:Bank", $test . "Bank" );
        ok( $record->{date}     eq "3/17/06",   $test . "Bank" );
        ok( $record->{payee}    eq "QFC",       $test . "Bank" );
        ok( $record->{memo}     eq "",          $test . "Bank" );
        ok( $record->{transaction}   eq "-100.00",   $test . "Bank" );
        ok( $record->{total}    eq "-100.00",   $test . "Bank" );
        ok( $record->{address}  eq "",          $test . "Bank" );
        ok( $record->{category} eq "Groceries", $test . "Bank" );
        $qif->{trim_white_space} = 0;
    }

    # Cash test
    {
        my $record = $qif->next;
        ok( $record->{header}  eq "Account", $test . "Cash" );
        ok( $record->{name}    eq "Cash",    $test . "Cash" );
        ok( $record->{type}    eq "Cash",    $test . "Cash" );
        ok( $record->{balance} eq "0.00",    $test . "Cash" );
        $record = $qif->next;
        ok( $record->{header}   eq "Type:Cash",       $test . "Cash" );
        ok( $record->{date}     eq "1/10/06",         $test . "Cash" );
        ok( $record->{payee}    eq "Opening Balance", $test . "Cash" );
        ok( $record->{memo}     eq "",                $test . "Cash" );
        ok( $record->{transaction}   eq "0.00",            $test . "Cash" );
        ok( $record->{address}  eq "",                $test . "Cash" );
        ok( $record->{status}   eq "X",               $test . "Cash" );
        ok( $record->{category} eq "[Cash]",          $test . "Cash" );
    }

    # Credit Card test
    {
        my $record = $qif->next;
        ok( $record->{header}  eq "Account",     $test . "Credit Card" );
        ok( $record->{name}    eq "Credit Card", $test . "Credit Card" );
        ok( $record->{limit}   eq "15,000.00",   $test . "Credit Card" );
        ok( $record->{type}    eq "CCard",       $test . "Credit Card" );
        ok( $record->{balance} eq "0.00",        $test . "Credit Card" );
        $record = $qif->next;
        ok( $record->{header}   eq "Type:CCard",      $test . "Credit Card" );
        ok( $record->{date}     eq "1/10/06",         $test . "Credit Card" );
        ok( $record->{payee}    eq "Opening Balance", $test . "Credit Card" );
        ok( $record->{memo}     eq "",                $test . "Credit Card" );
        ok( $record->{transaction}   eq "0.00",            $test . "Credit Card" );
        ok( $record->{address}  eq "",                $test . "Credit Card" );
        ok( $record->{status}   eq "X",               $test . "Credit Card" );
        ok( $record->{category} eq "[Credit Card]",   $test . "Credit Card" );
    }

    # Liability test
    {
        my $record = $qif->next;
        ok( $record->{header}  eq "Account",   $test . "Liability" );
        ok( $record->{name}    eq "Liability", $test . "Liability" );
        ok( $record->{type}    eq "Oth L",     $test . "Liability" );
        ok( $record->{balance} eq "50,000.00", $test . "Liability" );
        $record = $qif->next;
        ok( $record->{header}   eq "Type:Oth L",      $test . "Liability" );
        ok( $record->{date}     eq "1/10/06",         $test . "Liability" );
        ok( $record->{payee}    eq "Opening Balance", $test . "Liability" );
        ok( $record->{memo}     eq "",                $test . "Liability" );
        ok( $record->{transaction}   eq "-50,000.00",      $test . "Liability" );
        ok( $record->{address}  eq "",                $test . "Liability" );
        ok( $record->{status}   eq "X",               $test . "Liability" );
        ok( $record->{category} eq "[Liability]",     $test . "Liability" );
    }

    # Mutual Fund test
    {
        my $record = $qif->next;
        ok( $record->{header}  eq "Account",     $test . "Mutual Fund" );
        ok( $record->{name}    eq "Mutual Fund", $test . "Mutual Fund" );
        ok( $record->{type}    eq "Mutual",      $test . "Mutual Fund" );
        ok( $record->{balance} eq "672.87",      $test . "Mutual Fund" );
        for ( my $count = 0 ; $count < 1 ; $count++ ) {
            $record = $qif->next;
            ok( $record->{header} eq "Type:Invst", $test . "Mutual Fund" );
        }
    }

    # Portfolio test
    {
        my $record = $qif->next;
        ok( $record->{header}  eq "Account",   $test . "Portfolio" );
        ok( $record->{name}    eq "Portfolio", $test . "Portfolio" );
        ok( $record->{type}    eq "Port",      $test . "Portfolio" );
        ok( $record->{balance} eq "2,651.00",  $test . "Portfolio" );
    }

    # Invest test
    {
        my $record = $qif->next;
        ok( $record->{header}   eq "Type:Invst",   $test . "Invest" );
        ok( $record->{date}     eq "1/10/06",      $test . "Invest" );
        ok( $record->{action}   eq "ShrsIn",       $test . "Invest" );
        ok( $record->{security} eq "Intuit",       $test . "Invest" );
        ok( $record->{quantity} eq "50",           $test . "Invest" );
        ok( $record->{memo}     eq "Initial Move", $test . "Invest" );
    }

    # Prices test
    {
        my $record = $qif->next;
        ok( $record->{header}            eq "Type:Prices", $test . "Prices" );
        ok( $record->{symbol}            eq "INTU",        $test . "Prices" );
        ok( $record->{prices}[0]{close}  eq "55.400",      $test . "Prices" );
        ok( $record->{prices}[0]{date}   eq "12/12/05",    $test . "Prices" );
        ok( $record->{prices}[0]{max}    eq "55.560",      $test . "Prices" );
        ok( $record->{prices}[0]{min}    eq "53.660",      $test . "Prices" );
        ok( $record->{prices}[0]{volume} eq "3120461",     $test . "Prices" );
        ok( $record->{prices}[1]{close}  eq "55.570",      $test . "Prices" );
        ok( $record->{prices}[1]{date}   eq "12/13/05",    $test . "Prices" );
        ok( $record->{prices}[1]{max}    eq "55.740",      $test . "Prices" );
        ok( $record->{prices}[1]{min}    eq "54.600",      $test . "Prices" );
        ok( $record->{prices}[1]{volume} eq "2437647",     $test . "Prices" );
        $record = $qif->next;
        ok( $record->{header} eq "Type:Prices", $test . "Prices" );
        $record = $qif->next;
        ok( $record->{header} eq "Type:Prices", $test . "Prices" );
        ok( $record->{symbol}            eq "WIN",        $test . "Prices" );
        ok( $record->{prices}[0]{close}  eq "19.740",      $test . "Prices" );
        ok( $record->{prices}[0]{date}   eq "12/12/05",    $test . "Prices" );
        ok( exists($record->{prices}[0]{max}) == 0 ,    $test . "Prices" );
        ok( exists($record->{prices}[0]{min})   == 0,    $test . "Prices" );
        ok( exists($record->{prices}[0]{volume}) == 0,    $test . "Prices" );
    }

    # Memorized test
    {
        my $record = $qif->next;
        ok( $record->{header}      eq "Type:Memorized", $test . "Memorized" );
        ok( $record->{transaction}      eq "-50.00",         $test . "Memorized" );
        ok( $record->{payee}       eq "Safeway",        $test . "Memorized" );
        ok( $record->{memo}        eq "",               $test . "Memorized" );
        ok( $record->{type} eq "C",              $test . "Memorized" );
        $record = $qif->next;
        ok( $record->{header}   eq "Type:Memorized", $test . "Memorized" );
        ok( $record->{transaction}   eq "-1,140.17",      $test . "Memorized" );
        ok( $record->{payee}    eq "Bank",           $test . "Memorized" );
        ok( $record->{memo}     eq "",               $test . "Memorized" );
        ok( $record->{address}  eq "",               $test . "Memorized" );
        ok( $record->{category} eq "[Liability]",    $test . "Memorized" );
        ok( $record->{splits}[0]{category} eq "[Liability]",
            $test . "Memorized" );
        ok( $record->{splits}[0]{memo}   eq "principal", $test . "Memorized" );
        ok( $record->{splits}[0]{amount} eq "-952.67",   $test . "Memorized" );
        ok( $record->{splits}[1]{category} eq "Mortgage Int",
            $test . "Memorized" );
        ok( $record->{splits}[1]{memo}   eq "interest",  $test . "Memorized" );
        ok( $record->{splits}[1]{amount} eq "-187.50",   $test . "Memorized" );
        ok( $record->{first}             eq "2/1/06",    $test . "Memorized" );
        ok( $record->{years}             eq "4",         $test . "Memorized" );
        ok( $record->{made}              eq "0",         $test . "Memorized" );
        ok( $record->{periods}           eq "12",        $test . "Memorized" );
        ok( $record->{interest}          eq "4.5",       $test . "Memorized" );
        ok( $record->{balance}           eq "25,000.00", $test . "Memorized" );
        ok( $record->{loan}              eq "25,000.00", $test . "Memorized" );
        ok( $record->{type}       eq "P",         $test . "Memorized" );
        $record = $qif->next;
        ok( $record->{header}   eq "Type:Memorized", $test . "Memorized" );
        ok( $record->{action}   eq "SellX",          $test . "Memorized" );
        ok( $record->{security} eq "IDS New D A",    $test . "Memorized" );
        ok( $record->{price}    eq "22.096936",      $test . "Memorized" );
        ok( $record->{quantity} eq "158.393",        $test . "Memorized" );
        ok( $record->{total}     eq "3,500.00",      $test . "Memorized" );
        ok( $record->{transaction}   eq "3,500.00",  $test . "Memorized" );
        ok( $record->{memo}     eq "Investment",     $test . "Memorized" );
        ok( $record->{category} eq "[Invest]",       $test . "Memorized" );
        ok( $record->{amount}   eq "3,500.00",       $test . "Memorized" );
        ok( $record->{type}     eq "I",              $test . "Memorized" );
    }
}

