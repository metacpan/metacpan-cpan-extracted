use strict;
use Test::More;
use Data::Dumper;
use Exception::Class::TryCatch;

use Getopt::Lucid ':all';
use Getopt::Lucid::Exception;

# Work around win32 console buffering that can show diags out of order
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
    Switch("-t"),
    Counter("--verb_osity"),
    Param("--file-name"),
    List("-I"),
    Keypair("-d"),
];

my $case = {
    argv    => [ qw( --verb_osity -t --file-name=passwd
                     -I /etc -I /lib -d os=linux ) ],
    result  => {
        t           => 1,
        verb_osity  => 1,
        "file-name" => "passwd",
        I           => [qw(/etc /lib)],
        d           => { os => "linux" },
    },
    desc    => "getopt accessors"
};

my $replace = {
    t => 2,
    verb_osity => 3,
    "file-name" => "group",
    I => [qw(/var /tmp)],
    d => { os => "win32" },
};

my $num_tests = 11 ;
plan tests => $num_tests ;

my ($gl, @cmd_line);
try eval { $gl = Getopt::Lucid->new($spec, \@cmd_line) };
catch my $err;
is( $err, undef, "spec should validate" );
SKIP: {
    if ($err) {
        skip "because spec did not validate", $num_tests - 1;
    }
    @cmd_line = @{$case->{argv}};
    my $expect = $case->{result};
    my %opts;
    try eval { %opts = $gl->getopt->options };
    catch my $err;
    if ($err) {
        fail( "$case->{desc} threw an exception")
            or diag "Exception is '$err'";
        skip "because getopt failed", $num_tests - 2;
    } else {
        for my $key (keys %{$case->{result}}) {
            no strict 'refs';
            my $result = $case->{result}{$key};
            (my $clean_key = $key ) =~ s/-/_/g;
            if ( ref($result) eq 'ARRAY' ) {
                is_deeply( [eval "\$gl->get_$clean_key"], $result,
                    "accessor for '$key' correct");
                &{"Getopt::Lucid::set_$clean_key"}($gl,@{$replace->{$key}});
                is_deeply( [eval "\$gl->get_$clean_key"], $replace->{$key},
                    "mutator for '$key' correct");
            } elsif ( ref($result) eq 'HASH' ) {
                is_deeply( {eval "\$gl->get_$clean_key"}, $result,
                    "accessor for '$key' correct");
                &{"Getopt::Lucid::set_$clean_key"}($gl,%{$replace->{$key}});
                is_deeply( {eval "\$gl->get_$clean_key"}, $replace->{$key},
                    "mutator for '$key' correct");
            } else {
                is( (eval "\$gl->get_$clean_key") , $result,
                    "accessor for '$key' correct");
                &{"Getopt::Lucid::set_$clean_key"}($gl,$replace->{$key});
                is( eval "\$gl->get_$clean_key", $replace->{$key},
                    "mutator for '$key' correct");
            }
        }
    }
}


