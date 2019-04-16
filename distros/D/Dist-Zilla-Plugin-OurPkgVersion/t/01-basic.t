#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::DZil;
use Test::Version qw( version_ok );
use Path::Tiny qw( path );

my $tzil = Builder->from_config({ dist_root => 'corpus/DZT' });

$tzil->build;

version_ok( path($tzil->tempdir)->child('build/lib/DZT0.pm'));
version_ok( path($tzil->tempdir)->child('build/lib/DZT1.pm'));

my $lib_0 = $tzil->slurp_file('build/lib/DZT0.pm');
my $lib_1 = $tzil->slurp_file('build/lib/DZT1.pm');
my $lib_2 = $tzil->slurp_file('build/lib/DZT2.pm');
my $lib_3 = $tzil->slurp_file('build/lib/DZT3.pm');
my $lib_4 = $tzil->slurp_file('build/lib/DZT4.pm');
my $lib_5 = $tzil->slurp_file('build/lib/DZT5.pm');
my $lib_6 = $tzil->slurp_file('build/lib/DZT6.pm');
my $lib_7 = $tzil->slurp_file('build/lib/DZT7.pm');
my $lib_8 = $tzil->slurp_file('build/lib/DZT8.pm');
my $tst_0 = $tzil->slurp_file('build/t/basic.t'  );

# e short for expected files
# -------------------------------------------------------------------
my $elib_0 = <<'END LIB0';
use strict;
use warnings;
package DZT0;
our $VERSION = '0.1.0'; # VERSION
# ABSTRACT: my abstract
1;
END LIB0

my $elib_1 = <<'END LIB1';
use strict;
use warnings;
package DZT1;
BEGIN {
	our $VERSION = '0.1.0'; # VERSION
}
# ABSTRACT: my abstract
1;
END LIB1

my $elib_2 = <<'END LIB2';
use strict;
use warnings;
package DZT2;
1;
END LIB2

my $elib_3 = <<'END LIB3';
use strict;
use warnings;
package DZT3;
# This is a comment
1;
END LIB3

my $elib_4 = <<'END LIB4';
use strict;
use warnings;
package DZT4;
our $VERSION = '0.1.0'; # VERSION
package DZT4::Inner;
our $VERSION = '0.1.0'; # VERSION
1;
END LIB4

my $elib_5 = <<'END LIB5';
package DZT5;
use strict;
use warnings;
our $VERSION = '0.1.0'; # VERSION: foo
1;
END LIB5

my $elib_6 = <<'END LIB6';
package DZT6;
use strict;
use warnings;
our $VERSION = '0.1.0'; #VERSION
1;
END LIB6

my $elib_7 = <<'END LIB7';
use strict;
use warnings;
package DZT7;
our $VERSION = '0.1.0'; ## VERSION
# ABSTRACT: my abstract
1;
END LIB7

my $elib_8 = <<'END LIB8';
use strict;
use warnings;
package DZT8;
<<END
# VERSION
END

=pod

# VERSION

=cut

our $VERSION = ''; our $VERSION = '0.1.0'; # VERSION

1;
__END__

# VERSION
END LIB8

my $etst_0 = <<'END TST0';
#!/usr/bin/perl
# VERSION
END TST0
# -------------------------------------------------------------------

is ( $lib_0, $elib_0, 'check DZT0.pm' );
is ( $lib_1, $elib_1, 'check DZT1.pm' );
is ( $lib_2, $elib_2, 'check DZT2.pm' );
is ( $lib_3, $elib_3, 'check DZT3.pm' );
is ( $lib_4, $elib_4, 'check DZT4.pm' );
is ( $lib_5, $elib_5, 'check DZT5.pm' );
is ( $lib_6, $elib_6, 'check DZT6.pm' );
is ( $lib_7, $elib_7, 'check DZT7.pm' );
is ( $lib_8, $elib_8, 'check DZT8.pm' );
is ( $tst_0, $etst_0, 'check basic.t' );

for my $file ( qw/DZT2 DZT3/ ) {
	like (
		join( "\n", map { $_->{message} } @{ $tzil->chrome->logger->events } ),
		qr{Skipping: "lib/$file\.pm" has no "# VERSION" comment},
		"warn no #VERSION in $file.pm"
	);
}


done_testing;
