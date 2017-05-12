use strict;
use warnings;
use lib 't/lib';
use TestFilter;

my $coderef = sub { shift->remove_text_and_tag };

add_callbacks(
  remove_script => {
    script => {
      start => $coderef,
      end   => $coderef,
    },
  },
  remove_script_and_style => {
    script => {
      start => $coderef,
      end   => $coderef,
    },
    style => {
      start => $coderef,
      end   => $coderef,
    },
  },
);

test_all;

__END__
=== remove script tags
--- remove_script
<html>
<head>
<SCRIPT>
<!-- javascript
//-->
</script>
</head>
</html>
---
<html>
<head>
</head>
</html>
=== remove script tags
--- remove_script
<html>
<head>
<!-- javascript
//-->
</script>
</head>
</html>
---
<html>
<head>
</head>
</html>
=== remove script tags
--- remove_script
<html>
<head>
 <!-- javascript
-->
</head>
<body>
 <!-- javascript
-->
</body>
</html>
---
<html>
<head>
 <!-- javascript
-->
</head>
<body>
 <!-- javascript
-->
</body>
</html>
=== remove script_and_style tags
--- remove_script_and_style
<html>
<head>
<SCRIPT>
<!-- javascript
//-->
</script>
<STYLE>
<!-- css
//-->
</style>
</head>
</html>
---
<html>
<head>
</head>
</html>
