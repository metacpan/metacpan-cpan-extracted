#!/usr/bin/perl
#
# KeyFile stuff.
#
use strict;
use warnings;
use Cwd qw(cwd);
use File::Spec; # for catfile()
use Glib ':constants';
use Test::More tests => 33;

my $str = <<__EOK__
#top of the file

[mysection]
intkey=42
stringkey=hello
boolkey=1
doublekey=3.1415

[listsection]
intlist=1;1;2;3;5;8;13;
stringlist=Some;Values;In;A;List;
boollist=false;true;false
doublelist=23.42;3.1415

[locales]
#some string
mystring=Good morning
mystring[it]=Buongiorno
mystring[es]=Buenas dias
mystring[fr]=Bonjour
mystring[de]=Guten Tag
__EOK__
;

SKIP: {
	skip "Glib::KeyFile is new in glib 2.6.0", 33
		unless Glib->CHECK_VERSION (2, 6, 0);

	ok (defined Glib::KeyFile->new ());

	my $key_file = Glib::KeyFile->new;
	isa_ok ($key_file, 'Glib::KeyFile');

	my @groups;
	@groups = $key_file->get_groups;
	is (@groups, 0, 'we have no groups');

	ok ($key_file->load_from_data(
			$str,
			[ 'keep-comments', 'keep-translations' ]
		));

	@groups = $key_file->get_groups;
	is (@groups, 3, 'now we have two groups');

	is ($key_file->get_comment(undef, undef), "top of the file\n", 'we reached the top');

	my $start_group = 'mysection';
	ok ($key_file->has_group($start_group));
	is ($key_file->get_start_group, $start_group, 'start group');

	ok ($key_file->has_key($key_file->get_start_group, 'stringkey'));

	my $intval = 42;
	my $stringval = 'hello';
	my $boolval = TRUE;
	is ($key_file->get_string($start_group, 'stringkey'), $stringval, 'howdy?');
	is ($key_file->get_value($start_group, 'intkey'), $intval, 'the answer');
	is ($key_file->get_integer($start_group, 'intkey'), $intval, 'the answer, reloaded');
	is ($key_file->get_boolean($start_group, 'boolkey'), $boolval, 'we stay true to ourselves');

	ok ($key_file->has_group('listsection'));

	my @integers = $key_file->get_integer_list('listsection', 'intlist');
	is (@integers, 7, 'fibonacci would be proud');

	my @strings = $key_file->get_string_list('listsection', 'stringlist');
	eq_array (\@strings, ['Some', 'Values', 'In', 'A', 'List'], 'we are proud too');

	my @bools = $key_file->get_boolean_list('listsection', 'boollist');
	is (@bools, 3);
	eq_array (\@bools, [FALSE, TRUE, FALSE]);

	ok ($key_file->has_group('locales'));
	like ($key_file->get_comment('locales', 'mystring'), qr/^some string$/);
	is ($key_file->get_string('locales', 'mystring'), 'Good morning');
	is ($key_file->get_locale_string('locales', 'mystring', 'it'), 'Buongiorno');

	$key_file->set_locale_string_list('locales', 'mystring', 'en', 'one', 'two', 'three');
	is_deeply([$key_file->get_locale_string_list('locales', 'mystring', 'en')], ['one', 'two', 'three']);

	$key_file->set_string_list('listsection', 'stringlist', 'one', 'two', 'three');
	$key_file->set_locale_string('locales', 'mystring', 'en', 'one');
	$key_file->set_comment('locales', 'mystring', 'comment');
	like ($key_file->get_comment('locales', 'mystring'), qr/^comment$/);
	$key_file->set_comment('locales', undef, "another comment\n");
	is ($key_file->get_comment('locales', undef),
		Glib::major_version > 2 ||
		(Glib::major_version == 2 && Glib::minor_version >= 77) ?
		"another comment\n" : "#another comment\n#"
	);
	$key_file->set_comment(undef, undef, 'one comment more');
	like ($key_file->get_comment(undef, undef), qr/^one comment more$/);
	$key_file->set_boolean($start_group, 'boolkey', FALSE);
	$key_file->set_value($start_group, 'boolkey', '0');

	is_deeply([$key_file->get_keys('mysection')], ['intkey', 'stringkey', 'boolkey', 'doublekey']);

	SKIP: {
		skip "double stuff", 4
			unless Glib->CHECK_VERSION (2, 12, 0);

		my $epsilon = 1e-6;

		ok($key_file->get_double('mysection', 'doublekey') - 3.1415 < $epsilon);
		$key_file->set_double('mysection', 'doublekey', 23.42);
		ok($key_file->get_double('mysection', 'doublekey') - 23.42 < $epsilon);

		my @list = $key_file->get_double_list('listsection', 'doublelist');
		ok($list[0] - 23.42 < $epsilon &&
		   $list[1] - 3.1415 < $epsilon);

		$key_file->set_double_list('listsection', 'doublelist', 3.1415, 23.42);
		@list = $key_file->get_double_list('listsection', 'doublelist');
		ok($list[0] - 3.1415 < $epsilon &&
		   $list[1] - 23.42 < $epsilon);
	}

	$key_file->remove_comment('locales', 'mystring');
	$key_file->remove_comment('locales', undef);
	$key_file->remove_comment(undef, undef);
	$key_file->remove_key('locales', 'mystring');
	$key_file->remove_group('mysection');
	$key_file->remove_group('listsection');
	$key_file->remove_group('locales');

	is($key_file->to_data(), "");

	$key_file->set_list_separator(ord(':'));

	SKIP: {
		skip "load_from_dirs", 3
			unless Glib->CHECK_VERSION (2, 14, 0);

		my $file = 'tmp.ini';
		open my $fh, '>', $file or
			skip "load_from_dirs, can't create temporary file", 3;
		print $fh $str;
		close $fh;

		my $key_file = Glib::KeyFile->new;
		my ($success, $path) =
			$key_file->load_from_dirs($file,
						  [ 'keep-comments' ],
						  cwd(), '/tmp');
		ok ($success);
		is (File::Spec->canonpath($path), File::Spec->catfile(cwd(), $file));
		is ($key_file->get_comment(undef, undef), "top of the file\n", 'we reached the top again');

		unlink $file;
	}
}

__END__

Copyright (C) 2005 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
