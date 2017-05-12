#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <raylib.h>

#include "const-c.inc"

MODULE = Graphics::Raylib::XS		PACKAGE = Graphics::Raylib::XS		

INCLUDE: const-xs.inc

void
Begin2dMode(camera)
	Camera2D	camera

void
Begin3dMode(camera)
	Camera	camera

void
BeginBlendMode(mode)
	int	mode

void
BeginDrawing()

void
BeginShaderMode(shader)
	Shader	shader

void
BeginTextureMode(target)
	RenderTexture2D	target

BoundingBox
CalculateBoundingBox(mesh)
	Mesh	mesh

int
CheckCollisionBoxSphere(box, centerSphere, radiusSphere)
	BoundingBox	box
	Vector3	centerSphere
	float	radiusSphere

int
CheckCollisionBoxes(box1, box2)
	BoundingBox	box1
	BoundingBox	box2

int
CheckCollisionCircleRec(center, radius, rec)
	Vector2	center
	float	radius
	Rectangle	rec

int
CheckCollisionCircles(center1, radius1, center2, radius2)
	Vector2	center1
	float	radius1
	Vector2	center2
	float	radius2

int
CheckCollisionPointCircle(point, center, radius)
	Vector2	point
	Vector2	center
	float	radius

int
CheckCollisionPointRec(point, rec)
	Vector2	point
	Rectangle	rec

int
CheckCollisionPointTriangle(point, p1, p2, p3)
	Vector2	point
	Vector2	p1
	Vector2	p2
	Vector2	p3

int
CheckCollisionRayBox(ray, box)
	Ray	ray
	BoundingBox	box

int
CheckCollisionRaySphere(ray, spherePosition, sphereRadius)
	Ray	ray
	Vector3	spherePosition
	float	sphereRadius

int
CheckCollisionRaySphereEx(ray, spherePosition, sphereRadius, collisionPoint)
	Ray	ray
	Vector3	spherePosition
	float	sphereRadius
	Vector3 *	collisionPoint

int
CheckCollisionRecs(rec1, rec2)
	Rectangle	rec1
	Rectangle	rec2

int
CheckCollisionSpheres(centerA, radiusA, centerB, radiusB)
	Vector3	centerA
	float	radiusA
	Vector3	centerB
	float	radiusB

void
ClearBackground(color)
	Color	color

void
ClearDroppedFiles()

void
CloseAudioDevice()

void
CloseAudioStream(stream)
	AudioStream	stream

void
CloseVrDevice()

void
CloseWindow()

float *
ColorToFloat(color)
	Color	color

Light
CreateLight(type, position, diffuse)
	int	type
	Vector3	position
	Color	diffuse

void
DestroyLight(light)
	Light	light

void
DisableCursor()

void
DrawBillboard(camera, texture, center, size, tint)
	Camera	camera
	Texture2D	texture
	Vector3	center
	float	size
	Color	tint

void
DrawBillboardRec(camera, texture, sourceRec, center, size, tint)
	Camera	camera
	Texture2D	texture
	Rectangle	sourceRec
	Vector3	center
	float	size
	Color	tint

void
DrawBoundingBox(box, color)
	BoundingBox	box
	Color	color

void
DrawCircle(centerX, centerY, radius, color)
	int	centerX
	int	centerY
	float	radius
	Color	color

void
DrawCircle3D(center, radius, rotationAxis, rotationAngle, color)
	Vector3	center
	float	radius
	Vector3	rotationAxis
	float	rotationAngle
	Color	color

void
DrawCircleGradient(centerX, centerY, radius, color1, color2)
	int	centerX
	int	centerY
	float	radius
	Color	color1
	Color	color2

void
DrawCircleLines(centerX, centerY, radius, color)
	int	centerX
	int	centerY
	float	radius
	Color	color

void
DrawCircleV(center, radius, color)
	Vector2	center
	float	radius
	Color	color

void
DrawCube(position, width, height, length, color)
	Vector3	position
	float	width
	float	height
	float	length
	Color	color

void
DrawCubeTexture(texture, position, width, height, length, color)
	Texture2D	texture
	Vector3	position
	float	width
	float	height
	float	length
	Color	color

void
DrawCubeV(position, size, color)
	Vector3	position
	Vector3	size
	Color	color

void
DrawCubeWires(position, width, height, length, color)
	Vector3	position
	float	width
	float	height
	float	length
	Color	color

void
DrawCylinder(position, radiusTop, radiusBottom, height, slices, color)
	Vector3	position
	float	radiusTop
	float	radiusBottom
	float	height
	int	slices
	Color	color

void
DrawCylinderWires(position, radiusTop, radiusBottom, height, slices, color)
	Vector3	position
	float	radiusTop
	float	radiusBottom
	float	height
	int	slices
	Color	color

void
DrawFPS(posX, posY)
	int	posX
	int	posY

void
DrawGizmo(position)
	Vector3	position

void
DrawGrid(slices, spacing)
	int	slices
	float	spacing

void
DrawLight(light)
	Light	light

void
DrawLine(startPosX, startPosY, endPosX, endPosY, color)
	int	startPosX
	int	startPosY
	int	endPosX
	int	endPosY
	Color	color

void
DrawLine3D(startPos, endPos, color)
	Vector3	startPos
	Vector3	endPos
	Color	color

void
DrawLineV(startPos, endPos, color)
	Vector2	startPos
	Vector2	endPos
	Color	color

void
DrawModel(model, position, scale, tint)
	Model	model
	Vector3	position
	float	scale
	Color	tint

void
DrawModelEx(model, position, rotationAxis, rotationAngle, scale, tint)
	Model	model
	Vector3	position
	Vector3	rotationAxis
	float	rotationAngle
	Vector3	scale
	Color	tint

void
DrawModelWires(model, position, scale, tint)
	Model	model
	Vector3	position
	float	scale
	Color	tint

void
DrawModelWiresEx(model, position, rotationAxis, rotationAngle, scale, tint)
	Model	model
	Vector3	position
	Vector3	rotationAxis
	float	rotationAngle
	Vector3	scale
	Color	tint

void
DrawPixel(posX, posY, color)
	int	posX
	int	posY
	Color	color

void
DrawPixelV(position, color)
	Vector2	position
	Color	color

void
DrawPlane(centerPos, size, color)
	Vector3	centerPos
	Vector2	size
	Color	color

void
DrawPoly(center, sides, radius, rotation, color)
	Vector2	center
	int	sides
	float	radius
	float	rotation
	Color	color

void
DrawPolyEx(points, numPoints, color)
	Vector2 *	points
	int	numPoints
	Color	color

void
DrawPolyExLines(points, numPoints, color)
	Vector2 *	points
	int	numPoints
	Color	color

void
DrawRay(ray, color)
	Ray	ray
	Color	color

void
DrawRectangle(posX, posY, width, height, color)
	int	posX
	int	posY
	int	width
	int	height
	Color	color

void
DrawRectangleGradient(posX, posY, width, height, color1, color2)
	int	posX
	int	posY
	int	width
	int	height
	Color	color1
	Color	color2

void
DrawRectangleLines(posX, posY, width, height, color)
	int	posX
	int	posY
	int	width
	int	height
	Color	color

void
DrawRectangleRec(rec, color)
	Rectangle	rec
	Color	color

void
DrawRectangleV(position, size, color)
	Vector2	position
	Vector2	size
	Color	color

void
DrawSphere(centerPos, radius, color)
	Vector3	centerPos
	float	radius
	Color	color

void
DrawSphereEx(centerPos, radius, rings, slices, color)
	Vector3	centerPos
	float	radius
	int	rings
	int	slices
	Color	color

void
DrawSphereWires(centerPos, radius, rings, slices, color)
	Vector3	centerPos
	float	radius
	int	rings
	int	slices
	Color	color

void
DrawText(text, posX, posY, fontSize, color)
	const char *	text
	int	posX
	int	posY
	int	fontSize
	Color	color

void
DrawTextEx(spriteFont, text, position, fontSize, spacing, tint)
	SpriteFont	spriteFont
	const char *	text
	Vector2	position
	float	fontSize
	int	spacing
	Color	tint

void
DrawTexture(texture, posX, posY, tint)
	Texture2D	texture
	int	posX
	int	posY
	Color	tint

void
DrawTextureEx(texture, position, rotation, scale, tint)
	Texture2D	texture
	Vector2	position
	float	rotation
	float	scale
	Color	tint

void
DrawTexturePro(texture, sourceRec, destRec, origin, rotation, tint)
	Texture2D	texture
	Rectangle	sourceRec
	Rectangle	destRec
	Vector2	origin
	float	rotation
	Color	tint

void
DrawTextureRec(texture, sourceRec, position, tint)
	Texture2D	texture
	Rectangle	sourceRec
	Vector2	position
	Color	tint

void
DrawTextureV(texture, position, tint)
	Texture2D	texture
	Vector2	position
	Color	tint

void
DrawTriangle(v1, v2, v3, color)
	Vector2	v1
	Vector2	v2
	Vector2	v3
	Color	color

void
DrawTriangleLines(v1, v2, v3, color)
	Vector2	v1
	Vector2	v2
	Vector2	v3
	Color	color

void
EnableCursor()

void
End2dMode()

void
End3dMode()

void
EndBlendMode()

void
EndDrawing()

void
EndShaderMode()

void
EndTextureMode()

Color
Fade(color, alpha)
	Color	color
	float	alpha

const char *
FormatText(text, ...)
	const char *	text

void
GenTextureMipmaps(texture)
	Texture2D *	texture

Matrix
GetCameraMatrix(camera)
	Camera	camera

Rectangle
GetCollisionRec(rec1, rec2)
	Rectangle	rec1
	Rectangle	rec2

Color
GetColor(hexValue)
	int	hexValue

SpriteFont
GetDefaultFont()

Shader
GetDefaultShader()

Texture2D
GetDefaultTexture()

float
GetFPS()

float
GetFrameTime()

int
GetGamepadAxisCount(gamepad)
	int	gamepad

float
GetGamepadAxisMovement(gamepad, axis)
	int	gamepad
	int	axis

int
GetGamepadButtonPressed()

const char *
GetGamepadName(gamepad)
	int	gamepad

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
GetHexValue(color)
	Color	color

Color *
GetImageData(image)
	Image	image

int
GetKeyPressed()

Vector2
GetMousePosition()

Ray
GetMouseRay(mousePosition, camera)
	Vector2	mousePosition
	Camera	camera

int
GetMouseWheelMove()

int
GetMouseX()

int
GetMouseY()

float
GetMusicTimeLength(music)
	Music	music

float
GetMusicTimePlayed(music)
	Music	music

int
GetRandomValue(min, max)
	int	min
	int	max

int
GetScreenHeight()

int
GetScreenWidth()

int
GetShaderLocation(shader, uniformName)
	Shader	shader
	const char *	uniformName

Shader
GetStandardShader()

Image
GetTextureData(texture)
	Texture2D	texture

int
GetTouchPointsCount()

Vector2
GetTouchPosition(index)
	int	index

int
GetTouchX()

int
GetTouchY()

float *
GetWaveData(wave)
	Wave	wave

Vector2
GetWorldToScreen(position, camera)
	Vector3	position
	Camera	camera

void
HideCursor()

void
ImageAlphaMask(image, alphaMask)
	Image *	image
	Image	alphaMask

void
ImageColorBrightness(image, brightness)
	Image *	image
	int	brightness

void
ImageColorContrast(image, contrast)
	Image *	image
	float	contrast

void
ImageColorGrayscale(image)
	Image *	image

void
ImageColorInvert(image)
	Image *	image

void
ImageColorTint(image, color)
	Image *	image
	Color	color

Image
ImageCopy(image)
	Image	image

void
ImageCrop(image, crop)
	Image *	image
	Rectangle	crop

void
ImageDither(image, rBpp, gBpp, bBpp, aBpp)
	Image *	image
	int	rBpp
	int	gBpp
	int	bBpp
	int	aBpp

void
ImageDraw(dst, src, srcRec, dstRec)
	Image *	dst
	Image	src
	Rectangle	srcRec
	Rectangle	dstRec

void
ImageDrawText(dst, position, text, fontSize, color)
	Image *	dst
	Vector2	position
	const char *	text
	int	fontSize
	Color	color

void
ImageDrawTextEx(dst, position, font, text, fontSize, spacing, color)
	Image *	dst
	Vector2	position
	SpriteFont	font
	const char *	text
	float	fontSize
	int	spacing
	Color	color

void
ImageFlipHorizontal(image)
	Image *	image

void
ImageFlipVertical(image)
	Image *	image

void
ImageFormat(image, newFormat)
	Image *	image
	int	newFormat

void
ImageResize(image, newWidth, newHeight)
	Image *	image
	int	newWidth
	int	newHeight

void
ImageResizeNN(image, newWidth, newHeight)
	Image *	image
	int	newWidth
	int	newHeight

Image
ImageText(text, fontSize, color)
	const char *	text
	int	fontSize
	Color	color

Image
ImageTextEx(font, text, fontSize, spacing, tint)
	SpriteFont	font
	const char *	text
	float	fontSize
	int	spacing
	Color	tint

void
ImageToPOT(image, fillColor)
	Image *	image
	Color	fillColor

void
InitAudioDevice()

AudioStream
InitAudioStream(sampleRate, sampleSize, channels)
	unsigned int	sampleRate
	unsigned int	sampleSize
	unsigned int	channels

void
InitVrDevice(vdDevice)
	int	vdDevice

void
InitWindow(width, height, title)
	int	width
	int	height
	const char *	title

int
IsAudioBufferProcessed(stream)
	AudioStream	stream

int
IsAudioDeviceReady()

int
IsCursorHidden()

int
IsFileDropped()

int
IsGamepadAvailable(gamepad)
	int	gamepad

int
IsGamepadButtonDown(gamepad, button)
	int	gamepad
	int	button

int
IsGamepadButtonPressed(gamepad, button)
	int	gamepad
	int	button

int
IsGamepadButtonReleased(gamepad, button)
	int	gamepad
	int	button

int
IsGamepadButtonUp(gamepad, button)
	int	gamepad
	int	button

int
IsGamepadName(gamepad, name)
	int	gamepad
	const char *	name

int
IsGestureDetected(gesture)
	int	gesture

int
IsKeyDown(key)
	int	key

int
IsKeyPressed(key)
	int	key

int
IsKeyReleased(key)
	int	key

int
IsKeyUp(key)
	int	key

int
IsMouseButtonDown(button)
	int	button

int
IsMouseButtonPressed(button)
	int	button

int
IsMouseButtonReleased(button)
	int	button

int
IsMouseButtonUp(button)
	int	button

int
IsMusicPlaying(music)
	Music	music

int
IsSoundPlaying(sound)
	Sound	sound

int
IsVrDeviceReady()

int
IsVrSimulator()

int
IsWindowMinimized()

Model
LoadCubicmap(cubicmap)
	Image	cubicmap

Material
LoadDefaultMaterial()

Model
LoadHeightmap(heightmap, size)
	Image	heightmap
	Vector3	size

Image
LoadImage(fileName)
	const char *	fileName

Image
LoadImageEx(pixels, width, height)
	Color *	pixels
	int	width
	int	height

Image
LoadImageFromRES(rresName, resId)
	const char *	rresName
	int	resId

Image
LoadImageRaw(fileName, width, height, format, headerSize)
	const char *	fileName
	int	width
	int	height
	int	format
	int	headerSize

Material
LoadMaterial(fileName)
	const char *	fileName

Model
LoadModel(fileName)
	const char *	fileName

Model
LoadModelEx(data, dynamic)
	Mesh	data
	int	dynamic

Model
LoadModelFromRES(rresName, resId)
	const char *	rresName
	int	resId

Music
LoadMusicStream(fileName)
	const char *	fileName

RenderTexture2D
LoadRenderTexture(width, height)
	int	width
	int	height

Shader
LoadShader(vsFileName, fsFileName)
	char *	vsFileName
	char *	fsFileName

Sound
LoadSound(fileName)
	const char *	fileName

Sound
LoadSoundFromRES(rresName, resId)
	const char *	rresName
	int	resId

Sound
LoadSoundFromWave(wave)
	Wave	wave

SpriteFont
LoadSpriteFont(fileName)
	const char *	fileName

SpriteFont
LoadSpriteFontTTF(fileName, fontSize, numChars, fontChars)
	const char *	fileName
	int	fontSize
	int	numChars
	int *	fontChars

Material
LoadStandardMaterial()

Texture2D
LoadTexture(fileName)
	const char *	fileName

Texture2D
LoadTextureEx(data, width, height, textureFormat)
	void *	data
	int	width
	int	height
	int	textureFormat

Texture2D
LoadTextureFromImage(image)
	Image	image

Texture2D
LoadTextureFromRES(rresName, resId)
	const char *	rresName
	int	resId

Wave
LoadWave(fileName)
	const char *	fileName

Wave
LoadWaveEx(data, sampleCount, sampleRate, sampleSize, channels)
	float *	data
	int	sampleCount
	int	sampleRate
	int	sampleSize
	int	channels

float *
MatrixToFloat(mat)
	Matrix	mat

int
MeasureText(text, fontSize)
	const char *	text
	int	fontSize

Vector2
MeasureTextEx(spriteFont, text, fontSize, spacing)
	SpriteFont	spriteFont
	const char *	text
	float	fontSize
	int	spacing

void
PauseAudioStream(stream)
	AudioStream	stream

void
PauseMusicStream(music)
	Music	music

void
PauseSound(sound)
	Sound	sound

void
PlayAudioStream(stream)
	AudioStream	stream

void
PlayMusicStream(music)
	Music	music

void
PlaySound(sound)
	Sound	sound

void
ResumeAudioStream(stream)
	AudioStream	stream

void
ResumeMusicStream(music)
	Music	music

void
ResumeSound(sound)
	Sound	sound

void
SetCameraAltControl(altKey)
	int	altKey

void
SetCameraMode(camera, mode)
	Camera	camera
	int	mode

void
SetCameraMoveControls(frontKey, backKey, rightKey, leftKey, upKey, downKey)
	int	frontKey
	int	backKey
	int	rightKey
	int	leftKey
	int	upKey
	int	downKey

void
SetCameraPanControl(panKey)
	int	panKey

void
SetCameraSmoothZoomControl(szKey)
	int	szKey

void
SetConfigFlags(flags)
	char	flags

void
SetExitKey(key)
	int	key

void
SetGesturesEnabled(gestureFlags)
	unsigned int	gestureFlags

void
SetMatrixModelview(view)
	Matrix	view

void
SetMatrixProjection(proj)
	Matrix	proj

void
SetMousePosition(position)
	Vector2	position

void
SetMusicPitch(music, pitch)
	Music	music
	float	pitch

void
SetMusicVolume(music, volume)
	Music	music
	float	volume

void
SetShaderValue(shader, uniformLoc, value, size)
	Shader	shader
	int	uniformLoc
	float *	value
	int	size

void
SetShaderValueMatrix(shader, uniformLoc, mat)
	Shader	shader
	int	uniformLoc
	Matrix	mat

void
SetShaderValuei(shader, uniformLoc, value, size)
	Shader	shader
	int	uniformLoc
	int *	value
	int	size

void
SetSoundPitch(sound, pitch)
	Sound	sound
	float	pitch

void
SetSoundVolume(sound, volume)
	Sound	sound
	float	volume

void
SetTargetFPS(fps)
	int	fps

void
SetTextureFilter(texture, filterMode)
	Texture2D	texture
	int	filterMode

void
SetTextureWrap(texture, wrapMode)
	Texture2D	texture
	int	wrapMode

void
ShowCursor()

void
ShowLogo()

void
StopAudioStream(stream)
	AudioStream	stream

void
StopMusicStream(music)
	Music	music

void
StopSound(sound)
	Sound	sound

int
StorageLoadValue(position)
	int	position

void
StorageSaveValue(position, value)
	int	position
	int	value

const char *
SubText(text, position, length)
	const char *	text
	int	position
	int	length

void
ToggleFullscreen()

void
ToggleVrMode()

void
UnloadImage(image)
	Image	image

void
UnloadMaterial(material)
	Material	material

void
UnloadModel(model)
	Model	model

void
UnloadMusicStream(music)
	Music	music

void
UnloadRenderTexture(target)
	RenderTexture2D	target

void
UnloadShader(shader)
	Shader	shader

void
UnloadSound(sound)
	Sound	sound

void
UnloadSpriteFont(spriteFont)
	SpriteFont	spriteFont

void
UnloadTexture(texture)
	Texture2D	texture

void
UnloadWave(wave)
	Wave	wave

void
UpdateAudioStream(stream, data, numSamples)
	AudioStream	stream
	void *	data
	int	numSamples

void
UpdateCamera(camera)
	Camera *	camera

void
UpdateMusicStream(music)
	Music	music

void
UpdateSound(sound, data, numSamples)
	Sound	sound
	void *	data
	int	numSamples

void
UpdateTexture(texture, pixels)
	Texture2D	texture
	void *	pixels

void
UpdateVrTracking(camera)
	Camera *	camera

float *
VectorToFloat(vec)
	Vector3	vec

Wave
WaveCopy(wave)
	Wave	wave

void
WaveCrop(wave, initSample, finalSample)
	Wave *	wave
	int	initSample
	int	finalSample

void
WaveFormat(wave, sampleRate, sampleSize, channels)
	Wave *	wave
	int	sampleRate
	int	sampleSize
	int	channels

int
WindowShouldClose()
