#include <stddef.h>
#include <stdint.h>

#define IO    ((volatile uint32_t*)0x04000000)
#define VRAM  ((volatile uint16_t (*) [240])0x06000000)
#define RGB(r,g,b) ((r << 10) | (g << 5) | (b << 0))
#define RED   RGB(0x1f, 0, 0)
#define GREEN RGB(0, 0x1f, 0)
#define BLUE  RGB(0, 0, 0x1f)

int main(void)
{
    *IO = 0x0403;

    for (unsigned i = 0; i < 14; i++) {
        for (unsigned j = 0; j < 14; j++) {
            VRAM[j+60][i+100] = RED;
            VRAM[j+60][i+116] = GREEN;
            VRAM[j+76][i+100] = BLUE;
            VRAM[j+76][i+116] = GREEN | BLUE;
        }
    }

    for (;;)
        ;

    return 0;
}
