# -*- perl -*-

# t/002_pod.t - check pod

use Test::Pod tests => 4;

pod_file_ok( "lib/Mail/Builder/Simple.pm", "Valid POD file" );
pod_file_ok( "lib/Mail/Builder/Simple/Scalar.pm", "Valid POD file" );
pod_file_ok( "lib/Mail/Builder/Simple/TT.pm", "Valid POD file" );
pod_file_ok( "lib/Mail/Builder/Simple/HTML/Template.pm", "Valid POD file" );
