#!perl -T

use Test::More tests => 17;

BEGIN {
    use_ok('Math::Geometry::Construction::Types')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Vector')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::FixedPoint')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Line')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Circle')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Derivate')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Derivate::IntersectionLineLine')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Derivate::IntersectionCircleLine')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Derivate::IntersectionCircleCircle')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Derivate::TranslatedPoint')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Derivate::PointOnLine')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Derivate::PointOnCircle')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::DerivedPoint')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Draw')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Draw::SVG')
	|| print "Bail out!\n";
    use_ok('Math::Geometry::Construction::Draw::TikZ')
	|| print "Bail out!\n";
}

diag( "Testing Math::Geometry::Construction $Math::Geometry::Construction::VERSION, Perl $], $^X" );
