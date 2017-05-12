package CheckItaTrans;

use 5.010;
use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = (qw(start_log check_ita_transliteration check_ita_tr));

use Test::More;

use Lingua::IT::Ita2heb;

use English '-no_match_vars';
use open ':encoding(utf8)';
use charnames ':full';

my $log_fh;
my $log_filename;

sub start_log {
    my $source_fn = shift;

    $log_filename = "$source_fn.log";

    # To make Test::More output using the unicode characters ok.
    # See:
    # http://code.google.com/p/test-more/issues/detail?id=46
    binmode Test::More->builder->output, ":utf8";
    binmode Test::More->builder->failure_output, ":utf8";

    open $log_fh, '>', $log_filename    ## no critic InputOutput::RequireBriefOpen
        or croak("Couldn't open $log_filename for writing: $OS_ERROR");

    return;
}

sub check_ita_transliteration {
    my ($ita, $hebrew_transliteration, $blurb) = @_;
    local $Test::Builder::Level =  ## no critic Variables::ProhibitPackageVars
        $Test::Builder::Level + 1; ## no critic Variables::ProhibitPackageVars

    my $result = 
        Lingua::IT::Ita2heb::ita_to_heb(
            ref($ita) eq 'ARRAY' ? (@{$ita}) : $ita
        );

    say {$log_fh} "$blurb $result";
    return is(
        $result,
        $hebrew_transliteration,
        $blurb
    );
}

BEGIN
{
    *check_ita_tr = \&check_ita_transliteration;
}

sub END {
    close($log_fh)
        or croak("Couldn't close $log_filename after writing: $OS_ERROR");

    return;
}

1;

