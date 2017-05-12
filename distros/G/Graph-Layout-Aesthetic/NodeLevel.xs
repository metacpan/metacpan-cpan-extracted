#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

/* attribute 'node level' - level of node (from root) */

#include "at_node_level.h"
#include <limits.h>

/* Temporarily abuse sorted list as array of booleans */
#define at_level_assigned	level_sorted_vertex

static aglo_signed at_node_level_tree(aglo_graph graph, aglo_vertex v) {
    aglo_edge_record p;
    aglo_signed kid_level=1;

    if (graph->at_level_assigned[v]) return graph->at_level[v];

    graph->at_level_assigned[v] = true;
    graph->at_level[v] = 0;

    for (p=graph->edge_table[v];p;p=p->next)
        if (p->forward) {
            aglo_signed k = at_node_level_tree(graph, p->tail);
            if (k < kid_level) kid_level = k;
        }

    return graph->at_level[v] = kid_level - 1;
}

static void at_contract_node_level_tree(aglo_graph graph) {
    aglo_boolean change;

    do {
        aglo_unsigned i;
        aglo_edge_record p;

        change=false;
        for (i=0; i<graph->vertices; i++) {
            aglo_signed max_p_level = -INT_MAX;
            for (p=graph->edge_table[i]; p; p=p->next)
                if (!p->forward)
                    if (max_p_level < graph->at_level[p->tail])
                        max_p_level = graph->at_level[p->tail];
            if (max_p_level == -INT_MAX) continue;
            max_p_level++;
            if (max_p_level < graph->at_level[i]) {
                graph->at_level[i] = max_p_level;
                change=true;
            }
        }
    } while (change);
}

static void at_make_node_level_lists(aglo_graph graph, aglo_signed level) {
    aglo_vertex i, vcount;
    aglo_signed levels;
    aglo_vertex **level_ptr, *vertex_ptr;

    levels = -1;
    for (i=0; i<graph->vertices; i++) {
        graph->at_level[i] -= level;
        if (graph->at_level[i] < 0) 
            croak("Vertex %"UVuf" has negative node level %"IVdf, 
                  (UV) i, (IV) graph->at_level[i]);
        if (graph->at_level[i] > levels) levels = graph->at_level[i];
    }
    levels++;

    if (graph->level2nodes) {
        Safefree(graph->level2nodes);
        graph->level2nodes = NULL;
    }
    New(__LINE__, graph->level2nodes, levels+2, aglo_vertex *);
    
    level_ptr   = graph->level2nodes;
    vertex_ptr  = graph->level_sorted_vertex;
    vcount = 0;		/* doublecheck */
    for (level = 0; vcount < graph->vertices; level++) {
        aglo_vertex tvcount = vcount;

        *level_ptr++ = vertex_ptr;
        for (i=0; i<graph->vertices; i++)
            if (graph->at_level[i] == level) {
                *vertex_ptr++ = i;
                vcount++;
            }
        if (vcount == tvcount) croak("no nodes at level %"IVdf, (IV) level);
    }
    if (level != levels) croak("Expected %"IVdf" levels, found %"IVdf, 
                               (IV) levels, (IV) level);
    *level_ptr++ = vertex_ptr;
    *level_ptr++ = vertex_ptr;
    graph->nr_levels = levels;
}

static void at_calculate_node_level(aglo_graph graph) {
    aglo_vertex i;
    aglo_signed lev;
    aglo_signed min_level = INT_MAX;

    if (graph->at_level) {
        Safefree(graph->at_level);
        graph->at_level = NULL;
    }
    if (graph->level_sorted_vertex) {
        Safefree(graph->level_sorted_vertex);
        graph->level_sorted_vertex = NULL;
    }
    New(__LINE__, graph->at_level, graph->vertices, aglo_signed);
    Newz(__LINE__, graph->level_sorted_vertex, graph->vertices, aglo_vertex);

    /* initial assignement */
    for (i=0; i<graph->vertices; i++) {
        lev = at_node_level_tree(graph, i);
        if (lev < min_level) min_level = lev;
    }

    /* contraction */
    at_contract_node_level_tree(graph);
    at_make_node_level_lists(graph, min_level);
}

void at_setup_node_level(aglo_graph graph) {
    if (!graph->done) 
        croak("Won't calculate node levels on an unfinished topology");
    if (!graph->level_sequence) {
        at_calculate_node_level(graph);
        graph->level_sequence = 1;
    }
}

MODULE = Graph::Layout::Aesthetic::Dummy::NodeLevel	PACKAGE = Graph::Layout::Aesthetic::Dummy
