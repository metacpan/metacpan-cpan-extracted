#---------------------------------------------------------------------
# Configure Pod::Loom for building documentation
#---------------------------------------------------------------------

use strict;
use warnings;

{
  sort_attr   => 1,
  sort_diag   => 1,
  sort_method => 1,
  # This template will be filled in by TemplateCJM:
  version_desc => <<'END VERSION',
This document describes version {{$version}} of
{{$module}}, released {{$date}}
as part of {{$dist}} version {{$dist_version}}.
END VERSION
};
