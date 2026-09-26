#!perl
use strict;
use warnings;
use Test::More;

# A library that prints cannot be embedded, and a library that prints only on
# the paths nobody tested is worse. Everything that writes to a handle lives
# in Game::Durak::Terminal, and this is the grep that says so.

my $TERMINAL = 'lib/Game/Durak/Terminal.pm';

my @NOISY = (
    [ qr/\bprint\b/          => 'print' ],
    [ qr/\bprintf\b/         => 'printf' ],
    [ qr/\bsay\s*\(/         => 'say()' ],
    [ qr/\bwarn\b/           => 'warn' ],
    [ qr/\bSTDOUT\b/         => 'STDOUT' ],
    [ qr/\bSTDERR\b/         => 'STDERR' ],
);

opendir my $dh, 'lib/Game/Durak' or die "lib/Game/Durak: $!";
my @modules = ('lib/Game/Durak.pm',
               map { "lib/Game/Durak/$_" } grep { /\.pm\z/ } readdir $dh);
closedir $dh;

cmp_ok(scalar @modules, '>=', 9, scalar(@modules) . ' modules to read');

my ($code, @caught);

for my $file (sort @modules) {
    next if $file eq $TERMINAL;

    open my $fh, '<', $file or die "$file: $!";
    my $in_pod = 0;
    while (my $line = <$fh>) {
        $in_pod = 1 if $line =~ /\A=\w/;
        $in_pod = 0 if $line =~ /\A=cut/;
        last if $line =~ /\A__END__/;
        next if $in_pod || $line =~ /\A\s*\z/;
        $code++;
        for my $rule (@NOISY) {
            my ($pattern, $what) = @$rule;
            push @caught, "$file:$.: $what" if $line =~ $pattern;
        }
    }
    close $fh;
}

is_deeply(\@caught, [], 'nothing outside the terminal writes to a handle');
cmp_ok($code, '>=', 400, "$code lines of code were read");

# The terminal itself does print, or the grep above is measuring nothing.
open my $fh, '<', $TERMINAL or die "$TERMINAL: $!";
my $terminal = do { local $/; <$fh> };
close $fh;
like($terminal, qr/\bprint\b/, 'and the terminal does');

# The grep has to be able to fail.
my @would = grep { "    print {\$handle} \$line;\n" =~ $_->[0] } @NOISY;
cmp_ok(scalar @would, '>=', 1, 'a line that prints is caught');

# die is not printing: a state that cannot happen says so and stops, and the
# engine does that on purpose.
my $dies = 0;
for my $file (sort @modules) {
    open my $in, '<', $file or die "$file: $!";
    while (my $line = <$in>) {
        last if $line =~ /\A__END__/;
        $dies++ if $line =~ /\bdie\b/;
    }
    close $in;
}
cmp_ok($dies, '>=', 10, "$dies impossible states die rather than print");

done_testing();
