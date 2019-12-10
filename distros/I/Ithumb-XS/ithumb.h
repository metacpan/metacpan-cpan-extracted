enum IthumErrors {
    ITHUMB_REQUESTED_WIDTH_ERROR  = 101,
    ITHUMB_REQUESTED_HEIGHT_ERROR = 102,
    ITHUMB_REQUESTED_SRC_ERROR    = 103,
    ITHUMB_REQUESTED_DST_ERROR    = 104,
    ITHUMB_SCALE_FAILED_ERROR     = 105,
    ITHUMB_CROP_FAILED_ERROR      = 106
};

typedef struct img_t {
    int w;
    int h;
    char *src;
    char *dst;
} Img;

typedef struct err_t {
    unsigned short int code;
    char *msg;
} IErr;

int resize_and_crop(Img *image);

IErr get_error(int imlib_error_code);
