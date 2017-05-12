package t::lib::XSP::Test;

use strict;
use warnings;
use if -d 'blib' => 'blib';

use Test::Base -Base;
use Test::Differences;
use ExtUtils::XSpp::Typemap;

our @EXPORT = qw(run_diff);

# allows running tests both from t and from the top directory
use File::Spec;
BEGIN {
  if (-d 't') {
    unshift @INC, File::Spec->catdir(qw(t lib));
  }
  elsif (-d "lib") {
    unshift @INC, "lib";
  }
}

filters { xsp_stdout => 'xsp_stdout',
          xsp_file   => 'xsp_file',
          };

sub run_diff(@) {
    my( $got, $expected ) = @_;

    run {
        my $block = shift;
        my( $b_got, $b_expected ) = map { s/^\n+//s; s/\n+$//s; $_ }
                                        $block->$got, $block->$expected;

        eq_or_diff( $b_got, $b_expected, $block->name);
    };
}

use ExtUtils::XSpp;

package t::lib::XSP::Test::Filter;

use Test::Base::Filter -base;

no warnings 'redefine';

# some fixed "random" values to simplify testing
my( @random_list, @random_digits ) =
    qw(017082 074990 737474 643532 738748 630394 284033);
sub ExtUtils::XSpp::Grammar::_random_digits {
    die "No more random values" unless @random_digits;
    return shift @random_digits;
}

sub _munge_output($) {
    my $b_got = $_[0];

    # This removes the default typemap entry that is added for O_OBJECT
    # I admit that it doesn't make me feel all warm and fuzzy inside, but
    # the alternative of having even more code duplicated a lot of times in
    # all test files isn't any better.
    $b_got =~ s/^INPUT\s*\n.*^OUTPUT\s*\n.*^END\s*\n/END\n/sm;
    # remove some more repetitive preamble code
    $b_got =~ s|^#include <exception>\n.*?^#define xsp_constructor_class.*?\n|# XSP preamble\n|sm;

    return $b_got;
}

sub xsp_stdout {
    ExtUtils::XSpp::Typemap::reset_typemaps();
    @random_digits = @random_list;
    my $d = ExtUtils::XSpp::Driver->new( string => shift );
    my $out = $d->generate;
    ExtUtils::XSpp::Typemap::reset_typemaps();

    return _munge_output( $out->{'-'} );
}

sub xsp_file {
    ExtUtils::XSpp::Typemap::reset_typemaps();
    @random_digits = @random_list;
    my $name = Test::Base::filter_arguments();
    my $d = ExtUtils::XSpp::Driver->new( string => shift );
    my $out = $d->generate;
    ExtUtils::XSpp::Typemap::reset_typemaps();

    return _munge_output( $out->{$name} );
}

1;
