#!perl

use strict;
use warnings;
use Test::More;
use IPC::Open3;
use File::Spec;
use Config;
use Devel::TraceUse ();
use lib ();

my $tlib  = File::Spec->catdir( 't', 'lib' );
my $tlib2 = File::Spec->catdir( 't', 'lib2' );
my $vlib  = defined $lib::VERSION ? " $lib::VERSION" : '';

# all command lines prefixed with $^X -I"t/lib"
my @tests = (
    [ << 'OUT', qw(-d:TraceUse -MParent -e1) ],
Modules used from -e:
   1.  Parent, -e line 0 [main]
   2.    Child, Parent.pm line 3
   3.      Sibling, Child.pm line 3
OUT
    [ << 'OUT', qw(-d:TraceUse -MChild -e1) ],
Modules used from -e:
   1.  Child, -e line 0 [main]
   2.    Sibling, Child.pm line 3
   3.      Parent, Sibling.pm line 4
OUT
    [ << 'OUT', qw(-d:TraceUse -MSibling -e1) ],
Modules used from -e:
   1.  Sibling, -e line 0 [main]
   2.    Child, Sibling.pm line 3
   3.      Parent, Child.pm line 4
OUT
    [ << 'OUT', qw(-d:TraceUse -MM1 -e1) ],
Modules used from -e:
   1.  M1, -e line 0 [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
OUT
    [ << 'OUT', qw(-d:TraceUse -MM4 -e1) ],
Modules used from -e:
   1.  M4, -e line 0 [main]
   2.    M5, M4.pm line 3
   3.      M6, M5.pm line 9 [M5::in]
OUT
    [ << 'OUT', qw(-d:TraceUse -MM1 -e), 'require M4' ],
Modules used from -e:
   1.  M1, -e line 0 [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
   4.  M4, -e line 1 [main]
   5.    M5, M4.pm line 3
   6.      M6, M5.pm line 9 [M5::in]
OUT
    [ << 'OUT', qw(-d:TraceUse -e), 'require M4; use M1' ],
Modules used from -e:
   1.  M1, -e line 1 [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
   4.  M4, -e line 1 [main]
   5.    M5, M4.pm line 3
   6.      M6, M5.pm line 9 [M5::in]
OUT
    [ << 'OUT', qw(-d:TraceUse -MM4 -MM1 -e M5->load) ],
Modules used from -e:
   1.  M4, -e line 0 [main]
   2.    M5, M4.pm line 3
   3.      M6, M5.pm line 9 [M5::in]
   7.      M7 0, M5.pm line 4
   4.  M1, -e line 0 [main]
   5.    M2, M1.pm line 3
   6.      M3, M2.pm line 3
Possible proxies:
   2 -e line 0, sub main::BEGIN
OUT
    [ << 'OUT', qw(-d:TraceUse -e), 'eval { use M1 }' ],
Modules used from -e:
   1.  M1, -e line 1 [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
OUT
    [ << "OUT", '-d:TraceUse', "-Mlib=$tlib2", '-MM8', '-e1' ],
Modules used from -e:
   0.  lib$vlib, -e line 0 [main]
Modules used, but not reported:
  M8.pm
OUT
    [ << "OUT", '-d:TraceUse', "-Mlib=$tlib2", '-MM1', '-MM8', '-e1' ],
Modules used from -e:
   0.  lib$vlib, -e line 0 [main]
   0.  M1, -e line 0 [main]
   0.    M2, M1.pm line 3
   0.      M3, M2.pm line 3
   0.  M8, -e line 0 [main]
Possible proxies:
   3 -e line 0, sub main::BEGIN
OUT
    [ << "OUT", '-d:TraceUse', "-Mlib=$tlib2", '-MM7', '-MM8', '-e1' ],
Modules used from -e:
   0.  lib$vlib, -e line 0 [main]
   0.  M7 0, -e line 0 [main]
   0.  M8, -e line 0 [main]
Possible proxies:
   3 -e line 0, sub main::BEGIN
OUT
    [ << 'OUT', qw(-d:TraceUse -e), 'eval { require M10 }' ],
Modules used from -e:
   1.  M10, -e line 1 [main] (FAILED)
OUT
    [   << 'OUT', qw(-d:TraceUse -e), "eval { require M10 };\npackage M11;\neval { require M10 }" ],
Modules used from -e:
   1.  M10, -e line 1 [main] (FAILED)
   2.  M10, -e line 3 [M11] (FAILED)
OUT
    [   << "OUT", '-d:TraceUse', '-MM7', "-Mlib=$tlib2", '-MM1', '-MM8', '-e1' ],
Modules used from -e:
   0.  M7 0, -e line 0 [main]
   0.  lib$vlib, -e line 0 [main]
   0.  M1, -e line 0 [main]
   0.    M2, M1.pm line 3
   0.      M3, M2.pm line 3
   0.  M8, -e line 0 [main]
Possible proxies:
   4 -e line 0, sub main::BEGIN
OUT
    [   << 'OUT', '-d:TraceUse', "-I$tlib2", qw( -MM4 -MM1 -MM8 -MM10 -e M5->load) ],
Modules used from -e:
   1.  M4, -e line 0 [main]
   2.    M5, M4.pm line 3
   3.      M6, M5.pm line 9 [M5::in]
  11.      M7 0, M5.pm line 4
   4.  M1, -e line 0 [main]
   5.    M2, M1.pm line 3
   6.      M3, M2.pm line 3
   7.  M8, -e line 0 [main]
   8.  M10, -e line 0 [main]
   9.    M11 1.01, M10.pm line 3 [M8]
  10.    M12 1.12, M10.pm line 4 [M8]
Possible proxies:
   4 -e line 0, sub main::BEGIN
OUT
    [ << 'OUT', qw(-d:TraceUse -c -MM1 -e), 'require M4' ],
Modules used from -e:
   1.  M1, -e line 0 [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
-e syntax OK
OUT
);

# Module::CoreList-related tests
if ( eval { require Module::CoreList; 1; } ) {
    diag "Module::CoreList $Module::CoreList::VERSION installed";

    # Module::CoreList always knew about those
    push @tests,
        [ << 'OUT', '-d:TraceUse=hidecore:5.5.30', '-MConfig', '-e1' ],
Modules used from -e:
OUT
        [ << 'OUT', '-d:TraceUse=hidecore:5.006001', '-MConfig', '-e1' ],
Modules used from -e:
OUT
        if $] < 5.013010;
    push @tests, [ [
        "Module::CoreList $Module::CoreList::VERSION doesn't know about Perl 4"
    ], << "OUT", '-d:TraceUse=hidecore:4', '-e1' ];
Modules used from -e:
OUT

    # test hiding a well-known core module
    my $this_perl = Devel::TraceUse::numify($]);
    push @tests, [ << "OUT", '-d:TraceUse=hidecore', '-Mstrict', '-e1' ];
Modules used from -e:
OUT

    # does Module::CoreList know about this Perl?
    if ( !exists $Module::CoreList::version{$this_perl} ) {
        $tests[-1][0] .= << 'OUT';    # update the output
   1.  strict %%%, -e line 0 [main]
OUT
        unshift @{ $tests[-1] }, [         #  add a warning
            "Module::CoreList $Module::CoreList::VERSION doesn't know about Perl $this_perl"
        ];
    }

    # convert Module::CoreList devel version numbers to a number
    my $corelist_version = $Module::CoreList::VERSION;
    $corelist_version =~ tr/_//d;

    # Module::CoreList didn't know about 5.001 until its version 2.00
    push @tests, [ << 'OUT', '-d:TraceUse=hidecore:5.1', '-MConfig', '-e1' ],
Modules used from -e:
   1.  Config, -e line 0 [main]
OUT
        if $corelist_version >= 2 && $] < 5.013010;
}
else {
    diag "Module::CoreList not installed";
    push @tests, [ [
        q"Can't locate Module/CoreList.pm in @INC (@INC contains: <DELETED>)",
         'END failed--call queue aborted.'
    ], '', '-d:TraceUse=hidecore', '-e1' ];
}

my $warn_d = 'Use -d:TraceUse for more accurate information.';

# -MDevel::TraceUse usually produces the same output as -d:TraceUse
for ( 0 .. $#tests ) {
    unshift @{ $tests[$_] }, [] unless ref $tests[$_][0];
    push( @tests, [ @{ $tests[$_] } ] );
    $tests[-1][0] = [ @{ $tests[$_][0] } ];
    # keep options the same
    $tests[-1][2] =~ s/^-d:TraceUse/-MDevel::TraceUse/;
    # also expect the note about -d:TraceUse
    unshift @{ $tests[-1][0] }, $warn_d;
}

# but there are some exceptions
push @tests, (
    [ [], << 'OUT', qw(-d:TraceUse -e), 'eval q(use M1)' ],
Modules used from -e:
   1.  M1, -e line 1 (eval 1) [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
OUT
    [ [$warn_d], << 'OUT', qw(-MDevel::TraceUse -e), 'eval q(use M1)' ],
Modules used from -e:
   1.  M1, (eval 1) [main]
   2.    M2, M1.pm line 3
   3.      M3, M2.pm line 3
OUT
    [ [], << 'OUT', qw(-d:TraceUse -MM9 -e1) ],
Modules used from -e:
   1.  M9, -e line 0 [main]
   2.    M6, M9.pm line 3 (eval 1)
OUT
    [ [$warn_d], << 'OUT', qw(-MDevel::TraceUse -MM9 -e1) ],
Modules used from -e:
   1.  M9, -e line 0 [main]
   2.  M6, (eval 1) [M9]
OUT
);

my @outputs = (
    undef,
    'out.txt',
    File::Spec->rel2abs('out.txt'),
);

plan tests => (scalar(@outputs) * scalar(@tests));

my @temp_files;

# Clean-up
END {
    unlink for grep { -f $_ } @temp_files;
}

foreach my $o (@outputs) {
    run_test($o, @$_) for @tests;
}

sub run_test {
    my ( $output_file, $warns, $errput, @cmd ) = @_;

    if ( defined $output_file ) {
        #diag $output_file";
        @cmd = map {
            s/^(-.*?:TraceUse=..*)$/$1,output:$output_file/;
            s/^(-.*?:TraceUse)=?$/$1=output:$output_file/;
            $_
        } @cmd;
        push @temp_files, $output_file;
    }

    # Test name
    ( my $mesg = "Trace for: perl @cmd" ) =~ s/\n/\\n/g;

    # run the test subcommand
    local ( *IN, *OUT, *ERR );
    my $pid = open3( \*IN, \*OUT, \*ERR, $^X, '-Iblib/lib', "-I$tlib", @cmd );
    my @errput = map { s/[\015\012]*$//; $_ } <ERR>;
    waitpid( $pid, 0 );

    my @out;
    if (defined $output_file && length $errput) {
        unless (-f $output_file) {
            fail $mesg;
            diag qq(Missing expected output file "$output_file");
            return;
        }
        open my $f, '<', $output_file;
        @out = map { s/[\015\012]*$//; $_ } <$f>;
        close $f;
        unlink $f;
    }

    # we want to ignore modules loaded by those libraries
    my $nums = 1;
    for my $lib (qw( lib sitecustomize.pl )) {
        for my $arr (\@errput, \@out) {
            if ( grep /\. +.*\Q$lib\E[^,]*,/, @$arr ) {
                @$arr = normalize( $lib, @$arr );
                $nums = 0;
            }
        }
    }

    # take sitecustomize.pl into account in our expected errput
    ( $nums, $errput ) = add_sitecustomize( $nums, $errput, @cmd )
        if $Config{usesitecustomize};

    # clean up the "Can't locate" error message
    s/\(\@INC contains: .*/(\@INC contains: <DELETED>)/ for @errput;

    push @errput, @out;

    # make sure the 'syntax OK' is at the end
    if ( grep $_ eq '-c', @cmd ) {
        @errput = sort { $a =~ /syntax OK/ ? 1 : $b =~ /syntax OK/ ? -1 : 0 }
            @errput;
    }

    # remove version number of core modules used in testing
    s/(strict )[^,]+,/$1%%%,/g for @errput;

    # compare the results
    my @expected = map { s/[\015\012]*$//; $_ } split /^/, $errput;
    @expected = map { s/^(\s*\d+)\./%%%%./; $_ } @expected if !$nums;
    unshift @expected, @$warns;

    is_deeply( \@errput, \@expected, $mesg )
        or diag map ( {"$_\n"} '--- Got ---', @errput ),
        "--- Expected ---\n$errput";
}

# removes unexpected modules loaded by somewhat expected ones
# and normalize the errput so we can ignore them
sub normalize {
    my ( $lib, @lines ) = @_;
    my $loaded_by = 0;
    my $tab;
    for (@lines) {
        s/^(\s*\d+)\./%%%%./;
        if (/\.( +)\Q$lib\E[^,]*,/) {
            $loaded_by = 1;
            $tab       = $1 . '  ';
            next;
        }
        if ($loaded_by) {
            if   (/^%%%%\.$tab/) { $_         = 'deleted' }
            else                 { $loaded_by = 0 }
        }
    }
    return grep { $_ ne 'deleted' } @lines;
}

my $diag;

sub add_sitecustomize {
    my ( $nums, $errput, @cmd ) = @_;
    my $sitecustomize_path
        = File::Spec->catfile( $Config{sitelib}, 'sitecustomize.pl' );
    my ($sitecustomize) = grep { /\bsitecustomize\.pl$/ } keys %INC;

    # provide some info to the tester
    if ( !$diag++ ) {
        diag "This perl has sitecustomize.pl enabled, ",
            -e $sitecustomize_path
            ? "and the file $sitecustomize_path exists"
            : "but the file $sitecustomize_path does not exist";
        diag "sitecustomize.pl was loaded successfully via $INC{$sitecustomize}"
            if $sitecustomize;
    }
    $sitecustomize_path = $INC{$sitecustomize} if !-e $sitecustomize_path;

    # the output depends on the existence of sitecustomize.pl
    if ( -e $sitecustomize_path ) {

        # Loaded so first it's not caught by our @INC hook:
        #  Modules used, but not reported:
        #    /home/book/local/5.8.9/site/lib/sitecustomize.pl

        # grab the various postambles, starting from the end
        my ( @postambles, @unreported );
        $errput =~ s/(-e syntax OK.*)//s
            and unshift @postambles, $1;
        $errput =~ s/(Possible proxies:.*)//s
            and unshift @postambles, $1;
        $errput =~ s/(Modules used, but not reported:.*)//s
            and ( undef, @unreported ) = split( /^/, $1 );
        push @unreported, "  $sitecustomize\n";

        # put the postambles back
        $errput .= join '',
            "Modules used, but not reported:\n", ( sort @unreported ),
            @postambles;
    }
    elsif ( grep { $_ eq '-d:TraceUse' } @cmd ) {

        # Loaded first, but FAIL. The debugger will tell us with an older Perl.
        #  Modules used from -e:
        #     1.  C:/perl/site/lib/sitecustomize.pl, -e line 0 [main] (FAILED)
        if ( $] < 5.011 ) {
            $errput =~ s{Modules used from.*?^}
                        {$&   0.  $sitecustomize, -e line 0 [main] (FAILED)\n}sm;
            $nums = 0;
        }
    }

    # updated values
    return ( $nums, $errput );
}

