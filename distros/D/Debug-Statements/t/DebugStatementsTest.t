#!/home/utils/perl-5.20/5.20.1-006/bin/perl
##!/home/utils/perl-5.8.8/bin/perl
##!/home/utils/perl-5.14/5.14.1-nothreads-64/bin/perl
##!//home/utils/perl-5.16/5.16.2-nothreads-64/bin/perl
##!//home/utils/perl-5.18/5.18.4-001/bin/perl
use warnings;
use strict;
#use 5.014;    # enables 'say' and 'strict'
#use autodie;
sub say { print @_, "\n" }
use warnings FATAL => 'all';
use Getopt::Long;
use Test::More;
use Test::Fatal qw(lives_ok dies_ok);
use Test::Output qw(stdout_is stdout_like);
# FindBin helps t/DebugStatementsTest.t find lib/Debug/Statements.pm during 'dzil test'
use FindBin;
use lib "$FindBin::Bin/../lib";
use Debug::Statements qw(d d0 d1 d2 d3 D ls);
use_ok('Test::More') or die; 
use_ok('Test::Fatal') or die; 
use_ok('Test::Output') or die; 
use_ok('PadWalker') or die; 
use_ok('Debug::Statements') or die; 
use Data::Dumper;
$Data::Dumper::Terse = 1;                # eliminate the $VAR1

# Parse options
my $d = 0;
my $dd = 0;
my %opt;
$opt{print} = 0;
$opt{die} = 0;
Getopt::Long::GetOptions( \%opt, 'd' => sub { $d = 1 }, 'dd' => sub { $dd = 1 }, 'die', 'print' );
d( '', 10 ) if $dd;                   # Turn on say statements to help debug Debug::Statements.pm module

# Globals for testing
my $debug;
my $scalar          = 'myvalue';
my $scalar2         = 'myvalueTwo';
my $scalar3         = 'myvalueThree';
my @list            = ( 'zero', 1, 'two', "3" );
my @listdeleteme    = ( 'zero', 1, 'two', "3" );
my $listref         = \@list;
my $i;
my @nestedlist = ( [ 0, 1 ], [ 2, 3 ] );
my %hash = ( 'one' => 2, 'three' => 4 );
my $hashref        = \%hash;
my %nestedhash = (
    flintstones => {
        husband => "fred",
        pal     => "barney",
    },
);
my $nestedhashref = \%nestedhash;
my $ref;

# td() is the easiest to use since it assumes d() with one argument.  Internally it calls tsub().  td0() td1() td2() also call tsub().
# tdd() is similar, but supports d() d2() d3().  Also supports a second argument.  Does not automatically assume a description if none is given.

# tdd { d('$scalar')  } $exp, 'scalar';
sub tdd (&$$) {
    my ($coderef, $expected, $description) = @_;
    if ( $opt{print} ) {
        $coderef->();
    } else {
        if( ref $expected eq ref qr// ) {
            die if ! stdout_like {$coderef->()} $expected, $description  and $opt{die};
        } else {
            die if ! stdout_is {$coderef->()} $expected, $description  and $opt{die};
        }
    }
}

# tsub 'd', '$scalar', $exp, '';
sub tsub {
    my ($sub, $argument, $expected, $addl_description) = @_;
    $addl_description = '' if ! defined $addl_description;
    no strict;
    if ( $opt{print} ) {
        $sub->($argument) if defined $opt{print} and $opt{print};
    } else {
        if ( ref($argument) =~ /^(SCALAR|ARRAY|HASH|REF|CODE|GLOB)$/ ) {
            my $warning = qr(WARNING:.*was given a reference to a variable instead of a single-quoted string);
            die if ! like( $warning, $expected )  and $opt{die};
            return;
        }
        my $dummy = eval{$argument};
        $$argument = eval $dummy;
        if( ref $expected eq ref(qr//) ) {
            #die if ! stdout_like {$sub->($argument)} $expected, "$argument  $addl_description"  and $opt{die};  # Not working in 5.18 and 5.20
            die if ! stdout_like {$$argument = eval $dummy ; $sub->($argument)} $expected, "$argument  $addl_description"  and $opt{die}; # works
        } else {
            #D 'No regex';
            #die if ! stdout_is {$sub->($argument)} $expected, "$argument  $addl_description"  and $opt{die}; # Not working in 5.18 and 5.20
            #use Capture::Tiny 'capture_merged'; my ($merged, $status) = Capture::Tiny::capture_merged {$sub->($argument)}; say "\$merged = $merged"; # Not working in 5.18 and 5.20
            die if ! stdout_is {$$argument = eval $dummy ; $sub->($argument)} $expected, "$argument  $addl_description"  and $opt{die}; # works
        }
    }
    use strict;
}

# All these are equivalent:
#     tdd { d('$scalar')  } $exp, 'scalar';
#     tsub 'd', '$scalar', $exp, '';
#     td '$scalar', $exp, '';
sub td {
    my ($argument, $expected, $addl_description) = @_;
    tsub ('d', $argument, $expected, $addl_description);
}
sub td0 {
    my ($argument, $expected, $addl_description) = @_;
    tsub ('d0', $argument, $expected, $addl_description);
}
sub td1 {
    my ($argument, $expected, $addl_description) = @_;
    tsub ('d1', $argument, $expected, $addl_description);
}
sub td2 {
    my ($argument, $expected, $addl_description) = @_;
    tsub ('d2', $argument, $expected, $addl_description);
}

my $header = 'DEBUG sub __ANON__:';
my $header2 = 'DEBUG2 sub __ANON__:';
my $vr = '\s+[\$\@\%]\S+\s+=\s+';
my $r1 = qr($header${vr}2);
my $rn = qr($header${vr}\{\s+'flintstones'\s+=>\s+\{\s+'husband'\s+=>\s+'fred',\s+'pal'\s+=>\s+'barney'\s+\}\s+\});
my $rnt = qr($header${vr}\{\s+'flintstones'\s+=>\s+\{\s+'husband'\s+=>\s+'fred',\s+\.\.\.);
my $rnf = qr($header${vr}\{\s+'husband'\s+=>\s+'fred',\s+'pal'\s+=>\s+'barney'\s+\});
my $rnfh = qr($header${vr}'fred');
my $rnfp = qr($header${vr}'barney');
my $rnfhp = qr($header${vr}'(fred|barney)');
my $l = '\[\s+\'zero\',\s+1,\s+\'two\',\s+\'3\'\s+\]';
my $rl = qr($header${vr}${l});
my $rld2 = qr($header2${vr}${l});
my $lsort = '\[\s+1,\s+\'3\',\s+\'two\',\s+\'zero\'\s+\]';
my $rl1 = qr($header${vr}\[ 'zero', 1, 'two', '3' ]);
my $rle = qr($header${vr}.*\d+.*\s+${l});
my $rls = qr($header${vr}${lsort});
my $h = '\{\s+\'one\'\s+=>\s+2,\s+\'three\'\s+=>\s+4\s+\}';
my $rh = qr($header${vr}${h});
my $rhd2 = qr($header2${vr}${h});
my $rh1 = qr($header${vr}\{ 'one' => 2, 'three' => 4 \});
my $rhe = qr($header${vr}.*\d+.*\s+${h});
my $rhs = qr($header${vr}${h});
#D "Hello World";
#D '$scalar';
#D '@list %hash';
#die;
testScalar();
testArray();
testHash();
testPackageVars();
testSpecial();
testLevels();
testPrefixSuffix();
testMultipleVars();
testOption_printdebug();
testInternalDebug();
testOption_printsub();
testOption_compress();
testOption_disable();
testOption_flag();
testOption_Chomp();
testOption_Elements();
testOption_lineNumber();
testOption_tRuncate();
testOption_Sort();
testOption_Timestamp();
testOptions_multiple();
testOption_Q();
testOption_Die();
#say "\n### No subroutine";
#d('$scalar');
#d('@list');
#d('%hash');
testLsl();
#test_PerlCritic("/home/ckoknat/s/regression/Debug/Statements.pm");die;  ########
Test::More::done_testing();
exit 0;

say "#################";
say "Should print comments from Statements.pm";
open FILE, "/home/ate/scripts/regression/Debug/Statements.pm" or die "unable to open file for reading";
while ( my $line = <FILE> ) {
    if ( $line =~ /^\s*#\s*Used/ ) {
        d('$line');
        d("line $. = '$line'");
    }
}
say "Should print comments from Statements.pm such as       DEBUG:  At line 300:  \$line = '    # Used during development of this module";
open FILE, "/home/ate/scripts/regression/Debug/Statements.pm" or die "unable to open file for reading";
while ( my $line = <FILE> ) {
    if ( $line =~ /^\s*#\s*Used/ ) {
        d( '$line', 'n' );
    }
}

# 0.58 seconds
#Debug::Statements::disable()
#for my $i (1..100) {
#}

#test_PerlCritic($file)
sub test_PerlCritic {
    my $file = shift;
    # 5.8.6 does not have Test::Perl::Critic
    #my @exclude = ( qw( RequireExtendedFormatting RequireDotMatchAnything RequireLineBoundaryMatching ProhibitImplicitNewlines ProhibitReusedNames ProhibitConstantPragma ProhibitPostfixControls ProhibitExcessMainComplexity ) );
    ###### fix the next few lines and copy to k.t and CPN.t and cpn.t  OR  better yet include it with regression
    ##use Test::Perl::Critic( -severity => 3, -exclude => ['RequireExtendedFormatting','RequireDotMatchAnything','RequireLineBoundaryMatching','ProhibitImplicitNewlines','ProhibitReusedNames','ProhibitConstantPragma','ProhibitPostfixControls','ProhibitExcessMainComplexity'] ); # reported no failures
    ##Test::Perl::Critic::critic_ok($file,  "Test::Perl::Critic for $file with severity level 3 but excluding:\n     " . join "\n     ", ('RequireExtendedFormatting','RequireDotMatchAnything','RequireLineBoundaryMatching','ProhibitImplicitNewlines','ProhibitReusedNames','ProhibitConstantPragma','ProhibitPostfixControls','ProhibitExcessMainComplexity') );
    #use Test::Perl::Critic( -severity => 3, -exclude => [ qw( RequireExtendedFormatting RequireDotMatchAnything RequireLineBoundaryMatching ProhibitImplicitNewlines ProhibitReusedNames  ProhibitConstantPragma ProhibitPostfixControls ProhibitExcessMainComplexity] ) );
    #use Test::Perl::Critic(
    #    -severity => 3,
    #    -exclude  => [qw( RequireExtendedFormatting RequireDotMatchAnything RequireLineBoundaryMatching ProhibitImplicitNewlines ProhibitReusedNames ProhibitConstantPragma ProhibitPostfixControls ProhibitExcessMainComplexity )]
    #);    # reported no failures
    #Test::Perl::Critic::critic_ok( $file, "Test::Perl::Critic for $file with severity level 3 but excluding:\n     " . ( join "\n     ", qw( RequireExtendedFormatting RequireDotMatchAnything RequireLineBoundaryMatching ProhibitImplicitNewlines ProhibitReusedNames ProhibitConstantPragma ProhibitPostfixControls ProhibitExcessMainComplexity ) ) );
    # NOTE - if you get the error "Subroutine "abcd" with high complexity score" you can disable the check:
    #     sub checkName { ## no critic (ProhibitExcessComplexity)
    # For other errors see Perl::Critic::PolicySummary
}



sub testScalar {
    say "\n### testScalar";
    my $exp = "$header  \$scalar = 'myvalue'\n";
    $d = 1;
    stdout_like { d('$scalar')} qr(is printing debug statements), 'First run of Debug::Statements, inside $scalar';
    stdout_is { d('$scalar')} $exp, '$scalar d()';
    stdout_is { d '$scalar'} $exp, '$scalar d';
    tdd { d('$scalar') } $exp, '$scalar tdd()';
    # td() is a wrapper around Test::Output::stdout_is { d() } and Test::Output::stdout_like { d() }
    # It will be used instead of stdout_is for brevity
    # The next text is exactly the same as the previous test
    td '$scalar',   $exp, '$scalar td()';
    td '${scalar}', "$header  \${scalar} = 'myvalue'\n", '';
    td1 '$scalar',  $exp;
    td '$scalar',   $exp;
    my $err1 = "$header  myvalue\n";
    td "$scalar",   $err1, 'error - used double-quotes by mistake instead of single-quotes';
    td '\$scalar',  "\\$exp", 'backslash in front of DEBUG (user error)';  # this should not really be a test
    my $r_spell = qr(Check if you misspelled your variable name when you called);
    my $d_spell = 'scalar misspelled variable or wrong sigil';
    td '$misspelledvar', $r_spell, $d_spell;
    td '$list',       $r_spell, $d_spell;
    td '$nestedlist',    $r_spell, $d_spell;
    td '$hash',       $r_spell, $d_spell;
    td '$nestedhash',    $r_spell, $d_spell;
    td '$list[10]',   $r_spell, $d_spell;
    td '$hash{ten}',  $r_spell, $d_spell;
    my $warning = qr(WARNING:.*was given a reference to a variable instead of a single-quoted string);
    if ( $] lt '5.018' ) {
        #tsub 'd', '$scalar', $warning, 'scalar warning';
        tdd { d( \$scalar ) } $warning, 'scalar warning'; # 5.18
    }
    #td '\$scalar', $warning, 'warning';
    my $undefinedvar;
    my $expundef = "$header  \$undefinedvar = undef\n";
    tdd { d('$undefinedvar') } $expundef, 'scalar undef';
    #td '$undefinedvar', $expundef, 'undef';
    CLOSURE: {
        # Needed because $d is undef'd
        undef $d;
        td '$scalar',   '', '$d has not been declared';
        tdd { d0 '$scalar' }  $exp, '$scalar  d0';
        tdd { D '$scalar' }  $exp, '$scalar  D';
        td0 '$scalar',  $exp;
        my $d;
        td '$scalar',   '',   '$d is not defined';
        tdd { d0 '$scalar' }  $exp, '$scalar  d0';
        tdd { D '$scalar' }  $exp, '$scalar  D';
        td0 '$scalar',  $exp;
        $d = 0;
        td '$scalar',   '',   '$d = 0';
        td0 '$scalar',  $exp;
        tdd { d0 '$scalar' } "$header  \$scalar = 'myvalue'\n", '$scalar  d0';
        tdd { d0 '@list' }    $rl, '@list  d0';
        tdd { d0 '%hash' }    $rh, '%hash  d0';
        tdd { D '$scalar' } "$header  \$scalar = 'myvalue'\n", '$scalar  D';
        tdd { D '@list' }    $rl, '@list  D';
        tdd { D '%hash' }    $rh, '%hash  D';
    }
}

sub testArray {
    say "\n### testArray";
    $d = 1;
    stdout_like { d('@list') } $rl, '@list';
    stdout_like { d '@list'  } $rl, '@list';
    td '@list', $rl;
    td '@list', $rl;
    td '$listref', $rl;
    # The next two tests use stdout_like since td() only takes one argument for d()
    stdout_like { d('@list', 1 )  } $rl, '@list 1';
    stdout_like { d '@list', 1    } $rl, '@list 1';
    td '$list[0]',    "$header  \$list[0] = 'zero'\n";
    td '$list[-1]',   "$header  \$list[-1] = '3'\n";
    td '$listref->[0]',  "$header  \$listref->[0] = 'zero'\n";
    td '$listref->[-1]', "$header  \$listref->[-1] = '3'\n";
    td '${listref}', $rl;
    td '@{list}', $rl;
    td '$nestedlist[1]',    qr($header${vr}\[\s+2,\s+3\s+\]);
    td '$nestedlist[1][1]', "$header  \$nestedlist[1][1] = 3\n";
    for $i ( 0 .. 1 ) {
        # Needed to change call for testing purposes
        # This does not do a good job of testing, but I don't have any better ideas yet
        # The same problem is in the hash tests
        #d('$list[$i]');
        #d('$listref->[$i]');
        #td "\$list[\$i]",   qr($header${vr}'?$list[$i]'?);
        #td '$list[$i]',   qr($header${vr}'?$list[$i]'?);
        td "\$list[$i]",   qr($header${vr}'?$list[$i]'?);
        td "\$listref->[$i]", qr($header${vr}'?$listref->[$i]'?);
    }
    td '$list[1:3]',  qr(cannot be used on an array slice), "Not supported";
    td '@list[1:3]',  qr(cannot be used on an array slice), "Not supported";
    td '$list[asdf]', qr(cannot be used on an array element with non-digits), "Invalid";
    td '$#list',      qr(does not support \$#), "Not supported";
    td "#list = $#list",  "$header  #list = 3\n", 'Workaround for $#list';
    d("@list");
    #use re 'debug';
    my $rr = qr($header\s+zero\s+1\s+two\s+3);
    td "@list",  $rr, 'user error - d() was given double-quotes instead of single-quotes';
    my $warning = qr(was given a reference to a variable instead of a single-quoted string);
    td \@list, $warning, 'warning - reference given instead of single-quoted string';
    td \$listref, $warning, 'warning - reference given instead of single-quoted string';
    td $listref,  $warning, 'warning - reference given instead of single-quoted string';
}

sub testHash {
    say "\n### testHash";
    stdout_like { d('$hashref') } $rh, '$hashref';
    stdout_like { d '$hashref'  } $rh, '$hashref';
    td '$hashref', $rh;
    td '${hashref}', $rh;
    td '%hash', $rh;
    td '%{hash}', $rh;
    td '$hash{one}', $r1;
    td '$hash{"one"}', $r1;
    td '$hashref->{one}', $r1;
    td '%nestedhash', $rn;
    td '$nestedhashref', $rn;
    td '$nestedhash{flintstones}', $rnf;
    td '$nestedhashref->{flintstones}', $rnf;
    td '$nestedhash{flintstones}{husband}', $rnfh;
    td '$nestedhash{flintstones}{pal}', $rnfp;
    td '$nestedhashref->{flintstones}{pal}', $rnfp;
    td '$nestedhashref->{flintstones}->{pal}', $rnfp;
    for $ref ( keys %nestedhash ) {
        # Needed to change call for testing purposes
        #d('$nestedhash{$ref}');
        #d('$nestedhashref->{$ref}');
        td "\$nestedhash{$ref}", $rnf;
        td "\$nestedhashref->{$ref}", $rnf;
        for my $ref2 ( keys %{ $nestedhash{$ref} } ) {
            td "\$nestedhash{$ref}{$ref2}", $rnfhp;
            td "\$nestedhashref->{$ref}{$ref2}", $rnfhp;
        }
    }
    if (0) {
        say "###";
        say "%hash";
        d0('%hash');
        D '%hash';
        say "###";
        say "%hash";
        d0(%hash);
        say "###";
        # This is probably not working because of the test harness
        #td "%hash",  '', 'user error - d() was given double-quotes instead of single-quotes';
        stdout_is { d("%hash")} '', 'user error - d() was given double-quotes instead of single-quotes';
        die;
    }
    my $warning = qr(was given a reference to a variable instead of a single-quoted string);
    td \%hash, $warning, 'warning - reference given instead of single-quoted string';
    td \$hashref, $warning, 'warning - reference given instead of single-quoted string';
    td $hashref, $warning, 'warning - reference given instead of single-quoted string';
}

sub testPackageVars {
    say "\n### testPackageVars";
    $Data::Dumper::Terse = 1;
    td '$Data::Dumper::Terse', "$header  \$Data::Dumper::Terse = 1\n", 'package variable';
}

sub testSpecial {
    say "\n### testSpecial";
    my $r = qr($header${vr}\S+);
    td '$0', $r;
    td '$$', $r;
    #td '$?', $r;  # cannot handle ref type 9 at /home/utils/perl-5.8.8/lib/5.8.8/x86_64-linux/Data/Dumper.pm line 222.
    td '$.', $r;
    td '%ENV', $r;
    td '%SIG', $r;
    td '@INC', $r;
    #td '%INC', $r; # TO DO:  enhance code to handle this
    td '@ARGV', $r;
    my $warning = qr(does not support Special variables);
    @_ = qw(at underscore);
    td '@_', $warning, 'Special variables not supported';
    $_ = "dollar underscore";
    td '$_', $warning, 'Special variables not supported';
    /(\S+ll\S+)/;    # Used to fill $1
    td '$1', $warning, 'Special variables not supported';
    td '$&', $warning, 'Special variables not supported';
}

sub testLevels {
    say "\n### testLevels";
    tdd { d('$scalar') } "$header  \$scalar = 'myvalue'\n", '$scalar  normal';
    tdd { d('@list') }    $rl, '@list  normal';
    tdd { d('%hash') }    $rh, '%hash  normal';
    tdd { d('$scalar', 1) } "$header  \$scalar = 'myvalue'\n", '$scalar  1';
    tdd { d('@list', 1) }    $rl, '@list  1';
    tdd { d('%hash', 1) }    $rh, '%hash  1';
    tdd { d1('$scalar') } "$header  \$scalar = 'myvalue'\n", '$scalar  d1';
    tdd { d1('@list') }    $rl, '@list  d1';
    tdd { d1('%hash') }    $rh, '%hash  d1';
    $d = 2;
    tdd { d('$scalar') } "$header  \$scalar = 'myvalue'\n", '$scalar  normal';
    tdd { d('@list') }    $rl, '@list  normal';
    tdd { d('%hash') }    $rh, '%hash  normal';
    tdd { d('$scalar', 2) } "$header2  \$scalar = 'myvalue'\n", '$scalar  2';
    tdd { d('@list', 2) }    $rld2, '@list  2';
    tdd { d('%hash', 2) }    $rhd2, '%hash  2';
    tdd { d2('$scalar') } "$header2  \$scalar = 'myvalue'\n", '$scalar  d2';
    tdd { d2('@list') }    $rld2, '@list  d2';
    tdd { d2('%hash') }    $rhd2, '%hash  d2';
    $d = 1;
    tdd { d2('$scalar') } '', '$scalar  no print';
    tdd { d2('@list') }   '', '@list  no print';
    tdd { d2('%hash') }   '', '%hash  no print';
    tdd { d('$scalar', '2') } '', '$scalar  no print';
    tdd { d('@list', '2') }   '', '@list  no print';
    tdd { d('%hash', '2') }   '', '%hash  no print';
    tdd { d3('$scalar') } '', '$scalar  no print';
    tdd { d3('@list') }   '', '@list  no print';
    tdd { d3('%hash') }   '', '%hash  no print';
    tdd { d('$scalar', '3') } '', '$scalar  no print';
    tdd { d('@list', '3') }   '', '@list  no print';
    tdd { d('%hash', '3') }   '', '%hash  no print';
}

sub testPrefixSuffix {
    say "\n### testPrefixSuffix";
    tdd { d('') } qr($header), '""';
    tdd { d('\S') } qr($header  \\S), '\S';
    tdd { d('\n$scalar') } "\n$header  \$scalar = 'myvalue'\n", 'newline before $scalar';
    tdd { d('\n$scalar\n\n') } "\n$header  \$scalar = 'myvalue'\n\n\n", 'newline before $scalar and two afterwards';
    tdd { d('\n--------\n$scalar\n--------\n') } "\n--------\n$header  \$scalar = 'myvalue'\n--------\n\n", 'newlines and dashes before and after $scalar';
    tdd { d('comment1 comment2') } "$header  comment1 comment2\n", 'comment1 comment2';
    tdd { d('Here is a comment\n$scalar <- here is another comment') } "Here is a comment\n$header  \$scalar = 'myvalue' <- here is another comment\n", 'comment1 one one line, then show value of scalar along with comment2';
}

sub testMultipleVars {
    my $r = $header . $vr . '\S+';
    my $r3 = qr($r\n$r\n$r\n);
    td '$scalar $scalar2 $scalar3', $r3;
    td '$scalar,$scalar2,$scalar3', $r3;
    td '$scalar, $scalar2, $scalar3', $r3;
    td '($scalar, $scalar2, $scalar3)', $r3;
    td '\n$scalar $scalar2 $scalar3', qr(\n$r\n$r\n$r\n);
    td '$scalar $scalar2 $scalar3\n', qr($r\n$r\n$r\n);
}

sub testInternalDebug {
    if (0) {
        say "\n### testInternalDebug";
        tdd { d('$scalar') } qr($header  \$scalar = 'myvalue'\s*$), 'normal, internal debug is off';
        $d = -1;
        tdd { d('$scalar') } qr(internaldebug.*$header  \$scalar = 'myvalue'), 'internal debug is on';  # not working
        $d = 1;
        tdd { d('$scalar') } qr($header  \$scalar = 'myvalue'\s*$), 'normal, internal debug is off';
        die;
    }
}

sub testOption_printdebug {
    say "\n### testOption_printdebug";
    my $exp = "$header  \$scalar = 'myvalue'\n";
    $d = 1;
    td '$scalar',  "$header  \$scalar = 'myvalue'\n", 'normal, expecting DEBUG';
    d('$scalar');
    Debug::Statements::setPrintDebug("debug> ");
    td '$scalar',  "debug sub __ANON__>  \$scalar = 'myvalue'\n", 'debug >';
    Debug::Statements::setPrintDebug("");
    td '$scalar',  "sub __ANON__:  \$scalar = 'myvalue'\n", 'no DEBUG';
    Debug::Statements::setPrintDebug("DEBUG:  ");
}


sub testOption_printsub {
    say "\n### testOption_printsub";
    tdd { d('$scalar') } "$header  \$scalar = 'myvalue'\n", 'normal';
    tdd { d('$scalar', 'B*') }  "DEBUG:  \$scalar = 'myvalue'\n", 'sub name not printed';
    Debug::Statements::setPrintDebug("");
    tdd { d('$scalar') }  "\$scalar = 'myvalue'\n", 'debug and sub name not printed';
    Debug::Statements::setPrintDebug("DEBUG:  ");
    tdd { d('$scalar') }  "DEBUG:  \$scalar = 'myvalue'\n", 'sub name not printed';
    tdd { d('$scalar', 'b*') }  "$header  \$scalar = 'myvalue'\n", 'normal';
}

sub testOption_compress {
    say "\n### testOption_compress";
    tdd { d('$scalar', 'z*') }  "$header  \$scalar = 'myvalue'\n", 'normal';
    td '@list', $rl1;
    td '%hash', $rh1;
    tdd { d('$scalar', 'Z*') }  "$header  \$scalar = 'myvalue'\n", 'compressed';
    td '@list', $rl;
    td '%hash', $rh;
    tdd { d('$scalar', 'z*') }  "$header  \$scalar = 'myvalue'\n", 'normal';
}

sub testOption_disable {
    say "\n### testOption_disable";
    Debug::Statements::disable();
    td '$scalar', '', 'should not print';
    td '@list',   '', 'should not print';
    td '%hash',   '', 'should not print';
    Debug::Statements::enable();
}

sub testOption_flag {
    say "\n### testOption_flag";
    undef $d;
    td '$scalar', '', 'undef $d, should not print';
    Debug::Statements::setFlag('$debug');
    td '$scalar', '', 'setFlag $debug but it is undef, should not print';
    $debug = 0;
    td '$scalar', '', '$debug = 0, should not print';
    $debug = 1;
    my $exp = "$header  \$scalar = 'myvalue'\n";
    td '$scalar',   $exp, '$debug = 1, should print';
    undef $debug;
    Debug::Statements::setFlag('$d');
    $d = 1;
    td '$scalar',   $exp, 'setFlag $d, should print';
}

#my $optionsTable = { 'c' => 'Chomp', 'e' => 'Elements', 'n' => 'LineNumber', 's' => 'Sort', 't' => 'Timestamp', 'x' => 'Die' };
sub testOption_Chomp {
    say "\n### testOption_Chomp";
    my $line = "a b c\n";
    tdd { d('$line') }       "$header  \$line = 'a b c\n'\n", 'normal';
    tdd { d('$line', 'c') }  "$header  \$line = 'a b c'\n", 'c - no newline';
    tdd { d('$line') }       "$header  \$line = 'a b c\n'\n", 'normal';
    tdd { d('$line', 'c*') } "$header  \$line = 'a b c'\n", 'c* - no newline';
    tdd { d('$line', 'C*') } "$header  \$line = 'a b c\n'\n", 'C* - newline';
}

sub testOption_Elements {
    say "\n### testOption_Elements";
    d('@list');
    td '@list', $rl, 'normal';
    td '%hash', $rh, 'normal';
    tdd { d('@list') }    $rl, '@list  normal';
    tdd { d('%hash') }    $rh, '%hash  normal';
    tdd { d('@list', 'e') }    $rle, '@list  with number of elements';
    tdd { d('%hash', 'e') }    $rhe, '%hash  with number of elements';
    tdd { d('@list') }    $rl, '@list  normal';
    tdd { d('%hash') }    $rh, '%hash  normal';
    tdd { d('@list', 'e*') }    $rle, '@list  with number of elements';
    tdd { d('%hash', 'e*') }    $rhe, '%hash  with number of elements';
    tdd { d('@list', 'E*') }    $rl, '@list  normal';
    tdd { d('%hash', 'E*') }    $rh, '%hash  normal';
}

sub testOption_lineNumber {
    say "\n### testOption_lineNumber";
    tdd { d('$scalar') }  "$header  \$scalar = 'myvalue'\n", 'normal';
    tdd { d('$scalar', 'n') }  "$header  At line undef:  \$scalar = 'myvalue'\n", 'with line number';
    tdd { d('$scalar') }  "$header  \$scalar = 'myvalue'\n", 'normal';
    tdd { d('$scalar', 'n*') }  "$header  At line undef:  \$scalar = 'myvalue'\n", 'with line number';
    tdd { d('$scalar', 'N*') }  "$header  \$scalar = 'myvalue'\n", 'normal';
}

sub testOption_tRuncate {
    say "\n### testOption_tRuncate";
    tdd { d('%nestedhash') }    $rn, '%nestedhash  normal';
    Debug::Statements::setTruncate(3);
    tdd { d('%nestedhash', 'r') }    $rnt, '%nestedhash  truncated';
    Debug::Statements::setTruncate(5);
    tdd { d('%nestedhash') }    $rn, '%nestedhash  normal';
}

sub testOption_Sort {
    say "\n### testOption_Sort";
    tdd { d('@list') }    $rl, '@list  normal';
    tdd { d('%hash') }    $rh, '%hash  normal';
    tdd { d('@list', 's') }    $rls, '@list  sorted';
    tdd { d('%hash', 's') }    $rhs, '%hash  sorted';
    tdd { d('@list') }    $rl, '@list  normal';
    tdd { d('%hash') }    $rh, '%hash  normal';
    tdd { d('@list', 's*') }    $rls, '@list  sorted';
    tdd { d('%hash', 's*') }    $rhs, '%hash  sorted';
    tdd { d('@list', 'S*') }    $rl, '@list  normal';
    tdd { d('%hash', 'S*') }    $rh, '%hash  normal';
}

sub testOption_Timestamp {
    say "\n### testOption_Timestamp";
    tdd { d('$scalar') }       qr($header${vr}'myvalue'), 'normal';
    tdd { d('$scalar', 't') }  qr($header${vr}'myvalue'\s+at\s+\S+), 'timestamp';
}

sub testOptions_multiple {
    say "\n### testOptions_multiple";
    tdd { d('$scalar') }       qr($header${vr}'myvalue'), '$scalar normal';
    tdd { d('@list') }    $rl, '@list  normal';
    tdd { d('%hash') }    $rh, '%hash  normal';
    my $i = 1;
    tdd { d('$listref->[$i]') }  qr($header${vr}'?$listref->[$i]'?), '$listref->[$i]';
    my $ref = 'flintstones';
    tdd { d('$nestedhashref->{$ref}') } $rnf, '$nestedhashref->{flintstones}';
    tdd { d('$Data::Dumper::Terse') } "$header  \$Data::Dumper::Terse = 1\n", 'package variable';
    my $allopt = 'bcenstz';
    if ( $] lt '5.018' ) {
        tdd { d('$scalar', $allopt) }       qr($header  At line undef:\s+[\$\@\%]\S+\s+=\s+'myvalue'\s+at\s+\S+), '$scalar with all options';
        my $rlest = qr($header\s+At line undef:.*\d+.*\s+${lsort}\s+at\s+\S+);
        my $rhest = qr($header\s+At line undef:.*\d+.*\s+${h}\s+at\s+\S+);
        tdd { d('@list', $allopt) }     $rlest, '@list with all options';
        tdd { d('%hash', $allopt) }     $rhest, '%hash with all options';
        tdd { d('$scalar', 'a') }       qr(does not understand your option), 'invalid option a';
    }
    # tests not implemented
    #d( '$listref->[$i]',         $allopt );
    #d( '$nestedhashref->{$ref}', $allopt );
    #d( '$Data::Dumper::Terse',   $allopt );
}

sub testOption_Q {
    say "\n### testOption_Q";
    tdd { d('$scalar = "foo";') }       qr($header${vr}'myvalue'\s+=\s+"foo";), 'default handling of parsed line from Perl script';
    tdd { d('$scalar = "foo";', 'q') }  qr($header\s+\$scalar\s+=\s+"foo";), 'desired behavior';
}

sub testOption_Die {
    say "\n### testOption_Die";
    tdd { d('$scalar') }       qr($header${vr}'myvalue'), 'normal';
    $d = 0;
    lives_ok { d('$scalar', 'x') } 'should not die (will print DEBUG line underneath)';
    $d = 1;
    dies_ok { d('$scalar', 'x') } 'should die';
}

sub testLsl {
    say "\n### testLsl";
    my $rd;
    my $windows = ($^O =~ /Win/) ? 1 : 0;
    if ( $windows ) {
        # Volume in drive C is OSDisk
        $rd = '\s*Volume in';
        return; # ls() seems to work on Windows, but my tests fail
    } else {
        # -rwxrwxr-x  1 ckoknat hardware 29506 Dec 18 11:28 DebugStatementsTest.t
        $rd = '\S+\s+\d+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+';
    }
    $d = 1;
    my $header = 'DEBUG:  ls -l = ';
    tdd { ls("filename_does_not_exist") }  qr(does not exist), 'ls(filename_does_not_exist)';
    tdd { ls('$filename') }                qr(did not understand file name), "ls('\$filename') error";
    tdd { ls($0) }                         qr($header$rd), "File ls($0)";
    if ( $] lt '5.018' ) {
        tdd { ls('.') }                    qr($header$rd), "Directory ls(.)";
        tdd { ls("$0 $0") }                qr($header$rd.*\n$header$rd), "ls($0 $0)";
        tdd { ls("$0 .") }                 qr($header$rd.*\n$header$rd), "ls($0 .)";
        ##tdd { ls($filename), 2 }  '', 'ls() with too high a debug level';
    }
}

