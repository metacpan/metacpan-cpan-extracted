use strict;
use warnings;
use autodie;
use Test::More;
use Test::Warn;

BEGIN { use_ok('Makefile::Update::MSBuild'); }

sub do_update
{
    my ($instr, $sources) = @_;

    my $fullinput = <<EOF;
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup Label="ProjectConfigurations">
    <ProjectConfiguration Include="Debug|Win32">
      <Configuration>Debug</Configuration>
      <Platform>Win32</Platform>
    </ProjectConfiguration>
  </ItemGroup>
$instr
  <Import Project="\$(VCTargetsPath)\\Microsoft.Cpp.targets" />
  <ImportGroup Label="ExtensionTargets">
  </ImportGroup>
</Project>
EOF

    open my $out, '>', \my $outstr;
    open my $in, '<', \$fullinput;

    update_msbuild($in, $out, $sources)
}

warning_like {
        do_update(<<'EOF',
  <ItemGroup>
    <ClInclude Include="foo.h" />
    <ClCompile Include="foo.cpp" />
  </ItemGroup>
EOF
            [qw(foo.cpp)]
        )
    }
    qr/^Mix of sources and headers.*/,
    'mix of sources and headers warning given';

warning_like {
        do_update(<<'EOF',
  <ItemGroup>
    <ClCompile Include="foo.cpp" />
    <ClInclude Include="foo.h" />
  </ItemGroup>
EOF
            [qw(foo.cpp)]
        )
    }
    qr/^Mix of headers and sources.*/,
    'mix of headers and sources warning given';

warning_like {
        do_update(<<'EOF',
  <ItemGroup>
    <ClCompile Include="foo.cpp" />
    <ClCompile Include="foo.cpp" />
  </ItemGroup>
EOF
            [qw(foo.cpp)]
        )
    }
    qr/^Duplicate file "foo.cpp".*/,
    'duplicate file warning given';

done_testing()
