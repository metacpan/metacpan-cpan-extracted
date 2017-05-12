#!/usr/bin/env perl

# Creation date: 2007-02-19 16:49:01
# Authors: don

use strict;

use 5.006_00;
    
use ExtUtils::MakeMaker;
use File::Spec;
use Config;

my $src_dir = 'libjsonevt';

my $on_windows;
# for stuff to skip/change on Windows
if ($^O =~ /MSWin/) {
    $on_windows = 1;
    # $use_jsonevt = 0;
}

my @utf_files = qw/utf8 utf16 utf32/;
my @utf_headers = map { "$_.h" } @utf_files;

# my $obj_str = join(' ', map { "$_\$(OBJ_EXT)" } @utf_files, 'evt', 'jsonevt', 'json_writer',
#                    'print', 'old_parse', 'old_common');
my $obj_str = join(' ', map { "$_\$(OBJ_EXT)" } @utf_files, 'evt', 'jsonevt', 'json_writer',
                   'print', 'old_common', 'convenience');

sub MY::postamble {
    my ($self) = @_;

    my $stuff = '';

    my $exec_output_name = sub { my ($name) = @_;
                                 if ($on_windows and $self->{CC}
                                     and $self->{CC} =~ /\Acl(?:\.exe)?\Z/) {
                                     return "/Fe$name";
                                 }
                                 else {
                                     return "-o $name";
                                 }
                             };
    
    my $cc = '$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) ';
    my $cc_main = '$(CC) $(PASTHRU_INC) $(INC) $(CCFLAGS) $(OPTIMIZE) $(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION) $(XS_DEFINE_VERSION) ';
    my $config_h = File::Spec->catfile($src_dir, 'jsonevt_config.h');

    $stuff .= "\$(INST_DYNAMIC): $obj_str $config_h\n\n";
    
    $stuff .= "evt\$(OBJ_EXT): evt.c\n\n";
    # $stuff .= "old_parse\$(OBJ_EXT): old_parse.c old_parse.h old_common.h\n\n";
    $stuff .= "old_common\$(OBJ_EXT): old_common.c old_common.h\n\n";
    # $stuff .= "DWIW\$(OBJ_EXT): DWIW.h old_parse.h old_common.h $config_h\n\n";
    $stuff .= "DWIW\$(OBJ_EXT): DWIW.h old_common.h $config_h\n\n";

#     my $make_conf = File::Spec->catfile($src_dir, 'make_config');
#     my $exec_make_conf = File::Spec->rel2abs($make_conf);
#     $exec_make_conf .= " $config_h ./check_config " . $cc_main . ' ' . $exec_output_name->('check_config');
    
    my $add_evt_obj = sub {
        my ($name, @extra_headers) = @_;
        my $rv = '';
        
        $rv .= "$name\$(OBJ_EXT): ";
        $rv .= join(' ', map { File::Spec->catfile($src_dir, $_) }
                    ('jsonevt.h', 'jsonevt_private.h', @utf_headers, 'uni.h',
                     "$name.c", @extra_headers));
        $rv .= "\n";
        $rv .= "\t$cc " . File::Spec->catfile($src_dir, "$name.c") . "\n";
        $rv .= "\n";
        
        return $rv;
    };

    $stuff .= "$obj_str: $config_h\n\n";

#     $stuff .= "$config_h: $make_conf\n\t$exec_make_conf\n\n";
#     $stuff .= "$make_conf: $make_conf.c\n\t$cc_main " . $exec_output_name->($make_conf)
#         . " $make_conf.c\n\n";

#     use Data::Dumper;
#     $Data::Dumper::Sortkeys = 1;
#     print STDERR Data::Dumper->Dump([ $self ], [ 'self' ]) . "\n\n";
    
#     my $perl_exec;
#     for my $v (qw(FULLPERLRUN ABSPERLRUN FULLPERL ABSPERL)) {
#         if (defined($self->{$v})) {
#             $perl_exec = "\$($v)";
#             last;
#         }
#     }

    # my $perl_exec = $^X;
    my $perl_exec = $Config::Config{perlpath};
        
    $stuff .= "$config_h:\n\tcd $src_dir; ./configure && ./fixup_config '$perl_exec'\n\n";
    
    $stuff .= $add_evt_obj->('jsonevt');
    $stuff .= $add_evt_obj->('json_writer');
    $stuff .= $add_evt_obj->('print', 'print.h');
    $stuff .= $add_evt_obj->('convenience');

    foreach my $file (@utf_files) {
        $stuff .= "$file\$(OBJ_EXT): ";
        $stuff .= join(' ', map { File::Spec->catfile($src_dir, $_) }
                       ("$file.c", "$file.h", 'uni.h'));
        $stuff .= "\n";
        
        $stuff .= "\t" . '$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) ';
        $stuff .= File::Spec->catfile($src_dir, "$file.c") . "\n";
        $stuff .= "\n";
    }
    
    return $stuff;
}

sub MY::post_constants {
    my ($self) = @_;

    my @updates;

    my $optimize = $self->{OPTIMIZE};
    $optimize = '' unless $optimize;
    
    if ($ENV{DEVEL_JSON_DWIW}) {
        $optimize .= ' -Wall' unless $optimize =~ /-Wall/;
        $optimize .= ' -Werror' unless $optimize =~ /-Werror/;
    }

    if ($ENV{DEBUG_JSON_DWIW}) {
        $optimize .= ' -DDO_DEBUG';
        $optimize .= ' -g' unless $optimize =~ /-g/;
    }

    # $optimize .= ' -ansi -pedantic';
    
    push @updates, "OPTIMIZE = $optimize";

    return join("\n", @updates);
}

my $clean_str = join(' ', map { File::Spec->catfile('libjsonevt', $_) }
                     ('*.a', '*.so', '*$(OBJ_EXT)', 'jsonevt_config.h', 'make_config'));

my $args = {
            NAME => 'JSON::DWIW',
            DISTNAME => 'JSON-DWIW',
            VERSION_FROM => 'lib/JSON/DWIW.pm',
            ABSTRACT => 'JSON converter that does what I want',
            AUTHOR => 'DON OWENS <don@regexguy.com>',
            PM => { 'lib/JSON/DWIW.pm' => '$(INST_LIBDIR)/DWIW.pm',
                    'lib/JSON/DWIW/Boolean.pm' => '$(INST_LIBDIR)/DWIW/Boolean.pm',
                    'lib/JSON/DWIW/Changes.pm' => '$(INST_LIBDIR)/DWIW/Changes.pm',
                  },
            dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
            DIR => [],
            EXE_FILES => [],
            PREREQ_PM => { 'Test::More' => 0,
                         },
            clean => { FILES => $clean_str },
            # OPTIMIZE => '-Wall -O3 -fno-non-lvalue-assign -g',
            # OPTIMIZE => '-O2 -g -Wall',
            # OPTIMIZE => '-Wall -O3 -Werror',
           };

$args->{DEFINE} = "-DHAVE_JSONEVT -DNO_VERSION_IN_ERROR";
$args->{LDFROM} = "\$(OBJECT) $obj_str";
$args->{INC} = "-I$src_dir";

WriteMakefile(%$args);


