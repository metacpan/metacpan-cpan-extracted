#! perl

use strict;
use warnings;

use Test::More;
use English::Name;

my %mapping = (
	"\1RG" => "_",
	"\14IST_SEPARATOR" => "\"",
	"\20ID" => "\$",
	"\20ROCESS_ID" => "\$",
	"\20ROGRAM_NAME" => "0",
	"\22EAL_GROUP_ID" => "(",
	"\7ID" => "(",
	"\5FFECTIVE_GROUP_ID" => ")",
	"\5GID" => ")",
	"\22EAL_USER_ID" => "<",
	"\25ID" => "<",
	"\5FFECTIVE_USER_ID" => ">",
	"\5UID" => ">",
	"\23UBSCRIPT_SEPARATOR" => ";",
	"\23UBSEP" => ";",
	"\17LD_PERL_VERSION" => "]",
	"\23YSTEM_FD_MAX" => "\6",
	"\11NPLACE_EDIT" => "\11",
	"\17SNAME" => "\17",
	"\20ERL_VERSION" => "\26",
	"\5XECUTABLE_NAME" => "\30",
	"\15ATCH" => "&",
	"\20REMATCH" => "`",
	"\20OSTMATCH" => "'",
	"\20ERLDB" => "\20",
	"\14AST_PAREN_MATCH" => "+",
	"\14AST_SUBMATCH_RESULT" => "\16",
	"\14AST_MATCH_END" => "+",
	"\14AST_MATCH_START" => "-",
	"\14AST_REGEXP_CODE_RESULT" => "\22",
	"\11NPUT_LINE_NUMBER" => ".",
	"\11NPUT_RECORD_SEPARATOR" => "/",
	"\22S" => "/",
	"\16R" => ".",
	"\17UTPUT_FIELD_SEPARATOR" => ",",
	"\17FS" => ",",
	"\17UTPUT_RECORD_SEPARATOR" => "\\",
	"\17RS" => "\\",
	"\17UTPUT_AUTOFLUSH" => "|",
	"\17S_ERROR" => "!",
	"\5RRNO" => "!",
	"\5XTENDED_OS_ERROR" => "\5",
	"\5XCEPTIONS_BEING_CAUGHT" => "\22",
	"\27ARNING" => "\27",
	"\5VAL_ERROR" => "@",
	"\3HILD_ERROR" => "?",
	"\3OMPILING" => "\3",
	"\4EBUGGING" => "\4",
);

my %win_skip = map { $_ => 1 } grep /UID|GID|USER_ID|GROUP_ID/, keys %mapping;

sub quote {
	my $name = shift;
	$name =~ s/ ^ ([\1-\32]) (.*) / length $2 ?  "{^" . chr(64 + ord $1) . $2 . "}" :  "^" . chr(64 + ord $1) /xe;
	return $name;
}

subtest 'Definedness' => sub {
	for my $name ("\4EBUGGING", "\5UID", "\23YSTEM_FD_MAX") {
		next if $^O eq 'MSWin32' && $win_skip{$name};
		no strict 'refs';
		ok(defined(${$name}), sprintf '$%s is defined', quote($name));
	}
};

subtest 'Equivalence' => sub {
	for my $name (sort keys %mapping) {
		next if $^O eq 'MSWin32' && $win_skip{$name};
		my $official = $mapping{$name};
		no strict 'refs';
		is($$name, $$official, sprintf '$%s equals $%s', quote($name), quote($official));
	}
};

{
	local $! = 42;
	is(0+${^ERRNO}, 42, '${^ERRNO} is now locally 42');
}

done_testing;
