use strict;
use Test::More;
use Data::Dumper;
use Exception::Class::TryCatch;

use Getopt::Lucid ':all';
use Getopt::Lucid::Exception;
use lib ".";
use t::ErrorMessages;

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

my ($num_tests, @good_specs);

    push @good_specs, { 
        label => "test",
        spec  => [
            Switch("test|t")->default(1),
            Counter("verbose|v")->default(2),
            Param("file|f")->valid(qr/[a-z]+/)->default("foo"),
            List("lib|l")->default(qw( /var /tmp ))->valid(qr/[\/\w]+/),
            Keypair("def|d","os|arch",qr/\w+/)->default(
              {os => 'linux', arch => 'i386'}
            ),
        ],
        cases => [
            { 
                desc    => "no args, no config",
                argv    => [  ],
                config => undef, 
                result  => {
                  append => { 
                    "test" => 1, 
                    "verbose" => 2,
                    "file" => "foo",
                    "lib" => [qw( /var /tmp )],
                    "def" => {os => 'linux', arch => 'i386'},
                  },
                  merge => { 
                    "test" => 1, 
                    "verbose" => 2,
                    "file" => "foo",
                    "lib" => [qw( /var /tmp )],
                    "def" => {os => 'linux', arch => 'i386'},
                  },
                  replace => { 
                    "test" => 1, 
                    "verbose" => 2,
                    "file" => "foo",
                    "lib" => [qw( /var /tmp )],
                    "def" => {os => 'linux', arch => 'i386'},
                  },
                },
            },          
            { 
                desc    => "no args, valid config",
                argv    => [  ],
                config => {
                    "verbose" => 1,
                    "file"  => "bar",
                    "lib"   => "/home",
                    "def"   => { os => 'MSWin32' },
                },
                result  => { 
                  append => {
                    "test" => 1, 
                    "verbose" => 3,
                    "file" => "bar",
                    "lib" => [qw( /var /tmp /home )],
                    "def" => { os => 'MSWin32', arch => 'i386'},
                  },
                  merge => {
                    "test" => 1, 
                    "verbose" => 1,
                    "file" => "bar",
                    "lib" => [qw( /home )],
                    "def" => { os => 'MSWin32' },
                  },
                  replace => {
                    "test" => 0, 
                    "verbose" => 1,
                    "file" => "bar",
                    "lib" => [qw( /home )],
                    "def" => { os => 'MSWin32' },
                  },
                },
            },          
            { 
                desc    => "args plus valid config",
                argv    => [ qw/--def arch=amd64 / ],
                config => {
                    "verbose" => 1,
                    "file"  => "bar",
                    "lib"   => "/home",
                    "def"   => { os => 'MSWin32' },
                },
                result  => { 
                  append => {
                    "test" => 1, 
                    "verbose" => 3,
                    "file" => "bar",
                    "lib" => [qw( /var /tmp /home )],
                    "def" => { os => 'MSWin32', arch => 'amd64'},
                  },
                  merge => {
                    "test" => 1, 
                    "verbose" => 1,
                    "file" => "bar",
                    "lib" => [qw( /home )],
                    "def" => { os => 'MSWin32', arch => 'amd64' },
                  },
                  replace => {
                    "test" => 0, 
                    "verbose" => 1,
                    "file" => "bar",
                    "lib" => [qw( /home )],
                    "def" => { os => 'MSWin32', arch => 'amd64' },
                  },
                },
            },          
            { 
                argv    => [ ],
                exception   => "Getopt::Lucid::Exception::Spec",
                config => {
                    "file"  => "123",
                },
                error_msg => _default_invalid("file","123",),
                desc    => "invalid config"
            },
        ]
    };
    
for my $t (@good_specs) {
    $num_tests += 1 + 6 * @{$t->{cases}};
}

plan tests => $num_tests;

#--------------------------------------------------------------------------#
# Test good specs
#--------------------------------------------------------------------------#

my ($trial, @cmd_line);

while ( $trial = shift @good_specs ) {
    try eval { Getopt::Lucid->new($trial->{spec}, \@cmd_line) };
    catch my $err;
    is( $err, undef, "$trial->{label}: spec should validate" );
    SKIP: {    
        if ($err) {
            my $num_tests = 6 * @{$trial->{cases}};
            skip "because $trial->{label} spec did not validate", $num_tests;
        }
        for my $case ( @{$trial->{cases}} ) {
          for my $method ( qw/append merge replace/ ) {
            no strict 'refs';
            my $cmd = $method . "_defaults";
            my $gl = Getopt::Lucid->new($trial->{spec}, \@cmd_line);
            @cmd_line = @{$case->{argv}};
            try eval { 
              $gl->getopt;
              $gl->$cmd( $case->{config} ) if $case->{config};
            };
            catch my $err;
            if (defined $case->{exception}) { # expected
                ok( $err && $err->isa( $case->{exception} ), 
                    "$trial->{label} $method\_defaults\: $case->{desc} should throw exception" )
                    or diag why( got => ref($err), expected => $case->{exception});
                is( $err, $case->{error_msg}, 
                    "$trial->{label} $method\_defaults\: $case->{desc} error message correct");
            } elsif ($err) { # unexpected
                fail( "$trial->{label} $method\_defaults\: $case->{desc} threw an exception")
                    or diag "Exception is '$err'";
                pass("$trial->{label} $method\_defaults\: skipping \@ARGV check");
            } else { # no exception
                my %opts = $gl->options;
                is_deeply( \%opts, $case->{result}{$method}, 
                    "$trial->{label} $method\_defaults\: $case->{desc}" ) or
                    diag why( got => \%opts, expected => $case->{result}{$method});
                my $argv_after = $case->{after} || [];
                is_deeply( \@cmd_line, $argv_after,
                    "$trial->{label} $method\_defaults\: \@cmd_line correct after processing") or
                    diag why( got => \@cmd_line, expected => $argv_after);
            }
          }
        }
    }
}


