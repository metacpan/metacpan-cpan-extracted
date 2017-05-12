// Quick and very dirty port of of the clustering algorithm implementation
// from Andreas Noack's <http://code.google.com/p/linloglayout/> released
// under the terms of the LGPLv2.1+.

#include <list>
#include <map>
#include <istream>
#include <ostream>
#include <string>
#include <algorithm>
#include <iostream>
#include <sstream>
#include <fstream>
#include <vector>
#include <limits>

extern "C"
{
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

#undef max

class node {
public:
  node() : name(-1), weight(0) {
  }
  node(long aName, double aWeight) : weight(aWeight), name(aName) {
  }
  node(std::map< std::string, long>& string_map, std::string aName, double aWeight)
    : weight(aWeight) {
    if (string_map.find(aName) != string_map.end()) {
      name = string_map.find(aName)->second;
    } else {
      name = string_map.size();
      string_map.insert(std::pair<std::string, long>(aName, name));
    }
  }
  long name;
  double weight;
  int operator==(const node& right) const {
    return name == right.name;
  }
  bool operator<(const node& right) const {
    return name < right.name;
  }
};

class edge {
public:
  edge(node aSrc, node aDst, double aWeight)
    : src(aSrc), dst(aDst), weight(aWeight) {
  }
  class node src;
  class node dst;
  double weight;
  int operator==(const edge& right) const {
    return src == right.src && dst == right.dst && weight == right.weight;
  }
};

class NewmanGirvan {
public:
  std::map< std::string, long> string_map;
  std::map< std::string, node > nameToNode;
  std::map< long, double > nameToWeight;
  std::map< node, std::string > nodeToName;
  std::map< std::pair< node, node >, double> edgeToWeight;
  std::map< std::pair< node, node >, double>::iterator edgeToWeight_iter;

  void add_edge(std::string src, std::string dst, double weight) {
    if (nameToNode.find(src) == nameToNode.end()) {
      node new_node = createNode(src, 0);
      nameToNode.insert(std::pair<std::string, node>(src, new_node));
      nodeToName.insert(std::pair<node, std::string>(new_node, src));
    }
    if (nameToNode.find(dst) == nameToNode.end()) {
      node new_node = createNode(dst, 0);
      nameToNode.insert(std::pair<std::string, node>(dst, new_node));
      nodeToName.insert(std::pair<node, std::string>(new_node, dst));
    }
    edgeToWeight.insert(std::pair< std::pair<node, node>, double>(
      std::pair<node, node>(nameToNode[src], nameToNode[dst]),
      weight
    ));
  }

  void set_vertex_weight(std::string vertex, double weight) {
    nameToWeight[ string_map[vertex] ] = weight;
  }

  std::map<std::string, int> run() {
    std::list< edge > edges;
    for (edgeToWeight_iter = edgeToWeight.begin(); edgeToWeight_iter != edgeToWeight.end(); ++edgeToWeight_iter) {
      node src = edgeToWeight_iter->first.first;
      node dst = edgeToWeight_iter->first.second;
      double weight = edgeToWeight_iter->second;
      double revWeight = 0;
      std::pair<node, node> rev = std::pair<node,node>(dst, src);
      if (edgeToWeight.find(rev) != edgeToWeight.end()) {
        revWeight = edgeToWeight[rev];
      } else {
        edges.push_back(createEdge(dst, src, weight + revWeight));
      }
      edges.push_back(createEdge(src, dst, weight + revWeight));
    }

    std::list<edge> edges2;
    for (std::list< edge >::iterator i = edges.begin(); i != edges.end(); ++i) {
      edges2.push_back(createEdge(createNode(i->src.name, nameToWeight[ i->src.name ]),
                                  createNode(i->dst.name, nameToWeight[ i->dst.name ]),
                            i->weight));
    }

    edges = edges2;

    std::list<node> nodes;

    for (std::map< std::string, node >::iterator i = nameToNode.begin(); i != nameToNode.end(); ++i) {
      nodes.push_back(createNode(i->second.name, nameToWeight[i->second.name]));
    }

    std::map<node, int> temp = execute(nodes, edges, false);
    std::map<std::string, int> result;
    for (std::map<node, int>::const_iterator i = temp.begin(); i != temp.end(); ++i) {
      result[ nodeToName[ i->first ] ] = i->second;
    }
    return result;
  }

  node createNode(long aName, double aWeight) {
    return node(aName, aWeight);
  }
  node createNode(std::string aName, double aWeight) {
    return node(string_map, aName, aWeight);
  }
  edge createEdge(node aSrc, node aDst, double aWeight) {
    return edge(aSrc, aDst, aWeight);
  }
  void refine(std::map<node, int> nodeToCluster, std::map< node, std::list<edge> > nodeToEdges, double atedges, double atpairs);
  std::map<node, int> cluster(std::list<node>& nodes, std::list<edge>& edges, double atedges, double atpairs);
  std::map<node, int> execute(std::list<node>& nodes, std::list<edge>& edges, bool ignoreLoops);

};

double
edge_density(class edge& edge) {
  return edge.weight / (edge.src.weight * edge.dst.weight);
}

double qualityFunc(double interAtedges, double interAtpairs, double atedges, double atpairs) {
  return interAtedges/atedges - interAtpairs/atpairs;
}

void
NewmanGirvan::refine(std::map<node, int> nodeToCluster, std::map< node, std::list<edge> > nodeToEdges, double atedges, double atpairs) {
  int maxCluster = 0;

  for (std::map< node, int >::const_iterator i = nodeToCluster.begin(); i != nodeToCluster.end(); ++i) {
    maxCluster = std::max(maxCluster, i->second);
  }

  // compute clusterToAtnodes, interAtedges, interAtpairs
  std::vector<double> clusterToAtnodes( nodeToCluster.size() + 1 );

  for (std::map< node, int >::const_iterator i = nodeToCluster.begin(); i != nodeToCluster.end(); ++i) {
    clusterToAtnodes[nodeToCluster[i->first]] += i->first.weight;
  }

  double interAtedges = 0.0;
  for (std::map< node, std::list<edge> >::const_iterator i = nodeToEdges.begin(); i != nodeToEdges.end(); ++i) {
    for (std::list<edge>::const_iterator i2 = i->second.begin(); i2 != i->second.end(); ++i2) {
      if ( !nodeToCluster[i2->src] == nodeToCluster[i2->dst] ) {
        interAtedges += i2->weight;
      }
    }
  }
  double interAtpairs = 0.0;

  for (std::map< node, int >::const_iterator i = nodeToCluster.begin(); i != nodeToCluster.end(); ++i) {
    interAtpairs += i->first.weight;
  }

  interAtpairs *= interAtpairs; 

  for (std::vector<double>::const_iterator i = clusterToAtnodes.begin(); i != clusterToAtnodes.end(); ++i) {
    interAtpairs -= *i * *i;
  }

  // greedily move nodes between clusters 
  double prevQuality = std::numeric_limits<double>::max(); 
  double quality = qualityFunc(interAtedges, interAtpairs, atedges, atpairs);

  while (quality < prevQuality) {
    prevQuality = quality;
    for (std::map< node, int >::const_iterator i = nodeToCluster.begin(); i != nodeToCluster.end(); ++i) {
      node node = i->first;
      int bestCluster = 0; 
      double bestQuality = quality, bestInterAtedges = interAtedges, bestInterAtpairs = interAtpairs;
      std::vector<double> clusterToAtedges(nodeToCluster.size() + 1);

      for (std::list<edge>::const_iterator i = nodeToEdges[node].begin(); i != nodeToEdges[node].end(); ++i) {
        if (!(i->dst == node)) {
          // count weight twice to include reverse edge
          clusterToAtedges[nodeToCluster[i->dst]] += 2 * i->weight;
        }
      }
      int cluster = nodeToCluster[node];
      for (int newCluster = 0; newCluster <= maxCluster+1; newCluster++) {
        if (cluster == newCluster) continue;
        double newInterPairs = interAtpairs
          + clusterToAtnodes[cluster] * clusterToAtnodes[cluster]
          - (clusterToAtnodes[cluster]-node.weight) * (clusterToAtnodes[cluster]-node.weight)
          + clusterToAtnodes[newCluster] * clusterToAtnodes[newCluster]
          - (clusterToAtnodes[newCluster]+node.weight) * (clusterToAtnodes[newCluster]+node.weight);
        double newInterEdges = interAtedges 
          + clusterToAtedges[cluster]
        - clusterToAtedges[newCluster];
        double newQuality = qualityFunc(newInterEdges, newInterPairs, atedges, atpairs); 
        if (bestQuality - newQuality > 1e-8) {
          bestCluster = newCluster;
          bestQuality = newQuality;
          bestInterAtedges = newInterEdges;
          bestInterAtpairs = newInterPairs;
        }
      }
      if (bestQuality < quality) {
        clusterToAtnodes[cluster] -= node.weight;
        clusterToAtnodes[bestCluster] += node.weight;
        nodeToCluster[node] = bestCluster;
        maxCluster = std::max(maxCluster, bestCluster);
        quality = bestQuality;
        interAtedges = bestInterAtedges;
        interAtpairs = bestInterAtpairs;
      }
    }
  }
}

bool
compare_density(edge& first, edge& second) {
  return edge_density(first) > edge_density(second);
}

std::map<node, int>
NewmanGirvan::cluster(std::list<node>& nodes, std::list<edge>& edges, double atedges, double atpairs) {
    edges.sort(compare_density);

    std::map<node, node> nodeToContr;
    std::list<node> contrNodes;

    for (std::list<edge>::const_iterator i = edges.begin(); i != edges.end(); ++i) {
      edge edge = *i;
      if (edge_density(edge) < atedges/atpairs) break;
      if (edge.src == edge.dst) continue;
      if (nodeToContr.find(edge.src) != nodeToContr.end() || nodeToContr.find(edge.dst) != nodeToContr.end()) continue;
      // randomize contraction
      // if (!nodeToContr.isEmpty() && Math.random() < 0.5) continue;

      std::stringstream ss;
      ss << edge.src.name << " " << edge.dst.name;

      node contrNode = createNode(ss.str(), edge.src.weight + edge.dst.weight);

      nodeToContr.insert(std::pair<node,node>(edge.src, contrNode));
      nodeToContr.insert(std::pair<node,node>(edge.dst, contrNode));
      contrNodes.push_back(contrNode);
    }
    // terminal case: no nodes to contract
    if (nodeToContr.empty()) {
      std::map<node, int> nodeToCluster;
      int clusterId = 0;
      for (std::list<node>::const_iterator i = nodes.begin(); i != nodes.end(); ++i) {
        nodeToCluster.insert(std::pair<node, int>(*i, clusterId++));
      }
      return nodeToCluster;
    }

    // "contract" singleton clusters
    for (std::list<node>::const_iterator i = nodes.begin(); i != nodes.end(); ++i) {
      class node node = *i;
      if (nodeToContr.find(node) == nodeToContr.end()) {
        class node contrNode = createNode(node.name, node.weight);
        nodeToContr.insert(std::pair<class node, class node>(node, contrNode));
        contrNodes.push_back(contrNode);
      }
    }

    // contract edges
    std::map< node, std::map< node, double > > startToEndToWeight;
    std::map< node, std::map< node, double > >::const_iterator stetw_iter;

    for (std::list<node>::const_iterator i = contrNodes.begin(); i != contrNodes.end(); ++i) {
      startToEndToWeight.insert(std::pair<node, std::map<node, double> >(*i, std::map<node, double>()));
    }
    for (std::list<edge>::const_iterator i = edges.begin(); i != edges.end(); ++i) {
      class edge edge = *i;
      node contrStart = nodeToContr[edge.src];
      node contrEnd   = nodeToContr[edge.dst];
      double contrWeight = 0.0;
      std::map<node, double>& endToWeight = startToEndToWeight[contrStart];
      if (endToWeight.find(contrEnd) != endToWeight.end()) {
        contrWeight = endToWeight[contrEnd];
      }
      endToWeight[contrEnd] = contrWeight + edge.weight;
    }

    std::list<edge> contrEdges;
    for (stetw_iter = startToEndToWeight.begin(); stetw_iter != startToEndToWeight.end(); ++stetw_iter) {
      class node contrStart = stetw_iter->first;
      std::map<node, double>& endToWeight = startToEndToWeight[contrStart];
      for (std::map<node, double>::const_iterator i2 = endToWeight.begin(); i2 != endToWeight.end(); ++i2) {
        class node contrEnd = i2->first;
        class edge contrEdge = createEdge(contrStart, contrEnd, endToWeight[contrEnd]);
        contrEdges.push_back(contrEdge);
      }
    }

    // cluster contracted graph
    std::map<node, int> contrNodeToCluster 
      = cluster(contrNodes, contrEdges, atedges, atpairs);

    // decontract clustering
    std::map<node, int> nodeToCluster;
    for (std::map<node, node>::const_iterator i = nodeToContr.begin(); i != nodeToContr.end(); ++i) {
      nodeToCluster.insert(std::pair<node, int>(i->first, contrNodeToCluster[nodeToContr[i->first]]));
    }

    // refine decontracted clustering
    std::map< node, std::list<edge> > nodeToEdge;

    for (std::list<node>::const_iterator i = nodes.begin(); i != nodes.end(); ++i) {
      nodeToEdge.insert(std::pair<node, std::list<edge> >(*i, std::list<edge>()));
    }
    for (std::list<edge>::const_iterator i = edges.begin(); i != edges.end(); ++i) {
      nodeToEdge[i->src].push_back(*i);
    }

    refine(nodeToCluster, nodeToEdge, atedges, atpairs);

    return nodeToCluster;
}

std::map<node, int>
NewmanGirvan::execute(std::list<node>& nodes, std::list<edge>& edges, bool ignoreLoops) {

  // compute atedgeCnt and atpairCnt
  double atedgeCnt = 0.0; 
  for (std::list<edge>::const_iterator i = edges.begin(); i != edges.end(); ++i) {
    if (!ignoreLoops || !(i->src == i->dst)) { 
      atedgeCnt += i->weight;
    }
  }

  double atpairCnt = 0.0; 
  for (std::list<node>::const_iterator i = nodes.begin(); i != nodes.end(); ++i) {
    atpairCnt += i->weight;
  }
  atpairCnt *= atpairCnt;
  if (ignoreLoops) { 
    for (std::list<node>::const_iterator i = nodes.begin(); i != nodes.end(); ++i) {
      atpairCnt -= i->weight * i->weight;
    }
  }
        
  // compute clustering
  return cluster(nodes, edges, atedgeCnt, atpairCnt);
}



MODULE = Graph::NewmanGirvan          PACKAGE = Graph::NewmanGirvan

NewmanGirvan *
NewmanGirvan::new()

void
NewmanGirvan::add_edge(const char* src, const char* dst, double weight)

void
NewmanGirvan::set_vertex_weight(const char* vertex, double weight)

void
NewmanGirvan::compute()
  PREINIT:
  PPCODE:
    std::map<std::string, int> result = THIS->run();
    for (std::map<std::string, int>::const_iterator i = result.begin(); i != result.end(); ++i) {
      mXPUSHs(newSVpvn(i->first.c_str(), i->first.size()));
      mXPUSHs(newSVnv(i->second));
    }

void
NewmanGirvan::DESTROY()
