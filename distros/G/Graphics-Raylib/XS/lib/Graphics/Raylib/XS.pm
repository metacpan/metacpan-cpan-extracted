package Graphics::Raylib::XS;

use 5.008000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

# ABSTRACT: XS Wrapper around raylib
# VERSION


our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Graphics::Raylib::XS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	BLEND_ADDITIVE
	BLEND_ALPHA
	BLEND_MULTIPLIED
	CAMERA_CUSTOM
	CAMERA_FIRST_PERSON
	CAMERA_FREE
	CAMERA_ORBITAL
	CAMERA_THIRD_PERSON
	COMPRESSED_ASTC_4x4_RGBA
	COMPRESSED_ASTC_8x8_RGBA
	COMPRESSED_DXT1_RGB
	COMPRESSED_DXT1_RGBA
	COMPRESSED_DXT3_RGBA
	COMPRESSED_DXT5_RGBA
	COMPRESSED_ETC1_RGB
	COMPRESSED_ETC2_EAC_RGBA
	COMPRESSED_ETC2_RGB
	COMPRESSED_PVRT_RGB
	COMPRESSED_PVRT_RGBA
	DEG2RAD
	FILTER_ANISOTROPIC_16X
	FILTER_ANISOTROPIC_4X
	FILTER_ANISOTROPIC_8X
	FILTER_BILINEAR
	FILTER_POINT
	FILTER_TRILINEAR
	FLAG_CENTERED_MODE
	FLAG_FULLSCREEN_MODE
	FLAG_MSAA_4X_HINT
	FLAG_RESIZABLE_WINDOW
	FLAG_SHOW_LOGO
	FLAG_SHOW_MOUSE_CURSOR
	FLAG_VSYNC_HINT
	GAMEPAD_PLAYER1
	GAMEPAD_PLAYER2
	GAMEPAD_PLAYER3
	GAMEPAD_PLAYER4
	GAMEPAD_PS3_AXIS_L2
	GAMEPAD_PS3_AXIS_LEFT_X
	GAMEPAD_PS3_AXIS_LEFT_Y
	GAMEPAD_PS3_AXIS_R2
	GAMEPAD_PS3_AXIS_RIGHT_X
	GAMEPAD_PS3_AXIS_RIGHT_Y
	GAMEPAD_PS3_BUTTON_CIRCLE
	GAMEPAD_PS3_BUTTON_CROSS
	GAMEPAD_PS3_BUTTON_DOWN
	GAMEPAD_PS3_BUTTON_L1
	GAMEPAD_PS3_BUTTON_L2
	GAMEPAD_PS3_BUTTON_LEFT
	GAMEPAD_PS3_BUTTON_PS
	GAMEPAD_PS3_BUTTON_R1
	GAMEPAD_PS3_BUTTON_R2
	GAMEPAD_PS3_BUTTON_RIGHT
	GAMEPAD_PS3_BUTTON_SELECT
	GAMEPAD_PS3_BUTTON_SQUARE
	GAMEPAD_PS3_BUTTON_START
	GAMEPAD_PS3_BUTTON_TRIANGLE
	GAMEPAD_PS3_BUTTON_UP
	GAMEPAD_XBOX_AXIS_LEFT_X
	GAMEPAD_XBOX_AXIS_LEFT_Y
	GAMEPAD_XBOX_AXIS_LT
	GAMEPAD_XBOX_AXIS_RIGHT_X
	GAMEPAD_XBOX_AXIS_RIGHT_Y
	GAMEPAD_XBOX_AXIS_RT
	GAMEPAD_XBOX_BUTTON_A
	GAMEPAD_XBOX_BUTTON_B
	GAMEPAD_XBOX_BUTTON_DOWN
	GAMEPAD_XBOX_BUTTON_HOME
	GAMEPAD_XBOX_BUTTON_LB
	GAMEPAD_XBOX_BUTTON_LEFT
	GAMEPAD_XBOX_BUTTON_RB
	GAMEPAD_XBOX_BUTTON_RIGHT
	GAMEPAD_XBOX_BUTTON_SELECT
	GAMEPAD_XBOX_BUTTON_START
	GAMEPAD_XBOX_BUTTON_UP
	GAMEPAD_XBOX_BUTTON_X
	GAMEPAD_XBOX_BUTTON_Y
	GESTURE_DOUBLETAP
	GESTURE_DRAG
	GESTURE_HOLD
	GESTURE_NONE
	GESTURE_PINCH_IN
	GESTURE_PINCH_OUT
	GESTURE_SWIPE_DOWN
	GESTURE_SWIPE_LEFT
	GESTURE_SWIPE_RIGHT
	GESTURE_SWIPE_UP
	GESTURE_TAP
	HMD_DEFAULT_DEVICE
	HMD_FOVE_VR
	HMD_GOOGLE_CARDBOARD
	HMD_OCULUS_RIFT_CV1
	HMD_OCULUS_RIFT_DK2
	HMD_RAZER_OSVR
	HMD_SAMSUNG_GEAR_VR
	HMD_SONY_PLAYSTATION_VR
	HMD_VALVE_HTC_VIVE
	KEY_A
	KEY_B
	KEY_BACK
	KEY_BACKSPACE
	KEY_C
	KEY_D
	KEY_DOWN
	KEY_E
	KEY_EIGHT
	KEY_ENTER
	KEY_ESCAPE
	KEY_F
	KEY_F1
	KEY_F10
	KEY_F11
	KEY_F12
	KEY_F2
	KEY_F3
	KEY_F4
	KEY_F5
	KEY_F6
	KEY_F7
	KEY_F8
	KEY_F9
	KEY_FIVE
	KEY_FOUR
	KEY_G
	KEY_H
	KEY_I
	KEY_J
	KEY_K
	KEY_L
	KEY_LEFT
	KEY_LEFT_ALT
	KEY_LEFT_CONTROL
	KEY_LEFT_SHIFT
	KEY_M
	KEY_MENU
	KEY_N
	KEY_NINE
	KEY_O
	KEY_ONE
	KEY_P
	KEY_Q
	KEY_R
	KEY_RIGHT
	KEY_RIGHT_ALT
	KEY_RIGHT_CONTROL
	KEY_RIGHT_SHIFT
	KEY_S
	KEY_SEVEN
	KEY_SIX
	KEY_SPACE
	KEY_T
	KEY_THREE
	KEY_TWO
	KEY_U
	KEY_UP
	KEY_V
	KEY_VOLUME_DOWN
	KEY_VOLUME_UP
	KEY_W
	KEY_X
	KEY_Y
	KEY_Z
	KEY_ZERO
	LIGHT_DIRECTIONAL
	LIGHT_POINT
	LIGHT_SPOT
	MAX_TOUCH_POINTS
	MOUSE_LEFT_BUTTON
	MOUSE_MIDDLE_BUTTON
	MOUSE_RIGHT_BUTTON
	RAD2DEG
	UNCOMPRESSED_GRAYSCALE
	UNCOMPRESSED_GRAY_ALPHA
	UNCOMPRESSED_R4G4B4A4
	UNCOMPRESSED_R5G5B5A1
	UNCOMPRESSED_R5G6B5
	UNCOMPRESSED_R8G8B8
	UNCOMPRESSED_R8G8B8A8
	WRAP_CLAMP
	WRAP_MIRROR
	WRAP_REPEAT
	false
	true
	Begin2dMode
	Begin3dMode
	BeginBlendMode
	BeginDrawing
	BeginShaderMode
	BeginTextureMode
	CalculateBoundingBox
	CheckCollisionBoxSphere
	CheckCollisionBoxes
	CheckCollisionCircleRec
	CheckCollisionCircles
	CheckCollisionPointCircle
	CheckCollisionPointRec
	CheckCollisionPointTriangle
	CheckCollisionRayBox
	CheckCollisionRaySphere
	CheckCollisionRaySphereEx
	CheckCollisionRecs
	CheckCollisionSpheres
	ClearBackground
	ClearDroppedFiles
	CloseAudioDevice
	CloseAudioStream
	CloseVrDevice
	CloseWindow
	ColorToFloat
	CreateLight
	DestroyLight
	DisableCursor
	DrawBillboard
	DrawBillboardRec
	DrawBoundingBox
	DrawCircle
	DrawCircle3D
	DrawCircleGradient
	DrawCircleLines
	DrawCircleV
	DrawCube
	DrawCubeTexture
	DrawCubeV
	DrawCubeWires
	DrawCylinder
	DrawCylinderWires
	DrawFPS
	DrawGizmo
	DrawGrid
	DrawLight
	DrawLine
	DrawLine3D
	DrawLineV
	DrawModel
	DrawModelEx
	DrawModelWires
	DrawModelWiresEx
	DrawPixel
	DrawPixelV
	DrawPlane
	DrawPoly
	DrawPolyEx
	DrawPolyExLines
	DrawRay
	DrawRectangle
	DrawRectangleGradient
	DrawRectangleLines
	DrawRectangleRec
	DrawRectangleV
	DrawSphere
	DrawSphereEx
	DrawSphereWires
	DrawText
	DrawTextEx
	DrawTexture
	DrawTextureEx
	DrawTexturePro
	DrawTextureRec
	DrawTextureV
	DrawSOSTexture
	DrawTriangle
	DrawTriangleLines
	EnableCursor
	End2dMode
	End3dMode
	EndBlendMode
	EndDrawing
	EndShaderMode
	EndTextureMode
	Fade
	FormatText
	GenTextureMipmaps
	GetCameraMatrix
	GetCollisionRec
	GetColor
	GetDefaultFont
	GetDefaultShader
	GetDefaultTexture
	GetFPS
	GetFrameTime
	GetGamepadAxisCount
	GetGamepadAxisMovement
	GetGamepadButtonPressed
	GetGamepadName
	GetGestureDetected
	GetGestureDragAngle
	GetGestureDragVector
	GetGestureHoldDuration
	GetGesturePinchAngle
	GetGesturePinchVector
	GetHexValue
	GetImageData
	GetKeyPressed
	GetMousePosition
	GetMouseRay
	GetMouseWheelMove
	GetMouseX
	GetMouseY
	GetMusicTimeLength
	GetMusicTimePlayed
	GetRandomValue
	GetScreenHeight
	GetScreenWidth
	GetShaderLocation
	GetStandardShader
	GetTextureData
	GetTouchPointsCount
	GetTouchPosition
	GetTouchX
	GetTouchY
	GetWaveData
	GetWorldToScreen
	HideCursor
	ImageAlphaMask
	ImageColorBrightness
	ImageColorContrast
	ImageColorGrayscale
	ImageColorInvert
	ImageColorTint
	ImageCopy
	ImageCrop
	ImageDither
	ImageDraw
	ImageDrawText
	ImageDrawTextEx
	ImageFlipHorizontal
	ImageFlipVertical
	ImageFormat
	ImageResize
	ImageResizeNN
	ImageText
	ImageTextEx
	ImageToPOT
	InitAudioDevice
	InitAudioStream
	InitVrDevice
	InitWindow
	IsAudioBufferProcessed
	IsAudioDeviceReady
	IsCursorHidden
	IsFileDropped
	IsGamepadAvailable
	IsGamepadButtonDown
	IsGamepadButtonPressed
	IsGamepadButtonReleased
	IsGamepadButtonUp
	IsGamepadName
	IsGestureDetected
	IsKeyDown
	IsKeyPressed
	IsKeyReleased
	IsKeyUp
	IsMouseButtonDown
	IsMouseButtonPressed
	IsMouseButtonReleased
	IsMouseButtonUp
	IsMusicPlaying
	IsSoundPlaying
	IsVrDeviceReady
	IsVrSimulator
	IsWindowMinimized
	LoadCubicmap
	LoadDefaultMaterial
	LoadHeightmap
	LoadImage
	LoadImageEx
	LoadImageFromRES
	LoadImageRaw
	LoadSOSImage
	LoadImageFromAV
    LoadImageFromAV_uninitialized_mem
	LoadMaterial
	LoadModel
	LoadModelEx
	LoadModelFromRES
	LoadMusicStream
	LoadRenderTexture
	LoadShader
	LoadSound
	LoadSoundFromRES
	LoadSoundFromWave
	LoadSpriteFont
	LoadSpriteFontTTF
	LoadStandardMaterial
	LoadTexture
	LoadTextureEx
	LoadTextureFromImage
	LoadTextureFromRES
	LoadWave
	LoadWaveEx
	MatrixToFloat
	MeasureText
	MeasureTextEx
	PauseAudioStream
	PauseMusicStream
	PauseSound
	PlayAudioStream
	PlayMusicStream
	PlaySound
	ResumeAudioStream
	ResumeMusicStream
	ResumeSound
	SetCameraAltControl
	SetCameraMode
	SetCameraMoveControls
	SetCameraPanControl
	SetCameraSmoothZoomControl
	SetConfigFlags
	SetExitKey
	SetGesturesEnabled
	SetMatrixModelview
	SetMatrixProjection
	SetMousePosition
	SetMusicPitch
	SetMusicVolume
	SetShaderValue
	SetShaderValueMatrix
	SetShaderValuei
	SetSoundPitch
	SetSoundVolume
	SetTargetFPS
	SetTextureFilter
	SetTextureWrap
	ShowCursor
	ShowLogo
	StopAudioStream
	StopMusicStream
	StopSound
	StorageLoadValue
	StorageSaveValue
	SubText
	ToggleFullscreen
	ToggleVrMode
	UnloadImage
	UnloadMaterial
	UnloadModel
	UnloadMusicStream
	UnloadRenderTexture
	UnloadShader
	UnloadSound
	UnloadSpriteFont
	UnloadTexture
	UnloadWave
	UpdateAudioStream
	UpdateCamera
	UpdateMusicStream
	UpdateSound
	UpdateTexture
	UpdateTextureFromImage
	UpdateVrTracking
	VectorToFloat
	WaveCopy
	WaveCrop
	WaveFormat
	WindowShouldClose
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	BLEND_ADDITIVE
	BLEND_ALPHA
	BLEND_MULTIPLIED
	CAMERA_CUSTOM
	CAMERA_FIRST_PERSON
	CAMERA_FREE
	CAMERA_ORBITAL
	CAMERA_THIRD_PERSON
	COMPRESSED_ASTC_4x4_RGBA
	COMPRESSED_ASTC_8x8_RGBA
	COMPRESSED_DXT1_RGB
	COMPRESSED_DXT1_RGBA
	COMPRESSED_DXT3_RGBA
	COMPRESSED_DXT5_RGBA
	COMPRESSED_ETC1_RGB
	COMPRESSED_ETC2_EAC_RGBA
	COMPRESSED_ETC2_RGB
	COMPRESSED_PVRT_RGB
	COMPRESSED_PVRT_RGBA
	DEG2RAD
	FILTER_ANISOTROPIC_16X
	FILTER_ANISOTROPIC_4X
	FILTER_ANISOTROPIC_8X
	FILTER_BILINEAR
	FILTER_POINT
	FILTER_TRILINEAR
	FLAG_CENTERED_MODE
	FLAG_FULLSCREEN_MODE
	FLAG_MSAA_4X_HINT
	FLAG_RESIZABLE_WINDOW
	FLAG_SHOW_LOGO
	FLAG_SHOW_MOUSE_CURSOR
	FLAG_VSYNC_HINT
	GAMEPAD_PLAYER1
	GAMEPAD_PLAYER2
	GAMEPAD_PLAYER3
	GAMEPAD_PLAYER4
	GAMEPAD_PS3_AXIS_L2
	GAMEPAD_PS3_AXIS_LEFT_X
	GAMEPAD_PS3_AXIS_LEFT_Y
	GAMEPAD_PS3_AXIS_R2
	GAMEPAD_PS3_AXIS_RIGHT_X
	GAMEPAD_PS3_AXIS_RIGHT_Y
	GAMEPAD_PS3_BUTTON_CIRCLE
	GAMEPAD_PS3_BUTTON_CROSS
	GAMEPAD_PS3_BUTTON_DOWN
	GAMEPAD_PS3_BUTTON_L1
	GAMEPAD_PS3_BUTTON_L2
	GAMEPAD_PS3_BUTTON_LEFT
	GAMEPAD_PS3_BUTTON_PS
	GAMEPAD_PS3_BUTTON_R1
	GAMEPAD_PS3_BUTTON_R2
	GAMEPAD_PS3_BUTTON_RIGHT
	GAMEPAD_PS3_BUTTON_SELECT
	GAMEPAD_PS3_BUTTON_SQUARE
	GAMEPAD_PS3_BUTTON_START
	GAMEPAD_PS3_BUTTON_TRIANGLE
	GAMEPAD_PS3_BUTTON_UP
	GAMEPAD_XBOX_AXIS_LEFT_X
	GAMEPAD_XBOX_AXIS_LEFT_Y
	GAMEPAD_XBOX_AXIS_LT
	GAMEPAD_XBOX_AXIS_RIGHT_X
	GAMEPAD_XBOX_AXIS_RIGHT_Y
	GAMEPAD_XBOX_AXIS_RT
	GAMEPAD_XBOX_BUTTON_A
	GAMEPAD_XBOX_BUTTON_B
	GAMEPAD_XBOX_BUTTON_DOWN
	GAMEPAD_XBOX_BUTTON_HOME
	GAMEPAD_XBOX_BUTTON_LB
	GAMEPAD_XBOX_BUTTON_LEFT
	GAMEPAD_XBOX_BUTTON_RB
	GAMEPAD_XBOX_BUTTON_RIGHT
	GAMEPAD_XBOX_BUTTON_SELECT
	GAMEPAD_XBOX_BUTTON_START
	GAMEPAD_XBOX_BUTTON_UP
	GAMEPAD_XBOX_BUTTON_X
	GAMEPAD_XBOX_BUTTON_Y
	GESTURE_DOUBLETAP
	GESTURE_DRAG
	GESTURE_HOLD
	GESTURE_NONE
	GESTURE_PINCH_IN
	GESTURE_PINCH_OUT
	GESTURE_SWIPE_DOWN
	GESTURE_SWIPE_LEFT
	GESTURE_SWIPE_RIGHT
	GESTURE_SWIPE_UP
	GESTURE_TAP
	HMD_DEFAULT_DEVICE
	HMD_FOVE_VR
	HMD_GOOGLE_CARDBOARD
	HMD_OCULUS_RIFT_CV1
	HMD_OCULUS_RIFT_DK2
	HMD_RAZER_OSVR
	HMD_SAMSUNG_GEAR_VR
	HMD_SONY_PLAYSTATION_VR
	HMD_VALVE_HTC_VIVE
	KEY_A
	KEY_B
	KEY_BACK
	KEY_BACKSPACE
	KEY_C
	KEY_D
	KEY_DOWN
	KEY_E
	KEY_EIGHT
	KEY_ENTER
	KEY_ESCAPE
	KEY_F
	KEY_F1
	KEY_F10
	KEY_F11
	KEY_F12
	KEY_F2
	KEY_F3
	KEY_F4
	KEY_F5
	KEY_F6
	KEY_F7
	KEY_F8
	KEY_F9
	KEY_FIVE
	KEY_FOUR
	KEY_G
	KEY_H
	KEY_I
	KEY_J
	KEY_K
	KEY_L
	KEY_LEFT
	KEY_LEFT_ALT
	KEY_LEFT_CONTROL
	KEY_LEFT_SHIFT
	KEY_M
	KEY_MENU
	KEY_N
	KEY_NINE
	KEY_O
	KEY_ONE
	KEY_P
	KEY_Q
	KEY_R
	KEY_RIGHT
	KEY_RIGHT_ALT
	KEY_RIGHT_CONTROL
	KEY_RIGHT_SHIFT
	KEY_S
	KEY_SEVEN
	KEY_SIX
	KEY_SPACE
	KEY_T
	KEY_THREE
	KEY_TWO
	KEY_U
	KEY_UP
	KEY_V
	KEY_VOLUME_DOWN
	KEY_VOLUME_UP
	KEY_W
	KEY_X
	KEY_Y
	KEY_Z
	KEY_ZERO
	LIGHT_DIRECTIONAL
	LIGHT_POINT
	LIGHT_SPOT
	MAX_TOUCH_POINTS
	MOUSE_LEFT_BUTTON
	MOUSE_MIDDLE_BUTTON
	MOUSE_RIGHT_BUTTON
	RAD2DEG
	UNCOMPRESSED_GRAYSCALE
	UNCOMPRESSED_GRAY_ALPHA
	UNCOMPRESSED_R4G4B4A4
	UNCOMPRESSED_R5G5B5A1
	UNCOMPRESSED_R5G6B5
	UNCOMPRESSED_R8G8B8
	UNCOMPRESSED_R8G8B8A8
	WRAP_CLAMP
	WRAP_MIRROR
	WRAP_REPEAT
	false
	true
);

our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Graphics::Raylib::XS::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Graphics::Raylib::XS', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Graphics::Raylib::XS - XS wrapper around raylib

=head1 SYNOPSIS

  use Graphics::Raylib::XS ':all';

=head1 DESCRIPTION

See L<Graphics::Raylib> for a Perlish wrapper.

=head2 EXPORT

None by default.

=head2 Exportable constants

  BLEND_ADDITIVE
  BLEND_ALPHA
  BLEND_MULTIPLIED
  CAMERA_CUSTOM
  CAMERA_FIRST_PERSON
  CAMERA_FREE
  CAMERA_ORBITAL
  CAMERA_THIRD_PERSON
  COMPRESSED_ASTC_4x4_RGBA
  COMPRESSED_ASTC_8x8_RGBA
  COMPRESSED_DXT1_RGB
  COMPRESSED_DXT1_RGBA
  COMPRESSED_DXT3_RGBA
  COMPRESSED_DXT5_RGBA
  COMPRESSED_ETC1_RGB
  COMPRESSED_ETC2_EAC_RGBA
  COMPRESSED_ETC2_RGB
  COMPRESSED_PVRT_RGB
  COMPRESSED_PVRT_RGBA
  DEG2RAD
  FILTER_ANISOTROPIC_16X
  FILTER_ANISOTROPIC_4X
  FILTER_ANISOTROPIC_8X
  FILTER_BILINEAR
  FILTER_POINT
  FILTER_TRILINEAR
  FLAG_CENTERED_MODE
  FLAG_FULLSCREEN_MODE
  FLAG_MSAA_4X_HINT
  FLAG_RESIZABLE_WINDOW
  FLAG_SHOW_LOGO
  FLAG_SHOW_MOUSE_CURSOR
  FLAG_VSYNC_HINT
  GAMEPAD_PLAYER1
  GAMEPAD_PLAYER2
  GAMEPAD_PLAYER3
  GAMEPAD_PLAYER4
  GAMEPAD_PS3_AXIS_L2
  GAMEPAD_PS3_AXIS_LEFT_X
  GAMEPAD_PS3_AXIS_LEFT_Y
  GAMEPAD_PS3_AXIS_R2
  GAMEPAD_PS3_AXIS_RIGHT_X
  GAMEPAD_PS3_AXIS_RIGHT_Y
  GAMEPAD_PS3_BUTTON_CIRCLE
  GAMEPAD_PS3_BUTTON_CROSS
  GAMEPAD_PS3_BUTTON_DOWN
  GAMEPAD_PS3_BUTTON_L1
  GAMEPAD_PS3_BUTTON_L2
  GAMEPAD_PS3_BUTTON_LEFT
  GAMEPAD_PS3_BUTTON_PS
  GAMEPAD_PS3_BUTTON_R1
  GAMEPAD_PS3_BUTTON_R2
  GAMEPAD_PS3_BUTTON_RIGHT
  GAMEPAD_PS3_BUTTON_SELECT
  GAMEPAD_PS3_BUTTON_SQUARE
  GAMEPAD_PS3_BUTTON_START
  GAMEPAD_PS3_BUTTON_TRIANGLE
  GAMEPAD_PS3_BUTTON_UP
  GAMEPAD_XBOX_AXIS_LEFT_X
  GAMEPAD_XBOX_AXIS_LEFT_Y
  GAMEPAD_XBOX_AXIS_LT
  GAMEPAD_XBOX_AXIS_RIGHT_X
  GAMEPAD_XBOX_AXIS_RIGHT_Y
  GAMEPAD_XBOX_AXIS_RT
  GAMEPAD_XBOX_BUTTON_A
  GAMEPAD_XBOX_BUTTON_B
  GAMEPAD_XBOX_BUTTON_DOWN
  GAMEPAD_XBOX_BUTTON_HOME
  GAMEPAD_XBOX_BUTTON_LB
  GAMEPAD_XBOX_BUTTON_LEFT
  GAMEPAD_XBOX_BUTTON_RB
  GAMEPAD_XBOX_BUTTON_RIGHT
  GAMEPAD_XBOX_BUTTON_SELECT
  GAMEPAD_XBOX_BUTTON_START
  GAMEPAD_XBOX_BUTTON_UP
  GAMEPAD_XBOX_BUTTON_X
  GAMEPAD_XBOX_BUTTON_Y
  GESTURE_DOUBLETAP
  GESTURE_DRAG
  GESTURE_HOLD
  GESTURE_NONE
  GESTURE_PINCH_IN
  GESTURE_PINCH_OUT
  GESTURE_SWIPE_DOWN
  GESTURE_SWIPE_LEFT
  GESTURE_SWIPE_RIGHT
  GESTURE_SWIPE_UP
  GESTURE_TAP
  HMD_DEFAULT_DEVICE
  HMD_FOVE_VR
  HMD_GOOGLE_CARDBOARD
  HMD_OCULUS_RIFT_CV1
  HMD_OCULUS_RIFT_DK2
  HMD_RAZER_OSVR
  HMD_SAMSUNG_GEAR_VR
  HMD_SONY_PLAYSTATION_VR
  HMD_VALVE_HTC_VIVE
  KEY_A
  KEY_B
  KEY_BACK
  KEY_BACKSPACE
  KEY_C
  KEY_D
  KEY_DOWN
  KEY_E
  KEY_EIGHT
  KEY_ENTER
  KEY_ESCAPE
  KEY_F
  KEY_F1
  KEY_F10
  KEY_F11
  KEY_F12
  KEY_F2
  KEY_F3
  KEY_F4
  KEY_F5
  KEY_F6
  KEY_F7
  KEY_F8
  KEY_F9
  KEY_FIVE
  KEY_FOUR
  KEY_G
  KEY_H
  KEY_I
  KEY_J
  KEY_K
  KEY_L
  KEY_LEFT
  KEY_LEFT_ALT
  KEY_LEFT_CONTROL
  KEY_LEFT_SHIFT
  KEY_M
  KEY_MENU
  KEY_N
  KEY_NINE
  KEY_O
  KEY_ONE
  KEY_P
  KEY_Q
  KEY_R
  KEY_RIGHT
  KEY_RIGHT_ALT
  KEY_RIGHT_CONTROL
  KEY_RIGHT_SHIFT
  KEY_S
  KEY_SEVEN
  KEY_SIX
  KEY_SPACE
  KEY_T
  KEY_THREE
  KEY_TWO
  KEY_U
  KEY_UP
  KEY_V
  KEY_VOLUME_DOWN
  KEY_VOLUME_UP
  KEY_W
  KEY_X
  KEY_Y
  KEY_Z
  KEY_ZERO
  LIGHT_DIRECTIONAL
  LIGHT_POINT
  LIGHT_SPOT
  MAX_TOUCH_POINTS
  MOUSE_LEFT_BUTTON
  MOUSE_MIDDLE_BUTTON
  MOUSE_RIGHT_BUTTON
  RAD2DEG
  UNCOMPRESSED_GRAYSCALE
  UNCOMPRESSED_GRAY_ALPHA
  UNCOMPRESSED_R4G4B4A4
  UNCOMPRESSED_R5G5B5A1
  UNCOMPRESSED_R5G6B5
  UNCOMPRESSED_R8G8B8
  UNCOMPRESSED_R8G8B8A8
  WRAP_CLAMP
  WRAP_MIRROR
  WRAP_REPEAT
  false
  true

=head2 Exportable functions

  void Begin2dMode(Camera2D camera)
  void Begin3dMode(Camera camera)
  void BeginBlendMode(int mode)
  void BeginDrawing(void)
  void BeginShaderMode(Shader shader)
  void BeginTextureMode(RenderTexture2D target)
  BoundingBox CalculateBoundingBox(Mesh mesh)
  int CheckCollisionBoxSphere(BoundingBox box, Vector3 centerSphere, float radiusSphere)
  int CheckCollisionBoxes(BoundingBox box1, BoundingBox box2)
  int CheckCollisionCircleRec(Vector2 center, float radius, Rectangle rec)
  int CheckCollisionCircles(Vector2 center1, float radius1, Vector2 center2, float radius2)
  int CheckCollisionPointCircle(Vector2 point, Vector2 center, float radius)
  int CheckCollisionPointRec(Vector2 point, Rectangle rec)
  int CheckCollisionPointTriangle(Vector2 point, Vector2 p1, Vector2 p2, Vector2 p3)
  int CheckCollisionRayBox(Ray ray, BoundingBox box)
  int CheckCollisionRaySphere(Ray ray, Vector3 spherePosition, float sphereRadius)
  int CheckCollisionRaySphereEx(Ray ray, Vector3 spherePosition, float sphereRadius, Vector3 *collisionPoint)
  int CheckCollisionRecs(Rectangle rec1, Rectangle rec2)
  int CheckCollisionSpheres(Vector3 centerA, float radiusA, Vector3 centerB, float radiusB)
  void ClearBackground(Color color)
  void ClearDroppedFiles(void)
  void CloseAudioDevice(void)
  void CloseAudioStream(AudioStream stream)
  void CloseVrDevice(void)
  void CloseWindow(void)
  float *ColorToFloat(Color color)
  Light CreateLight(int type, Vector3 position, Color diffuse)
  void DestroyLight(Light light)
  void DisableCursor(void)
  void DrawBillboard(Camera camera, Texture2D texture, Vector3 center, float size, Color tint)
  void DrawBillboardRec(Camera camera, Texture2D texture, Rectangle sourceRec, Vector3 center, float size, Color tint)
  void DrawBoundingBox(BoundingBox box, Color color)
  void DrawCircle(int centerX, int centerY, float radius, Color color)
  void DrawCircle3D(Vector3 center, float radius, Vector3 rotationAxis, float rotationAngle, Color color)
  void DrawCircleGradient(int centerX, int centerY, float radius, Color color1, Color color2)
  void DrawCircleLines(int centerX, int centerY, float radius, Color color)
  void DrawCircleV(Vector2 center, float radius, Color color)
  void DrawCube(Vector3 position, float width, float height, float length, Color color)
  void DrawCubeTexture(Texture2D texture, Vector3 position, float width, float height, float length, Color color)
  void DrawCubeV(Vector3 position, Vector3 size, Color color)
  void DrawCubeWires(Vector3 position, float width, float height, float length, Color color)
  void DrawCylinder(Vector3 position, float radiusTop, float radiusBottom, float height, int slices, Color color)
  void DrawCylinderWires(Vector3 position, float radiusTop, float radiusBottom, float height, int slices, Color color)
  void DrawFPS(int posX, int posY)
  void DrawGizmo(Vector3 position)
  void DrawGrid(int slices, float spacing)
  void DrawLight(Light light)
  void DrawLine(int startPosX, int startPosY, int endPosX, int endPosY, Color color)
  void DrawLine3D(Vector3 startPos, Vector3 endPos, Color color)
  void DrawLineV(Vector2 startPos, Vector2 endPos, Color color)
  void DrawModel(Model model, Vector3 position, float scale, Color tint)
  void DrawModelEx(Model model, Vector3 position, Vector3 rotationAxis, float rotationAngle, Vector3 scale, Color tint)
  void DrawModelWires(Model model, Vector3 position, float scale, Color tint)
  void DrawModelWiresEx(Model model, Vector3 position, Vector3 rotationAxis, float rotationAngle, Vector3 scale, Color tint)
  void DrawPixel(int posX, int posY, Color color)
  void DrawPixelV(Vector2 position, Color color)
  void DrawPlane(Vector3 centerPos, Vector2 size, Color color)
  void DrawPoly(Vector2 center, int sides, float radius, float rotation, Color color)
  void DrawPolyEx(Vector2 *points, int numPoints, Color color)
  void DrawPolyExLines(Vector2 *points, int numPoints, Color color)
  void DrawRay(Ray ray, Color color)
  void DrawRectangle(int posX, int posY, int width, int height, Color color)
  void DrawRectangleGradient(int posX, int posY, int width, int height, Color color1, Color color2)
  void DrawRectangleLines(int posX, int posY, int width, int height, Color color)
  void DrawRectangleRec(Rectangle rec, Color color)
  void DrawRectangleV(Vector2 position, Vector2 size, Color color)
  void DrawSphere(Vector3 centerPos, float radius, Color color)
  void DrawSphereEx(Vector3 centerPos, float radius, int rings, int slices, Color color)
  void DrawSphereWires(Vector3 centerPos, float radius, int rings, int slices, Color color)
  void DrawText(const char *text, int posX, int posY, int fontSize, Color color)
  void DrawTextEx(SpriteFont spriteFont, const char* text, Vector2 position,
                float fontSize, int spacing, Color tint)
  void DrawTexture(Texture2D texture, int posX, int posY, Color tint)
  void DrawTextureEx(Texture2D texture, Vector2 position, float rotation, float scale, Color tint)
  void DrawTexturePro(Texture2D texture, Rectangle sourceRec, Rectangle destRec, Vector2 origin,
                    float rotation, Color tint)
  void DrawTextureRec(Texture2D texture, Rectangle sourceRec, Vector2 position, Color tint)
  void DrawTextureV(Texture2D texture, Vector2 position, Color tint)
  void DrawSOSTexture(void)
  void DrawTriangle(Vector2 v1, Vector2 v2, Vector2 v3, Color color)
  void DrawTriangleLines(Vector2 v1, Vector2 v2, Vector2 v3, Color color)
  void EnableCursor(void)
  void End2dMode(void)
  void End3dMode(void)
  void EndBlendMode(void)
  void EndDrawing(void)
  void EndShaderMode(void)
  void EndTextureMode(void)
  Color Fade(Color color, float alpha)
  const char *FormatText(const char *text, ...)
  void GenTextureMipmaps(Texture2D *texture)
  Matrix GetCameraMatrix(Camera camera)
  Rectangle GetCollisionRec(Rectangle rec1, Rectangle rec2)
  Color GetColor(int hexValue)
  SpriteFont GetDefaultFont(void)
  Shader GetDefaultShader(void)
  Texture2D GetDefaultTexture(void)
  float GetFPS(void)
  float GetFrameTime(void)
  int GetGamepadAxisCount(int gamepad)
  float GetGamepadAxisMovement(int gamepad, int axis)
  int GetGamepadButtonPressed(void)
  const char *GetGamepadName(int gamepad)
  int GetGestureDetected(void)
  float GetGestureDragAngle(void)
  Vector2 GetGestureDragVector(void)
  float GetGestureHoldDuration(void)
  float GetGesturePinchAngle(void)
  Vector2 GetGesturePinchVector(void)
  int GetHexValue(Color color)
  Color *GetImageData(Image image)
  int GetKeyPressed(void)
  Vector2 GetMousePosition(void)
  Ray GetMouseRay(Vector2 mousePosition, Camera camera)
  int GetMouseWheelMove(void)
  int GetMouseX(void)
  int GetMouseY(void)
  float GetMusicTimeLength(Music music)
  float GetMusicTimePlayed(Music music)
  int GetRandomValue(int min, int max)
  int GetScreenHeight(void)
  int GetScreenWidth(void)
  int GetShaderLocation(Shader shader, const char *uniformName)
  Shader GetStandardShader(void)
  Image GetTextureData(Texture2D texture)
  int GetTouchPointsCount(void)
  Vector2 GetTouchPosition(int index)
  int GetTouchX(void)
  int GetTouchY(void)
  float *GetWaveData(Wave wave)
  Vector2 GetWorldToScreen(Vector3 position, Camera camera)
  void HideCursor(void)
  void ImageAlphaMask(Image *image, Image alphaMask)
  void ImageColorBrightness(Image *image, int brightness)
  void ImageColorContrast(Image *image, float contrast)
  void ImageColorGrayscale(Image *image)
  void ImageColorInvert(Image *image)
  void ImageColorTint(Image *image, Color color)
  Image ImageCopy(Image image)
  void ImageCrop(Image *image, Rectangle crop)
  void ImageDither(Image *image, int rBpp, int gBpp, int bBpp, int aBpp)
  void ImageDraw(Image *dst, Image src, Rectangle srcRec, Rectangle dstRec)
  void ImageDrawText(Image *dst, Vector2 position, const char *text, int fontSize, Color color)
  void ImageDrawTextEx(Image *dst, Vector2 position, SpriteFont font, const char *text, float fontSize, int spacing, Color color)
  void ImageFlipHorizontal(Image *image)
  void ImageFlipVertical(Image *image)
  void ImageFormat(Image *image, int newFormat)
  void ImageResize(Image *image, int newWidth, int newHeight)
  void ImageResizeNN(Image *image,int newWidth,int newHeight)
  Image ImageText(const char *text, int fontSize, Color color)
  Image ImageTextEx(SpriteFont font, const char *text, float fontSize, int spacing, Color tint)
  void ImageToPOT(Image *image, Color fillColor)
  void InitAudioDevice(void)
  AudioStream InitAudioStream(unsigned int sampleRate,
                                  unsigned int sampleSize,
                                  unsigned int channels)
  void InitVrDevice(int vdDevice)
  void InitWindow(int width, int height, const char *title)
  int IsAudioBufferProcessed(AudioStream stream)
  int IsAudioDeviceReady(void)
  int IsCursorHidden(void)
  int IsFileDropped(void)
  int IsGamepadAvailable(int gamepad)
  int IsGamepadButtonDown(int gamepad, int button)
  int IsGamepadButtonPressed(int gamepad, int button)
  int IsGamepadButtonReleased(int gamepad, int button)
  int IsGamepadButtonUp(int gamepad, int button)
  int IsGamepadName(int gamepad, const char *name)
  int IsGestureDetected(int gesture)
  int IsKeyDown(int key)
  int IsKeyPressed(int key)
  int IsKeyReleased(int key)
  int IsKeyUp(int key)
  int IsMouseButtonDown(int button)
  int IsMouseButtonPressed(int button)
  int IsMouseButtonReleased(int button)
  int IsMouseButtonUp(int button)
  int IsMusicPlaying(Music music)
  int IsSoundPlaying(Sound sound)
  int IsVrDeviceReady(void)
  int IsVrSimulator(void)
  int IsWindowMinimized(void)
  Model LoadCubicmap(Image cubicmap)
  Material LoadDefaultMaterial(void)
  Model LoadHeightmap(Image heightmap, Vector3 size)
  Image LoadImage(const char *fileName)
  Image LoadImageEx(Color *pixels, int width, int height)
  Image LoadImageFromRES(const char *rresName, int resId)
  Image LoadImageRaw(const char *fileName, int width, int height, int format, int headerSize)
  Image LoadSOSImage(void)
  Image LoadImageFromAV(SV *array_ref, SV *color_cb, int width, int height)
  Image LoadImageFromAV_uninitialized_mem(SV *array_ref, SV *color_cb, int width, int height)
  Material LoadMaterial(const char *fileName)
  Model LoadModel(const char *fileName)
  Model LoadModelEx(Mesh data, int dynamic)
  Model LoadModelFromRES(const char *rresName, int resId)
  Music LoadMusicStream(const char *fileName)
  RenderTexture2D LoadRenderTexture(int width, int height)
  Shader LoadShader(char *vsFileName, char *fsFileName)
  Sound LoadSound(const char *fileName)
  Sound LoadSoundFromRES(const char *rresName, int resId)
  Sound LoadSoundFromWave(Wave wave)
  SpriteFont LoadSpriteFont(const char *fileName)
  SpriteFont LoadSpriteFontTTF(const char *fileName, int fontSize, int numChars, int *fontChars)
  Material LoadStandardMaterial(void)
  Texture2D LoadTexture(const char *fileName)
  Texture2D LoadTextureEx(void *data, int width, int height, int textureFormat)
  Texture2D LoadTextureFromImage(Image image)
  Texture2D LoadTextureFromRES(const char *rresName, int resId)
  Wave LoadWave(const char *fileName)
  Wave LoadWaveEx(float *data, int sampleCount, int sampleRate, int sampleSize, int channels)
  float *MatrixToFloat(Matrix mat)
  int MeasureText(const char *text, int fontSize)
  Vector2 MeasureTextEx(SpriteFont spriteFont, const char *text, float fontSize, int spacing)
  void PauseAudioStream(AudioStream stream)
  void PauseMusicStream(Music music)
  void PauseSound(Sound sound)
  void PlayAudioStream(AudioStream stream)
  void PlayMusicStream(Music music)
  void PlaySound(Sound sound)
  void ResumeAudioStream(AudioStream stream)
  void ResumeMusicStream(Music music)
  void ResumeSound(Sound sound)
  void SetCameraAltControl(int altKey)
  void SetCameraMode(Camera camera, int mode)
  void SetCameraMoveControls(int frontKey, int backKey,
                                 int rightKey, int leftKey,
                                 int upKey, int downKey)
  void SetCameraPanControl(int panKey)
  void SetCameraSmoothZoomControl(int szKey)
  void SetConfigFlags(char flags)
  void SetExitKey(int key)
  void SetGesturesEnabled(unsigned int gestureFlags)
  void SetMatrixModelview(Matrix view)
  void SetMatrixProjection(Matrix proj)
  void SetMousePosition(Vector2 position)
  void SetMusicPitch(Music music, float pitch)
  void SetMusicVolume(Music music, float volume)
  void SetShaderValue(Shader shader, int uniformLoc, float *value, int size)
  void SetShaderValueMatrix(Shader shader, int uniformLoc, Matrix mat)
  void SetShaderValuei(Shader shader, int uniformLoc, int *value, int size)
  void SetSoundPitch(Sound sound, float pitch)
  void SetSoundVolume(Sound sound, float volume)
  void SetTargetFPS(int fps)
  void SetTextureFilter(Texture2D texture, int filterMode)
  void SetTextureWrap(Texture2D texture, int wrapMode)
  void ShowCursor(void)
  void ShowLogo(void)
  void StopAudioStream(AudioStream stream)
  void StopMusicStream(Music music)
  void StopSound(Sound sound)
  int StorageLoadValue(int position)
  void StorageSaveValue(int position, int value)
  const char *SubText(const char *text, int position, int length)
  void ToggleFullscreen(void)
  void ToggleVrMode(void)
  void UnloadImage(Image image)
  void UnloadMaterial(Material material)
  void UnloadModel(Model model)
  void UnloadMusicStream(Music music)
  void UnloadRenderTexture(RenderTexture2D target)
  void UnloadShader(Shader shader)
  void UnloadSound(Sound sound)
  void UnloadSpriteFont(SpriteFont spriteFont)
  void UnloadTexture(Texture2D texture)
  void UnloadWave(Wave wave)
  void UpdateAudioStream(AudioStream stream, void *data, int numSamples)
  void UpdateCamera(Camera *camera)
  void UpdateMusicStream(Music music)
  void UpdateSound(Sound sound, void *data, int numSamples)
  void UpdateTexture(Texture2D texture, void *pixels)
  void UpdateTextureFromImage(Texture2D texture, Image image)
  void UpdateVrTracking(Camera *camera)
  float *VectorToFloat(Vector3 vec)
  Wave WaveCopy(Wave wave)
  void WaveCrop(Wave *wave, int initSample, int finalSample)
  void WaveFormat(Wave *wave, int sampleRate, int sampleSize, int channels)
  int WindowShouldClose(void)



=head1 SEE ALSO

L<http://www.raylib.com>

L<Alien::raylib>

=head1 AUTHOR

Ahmad Fatoum, E<lt>ahmad@a3f.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
