package FindApp::Test::Setup;

use parent "Import::Base";

my   @pragmata = qw<utf8 strict warnings>; push @pragmata, (
      filetest  => [ qw<access> ],                      # so -r etc work with ACLs
      charnames => [ qw<:full :short latin greek> ],    # \N{EN DASH}, \N{Omega}
      lib       => [ qw<lib t/lib> ],
      open      => [ ":std", OUT => ":utf8" ],
      feature   => [ qw<say state> ],                   # but not switch, which is deprecated
     -feature   => [ qw<switch> ],                      # smartmatch is a bug, not a feature
     -indirect  => [ qw<fatal> ],                       # forbid "indirect object" syntqctic ambiguity
    "namespace::autoclean",
);                                           push @pragmata,
      feature  => [qw<unicode_strings>]                   if $^V >= v5.11.3;
                                             push @pragmata,
      feature  => [qw<fc current_sub>]                    if $^V >= v5.16;

my @modules = (
    "Carp",
    "Test::More",
    "Test::Exception",
    "FindApp::Test::Unwarned",
    "FindApp::Test::Utils" => [":all"],
);

our @IMPORT_MODULES = (@pragmata, @modules);

1;
