#!perl
use 5.014;
use strict;
use warnings;
use utf8;
use Test::More;

use Game::Terminal::Kit::Frame;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw/output failure_output todo_output/;

sub box { return Game::Terminal::Kit::Frame::box(@_) }
sub shape { my $box = box(@_); return join '', @{$box}{ Game::Terminal::Kit::Frame::parts() } }

subtest 'the names' => sub {
	plan tests => 5;
	is_deeply [Game::Terminal::Kit::Frame::marks()], [qw/cursor from target recent plain/],
		'the marks, strongest first';
	is_deeply [Game::Terminal::Kit::Frame::parts()], [qw/tl t tr l r bl b br/], 'the parts of a box';
	is Game::Terminal::Kit::Frame::known('cursor'), 'cursor', 'a mark is itself';
	is Game::Terminal::Kit::Frame::known('sparkly'), 'plain', 'anything else is plain';
	is Game::Terminal::Kit::Frame::known(undef), 'plain', 'and so is nothing';
};

subtest 'every box is whole and one column a glyph' => sub {
	my @marks = Game::Terminal::Kit::Frame::marks();
	plan tests => 4 * @marks;
	for my $mark (@marks) {
		for my $ascii (0, 1) {
			my $box = box($mark, $ascii);
			my $form = $ascii ? 'ASCII' : 'Unicode';
			is_deeply [sort keys %{$box}], [sort { $a cmp $b } Game::Terminal::Kit::Frame::parts()],
				"$mark in $form has the eight parts";
			is_deeply [grep { length $box->{$_} != 1 } keys %{$box}], [],
				"$mark in $form is one character a part";
		}
	}
};

subtest 'the boxes themselves' => sub {
	plan tests => 12;
	is shape('plain'), '┌─┐││└─┘', 'plain is light';
	is shape('recent'), '╔═╗║║╚═╝', 'recent is double';
	is shape('cursor'), '┏━┓┃┃┗━┛', 'the cursor is heavy';
	is shape('from'), shape('plain'), 'from is light, told apart by its brackets';
	is shape('target'), shape('plain'), 'and so is target';
	is shape('plain', 1), '+-+||+-+', 'plain in ASCII';
	is shape('recent', 1), '#=#||#=#', 'recent in ASCII';
	is shape('cursor', 1), '+=+||+=+', 'the cursor in ASCII';
	unlike shape($_, 1), qr/[^ -~]/, "$_ in ASCII is ASCII" for qw/plain recent cursor/;
	is shape('sparkly'), shape('plain'), 'an unknown mark is boxed plain';
};

subtest 'three shapes that cannot be confused' => sub {
	plan tests => 6;
	for my $ascii (0, 1) {
		my %top = map { $_ => join '', @{ box($_, $ascii) }{qw/tl t tr/} } qw/plain recent cursor/;
		my $form = $ascii ? 'ASCII' : 'Unicode';
		isnt $top{plain}, $top{recent}, "plain and recent differ along the top in $form";
		isnt $top{plain}, $top{cursor}, "plain and the cursor differ in $form";
		isnt $top{recent}, $top{cursor}, "recent and the cursor differ in $form";
	}
};

subtest 'brackets' => sub {
	plan tests => 8;
	my %want = (
		plain => [' ', ' '], recent => ['{', '}'], cursor => ['[', ']'],
		from => ['(', ')'], target => ['<', '>'],
	);
	is_deeply [Game::Terminal::Kit::Frame::brackets($_)], $want{$_}, "$_ brackets" for sort keys %want;
	is_deeply [Game::Terminal::Kit::Frame::brackets('sparkly')], [' ', ' '], 'an unknown mark has none';
	my %seen;
	$seen{ join '', Game::Terminal::Kit::Frame::brackets($_) }++ for keys %want;
	is scalar(keys %seen), 5, 'the five pairs are five different pairs';
	is_deeply [grep { length != 2 } keys %seen], [], 'and each is two columns';
};

subtest 'the strongest of several' => sub {
	plan tests => 7;
	is Game::Terminal::Kit::Frame::strongest(), 'plain', 'none is plain';
	is Game::Terminal::Kit::Frame::strongest('recent'), 'recent', 'one is itself';
	is Game::Terminal::Kit::Frame::strongest('recent', 'cursor'), 'cursor', 'the cursor beats recent';
	is Game::Terminal::Kit::Frame::strongest('cursor', 'recent'), 'cursor', 'in either order';
	is Game::Terminal::Kit::Frame::strongest('target', 'recent', 'from'), 'from', 'from beats target and recent';
	is Game::Terminal::Kit::Frame::strongest('recent', 'target'), 'target', 'target beats recent';
	is Game::Terminal::Kit::Frame::strongest('sparkly', undef), 'plain', 'unknown marks are plain';
};

subtest 'a box round some lines' => sub {
	plan tests => 5;
	is_deeply [Game::Terminal::Kit::Frame::around('cursor', 0, ' 6 ', ' 4 ')],
		['┏━━━┓', '┃ 6 ┃', '┃ 4 ┃', '┗━━━┛'], 'the cursor round a tile';
	is_deeply [Game::Terminal::Kit::Frame::around('recent', 1, ' 6 ', ' 4 ')],
		['#===#', '| 6 |', '| 4 |', '#===#'], 'recent in ASCII';
	is_deeply [Game::Terminal::Kit::Frame::around('plain', 1, 'long', 'a', '')],
		['+----+', '|long|', '|a   |', '|    |', '+----+'], 'short lines are padded to the longest';
	is_deeply [Game::Terminal::Kit::Frame::around('plain', 1)], ['++', '++'], 'no lines is an empty box';
	my %width;
	$width{length $_}++ for map { Game::Terminal::Kit::Frame::around($_, 0, 'ab', 'c') } qw/plain recent cursor/;
	is_deeply [keys %width], [4], 'every line of every weight is the same width';
};

done_testing;
