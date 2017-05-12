#: t/Backend/Base.pm

package Test::Make::Base;

#use Smart::Comments;
use lib 'inc';
use Test::Base -Base;
use Test::Make::Util;
use File::Temp qw( tempdir tempfile );
use Cwd ();
use File::Spec ();
use FindBin;
use IPC::Run3;
use Time::HiRes qw( time );
#use Data::Dumper::Simple;

our @EXPORT = qw(
    run_test run_tests create_file use_source_ditto
    $MAKE $PERL $SHELL $PWD
);

our @EXPORT_BASE = qw(set_make set_shell set_filters);

our ($SHELL, $PERL, $MAKE, $MAKEPATH, $MAKEFILE, $PWD);
our (@MakeExe, %Filters);
our ($UseSourceDitto, $SavedSource);

# default filters for expected values
#filters {
#    stdout => [qw< preprocess >],
#    stdour_like => [qw< preprocess_like >],
#    stderr => [qw< preprocess >],
#    stderr_like => [qw< preprocess_like >],
#};

sub set_make ($$) {
    my ($env_name, $default) = @_;
    $MAKEPATH = $ENV{$env_name} || $default;
    $MAKEPATH =~ s,\\,/,g;
    my $stderr;
    run3 [split(/\s+/, $MAKEPATH), '-f', 'no/no/no'], \undef, \undef, \$stderr;
    #die $stderr;
    if ($stderr =~ /^(\S+)\s*:/) {
        $MAKE = $1;
        $MAKE =~ s/(.*[\\\/])//;
    } else {
        $MAKE = '';
    }
    ### $MAKE
    #$MAKE =~ s{\\}{/}g;
}

sub set_shell ($$) {
    my ($env_name, $default) = @_;
    $SHELL = $ENV{$env_name} || $default;
}

BEGIN {
    if ($^O =~ / /) {
        $PERL = 'perl';
    } else {
        $PERL = $^X;
    }
    #warn $PERL;

    # Get a clean environment
    clean_env();

    # Delay the Test::Base filters
    filters_delay();
}

sub use_source_ditto () {
    $UseSourceDitto = 1;
}

sub run_test ($) {
    my $block = shift;

    my $tempdir = tempdir( 'backend_XXXXXX', TMPDIR => 1, CLEANUP => 1 );
    my $saved_cwd = Cwd::cwd;
    chdir $tempdir;
    $PWD = $tempdir;
    $PWD =~ s,\\,/,g;

    %::ExtraENV = ();


    my $filename = $block->filename;
    chomp $filename if $filename;
    my $source   = $block->source;

    if (defined $source) {
        my $fh;
        if (not $filename) {
            ($fh, $filename) = 
                tempfile( "Makefile_XXXXX", DIR => '.', UNLINK => 1 );
        } else {
            open $fh, "> $filename" or
                confess("can't open $filename for writing: $!");
        }
        $MAKEFILE = $filename;
        $MAKEFILE =~ s,\\,/,g;
        $block->run_filters;
        $SavedSource = $block->source if $UseSourceDitto;
        print $fh $block->source;
        close $fh;
    } else {
        $block->run_filters;
        $filename = $block->filename;
    }

    process_pre($block);
    process_touch($block);
    process_utouch($block);

    {
        no warnings 'uninitialized';
        local %ENV = %ENV;
        %ENV = (%ENV, %::ExtraENV) if %::ExtraENV;

        run_make($block, $filename);

        process_post($block);
        process_found($block);
        process_not_found($block);

        %::ExtraENV = ();
    }

    chdir $saved_cwd;
    #warn "\nstderr: $stderr\nstdout: $stdout\n";
}

sub run_tests () {
    for my $block (blocks()) {
        run_test($block);
    }
}

sub create_file ($$) {
    my ($filename, $content) = @_;
    my $fh;
    if (not $filename) {
        ($fh, $filename) = 
            tempfile( "create_file_XXXXX", DIR => '.', UNLINK => 1 );
    } else {
        open $fh, "> $filename" or
            confess("can't open $filename for writing: $!");
    }
    #$content .= "\n\nSHELL=$SHELL" if $SHELL;
    print $fh $content;
    close $fh;
    return $filename;
}

sub process_touch ($) {
    my $block = shift;
    my $buf = $block->touch;
    return if not $buf;
    touch(split /\s+/, $buf);
}

sub process_utouch ($) {
    my $block = shift;
    my $buf = $block->utouch;
    return if not $buf;
    my @pairs = split /\s+/, $buf;
    ### @pairs
    while (@pairs) {
        my $time = shift @pairs;
        my $file = shift @pairs;
        utouch($time => $file);
    }
}

sub set_filters (@) {
    %Filters = @_;
}

# returns ($errcode, $stdout, $stderr) or $errcode
sub run_make($$) {
    my ($block, $filename) = @_;
    my $options  = $block->options || '';
    my $goals    = $block->goals || '';

    @MakeExe = split_arg($MAKEPATH) if not @MakeExe;
    #warn Dumper($filename);
    my (@pre, @post);
    if ($filename and $options !~ /-f\s+\S+/) {
        push @pre, '-f', $filename;
    }
    if ($SHELL and $options !~ m/SHELL\s*=\s*/ and $^O eq 'MSWin32') {
        push @post, "SHELL=$SHELL";
    }
    my $cmd = [
        @MakeExe,
        @pre,
        process_args("$options $goals"),
        @post,
    ];
    #warn Dumper($cmd);
    test_shell_command( $block, $cmd, %Filters );
}

package Test::Make::Base::Filter;
use Test::Base::Filter -Base;

sub quote {
    qq/"$_[0]"/;
}

sub preprocess {
    my $s = shift;
    return if not defined $s;
    ### $Test::Make::Bae::MAKE
    $s =~ s/\#MAKE\#/$Test::Make::Base::MAKE/gsi;
    $s =~ s/\#MAKEPATH\#/$Test::Make::Base::MAKEPATH/gs;
    $s =~ s/\#MAKEFILE\#/$Test::Make::Base::MAKEFILE/gs;
    $s =~ s/\#PWD\#/$Test::Make::Base::PWD/gs;
    return $s;
}

sub preprocess_like {
    my $s = shift;
    return if not defined $s;
    $s =~ s/\#MAKE\#/quotemeta $Test::Make::Base::MAKE/gse;
    $s =~ s/\#MAKEPATH\#/quotemeta $Test::Make::Base::MAKEPATH/gse;
    $s =~ s/\#MAKEFILE\#/quotemeta $Test::Make::Base::MAKEFILE/gse;
    $s =~ s/\#PWD\#/quotemeta $Test::Make::Base::PWD/gse;
    return $s;
}

sub expand {
    my $s = shift;
    return if not $s;
    return eval(qq{"$s"});
}

sub ditto {
    if (!defined $UseSourceDitto) {
        die "Error: ditto found while no use_source_ditto call.\n";
    }
    $SavedSource;
}

1;
