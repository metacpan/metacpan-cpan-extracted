/* 
 * Copyright(C) 1998 Tuomas J. Lukka
 * NO WARRANTY. See the license (the file COPYING in the VRML::Browser
 * distribution) for details.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define XRES 96
#define YRES 96
#define PPI 72
#define PIXELSIZE 1
#define POINTSIZE 50

/* XXX Find out why *1.7... */
#define OUT2GL(a) (size * (0.0 +(a))/(1.7*(font->ascent + font->descent)) /PPI*XRES/64.0)

#include <GL/gl.h>
#include <GL/glu.h>
#include <GL/glx.h>

#include "../OpenGL/OpenGL.m"

D_OPENGL;

#include <stdio.h>

#include <freetype.h>

/* We assume that all pre-1.1 are 1.0 */
#ifndef TT_FREETYPE_MAJOR
#define TT_FREETYPE_MAJOR 1
#define TT_FREETYPE_MINOR 0
#endif


#if TT_FREETYPE_MINOR != 0 || TT_FREETYPE_MAJOR > 1
#define N_CONTOURS(outline) ((outline).n_contours)
#define N_CONENDS(outline) ((outline).contours)
#define XCOORD(outline,i) ((outline).points[i].x)
#define YCOORD(outline,i) ((outline).points[i].y)
#define FLAG(outline,i) ((outline).flags[i])
#else
#define N_CONTOURS(outline) ((outline).contours)
#define N_CONENDS(outline) ((outline).conEnds)
#define XCOORD(outline,i) ((outline).xCoord[i])
#define YCOORD(outline,i) ((outline).yCoord[i])
#define FLAG(outline,i) ((outline).flag[i])
#endif

TT_Engine engine;

GLUtriangulatorObj *triang;

static int verbose;

static void tjl_beg(GLenum e) {
	if(verbose) printf("BEGIN %d\n",e);
	glBegin(e);
}

static void tjl_end() {
	if(verbose) printf("END\n");
	glEnd();
}

static void tjl_ver(void *p) {
	GLdouble *dp = p;
	if(verbose) printf("V: %f %f %f\n",dp[0],dp[1],dp[2]);
	glVertex3f(dp[0],dp[1],dp[2]);
}

static void tjl_err(GLenum e) {
	/* if(verbose) */ printf("ERROR %d: '%s'\n",e,gluErrorString(e));
}

typedef struct Tjl_Font {
	TT_Face face;
	TT_Face_Properties prop;
	TT_CharMap charmap;
	TT_Instance instance;
	TT_Instance_Metrics imetrics;
	float ascent,descent; /* points */
} Tjl_Font;

typedef struct Tjl_Glyph {
	TT_Glyph glyph;
	TT_Outline outline;
	TT_Glyph_Metrics metrics;
} Tjl_Glyph;

int myglyph_is = 0;
static Tjl_Glyph myglyph; /* Later, cache.. */
static Tjl_Font myfont;
static Tjl_Font *myfontp;

static Tjl_Font *get_font(char *name) {
	Tjl_Font *font = &myfont;
	int err;
	double upm;
	if(err = TT_Open_Face(engine, name, &(font->face))) 
	  die("TT 2err %d\n",err);
	if(err = TT_Get_Face_Properties(font->face, &(font->prop))) 
	  die("TT 2.5err %d\n",err);
	if(err = TT_New_Instance(font->face, &(font->instance))) 
	  die("TT 3err %d\n",err);
/*	if(err = TT_Set_Instance_PixelSizes(font->instance,PIXELSIZE,PIXELSIZE,POINTSIZE)) 
	  die("TT 3err %d\n",err);
 */
	if(err = TT_Set_Instance_PointSize(font->instance,POINTSIZE)) 
	  die("TT 3err %d\n",err);
	if(err = TT_Get_Instance_Metrics(font->instance,&(font->imetrics))) 
	  die("TT 3.5err %d\n",err);
	if(err = TT_Get_CharMap(font->face, 2, &(font->charmap)))
	  die("TT 5err %d\n",err);
	upm = font->prop.header->Units_Per_EM;
	font->ascent = (0.0 + font->prop.horizontal->Ascender * font->imetrics.y_ppem) / upm;
	font->descent = (0.0 + font->prop.horizontal->Descender * font->imetrics.y_ppem) / upm;
	return &myfont;
}

static Tjl_Glyph *get_glyph(Tjl_Font *font, char ch) {
	int gindex,err;
	Tjl_Glyph *glyph = &myglyph;
	if(!myglyph_is) {
		/* TT_Done_Glyph(glyph->glyph); */
		if(err = TT_New_Glyph(font->face, &(glyph->glyph)))
		  die("TT 4err %d\n",err);
	}
	myglyph_is = 1;

	gindex = TT_Char_Index(font->charmap, ch);
	if(err = TT_Load_Glyph(font->instance,(glyph->glyph), gindex, TTLOAD_SCALE_GLYPH))
	  die("TT 10err %d\n",err);
	if(err = TT_Get_Glyph_Outline(glyph->glyph, &(glyph->outline)))
	  die("TT 11err %d\n",err);
	if(err = TT_Get_Glyph_Metrics(glyph->glyph, &(glyph->metrics)))
	  die("TT 12err %d\n",err);

	  return glyph;
}

static double Tjl_extent(Tjl_Font *font, char *str)
{
	double cur = 0;
	int i;
	for(i=0; i<strlen(str); i++) {
		Tjl_Glyph *g = get_glyph(font, str[i]);
		cur += g->metrics.advance;
	}
	return cur;
}

/* XXX Argh... */
static GLdouble vecs[3*10000];

static void tjl_rendertext(int n,SV **p,int nl, float *length, 
		float maxext, double spacing, double size) {
	char *str;
	int i,gindex,row;
	int contour; int point;
	int err;
	float xorig = 0;
	float yorig = 0;
	float shrink = 0;
	float rshrink = 0;
	Tjl_Font *font = myfontp;
	int flag;
	GLdouble v[3];
	GLdouble *v2;
	GLdouble *vnew;
	GLdouble *vlast;
	int flaglast;
	glNormal3f(0,0,-1);
	glEnable(GL_LIGHTING);
	if(verbose) printf("Tjl TT_Render\n");
	if(maxext > 0) {
	   double maxlen = 0;
	   double l;
	   for(row = 0; row < n; row++) {
		str = SvPV(p[row],na);
		l = Tjl_extent(font, str) ;
		if(l > maxlen) {maxlen = l;}
	   }
	   if(maxlen > maxext) {shrink = maxext / OUT2GL(maxlen);}
	}
   for(row = 0; row < n; row++) {
   	double l;
   	str = SvPV(p[row],na);
        xorig = 0;
	rshrink = 0;
	if(row < nl && length[row]) {
		l = Tjl_extent(font,str);
		rshrink = length[row] / OUT2GL(l);
	}
	if(shrink) {
		glScalef(shrink,1,1);
	}
	if(rshrink) {
		glScalef(rshrink,1,1);
	}
	for(i=0; i<strlen(str); i++) {
		Tjl_Glyph *glyph = get_glyph(font,str[i]);
		int nthvec = 0;
		gluBeginPolygon(triang);
		if(verbose) printf("Contours: %d\n",glyph->outline.contours);
		for(contour = 0; contour < N_CONTOURS(glyph->outline); contour++) {
			vlast = 0;
			flaglast = 0;
			if(contour) {
				gluNextContour(triang,GLU_UNKNOWN);
			}
			if(verbose) printf("End %d: %d\n", contour, N_CONENDS(glyph->outline)[contour]);
			for(point = (contour ? N_CONENDS(glyph->outline)[contour-1]+1
					: 0); 
			    point <= N_CONENDS(glyph->outline)[contour];
			    point ++) {
			    	float x = OUT2GL(XCOORD(glyph->outline,point)+xorig);
			    	float y = (0.0 + OUT2GL(YCOORD(glyph->outline,point)) + yorig);
				flag = FLAG(glyph->outline,point);
				v[0] = x; v[1] = y; v[2] = 0;
				v2 = vecs+3*(nthvec++);
				if(nthvec >= 10000) {
					die("Too large letters");
				}
				v2[0] = v[0]; v2[1] = v[1]; v2[2] = v[2];
				if(vlast &&
				   v2[0] == vlast[0] &&
				   v2[1] == vlast[1] &&
				   v2[2] == vlast[2]) {
					continue;
				}
				if(verbose) printf("OX, OY: %f, %f, X,Y: %f,%f FLAG %d\n",XCOORD(glyph->outline,point)+0.0,
							YCOORD(glyph->outline,point)+0.0,x,y,flag);
				if(flag) {
					gluTessVertex(triang,v2,v2);
				} else {
					if(!vlast) {
						die("Can't be first off");
						if(flaglast) {
							/* Interp */
							vnew = vecs+3*(nthvec++);
							if(nthvec >= 10000) {
								die("Too large letters2");
							}
							vnew[0] = 0.5*(v2[0]+vlast[0]);
							vnew[1] = 0.5*(v2[1]+vlast[1]);
							vnew[2] = 0.5*(v2[2]+vlast[2]);
							gluTessVertex(triang,vnew,vnew);
						} else {
							/* Nothing */
						}
					}
				}
				vlast = v2;
				flaglast = flag;
			}
		}
		gluEndPolygon(triang);
		xorig += glyph->metrics.advance;
	}
	yorig -= spacing;
   }
}


MODULE=VRML::Text 	PACKAGE=VRML::Text

PROTOTYPES: ENABLE

void *
get_rendptr()
CODE:
	RETVAL = (void *)tjl_rendertext;
OUTPUT:
	RETVAL

void
open_font(name)
char *name
CODE:
	int err;
	if(err = TT_Init_FreeType(&engine))
	  die("TT 1err %d\n",err);
	/* myfontp = get_font("fonts/baklava.ttf"); */
	myfontp = get_font(name);

	triang = gluNewTess();
	/* gluTessCallback(triang, GLU_BEGIN, glBegin);
	 * gluTessCallback(triang, GLU_VERTEX, glVertex3dv);
	 * gluTessCallback(triang, GLU_END, glEnd);
	 */
	gluTessCallback(triang, GLU_BEGIN, tjl_beg);
	gluTessCallback(triang, GLU_VERTEX, tjl_ver);
	gluTessCallback(triang, GLU_END, tjl_end);
	gluTessCallback(triang, GLU_ERROR, tjl_err);

void
set_verbose(i)
	int i
CODE:
	verbose = i;

BOOT: 
	{
	I_OPENGL;
	}



