#!/usr/bin/env perl

use strict;
use warnings;
use lib 'ext';
use inc::Module::Install;

name 'Gtk2-Phat';
license 'lgpl';
perl_version '5.008';
all_from 'lib/Gtk2/Phat.pm';

phat or exit;

requires 'Gtk2';

configure_requires 'Cwd';
configure_requires 'File::Spec';
configure_requires 'Gtk2::CodeGen';
configure_requires 'Glib::MakeHelper';
configure_requires 'ExtUtils::Depends';
configure_requires 'ExtUtils::PkgConfig';

test_requires 'Gtk2::TestHelper';

no_index directory => qw/inc ext/;

=for later

find out if refering to an xs file in a provides field is valid. the metayml
spec isn't very clear on that. cpants analyze fails if you do that. the spec
also doesn't say if omiting the file field is allowed. cpants reports an error
if you do so.

    provides map {
        ("Gtk2::Phat::$_" => { file => "xs/${_}.xs" })
    } (map {
        my $t = $_;
        map { $_ . $t } ('', qw/H V/)
    } qw/FanSlider Keyboard/), 'SliderButton';

=cut

extra_tests;
auto_provides;

WriteAll;
