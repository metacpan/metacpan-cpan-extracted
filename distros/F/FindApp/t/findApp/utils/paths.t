#!/usr/bin/env perl

use t::setup;

use FindApp::Utils qw(function);

my @FUNCS = qw(
    basename_noext  
    dir_file_ext   
    file_dir_ext  
    is_absolute  
    is_relative 
    module2path     
    pathify_modules
);

my $NO_EMPTY = qr/paths cannot be empty/;
my $NO_UNDEF = qr/paths cannot be undef/;

my $Module; BEGIN {
   $Module = "FindApp::Utils::Paths";
   use_ok($Module, ":all") || die;
}

run_tests();

################

sub parse_tests {

    my $path = "/tmp/foo.tar.gz";
    cmp_ok basename_noext($path), "eq", "foo", "basename_noext($path) is 'foo'";

    my($dir, $file, $ext) = dir_file_ext($path);
    cmp_ok $dir,  "eq", "/tmp/",        "found dir of '/tmp/' after dir_file_ext($path)";
    cmp_ok $file, "eq", "foo",          "found file of 'foo' after dir_file_ext($path)";
    cmp_ok $ext,  "eq", ".tar.gz",      "found ext of '.tar.gz' after dir_file_ext($path)";

    ($file, $dir, $ext) = file_dir_ext($path);
    cmp_ok $file, "eq", "foo",          "found file of 'foo' after file_dir_ext($path)";
    cmp_ok $dir,  "eq", "/tmp/",        "found dir of '/tmp/' after file_dir_ext($path)";
    cmp_ok $ext,  "eq", ".tar.gz",      "found ext of '.tar.gz' after file_dir_ext($path)";
}

sub pathify_tests {
    my $mod  = "Some::Where::Else";
    my $path = "Some/Where/Else.pm";

    my @answer = pathify_modules($mod);
    cmp_ok scalar @answer, "==", 1, "one answer for one question";
    cmp_ok $answer[0], "eq", $path, "$mod pathifies to $path";

    @answer = pathify_modules($path);
    cmp_ok $answer[0], "eq", $path, "$path pathifies back to same $path unaltered";

}

sub exception_tests {
    die "no funcs" unless @FUNCS;
    for my $func (@FUNCS) {
        no strict "refs";
        throws_ok { $func->(undef) } $NO_UNDEF, "$func dies on arg of undef";
        throws_ok { $func->("")    } $NO_EMPTY, "$func dies on arg of zero-length string";
    }
}

sub filename_tests {

    my @abs_paths = qw( / /. /.. // /fingol /fin/weg );
    my @rel_paths = qw(   .   ..     fingol  fin/weg );

    for my $abs (@abs_paths) {
        ok  is_absolute($abs), "path '$abs' is absolute";
        ok !is_relative($abs), "path '$abs' isn't relative";
    }

    for my $rel (@rel_paths) {
        ok !is_absolute($rel), "path '$rel' isn't absolute";
        ok  is_relative($rel), "path '$rel' is relative";
    }

    for my $path (@abs_paths, @rel_paths) {
        cmp_ok is_absolute($path), "!=", is_relative($path), 
            "path '$path' isn't both absolute and relative at the same time";
    }

}

#basename_noext, dir_file_ext, file_dir_ext, is_absolute, is_relative, module2path, pathify_modules
