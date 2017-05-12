[![Build Status](https://travis-ci.org/marmand/Dist-Zilla-Plugin-Documentation-SQL.svg?branch=master)](https://travis-ci.org/marmand/Dist-Zilla-Plugin-Documentation-SQL)
[![Coverage Status](https://coveralls.io/repos/marmand/Dist-Zilla-Plugin-Documentation-SQL/badge.png)](https://coveralls.io/r/marmand/Dist-Zilla-Plugin-Documentation-SQL)

SYNOPSIS
========

Put in your dist.ini file

```ini
name = Sample-Package
author = E. Xavier Ample <example@example.org>
license = GPL_3
copyright_holder = E. Xavier Ample
copyright_year = 2014
version = 0.42

[Documentation::SQL]
```

Then, dist will automatically search all your package files for documentation that looks like

```pod
=sql SELECT * FROM table

=cut
```

And will put all of them in a single file, located at (for the example)

```
lib/Sample/Package/Documentation/SQL.pod
```
