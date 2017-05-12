%module "Games::DungeonMaker"
%include "std_pair.i"
%include "std_vector.i"
%{
#include "DungeonMaker.h"
%}

%template (pair_ii) std::pair<int,int>;
/*
%import "/usr/local/include/DungeonMaker.h";
%template (pair_cd) std::pair<CrawlerData, CrawlerData>;
%template (vector_ic) std::vector<IntCoordinate>;
%template (vector_dir) std::vector<Direction>;
%template (vector_rf) std::vector<RectFill>;
%template (vector_i) std::vector<int>;
%template (vector_cd) std::vector<CrawlerData>;
%template (vector_td) std::vector<TunnelerData>;
%template (vector_pair_cd) std::vector<std::pair<CrawlerData , CrawlerData> >;
%template (vector_ti) std::vector<TripleInt>;
%template (vector_square) std::vector<SquareData>;
%template (vector_room) std::vector<Room>;
%template (vector_flags) std::vector<FlagsDir>;
*/

%include "/usr/local/include/DungeonMaker.h"

