#!perl ## no critic (TidyCode)

use strict;
use warnings;

use Data::Dumper ();
use Locale::TextDomain::OO::Util::Constants;

our $VERSION = 0;

my $const = Locale::TextDomain::OO::Util::Constants->instance;

() = print {*STDOUT} Data::Dumper ## no critic (LongChainsOfMethodCalls)
    ->new(
        [
            {
                lexicon_key_separator => $const->lexicon_key_separator,
                msg_key_separator     => $const->msg_key_separator,
                plural_separator      => $const->plural_separator,
            },
        ],
        [ qw( constants ) ],
    )
    ->Indent(1)
    ->Quotekeys(0)
    ->Sortkeys(1)
    ->Useqq(1)
    ->Dump;

# $Id: 01_constants.pl 635 2017-02-23 06:54:16Z steffenw $

__END__

Output:

$constants = {
  lexicon_key_separator => ":",
  msg_key_separator => "\4",
  plural_separator => "\0"
};
