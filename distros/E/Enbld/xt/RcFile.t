#!/usr/bin/perl

use strict;
use warnings;

use autodie;
use File::Temp;
use File::Spec;

use Test::More;
use Test::Exception;

require Enbld::HTTP;

require_ok( 'Enbld::RcFile' );

subtest 'lack of arguments' => sub {
    throws_ok {
        Enbld::RcFile->new;
    } qr/Configuration file's command is not specified/, 'lack of command';
};

subtest 'set contents - error' => sub {
    my $rcfile = Enbld::RcFile->new(
            command   => 'set',
            filepath  => 'rcfile.txt',
            );

    throws_ok {
        $rcfile->do;
    } qr/Configuration file's contents isn't set/, 'set error';
};

subtest 'set contents' => sub {
    my $dir = File::Temp->newdir;
    my $filename = '.enbldrc';
    my $fullpath = File::Spec->catfile( $dir, $filename );

    my $rcfile = Enbld::RcFile->new(
            filepath    =>  $filename,
            directory   =>  $dir,
            contents    =>  'Enbld',
            command     =>  'set',
            );

    is( $rcfile->do, $filename, 'set rcfile' );

    ok( -e $fullpath, 'create rc file' );
    
    open my $fh, '<', $fullpath;
    my $content = do { local $/; <$fh> };
    close $fh;

    like( $content, qr/Enbld/, 'contents' );

    my @DSL;
    push @DSL, "conf '.enbldrc' => set {\n";
    push @DSL, "    to '" . $dir . "';\n";
    push @DSL, "    content 'Enbld';\n";
    push @DSL, "};\n";

    my $DSLed = $rcfile->DSL;

    is_deeply( $DSLed, \@DSL, 'DSL' );

    my $serialized = $rcfile->serialize;

    is_deeply( $serialized,
            {
            filepath    => $filename,
            command     => 'set',
            contents    => "Enbld",
            directory   => $dir,
            },
            'serialized' );
};

subtest 'set contents - digest same' => sub {

    my $file     = 'rcfile.txt';
    my $dir      = File::Temp->newdir;
    my $contents = 'configuration string';

    open my $fh, '>', File::Spec->catfile( $dir, $file );
    print $fh $contents;
    close $fh;

    my $rcfile = Enbld::RcFile->new(
            command     => 'set',
            directory   => $dir,
            filepath    => $file,
            contents    => $contents,
            );

    my $result = $rcfile->do;

    is( $result, undef, 'digest is same' );
};

subtest 'set contents - digest different' => sub {

    my $file     = 'rcfile.txt';
    my $dir      = File::Temp->newdir;
    my $contents = 'configuration string';

    open my $fh, '>', File::Spec->catfile( $dir, $file );
    print $fh $contents . ",but different";
    close $fh;

    my $rcfile = Enbld::RcFile->new(
            command     => 'set',
            directory   => "$dir",
            filepath    => $file,
            contents    => $contents,
            );

    my $result = $rcfile->do;

    isnt( $result, undef, 'digest is diffrence' );
};

subtest 'load conf' => sub {
    my $dir = File::Temp->newdir;
    my $filepath = '.vimrc';
    my $fullpath = File::Spec->catfile( $dir, $filepath );
    my $url = 'https://raw.github.com/magnolia-k/vimrc/master/.vimrc';

    my $rcfile = Enbld::RcFile->new(
          filepath  =>  $filepath,
          directory =>  $dir,
          url       =>  $url,
          command   =>  'load',
          );

    is( $rcfile->do, $filepath, 'set rcfile' );
    ok( -e $fullpath, 'create rc file' );

    open my $fh, '<', $fullpath;
    my $content = do { local $/; <$fh> };
    close $fh;

    like( $content, qr/syntax on/, 'contents' );

    my $DSLed = $rcfile->DSL;

    like( $DSLed->[0], qr/load/, 'DSL' );

    my $serialized = $rcfile->serialize;

    is( $serialized->{filepath},  $filepath, 'filepath'  );
    is( $serialized->{command},   'load',    'command'   );
    is( $serialized->{directory}, $dir,      'directory' );
    is( $serialized->{contents},  undef,     'contents'  );
};

subtest 'load and set conf' => sub {
    my $dir = File::Temp->newdir;
    my $filepath = '.vimrc';
    my $fullpath = File::Spec->catfile( $dir, $filepath );
    my $url = 'https://raw.github.com/magnolia-k/vimrc/master/.vimrc';

    my $rcfile = Enbld::RcFile->new(
          filepath  =>  $filepath,
          directory =>  $dir,
          url       =>  $url,
          contents  =>  'contents',
          command   =>  'load',
          );

    is( $rcfile->do, $filepath, 'set rcfile' );
    ok( -e $fullpath, 'create rc file' );

    open my $fh, '<', $fullpath;
    my $content = do { local $/; <$fh> };
    close $fh;

    like( $content, qr/content/, 'contents' );

    my $DSLed = $rcfile->DSL;

    like( $DSLed->[0], qr/load/, 'DSL' );

    my $serialized = $rcfile->serialize;

    is( $serialized->{filepath},  $filepath, 'filepath'  );
    is( $serialized->{command},   'load',    'command'   );
    is( $serialized->{directory}, $dir,      'directory' );

    like( $serialized->{contents}, qr/content/, 'contents' );
};

subtest 'load conf - same digest' => sub {
    my $dir  = File::Temp->newdir;
    my $file = '.vimrc';
    my $url  = 'https://raw.github.com/magnolia-k/vimrc/master/.vimrc';

    Enbld::HTTP->download( $url, File::Spec->catfile( $dir, $file )); 

    my $rcfile = Enbld::RcFile->new(
          command   => 'load',
          filepath  => $file,
          directory => $dir,
          url       => $url,
          );

    my $result = $rcfile->do;
    is( $result, undef, 'digest is same' );
};

subtest 'load conf - different digest' => sub {
    my $dir  = File::Temp->newdir;
    my $file = '.vimrc';
    my $url  = 'https://raw.github.com/magnolia-k/vimrc/master/.vimrc';

    Enbld::HTTP->download( $url, File::Spec->catfile( $dir, $file ));

    my $rcfile = Enbld::RcFile->new(
          command   => 'load',
          filepath  => $file,
          directory => $dir,
          url       => $url,
          contents  => "additional string\n",
          );

    my $result = $rcfile->do;
    isnt( $result, undef, 'digest is different' );
};

subtest 'conf copy' => sub {
    my $source_dir      = File::Temp->newdir;
    my $destination_dir = File::Temp->newdir;
    my $filename        = '.enbldrc';

    my $path = File::Spec->catfile( $source_dir, $filename );
    open my $fh, '>', $path;
    print $fh "configuration string\n";
    close $fh;

    my $rcfile = Enbld::RcFile->new(
            command     =>  'copy',
            filepath    =>  $filename,
            directory   =>  $destination_dir,
            source      =>  $path,
            contents    =>  "additional string",
            );

    is( $rcfile->do, $filename, 'copy rcfile' );

    ok( -e File::Spec->catfile( $destination_dir, $filename ), 'create rc file' );
    
    open my $fh_contents, '<', File::Spec->catfile( $destination_dir, $filename );
    my $content = do { local $/; <$fh_contents> };
    close $fh_contents;

    like( $content, qr/configuration string/, 'contents' );

    my @DSL;
    push @DSL, "conf '.enbldrc' => copy {\n";
    push @DSL, "    from '" . $path . "';\n";
    push @DSL, "    to '" . $destination_dir . "';\n";
    push @DSL, "    content 'additional string';\n";
    push @DSL, "};\n";

    my $DSLed = $rcfile->DSL;

    is_deeply( $DSLed, \@DSL, 'DSL' );

    my $serialized = $rcfile->serialize;

    is_deeply( $serialized,
            {
            filepath    => $filename,
            command     => 'copy',
            contents    => 'additional string',
            directory   => $destination_dir,
            source      => $path,
            },
            'serialized' );
};

subtest 'conf copy - same digest' => sub {
    my $source_dir      = File::Temp->newdir;
    my $destination_dir = File::Temp->newdir;
    my $filename        = '.enbldrc';

    my $path = File::Spec->catfile( $source_dir, $filename );

    open my $fh_source, '>', $path;
    print $fh_source "configuration string\n";
    close $fh_source;

    open my $fh_destination, '>', File::Spec->catfile( $destination_dir, $filename );
    print $fh_destination "configuration string\n";
    close $fh_destination;

    my $rcfile = Enbld::RcFile->new(
            command     =>  'copy',
            filepath    =>  $filename,
            directory   =>  $destination_dir,
            source      =>  $path,
            );

    is( $rcfile->do, undef, 'same digest' );
};

subtest 'conf copy - different digest' => sub {
    my $source_dir      = File::Temp->newdir;
    my $destination_dir = File::Temp->newdir;
    my $filename        = '.enbldrc';

    my $path = File::Spec->catfile( $source_dir, $filename );

    open my $fh_source, '>', $path;
    print $fh_source "configuration string\n";
    close $fh_source;

    open my $fh_destination, '>', File::Spec->catfile( $destination_dir, $filename );
    print $fh_destination "configuration string, with additional string\n";
    close $fh_destination;

    my $rcfile = Enbld::RcFile->new(
            command     =>  'copy',
            filepath    =>  $filename,
            directory   =>  $destination_dir,
            source      =>  $path,
            );

    isnt( $rcfile->do, undef, 'different digest' );
};

done_testing();
