#!perl -T
use strict;
use warnings;

use Test::More tests => 34;
use Test::Exception;
use Math::Geometry::Construction;

sub is_close {
    my ($value, $reference, $message, $limit) = @_;

    cmp_ok(abs($value - $reference), '<', ($limit || 1e-12), $message);
}

sub construction {
    my $construction;
    my $output;

    $construction = Math::Geometry::Construction->new;
    ok(defined($construction), 'construction is defined');
    isa_ok($construction, 'Math::Geometry::Construction');
    is($construction->count_objects, 0, 'no objects yet');

    throws_ok(sub { $construction->draw },
	      qr/undef/,
	      'draw requires type');
    foreach('Foo; system',
	    '!foo',
	    ';',
	    '!',
	    '$abc',
	    '@bar',
	    ',',
	    ',baz',
	    'Foo::Bar;',
	    '%Foo::Bar',
	    'foo9::bar::Baz; ')
    {
	throws_ok(sub { $construction->draw($_) },
		  qr/regex/,
		  'draw type regex check');
    }

    foreach('Foo::Bar',
	    'Foo98::Bar_Baz')
    {
	throws_ok(sub { $construction->draw($_) },
		  qr/Unable to load module $_/,
		  'valid but non-existing output class');
    }

    my $prefix = 'Math::Geometry::Construction::Draw::';
    foreach('Foo',
	    'QUX13',
	    'Foo:Bar',
	    '1',
	    'a')
    {
	throws_ok(sub { $construction->draw($_) },
		  qr/Unable to load module $prefix$_/,
		  'valid but non-existing output class');
    }

    throws_ok(sub { $construction->draw('SVG') },
	      qr/Attribute \((?:width|height)\) is required/,
	      'width required in draw');
    throws_ok(sub { $construction->draw('SVG', width => 100) },
	      qr/Attribute \(height\) is required/,
	      'height required in draw');
    $output = $construction->draw('SVG', width => 100, height => 100);
    isa_ok($output, 'SVG');

    throws_ok(sub { $construction->as_svg },
	      qr/Attribute \((?:width|height)\) is required/,
	      'width required in as_svg');
    throws_ok(sub { $construction->as_svg(width => 100) },
	      qr/Attribute \(height\) is required/,
	      'height required in as_svg');

    $output = $construction->as_svg(width => 100, height => 200);
    isa_ok($output, 'SVG');

    throws_ok(sub { $construction->draw('TikZ') },
	      qr/Attribute \((?:width|height)\) is required/,
	      'width required in draw');
    throws_ok(sub { $construction->draw('TikZ', width => 100) },
	      qr/Attribute \(height\) is required/,
	      'height required in draw');
    $output = $construction->draw('TikZ', width => 100, height => 100);
    isa_ok($output, 'LaTeX::TikZ::Set::Sequence');

    throws_ok(sub { $construction->as_tikz },
	      qr/Attribute \((?:width|height)\) is required/,
	      'width required in as_tikz');
    throws_ok(sub { $construction->as_tikz(width => 100) },
	      qr/Attribute \(height\) is required/,
	      'height required in as_tikz');

    $output = $construction->as_tikz(width => 100, height => 200);
    isa_ok($output, 'LaTeX::TikZ::Set::Sequence');
}

construction;
