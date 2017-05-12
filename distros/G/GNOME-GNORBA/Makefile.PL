use ExtUtils::MakeMaker;

$cflags = `gnome-config --cflags gtk`;
undef $cflags if $?;

$libs = `gnome-config --libs gtk`;
undef $libs if $?;

@libs = split ' ', $libs;
@newlibs;
foreach (@libs) {
    if ($_ !~ /^-l/ || $_ eq "-lX11") {
	push @newlibs, $_;
    }
}
$libs = join (" ", @newlibs);

WriteMakefile(
    'NAME'	=> 'GNOME::GNORBA',
    'VERSION_FROM' => 'GNORBA.pm',
    'INC'	=> $cflags,
    'LIBS'	=> [$libs],
    'DEFINE'	=> '',
    'OPTIMIZE'  => '-g -Wall',
    'INC'	=> '',
);
