# -*- perl -*-
#$Id: 03_file.t 1121 2007-01-01 14:43:51Z jimk $
# t/03_file.t - test what happens when source is a file
use strict;
use warnings;

use Test::More tests => 37;
use_ok( 'List::RewriteElements' );
use lib ( "t/testlib" );
use_ok( 'IO::Capture::Stdout' );
use_ok( 'Cwd' );
use_ok( 'File::Basename' );
use_ok( 'File::Spec' );
use_ok( 'File::Temp', qw| tempdir | );
use Carp;

my $lre;
my @lines;

$lre  = List::RewriteElements->new ( {
    file        => "t/testlib/simple.txt",
    body_rule   => sub {
        my $record = shift;
        return (10 * $record);
    },
} );
isa_ok ($lre, 'List::RewriteElements');

my $cap = IO::Capture::Stdout->new();
$cap->start();
$lre->generate_output();
$cap->stop();
chomp( @lines = $cap->read() );
is($lines[0], q{10}, "First element of list is correct");
is($lines[-1], q{100}, "Last element of list is correct");

{
    my $cwd = cwd();
    
    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    my $output = "./output";
    $lre  = List::RewriteElements->new ( {
        file        => "$cwd/t/testlib/simple.txt",
        body_rule   => sub {
            my $record = shift;
            return (10 * $record);
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
    is($lines[-1], q{100}, "Last element of list is correct");

    ok(chdir $cwd, 'changed back to original directory after testing');
}

{
    my $cwd = cwd();
    
    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    my $source = "$cwd/t/testlib/simple.txt";
    my $suffix = q{.out};
    $lre  = List::RewriteElements->new ( {
        file        => $source,
        body_rule   => sub {
            my $record = shift;
            return (10 * $record);
        },
        output_suffix => $suffix,
    } );
    isa_ok ($lre, 'List::RewriteElements');

    is($lre->get_output_path(), q{},
        "Output path not yet determined");
    is($lre->get_output_basename(), q{},
        "Output basename not yet determined");
    is($lre->get_output_basename(), q{},
        "Output basename not yet determined");

    is($lre->get_total_rows(), 0,
        "Total number of rows is not yet determined");
    is($lre->get_total_records(), 0,
        "Total number of records is not yet determined");
    is($lre->get_records_changed(), 0,
        "Total number of records changed is not yet determined");
    is($lre->get_records_unchanged(), 0,
        "Total number of records unchanged is not yet determined");
    is($lre->get_records_deleted(), 0,
        "Total number of records deleted is not yet determined");

    $lre->generate_output();
    my $output = File::Spec->catfile( cwd(), basename($source) . $suffix );
    ok(-f $output, "Output file created");
    is($lre->get_output_path(), $output,
        "Output path correctly reported");
    is($lre->get_output_basename(), basename($output),
        "Output basename correctly reported");

    my @lines;
    open my $FH, $output or croak "Unable to open $output for reading";
    while (<$FH>) {
        chomp;
        push @lines, $_;
    }
    close $FH or croak "Unable to close $output";
    is($lines[0], q{10}, "First element of list is correct");
    is($lines[-1], q{100}, "Last element of list is correct");

    ok(chdir $cwd, 'changed back to original directory after testing');
}

{
    my $cwd = cwd();
    
    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    my $output = "./output";
    my $source = "$cwd/t/testlib/simple.txt";
    my $suffix = q{.out};
    $lre  = List::RewriteElements->new ( {
        file            => $source,
        body_rule       => sub {
            my $record = shift;
            return (10 * $record);
        },
        output_file     => $output,
        output_suffix   => $suffix,
    } );
    isa_ok ($lre, 'List::RewriteElements');

    $lre->generate_output();
    ok(-f $output, "'output_file' took precedence over 'output_suffix");

    my @lines;
    open my $FH, $output or croak "Unable to open $output for reading";
    while (<$FH>) {
        chomp;
        push @lines, $_;
    }
    close $FH or croak "Unable to close $output";
    is($lines[0], q{10}, "First element of list is correct");
    is($lines[-1], q{100}, "Last element of list is correct");
    untie @lines;

    ok(chdir $cwd, 'changed back to original directory after testing');
}

