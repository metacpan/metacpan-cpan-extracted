typedef struct {
    int x;
    int y;
    int width;
    int height;
} IntRectangle;

static int ColorEqual(Color a, Color b) {
    return a.r == b.r && a.g == b.g && a.b == b.b && a.a == b.a;
}
typedef IntRectangle ImageSet_t(Color*, IntRectangle, Color, unsigned, unsigned);

static IntRectangle
TransposedImageSet(Color *dst, IntRectangle dst_rect, Color color, unsigned width, unsigned height)
{ /* FIXME height/width */
    IntRectangle ret = dst_rect;
    if (width > dst_rect.width-dst_rect.y || height > dst_rect.height-dst_rect.x)
        return dst_rect;

    if (!ColorEqual(color, BLANK)) {
        unsigned y, x;
        for(y = 0; y < height; y++) {
            for(x = 0; x < width; x++) {
                Color *pixel = &dst[(x+dst_rect.x)*dst_rect.width + (dst_rect.y+y)];
                *pixel = color;
            }
        }
    }

    ret.x += width;
    if (ret.x >= ret.width) {
        ret.x -= ret.width;
        ret.y += height;
    }
    if (ret.y >= ret.height) {
        ret.y -= ret.height;
    }

    return ret;
}

static IntRectangle
ImageSet(Color *dst, IntRectangle dst_rect, Color color, unsigned width, unsigned height)
{ /* FIXME height/width */
    IntRectangle ret = dst_rect;
    if (width > dst_rect.width-dst_rect.x || height > dst_rect.height-dst_rect.y)
        return dst_rect;

    if (!ColorEqual(color, BLANK)) {
        unsigned y, x;
        for(y = 0; y < height; y++) {
            for(x = 0; x < width; x++) {
                Color *pixel = &dst[(y+dst_rect.y)*dst_rect.width + (dst_rect.x+x)];
                *pixel = color;
            }
        }
    }

    ret.x += width;
    if (ret.x >= ret.width) {
        ret.x -= ret.width;
        ret.y += height;
    }
    if (ret.y >= ret.height) {
        ret.y -= ret.height;
    }

    return ret;
}




