// http://www.cpantesters.org/cpan/report/bdd1ffc0-0c96-11e8-a1cf-bb670eaac09d
#include <stdbool.h>
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <raylib.h>

#include "const-c.inc"

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



MODULE = Graphics::Raylib::XS        PACKAGE = Graphics::Raylib::XS

INCLUDE: const-xs.inc

void
BeginBlendMode(mode)
    int    mode

void
BeginDrawing()

void
BeginMode2D(camera)
    Camera2D    camera

void
BeginMode3D(camera)
    Camera3D    camera

void
BeginShaderMode(shader)
    Shader    shader

void
BeginTextureMode(target)
    RenderTexture2D    target

void
BeginVrDrawing()

bool
ChangeDirectory(dir)
    char *    dir

bool
CheckCollisionBoxSphere(box, centerSphere, radiusSphere)
    BoundingBox    box
    Vector3    centerSphere
    float    radiusSphere

bool
CheckCollisionBoxes(box1, box2)
    BoundingBox    box1
    BoundingBox    box2

bool
CheckCollisionCircleRec(center, radius, rec)
    Vector2    center
    float    radius
    Rectangle    rec

bool
CheckCollisionCircles(center1, radius1, center2, radius2)
    Vector2    center1
    float    radius1
    Vector2    center2
    float    radius2

bool
CheckCollisionPointCircle(point, center, radius)
    Vector2    point
    Vector2    center
    float    radius

bool
CheckCollisionPointRec(point, rec)
    Vector2    point
    Rectangle    rec

bool
CheckCollisionPointTriangle(point, p1, p2, p3)
    Vector2    point
    Vector2    p1
    Vector2    p2
    Vector2    p3

bool
CheckCollisionRayBox(ray, box)
    Ray    ray
    BoundingBox    box

bool
CheckCollisionRaySphere(ray, spherePosition, sphereRadius)
    Ray    ray
    Vector3    spherePosition
    float    sphereRadius

bool
CheckCollisionRaySphereEx(ray, spherePosition, sphereRadius, collisionPoint)
    Ray    ray
    Vector3    spherePosition
    float    sphereRadius
    Vector3 *    collisionPoint

bool
CheckCollisionRecs(rec1, rec2)
    Rectangle    rec1
    Rectangle    rec2

bool
CheckCollisionSpheres(centerA, radiusA, centerB, radiusB)
    Vector3    centerA
    float    radiusA
    Vector3    centerB
    float    radiusB

void
ClearBackground(color)
    Color    color

void
ClearDroppedFiles()

void
CloseAudioDevice()

void
CloseAudioStream(stream)
    AudioStream    stream

void
CloseVrSimulator()

void
CloseWindow()

Vector4
ColorNormalize(color)
    Color    color

Vector3
ColorToHSV(color)
    Color    color

int
ColorToInt(color)
    Color    color

void
DisableCursor()

void
DrawBillboard(camera, texture, center, size, tint)
    Camera3D    camera
    Texture2D    texture
    Vector3    center
    float    size
    Color    tint

void
DrawBillboardRec(camera, texture, sourceRec, center, size, tint)
    Camera3D    camera
    Texture2D    texture
    Rectangle    sourceRec
    Vector3    center
    float    size
    Color    tint

void
DrawBoundingBox(box, color)
    BoundingBox    box
    Color    color

void
DrawCircle(centerX, centerY, radius, color)
    int    centerX
    int    centerY
    float    radius
    Color    color

void
DrawCircle3D(center, radius, rotationAxis, rotationAngle, color)
    Vector3    center
    float    radius
    Vector3    rotationAxis
    float    rotationAngle
    Color    color

void
DrawCircleGradient(centerX, centerY, radius, color1, color2)
    int    centerX
    int    centerY
    float    radius
    Color    color1
    Color    color2

void
DrawCircleLines(centerX, centerY, radius, color)
    int    centerX
    int    centerY
    float    radius
    Color    color

void
DrawCircleV(center, radius, color)
    Vector2    center
    float    radius
    Color    color

void
DrawCube(position, width, height, length, color)
    Vector3    position
    float    width
    float    height
    float    length
    Color    color

void
DrawCubeTexture(texture, position, width, height, length, color)
    Texture2D    texture
    Vector3    position
    float    width
    float    height
    float    length
    Color    color

void
DrawCubeV(position, size, color)
    Vector3    position
    Vector3    size
    Color    color

void
DrawCubeWires(position, width, height, length, color)
    Vector3    position
    float    width
    float    height
    float    length
    Color    color

void
DrawCylinder(position, radiusTop, radiusBottom, height, slices, color)
    Vector3    position
    float    radiusTop
    float    radiusBottom
    float    height
    int    slices
    Color    color

void
DrawCylinderWires(position, radiusTop, radiusBottom, height, slices, color)
    Vector3    position
    float    radiusTop
    float    radiusBottom
    float    height
    int    slices
    Color    color

void
DrawFPS(posX, posY)
    int    posX
    int    posY

void
DrawGizmo(position)
    Vector3    position

void
DrawGrid(slices, spacing)
    int    slices
    float    spacing

void
DrawLine(startPosX, startPosY, endPosX, endPosY, color)
    int    startPosX
    int    startPosY
    int    endPosX
    int    endPosY
    Color    color

void
DrawLine3D(startPos, endPos, color)
    Vector3    startPos
    Vector3    endPos
    Color    color

void
DrawLineBezier(startPos, endPos, thick, color)
    Vector2    startPos
    Vector2    endPos
    float    thick
    Color    color

void
DrawLineEx(startPos, endPos, thick, color)
    Vector2    startPos
    Vector2    endPos
    float    thick
    Color    color

void
DrawLineV(startPos, endPos, color)
    Vector2    startPos
    Vector2    endPos
    Color    color

void
DrawModel(model, position, scale, tint)
    Model    model
    Vector3    position
    float    scale
    Color    tint

void
DrawModelEx(model, position, rotationAxis, rotationAngle, scale, tint)
    Model    model
    Vector3    position
    Vector3    rotationAxis
    float    rotationAngle
    Vector3    scale
    Color    tint

void
DrawModelWires(model, position, scale, tint)
    Model    model
    Vector3    position
    float    scale
    Color    tint

void
DrawModelWiresEx(model, position, rotationAxis, rotationAngle, scale, tint)
    Model    model
    Vector3    position
    Vector3    rotationAxis
    float    rotationAngle
    Vector3    scale
    Color    tint

void
DrawPixel(posX, posY, color)
    int    posX
    int    posY
    Color    color

void
DrawPixelV(position, color)
    Vector2    position
    Color    color

void
DrawPlane(centerPos, size, color)
    Vector3    centerPos
    Vector2    size
    Color    color

void
DrawPoly(center, sides, radius, rotation, color)
    Vector2    center
    int    sides
    float    radius
    float    rotation
    Color    color

void
DrawPolyEx(points, numPoints, color)
    Vector2 *    points
    int    numPoints
    Color    color

void
DrawPolyExLines(points, numPoints, color)
    Vector2 *    points
    int    numPoints
    Color    color

void
DrawRay(ray, color)
    Ray    ray
    Color    color

void
DrawRectangle(posX, posY, width, height, color)
    int    posX
    int    posY
    int    width
    int    height
    Color    color

void
DrawRectangleGradientEx(rec, col1, col2, col3, col4)
    Rectangle    rec
    Color    col1
    Color    col2
    Color    col3
    Color    col4

void
DrawRectangleGradientH(posX, posY, width, height, color1, color2)
    int    posX
    int    posY
    int    width
    int    height
    Color    color1
    Color    color2

void
DrawRectangleGradientV(posX, posY, width, height, color1, color2)
    int    posX
    int    posY
    int    width
    int    height
    Color    color1
    Color    color2

void
DrawRectangleLines(posX, posY, width, height, color)
    int    posX
    int    posY
    int    width
    int    height
    Color    color

void
DrawRectangleLinesEx(rec, lineThick, color)
    Rectangle    rec
    int    lineThick
    Color    color

void
DrawRectanglePro(rec, origin, rotation, color)
    Rectangle    rec
    Vector2    origin
    float    rotation
    Color    color

void
DrawRectangleRec(rec, color)
    Rectangle    rec
    Color    color

void
DrawRectangleV(position, size, color)
    Vector2    position
    Vector2    size
    Color    color

void
DrawSphere(centerPos, radius, color)
    Vector3    centerPos
    float    radius
    Color    color

void
DrawSphereEx(centerPos, radius, rings, slices, color)
    Vector3    centerPos
    float    radius
    int    rings
    int    slices
    Color    color

void
DrawSphereWires(centerPos, radius, rings, slices, color)
    Vector3    centerPos
    float    radius
    int    rings
    int    slices
    Color    color

void
DrawText(text, posX, posY, fontSize, color)
    char *    text
    int    posX
    int    posY
    int    fontSize
    Color    color

void
DrawTextEx(font, text, position, fontSize, spacing, tint)
    Font    font
    char *    text
    Vector2    position
    float    fontSize
    float    spacing
    Color    tint

void
DrawTexture(texture, posX, posY, tint)
    Texture2D    texture
    int    posX
    int    posY
    Color    tint

void
DrawTextureEx(texture, position, rotation, scale, tint)
    Texture2D    texture
    Vector2    position
    float    rotation
    float    scale
    Color    tint

void
DrawTexturePro(texture, sourceRec, destRec, origin, rotation, tint)
    Texture2D    texture
    Rectangle    sourceRec
    Rectangle    destRec
    Vector2    origin
    float    rotation
    Color    tint

void
DrawTextureRec(texture, sourceRec, position, tint)
    Texture2D    texture
    Rectangle    sourceRec
    Vector2    position
    Color    tint

void
DrawTextureV(texture, position, tint)
    Texture2D    texture
    Vector2    position
    Color    tint

void
DrawTriangle(v1, v2, v3, color)
    Vector2    v1
    Vector2    v2
    Vector2    v3
    Color    color

void
DrawTriangleLines(v1, v2, v3, color)
    Vector2    v1
    Vector2    v2
    Vector2    v3
    Color    color

void
EnableCursor()

void
EndBlendMode()

void
EndDrawing()

void
EndMode2D()

void
EndMode3D()

void
EndShaderMode()

void
EndTextureMode()

void
EndVrDrawing()

void
ExportImage(image, fileName)
    Image    image
    char *    fileName

void
ExportMesh(mesh, fileName)
    Mesh    mesh
    char *    fileName

Color
Fade(color, alpha)
    Color    color
    float    alpha

char *
FormatText(text, ...)
    char *    text

Image
GenImageCellular(width, height, tileSize)
    int    width
    int    height
    int    tileSize

Image
GenImageChecked(width, height, checksX, checksY, col1, col2)
    int    width
    int    height
    int    checksX
    int    checksY
    Color    col1
    Color    col2

Image
GenImageColor(width, height, color)
    int    width
    int    height
    Color    color

Image
GenImageFontAtlas(chars, fontSize, charsCount, padding, packMethod)
    CharInfo *    chars
    int    fontSize
    int    charsCount
    int    padding
    int    packMethod

Image
GenImageGradientH(width, height, left, right)
    int    width
    int    height
    Color    left
    Color    right

Image
GenImageGradientRadial(width, height, density, inner, outer)
    int    width
    int    height
    float    density
    Color    inner
    Color    outer

Image
GenImageGradientV(width, height, top, bottom)
    int    width
    int    height
    Color    top
    Color    bottom

Image
GenImagePerlinNoise(width, height, offsetX, offsetY, scale)
    int    width
    int    height
    int    offsetX
    int    offsetY
    float    scale

Image
GenImageWhiteNoise(width, height, factor)
    int    width
    int    height
    float    factor

Mesh
GenMeshCube(width, height, length)
    float    width
    float    height
    float    length

Mesh
GenMeshCubicmap(cubicmap, cubeSize)
    Image    cubicmap
    Vector3    cubeSize

Mesh
GenMeshCylinder(radius, height, slices)
    float    radius
    float    height
    int    slices

Mesh
GenMeshHeightmap(heightmap, size)
    Image    heightmap
    Vector3    size

Mesh
GenMeshHemiSphere(radius, rings, slices)
    float    radius
    int    rings
    int    slices

Mesh
GenMeshKnot(radius, size, radSeg, sides)
    float    radius
    float    size
    int    radSeg
    int    sides

Mesh
GenMeshPlane(width, length, resX, resZ)
    float    width
    float    length
    int    resX
    int    resZ

Mesh
GenMeshSphere(radius, rings, slices)
    float    radius
    int    rings
    int    slices

Mesh
GenMeshTorus(radius, size, radSeg, sides)
    float    radius
    float    size
    int    radSeg
    int    sides

Texture2D
GenTextureBRDF(shader, cubemap, size)
    Shader    shader
    Texture2D    cubemap
    int    size

Texture2D
GenTextureCubemap(shader, skyHDR, size)
    Shader    shader
    Texture2D    skyHDR
    int    size

Texture2D
GenTextureIrradiance(shader, cubemap, size)
    Shader    shader
    Texture2D    cubemap
    int    size

void
GenTextureMipmaps(texture)
    Texture2D *    texture

Texture2D
GenTexturePrefilter(shader, cubemap, size)
    Shader    shader
    Texture2D    cubemap
    int    size

Matrix
GetCameraMatrix(camera)
    Camera3D    camera

RayHitInfo
GetCollisionRayGround(ray, groundHeight)
    Ray    ray
    float    groundHeight

RayHitInfo
GetCollisionRayModel(ray, model)
    Ray    ray
    Model *    model

RayHitInfo
GetCollisionRayTriangle(ray, p1, p2, p3)
    Ray    ray
    Vector3    p1
    Vector3    p2
    Vector3    p3

Rectangle
GetCollisionRec(rec1, rec2)
    Rectangle    rec1
    Rectangle    rec2

Color
GetColor(hexValue)
    int    hexValue

Font
GetFontDefault()

char *
GetDirectoryPath(fileName)
    char *    fileName

char *
GetExtension(fileName)
    char *    fileName

int
GetFPS()

char *
GetFileName(filePath)
    char *    filePath

float
GetFrameTime()

int
GetGamepadAxisCount(gamepad)
    int    gamepad

float
GetGamepadAxisMovement(gamepad, axis)
    int    gamepad
    int    axis

int
GetGamepadButtonPressed()

char *
GetGamepadName(gamepad)
    int    gamepad

int
GetGestureDetected()

float
GetGestureDragAngle()

Vector2
GetGestureDragVector()

float
GetGestureHoldDuration()

float
GetGesturePinchAngle()

Vector2
GetGesturePinchVector()

int
GetGlyphIndex(font, character)
    Font    font
    int    character

Color *
GetImageData(image)
    Image    image

Vector4 *
GetImageDataNormalized(image)
    Image    image

int
GetKeyPressed()

Matrix
GetMatrixModelview()

Vector2
GetMousePosition()

Ray
GetMouseRay(mousePosition, camera)
    Vector2    mousePosition
    Camera3D    camera

int
GetMouseWheelMove()

int
GetMouseX()

int
GetMouseY()

float
GetMusicTimeLength(music)
    Music    music

float
GetMusicTimePlayed(music)
    Music    music

int
GetPixelDataSize(width, height, arg2)
    int    width
    int    height
    int    arg2

int
GetRandomValue(min, max)
    int    min
    int    max

int
GetScreenHeight()

int
GetScreenWidth()

Shader
GetShaderDefault()

int
GetShaderLocation(shader, uniformName)
    Shader    shader
    char *    uniformName

Image
GetTextureData(texture)
    Texture2D    texture

Texture2D
GetTextureDefault()

double
GetTime()

int
GetTouchPointsCount()

Vector2
GetTouchPosition(index)
    int    index

int
GetTouchX()

int
GetTouchY()

VrDeviceInfo
GetVrDeviceInfo(vrDeviceType)
    int    vrDeviceType

float *
GetWaveData(wave)
    Wave    wave

char *
GetWorkingDirectory()

Vector2
GetWorldToScreen(position, camera)
    Vector3    position
    Camera3D    camera

void
HideCursor()

void
ImageAlphaClear(image, color, threshold)
    Image *    image
    Color    color
    float    threshold

void
ImageAlphaCrop(image, threshold)
    Image *    image
    float    threshold

void
ImageAlphaMask(image, alphaMask)
    Image *    image
    Image    alphaMask

void
ImageAlphaPremultiply(image)
    Image *    image

void
ImageColorBrightness(image, brightness)
    Image *    image
    int    brightness

void
ImageColorContrast(image, contrast)
    Image *    image
    float    contrast

void
ImageColorGrayscale(image)
    Image *    image

void
ImageColorInvert(image)
    Image *    image

void
ImageColorReplace(image, color, replace)
    Image *    image
    Color    color
    Color    replace

void
ImageColorTint(image, color)
    Image *    image
    Color    color

Image
ImageCopy(image)
    Image    image

void
ImageCrop(image, crop)
    Image *    image
    Rectangle    crop

void
ImageDither(image, rBpp, gBpp, bBpp, aBpp)
    Image *    image
    int    rBpp
    int    gBpp
    int    bBpp
    int    aBpp

void
ImageDraw(dst, src, srcRec, dstRec)
    Image *    dst
    Image    src
    Rectangle    srcRec
    Rectangle    dstRec

void
ImageDrawRectangle(dst, position, rec, color)
    Image *    dst
    Vector2    position
    Rectangle    rec
    Color    color

void
ImageDrawText(dst, position, text, fontSize, color)
    Image *    dst
    Vector2    position
    char *    text
    int    fontSize
    Color    color

void
ImageDrawTextEx(dst, position, font, text, fontSize, spacing, color)
    Image *    dst
    Vector2    position
    Font    font
    char *    text
    float    fontSize
    float    spacing
    Color    color

void
ImageFlipHorizontal(image)
    Image *    image

void
ImageFlipVertical(image)
    Image *    image

void
ImageFormat(image, newFormat)
    Image *    image
    int    newFormat

void
ImageMipmaps(image)
    Image *    image

void
ImageResize(image, newWidth, newHeight)
    Image *    image
    int    newWidth
    int    newHeight

void
ImageResizeCanvas(image, newWidth, newHeight, offsetX, offsetY, color)
    Image *    image
    int    newWidth
    int    newHeight
    int    offsetX
    int    offsetY
    Color    color

void
ImageResizeNN(image, newWidth, newHeight)
    Image *    image
    int    newWidth
    int    newHeight

void
ImageRotateCCW(image)
    Image *    image

void
ImageRotateCW(image)
    Image *    image

Image
ImageText(text, fontSize, color)
    char *    text
    int    fontSize
    Color    color

Image
ImageTextEx(font, text, fontSize, spacing, tint)
    Font    font
    char *    text
    float    fontSize
    float    spacing
    Color    tint

void
ImageToPOT(image, fillColor)
    Image *    image
    Color    fillColor

void
InitAudioDevice()

AudioStream
InitAudioStream(sampleRate, sampleSize, channels)
    unsigned int    sampleRate
    unsigned int    sampleSize
    unsigned int    channels

void
InitVrSimulator(info)
    VrDeviceInfo    info

void
InitWindow(width, height, title)
    int    width
    int    height
    char *    title

bool
IsAudioBufferProcessed(stream)
    AudioStream    stream

bool
IsAudioDeviceReady()

bool
IsAudioStreamPlaying(stream)
    AudioStream    stream

bool
IsCursorHidden()

bool
IsFileDropped()

bool
IsFileExtension(fileName, ext)
    char *    fileName
    char *    ext

bool
IsGamepadAvailable(gamepad)
    int    gamepad

bool
IsGamepadButtonDown(gamepad, button)
    int    gamepad
    int    button

bool
IsGamepadButtonPressed(gamepad, button)
    int    gamepad
    int    button

bool
IsGamepadButtonReleased(gamepad, button)
    int    gamepad
    int    button

bool
IsGamepadButtonUp(gamepad, button)
    int    gamepad
    int    button

bool
IsGamepadName(gamepad, name)
    int    gamepad
    char *    name

bool
IsGestureDetected(gesture)
    int    gesture

bool
IsKeyDown(key)
    int    key

bool
IsKeyPressed(key)
    int    key

bool
IsKeyReleased(key)
    int    key

bool
IsKeyUp(key)
    int    key

bool
IsMouseButtonDown(button)
    int    button

bool
IsMouseButtonPressed(button)
    int    button

bool
IsMouseButtonReleased(button)
    int    button

bool
IsMouseButtonUp(button)
    int    button

bool
IsMusicPlaying(music)
    Music    music

bool
IsSoundPlaying(sound)
    Sound    sound

bool
IsVrSimulatorReady()

bool
IsWindowMinimized()

bool
IsWindowReady()

Font
LoadFont(fileName)
    char *    fileName

CharInfo *
LoadFontData(fileName, fontSize, fontChars, charsCount, sdf)
    char *    fileName
    int    fontSize
    int *    fontChars
    int    charsCount
    bool    sdf

Font
LoadFontEx(fileName, fontSize, charsCount, fontChars)
    char *    fileName
    int    fontSize
    int    charsCount
    int *    fontChars

Image
LoadImage(fileName)
    char *    fileName

Image
LoadImageEx(pixels, width, height)
    Color *    pixels
    int    width
    int    height

Image
LoadImagePro(data, width, height, format)
    void *    data
    int    width
    int    height
    int    format

Image
LoadImageRaw(fileName, width, height, format, headerSize)
    char *    fileName
    int    width
    int    height
    int    format
    int    headerSize

Image
LoadImageFromAV(array_ref, color_cb)
    SV *array_ref
    SV *color_cb
  ALIAS:
    LoadImageFromAV_uninitialized_mem = 1
    LoadImageFromAV_transposed = 2
    LoadImageFromAV_transposed_uninitialized_mem = 3
  INIT:
    int i;
    AV *av;
    Color *pixels;
    Image img;
    int literal_color = 0;
    int currwidth = 0;
    IntRectangle where = { 0, 0, 0, 0 };
    ImageSet_t *my_ImageSet = ImageSet;
  PPCODE:
    if (!SvROK(array_ref) || SvTYPE(SvRV(array_ref)) != SVt_PVAV)
        croak("expected ARRAY ref as first argument");
    literal_color = !SvOK(color_cb);
    if (!literal_color && (!SvROK(color_cb) || SvTYPE(SvRV(color_cb)) != SVt_PVCV))
        croak("expected CODE ref as second argument");

    av = (AV*)SvRV(array_ref);
    where.height = av_len(av) + 1;
    for (i = 0; i < where.height; i++) {
        SV** row_sv = av_fetch(av, i, 0);
        if (!row_sv || !SvROK(*row_sv) || SvTYPE(SvRV(*row_sv)) != SVt_PVAV)
            croak("expected ARRAY ref as rows");
        currwidth = av_len((AV*)SvRV(*row_sv)) + 1;
        if (currwidth > where.width)
            where.width = currwidth;
    }
    if (ix & 1) /* Looks cool, try it! */
        Newx(pixels, where.height * where.width, Color);
    else
        Newxz(pixels, where.height * where.width, Color);

    if (ix & 2)
        my_ImageSet = TransposedImageSet;

    EXTEND(SP, 3);
    for (i = 0; i < where.height; i++) {
        AV* row = (AV*)SvRV(*av_fetch(av, i, 0));

        for (int j = 0; j < where.width; j++) {
            SV *ret;
            SV** pixel = av_fetch(row, j, 0);
            if (!pixel) {
                /* do something ? */
            }

            Color color = BLANK;
            if (literal_color && pixel) {
                // No check! stay safe
                color = *(Color *)SvPV_nolen(SvRV(*pixel));
            } else {
                PUSHMARK(SP);
                PUSHs(pixel ? *pixel : &PL_sv_undef);
                PUSHs(sv_2mortal(newSViv(j)));
                PUSHs(sv_2mortal(newSViv(i)));
                PUTBACK;

                call_sv(color_cb, G_SCALAR);
                SPAGAIN;
                SV *ret = POPs;
                if (sv_isa(ret, "Graphics::Raylib::XS::Color"))
                    color = *(Color *)SvPV_nolen(SvRV(ret));
            }

            where = my_ImageSet(pixels, where, color, 1, 1);

        }
    }
    RETVAL = LoadImageEx(pixels, where.width, where.height);
    Safefree(pixels);
    {
        SV * RETVALSV;
        RETVALSV = sv_newmortal();
        sv_setref_pvn(RETVALSV, "Graphics::Raylib::XS::Image", (char *)&RETVAL, sizeof(RETVAL));
        ST(0) = RETVALSV;
    }
    XSRETURN(1);



Material
LoadMaterial(fileName)
    char *    fileName

Material
LoadMaterialDefault()

Mesh
LoadMesh(fileName)
    char *    fileName

Model
LoadModel(fileName)
    char *    fileName

Model
LoadModelFromMesh(mesh)
    Mesh    mesh

Music
LoadMusicStream(fileName)
    char *    fileName

RenderTexture2D
LoadRenderTexture(width, height)
    int    width
    int    height

Shader
LoadShader(vsFileName, fsFileName)
    char *    vsFileName
    char *    fsFileName

Shader
LoadShaderCode(vsCode, fsCode)
    char *    vsCode
    char *    fsCode

Sound
LoadSound(fileName)
    char *    fileName

Sound
LoadSoundFromWave(wave)
    Wave    wave

char *
LoadText(fileName)
    char *    fileName

Texture2D
LoadTexture(fileName)
    char *    fileName

Texture2D
LoadTextureFromImage(image)
    Image    image

Wave
LoadWave(fileName)
    char *    fileName

Wave
LoadWaveEx(data, sampleCount, sampleRate, sampleSize, channels)
    void *    data
    int    sampleCount
    int    sampleRate
    int    sampleSize
    int    channels

int
MeasureText(text, fontSize)
    char *    text
    int    fontSize

Vector2
MeasureTextEx(font, text, fontSize, spacing)
    Font    font
    char *    text
    float    fontSize
    float    spacing

void
MeshBinormals(mesh)
    Mesh *    mesh

BoundingBox
MeshBoundingBox(mesh)
    Mesh    mesh

void
MeshTangents(mesh)
    Mesh *    mesh

void
PauseAudioStream(stream)
    AudioStream    stream

void
PauseMusicStream(music)
    Music    music

void
PauseSound(sound)
    Sound    sound

void
PlayAudioStream(stream)
    AudioStream    stream

void
PlayMusicStream(music)
    Music    music

void
PlaySound(sound)
    Sound    sound

void
ResumeAudioStream(stream)
    AudioStream    stream

void
ResumeMusicStream(music)
    Music    music

void
ResumeSound(sound)
    Sound    sound

void
SetAudioStreamPitch(stream, pitch)
    AudioStream    stream
    float    pitch

void
SetAudioStreamVolume(stream, volume)
    AudioStream    stream
    float    volume

void
SetCameraAltControl(altKey)
    int    altKey

void
SetCameraMode(camera, mode)
    Camera3D    camera
    int    mode

void
SetCameraMoveControls(frontKey, backKey, rightKey, leftKey, upKey, downKey)
    int    frontKey
    int    backKey
    int    rightKey
    int    leftKey
    int    upKey
    int    downKey

void
SetCameraPanControl(panKey)
    int    panKey

void
SetCameraSmoothZoomControl(szKey)
    int    szKey

void
SetConfigFlags(flags)
    unsigned char    flags

void
SetExitKey(key)
    int    key

void
SetGesturesEnabled(gestureFlags)
    unsigned int    gestureFlags

void
SetMasterVolume(volume)
    float    volume

void
SetMatrixModelview(view)
    Matrix    view

void
SetMatrixProjection(proj)
    Matrix    proj

void
SetMousePosition(position)
    Vector2    position

void
SetMouseScale(scale)
    float    scale

void
SetMusicLoopCount(music, count)
    Music    music
    int    count

void
SetMusicPitch(music, pitch)
    Music    music
    float    pitch

void
SetMusicVolume(music, volume)
    Music    music
    float    volume

void
SetShaderValue(shader, uniformLoc, value, size)
    Shader    shader
    int    uniformLoc
    const float *    value
    int    size

void
SetShaderValueMatrix(shader, uniformLoc, mat)
    Shader    shader
    int    uniformLoc
    Matrix    mat

void
SetShaderValuei(shader, uniformLoc, value, size)
    Shader    shader
    int    uniformLoc
    const int *    value
    int    size

void
SetSoundPitch(sound, pitch)
    Sound    sound
    float    pitch

void
SetSoundVolume(sound, volume)
    Sound    sound
    float    volume

void
SetTargetFPS(fps)
    int    fps

void
SetTextureFilter(texture, filterMode)
    Texture2D    texture
    int    filterMode

void
SetTextureWrap(texture, wrapMode)
    Texture2D    texture
    int    wrapMode

void
SetTraceLog(types)
    unsigned char    types

void
SetVrDistortionShader(shader)
    Shader    shader

void
SetWindowIcon(image)
    Image    image

void
SetWindowMinSize(width, height)
    int    width
    int    height

void
SetWindowMonitor(monitor)
    int    monitor

void
SetWindowPosition(x, y)
    int    x
    int    y

void
SetWindowSize(width, height)
    int    width
    int    height

void
SetWindowTitle(title)
    char *    title

void
ShowCursor()

void
ShowLogo()

void
StopAudioStream(stream)
    AudioStream    stream

void
StopMusicStream(music)
    Music    music

void
StopSound(sound)
    Sound    sound

int
StorageLoadValue(position)
    int    position

void
StorageSaveValue(position, value)
    int    position
    int    value

char *
SubText(text, position, length)
    char *    text
    int    position
    int    length

void
TakeScreenshot(fileName)
    char *    fileName

void
ToggleFullscreen()

void
ToggleVrMode()

void
TraceLog(logType, text, ...)
    int    logType
    char *    text

void
UnloadFont(font)
    Font    font

void
UnloadImage(image)
    Image    image

void
UnloadMaterial(material)
    Material    material

void
UnloadMesh(mesh)
    Mesh *    mesh

void
UnloadModel(model)
    Model    model

void
UnloadMusicStream(music)
    Music    music

void
UnloadRenderTexture(target)
    RenderTexture2D    target

void
UnloadShader(shader)
    Shader    shader

void
UnloadSound(sound)
    Sound    sound

void
UnloadTexture(texture)
    Texture2D    texture

void
UnloadWave(wave)
    Wave    wave

void
UpdateAudioStream(stream, data, samplesCount)
    AudioStream    stream
    const void *    data
    int    samplesCount

void
UpdateCamera(camera)
    Camera3D *    camera

void
UpdateMusicStream(music)
    Music    music

void
UpdateSound(sound, data, samplesCount)
    Sound    sound
    const void *    data
    int    samplesCount

void
UpdateTexture(texture, pixels)
    Texture2D    texture
    const void *    pixels

void
UpdateTextureFromImage(texture, image)
    Texture2D    texture
    Image image
  CODE:
    UpdateTexture(texture, GetImageData(image));

void
UpdateVrTracking(camera)
    Camera3D *    camera

Wave
WaveCopy(wave)
    Wave    wave

void
WaveCrop(wave, initSample, finalSample)
    Wave *    wave
    int    initSample
    int    finalSample

void
WaveFormat(wave, sampleRate, sampleSize, channels)
    Wave *    wave
    int    sampleRate
    int    sampleSize
    int    channels

bool
WindowShouldClose()
