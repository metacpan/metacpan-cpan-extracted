#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;

use Dist::Zilla::File::OnDisk;
use Dist::Zilla::Plugin::PruneAliases;

plan tests => 4 + 1;


sub is_alias {
	my $file = Dist::Zilla::File::OnDisk->new(name => shift);
	return Dist::Zilla::Plugin::PruneAliases::_is_alias(undef, $file);
}

lives_and { ok   is_alias 't/corpus/alias' } 'alias';
lives_and { ok ! is_alias 't/corpus/file'  } 'file';
lives_and { ok ! is_alias 't/corpus/book'  } 'book';
lives_and { ok ! is_alias 't/corpus/empty' } 'empty';


done_testing;
