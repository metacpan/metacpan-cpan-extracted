#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/vf2_sub_graph_iso.hpp>

using namespace boost;

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

template <typename CorrespondenceMap>
struct property_map_perl {
    property_map_perl(const CorrespondenceMap corr_map) :
        m_corr_map(corr_map) {}

    template <typename ItemFirst, typename ItemSecond>
    bool operator()(const ItemFirst item1, const ItemSecond item2) {
        return (m_corr_map[item1][item2]);
    }

    private:
        const CorrespondenceMap m_corr_map;
};

template <typename CorrespondenceMap>
property_map_perl<CorrespondenceMap>
make_property_map_perl
(const CorrespondenceMap corr_map) {
    return (property_map_perl<CorrespondenceMap>(corr_map));
}

template <typename Graph1, typename Graph2>
struct print_callback {
    print_callback(const Graph1& graph1, const Graph2& graph2, std::vector<int>& correspondence)
      : graph1_(graph1), graph2_(graph2), correspondence_(correspondence) {}

    template <typename CorrespondenceMap1To2,
              typename CorrespondenceMap2To1>
    bool operator()(CorrespondenceMap1To2 f, CorrespondenceMap2To1) const {
        BGL_FORALL_VERTICES_T(v, graph1_, Graph1) {
            correspondence_.push_back( get(vertex_index_t(), graph1_, v) );
            correspondence_.push_back( get(vertex_index_t(), graph2_, get(f, v)) );
        }

        return true;
    }
    
    private:
        const Graph1& graph1_;
        const Graph2& graph2_;
        std::vector<int>& correspondence_;
};

MODULE = Graph::VF2		PACKAGE = Graph::VF2

SV *
_vf2(vertices1, edges1, vertices2, edges2, vertex_map)
        SV * vertices1
        SV * edges1
        SV * vertices2
        SV * edges2
        SV * vertex_map
    CODE:
        typedef property< edge_name_t, SV* > edge_property;
        typedef property< vertex_name_t, SV*, property< vertex_index_t, int > > vertex_property;
        typedef adjacency_list< setS, vecS, undirectedS, vertex_property, edge_property > graph_type;

        // Build graph1
        int num_vertices1 = av_top_index((AV*) SvRV(vertices1)) + 1;
        graph_type graph1;
        for (ssize_t i = 0; i < num_vertices1; i++) {
            add_vertex( vertex_property(newSViv(1)), graph1 );
        }
        for (ssize_t i = 0; i <= av_top_index((AV*) SvRV(edges1)); i++) {
            AV * edge = (AV*) SvRV( av_fetch( (AV*) SvRV(edges1), i, 0 )[0] );
            add_edge( SvIV( av_fetch( edge, 0, 0 )[0] ),
                      SvIV( av_fetch( edge, 1, 0 )[0] ), graph1 );
        }

        // Build graph2
        int num_vertices2 = av_top_index((AV*) SvRV(vertices2)) + 1;
        graph_type graph2;
        for (ssize_t i = 0; i < num_vertices2; i++) {
            add_vertex( vertex_property(newSViv(1)), graph2 );
        }
        for (ssize_t i = 0; i <= av_top_index((AV*) SvRV(edges2)); i++) {
            AV * edge = (AV*) SvRV( av_fetch( (AV*) SvRV(edges2), i, 0 )[0] );
            add_edge( SvIV( av_fetch( edge, 0, 0 )[0] ),
                      SvIV( av_fetch( edge, 1, 0 )[0] ), graph2 );
        }

        bool** corr_map = (bool**)calloc(num_vertices1, sizeof(bool*));
        for (int i = 0; i < num_vertices1; ++i) {
            corr_map[i] = (bool*)calloc(num_vertices2, sizeof(bool));
            AV * line = (AV*) SvRV( av_fetch( (AV*) SvRV(vertex_map), i, 0 )[0] );
            for (int j = 0; j < num_vertices2; ++j) {
                corr_map[i][j] = SvIV( av_fetch( line, j, 0 )[0] );
            }
        }

        auto vertex_comp = make_property_map_perl(corr_map);
        // Edge predicate is unused - TODO
        auto edge_comp = make_property_map_perl(corr_map);

        std::vector<int> correspondence;

        // Create callback to print mappings
        print_callback< graph_type, graph_type > callback(graph1, graph2, correspondence);

        // Print out all subgraph isomorphism mappings between graph1 and graph2.
        // Vertices and edges are assumed to be always equivalent.
        vf2_subgraph_iso(graph1, graph2, callback, vertex_order_by_mult(graph1),
            edges_equivalent(always_equivalent()).vertices_equivalent(vertex_comp));

        for (int i = 0; i < num_vertices1; ++i) {
            free(corr_map[i]);
        }
        free(corr_map);

        AV* map = newAV();

        for (int n : correspondence)
            av_push( map, newSViv( n ) );

        RETVAL = newRV_noinc( (SV*)map );
    OUTPUT:
        RETVAL
