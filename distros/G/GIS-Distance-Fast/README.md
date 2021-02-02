# NAME

GIS::Distance::Fast - C implementation of GIS::Distance formulas.

# DESCRIPTION

This distribution re-implements some, but not all, of the formulas
that come with [GIS::Distance](https://metacpan.org/pod/GIS%3A%3ADistance) in the C programming language.  C code
is generally much faster than the Perl equivalent.

See ["SPEED" in GIS::Distance](https://metacpan.org/pod/GIS%3A%3ADistance#SPEED) for some benchmarking and how to run your
own benchmarks.

This module need not be used directly.  [GIS::Distance](https://metacpan.org/pod/GIS%3A%3ADistance) will automatically
use the `GIS::Distance::Fast::*` formulas when installed.

# FORMULAS

- [GIS::Distance::Fast::Cosine](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AFast%3A%3ACosine)
- [GIS::Distance::Fast::GreatCircle](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AFast%3A%3AGreatCircle)
- [GIS::Distance::Fast::Haversine](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AFast%3A%3AHaversine)
- [GIS::Distance::Fast::Polar](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AFast%3A%3APolar)
- [GIS::Distance::Fast::Vincenty](https://metacpan.org/pod/GIS%3A%3ADistance%3A%3AFast%3A%3AVincenty)

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
