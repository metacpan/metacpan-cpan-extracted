# NAME

GIS::Distance::Fast - C implementation of GIS::Distance formulas.

# DESCRIPTION

This distribution re-implements some, but not all, of the formulas
that come with [GIS::Distance](https://metacpan.org/pod/GIS::Distance) in the C programming language.  C code
is generally much faster than the Perl equivalent.

See ["SPEED" in GIS::Distance](https://metacpan.org/pod/GIS::Distance#SPEED) for some benchmarking and how to run your
own benchmarks.

This module need not be used directly.  [GIS::Distance](https://metacpan.org/pod/GIS::Distance) will automatically
use the `GIS::Distance::Fast::*` formulas when installed.

# FORMULAS

- [GIS::Distance::Fast::Cosine](https://metacpan.org/pod/GIS::Distance::Fast::Cosine)
- [GIS::Distance::Fast::GreatCircle](https://metacpan.org/pod/GIS::Distance::Fast::GreatCircle)
- [GIS::Distance::Fast::Haversine](https://metacpan.org/pod/GIS::Distance::Fast::Haversine)
- [GIS::Distance::Fast::Polar](https://metacpan.org/pod/GIS::Distance::Fast::Polar)
- [GIS::Distance::Fast::Vincenty](https://metacpan.org/pod/GIS::Distance::Fast::Vincenty)

# SUPPORT

Please submit bugs and feature requests to the
GIS-Distance-Fast GitHub issue tracker:

[https://github.com/bluefeet/GIS-Distance-Fast/issues](https://github.com/bluefeet/GIS-Distance-Fast/issues)

# AUTHORS

```
Aran Clary Deltac <bluefeet@gmail.com>
```

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
