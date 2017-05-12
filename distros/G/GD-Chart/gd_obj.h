#ifndef GD_OBJ
#define GD_OBJ

#include "gdc.h"

typedef enum { CHART, PIE } CHART_TYPE;

typedef struct {
	int w,h;
	int s,p;
	char flags;
	unsigned long *cols;
	char *title;
	char **labels;
	float *data;
	float *vol;
	int labels_num;
	unsigned long plotcolour, linecolour;
	unsigned short angle_3d, depth_3d;
	enum GDC_font_size title_size, label_size;
	FILE *output;
	union {
		GDC_CHART_T chart;
		GDCPIE_TYPE pie;
	} img;
	CHART_TYPE type;
	unsigned long bgcolour;
	GDC_image_type_t img_type;
	GDC_ANNOTATION_T note;
	GDC_SCATTER_T scatter;
} gdchart;

#define CLOSE_FD	0x01

typedef struct {
        GDC_ANNOTATION_T *n;
} note;

typedef struct {
	GDC_SCATTER_T *s;
	int num;
	int set;
} scatter;

#endif
