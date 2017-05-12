#!/usr/bin/perl
# $Id$
use strict;
use warnings;
use utf8;
use Test::More;
use Glib qw(TRUE FALSE);

unless (Glib -> CHECK_VERSION (2, 6, 0)) {
  plan skip_all => 'the option stuff is new in 2.6';
} else {
  plan tests => 33;
}

# --------------------------------------------------------------------------- #

my ($none, $string, $int, $filename, $string_array, $filename_array);

my $entries = [
  { long_name => 'none',
    short_name => 'n',
    flags => [qw/reverse in-main/],
    arg_type => 'none',
    arg_value => \$none,
    description => 'none desc.',
    arg_description => 'none arg desc.' },

  { long_name => 'string',
    short_name => 's',
    arg_type => 'string',
    arg_value => \$string },

  { long_name => 'int',
    short_name => 'i',
    arg_type => 'int',
    arg_value => \$int },

  { long_name => 'filename',
    short_name => undef,
    arg_type => 'filename',
    arg_value => \$filename },

  { long_name => 'string-array',
    arg_type => 'string-array',
    arg_value => \$string_array },

  [ 'filename-array', undef, 'filename-array', \$filename_array ],
];

# --------------------------------------------------------------------------- #

# Misc. non-parse API.
{
  my $context = Glib::OptionContext -> new('- urgsify your life');
  isa_ok($context, 'Glib::OptionContext');

  $context -> set_help_enabled(TRUE);
  is($context -> get_help_enabled(), TRUE);

  $context -> set_ignore_unknown_options(TRUE);
  is($context -> get_ignore_unknown_options(), TRUE);

  my $group = Glib::OptionGroup -> new(name => 'urgs',
                                       description => 'Urgs Urgs Urgs',
                                       help_description => 'Help with Urgs',
                                       entries => $entries);
  isa_ok($group, 'Glib::OptionGroup');

  $context -> set_main_group($group);
  isa_ok($context -> get_main_group(), 'Glib::OptionGroup');
}

# --------------------------------------------------------------------------- #

# Translation stuff.  Commented out since it aborts the program.
{
  my $context = Glib::OptionContext -> new('- urgsify your life');
  my $group = Glib::OptionGroup -> new(name => 'urgs',
                                       description => 'Urgs Urgs Urgs',
                                       help_description => 'Help with Urgs',
                                       entries => $entries);

  $group -> set_translation_domain('de_DE');
  $group -> set_translate_func(sub {
    my ($string, $data) = @_;

    warn $string;
    warn $data;

    return reverse $string;
  }, 'atad');

  $context -> add_group($group);

  #@ARGV = qw(--help);
  #@ARGV = qw(--help-urgs);
  #$context -> parse();
}

# --------------------------------------------------------------------------- #

# Parsing.
{
  my $context = Glib::OptionContext -> new('- urgsify your life');
  $context -> add_main_entries($entries, 'de_DE');

  # Test that undef is preserved.
  {
    @ARGV = qw();
    $context -> parse();

    is ($none, FALSE); # FIXME?
    is ($string, undef);
    is ($int, 0); # FIXME?
    is ($filename, undef);
    is ($string_array, undef);
    is ($filename_array, undef);
  }

  # Test that existing values are not overwritten.
  {
    $none = TRUE;
    $string = 'ürgs';
    $int = 23;
    $filename = $^X;
    $string_array = [qw/á é í ó ú/];
    $filename_array = [$^X, $0];

    @ARGV = qw();
    $context -> parse();

    is ($none, TRUE);
    is ($string, 'ürgs');
    is ($int, 23);
    is ($filename, $^X);
    is_deeply ($string_array, [qw/á é í ó ú/]);
    is_deeply ($filename_array, [$^X, $0]);
  }

  # Test actual parsing.
  {
    @ARGV = qw(-n
               -s bla
               -i 42
               --filename ~/Foo
               --string-array aaa --string-array bbb
               --filename-array /usr/bin/bla --filename-array ./harness);
    $context -> parse();

    is ($none, FALSE);
    is ($string, 'bla');
    is ($int, 42);
    is ($filename, '~/Foo');
    is_deeply ($string_array, [qw/aaa bbb/]);
    is_deeply ($filename_array, [qw(/usr/bin/bla ./harness)]);
  }

  # Test that there is no double-encoding for utf8-encoded strings.
SKIP:  {
    my $codeset;
    # This eval() was taken from <https://metacpan.org/module/I18N::Langinfo>
    # and from a suggestion from Kevin Ryde
    eval {
        require I18N::Langinfo;
        $codeset = I18N::Langinfo::langinfo(I18N::Langinfo::CODESET());
    };
    # If there was an error requiring I18N::Langinfo, then skip this block of
    # tests; we need I18N::Langinfo to check LC_ALL/LANG
    skip("Can't check LC_ALL/LANG, I18N::Langinfo unavailable; $@", 4)
        if ( length($@) > 0 );
    # If LC_ALL/LANG is not some variant of UTF-8 (8-bit, wide/multibyte
    # characters), skip this block of tests
    skip("Can't test parsing of wide-byte args (non-UTF-8 locale: $codeset)", 4)
        if ( $codeset !~ /UTF-8|utf8/i );
    @ARGV = qw(-s ❤ ❤);
    $context -> parse();

    is ($string, '❤');
    is (length $string, 1);

    is ($ARGV[0], '❤');
    is (length $ARGV[0], 1);
  }
}

# --------------------------------------------------------------------------- #

SKIP: {
  skip 'new 2.12 stuff', 6
    unless Glib->CHECK_VERSION(2, 12, 0);

  my ($double, $int64);

  my $entries = [
    [ 'double', 'd', 'double', \$double ],
    [ 'int64',  'i', 'int64',  \$int64 ],
  ];
  my $context = Glib::OptionContext -> new('- urgsify your life');
  $context -> add_main_entries($entries, 'de_DE');

  # Test that undef is preserved.
  {
    @ARGV = qw();
    $context -> parse();

    is ($double, 0); # FIXME?
    is ($int64, 0); # FIXME?
  }

  # Test that existing values are not overwritten.
  {
    $double = 0.23;
    $int64 = 23;

    @ARGV = qw();
    $context -> parse();

    ok ($double - 0.23 < 1e-6);
    is ($int64, 23);
  }

  # Test actual parsing.
  {
    @ARGV = qw(-d 0.42
               -i 42);
    $context -> parse();

    ok ($double - 0.42 < 1e-6);
    is ($int64, 42);
  }
}
