#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;
use utf8;
use Test::More 0.88 tests => 56; # done_testing

use Test::DZil 'Builder';

#---------------------------------------------------------------------
sub make_ini
{
  my $version = shift;

  my $ini = "version = $version\n" . <<'END START';
name     = DZT-Sample
author   = E. Xavier Ample <example@example.org>
license  = Perl_5
copyright_holder = E. Xavier Ample

[Prereqs]
Foo::Bar = 1.00
Bloofle  = 0
Baz      = v1.2.3
perl     = 5.008
END START

  $ini . join('', map { "$_\n" } @_);
} # end make_ini

#---------------------------------------------------------------------
sub make_changes
{
  my $changes = "Revision history for DZT-Sample\n\n";

  my $num = @_;

  while ($num > 0) {
    $changes .= sprintf("0.%02d   %s\n\t- What happened in release %d\n\n",
                        $num, shift, $num);
    --$num;
  }

  $changes =~ s/\n*\z/\n/;

  $changes;
} # end make_changes

#---------------------------------------------------------------------
sub make_re
{
  my $text = quotemeta shift;

  $text =~ s/\\\n/ *\n/g;

  qr/^$text/m;
} # end make_re

#---------------------------------------------------------------------
{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => make_ini(
          '0.04',
          '[GatherDir]',
          '[TemplateCJM]',
        ),
        'source/Changes' => make_changes('March 29, 2010', 'March 15, 2010', 'March 7, 2010', 'October 11, 2009'),
      },
    },
  );

  $tzil->build;

  my $readme = $tzil->slurp_file('build/README');
  like(
    $readme,
    qr{\A\QDZT-Sample version 0.04, released March 29, 2010\E\n},
    "English date first line of README",
  );

  like($readme, qr{^File: README\n}m, "English date filename correct in README");
  like($readme, qr{^Path: README\n}m, "English date pathname correct in README");

  my $expected_depends = <<'END DEPEND';
DEPENDENCIES

  Package   Minimum Version
  --------- ---------------
  perl       5.8.0
  Baz        1.2.3
  Bloofle
  Foo::Bar   1.00
END DEPEND

  like($readme, make_re($expected_depends), "English date DEPENDENCIES in README");

  my $expected_changes = <<'END CHANGES';
CHANGES
    Here's what's new in version 0.04 of DZT-Sample:
    (See the file "Changes" for the full revision history.)

	- What happened in release 4



END CHANGES

  like($readme, make_re($expected_changes), "English date CHANGES in README");

  undef $readme;

  my $module = $tzil->slurp_file('build/lib/DZT/Sample.pm');

  like(
    $module,
    qr{^\Q# This file is part of DZT-Sample 0.04 (March 29, 2010)\E\n}m,
    'English date comment in module',
  );

  like(
    $module,
    qr{^\Q# This { {comment}} should be unchanged.\E\n}m,
    'English date unchanged comment in module',
  );

  like(
    $module,
    make_re("DZT::Sample requires L<Bloofle> and\n".
            "L<Foo::Bar> (1.00 or later).\n"),
    'English date POD in module',
  );

  like(
    $module,
    qr{^# File: Sample\.pm\n}m,
    "English date filename correct in module"
  );

  like(
    $module,
    qr{^# Path: lib/DZT/Sample\.pm\n}m,
    "English date pathname correct in module"
  );

  my $manual = $tzil->slurp_file('build/lib/DZT/Manual.pod');

  like(
    $manual,
    qr{^\QThis document (DZT::Manual) describes DZT-Sample 0.04.\E\n}m,
    'English date VERSION in manual',
  );

  like(
    $manual,
    qr{^File: Manual\.pod\n}m,
    "English date filename correct in manual"
  );

  like(
    $manual,
    qr{^Path: lib/DZT/Manual\.pod\n}m,
    "English date pathname correct in manual"
  );
}

#---------------------------------------------------------------------
{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => make_ini(
          '0.04',
          '[GatherDir]',
          '[TemplateCJM]',
        ),
        'source/Changes' => make_changes('2010-03-29', '2010-03-15', '2010-03-07', '2009-10-11'),
      },
    },
  );

  $tzil->build;

  my $readme = $tzil->slurp_file('build/README');
  like(
    $readme,
    qr{\A\QDZT-Sample version 0.04, released 2010-03-29\E\n},
    "spec date first line of README",
  );

  like($readme, qr{^File: README\n}m, "spec date filename correct in README");
  like($readme, qr{^Path: README\n}m, "spec date pathname correct in README");

  my $expected_depends = <<'END DEPEND';
DEPENDENCIES

  Package   Minimum Version
  --------- ---------------
  perl       5.8.0
  Baz        1.2.3
  Bloofle
  Foo::Bar   1.00
END DEPEND

  like($readme, make_re($expected_depends), "spec date DEPENDENCIES in README");

  my $expected_changes = <<'END CHANGES';
CHANGES
    Here's what's new in version 0.04 of DZT-Sample:
    (See the file "Changes" for the full revision history.)

	- What happened in release 4



END CHANGES

  like($readme, make_re($expected_changes), "spec date CHANGES in README");

  undef $readme;

  my $module = $tzil->slurp_file('build/lib/DZT/Sample.pm');

  like(
    $module,
    qr{^\Q# This file is part of DZT-Sample 0.04 (2010-03-29)\E\n}m,
    'spec date comment in module',
  );

  like(
    $module,
    qr{^\Q# This { {comment}} should be unchanged.\E\n}m,
    'spec date unchanged comment in module',
  );

  like(
    $module,
    make_re("DZT::Sample requires L<Bloofle> and\n".
            "L<Foo::Bar> (1.00 or later).\n"),
    'spec date POD in module',
  );

  like(
    $module,
    qr{^# File: Sample\.pm\n}m,
    "spec date filename correct in module"
  );

  like(
    $module,
    qr{^# Path: lib/DZT/Sample\.pm\n}m,
    "spec date pathname correct in module"
  );

  my $manual = $tzil->slurp_file('build/lib/DZT/Manual.pod');

  like(
    $manual,
    qr{^\QThis document (DZT::Manual) describes DZT-Sample 0.04.\E\n}m,
    'spec date VERSION in manual',
  );

  like(
    $manual,
    qr{^File: Manual\.pod\n}m,
    "spec date filename correct in manual"
  );

  like(
    $manual,
    qr{^Path: lib/DZT/Manual\.pod\n}m,
    "spec date pathname correct in manual"
  );
}

#---------------------------------------------------------------------
{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => make_ini(
          '0.04',
          '[GatherDir]',
          '[TemplateCJM]',
          'date_format = MMMM d, y',
        ),
        'source/Changes' => make_changes('2010-03-29', '2010-03-15', '2010-03-07', '2009-10-11'),
      },
    },
  );

  $tzil->build;

  my $readme = $tzil->slurp_file('build/README');
  like(
    $readme,
    qr{\A\QDZT-Sample version 0.04, released March 29, 2010\E\n},
    "reformatted date first line of README",
  );

  like($readme, qr{^File: README\n}m,
       "reformatted date filename correct in README");
  like($readme, qr{^Path: README\n}m,
       "reformatted date pathname correct in README");

  my $expected_depends = <<'END DEPEND';
DEPENDENCIES

  Package   Minimum Version
  --------- ---------------
  perl       5.8.0
  Baz        1.2.3
  Bloofle
  Foo::Bar   1.00
END DEPEND

  like($readme, make_re($expected_depends), "reformatted date DEPENDENCIES in README");

  my $expected_changes = <<'END CHANGES';
CHANGES
    Here's what's new in version 0.04 of DZT-Sample:
    (See the file "Changes" for the full revision history.)

	- What happened in release 4



END CHANGES

  like($readme, make_re($expected_changes), "reformatted date CHANGES in README");

  undef $readme;

  my $module = $tzil->slurp_file('build/lib/DZT/Sample.pm');

  like(
    $module,
    qr{^\Q# This file is part of DZT-Sample 0.04 (March 29, 2010)\E\n}m,
    'reformatted date comment in module',
  );

  like(
    $module,
    qr{^\Q# This { {comment}} should be unchanged.\E\n}m,
    'reformatted date unchanged comment in module',
  );

  like(
    $module,
    make_re("DZT::Sample requires L<Bloofle> and\n".
            "L<Foo::Bar> (1.00 or later).\n"),
    'reformatted date POD in module',
  );

  like(
    $module,
    qr{^# File: Sample\.pm\n}m,
    "reformatted date filename correct in module"
  );

  like(
    $module,
    qr{^# Path: lib/DZT/Sample\.pm\n}m,
    "reformatted date pathname correct in module"
  );

  my $manual = $tzil->slurp_file('build/lib/DZT/Manual.pod');

  like(
    $manual,
    qr{^\QThis document (DZT::Manual) describes DZT-Sample 0.04.\E\n}m,
    'reformatted date VERSION in manual',
  );

  like(
    $manual,
    qr{^File: Manual\.pod\n}m,
    "reformatted date filename correct in manual"
  );

  like(
    $manual,
    qr{^Path: lib/DZT/Manual\.pod\n}m,
    "reformatted date pathname correct in manual"
  );
}

#---------------------------------------------------------------------
{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => make_ini(
          '0.04',
          '[GatherDir]',
          '[TemplateCJM]',
          'date_format = MMMM d, y',
        ),
        'source/Changes' => make_changes('2010-03-29 release note 4',
                                         '2010-03-15 release note 3',
                                         '2010-03-07 release note 2',
                                         '2009-10-11 release note 1'),
      },
    },
  );

  $tzil->build;

  my $readme = $tzil->slurp_file('build/README');
  like(
    $readme,
    qr{\A\QDZT-Sample version 0.04, released March 29, 2010\E\n},
    "release note first line of README",
  );

  like($readme, qr{^File: README\n}m, "release note filename correct in README");
  like($readme, qr{^Path: README\n}m, "release note pathname correct in README");

  my $expected_depends = <<'END DEPEND';
DEPENDENCIES

  Package   Minimum Version
  --------- ---------------
  perl       5.8.0
  Baz        1.2.3
  Bloofle
  Foo::Bar   1.00
END DEPEND

  like($readme, make_re($expected_depends), "release note DEPENDENCIES in README");

  my $expected_changes = <<'END CHANGES';
CHANGES
    Here's what's new in version 0.04 of DZT-Sample:
    (See the file "Changes" for the full revision history.)

	- What happened in release 4



END CHANGES

  like($readme, make_re($expected_changes), "release note CHANGES in README");

  undef $readme;

  my $module = $tzil->slurp_file('build/lib/DZT/Sample.pm');

  like(
    $module,
    qr{^\Q# This file is part of DZT-Sample 0.04 (March 29, 2010)\E\n}m,
    'release note comment in module',
  );

  like(
    $module,
    qr{^\Q# This { {comment}} should be unchanged.\E\n}m,
    'release note unchanged comment in module',
  );

  like(
    $module,
    make_re("DZT::Sample requires L<Bloofle> and\n".
            "L<Foo::Bar> (1.00 or later).\n"),
    'release note POD in module',
  );

  like(
    $module,
    qr{^# File: Sample\.pm\n}m,
    "release note date filename correct in module"
  );

  like(
    $module,
    qr{^# Path: lib/DZT/Sample\.pm\n}m,
    "release note date pathname correct in module"
  );

  my $manual = $tzil->slurp_file('build/lib/DZT/Manual.pod');

  like(
    $manual,
    qr{^\QThis document (DZT::Manual) describes DZT-Sample 0.04.\E\n}m,
    'release note VERSION in manual',
  );

  like(
    $manual,
    qr{^File: Manual\.pod\n}m,
    "release note date filename correct in manual"
  );

  like(
    $manual,
    qr{^Path: lib/DZT/Manual\.pod\n}m,
    "release note date pathname correct in manual"
  );
}

#---------------------------------------------------------------------
{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => make_ini(
          '0.02',
          '[GatherDir]',
          '[TemplateCJM]',
        ),
        'source/Changes' => <<'END CHANGES UTF-8',
Revision history

0.02   2010-03-29
	- test “release”

0.01   2010-03-15
	- initial release
END CHANGES UTF-8
      },
    },
  );

  $tzil->build;

  my $readme = $tzil->slurp_file('build/README');
  like(
    $readme,
    qr{\A\QDZT-Sample version 0.02, released 2010-03-29\E\n},
    "UTF-8 date unchanged in README",
  );

  my $expected_depends = <<'END DEPEND';
DEPENDENCIES

  Package   Minimum Version
  --------- ---------------
  perl       5.8.0
  Baz        1.2.3
  Bloofle
  Foo::Bar   1.00
END DEPEND

  like($readme, make_re($expected_depends), "UTF-8 DEPENDENCIES in README");

  my $expected_changes = <<'END CHANGES';
CHANGES
    Here's what's new in version 0.02 of DZT-Sample:
    (See the file "Changes" for the full revision history.)

	- test “release”


END CHANGES

  like($readme, make_re($expected_changes), "UTF-8 CHANGES in README");

  undef $readme;

  my $module = $tzil->slurp_file('build/lib/DZT/Sample.pm');

  like(
    $module,
    qr{^\Q# This file is part of DZT-Sample 0.02 (2010-03-29)\E\n}m,
    'UTF-8 comment in module',
  );
}

done_testing;
