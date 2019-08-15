#include "tesselate.h"
#include "mapbox/earcut.hpp"
#include <memory>
#include <assert.h>

using coord_t = geos::geom::Coordinate;

namespace mapbox {
namespace util {

template <>
struct nth<0, coord_t> {
    inline static auto get(const coord_t &t) {
        return t.x;
    };
};
template <>
struct nth<1, coord_t> {
    inline static auto get(const coord_t &t) {
        return t.y;
    };
};

} // namespace util
} // namespace mapbox

namespace panda { namespace Geos {

geos::geom::GeometryCollection* tesselate(geos::geom::Polygon& input) {
    using seq_holder_t = std::unique_ptr<geos::geom::CoordinateSequence>;
    using result_t = std::vector<geos::geom::Geometry*>;
    using poly_sequence_t = std::vector<coord_t>;

    auto shell = input.getExteriorRing();
    auto shell_coords = seq_holder_t{shell->getCoordinates()};
    std::vector<poly_sequence_t> polygon;
    poly_sequence_t linearized;

    /* outer ring/shell */
    assert(shell_coords->size() > 1);
    poly_sequence_t shell_seq;
    for (size_t i = 0; i < shell_coords->size() - 1; ++i) {
        auto& coord = shell_coords->getAt(i);
        shell_seq.push_back(coord);
        linearized.push_back(coord);
    }
    polygon.push_back(shell_seq);

    /* inner rings/holes */
    auto holes_num = input.getNumInteriorRing();
    for (size_t i = 0; i < holes_num; ++i) {
        auto* hole = input.getInteriorRingN(i);
        auto hole_coords = seq_holder_t{hole->getCoordinates()};
        assert(hole_coords->size() > 1);
        poly_sequence_t seq;
        for (size_t j = 0; j < hole_coords->size() - 1; ++j) {
            auto& coord = hole_coords->getAt(j);
            seq.push_back(coord);
            linearized.push_back(coord);
        }
        polygon.push_back(seq);
    }

    /* run tesselation */
    using N = uint32_t;
    std::vector<N> indices = mapbox::earcut<N>(polygon);
    auto vertices = indices.size();
    if (!vertices) throw "no tesselation (invalid polygon?)";
    assert(vertices % 3 == 0);

    /* construct triangles as polygones */
    auto factory = input.getFactory();
    auto seq_factory = factory->getCoordinateSequenceFactory();
    auto triangles = new result_t();
    for(size_t i = 0; i < indices.size(); i += 3) {
        auto& c_A = linearized[indices[i + 0]];
        auto& c_B = linearized[indices[i + 1]];
        auto& c_C = linearized[indices[i + 2]];
        auto seq = seq_holder_t{seq_factory->create(4, 2)};
        seq->setAt(c_A, 0);
        seq->setAt(c_B, 1);
        seq->setAt(c_C, 2);
        seq->setAt(c_A, 3); /* close the poly */

        auto shell = factory->createLinearRing(seq.release());
        auto holes = new std::vector<geos::geom::Geometry*>();
        auto poly = factory->createPolygon(shell, holes);
        triangles->push_back(poly);
    }

    return factory->createGeometryCollection(triangles);
}


}}
