use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;
use Path::Class qw( file dir );
use ExtUtils::Typemaps;

plan tests => 5;

$ENV{DIST_ZILLA_PLUGIN_MATH64_TEST} = file(__FILE__)->parent->parent->absolute->subdir('share')->stringify;

note "share = $ENV{DIST_ZILLA_PLUGIN_MATH64_TEST}";

subtest 'root' => sub {
  plan tests => 10;
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          # [MathInt64]
          'MathInt64',
        ),
      },
    }
  );

  $tzil->build;

  note $_->name for @{ $tzil->files };

  ok grep { $_->name eq 'perl_math_int64.c' } @{ $tzil->files };
  ok grep { $_->name eq 'perl_math_int64.h' } @{ $tzil->files };
  ok grep { $_->name eq 'perl_math_int64_types.h' } @{ $tzil->files };
  
  my($file) = grep { $_->name eq 'typemap' } @{ $tzil->files };
  
  ok $file;
  
  SKIP: {
    skip "typemap failed", 6 unless $file;
    note $file->content;
    my $typemap = ExtUtils::Typemaps->new(string => $file->content);
    ok $typemap->get_typemap(ctype => 'int64_t');
    ok $typemap->get_typemap(ctype => 'uint64_t');
    ok $typemap->get_inputmap(xstype => 'T_INT64');
    ok $typemap->get_inputmap(xstype => 'T_UINT64');
    ok $typemap->get_outputmap(xstype => 'T_INT64');
    ok $typemap->get_outputmap(xstype => 'T_UINT64');
  };
};

subtest 'merge' => sub {
  plan tests => 15;
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT2' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          # [MathInt64]
          'MathInt64',
        ),
      },
    }
  );

  $tzil->build;

  note $_->name for @{ $tzil->files };
  ok grep { $_->name eq 'perl_math_int64.c' } @{ $tzil->files };
  ok grep { $_->name eq 'perl_math_int64.h' } @{ $tzil->files };
  ok grep { $_->name eq 'perl_math_int64_types.h' } @{ $tzil->files };
  
  my($file) = grep { $_->name eq 'typemap' } @{ $tzil->files };
  
  ok $file;
  
  SKIP: {
    skip "typemap failed", 10 unless $file;
    note $file->content;
    my $typemap = ExtUtils::Typemaps->new(string => $file->content);
    ok $typemap->get_typemap(ctype => 'int64_t');
    ok $typemap->get_typemap(ctype => 'uint64_t');
    ok $typemap->get_typemap(ctype => 'struct archive *');
    ok $typemap->get_typemap(ctype => 'string_or_null');
    ok $typemap->get_inputmap(xstype => 'T_INT64');
    ok $typemap->get_inputmap(xstype => 'T_UINT64');
    ok $typemap->get_inputmap(xstype => 'T_PV_OR_NULL');
    ok $typemap->get_outputmap(xstype => 'T_INT64');
    ok $typemap->get_outputmap(xstype => 'T_UINT64');
    ok $typemap->get_outputmap(xstype => 'T_PV_OR_NULL');
  };
  
  pass 'and it was good';
};

subtest 'typemap_path' => sub {
  plan tests => 10;
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          # [MathInt64]
          [ 'MathInt64', => { typemap_path => 'xs/typemap' } ],
        ),
      },
    }
  );

  $tzil->build;

  ok grep { $_->name eq 'perl_math_int64.c' } @{ $tzil->files };
  ok grep { $_->name eq 'perl_math_int64.h' } @{ $tzil->files };
  ok grep { $_->name eq 'perl_math_int64_types.h' } @{ $tzil->files };

  my($file) = grep { $_->name eq 'xs/typemap' } @{ $tzil->files };

  ok $file;

  SKIP: {
    skip "typemap failed", 6 unless $file;
    note $file->content;
    my $typemap = ExtUtils::Typemaps->new(string => $file->content);
    ok $typemap->get_typemap(ctype => 'int64_t');
    ok $typemap->get_typemap(ctype => 'uint64_t');
    ok $typemap->get_inputmap(xstype => 'T_INT64');
    ok $typemap->get_inputmap(xstype => 'T_UINT64');
    ok $typemap->get_outputmap(xstype => 'T_INT64');
    ok $typemap->get_outputmap(xstype => 'T_UINT64');
  };
};

subtest 'dir' => sub {
  plan tests => 10;
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          # [MathInt64]
          # dir = xs
          [ 'MathInt64' => { dir => 'xs' } ],
        ),
      },
    }
  );

  $tzil->build;

  ok grep { $_->name eq 'xs/perl_math_int64.c' } @{ $tzil->files };
  ok grep { $_->name eq 'xs/perl_math_int64.h' } @{ $tzil->files };
  ok grep { $_->name eq 'xs/perl_math_int64_types.h' } @{ $tzil->files };

  my($file) = grep { $_->name eq 'typemap' } @{ $tzil->files };

  ok $file;

  SKIP: {
    skip "typemap failed", 6 unless $file;
    note $file->content;
    my $typemap = ExtUtils::Typemaps->new(string => $file->content);
    ok $typemap->get_typemap(ctype => 'int64_t');
    ok $typemap->get_typemap(ctype => 'uint64_t');
    ok $typemap->get_inputmap(xstype => 'T_INT64');
    ok $typemap->get_inputmap(xstype => 'T_UINT64');
    ok $typemap->get_outputmap(xstype => 'T_INT64');
    ok $typemap->get_outputmap(xstype => 'T_UINT64');
  };
};

subtest 'no typemap' => sub {
  plan tests => 4;
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          # [MathInt64]
          [ 'MathInt64' => { typemap => 0 } ],
        ),
      },
    }
  );

  $tzil->build;

  ok grep { $_->name eq 'perl_math_int64.c' } @{ $tzil->files };
  ok grep { $_->name eq 'perl_math_int64.h' } @{ $tzil->files };
  ok grep { $_->name eq 'perl_math_int64_types.h' } @{ $tzil->files };
  ok ! grep { $_->name eq 'typemap' } @{ $tzil->files };
};
