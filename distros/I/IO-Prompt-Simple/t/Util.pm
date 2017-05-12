package t::Util;

use strict;
use warnings;
use Test::More;
use base 'Exporter';
use IO::Prompt::Simple;

our @EXPORT = 'test_prompt';

sub test_prompt {
    my %specs = @_;
    my ($input, $answer, $prompt, $desc, $opts, $isa_tty) =
        @specs{qw/input answer prompt desc opts isa_tty/};

    $isa_tty = defined $isa_tty ? $isa_tty : 1;
    $input = "$input\n" if defined $input;

    # using PerlIO::scalar
    open my $in, '<', \$input or die $!;
    open my $out, '>', \my $output or die $!;

    local *STDIN  = *$in;
    local *STDOUT = *$out;

    if (ref $opts eq 'HASH') {
        $opts->{input}  = $in;
        $opts->{output} = $out;
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $line = (caller)[2];

    no warnings 'redefine';
    local *IO::Prompt::Simple::_isa_tty = sub { $isa_tty };

    note "$desc at line $line"; do {
        my @got = prompt 'prompt', $opts;
        if (ref $prompt eq 'Regexp') {
            like $output, $prompt, 'prompt ok';
        }
        else {
            is $output, $prompt, 'prompt ok';
        }

        if (ref $answer) {
            is_deeply \@got, $answer, 'expects ok';
        }
        else {
            is $got[0], $answer, 'expects ok';
        }
    };
}

1;
