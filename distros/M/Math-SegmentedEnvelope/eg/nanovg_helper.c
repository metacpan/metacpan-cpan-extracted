/*
 * NanoVG C helper for Perl FFI::Platypus
 * Wraps NanoVG + OpenGL context for 2D vector rendering
 *
 * Build:
 *   cc -shared -fPIC -O2 -o libnanovg_helper.so nanovg_helper.c \
 *      -lnanovg -lGL -lglut -I/usr/include
 */
#define GL_GLEXT_PROTOTYPES
#include <GL/gl.h>
#include <GL/glext.h>
#include <GL/glut.h>

#define NANOVG_GL2_IMPLEMENTATION
#include <nanovg.h>
#include <nanovg_gl.h>
#include <stdlib.h>

static NVGcontext *vg = NULL;
static int win_w = 800, win_h = 450;

/* Envelope data passed from Perl */
#define MAX_CURVES 8
#define MAX_SAMPLES 2048

static struct {
    float vals[MAX_SAMPLES];
    int n;
    unsigned char r, g, b;
    int active;
} curves[MAX_CURVES];
static int num_curves = 0;
static float playhead = 0;
static float playhead_val = 0;
static float pad = 40;

/* Callbacks */
static void (*perl_tick_cb)(void) = NULL;

void nvg_init(int w, int h) {
    int argc = 1;
    char *argv[] = {"nanovg", NULL};
    win_w = w; win_h = h;
    glutInit(&argc, argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_STENCIL | GLUT_MULTISAMPLE);
    /* GL2 compatibility profile (default) */
    glutInitWindowSize(w, h);
    glutCreateWindow("Envelope Viewer (NanoVG)");

    /* No GLEW needed for GL2 */
    fprintf(stderr, "nanovg: GL=%s  GLSL=%s\n",
        glGetString(GL_VERSION), glGetString(GL_SHADING_LANGUAGE_VERSION));

    vg = nvgCreateGL2(NVG_ANTIALIAS | NVG_STENCIL_STROKES);
    if (!vg) {
        fprintf(stderr, "nanovg: nvgCreateGL2 FAILED (glError=%d)\n", glGetError());
    } else {
        fprintf(stderr, "nanovg: vg=%p OK\n", (void*)vg);
    }
}

void nvg_set_curves(int n) { num_curves = n < MAX_CURVES ? n : MAX_CURVES; }

void nvg_set_curve_data(int idx, float *data, int n,
                        unsigned char r, unsigned char g, unsigned char b, int active) {
    if (idx >= MAX_CURVES) return;
    int m = n < MAX_SAMPLES ? n : MAX_SAMPLES;
    for (int i = 0; i < m; i++) curves[idx].vals[i] = data[i];
    curves[idx].n = m;
    curves[idx].r = r;
    curves[idx].g = g;
    curves[idx].b = b;
    curves[idx].active = active;
}

void nvg_set_playhead(float ph, float val) {
    playhead = ph;
    playhead_val = val;
}

static void render(void) {
    float pw = win_w - 2 * pad;
    float ph = win_h - 2 * pad;

    glViewport(0, 0, win_w, win_h);
    glClearColor(0.08f, 0.08f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    if (!vg) { fprintf(stderr, "nanovg: vg is NULL!\n"); return; }

    nvgBeginFrame(vg, win_w, win_h, 1.0f);

    /* Grid */
    nvgStrokeColor(vg, nvgRGBA(60, 60, 70, 40));
    nvgStrokeWidth(vg, 0.5f);
    for (int i = 0; i <= 10; i++) {
        float x = pad + i / 10.0f * pw;
        float y = pad + i / 10.0f * ph;
        nvgBeginPath(vg); nvgMoveTo(vg, x, pad); nvgLineTo(vg, x, pad + ph); nvgStroke(vg);
        nvgBeginPath(vg); nvgMoveTo(vg, pad, y); nvgLineTo(vg, pad + pw, y); nvgStroke(vg);
    }

    /* Envelopes */
    for (int ci = 0; ci < num_curves; ci++) {
        int n = curves[ci].n;
        if (n < 2) continue;
        int act = curves[ci].active;

        /* Fill */
        nvgBeginPath(vg);
        nvgMoveTo(vg, pad, pad + ph);
        for (int i = 0; i < n; i++) {
            float x = pad + (float)i / (n - 1) * pw;
            float y = pad + (1.0f - curves[ci].vals[i]) * ph;
            nvgLineTo(vg, x, y);
        }
        nvgLineTo(vg, pad + pw, pad + ph);
        nvgClosePath(vg);
        nvgFillColor(vg, nvgRGBA(curves[ci].r, curves[ci].g, curves[ci].b, act ? 25 : 8));
        nvgFill(vg);

        /* Stroke */
        nvgBeginPath(vg);
        for (int i = 0; i < n; i++) {
            float x = pad + (float)i / (n - 1) * pw;
            float y = pad + (1.0f - curves[ci].vals[i]) * ph;
            if (i == 0) nvgMoveTo(vg, x, y); else nvgLineTo(vg, x, y);
        }
        nvgStrokeColor(vg, nvgRGBA(curves[ci].r, curves[ci].g, curves[ci].b, act ? 230 : 60));
        nvgStrokeWidth(vg, act ? 2.5f : 1.5f);
        nvgStroke(vg);
    }

    /* Playhead */
    float px = pad + playhead * pw;
    nvgStrokeColor(vg, nvgRGBA(255, 255, 100, 180));
    nvgStrokeWidth(vg, 1.5f);
    nvgBeginPath(vg); nvgMoveTo(vg, px, pad); nvgLineTo(vg, px, pad + ph); nvgStroke(vg);

    /* Dot */
    float py = pad + (1.0f - playhead_val) * ph;
    nvgBeginPath(vg);
    nvgCircle(vg, px, py, 5.0f);
    nvgFillColor(vg, nvgRGBA(255, 255, 80, 255));
    nvgFill(vg);

    /* Legend */
    float ly = pad + 8;
    for (int ci = 0; ci < num_curves; ci++) {
        nvgBeginPath(vg);
        nvgRect(vg, pad + 8, ly, 12, 12);
        nvgFillColor(vg, nvgRGBA(curves[ci].r, curves[ci].g, curves[ci].b,
                                  curves[ci].active ? 255 : 120));
        nvgFill(vg);
        ly += 18;
    }

    nvgEndFrame(vg);
    glutSwapBuffers();
}

static void idle(void) {
    if (perl_tick_cb) perl_tick_cb();
    glutPostRedisplay();
}

void nvg_set_tick_callback(void (*cb)(void)) { perl_tick_cb = cb; }
void nvg_main_loop(void) {
    glutDisplayFunc(render);
    glutIdleFunc(idle);
    glutMainLoop();
}
void nvg_cleanup(void) { if (vg) nvgDeleteGL2(vg); }
