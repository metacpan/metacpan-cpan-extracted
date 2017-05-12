use strict;
use warnings;
use autodie;
use File::Temp ();
use Test::More;

use Makefile::Update;
BEGIN { use_ok('Makefile::Update::MSBuild'); }

my $tmp_project = File::Temp->new(UNLINK => 0);
my $fn = $tmp_project->filename;

print $tmp_project <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup Label="ProjectConfigurations">
    <ProjectConfiguration Include="Debug|Win32">
      <Configuration>Debug</Configuration>
      <Platform>Win32</Platform>
    </ProjectConfiguration>
  </ItemGroup>
  <ItemGroup>
    <ClCompile Include="foo.cpp" />
  </ItemGroup>
  <ItemGroup>
    <ClInclude Include="foo.hpp" />
  </ItemGroup>
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />
  <ImportGroup Label="ExtensionTargets">
  </ImportGroup>
</Project>
EOF
undef $tmp_project;

my $fn_filters = "$fn.filters";
open my $tmp_filters, '>', $fn_filters;
print $tmp_filters <<'EOF';
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup>
    <Filter Include="Common Sources">
      <UniqueIdentifier>{...}</UniqueIdentifier>
    </Filter>
    <Filter Include="Common Headers">
      <UniqueIdentifier>{...}</UniqueIdentifier>
    </Filter>
  </ItemGroup>
  <ItemGroup>
    <ClCompile Include="foo.cpp">
      <Filter>Sources</Filter>
    </ClCompile>
  </ItemGroup>
  <ItemGroup>
    <ClInclude Include="foo.hpp">
      <Filter>Headers</Filter>
    </ClInclude>
  </ItemGroup>
</Project>
EOF
close $tmp_filters;

my $old_sources = [qw(foo.cpp)];
my $old_headers = [qw(foo.hpp)];

my $new_sources = [qw(bar.cpp)];
my $new_headers = [qw(bar.hpp)];

my $options = {
    file => $fn,
    verbose => 1,
};

is(update_msbuild_project($options, $old_sources, $old_headers), 0, 'no changes if nothing changed');
is(update_msbuild_project($options, $new_sources, $old_headers), 1, 'changes if sources changed');
is(update_msbuild_project($options, $old_sources, $new_headers), 1, 'changes if headers changed');

done_testing();

END {
    unlink $fn;
    unlink $fn_filters;
}
