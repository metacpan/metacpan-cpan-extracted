#include "hexgrid.h"
#include <stdlib.h>
#include <math.h>

HexCube hex_oddr_to_cube(HexOddr coord) {
    int col = coord.col;
    int row = coord.row;
    int q = col - ((row - (row & 1)) >> 1);
    int r = row;
    int s = -q - r;
    HexCube c = { q, r, s };
    return c;
}

HexOddr hex_cube_to_oddr(HexCube cube) {
    int q = cube.q;
    int r = cube.r;
    int col = q + ((r - (r & 1)) >> 1);
    int row = r;
    HexOddr o = { col, row };
    return o;
}

static inline int int_abs(int x) {
    return x < 0 ? -x : x;
}

static inline int int_max(int a, int b) {
    return a > b ? a : b;
}

int hex_distance(HexOddr a, HexOddr b) {
    HexCube ca = hex_oddr_to_cube(a);
    HexCube cb = hex_oddr_to_cube(b);
    return int_max(int_abs(ca.q - cb.q), int_max(int_abs(ca.r - cb.r), int_abs(ca.s - cb.s)));
}

bool hex_is_collinear(HexOddr a, HexOddr b) {
    if (a.col == b.col && a.row == b.row) return false;
    HexCube ca = hex_oddr_to_cube(a);
    HexCube cb = hex_oddr_to_cube(b);
    return ca.q == cb.q || ca.r == cb.r || ca.s == cb.s;
}

HexOddr hex_neighbor(HexOddr coord, int dir_index) {
    int c = coord.col;
    int r = coord.row;
    int parity = r & 1;
    dir_index = (dir_index % 6 + 6) % 6;

    int dc = 0;
    int dr = 0;

    switch (dir_index) {
        case 0: dc = +1; dr = 0; break;
        case 1: dc = parity == 0 ? 0 : +1; dr = -1; break;
        case 2: dc = parity == 0 ? -1 : 0; dr = -1; break;
        case 3: dc = -1; dr = 0; break;
        case 4: dc = parity == 0 ? -1 : 0; dr = +1; break;
        case 5: dc = parity == 0 ? 0 : +1; dr = +1; break;
    }

    HexOddr res = { c + dc, r + dr };
    return res;
}

void hex_neighbors(HexOddr coord, HexOddr out_neighbors[6]) {
    for (int i = 0; i < 6; i++) {
        out_neighbors[i] = hex_neighbor(coord, i);
    }
}

int hex_collinear_ray(HexOddr from, HexOddr to, HexOddr* out_ray, int max_length) {
    if (!hex_is_collinear(from, to) || max_length <= 0) {
        return 0;
    }

    HexCube c_from = hex_oddr_to_cube(from);
    HexCube c_to   = hex_oddr_to_cube(to);
    int dist = hex_distance(from, to);
    if (dist == 0) return 0;

    double dq = (double)(c_to.q - c_from.q) / dist;
    double dr = (double)(c_to.r - c_from.r) / dist;
    double ds = (double)(c_to.s - c_from.s) / dist;

    int count = dist < max_length ? dist : max_length;

    for (int step = 1; step <= count; step++) {
        int q = (int)round(c_from.q + dq * step);
        int r = (int)round(c_from.r + dr * step);
        int s = (int)round(c_from.s + ds * step);
        HexCube step_cube = { q, r, s };
        out_ray[step - 1] = hex_cube_to_oddr(step_cube);
    }

    return count;
}
