#include "../shapereader.h"
#include "tap.h"

int tests_planned = 0;
int tests_run = 0;
int tests_failed = 0;

shp_box_t box = {-1.0, -1.0, 1.0, 1.0};

static int
test_is_in_box(void)
{
    shp_point_t point = {0.0, 0.0};
    return shp_box_point_in_box(&box, &point) == 1;
}

static int
test_is_left_of_box(void)
{
    shp_point_t point = {-1.0001, 0.0};
    return shp_box_point_in_box(&box, &point) == 0;
}

static int
test_is_right_of_box(void)
{
    shp_point_t point = {1.0001, 0.0};
    return shp_box_point_in_box(&box, &point) == 0;
}

static int
test_is_below_box(void)
{
    shp_point_t point = {0.0, -1.0001};
    return shp_box_point_in_box(&box, &point) == 0;
}

static int
test_is_above_box(void)
{
    shp_point_t point = {0.0, 1.0001};
    return shp_box_point_in_box(&box, &point) == 0;
}

static int
test_is_on_left_boundary(void)
{
    shp_point_t point = {-1.0, 0.0};
    return shp_box_point_in_box(&box, &point) == -1;
}

static int
test_is_on_right_boundary(void)
{
    shp_point_t point = {1.0, 0.0};
    return shp_box_point_in_box(&box, &point) == -1;
}

static int
test_is_on_bottom_boundary(void)
{
    shp_point_t point = {0.0, -1.0};
    return shp_box_point_in_box(&box, &point) == -1;
}

static int
test_is_on_top_boundary(void)
{
    shp_point_t point = {0.0, 1.0};
    return shp_box_point_in_box(&box, &point) == -1;
}

int
main(int argc, char *argv[])
{
    plan(9);
    ok(test_is_in_box, "point is in box");
    ok(test_is_left_of_box, "point is left of box");
    ok(test_is_right_of_box, "point is right of box");
    ok(test_is_below_box, "point is below box");
    ok(test_is_above_box, "point is above box");
    ok(test_is_on_left_boundary, "point is on left boundary");
    ok(test_is_on_right_boundary, "point is on right boundary");
    ok(test_is_on_bottom_boundary, "point is on bottom boundary");
    ok(test_is_on_top_boundary, "point is on top boundary");
    done_testing();
}
