use strict;
# compatible use warnings
BEGIN{ if (not $] < 5.006) { require warnings; warnings->import } }

use Test::More;
use Config;
my $debug = 0;

eval "use Devel::CheckLib";
if($@ =~ /Couldn't find your C compiler/) {
    plan skip_all => "Couldn't find your C compiler";
}

my $platform_lib = 
    $^O eq 'MSWin32'                       # if Win32 (not Cygwin) ...
        ? (
            $Config{cc} =~ /(^|^\w+ )bcc/
                ? 'cc3250'                 # ... Borland
                : 'msvcrt'                 # ... otherwise assume Microsoft
          )
        : 'm'                              # default to Unix-style
;

# Cases are AoH: { arg => $string, missing => $string }
my @cases = (
    { arg => qq{lib => 'foo'},                    missing => ['foo'] },
    { arg => qq{lib => [qw/$platform_lib foo/]},  missing => ['foo'] },
    { arg => qq{lib => [qw/foo $platform_lib/]},  missing => ['foo'] },
    { arg => qq{lib => [qw/foo bar/]},            missing => [qw/foo bar/] },
);

plan tests => 3 * @cases;

for my $c ( @cases ) {
    eval "assert_lib(debug => $debug, $c->{arg})";
    my $err = $@;
    ok ( $err, "died on '$c->{arg}'" );
    my $miss_string = join(q{, }, map { qq{'$_'} } @{$c->{missing}} );
    like ($err, "/^Can't link\/include C library ${miss_string}/ms",
        "missing $miss_string detected"
    );
    ok(!check_lib(debug => $debug, eval($c->{arg})),
      "... and check_lib is false");
}
