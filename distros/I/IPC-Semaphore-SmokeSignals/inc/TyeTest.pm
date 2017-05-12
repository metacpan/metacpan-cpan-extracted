package TyeTest;
use strict;

use Test qw< plan ok skip >;
use Carp qw< croak >;
use vars qw< @EXPORT_OK >;

BEGIN {
    @EXPORT_OK = qw<
        plan ok skip
        Okay True False
        Note Dump SkipIf
        Lives Dies Warns LinesLike
    >;
    require Exporter;
    *import = \&Exporter::import;
}

$| = 1;

return 1;   # Just subroutines below here.


# Okay( $expect, codeToTest(), 'Description of test' );
# Okay( $boolean ); # But don't use it this way (much)

sub Okay($;$$) {
    my( $expect, $got, $desc ) = @_;
    local( $Test::TestLevel ) = 1 + $Test::TestLevel;
    return ok( $expect )            if  1 == @_;
    return ok( $got, $expect )      if  ! $desc;
    return ok( $got, $expect, $desc );
}


# True( codeToTest(), 'Description of test' );

sub True($;$) {
    my( $got, $desc ) = @_;
    my $expect = qr/^([^0]|..)/s;
    $expect = $got          # Pass test if got a 'true' value.
        if  $got;
    local( $Test::TestLevel ) = 1 + $Test::TestLevel;
    return Okay( $expect, $got, $desc );
}


# False( codeToTest(), 'Description of test' );

sub False($;$) {
    my( $got, $desc ) = @_;
    my $expect = qr/^0?\z/; # Explain what we expected.
    $expect = $got          # Pass test if got 0, '', or undef()...
        if  ! $got;         #   (any 'false' value).
    local( $Test::TestLevel ) = 1 + $Test::TestLevel;
    return Okay( $expect, $got, $desc );
}


# Note( $string, ... );

sub Note {
    # Note:  Ignores trailing newlines per string
    for my $line (  map { split /\n/, $_ } @_  ) {
        print "#$line\n";
    }
}


# Dump( $data, ... );

sub Dump {
    require Data::Dumper;
    my $dd = Data::Dumper->new(
        1 == @_ ? [@_] : [[@_]],
    );
    $dd->Indent(1)->Useqq(1)->Terse(1)->Sortkeys(1);
    Note( $dd->Dump() );
}


# SkipIf( $skipReason, $expect, sub { codeToMaybeTest() }, 'Description of test' );
# SkipIf(
#   ! Okay( $expect1, codeToTest(), 'Description of first test' ),
#   $expect2, sub { codeToTestIfFirstTestPasses() }, 'Description of 2nd test',
# )
#
# my $skip = $ENV{TESTSERVER} ? '' : 'TESTSERVER not set in environment';
# SkipIf( $skip, sub { codeThatNeedsTestServer() }, 'Description of test' );
#
# Give $skipReason as a false value to have the test run (not skipped).
# A $skipReason of '1' becomes "Prior test failed"

sub SkipIf($;$$$) {
    my( $skip, $expect, $sub, $desc ) = @_;
    croak( "Can't not skip a non-test" )
        if  ! $skip  &&  @_ <= 1;
    $skip = 'Prior test failed'
        if  $skip  &&  '1' eq $skip;
    local( $Test::TestLevel ) = 1 + $Test::TestLevel;
    return skip( $skip )                    if  1 == @_;
    return skip( $skip, $expect )           if  2 == @_;
    return skip( $skip, $sub, $expect )     if  3 == @_;
    return skip( $skip, $sub, $expect, $desc );
}


# Lives( $stringOfPerlCodeToTest, 'Description of test' );
# Lives( \&subToCallThatMightDie, 'Description of test' );
# Lives( sub { ... }, 'Description of test' );
#
# "Should not die:\n" gets prepended to the description.

sub Lives {
    my( $code, $desc ) = @_;

    my( $pkg, $file, $line ) = caller( $Test::TestLevel );
    local( $Test::TestLevel ) = 1 + $Test::TestLevel;

    if(  ref $code  ) {
        if(  ! $desc  ) {
            ( $desc ) = $file =~ m{([^/]+)$};
            $desc ||= $file;
            $desc .= " line $line";
        }
        return Okay( 1, eval { $code->(); 1 }, "Should not die: $desc\nError: $@" );
    }
    $desc &&= " $desc";
    $desc ||= "\n$code";
    my $eval = join "\n",
        "package $pkg;",
        qq<#line $line "$file">,
        "# your code:",
        $code,
        ";1\n";
    return Okay( 1, eval $eval, "Should not die:$desc\nError: $@" );
}


# Dies( 'Test desc', $stringOfPerlCodeToTest, qr/expected error/, qr/.../... )
# Dies( 'Test desc', \&subThatShouldDie, qr/expected error/, qr/.../... )
# Dies( 'Test desc', sub { ... }, qr/expected error/, qr/.../... )
#
# Counts as 1+@regexes when counting what to tell plan().
# Description defaults to the code if it is a string.
# Prepends "Should die:" then "Error from:" or "Error $n from:" to desc.
# If you give a string instead of a regex, then index() ignoring case is done.
# Format your code as follows if you want accurate display of line numbers:
#   Dies( 'Test desc',
#       $code,
#       qr/test/,

sub Dies {
    my( $desc, $code, @omens ) = @_;

    my( $pkg, $file, $line ) = caller( $Test::TestLevel );
    local( $Test::TestLevel ) = 1 + $Test::TestLevel;

    my $skip;
    $desc &&= " $desc";
    if(  ref $code  ) {
        --$line;
        if(  ! $desc  ) {
            ( $desc ) = $file =~ m{([^/]+)$};
            $desc ||= $file;
            $desc .= " line $line";
        }
        $skip = ! Okay( undef, eval { $code->(); 1 }, "Should die: $desc" );
    } else {
        $desc ||= "\n" . join '', $code, $code =~ /\n$/ ? '' : "\n";
        my $eval = join "\n",
            "package $pkg;",
            qq<#line $line "$file">,
            "# your code:",
            $code,
            ";1\n";
        $skip = ! Okay( undef, eval $eval, "Should die:$desc" ),
    }
    my $got = $@;
    my $idx = 1 == @omens ? '' : 1;
    my $sp = $idx ? ' ' : '';
    my $fail = $skip;
    for my $omen (  @omens  ) {
        $omen = $omen->()
            if  'CODE' eq ref $omen;
        $omen = qr/\Q$omen/i
            if  ! ref $omen;
        $fail = 1
            if  ! SkipIf( $skip, $omen, $got, "Error$sp$idx from:$desc" );
        $idx++;
    }
    return ! $fail;
}


# Warns( 'Test desc', \&subThatShouldNotWarn )
# Warns( 'Test desc', \&subThatShouldWarn, qr/expected error/, qr/.../... )
# Warns( 'Test desc', sub {...}, qr/expected error/, qr/.../... )
# Warns( 'Desc', sub {...}, [ qr/first/, ... ], [ qr/2nd/ ], ... )
#
# Counts as 1+@regexes tests when counting what to tell plan().
# Giving no regexes actually asserts that no warnings are generated (1 test).
# Giving 1 or more array refs means you expect a precise number of warnings
#   and the first array of regexes is tested against the 1st warning, etc.
# Else, don't use array refs and each regex must match at least one warning.
# If you give a string instead of a regex, then index() ignoring case is done.
# Various strings get prepended to the test description.
# Description defaults to a file and line number.

sub Warns {
    my( $desc, $sub, @omens ) = @_;
    if(  ! $desc  ) {
        my( $pkg, $file, $line ) = caller( $Test::TestLevel );
        ++$line;
        ( $desc ) = $file =~ m{([^/]+)$};
        $desc ||= $file;
        $desc .= " line $line";
    }

    # Collect any warnings from running the code:
    my @warns;
    {
        local( $SIG{__WARN__} ) = sub { push @warns, $_[0] };
        $sub->();
    }
    local( $Test::TestLevel ) = 1 + $Test::TestLevel;
    return LinesLike( $desc, 'warning', \@warns, @omens );
}


sub LinesLike {
    my( $desc, $what, $lines_av, @omens ) = @_;
    if(  ! $desc  ) {
        my( $pkg, $file, $line ) = caller( $Test::TestLevel );
        ++$line;
        ( $desc ) = $file =~ m{([^/]+)$};
        $desc ||= $file;
        $desc .= " line $line";
    }

    local( $Test::TestLevel ) = 1 + $Test::TestLevel;

    # We expected no lines:
    if(  ! @omens  ) {
        $desc = "No $what from: $desc";
        $desc .= "\n$lines_av->[0]"
            if  @$lines_av;
        return Okay( 0, 0+@$lines_av, $desc );
    }

    my $fail;
    if(  "ARRAY" eq ref $omens[0]  ) {
        # We expected a specific list of lines:
        $fail = ! Okay( 0+@omens, 0+@$lines_av, "\u$what(s) from: $desc" );
        if(  ! $fail  ) {   # Got expected number, so test each:
            for my $i (  1 .. @omens  ) {
                my $line = $lines_av->[$i-1];
                for my $omen (  @{ $omens[$i-1] }  ) {
                    $omen = qr/\Q$omen/i
                        if  ! ref $omen;
                    $fail += ! Okay( $omen, $line, "\u$what $i from: $desc" );
                }
            }
            return ! $fail;
        }
        # Got unexpected number; fall back to just checking each omen:
        @omens = map @$_, @omens;
    } else {
        # We expected at least one line:
        $fail = ! Okay(
            1, 0+!!@$lines_av,
            join( ' ', "Got", 0+@$lines_av, "$what(s) from: $desc" ),
        );
    }

    if(  ! @$lines_av  ) {
        skip( "Expected $what; got none; $_" )
            for  @omens;
        return 0;
    }

    s/\n?$/\n/
        for @$lines_av;
    my $all = join '', @$lines_av;
    my $s = 1 == @$lines_av ? '' : 's';
    for my $omen (  @omens  ) {
        $omen = qr/\Q$omen/i
            if  ! ref $omen;
        $fail += ! Okay( $omen, $all, "\u$what$s from: $desc" );
    }
    return ! $fail;
}
