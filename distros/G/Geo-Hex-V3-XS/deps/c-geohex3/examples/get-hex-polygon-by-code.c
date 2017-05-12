#include "geohex3.h"
#include <stdio.h>

int main (int argc, char *argv[]) {
  for (int i = 1; i < argc; i++) {
    printf("/********* geohex:%s **********/\n", argv[i]);
    const geohex_verify_result_t result = geohex_verify_code(argv[i]);
    switch (result) {
      case GEOHEX3_VERIFY_RESULT_SUCCESS:
        {
          const geohex_t geohex = geohex_get_zone_by_code(argv[i]);
          const geohex_polygon_t polygon = geohex_get_hex_polygon(&geohex);
          printf("top.left.lat     = %Lf\n", polygon.top.left.lat);
          printf("top.left.lng     = %Lf\n", polygon.top.left.lng);
          printf("top.right.lat    = %Lf\n", polygon.top.right.lat);
          printf("top.right.lng    = %Lf\n", polygon.top.right.lng);
          printf("middle.left.lat  = %Lf\n", polygon.middle.left.lat);
          printf("middle.left.lng  = %Lf\n", polygon.middle.left.lng);
          printf("middle.right.lat = %Lf\n", polygon.middle.right.lat);
          printf("middle.right.lng = %Lf\n", polygon.middle.right.lng);
          printf("bottom.left.lat  = %Lf\n", polygon.bottom.left.lat);
          printf("bottom.left.lng  = %Lf\n", polygon.bottom.left.lng);
          printf("bottom.right.lat = %Lf\n", polygon.bottom.right.lat);
          printf("bottom.right.lng = %Lf\n", polygon.bottom.right.lng);
        }
        break;
      case GEOHEX3_VERIFY_RESULT_INVALID_CODE:
        printf("code:%s is invalid.\n", argv[i]);
        break;
      case GEOHEX3_VERIFY_RESULT_INVALID_LEVEL:
        printf("code:%s is invalid level. MAX_LEVEL:%d\n", argv[i], GEOHEX3_MAX_LEVEL);
        break;
    }
  }
}
