# -*- perl -*-
#$Id: 04_body_suppress.t 1121 2007-01-01 14:43:51Z jimk $
# t/04_body_suppress.tt - test what happens when body_suppress element is supplied
use strict;
use warnings;

use Test::More tests => 34;
use_ok( 'List::RewriteElements' );
use_ok( 'Cwd' );
use_ok( 'File::Temp', qw| tempdir | );
use_ok( 'Tie::File' );
use_ok( 'File::Copy' );
use lib ( "t/testlib" );
use_ok( 'IO::Capture::Stdout' );
use Carp;;

my $lre;
my @lines;

$lre  = List::RewriteElements->new ( {
    list        => [ map {"$_\n"} (1..10) ],
    body_rule   => sub {
        my $record = shift;
        return (10 * $record);
    },
    body_suppress   => sub {
        my $record = shift;
        chomp $record;
        return if $record eq '10';
    },
} );
isa_ok ($lre, 'List::RewriteElements');

my $cap = IO::Capture::Stdout->new();
$cap->start();
$lre->generate_output();
$cap->stop();
chomp( @lines = $cap->read() );
is($lines[0], q{10}, "First element of list is correct");
is($lines[-1], q{90}, "Last element of list is correct");

{
    my $cwd = cwd();
    
    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    my $output = "./output";
    $lre  = List::RewriteElements->new ( {
        list        => [ map {"$_\n"} (1..10) ],
        body_rule   => sub {
            my $record = shift;
            return (10 * $record);
        },
        body_suppress   => sub {
            my $record = shift;
            chomp $record;
            return if $record eq '10';
        },
        output_file => $output,
    } );
    isa_ok ($lre, 'List::RewriteElements');

    is($lre->get_records_deleted(), 0,
        "Count of records deleted not yet determined");
    is($lre->get_total_records(), 0,
        "Count of records out not yet determined");
    is($lre->get_records_changed(), 0,
        "Count of records changed not yet determined");
    is($lre->get_records_unchanged(), 0,
        "Count of records unchanged not yet determined");
    is($lre->get_total_rows(), 0,
        "Count of rows out not yet determined");

    $lre->generate_output();
    ok(-f $output, "Output file created");

    is($lre->get_records_deleted(), 1,
        "Confirmed count of records deleted");
    is($lre->get_total_records(), 9,
        "Confirmed count of records out");
    is($lre->get_records_changed(), 9,
        "Count of records changed confirmed");
    is($lre->get_records_unchanged(), 0,
        "Count of records unchanged confirmed");
    is($lre->get_total_rows(), 9,
        "Confirmed count of rows out");

    my @lines;
    open my $FH, $output or croak "Unable to open $output for reading";
    while (<$FH>) {
        chomp;
        push @lines, $_;
    }
    close $FH or croak "Unable to close $output";
    is($lines[0], q{10}, "First element of list is correct");
    is($lines[-1], q{90}, "Last element of list is correct");
    
    ok(chdir $cwd, 'changed back to original directory after testing');
}

# In case below, body rule requires fetching an item from external
# environment, thereby changing the state of the external environment.
{
    my $cwd = cwd();
    
    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    my $dupe = qq{$tdir/complex.txt};
    copy(qq{$cwd/t/testlib/complex.txt}, $dupe);
    ok(-f $dupe, "sample file copied correctly");

    my @greeks;
    tie @greeks, 'Tie::File', $dupe, recsep => "\n";
    my $numcount = scalar(@greeks);
    
    my $snatch_number_ref = sub {
        return (shift @greeks);
    };

    my $output = "./output";
    $lre  = List::RewriteElements->new ( {
        list        => [ map {"$_\n"} (1..10) ],
        body_rule   => sub {
            my $record = shift;
            my $rv;
            chomp $record;
            if ($record eq '9') {
                $rv = &{$snatch_number_ref};
            } else {
                $rv = (10 * $record);
            }
            return $rv;
        },
        body_suppress   => sub {
            my $record = shift;
            chomp $record;
            return if $record eq '10';
        },
        output_file => $output,
    } );
    isa_ok ($lre, 'List::RewriteElements');

    $lre->generate_output();
    ok(-f $output, "Output file created");

    my @lines;
    open my $FH, $output or croak "Unable to open $output for reading";
    while (<$FH>) {
        chomp;
        push @lines, $_;
    }
    close $FH or croak "Unable to close $output";
    is($lines[0], q{10}, "First element of list is correct");
    is($lines[-2], q{80}, "Next to last element of list is correct");
    is($lines[-1], q{alpha}, "Last element of list is correct");

    is(scalar(@greeks), $numcount - 1,
        "Count of items in external file is correct");
    untie @greeks;
    
    ok(chdir $cwd, 'changed back to original directory after testing');
}

