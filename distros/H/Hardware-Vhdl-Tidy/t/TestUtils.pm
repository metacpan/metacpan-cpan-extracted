package TestUtils;
use Exporter qw(import);
use File::Temp qw/tempfile/;
use Test::More;

our @EXPORT_OK = qw( create_tidy_test compare_indentation string_to_filehandle escape );

sub create_tidy_test {
    # given a VHDL source string, returns two array refs:
    #  - the lines from the VHDL source, with case randomised
    #  - the same lines, but with initial whitespace also randomised
    my $vhdl = shift;
    my @in = map { lc $_."\n" } split(/\n/, $vhdl);
    my @linesource;
    for my $line (@in) {
        for my $i (0 .. length($line)-1) {
            substr($line, $i, 1, uc substr($line, $i, 1)) if (rand(2)<1);
        }
        my $cline = $line;
        $cline =~ s/^\s*//;
        $cline = (' ' x rand(8)) . $cline;
        push @linesource, $cline;
    }
    return (\@in, \@linesource);
}

sub compare_indentation {
    my ($in_ref, $out_ref) = @_;
    my $errs=0;
    my $errlog='';
    my $ln=0;
    for my $inline (@{$in_ref}) {
        my $outline = shift @{$out_ref};
        $ln++;
        if ((!defined $outline) || ($outline ne $inline)) {
            $outline = '<EOF>' if !defined $outline;
            $errs++;
            if ($errs>3) { $errlog .= " ... further errors suppressed"; last }
            my ($int, $outt) = ($inline, $outline);
            my ($ins, $outs) = (0, 0);
            if ($int =~ /^(\s+)(.*)$/) { $ins=length $1; $int=$2 }
            if ($outt =~ /^(\s+)(.*)$/) { $outs=length $1; $outt=$2 }
            if ($int eq $outt) {
                $errlog .= "test line $ln: expected $ins indent spaces before '".&escape($int)."', got $outs\n";
            } else {
                $errlog .= "test line $ln: expected '".&escape($inline)."', got '".&escape($outline)."'\n";
            }
        }
    }
    diag($errlog."\n\n") if $errlog;
    return $errs==0;
}

sub escape {
    my $t = shift;
    $t =~ s/\n/\\n/g;
    $t =~ s/\r/\\r/g;
    $t =~ s/\t/\\t/g;
    $t;
}

sub string_to_filehandle {
    my $string = shift;
    my $fh = tempfile();
    binmode $fh;
    print $fh $string;
    seek $fh, 0, 0;
    $fh;
}

1;