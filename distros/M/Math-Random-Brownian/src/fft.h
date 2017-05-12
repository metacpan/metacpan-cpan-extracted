typedef struct _complex
        {
        float re;
        float im;
        } complex;

int
fft(int lx, complex *cx, float signi, float sc);
