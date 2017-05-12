use strict;
use warnings;

# this is just like t/01-basic.t except we use [EOLTests].

use Path::Tiny;
my $code = path('t', '01-basic.t')->slurp_utf8;

my $begin_warnings = <<'END';
my @warnings = warnings {
END

my $end_warnings = <<'END';
};  # end warnings capture

cmp_deeply(
    \@warnings,
    superbagof(re(qr/^\Q!!! [EOLTests] is deprecated and may be removed in a future release; replace it with [Test::EOL] (note the different default filename)\E/)),
    'deprecation warning was seen',
);
END

$code =~ s/Test::EOL(?!'\s*=>)/EOLTests/g;
$code =~ s{xt(.)author(.)eol\.t}{xt$1release$2eol.t}g;

$code =~ s/^(my \$tzil = .*\n)/$begin_warnings\n$1/m;
$code =~ s/had_no_warnings/$end_warnings\nhad_no_warnings/;

use Dist::Zilla::Plugin::Test::EOL;
$code =~ s/^(\s+)(finder => .*,)$/$1$2\n$1version => '$Dist::Zilla::Plugin::Test::EOL::VERSION',/m;

eval $code;
die $@ if $@;
