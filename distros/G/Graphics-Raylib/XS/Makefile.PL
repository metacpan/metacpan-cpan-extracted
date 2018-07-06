use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# XXX uncomment the Acme::Alien::__cpu_model lines if it fails to build
#     because of a missing __cpu_model symbol
#use Acme::Alien::__cpu_model;
use Alien::raylib;

my @LIBS = (
    Alien::raylib->libs_static,
#   Acme::Alien::__cpu_model,
);
my @other_ldflags;
#@other_ldflags = ('-L/usr/local/Cellar/glfw/3.2.1/lib -lglfw');
if ($^O eq 'darwin') { # fixed upstream in ExtUtils::MakeMaker v7.31_04
    my @frameworks;
    for (@LIBS) { push @frameworks, $1 while(s/(-framework\s*\S+|-F\s*\S+)//); }
    @other_ldflags = (
        dynamic_lib =>  { OTHERLDFLAGS => "@frameworks" },
    );
}
WriteMakefile(
    NAME              => 'Graphics::Raylib::XS',
    VERSION_FROM      => 'lib/Graphics/Raylib/XS.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Graphics/Raylib/XS.pm', # retrieve abstract from module
    AUTHOR            => 'Ahmad Fatoum <ahmad@a3f.at>',
    LICENSE           => 'perl',
    DEFINE            => '-Wno-format',
    LIBS              => [ @LIBS ],
    @other_ldflags,
    INC               => Alien::raylib->cflags_static,
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(DEG2RAD FLAG_FULLSCREEN_MODE FLAG_MSAA_4X_HINT FLAG_SHOW_LOGO
		 FLAG_VSYNC_HINT FLAG_WINDOW_RESIZABLE FLAG_WINDOW_TRANSPARENT
		 FLAG_WINDOW_UNDECORATED GAMEPAD_PLAYER1 GAMEPAD_PLAYER2
		 GAMEPAD_PLAYER3 GAMEPAD_PLAYER4 GAMEPAD_PS3_AXIS_L2
		 GAMEPAD_PS3_AXIS_LEFT_X GAMEPAD_PS3_AXIS_LEFT_Y
		 GAMEPAD_PS3_AXIS_R2 GAMEPAD_PS3_AXIS_RIGHT_X
		 GAMEPAD_PS3_AXIS_RIGHT_Y GAMEPAD_PS3_BUTTON_CIRCLE
		 GAMEPAD_PS3_BUTTON_CROSS GAMEPAD_PS3_BUTTON_DOWN
		 GAMEPAD_PS3_BUTTON_L1 GAMEPAD_PS3_BUTTON_L2
		 GAMEPAD_PS3_BUTTON_LEFT GAMEPAD_PS3_BUTTON_PS
		 GAMEPAD_PS3_BUTTON_R1 GAMEPAD_PS3_BUTTON_R2
		 GAMEPAD_PS3_BUTTON_RIGHT GAMEPAD_PS3_BUTTON_SELECT
		 GAMEPAD_PS3_BUTTON_SQUARE GAMEPAD_PS3_BUTTON_START
		 GAMEPAD_PS3_BUTTON_TRIANGLE GAMEPAD_PS3_BUTTON_UP
		 GAMEPAD_XBOX_AXIS_LEFT_X GAMEPAD_XBOX_AXIS_LEFT_Y
		 GAMEPAD_XBOX_AXIS_LT GAMEPAD_XBOX_AXIS_RIGHT_X
		 GAMEPAD_XBOX_AXIS_RIGHT_Y GAMEPAD_XBOX_AXIS_RT
		 GAMEPAD_XBOX_BUTTON_A GAMEPAD_XBOX_BUTTON_B
		 GAMEPAD_XBOX_BUTTON_DOWN GAMEPAD_XBOX_BUTTON_HOME
		 GAMEPAD_XBOX_BUTTON_LB GAMEPAD_XBOX_BUTTON_LEFT
		 GAMEPAD_XBOX_BUTTON_RB GAMEPAD_XBOX_BUTTON_RIGHT
		 GAMEPAD_XBOX_BUTTON_SELECT GAMEPAD_XBOX_BUTTON_START
		 GAMEPAD_XBOX_BUTTON_UP GAMEPAD_XBOX_BUTTON_X
		 GAMEPAD_XBOX_BUTTON_Y KEY_A KEY_B KEY_BACK KEY_BACKSLASH
		 KEY_BACKSPACE KEY_C KEY_CAPS_LOCK KEY_D KEY_DELETE KEY_DOWN
		 KEY_E KEY_EIGHT KEY_END KEY_ENTER KEY_ESCAPE KEY_F KEY_F1
		 KEY_F10 KEY_F11 KEY_F12 KEY_F2 KEY_F3 KEY_F4 KEY_F5 KEY_F6
		 KEY_F7 KEY_F8 KEY_F9 KEY_FIVE KEY_FOUR KEY_G KEY_GRAVE KEY_H
		 KEY_HOME KEY_I KEY_INSERT KEY_J KEY_K KEY_L KEY_LEFT
		 KEY_LEFT_ALT KEY_LEFT_CONTROL KEY_LEFT_SHIFT KEY_M KEY_MENU
		 KEY_N KEY_NINE KEY_NUM_LOCK KEY_O KEY_ONE KEY_P KEY_PAGE_DOWN
		 KEY_PAGE_UP KEY_PAUSE KEY_PRINT_SCREEN KEY_Q KEY_R KEY_RIGHT
		 KEY_RIGHT_ALT KEY_RIGHT_CONTROL KEY_RIGHT_SHIFT KEY_S
		 KEY_SCROLL_LOCK KEY_SEVEN KEY_SIX KEY_SLASH KEY_SPACE KEY_T
		 KEY_TAB KEY_THREE KEY_TWO KEY_U KEY_UP KEY_V KEY_VOLUME_DOWN
		 KEY_VOLUME_UP KEY_W KEY_X KEY_Y KEY_Z KEY_ZERO LOC_MAP_DIFFUSE
		 LOC_MAP_SPECULAR MAP_DIFFUSE MAP_SPECULAR MAX_MATERIAL_MAPS
		 MAX_SHADER_LOCATIONS MAX_TOUCH_POINTS MOUSE_LEFT_BUTTON
		 MOUSE_MIDDLE_BUTTON MOUSE_RIGHT_BUTTON RAD2DEG),
              {name=>"BLEND_ADDITIVE", macro=>"1"},
              {name=>"BLEND_ALPHA", macro=>"1"},
              {name=>"BLEND_MULTIPLIED", macro=>"1"},
              {name=>"CAMERA_CUSTOM", macro=>"1"},
              {name=>"CAMERA_FIRST_PERSON", macro=>"1"},
              {name=>"CAMERA_FREE", macro=>"1"},
              {name=>"CAMERA_ORBITAL", macro=>"1"},
              {name=>"CAMERA_ORTHOGRAPHIC", macro=>"1"},
              {name=>"CAMERA_PERSPECTIVE", macro=>"1"},
              {name=>"CAMERA_THIRD_PERSON", macro=>"1"},
              {name=>"COMPRESSED_ASTC_4x4_RGBA", macro=>"1"},
              {name=>"COMPRESSED_ASTC_8x8_RGBA", macro=>"1"},
              {name=>"COMPRESSED_DXT1_RGB", macro=>"1"},
              {name=>"COMPRESSED_DXT1_RGBA", macro=>"1"},
              {name=>"COMPRESSED_DXT3_RGBA", macro=>"1"},
              {name=>"COMPRESSED_DXT5_RGBA", macro=>"1"},
              {name=>"COMPRESSED_ETC1_RGB", macro=>"1"},
              {name=>"COMPRESSED_ETC2_EAC_RGBA", macro=>"1"},
              {name=>"COMPRESSED_ETC2_RGB", macro=>"1"},
              {name=>"COMPRESSED_PVRT_RGB", macro=>"1"},
              {name=>"COMPRESSED_PVRT_RGBA", macro=>"1"},
              {name=>"FILTER_ANISOTROPIC_16X", macro=>"1"},
              {name=>"FILTER_ANISOTROPIC_4X", macro=>"1"},
              {name=>"FILTER_ANISOTROPIC_8X", macro=>"1"},
              {name=>"FILTER_BILINEAR", macro=>"1"},
              {name=>"FILTER_POINT", macro=>"1"},
              {name=>"FILTER_TRILINEAR", macro=>"1"},
              {name=>"GESTURE_DOUBLETAP", macro=>"1"},
              {name=>"GESTURE_DRAG", macro=>"1"},
              {name=>"GESTURE_HOLD", macro=>"1"},
              {name=>"GESTURE_NONE", macro=>"1"},
              {name=>"GESTURE_PINCH_IN", macro=>"1"},
              {name=>"GESTURE_PINCH_OUT", macro=>"1"},
              {name=>"GESTURE_SWIPE_DOWN", macro=>"1"},
              {name=>"GESTURE_SWIPE_LEFT", macro=>"1"},
              {name=>"GESTURE_SWIPE_RIGHT", macro=>"1"},
              {name=>"GESTURE_SWIPE_UP", macro=>"1"},
              {name=>"GESTURE_TAP", macro=>"1"},
              {name=>"HMD_DEFAULT_DEVICE", macro=>"1"},
              {name=>"HMD_OCULUS_GO", macro=>"1"},
              {name=>"HMD_OCULUS_RIFT_CV1", macro=>"1"},
              {name=>"HMD_OCULUS_RIFT_DK2", macro=>"1"},
              {name=>"HMD_SONY_PSVR", macro=>"1"},
              {name=>"HMD_VALVE_HTC_VIVE", macro=>"1"},
              {name=>"LOC_COLOR_AMBIENT", macro=>"1"},
              {name=>"LOC_COLOR_DIFFUSE", macro=>"1"},
              {name=>"LOC_COLOR_SPECULAR", macro=>"1"},
              {name=>"LOC_MAP_ALBEDO", macro=>"1"},
              {name=>"LOC_MAP_BRDF", macro=>"1"},
              {name=>"LOC_MAP_CUBEMAP", macro=>"1"},
              {name=>"LOC_MAP_EMISSION", macro=>"1"},
              {name=>"LOC_MAP_HEIGHT", macro=>"1"},
              {name=>"LOC_MAP_IRRADIANCE", macro=>"1"},
              {name=>"LOC_MAP_METALNESS", macro=>"1"},
              {name=>"LOC_MAP_NORMAL", macro=>"1"},
              {name=>"LOC_MAP_OCCLUSION", macro=>"1"},
              {name=>"LOC_MAP_PREFILTER", macro=>"1"},
              {name=>"LOC_MAP_ROUGHNESS", macro=>"1"},
              {name=>"LOC_MATRIX_MODEL", macro=>"1"},
              {name=>"LOC_MATRIX_MVP", macro=>"1"},
              {name=>"LOC_MATRIX_PROJECTION", macro=>"1"},
              {name=>"LOC_MATRIX_VIEW", macro=>"1"},
              {name=>"LOC_VECTOR_VIEW", macro=>"1"},
              {name=>"LOC_VERTEX_COLOR", macro=>"1"},
              {name=>"LOC_VERTEX_NORMAL", macro=>"1"},
              {name=>"LOC_VERTEX_POSITION", macro=>"1"},
              {name=>"LOC_VERTEX_TANGENT", macro=>"1"},
              {name=>"LOC_VERTEX_TEXCOORD01", macro=>"1"},
              {name=>"LOC_VERTEX_TEXCOORD02", macro=>"1"},
              {name=>"LOG_DEBUG", macro=>"1"},
              {name=>"LOG_ERROR", macro=>"1"},
              {name=>"LOG_INFO", macro=>"1"},
              {name=>"LOG_OTHER", macro=>"1"},
              {name=>"LOG_WARNING", macro=>"1"},
              {name=>"MAP_ALBEDO", macro=>"1"},
              {name=>"MAP_BRDF", macro=>"1"},
              {name=>"MAP_CUBEMAP", macro=>"1"},
              {name=>"MAP_EMISSION", macro=>"1"},
              {name=>"MAP_HEIGHT", macro=>"1"},
              {name=>"MAP_IRRADIANCE", macro=>"1"},
              {name=>"MAP_METALNESS", macro=>"1"},
              {name=>"MAP_NORMAL", macro=>"1"},
              {name=>"MAP_OCCLUSION", macro=>"1"},
              {name=>"MAP_PREFILTER", macro=>"1"},
              {name=>"MAP_ROUGHNESS", macro=>"1"},
              {name=>"UNCOMPRESSED_GRAYSCALE", macro=>"1"},
              {name=>"UNCOMPRESSED_GRAY_ALPHA", macro=>"1"},
              {name=>"UNCOMPRESSED_R32", macro=>"1"},
              {name=>"UNCOMPRESSED_R32G32B32", macro=>"1"},
              {name=>"UNCOMPRESSED_R32G32B32A32", macro=>"1"},
              {name=>"UNCOMPRESSED_R4G4B4A4", macro=>"1"},
              {name=>"UNCOMPRESSED_R5G5B5A1", macro=>"1"},
              {name=>"UNCOMPRESSED_R5G6B5", macro=>"1"},
              {name=>"UNCOMPRESSED_R8G8B8", macro=>"1"},
              {name=>"UNCOMPRESSED_R8G8B8A8", macro=>"1"},
              {name=>"WRAP_CLAMP", macro=>"1"},
              {name=>"WRAP_MIRROR", macro=>"1"},
              {name=>"WRAP_REPEAT", macro=>"1"},
              {name=>"false", macro=>"1"},
              {name=>"true", macro=>"1"});
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Graphics::Raylib::XS',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
