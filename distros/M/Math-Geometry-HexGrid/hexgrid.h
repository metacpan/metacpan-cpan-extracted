#ifndef HEXGRID_H
#define HEXGRID_H

#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int col;
    int row;
} HexOddr;

typedef struct {
    int q;
    int r;
    int s;
} HexCube;

HexCube hex_oddr_to_cube(HexOddr coord);
HexOddr hex_cube_to_oddr(HexCube cube);

int hex_distance(HexOddr a, HexOddr b);
bool hex_is_collinear(HexOddr a, HexOddr b);

HexOddr hex_neighbor(HexOddr coord, int dir_index);
void hex_neighbors(HexOddr coord, HexOddr out_neighbors[6]);

int hex_collinear_ray(HexOddr from, HexOddr to, HexOddr* out_ray, int max_length);

#ifdef __cplusplus
}
#endif

#endif /* HEXGRID_H */
