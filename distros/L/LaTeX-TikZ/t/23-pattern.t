#!perl -T

use strict;
use warnings;

use Test::More tests => 5 + 4 * 5;

use LaTeX::TikZ;

use lib 't/lib';
use LaTeX::TikZ::TestHelper;

using Tikz->formatter(
 format => '%d',
);

sub check_patterns {
 my ($set, $desc, $exp_decl, $exp) = @_;

 local $Test::Builder::Level = $Test::Builder::Level + 1;

 my ($head, $decl, $body) = check($set, $desc, $exp);

 is $head->[-1], '\usetikzlibrary{patterns}', "$desc: header";

 unless (ref $exp_decl eq 'ARRAY') {
  $exp_decl = [ split /\n/, $exp_decl ];
 }

 is_deeply $decl, $exp_decl, "$desc: declarations";
}

my $lines = eval {
 Tikz->raw("foo")
     ->mod(Tikz->pattern(class => 'Lines'));
};
is $@, '', 'creating a line pattern doesn\'t croak';

check_patterns $lines, 'a line pattern', <<'DECL', <<'BODY';
\pgfdeclarepatternformonly{pata}{\pgfqpoint{-0.2pt}{-0.2pt}}{\pgfqpoint{1.8pt}{1.8pt}}{\pgfqpoint{1.6pt}{1.6pt}}{
\pgfsetlinewidth{0.2pt}
\pgfpathmoveto{\pgfqpoint{-0.2pt}{0.8pt}}
\pgfpathlineto{\pgfqpoint{1.8pt}{0.8pt}}
\pgfusepath{stroke}
}
DECL
\draw [fill,pattern=pata] foo ;
BODY

my $dots = eval {
 Tikz->raw("foo")
     ->mod(Tikz->pattern(class => 'Dots'));
};
is $@, '', 'creating a dot pattern doesn\'t croak';

check_patterns $dots, 'a dot pattern', <<'DECL', <<'BODY';
\pgfdeclarepatternformonly{patb}{\pgfqpoint{-0.2pt}{-0.2pt}}{\pgfqpoint{1.8pt}{1.8pt}}{\pgfqpoint{1.6pt}{1.6pt}}{
\pgfpathcircle{\pgfqpoint{0.8pt}{0.8pt}}{0.2pt}
\pgfusepath{fill}
}
DECL
\draw [fill,pattern=patb] foo ;
BODY

my ($lines_mod) = $lines->mods;
my ($dots_mod)  = $dots->mods;

my $seq = eval {
 Tikz->seq(
  Tikz->raw('foo')
      ->mod($lines_mod)
 )->mod($lines_mod);
};
is $@, '', 'creating a sequence with two identic patterns doesn\'t croak';

check_patterns $seq, 'a sequence with two identic patterns', <<'DECL', <<'BODY';
\pgfdeclarepatternformonly{pata}{\pgfqpoint{-0.2pt}{-0.2pt}}{\pgfqpoint{1.8pt}{1.8pt}}{\pgfqpoint{1.6pt}{1.6pt}}{
\pgfsetlinewidth{0.2pt}
\pgfpathmoveto{\pgfqpoint{-0.2pt}{0.8pt}}
\pgfpathlineto{\pgfqpoint{1.8pt}{0.8pt}}
\pgfusepath{stroke}
}
DECL
\draw [fill,pattern=pata] foo ;
BODY

$seq = eval {
 Tikz->seq(
  Tikz->raw('foo')
      ->mod($lines_mod)
 )->mod(Tikz->pattern(class => 'Lines', direction => 'vertical'));
};
is $@, '',
         'creating a sequence with two orthogonal line patterns doesn\'t croak';

check_patterns $seq, 'a sequence with two orthogonal line patterns',
               <<'DECL', <<'BODY';
\pgfdeclarepatternformonly{patc}{\pgfqpoint{-0.2pt}{-0.2pt}}{\pgfqpoint{1.8pt}{1.8pt}}{\pgfqpoint{1.6pt}{1.6pt}}{
\pgfsetlinewidth{0.2pt}
\pgfpathmoveto{\pgfqpoint{0.8pt}{-0.2pt}}
\pgfpathlineto{\pgfqpoint{0.8pt}{1.8pt}}
\pgfusepath{stroke}
}
\pgfdeclarepatternformonly{pata}{\pgfqpoint{-0.2pt}{-0.2pt}}{\pgfqpoint{1.8pt}{1.8pt}}{\pgfqpoint{1.6pt}{1.6pt}}{
\pgfsetlinewidth{0.2pt}
\pgfpathmoveto{\pgfqpoint{-0.2pt}{0.8pt}}
\pgfpathlineto{\pgfqpoint{1.8pt}{0.8pt}}
\pgfusepath{stroke}
}
DECL
\draw [fill,pattern=patc,pattern=pata] foo ;
BODY

$seq = eval {
 Tikz->seq(
  Tikz->raw('foo')
      ->mod($lines_mod)
 )->mod($dots_mod);
};
is $@, '', 'creating a sequence with two different patterns doesn\'t croak';

check_patterns $seq, 'a sequence with two different patterns',
               <<'DECL', <<'BODY';
\pgfdeclarepatternformonly{patb}{\pgfqpoint{-0.2pt}{-0.2pt}}{\pgfqpoint{1.8pt}{1.8pt}}{\pgfqpoint{1.6pt}{1.6pt}}{
\pgfpathcircle{\pgfqpoint{0.8pt}{0.8pt}}{0.2pt}
\pgfusepath{fill}
}
\pgfdeclarepatternformonly{pata}{\pgfqpoint{-0.2pt}{-0.2pt}}{\pgfqpoint{1.8pt}{1.8pt}}{\pgfqpoint{1.6pt}{1.6pt}}{
\pgfsetlinewidth{0.2pt}
\pgfpathmoveto{\pgfqpoint{-0.2pt}{0.8pt}}
\pgfpathlineto{\pgfqpoint{1.8pt}{0.8pt}}
\pgfusepath{stroke}
}
DECL
\draw [fill,pattern=patb,pattern=pata] foo ;
BODY
