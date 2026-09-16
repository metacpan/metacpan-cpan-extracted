package EV::WebKit::Fingerprint;
use v5.10; use strict; use warnings;
our $VERSION = '0.04';
use File::ShareDir ();
use Carp ();
use Glib ();
use Cwd ();

# The installed extension directory holds ONLY evwk_fp.so, so it can be handed
# straight to set_web_process_extensions_directory. Located via File::ShareDir
# in an installed dist, or the in-tree share/ during development/testing.
my $SO_DIR;
sub _so_dir {
    return $SO_DIR if defined $SO_DIR;
    my @cand;
    # Prefer an in-tree build (blib during `make test`, or a plain checkout) over
    # an installed copy, so testing a checkout never resolves a stale
    # already-installed .so. Cwd::getcwd, not $ENV{PWD} (a shell var that is unset
    # under service managers and stale after any chdir).
    my $cwd = eval { Cwd::getcwd() };
    if (defined $cwd) {
        # share/wext BEFORE blib: the Makefile rule compiles into share/wext and
        # blib's is a COPY made afterwards, so preferring the copy left a
        # checkout that already had a blib silently running the OLD extension
        # whenever only the .so was rebuilt. Both in-tree paths still precede
        # File::ShareDir, so a checkout still never resolves an installed .so.
        push @cand, "$cwd/share/wext", "$cwd/blib/lib/auto/share/dist/EV-WebKit/wext";
    }
    my $dist = eval { File::ShareDir::dist_dir('EV-WebKit') };
    push @cand, "$dist/wext" if defined $dist;
    for my $d (@cand) { if (-e "$d/evwk_fp.so") { return $SO_DIR = $d } }
    return $SO_DIR = '';   # cached "not found"
}

sub available { my $d = _so_dir(); return $d ne '' ? 1 : 0 }

# The closed set of DOM feature-presence stub groups the extension's FEATURES_JS
# knows how to install. Keep in sync with that switch.
our @FEATURE_GROUPS = qw(connection storage battery usb bluetooth hid serial scheduling rtc);

# Canonical per-GPU-family WebGL capability sets. pname keys are the JS WebGL
# numeric constants (decimal); values are a number, a string, or [n,n] for a
# 2-vector. VENDOR(7936)/RENDERER(7937) are the MASKED values real Chrome/Safari
# report; the UNMASKED pair comes from each preset's webgl_vendor/webgl_renderer
# via the existing string spoof. These are the canonical set for the family, not
# a per-driver capture -- a fingerprinter with a per-driver database could still
# find a mismatch (documented in the Ceiling POD).
my %WEBGL_ANGLE_NVIDIA = (
    params1 => {
        7936 => 'WebKit', 7937 => 'WebKit WebGL',
        7938 => 'WebGL 1.0 (OpenGL ES 2.0 Chromium)',
        35724 => 'WebGL GLSL ES 1.0 (OpenGL ES GLSL ES 1.0 Chromium)',
        3379 => 16384, 34076 => 16384, 34024 => 16384, 3386 => [32767,32767],
        34921 => 16, 36347 => 4096, 36348 => 30, 36349 => 1024,
        35660 => 16, 34930 => 16, 35661 => 32,
        33902 => [1,1], 33901 => [1,1024], 34047 => 16,
    },
    params2 => {
        # A WebGL2 context MUST report 2.0 strings: params1 (WebGL1) is merged
        # under params2, so these override the 1.0 pair for a webgl2 context.
        7938 => 'WebGL 2.0 (OpenGL ES 3.0 Chromium)',
        35724 => 'WebGL GLSL ES 3.00 (OpenGL ES GLSL ES 3.0 Chromium)',
        32883 => 2048, 35071 => 2048, 36063 => 8, 34852 => 8, 36183 => 8,
        35376 => 65536, 34045 => 2, 36203 => 4294967294,
        35373 => 12, 35371 => 12, 35375 => 24, 35374 => 24,
        # ES3 requires *_VECTORS == *_COMPONENTS/4; params1 has vertex=4096,
        # fragment=1024, varying=30 vectors, so these must be 4x those.
        35658 => 16384, 35657 => 4096, 35659 => 120, 37157 => 120, 37154 => 120,
    },
    extensions1 => [qw(
        ANGLE_instanced_arrays EXT_blend_minmax EXT_clip_control
        EXT_color_buffer_half_float EXT_depth_clamp EXT_disjoint_timer_query
        EXT_float_blend EXT_frag_depth EXT_polygon_offset_clamp EXT_shader_texture_lod
        EXT_texture_compression_bptc EXT_texture_compression_rgtc
        EXT_texture_filter_anisotropic EXT_texture_mirror_clamp_to_edge EXT_sRGB
        KHR_parallel_shader_compile OES_element_index_uint OES_fbo_render_mipmap
        OES_standard_derivatives OES_texture_float OES_texture_float_linear
        OES_texture_half_float OES_texture_half_float_linear OES_vertex_array_object
        WEBGL_blend_func_extended WEBGL_color_buffer_float
        WEBGL_compressed_texture_s3tc WEBGL_compressed_texture_s3tc_srgb
        WEBGL_debug_renderer_info WEBGL_debug_shaders WEBGL_depth_texture
        WEBGL_draw_buffers WEBGL_lose_context WEBGL_multi_draw WEBGL_polygon_mode
    )],
    extensions2 => [qw(
        EXT_clip_control EXT_color_buffer_float EXT_color_buffer_half_float
        EXT_conservative_depth EXT_depth_clamp EXT_disjoint_timer_query_webgl2
        EXT_float_blend EXT_polygon_offset_clamp EXT_render_snorm
        EXT_texture_compression_bptc EXT_texture_compression_rgtc
        EXT_texture_filter_anisotropic EXT_texture_mirror_clamp_to_edge
        EXT_texture_norm16 KHR_parallel_shader_compile
        NV_shader_noperspective_interpolation OES_draw_buffers_indexed
        OES_sample_variables OES_shader_multisample_interpolation
        OES_texture_float_linear OVR_multiview2 WEBGL_blend_func_extended
        WEBGL_clip_cull_distance WEBGL_compressed_texture_s3tc
        WEBGL_compressed_texture_s3tc_srgb WEBGL_debug_renderer_info
        WEBGL_debug_shaders WEBGL_lose_context WEBGL_multi_draw WEBGL_polygon_mode
        WEBGL_provoking_vertex WEBGL_stencil_texturing
    )],
    precision => {   # "shaderType.precisionType" -> [rangeMin,rangeMax,precision]
        'VERTEX.HIGH_FLOAT'    => [127,127,23], 'VERTEX.MEDIUM_FLOAT'   => [127,127,23],
        'VERTEX.LOW_FLOAT'     => [127,127,23], 'FRAGMENT.HIGH_FLOAT'   => [127,127,23],
        'FRAGMENT.MEDIUM_FLOAT'=> [127,127,23], 'FRAGMENT.LOW_FLOAT'    => [127,127,23],
        # every shader/precision combination must be listed, or the unlisted ones
        # fall through and report the REAL host precision alongside spoofed ones
        'VERTEX.HIGH_INT'      => [31,30,0],    'FRAGMENT.HIGH_INT'     => [31,30,0],
        'VERTEX.MEDIUM_INT'    => [31,30,0],    'FRAGMENT.MEDIUM_INT'   => [31,30,0],
        'VERTEX.LOW_INT'       => [31,30,0],    'FRAGMENT.LOW_INT'      => [31,30,0],
    },
);
my %WEBGL_APPLE = (
    params1 => {
        7936 => 'WebKit', 7937 => 'WebKit WebGL',
        # WebKit builds this as "WebGL GLSL ES 1.0 (" + native GLSL version + ")"
        # unconditionally, so no WebKit port -- hence no Safari -- can emit the
        # bare form. (WebGL2's bare "WebGL GLSL ES 3.00" IS hardcoded, so params2
        # is correct as written.)
        7938 => 'WebGL 1.0', 35724 => 'WebGL GLSL ES 1.0 (1.0)',
        3379 => 16384, 34076 => 16384, 34024 => 16384, 3386 => [16384,16384],
        34921 => 16, 36347 => 1024, 36348 => 31, 36349 => 1024,
        35660 => 16, 34930 => 16, 35661 => 32,
        33902 => [1,1], 33901 => [1,511], 34047 => 16,
    },
    params2 => {
        7938 => 'WebGL 2.0', 35724 => 'WebGL GLSL ES 3.00',
        32883 => 2048, 35071 => 2048, 36063 => 8, 34852 => 8, 36183 => 4,
        35376 => 65536, 34045 => 2, 36203 => 4294967294,
        35373 => 12, 35371 => 12, 35375 => 24, 35374 => 24,
        # params1 has vertex=1024, fragment=1024, varying=31 vectors -> x4.
        35658 => 4096, 35657 => 4096, 35659 => 124, 37157 => 124, 37154 => 124,
    },
    extensions1 => [qw(
        ANGLE_instanced_arrays EXT_blend_minmax EXT_clip_control EXT_color_buffer_half_float
        EXT_float_blend EXT_frag_depth EXT_shader_texture_lod
        EXT_texture_filter_anisotropic EXT_sRGB KHR_parallel_shader_compile
        OES_element_index_uint OES_fbo_render_mipmap OES_standard_derivatives
        OES_texture_float OES_texture_float_linear OES_texture_half_float
        OES_texture_half_float_linear OES_vertex_array_object
        WEBGL_color_buffer_float WEBGL_compressed_texture_astc
        WEBGL_compressed_texture_etc WEBGL_compressed_texture_pvrtc
        WEBGL_debug_renderer_info WEBGL_depth_texture WEBGL_draw_buffers WEBGL_lose_context
        WEBGL_multi_draw
    )],
    extensions2 => [qw(
        EXT_clip_control EXT_color_buffer_float EXT_color_buffer_half_float
        EXT_float_blend EXT_texture_filter_anisotropic EXT_texture_norm16
        KHR_parallel_shader_compile OES_draw_buffers_indexed OES_texture_float_linear
        OVR_multiview2 WEBGL_clip_cull_distance WEBGL_compressed_texture_astc
        WEBGL_compressed_texture_etc WEBGL_compressed_texture_pvrtc
        WEBGL_debug_renderer_info WEBGL_lose_context
        WEBGL_multi_draw WEBGL_provoking_vertex
    )],
    precision => {
        'VERTEX.HIGH_FLOAT'    => [127,127,23], 'VERTEX.MEDIUM_FLOAT'   => [15,15,10],
        'VERTEX.LOW_FLOAT'     => [15,15,10],   'FRAGMENT.HIGH_FLOAT'   => [127,127,23],
        'FRAGMENT.MEDIUM_FLOAT'=> [15,15,10],   'FRAGMENT.LOW_FLOAT'    => [15,15,10],
        # every shader/precision combination must be listed, or the unlisted ones
        # fall through and report the REAL host precision alongside spoofed ones
        'VERTEX.HIGH_INT'      => [31,30,0],    'FRAGMENT.HIGH_INT'     => [31,30,0],
        # fp16 mediump/lowp pairs with 16-bit ints, as ANGLE reports them
        'VERTEX.MEDIUM_INT'    => [15,14,0],    'FRAGMENT.MEDIUM_INT'   => [15,14,0],
        'VERTEX.LOW_INT'       => [15,14,0],    'FRAGMENT.LOW_INT'      => [15,14,0],
    },
);
my %WEBGL_ADRENO = (
    params1 => {
        7936 => 'WebKit', 7937 => 'WebKit WebGL',
        7938 => 'WebGL 1.0 (OpenGL ES 2.0 Chromium)',
        35724 => 'WebGL GLSL ES 1.0 (OpenGL ES GLSL ES 1.0 Chromium)',
        3379 => 16384, 34076 => 16384, 34024 => 16384, 3386 => [16384,16384],
        34921 => 16, 36347 => 256, 36348 => 31, 36349 => 224,
        35660 => 16, 34930 => 16, 35661 => 32,
        33902 => [1,8], 33901 => [1,1023], 34047 => 16,
    },
    params2 => {
        7938 => 'WebGL 2.0 (OpenGL ES 3.0 Chromium)',
        35724 => 'WebGL GLSL ES 3.00 (OpenGL ES GLSL ES 3.0 Chromium)',
        32883 => 2048, 35071 => 2048, 36063 => 8, 34852 => 8, 36183 => 4,
        35376 => 65536, 34045 => 2, 36203 => 4294967294,
        # combined uniform blocks must be at least vertex+fragment (24+24)
        35373 => 24, 35371 => 24, 35375 => 72, 35374 => 48,
        # params1 has vertex=256, fragment=224, varying=31 vectors -> x4.
        35658 => 1024, 35657 => 896, 35659 => 124, 37157 => 124, 37154 => 124,
    },
    extensions1 => [qw(
        ANGLE_instanced_arrays EXT_blend_minmax EXT_clip_control EXT_color_buffer_half_float
        EXT_disjoint_timer_query EXT_float_blend EXT_frag_depth EXT_shader_texture_lod
        EXT_texture_filter_anisotropic EXT_sRGB KHR_parallel_shader_compile
        OES_element_index_uint OES_fbo_render_mipmap OES_standard_derivatives
        OES_texture_float OES_texture_float_linear OES_texture_half_float
        OES_texture_half_float_linear OES_vertex_array_object WEBGL_color_buffer_float
        WEBGL_compressed_texture_astc WEBGL_compressed_texture_etc
        WEBGL_compressed_texture_etc1 WEBGL_debug_renderer_info WEBGL_debug_shaders
        WEBGL_depth_texture WEBGL_draw_buffers WEBGL_lose_context WEBGL_multi_draw
    )],
    extensions2 => [qw(
        EXT_clip_control EXT_color_buffer_float EXT_color_buffer_half_float
        EXT_disjoint_timer_query_webgl2 EXT_float_blend EXT_texture_filter_anisotropic
        EXT_texture_norm16 KHR_parallel_shader_compile OES_draw_buffers_indexed
        OES_sample_variables OES_shader_multisample_interpolation OES_texture_float_linear
        OVR_multiview2 WEBGL_clip_cull_distance WEBGL_compressed_texture_astc
        WEBGL_compressed_texture_etc WEBGL_debug_renderer_info WEBGL_debug_shaders
        WEBGL_lose_context WEBGL_multi_draw WEBGL_provoking_vertex
    )],
    precision => {
        'VERTEX.HIGH_FLOAT'    => [127,127,23], 'VERTEX.MEDIUM_FLOAT'   => [15,15,10],
        'VERTEX.LOW_FLOAT'     => [15,15,10],   'FRAGMENT.HIGH_FLOAT'   => [127,127,23],
        'FRAGMENT.MEDIUM_FLOAT'=> [15,15,10],   'FRAGMENT.LOW_FLOAT'    => [15,15,10],
        # every shader/precision combination must be listed, or the unlisted ones
        # fall through and report the REAL host precision alongside spoofed ones
        'VERTEX.HIGH_INT'      => [31,30,0],    'FRAGMENT.HIGH_INT'     => [31,30,0],
        # fp16 mediump/lowp pairs with 16-bit ints, as ANGLE reports them
        'VERTEX.MEDIUM_INT'    => [15,14,0],    'FRAGMENT.MEDIUM_INT'   => [15,14,0],
        'VERTEX.LOW_INT'       => [15,14,0],    'FRAGMENT.LOW_INT'      => [15,14,0],
    },
);

# Each preset declares ONLY the fields that real device exposes (sparse rule).
# Numbers are plain scalars; screen is [w,h] or [w,h,availW,availH,colorDepth].
my %PRESET = (
    'windows-chrome' => {
        user_agent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36',
        platform => 'Win32', vendor => 'Google Inc.', languages => ['en-US','en'],
        hardwareConcurrency => 8, deviceMemory => 8, maxTouchPoints => 0,
        screen => [1920,1080,1920,1040,24], devicePixelRatio => 1,
        webgl_vendor => 'Google Inc. (NVIDIA)',
        webgl_renderer => 'ANGLE (NVIDIA, NVIDIA GeForce RTX 3060 Direct3D11 vs_5_0 ps_5_0, D3D11)',
        webgl => \%WEBGL_ANGLE_NVIDIA,
        # Desktop Chrome's interface set; WebHID/Web Serial are desktop-only.
        features => [qw(connection storage battery usb bluetooth hid serial scheduling rtc)],
        # Chrome-only: drives window.chrome + navigator.userAgentData.
        # Brand list, order and GREASE entry are curl-impersonate's chrome150
        # template verbatim, so the Sec-CH-UA on the wire and navigator
        # .userAgentData cannot disagree. The GREASE brand and its version move
        # every release -- 150 uses "Not;A=Brand";v="8", not 131's "Not_A Brand"
        # v24 -- so it is not a constant to carry forward.
        # 150.0.7871.189 is the last stable 150 build (Chrome version history
        # API), not a plausible-looking invention: it is what a site asking for
        # high-entropy hints compares against.
        ua_data => { platform => 'Windows', platformVersion => '10.0.0', architecture => 'x86', bitness => '64', model => '', uaFullVersion => '150.0.7871.189',
                     brands          => [ {brand=>'Not;A=Brand',version=>'8'},     {brand=>'Chromium',version=>'150'},           {brand=>'Google Chrome',version=>'150'} ],
                     fullVersionList => [ {brand=>'Not;A=Brand',version=>'8.0.0.0'}, {brand=>'Chromium',version=>'150.0.7871.189'}, {brand=>'Google Chrome',version=>'150.0.7871.189'} ] },
    },
    'macos-safari' => {
        user_agent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15',
        platform => 'MacIntel', vendor => 'Apple Computer, Inc.', languages => ['en-US','en'],
        hardwareConcurrency => 10, maxTouchPoints => 0,   # Safari omits deviceMemory
        screen => [1512,982,1512,944,30], devicePixelRatio => 2,
        webgl_vendor => 'Apple Inc.', webgl_renderer => 'Apple GPU',
        webgl => \%WEBGL_APPLE,
        # Safari exposes neither NetworkInformation, Battery, nor WebUSB/Bluetooth/HID/Serial.
        features => [qw(storage rtc)],
    },
    'iphone-safari' => {
        user_agent => 'Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1',
        platform => 'iPhone', vendor => 'Apple Computer, Inc.', languages => ['en-US','en'],
        hardwareConcurrency => 6, maxTouchPoints => 5,
        screen => [390,844,390,844,24], devicePixelRatio => 3,
        webgl_vendor => 'Apple Inc.', webgl_renderer => 'Apple GPU',
        webgl => \%WEBGL_APPLE,
        features => [qw(storage rtc)],
        mobile => 1,   # drives window sizing + touch + pointer/hover/resolution media queries (Safari: no ua_data)
    },
    'windows-firefox' => {
        # Gecko, claimed from a WebKit engine: a bigger lie than the others, and
        # the residual Gecko-only surface is documented in the POD. What IS
        # coherent is the whole header + TLS + HTTP/2 stack, which is Firefox's.
        user_agent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:147.0) Gecko/20100101 Firefox/147.0',
        # Firefox reports an EMPTY navigator.vendor, where Chrome says
        # "Google Inc." and WebKit "Apple Computer, Inc." -- one of the cheapest
        # engine checks there is, so it has to be the empty string, not absent.
        platform => 'Win32', vendor => '', languages => ['en-US','en'],
        # Gecko's own navigator surface. productSub is the cheap engine check --
        # every Gecko build reports 20100101 where WebKit and Chromium report
        # 20030107 -- and oscpu/buildID exist in no other engine, so their
        # ABSENCE is as much a tell as a wrong value. buildID has been frozen at
        # this constant since Firefox 64 for exactly this reason.
        productSub => '20100101',
        oscpu      => 'Windows NT 10.0; Win64; x64',
        buildID    => '20181001000000',
        # Viewport origin in screen coordinates: 0 across, and down by the
        # chrome above it for a maximised window.
        mozInnerScreenX => 0, mozInnerScreenY => 74,
        # No deviceMemory: Firefox has never shipped it.
        hardwareConcurrency => 8, maxTouchPoints => 0,
        screen => [1920,1080,1920,1040,24], devicePixelRatio => 1,
        # Firefox on Windows renders through ANGLE too, so the unmasked strings
        # are the same shape as Chrome's on the same GPU.
        webgl_vendor => 'Google Inc. (NVIDIA)',
        webgl_renderer => 'ANGLE (NVIDIA, NVIDIA GeForce RTX 3060 Direct3D11 vs_5_0 ps_5_0, D3D11)',
        webgl => \%WEBGL_ANGLE_NVIDIA,
        # Same interface set as Safari, by coincidence rather than kinship:
        # Firefox dropped Battery, never shipped NetworkInformation for content,
        # and implements none of WebUSB/Bluetooth/HID/Serial.
        features => [qw(storage rtc)],
        # No ua_data: client hints are Chromium-only, so identity_headers emits
        # no Sec-CH-UA for this profile, which is what Firefox does.
    },
    'pixel-chrome' => {
        # Chrome 131's reduced/frozen Android UA (model "K", version "Android 10");
        # the real device + OS version ride only in Sec-CH-UA-Model/-Platform-Version
        # + navigator.userAgentData -- matching curl-impersonate's chrome131_android.
        user_agent => 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
        platform => 'Linux armv8l', vendor => 'Google Inc.', languages => ['en-US','en'],
        hardwareConcurrency => 8, deviceMemory => 8, maxTouchPoints => 5,
        screen => [412,915,412,915,24], devicePixelRatio => 2.625,
        webgl_vendor => 'Google Inc. (Qualcomm)',
        webgl_renderer => 'ANGLE (Qualcomm, Adreno (TM) 730, OpenGL ES 3.2)',
        webgl => \%WEBGL_ADRENO,
        # Android Chrome has WebUSB + Web Bluetooth but NOT WebHID / Web Serial.
        features => [qw(connection storage battery usb bluetooth scheduling rtc)],
        mobile => 1,
        # Chrome for Android had NO inline PDF viewer at 131, so it reports
        # pdfViewerEnabled false and an EMPTY plugins/mimeTypes list, where every
        # other preset (and WebKitGTK itself) reports true and the five plugin
        # names the HTML spec hardcodes. Dates, because the margin is narrow:
        # Chrome 131 for Android shipped 2024-11-06, the Android viewer first
        # appeared behind a flag in 2024-12, and only became default-on in
        # Chrome 135 (2025-04). So 131 predates it outright.
        pdf_viewer => 0,
        ua_data => { platform => 'Android', platformVersion => '14.0.0', architecture => '', bitness => '', model => 'Pixel 8', uaFullVersion => '131.0.6778.86',
                     brands          => [ {brand=>'Google Chrome',version=>'131'},          {brand=>'Chromium',version=>'131'},          {brand=>'Not_A Brand',version=>'24'} ],
                     fullVersionList => [ {brand=>'Google Chrome',version=>'131.0.6778.86'}, {brand=>'Chromium',version=>'131.0.6778.86'}, {brand=>'Not_A Brand',version=>'24.0.0.0'} ] },
    },
);

# field => validator: 'str'/'num'/'strv'/'screen'/'bool'/'uadata'.
my %FIELD = (
    user_agent => 'str', platform => 'str', vendor => 'str',
    productSub => 'str', oscpu => 'str', buildID => 'str',
    webgl_vendor => 'str', webgl_renderer => 'str', languages => 'strv',
    hardwareConcurrency => 'num', deviceMemory => 'num', maxTouchPoints => 'num',
    devicePixelRatio => 'num', screen => 'screen',
    mozInnerScreenX => 'num', mozInnerScreenY => 'num',
    mobile => 'bool', ua_data => 'uadata', webgl => 'webgl', features => 'features',
    pdf_viewer => 'bool',
);

sub profiles { return sort keys %PRESET }

# Map each preset to the curl-impersonate target with the matching TLS/HTTP2
# fingerprint. curl ships only macOS desktop Chrome + Android Chrome, but
# Windows/macOS Chrome share an identical ClientHello (JA4 is OS-independent), so
# windows-chrome also uses chrome150 -- the OS lives in override_headers, not the
# TLS. Consumed by EV::WebKit's network_fingerprint wiring.
my %CURL_TARGET = (
    'windows-chrome'  => 'chrome150',
    'macos-safari'    => 'safari26_0',
    'iphone-safari'   => 'safari26_0_ios',
    'windows-firefox' => 'firefox147',
    # chrome131_android is still the newest Android target upstream ships, so
    # this one stays at 131 rather than claiming a Chrome the TLS cannot back.
    'pixel-chrome'    => 'chrome131_android',
);
sub curl_target { $CURL_TARGET{ $_[0] // '' } }

# The identity headers (User-Agent + Chrome client hints) a resolved profile
# should present to origins. The proxy forces these over curl's target defaults
# so the origin-seen OS/UA matches the JS layer -- e.g. Windows Chrome on the
# macOS-flavored chrome150 target. Safari profiles (no ua_data) carry just the UA.
# Chrome renders navigator.languages as Accept-Language "en-US,en;q=0.9,..." --
# the first tag unweighted, each later tag q = 1 - 0.1*i (floored at 0.1),
# formatted without trailing zeros. The proxy no longer forwards WebKit's own
# (possibly libsoup-formatted) Accept-Language, so we supply the exact form here.
sub _accept_language {
    my ($langs) = @_;
    my @out;
    for my $i (0 .. $#$langs) {
        if ($i == 0) { push @out, $langs->[$i]; next }
        my $q = 1 - 0.1 * $i;
        $q = 0.1 if $q < 0.1;
        push @out, sprintf('%s;q=%s', $langs->[$i], sprintf('%g', $q));
    }
    return join ',', @out;
}

sub identity_headers {
    my ($fp) = @_;
    my %h = ('user-agent' => $fp->{user_agent});
    $h{'accept-language'} = _accept_language($fp->{languages})
        if $fp->{languages} && @{ $fp->{languages} };
    if (my $u = $fp->{ua_data}) {   # Chrome
        $h{'sec-ch-ua'}          = join ', ', map { qq{"$_->{brand}";v="$_->{version}"} } @{ $u->{brands} || [] };
        $h{'sec-ch-ua-mobile'}   = $fp->{mobile} ? '?1' : '?0';
        $h{'sec-ch-ua-platform'} = qq{"$u->{platform}"};
    }
    return \%h;
}

# The HIGH-entropy client hints a resolved profile reports via
# getHighEntropyValues(). Real Chrome sends these only after an origin opts in
# with Accept-CH, so the proxy adds them per-host on demand (not on every
# request); this keeps the header layer consistent with the JS ua_data. Safari
# profiles (no ua_data) have none.
sub high_entropy_headers {
    my ($fp) = @_;
    my $u = $fp->{ua_data} or return {};
    my %h = (
        'sec-ch-ua-platform-version' => qq{"$u->{platformVersion}"},
        'sec-ch-ua-arch'             => qq{"$u->{architecture}"},
        'sec-ch-ua-bitness'          => qq{"$u->{bitness}"},
        'sec-ch-ua-model'            => qq{"$u->{model}"},
        # match what the JS getHighEntropyValues() reports, or an Accept-CH'ing
        # origin that cross-checks the two channels sees a contradiction:
        'sec-ch-ua-wow64'            => '?0',                      # JS wow64:false (no 32-on-64 preset)
        'sec-ch-ua-full-version'     => qq{"$u->{uaFullVersion}"}, # deprecated singular; JS still exposes uaFullVersion
    );
    if ($u->{fullVersionList}) {
        $h{'sec-ch-ua-full-version-list'} =
            join ', ', map { qq{"$_->{brand}";v="$_->{version}"} } @{ $u->{fullVersionList} };
    }
    return \%h;
}

sub resolve {
    my ($arg) = @_;
    my ($name, %ov);
    if (ref $arg eq 'HASH') { %ov = %$arg; $name = delete $ov{profile}; }
    elsif (!ref $arg)       { $name = $arg; }
    else { Carp::croak('fingerprint: expected a preset name or a hashref') }
    Carp::croak('fingerprint: a profile hashref needs a "profile" => <preset> base') unless defined $name;
    my $base = $PRESET{$name}
        or Carp::croak("fingerprint: unknown fingerprint profile '$name' (have: " . join(', ', profiles()) . ')');
    my %p = (%$base, %ov);   # overrides win
    for my $k (sort keys %p) {
        my $t = $FIELD{$k} or Carp::croak("fingerprint: unknown fingerprint field '$k'");
        my $v = $p{$k};
        # NUL rejection mirrors the module's own standard (add_user_script): an
        # embedded NUL silently truncates the value WebKit receives, producing a
        # silently-wrong -- de-anonymizing -- fingerprint rather than an error.
        if    ($t eq 'str')  { Carp::croak("fingerprint: $k must be a string without a NUL byte")
                                   if ref $v || !defined $v || index($v, "\0") >= 0 }
        elsif ($t eq 'num')  { Carp::croak("fingerprint: $k must be a number")  unless defined $v && !ref $v && $v =~ /\A-?\d+(?:\.\d+)?\z/ }
        elsif ($t eq 'strv') { Carp::croak("fingerprint: $k must be a non-empty arrayref of non-empty NUL-free strings")
                                   unless ref $v eq 'ARRAY' && @$v && !grep { !defined($_) || ref($_) || !length($_) || index($_, "\0") >= 0 } @$v }
        elsif ($t eq 'screen') { Carp::croak("fingerprint: screen must be [w,h] or [w,h,availW,availH,colorDepth]")
                                   unless ref $v eq 'ARRAY' && (@$v == 2 || @$v == 5) && !grep { !defined || ref || !/\A\d+\z/ } @$v }
        elsif ($t eq 'bool')   { Carp::croak("fingerprint: $k must be 0 or 1") unless defined $v && !ref $v && ($v eq '0' || $v eq '1') }
        elsif ($t eq 'webgl')  {
            Carp::croak("fingerprint: webgl must be a hashref") unless ref $v eq 'HASH';
            # Same silent-no-op class as features: a typo'd or empty webgl block
            # leaves the JS wrapper with nothing to install, so the caller believes
            # the GPU family is spoofed while getSupportedExtensions() still returns
            # the host's list next to a spoofed webgl_renderer.
            my @need = qw(params1 params2 extensions1 extensions2 precision);
            my %ok = map { $_ => 1 } @need;
            if (my @bad = grep { !$ok{$_} } sort keys %$v) {
                Carp::croak("fingerprint: unknown webgl key(s): @bad (have: " . join(', ', @need) . ')');
            }
            for my $k2 (@need) {
                Carp::croak("fingerprint: webgl.$k2 is required")
                    unless defined $v->{$k2};
                my $want = ($k2 =~ /^extensions/) ? 'ARRAY' : 'HASH';
                Carp::croak("fingerprint: webgl.$k2 must be " . ($want eq 'ARRAY' ? 'an arrayref' : 'a hashref'))
                    unless ref $v->{$k2} eq $want;
            }
        }
        elsif ($t eq 'features') {
            Carp::croak("fingerprint: features must be an arrayref of strings")
                unless ref $v eq 'ARRAY' && !grep { ref($_) || !defined($_) || index($_, "\0") >= 0 } @$v;
            # The group names are a CLOSED set consumed by FEATURES_JS. Accepting
            # an unknown one silently installs nothing -- the caller believes the
            # interface is present when it is not, which is exactly the kind of
            # quiet, de-anonymizing mismatch a fingerprint spoof must not have.
            my %known = map { $_ => 1 } @FEATURE_GROUPS;
            if (my @bad = grep { !$known{$_} } @$v) {
                Carp::croak("fingerprint: unknown features group(s): @{[ sort @bad ]} (have: "
                          . join(', ', @FEATURE_GROUPS) . ')');
            }
        }
        elsif ($t eq 'uadata') {
            Carp::croak("fingerprint: ua_data must be a hashref") unless ref $v eq 'HASH';
            for my $k2 (sort keys %$v) {
                my $vv = $v->{$k2};
                if ($k2 eq 'brands' || $k2 eq 'fullVersionList') {
                    Carp::croak("fingerprint: ua_data.$k2 must be a non-empty arrayref of {brand,version} hashes")
                        unless ref $vv eq 'ARRAY' && @$vv;
                    for my $e (@$vv) {
                        Carp::croak("fingerprint: ua_data.$k2 entries must be {brand=>str,version=>str}")
                            unless ref $e eq 'HASH'
                                && !grep { !defined || ref || index($_, "\0") >= 0 } ($e->{brand}, $e->{version});
                    }
                }
                else { Carp::croak("fingerprint: ua_data.$k2 must be a NUL-free string")
                           if ref $vv || !defined $vv || index($vv, "\0") >= 0 }
            }
        }
    }
    # Hand back a private deep copy. %PRESET's nested structures are SHARED (both
    # Safari presets point at the same %WEBGL_APPLE table), so returning live refs
    # would let a caller who edits one resolved profile silently re-fingerprint a
    # different preset for the rest of the process.
    return _clone(\%p);
}

sub _clone {
    my ($v, $depth) = @_;
    $depth //= 0;
    # A caller can pass their own structure into an override, and a cyclic one
    # would otherwise recurse until the stack dies rather than erroring cleanly.
    Carp::croak('fingerprint: profile data nested too deeply (cyclic reference?)') if $depth > 64;
    return [ map { _clone($_, $depth + 1) } @$v ]                        if ref $v eq 'ARRAY';
    return { map { ($_ => _clone($v->{$_}, $depth + 1)) } keys %$v }      if ref $v eq 'HASH';
    return $v;
}

# Build the a{sv} GVariant of present, non-user_agent keys. screen is flattened
# to screen_width/height/availWidth/availHeight/colorDepth/pixelDepth; every
# number is a double ('d'); languages is 'as'.
sub gvariant {
    my ($p, $seed, $extra) = @_;
    my %d = %{ $extra || {} };   # entries the caller needs regardless of profile
    $p ||= {};
    $d{$_} = Glib::Variant->new('s', $p->{$_}) for grep { defined $p->{$_} } qw/platform vendor webgl_vendor webgl_renderer productSub oscpu buildID/;
    $d{languages} = Glib::Variant->new('as', $p->{languages}) if $p->{languages};
    $d{$_} = Glib::Variant->new('d', $p->{$_} + 0) for grep { defined $p->{$_} } qw/hardwareConcurrency deviceMemory maxTouchPoints devicePixelRatio mozInnerScreenX mozInnerScreenY/;
    if (my $s = $p->{screen}) {
        my ($w,$h,$aw,$ah,$cd) = @$s == 5 ? @$s : ($s->[0],$s->[1],$s->[0],$s->[1],24);
        $d{screen_width}       = Glib::Variant->new('d', $w);
        $d{screen_height}      = Glib::Variant->new('d', $h);
        $d{screen_availWidth}  = Glib::Variant->new('d', $aw);
        $d{screen_availHeight} = Glib::Variant->new('d', $ah);
        $d{screen_colorDepth}  = Glib::Variant->new('d', $cd);
        $d{screen_pixelDepth}  = Glib::Variant->new('d', $cd);
    }
    # Readback-noise seed (opt-in). Passed as its own double so the extension can
    # read it without parsing the coherence JSON; folded to guint32 in C.
    $d{seed} = Glib::Variant->new('d', $seed + 0) if defined $seed;
    # JS-layer coherence (window.chrome, navigator.userAgentData, matchMedia,
    # touch) is not a native getter -- it is a JSON config the extension evals
    # as JS. Carried as one 's' blob, separate from the native-getter fields.
    if (my $coh = _coherence($p)) {
        require Cpanel::JSON::XS;
        $d{coherence} = Glib::Variant->new('s', Cpanel::JSON::XS::encode_json($coh));
    }
    return Glib::Variant->new('a{sv}', \%d);
}

# Derive the JS-coherence config from the profile: window.chrome + userAgentData
# for a Chrome profile (has ua_data); touch + pointer/hover/resolution media
# overrides for a mobile profile. Returns undef when neither applies.
sub _coherence {
    my ($p) = @_;
    # No profile at all means a PLAIN browser, and new() promises the extension
    # then "defines nothing, leaving a plain instance exactly as it was". Every
    # other block below is gated on a field, but the orientation block is not --
    # it deliberately does not key off `mobile`, so with an empty profile it was
    # the one thing that still emitted a blob. The extension gates COHERENCE_JS
    # and the WebGL getParameter wrapper on the blob's mere presence, so a
    # default browser was shipping window.ScreenOrientation (which stock
    # WebKitGTK does not expose) and a getParameter whose toString no longer
    # said [native code] -- both measured against the extension forced off.
    return undef unless $p && %$p;
    my %c;
    if (my $u = $p->{ua_data}) {
        $c{chrome}  = 1;
        $c{ua_data} = { %$u, mobile => ($p->{mobile} ? 1 : 0) };
    }
    my %media;
    if ($p->{mobile}) {
        $c{touch} = 1;
        $media{pointer} = 'coarse';
        $media{hover}   = 'none';
    }
    # Desktop Chrome 131 and Safari 18 both expose screen.orientation, so it must
    # not be gated to mobile -- 'orientation' in screen was false on the desktop
    # profiles, a one-expression presence probe.
    # ... and the type follows the spoofed SCREEN's aspect, not the mobile flag.
    # Keying it off mobile made a portrait desktop screen (or a landscape tablet
    # profile) report an orientation its own screen.width/height contradict --
    # screen.width > screen.height with type 'portrait-primary' is a two-property
    # probe. Square counts as landscape, as the engines do.
    my ($ow, $oh) = @{ $p->{screen} || [] }[0,1];
    my $portrait = (defined $ow && defined $oh) ? ($oh > $ow) : $p->{mobile};
    $c{orientation} = $portrait
        ? { type => 'portrait-primary',  angle => 0 }
        : { type => 'landscape-primary', angle => 0 };
    # Resolution media queries must agree with the spoofed devicePixelRatio for
    # ANY profile whose dpr differs from 1 (e.g. a Retina desktop), not just
    # mobile -- otherwise matchMedia('(min-resolution: 2dppx)') contradicts
    # window.devicePixelRatio===2.
    my $dpr = ($p->{devicePixelRatio} // 1) + 0;
    $media{dppx} = $dpr if $dpr != 1;
    # Emit the media block whenever a SCREEN is spoofed, not only for mobile or a
    # non-1 dpr. Otherwise a desktop dpr-1 profile got no matchMedia wrapper at
    # all, so device-width/height fell through to the engine and a binary search
    # over '(device-width: Npx)' recovered the real host geometry -- defeating the
    # native screen spoof in two lines.
    $c{media} = \%media if %media || $p->{screen};
    # WebGL numeric capabilities / extension lists / shader precision are JS-layer
    # config too -- the extension's WebGL wrapper reads them from this same blob.
    $c{webgl} = $p->{webgl} if $p->{webgl};
    # Which DOM feature-presence stub groups to install (each in-guarded in JS, so
    # a build that ships the real API keeps it). See FEATURES_JS in the extension.
    $c{features} = $p->{features} if $p->{features};
    # Only emitted when the profile says there is NO inline PDF viewer, because
    # that is the only case needing action: WebKitGTK already reports the
    # viewer-present state (true + the five spec-hardcoded plugin names) that
    # every other preset wants.
    $c{no_pdf_viewer} = 1 if exists $p->{pdf_viewer} && !$p->{pdf_viewer};
    return %c ? \%c : undef;
}

1;

__END__

=head1 NAME

EV::WebKit::Fingerprint - profile data behind EV::WebKit's fingerprint option

=head1 DESCRIPTION

The preset device profiles (C<windows-chrome>, C<macos-safari>,
C<iphone-safari>, C<windows-firefox>, C<pixel-chrome>), their validation, and the marshalling that
hands them to the bundled web-process extension. Used by L<EV::WebKit>. You do
not normally touch it directly: pass C<< fingerprint => >> to
L<EV::WebKit/new> and read L<EV::WebKit/fingerprint> back, which is also where
the profile keys, the override rules and the B<Ceiling> -- what this spoof does
and does not hide -- are documented.

Two of its functions are re-exported as methods for convenience:
C<< EV::WebKit->fingerprint_profiles >> lists the preset names, and
C<< EV::WebKit->fingerprint_available >> reports whether the compiled
extension was found. Prefer those.

=head1 FUNCTIONS

None of these are exported; call them fully qualified if you must.

=head2 available

    my $ok = EV::WebKit::Fingerprint::available();

True if the compiled web-process extension (C<evwk_fp.so>) was located -- in
an installed dist via L<File::ShareDir>, or the in-tree C<share/> during
development. Without it C<< fingerprint => >> croaks.

=head2 profiles

    my @names = EV::WebKit::Fingerprint::profiles();

The preset names, sorted.

=head2 resolve

    my $fp = EV::WebKit::Fingerprint::resolve('windows-chrome');
    my $fp = EV::WebKit::Fingerprint::resolve({ profile => 'macos-safari', ... });

Expands a preset name, or a hashref of overrides over a C<profile> base, into
the full profile hash. The base is B<required> in the hashref form: there is no
neutral profile to override, and half a device is an incoherent one. Croaks on a
missing or unknown preset, an unknown key, or a value of the wrong shape -- deliberately, so a typo cannot silently
produce a half-spoofed and therefore B<incoherent> device.

=head2 gvariant

    my $v = EV::WebKit::Fingerprint::gvariant($fp, $seed, \%extra);

Marshals a resolved profile into the C<a{sv}> C<GVariant> the extension reads
at startup. C<$seed> is optional and enables readback noise. C<\%extra> is
optional and carries entries the extension needs whether or not a profile was
asked for -- the frame-addressing bootstrap goes over on it -- so C<$fp> may
be C<undef>.

=head2 curl_target, identity_headers, high_entropy_headers

Support for C<< network_fingerprint => >>: the libcurl-impersonate target
matching a preset, and the identity / client-hint headers that must be forced
over that target's defaults so the JS and HTTP layers agree.

=cut
