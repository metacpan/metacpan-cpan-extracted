
#include <stdlib.h>
#include <stdio.h>
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "bheap.h"

typedef struct mapTile {
    short G;
    short H;
    int    parent;
    char   visited;
} mapTile;

typedef struct mapPath {
    short x;
    short y;
    struct mapPath *next;
} mapPath;

typedef struct mapInfo {
    unsigned short width;
    unsigned short height;
    char *hMap;
    unsigned char *rMap;
    unsigned char R;
} mapInfo;

int calcH(int x1,int y1,int x2,int y2)
{
    int x,y;
    x = (x1 > x2) ? x1-x2 : x2-x1;
    y = (y1 > y2) ? y1-y2 : y2-y1;
    return (x > y) ? x : y;
}

mapPath *newPathNode(int x, int y, mapPath *next)
{
    mapPath *node;

    node       = (mapPath *)calloc(1,sizeof(mapPath));
    node->x    = x;
    node->y    = y;
    node->next = next;

    return node;
}

void addPoint(AV *path, I32 x, I32 y)
{
    AV *point;

    point = newAV();
    av_push(point, newSVnv(x));
    av_push(point, newSVnv(y));
    av_unshift(path, 1);
    av_store(path, 0, newRV_inc((SV*)point));
    //fprintf(stderr, "Node: %d,%d\n",x,y);
}

// Recursively flood fill a region
// Yes - is bad, how do I *efficiently*
// flood fill a height map ?
// All location with height == 0 have
// their region set 1
int floodFill(mapInfo *map, unsigned short x, unsigned short y)
{
    int i,j;
    int crntH;

    int ret = 0;

    crntH = map->hMap[y*map->width+x];
    for(i=x-1;i<=x+1;i++) {
        for(j=y-1;j<=y+1;j++) {
            //fprintf(stderr, "  %d,%d\n",i,j);
            if (i>=0 && j>=0 && i<map->width && j<map->height) {
                unsigned char r = map->rMap[j*map->width+i];
                int h = map->hMap[j*map->width+i];
                //fprintf(stderr, "    onMap\n");
                if (h<=crntH+2 && h>=crntH-2 && r==0) {
                    if (h != 0) {
                        map->rMap[j*map->width+i] = map->R;
                        floodFill(map, (unsigned short)i,(unsigned short)j);
                        ret = 1;
                    }
                    else {
                        map->rMap[j*map->width+i] = 1;
                    }
                }
            }
        }
    }
    return ret;
}

MODULE = Games::EternalLands::MapHelper     PACKAGE = Games::EternalLands::MapHelper

int
getZ(heightMap,width,height,x,y)
        char * heightMap
        int width
        int height
        int x
        int y
    CODE:
        int h;
        if (x < 0 || y < 0 || x >= width || y >= height)
            h = 0;
        else
            RETVAL = (int)heightMap[y*width+x];
    OUTPUT:
        RETVAL

SV *
findPathFromTo(heightMap,width,height,fromX,fromY,toX,toY,delta)
        char * heightMap
        int width
        int height
        int fromX
        int fromY
        int toX
        int toY
        int delta
    CODE:
        bheap_t *openTiles;
        int crntTile, fromTile;
        int crntHeight,surrHeight;
        int nTiles;
        mapTile *tiles;
        int found = -1;
        AV *path;
        path = (AV *)sv_2mortal((SV *)newAV());

        nTiles    = width*height;
        tiles     = (mapTile *)calloc(nTiles, sizeof(mapTile));
        openTiles = bh_alloc(nTiles);
        fromTile  = fromY*width+fromX;

        //fprintf(stderr,"findPath(hBuf,%d,%d,%d,%d,%d,%d,%d\n",width,height,fromX,fromY,toX,toY,delta);

        tiles[fromTile].G       = 0;
        tiles[fromTile].H       = calcH(fromX,fromY,toX,toY);
        tiles[fromTile].parent  = -1;
        tiles[fromTile].visited = 1;
        bh_insert(openTiles, fromTile, 0);

        if (calcH(fromX,fromY,toX,toY) <= delta) {
            //fprintf(stderr,"No path needed: from-to <= %d\n",delta);
            found = fromTile;
        }
        while((openTiles->n > 0) && (found==-1)) {
            int x,y;
            int crntX,crntY,crntG;
            int crntTile = bh_min(openTiles);

            bh_delete(openTiles, crntTile);

            crntX      = crntTile % width;
            crntY      = crntTile / width;
            crntG      = tiles[crntTile].G;
            crntHeight = heightMap[crntTile];

            //fprintf(stderr,"I am at (%d,%d) G=%d H=%d Z=%d\n",crntX,crntY,crntG,tiles[crntTile].H,crntHeight);
            for(x=crntX-1; x<=crntX+1; x++) {
                for(y=crntY-1; y<=crntY+1; y++) {
                    int surrTile,surrG;
                    //fprintf(stderr, "  Considering (%d,%d)\n",x,y);
                    if ((x!=crntX || y!=crntY) &&  x >= 0 && y >= 0 && x < width && y < height) {
                        surrTile   = y*width+x;
                        surrHeight = heightMap[surrTile];
                        if (surrHeight!=0 && (surrHeight >=crntHeight-2) && (surrHeight <= crntHeight+2)) {
                            surrG = crntG+1;
                            if (tiles[surrTile].visited) {
                                //fprintf(stderr,"    Node has been visited before\n");
                                if (surrG < tiles[surrTile].G) {
                                    //fprintf(stderr,"      Better path %d < %d\n",surrG,tiles[surrTile].G);
                                    tiles[surrTile].G       = surrG;
                                    tiles[surrTile].parent  = crntTile;
                                    bh_decrease_key(openTiles, surrTile, surrG+tiles[surrTile].H);
                                }
                            }
                            else {
                                //fprintf(stderr,"    New node\n");
                                tiles[surrTile].G       = surrG;
                                tiles[surrTile].H       = calcH(x,y,toX,toY);
                                tiles[surrTile].parent  = crntTile;
                                tiles[surrTile].visited = 1;
                                if (tiles[surrTile].H <= delta) {
                                    //fprintf(stderr,"    found: %d < %d\n",tiles[surrTile].H,delta);
                                    found = surrTile;
                                }
                                else {
                                    //fprintf(stderr,"    queueing\n");
                                    bh_insert(openTiles, surrTile, surrG+tiles[surrTile].H);
                                }
                            }
                        }
                        //else fprintf(stderr,"Skipping - height diff > 2\n");
                    }
                    //else fprintf(stderr,"Skipping - not on the map\n");
                }
            }
        }
        if (found != -1) {
            int parent;
            addPoint(path, found%width, found/width);
            parent = tiles[found].parent;
            while(parent != -1) {
                addPoint(path, parent%width, parent/width);
                parent = tiles[parent].parent;
            }
            RETVAL = newRV_inc((SV *)path);
        }
        else {
            RETVAL = &PL_sv_undef;
        }
        free(tiles);
        bh_free(openTiles);
    OUTPUT:
        RETVAL

int
getRegion(rMap,width,height,x,y)
        char *rMap
        int width
        int height
        int x
        int y
    CODE:
        unsigned short *regions = (unsigned short *)rMap;

        if (x<0 || y<0 || x>=width || y>=height)
            RETVAL = 0;
        else
            RETVAL = (int)regions[y*width+x];
    OUTPUT:
        RETVAL

void
findRegions(hMap,rMap,width,height)
        char *hMap
        char *rMap
        unsigned short width
        unsigned short height
    CODE:
        unsigned short x,y;
        mapInfo map;

        map.width  = width;
        map.height = height;
        map.hMap   = hMap;
        map.rMap   = (unsigned char *)rMap;
        map.R      = 2; // R=1 is reserved for unreachable locations

        //fprintf(stderr,"Initialiazing rMap to 0\n");
        memset(rMap,0,width*height);
        for(x=0;x<width;x++) {
            for(y=0;y<height;y++) {
                if (map.rMap[y*width+x] == 0) {
                    //fprintf(stderr, "Flood filling from %d,%d with %d\n",x,y,map.R);
                    if (floodFill(&map,x,y))
                        map.R++;
                }
            }
        }

