use strict;
use Test::More;
use Data::Dumper;
use Exception::Class::TryCatch;

use Getopt::Lucid ':all';
use Getopt::Lucid::Exception;
use lib ".";
use t::ErrorMessages;

# Work around buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

sub why {
    my %vars = @_;
    $Data::Dumper::Sortkeys = 1;
    return "\n" . Data::Dumper->Dump([values %vars],[keys %vars]) . "\n";
}

#--------------------------------------------------------------------------#
# Test cases
#--------------------------------------------------------------------------#

my $spec = [
    Switch("-t")->default(0),
    Counter("-v")->default(1),
    Param("--file-names")->default("hosts"),
    List("-I")->default("/home"),
    Keypair("-d")->default( arch => "i386" ),
    Switch("-x")->default(1),
    Param( '--undef' )->default( undef ),
    Param( '--empty' )->default( '' ),
    Param( '--no_param' )->default(),
    Param( '--without_default' ),
];

my $case = {
    argv    => [ qw( -tvv -I /etc -I /lib -d version=1.0a ) ],
    result  => {
        t => 1,
        v => 3,
        "file-names" => "hosts",
        I => [qw(/home /etc /lib)],
        d => { arch => "i386", version => "1.0a" },
        x => 1,
        undef => undef,
        empty => '',
        no_param => undef,
        without_default => undef,
    },
    desc    => "getopt"
};

my $config1 = {
    t => 1,
    v => 4,
    "file-names" => "group",
    I => [qw(/var /tmp)],
    d => { os => "win32" },
    z => 1,  # extra not in the spec
    undef => undef,
    empty => '',
    no_param => undef,
    without_default => undef,
};

# package variables for easier looping by name later

use vars qw(
    $merge_default $merge_result
    $append_default $append_result
    $replace_default $replace_result
);

$merge_default = {
    t => 1,
    v => 4,
    "file-names" => "group",
    I => [qw(/var /tmp)],
    d => { os => "win32" },
    x => 1,
    undef => undef,
    empty => '',
    no_param => undef,
    without_default => undef,
};

$append_default = {
    t => 1,
    v => 5,
    "file-names" => "group",
    I => [qw(/home /var /tmp)],
    d => { arch => "i386", os => "win32" },
    x => 1,
    undef => undef,
    empty => '',
    no_param => undef,
    without_default => undef,
};

$replace_default = {
    t => 1,
    v => 4,
    "file-names" => "group",
    I => [qw(/var /tmp)],
    d => { os => "win32" },
    x => 0,
    undef => undef,
    empty => '',
    no_param => undef,
    without_default => undef,
};

$merge_result = {
    t => 1,
    v => 6,
    "file-names" => "group",
    I => [qw(/var /tmp /etc /lib)],
    d => { os => "win32", version => "1.0a" },
    x => 1,
    undef => undef,
    empty => '',
    no_param => undef,
    without_default => undef,
};

$append_result = {
    t => 1,
    v => 7,
    "file-names" => "group",
    I => [qw(/home /var /tmp /etc /lib)],
    d => { arch => "i386", os => "win32", version => "1.0a" },
    x => 1,
    undef => undef,
    empty => '',
    no_param => undef,
    without_default => undef,
};

$replace_result = {
    t => 1,
    v => 6,
    "file-names" => "group",
    I => [qw(/var /tmp /etc /lib)],
    d => { os => "win32", version => "1.0a" },
    x => 0,
    undef => undef,
    empty => '',
    no_param => undef,
    without_default => undef,
};

my $num_tests = 30 ;
plan tests => $num_tests ;

my ($gl, @cmd_line, $err);
try eval { $gl = Getopt::Lucid->new($spec, \@cmd_line) };
catch $err;
is( $err, undef, "spec should validate" );
SKIP: {
    if ($err) {
        skip "because spec did not validate", $num_tests - 1;
    }
    @cmd_line = @{$case->{argv}};
    my %opts;
    try eval { $gl->getopt };
    catch my $err;
    if ($err) {
        fail( "$case->{desc} threw an exception")
            or diag "Exception is '$err'";
        skip "because getopt failed", $num_tests - 2;
    } else {
        my $expect = $case->{result} ;
        my %basic_default;
        for my $opt (@$spec) {
            local $_ = $opt->{name};
            (my $strip = $_) =~ s/^-+//g;
            $basic_default{$strip} = (exists $opt->{default})
                ? $opt->{default}
                : undef;
        }
        is_deeply( {$gl->defaults}, \%basic_default,
            "basic default options returned correctly") or
            diag why( got => {$gl->options}, expected => \%basic_default);
        is_deeply( {$gl->options}, $expect,
            "options with default from spec processed correctly") or
            diag why( got => {$gl->options}, expected => $expect);

        # Test things working correctly
        for my $fcn ( qw( merge append replace ) ) {
            no strict 'refs';
            my $call = "${fcn}_defaults";
            my ($default, $result) = map { "${fcn}_$_" } qw( default result );
            for my $c ( 0 .. 1 ) {
                $c  ? $gl->$call( %$config1 )
                    : $gl->$call( $config1 );
                my $msg = $c
                    ? "hash version"
                    : "hashref version";
                is_deeply( {$gl->defaults}, $$default,
                    "$call updated defaults correctly ($msg)") or
                    diag why( got => {$gl->defaults}, expected => $$default);
                is_deeply( {$gl->options}, $$result,
                    "$call refreshed options correctly ($msg)") or
                    diag why( got => {$gl->options}, expected => $$result);
                $gl->reset_defaults();
                is_deeply( {$gl->options}, $expect,
                    "options reset to spec correctly ($msg)") or
                    diag why( got => {$gl->options}, expected => $expect);
            }
        }

        # Test bad args
        for my $fcn ( qw( merge append replace ) ) {
            no strict 'refs';
            my $call = "${fcn}_defaults";
            eval { $gl->$call ( "bad_value" ) };
            catch $err;
            is( $err, _invalid_splat_defaults("$call()"),
                "$call() with invalid arguments throws exception");
            eval { $gl->$call ( I => {key => "value"} ) };
            catch $err;
            is( $err, _invalid_list("I","$call()"),
                "$call() with invalid list option throws exception");
            eval { $gl->$call ( d => [key => "value"] ) };
            catch $err;
            is( $err, _invalid_keypair("d","$call()"),
                "$call() with invalid keypair option throws exception");
        }
    }
}

