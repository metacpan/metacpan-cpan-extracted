# -*- perl -*-
#$Id: 02_list.t 1121 2007-01-01 14:43:51Z jimk $
# t/02_list.t - test what happens when source is a list
use strict;
use warnings;

use Test::More tests => 13;
use_ok( 'List::RewriteElements' );
use_ok( 'Cwd' );
use_ok( 'File::Temp', qw| tempdir | );
use lib ( "t/testlib" );
use_ok( 'IO::Capture::Stdout' );
use Carp;

my $lre;
my @lines;

$lre  = List::RewriteElements->new ( {
    list        => [ map {"$_\n"} (1..10) ],
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
        list        => [ map {"$_\n"} (1..10) ],
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

