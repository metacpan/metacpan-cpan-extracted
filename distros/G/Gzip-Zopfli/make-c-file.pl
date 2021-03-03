#!/home/ben/software/install/bin/perl
use Z;
my $dir = '/home/ben/software/zopfli/zopfli-zopfli-1.0.3/src/zopfli';
my @c = <$dir/*.c>;
my @h = <$dir/*.h>;
my %h2file;
for my $hfile (@h) {
    my $h = $hfile;
    $h =~ s!.*/!!;
    $h2file{$h} = read_text ($hfile);
}
my $out = "$Bin/zopfli-one.c";
my $c = '';
for my $file (@c) {
    my $text = read_text ($file);
    $c .= $text;
}
# Do this until all the #include "" are gone.
while ($c =~ s!^#\s*include\s*"(.*?)"!/* $1 */\n$h2file{$1}!gm) {
}
# Suppress compiler warnings.
$c =~ s!(ZOPFLI_CACHE_LENGTH \* 3 \* blocksize)!(unsigned long) ($1)!g;
#$c =~ s!^#\s*include\s*"(.*?)"!/* $1 */\n$h2file{$1}!gm;
write_text ($out, $c);
do_system ("cc -Wall -c $out");
my $o = $out;
$o =~ s!\.c!.o!;
unlink ($o) or die $!;
