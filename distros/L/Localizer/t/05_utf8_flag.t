use strict;
use warnings;
use utf8;
use Test::More;

use Localizer::Resource;

use Localizer::Style::Gettext;
use Localizer::Style::Maketext;

my %dat = read_key_value("t/dat/utf8.properties");

for my $style (
    Localizer::Style::Gettext->new(),
    Localizer::Style::Maketext->new(),
) {
    for my $s (qw(e1 e2 e3 e4 e5 e6)) {
        my $code = $style->compile($s, $dat{$s});
        my $got = do {
            if (UNIVERSAL::isa($code, 'CODE')) {
                $code->('e', 'k');
            } else {
                $$code;
            }
        };
        ok utf8::is_utf8($got), "$s " . ref($style);
    }
}

done_testing;

sub read_key_value {
    my ($filename, $iolayer) = @_;
    $iolayer //= '<:encoding(utf-8)';

    open my $fh, $iolayer, $filename
        or Carp::croak("Cannot open '$filename' for reading: $!");

    my @out;
    for my $line (<$fh>) {
        if ($line =~ /\A[ \t]*([^=]+?)[ \t]*=[ \t]*(.+?)[\015\012]*\z/) {
            my ($k, $v) = ($1, $2);
            $v =~ s/\\n/\n/g;
            push @out, $k, $v;
        }
    }

    return @out;
}
