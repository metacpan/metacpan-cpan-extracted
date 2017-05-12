#!/usr/bin/perl -w

use t::lib::QuickBundle::Test tests => 3;

create_bundle( <<EOI, 'Language' );
[application]
name=Language
version=0.01
dependencies=basic_dependencies
main=t/bin/basic.pl
languages=<<EOT
lang_default
lang_italian
lang_english
lang_korean
EOT

[lang_default]
language=default
version=0.01
copyright=Copyright 2011 Yoyodyne corp.
display=Basic Display Def

[lang_italian]
language=it
name=Basic IT
display=Basic display IT

[lang_english]
language=en

[lang_korean]
language=ko
name=Basic KO
display=Basic display KO
copyright=Copyright KO 2011 Yoyodyne corp.

[basic_dependencies]
scandeps=basic_scandeps

[basic_scandeps]
script=t/bin/perl.pl
EOI

sub _read {
    my( $lang ) = @_;
    my $file = "t/outdir/Language.app/Contents/Resources/$lang.lproj/InfoPlist.strings";

    open my $in, '<:encoding(utf-16)', $file or die "Can't open '$file': $!";
    local $/;

    return scalar <$in>;
}

is( _read( 'English' ), <<EOT );
CFBundleShortVersionString = "0.01";
NSHumanReadableCopyright = "Copyright 2011 Yoyodyne corp.";
CFBundleDisplayName = "Basic Display Def";
EOT

is( _read( 'Italian' ), <<EOT );
CFBundleGetInfoString = "Basic IT 0.01, Copyright 2011 Yoyodyne corp.";
CFBundleShortVersionString = "0.01";
NSHumanReadableCopyright = "Copyright 2011 Yoyodyne corp.";
CFBundleName = "Basic IT";
CFBundleDisplayName = "Basic display IT";
EOT

is( _read( 'ko' ), <<EOT );
CFBundleGetInfoString = "Basic KO 0.01, Copyright KO 2011 Yoyodyne corp.";
CFBundleShortVersionString = "0.01";
NSHumanReadableCopyright = "Copyright KO 2011 Yoyodyne corp.";
CFBundleName = "Basic KO";
CFBundleDisplayName = "Basic display KO";
EOT
