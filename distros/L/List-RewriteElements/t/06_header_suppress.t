# -*- perl -*-
#$Id: 06_header_suppress.t 1121 2007-01-01 14:43:51Z jimk $
# t/06_header_suppress.tt - test what happens when header_suppress element is supplied
use strict;
use warnings;

use Test::More tests =>  93;
use_ok( 'List::RewriteElements' );
use_ok( 'Cwd' );
use_ok( 'File::Temp', qw| tempdir | );
use lib ( "t/testlib" );
use_ok( 'IO::Capture::Stdout' );
use Carp;

my $lre;
my @lines;
my $cap;

# Case 1:  header present; header rule supplied; header suppression criterion
# supplied; but header does not meet criterion for suppression

$lre  = List::RewriteElements->new ( {
    list        => [ map {"$_\n"} ( q{alpha}, 1..10 ) ],
    body_rule   => sub {
        my $record = shift;
        return (10 * $record);
    },
    header_rule   => sub {
        my $header = shift;
        return uc($header);
    },
    header_suppress  => sub {
        my $header = shift;
        chomp $header;
        return if $header eq 'omega';
    },
} );
isa_ok ($lre, 'List::RewriteElements');

$cap = IO::Capture::Stdout->new();
$cap->start();
$lre->generate_output();
$cap->stop();
chomp( @lines = $cap->read() );
is($lines[0], q{ALPHA}, "Header is correct; no suppression");
is($lines[1], q{10}, "First element of list is correct");
is($lines[-1], q{100}, "Last element of list is correct");

# Case 2:  header present; header rule supplied; header suppression criterion
# supplied; header meets criterion for suppression

$lre  = List::RewriteElements->new ( {
    list        => [ map {"$_\n"} ( q{alpha}, 1..10 ) ],
    body_rule   => sub {
        my $record = shift;
        return (10 * $record);
    },
    header_rule   => sub {
        my $header = shift;
        return uc($header);
    },
    header_suppress  => sub {
        my $header = shift;
        chomp $header;
        return if $header eq 'alpha';
    },
} );
isa_ok ($lre, 'List::RewriteElements');

is($lre->get_total_rows(), 0,
    "Count of rows out not yet determined");
is($lre->get_total_records(), 0,
    "Count of records out not yet determined");
is($lre->get_records_changed(), 0,
    "Count of records changed not yet determined");
is($lre->get_records_unchanged(), 0,
    "Count of records unchanged not yet determined");
is($lre->get_records_deleted(), 0,
    "Count of records deleted not yet determined");
ok(! defined ($lre->get_header_status()),
    "Header status not yet defined");

$cap = IO::Capture::Stdout->new();
$cap->start();
$lre->generate_output();
$cap->stop();
chomp( @lines = $cap->read() );

is($lre->get_total_rows(), 10,
    "Confirmed count of rows out");
is($lre->get_total_records(), 10,
    "Confirmed count of records out");
is($lre->get_records_changed(), 10,
    "Count of records changed confirmed");
is($lre->get_records_unchanged(), 0,
    "Count of records unchanged confirmed");
is($lre->get_records_deleted(), 0,
    "Confirmed count of records deleted");
is($lre->get_header_status, -1,
    "Header status unchanged");

is($lines[0], q{10},
    "First element of list is correct; suppression was correct");
is($lines[-1], q{100}, "Last element of list is correct");

# Case 3:  (same as #1, only from file)

{
    my $cwd = cwd();
    
    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    my $output = "./output";
    $lre  = List::RewriteElements->new ( {
        list        => [ map {"$_\n"} ( q{alpha}, 1..10 ) ],
        body_rule   => sub {
            my $record = shift;
            return (10 * $record);
        },
        header_rule   => sub {
            my $header = shift;
            return uc($header);
        },
        header_suppress  => sub {
            my $header = shift;
            chomp $header;
            return if $header eq 'omega';
        },
        output_file => $output,
    } );
    isa_ok ($lre, 'List::RewriteElements');

    is($lre->get_total_rows(), 0,
        "Count of rows out not yet determined");
    is($lre->get_total_records(), 0,
        "Count of records out not yet determined");
    is($lre->get_records_changed(), 0,
        "Count of records changed not yet determined");
    is($lre->get_records_unchanged(), 0,
        "Count of records unchanged not yet determined");
    is($lre->get_records_deleted(), 0,
        "Count of records deleted not yet determined");
    ok(! defined ($lre->get_header_status()),
        "Header status not yet defined");

    $lre->generate_output();
    ok(-f $output, "Output file created");

    is($lre->get_total_rows(), 11,
        "Confirmed count of rows out");
    is($lre->get_total_records(), 10,
        "Confirmed count of records out");
    is($lre->get_records_changed(), 10,
        "Count of records changed confirmed");
    is($lre->get_records_unchanged(), 0,
        "Count of records unchanged confirmed");
    is($lre->get_records_deleted(), 0,
        "Confirmed count of records deleted");
    is($lre->get_header_status, 1,
        "Header status unchanged");

    my @lines;
    open my $FH, $output or croak "Unable to open $output for reading";
    while (<$FH>) {
        chomp;
        push @lines, $_;
    }
    close $FH or croak "Unable to close $output";
    is($lines[0], q{ALPHA}, "Header is correct; no suppression");
    is($lines[1], q{10}, "First element of list is correct");
    is($lines[-1], q{100}, "Last element of list is correct");
    
    ok(chdir $cwd, 'changed back to original directory after testing');
}

# Case 4:  header present; header rule supplied; header suppression criterion
# supplied; header meets criterion for suppression; body suppression criterion
# supplied; some records meet criterion for suppression

$lre  = List::RewriteElements->new ( {
    list        => [ map {"$_\n"} ( q{alpha}, 1..10 ) ],
    body_rule   => sub {
        my $record = shift;
        chomp $record;
        return (10 * $record);
    },
    body_suppress   => sub {
        my $record = shift;
        chomp $record;
        return if ($record % 3 == 0);
    },
    header_rule   => sub {
        my $header = shift;
        chomp $header;
        return uc($header);
    },
    header_suppress  => sub {
        my $header = shift;
        chomp $header;
        return if $header eq 'alpha';
    },
} );
isa_ok ($lre, 'List::RewriteElements');

is($lre->get_total_rows(), 0,
    "Count of rows out not yet determined");
is($lre->get_total_records(), 0,
    "Count of records out not yet determined");
is($lre->get_records_changed(), 0,
    "Count of records changed not yet determined");
is($lre->get_records_unchanged(), 0,
    "Count of records unchanged not yet determined");
is($lre->get_records_deleted(), 0,
    "Count of records deleted not yet determined");
ok(! defined ($lre->get_header_status()),
    "Header status not yet defined");

$cap = IO::Capture::Stdout->new();
$cap->start();
$lre->generate_output();
$cap->stop();
chomp( @lines = $cap->read() );

is($lre->get_total_rows(),  7,
    "Confirmed count of rows out");
is($lre->get_total_records(),  7,
    "Confirmed count of records out");
is($lre->get_records_changed(),  7,
    "Count of records changed confirmed");
is($lre->get_records_unchanged(), 0,
    "Count of records unchanged confirmed");
is($lre->get_records_deleted(), 3,
    "Confirmed count of records deleted");
is($lre->get_header_status, -1,
    "Header status unchanged");

is($lines[0], q{10},
    "First element of list is correct; suppression was correct");
is($lines[-1], q{100}, "Last element of list is correct");

# Case 5:  header present; header rule supplied; header suppression criterion
# supplied; header does not meet criterion for either change or suppression;
# some records do not meet criteria for change

$lre  = List::RewriteElements->new ( {
    list        => [ map {"$_\n"} ( q{alpha}, 1..10 ) ],
    body_rule   => sub {
        my $record = shift;
        chomp $record;
        (! ($record % 3) ) ? return (30 * $record)
                           : return $record;
    },
    header_rule   => sub {
        my $header = shift;
        chomp $header;
        ($header eq 'omega') ? return uc($header)
                             : return $header;
    },
    header_suppress  => sub {
        my $header = shift;
        chomp $header;
        return if $header eq 'zeta';
    },
} );
isa_ok ($lre, 'List::RewriteElements');

is($lre->get_total_rows(), 0,
    "Count of rows out not yet determined");
is($lre->get_total_records(), 0,
    "Count of records out not yet determined");
is($lre->get_records_changed(), 0,
    "Count of records changed not yet determined");
is($lre->get_records_unchanged(), 0,
    "Count of records unchanged not yet determined");
is($lre->get_records_deleted(), 0,
    "Count of records deleted not yet determined");
ok(! defined ($lre->get_header_status()),
    "Header status not yet defined");

$cap = IO::Capture::Stdout->new();
$cap->start();
$lre->generate_output();
$cap->stop();
chomp( @lines = $cap->read() );

is($lre->get_total_rows(), 11,
    "Confirmed count of rows out");
is($lre->get_total_records(), 10,
    "Confirmed count of records out");
is($lre->get_records_changed(),  3,
    "Count of records changed confirmed");
is($lre->get_records_unchanged(), 7,
    "Count of records unchanged confirmed");
is($lre->get_records_deleted(), 0,
    "Confirmed count of records deleted");
is($lre->get_header_status,  0,
    "Header status unchanged");

is($lines[0], q{alpha}, "Header is correctly unchanged");
is($lines[1], q{1}, "First record in list is correct");
is($lines[3], q{90}, "Third record in list is correct");
is($lines[-2], q{270}, "Next to last record in list is correct");
is($lines[-1], q{10}, "Last element of list is correct");

# Case 6:  header present; header rule supplied; header suppression criterion
# not supplied; header does not meet criterion for change;
# some records do not meet criteria for change

$lre  = List::RewriteElements->new ( {
    list        => [ map {"$_\n"} ( q{alpha}, 1..10 ) ],
    body_rule   => sub {
        my $record = shift;
        chomp $record;
        (! ($record % 3) ) ? return (30 * $record)
                           : return $record;
    },
    header_rule   => sub {
        my $header = shift;
        chomp $header;
        ($header eq 'omega') ? return uc($header)
                             : return $header;
    },
} );
isa_ok ($lre, 'List::RewriteElements');

is($lre->get_total_rows(), 0,
    "Count of rows out not yet determined");
is($lre->get_total_records(), 0,
    "Count of records out not yet determined");
is($lre->get_records_changed(), 0,
    "Count of records changed not yet determined");
is($lre->get_records_unchanged(), 0,
    "Count of records unchanged not yet determined");
is($lre->get_records_deleted(), 0,
    "Count of records deleted not yet determined");
ok(! defined ($lre->get_header_status()),
    "Header status not yet defined");

$cap = IO::Capture::Stdout->new();
$cap->start();
$lre->generate_output();
$cap->stop();
chomp( @lines = $cap->read() );

is($lre->get_total_rows(), 11,
    "Confirmed count of rows out");
is($lre->get_total_records(), 10,
    "Confirmed count of records out");
is($lre->get_records_changed(),  3,
    "Count of records changed confirmed");
is($lre->get_records_unchanged(), 7,
    "Count of records unchanged confirmed");
is($lre->get_records_deleted(), 0,
    "Confirmed count of records deleted");
is($lre->get_header_status,  0,
    "Header status unchanged");

is($lines[0], q{alpha}, "Header is correctly unchanged");
is($lines[1], q{1}, "First record in list is correct");
is($lines[3], q{90}, "Third record in list is correct");
is($lines[-2], q{270}, "Next to last record in list is correct");
is($lines[-1], q{10}, "Last element of list is correct");

