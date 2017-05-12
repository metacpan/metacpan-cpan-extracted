/* BmpIoLib.h */
/* http://www.syuhitu.org/other/bmp/bmp.html */

/////////////////////////////////////////////////////////////////
// BmpIO.h
// ビットマップファイルを入力する関数を宣言
/////////////////////////////////////////////////////////////////

#if !defined( BMPIO_H_INCLUDED_ )
#define BMPIO_H_INCLUDED_

#ifdef __cplusplus
extern "C" {
#endif

// 色を保持する構造体
typedef struct tagInternalColor
{
	unsigned char r;
	unsigned char g;
	unsigned char b;
} ICOLOR;

// 画像データを保持する構造体
typedef struct tagInternalBMP
{
	int width;
	int height;
	int BitPerPix;	// １ピクセルあたりのビット数
	ICOLOR *pColor;	// カラーテーブルもしくはピクセルのデータ
	unsigned char *pPix;	// ピクセルのデータ
} IBMP;

// 共通のタスク
IBMP* BmpIO_CreateBitmap( int width, int height, int BitPerPixcel );
IBMP* BmpIO_Load( FILE *infile );
int BmpIO_Save( FILE *outfile, const IBMP *pBmp );
void BmpIO_DeleteBitmap( IBMP *pBmp );
int BmpIO_GetWidth( const IBMP *pBmp );
int BmpIO_GetHeight( const IBMP *pBmp );
int BmpIO_GetBitPerPixcel( const IBMP *pBmp );
unsigned char BmpIO_GetR( int x, int y, const IBMP *pBmp );
unsigned char BmpIO_GetG( int x, int y, const IBMP *pBmp );
unsigned char BmpIO_GetB( int x, int y, const IBMP *pBmp );

// 24bitビットマップ用
void BmpIO_SetR( int x, int y, IBMP *pBmp, unsigned char v );
void BmpIO_SetG( int x, int y, IBMP *pBmp, unsigned char v );
void BmpIO_SetB( int x, int y, IBMP *pBmp, unsigned char v );

// 1,4,8bitビットマップ用
unsigned char BmpIO_GetColorTableR( int idx, const IBMP *pBmp );
unsigned char BmpIO_GetColorTableG( int idx, const IBMP *pBmp );
unsigned char BmpIO_GetColorTableB( int idx, const IBMP *pBmp );
void BmpIO_SetColorTableR( int idx, const IBMP *pBmp, unsigned char v );
void BmpIO_SetColorTableG( int idx, const IBMP *pBmp, unsigned char v );
void BmpIO_SetColorTableB( int idx, const IBMP *pBmp, unsigned char v );
unsigned char BmpIO_GetPixcel( int x, int y, const IBMP *pBmp );
void BmpIO_SetPixcel( int x, int y, const IBMP *pBmp, unsigned char v );
int BmpIO_TranseTo24BitColor( IBMP *pBmp );

#ifdef __cplusplus
}
#endif


#endif // BMPIO_H_INCLUDED_