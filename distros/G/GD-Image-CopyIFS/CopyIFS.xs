#include "libIFS.h"

typedef gdImagePtr	GD__Image;

MODULE = GD::Image::CopyIFS     PACKAGE = GD::Image     PREFIX=gd

void
gdcopyIFS(destination,source,dstX,dstY,srcX,srcY,destW,destH,srcW,srcH,min=0.99999999,max=9)
	GD::Image	destination
	GD::Image	source
	int		dstX
	int		dstY
	int		srcX
	int		srcY
	int		destW
	int		destH
	int		srcW
	int		srcH
        double          min
        double          max
        PROTOTYPE: $$$$$$$$$$$$
	CODE:
	{
        gdImageCopyIFS(destination,source,dstX,dstY,srcX,srcY,destW,destH,srcW,srcH,min,max);
	}

