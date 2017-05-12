package # hidden from PAUSE indexer
Multilingual::Code;
our $VERSION = '0.000001';

use 5.014; use warnings;
use Keyword::Declare;

sub left_justify {
    my $block = shift;
    if (my $indent = $block =~ m{^(\s+)}m ? $1 : undef) {
        $block =~ s{^$indent}{}gm;
    }
    return $block;
}

sub import {
    keytype Blocklike {
        / \{ (?&BlockBody) \} (?(DEFINE) (?<BlockBody> (?: [^{}\\]++ | \\. | \{ (?&BlockBody) \} )*+ )) /x
    }

    our $next_anon = 'ANON00000001';
    keyword ANSI_C (Blocklike $block) {
        my ($c_params, $perl_args) = (q{}, q{});
        my $anon_sub = $Multilingual::Code::next_anon++;
        my %seen;
        $block =~ s{\$(\w+)}{ if (!$seen{$1}++) { $c_params .= "char* $1,"; $perl_args .= "\$$1,"; } $1 }gexms;
        $c_params =~ s{,$}{};
        return qq[
            use Inline C => q{void $anon_sub ($c_params) $block};
            $anon_sub($perl_args);
        ];
    }
    keyword PYTHON (Blocklike $block) {
        use List::Util 'minstr';
        my ($py_params, $perl_args) = (q{}, q{});
        my $anon_sub = $Multilingual::Code::next_anon++;
        my %seen;
        $block =~ s{\A \{ | \} \Z}{}gx;
        my $prefix = minstr( grep {defined} $block =~ m{^(\h+)}gcxms );
        $block =~ s{^$prefix}{}gm;
        $block =~ s{(?<sigil> [\$\@] ) (?<name> \w+ ) }
                   { my %var = %+;
                     if (!$seen{$var{name}}++) {
                        $py_params .= "$var{name},";
                        $perl_args .= '\\' if $var{sigil} eq '@';
                        $perl_args .= "$var{sigil}$var{name},";
                     }
                     $var{name}
                   }gexms;
        $py_params =~ s{,$}{};
        my ($defs, $execs) = (q{}, q{});
        for my $construct (split m{^(?=\S)}xm, $block) {
            if ($construct =~ /\A\s*def\b/) { $defs  .= $construct; }
            else                            { $execs .= $construct; }
        }
        $execs =~ s{^}{    }gm;
        return ($defs  =~ /\S/ ? qq[ use Inline Python => q{$defs}; ] : q{})
             . ($execs =~ /\S/ ? qq[ use Inline Python => q{def $anon_sub($py_params):\n$execs}; $anon_sub($perl_args); ] : q{});
    }
}

1;
