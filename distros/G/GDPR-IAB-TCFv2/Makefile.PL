use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'GDPR::IAB::TCFv2',
  VERSION_FROM     => 'lib/GDPR/IAB/TCFv2.pm',
  ABSTRACT_FROM    => 'lib/GDPR/IAB/TCFv2.pm',
  AUTHOR           => 'Tiago Peczenyj <tiago.peczenyj+cpan@gmail.com>',
  LICENSE          => 'perl_5',
  MIN_PERL_VERSION => '5.012000',
  EXE_FILES        => ['bin/iabtcfv2'],
  TEST_REQUIRES    => {

    # JSON::PP and Time::Piece are listed here (rather than under
    # PREREQ_PM) because they are runtime deps of the optional
    # CMPValidator feature only. The lib/ side lazy-requires them
    # at first use; we still need them installed in the test
    # environment so t/14-cmp-validator.t can exercise the feature.
    # End-user installs that opt into CMPValidator should also pull
    # them in via the META `recommends` block.
    'JSON::PP'               => 0,
    'Time::Piece'            => 0,
    'Test::Exception'        => 0.43,
    'Test::More'             => 0.94,
    'Test::Pod'              => 0,
    'Test::Synopsis'         => 0,
    'Test::Warn'             => 0.30,
    'IO::Compress::Gzip'     => 0,
    'IO::Uncompress::Gunzip' => 0,
  },

  # META_MERGE is gated on EUMM 6.46 (META v2 support) so installs on
  # ancient toolchains -- notably the EUMM 6.42 that shipped with Perl
  # 5.12.0, our MIN_PERL_VERSION floor -- still build cleanly. Modern
  # CPAN clients see the full meta block.
  (
    eval { ExtUtils::MakeMaker->VERSION(6.46) }
    ? (
      META_MERGE => {
        dynamic_config => 0,
        'meta-spec'    => {version => 2},

        # `t` is auto-injected by EUMM, so listing it here would
        # produce a duplicate entry in the rendered META. List only
        # the dirs EUMM does not already exclude.
        no_index => {directory => ['xt', 'bench', 'docs']},
        prereqs  => {
          runtime => {
            requires   => {perl => '5.012000'},
            recommends => {

              # CMPValidator opt-in feature: lazy-required at first
              # use, with a clear croak when missing. Listed here
              # so toolchains that honor `recommends` install them
              # automatically; base parser users do not pay the
              # dep cost.
              'JSON::PP'    => 0,
              'Time::Piece' => 0,
              'HTTP::Tiny'  => 0,

              'JSON'               => 0,
              'JSON::XS'           => 0,
              'DateTimeX::TO_JSON' => 0,
            },
          },
        },
        provides  => _get_provides(),
        resources => {
          bugtracker => {web => 'https://github.com/peczenyj/GDPR-IAB-TCFv2/issues'},
          homepage   => 'https://github.com/peczenyj/GDPR-IAB-TCFv2',
          license    => ['http://dev.perl.org/licenses/'],
          repository => {
            type => 'git',
            url  => 'https://github.com/peczenyj/GDPR-IAB-TCFv2.git',
            web  => 'https://github.com/peczenyj/GDPR-IAB-TCFv2',
          },
          x_security_policy => 'https://github.com/peczenyj/GDPR-IAB-TCFv2/blob/devel/SECURITY.md',
        },
        x_authority => 'cpan:PACMAN',
      }
      )
    : ()
  ),
);

sub _get_provides {
  use File::Find;
  my %provides;
  find(
    {
      wanted => sub {
        return unless /\.pm$/;
        my $file   = $File::Find::name;
        my $module = $file;
        $module =~ s|^lib/||;
        $module =~ s|/|::|g;
        $module =~ s|\.pm$||;
        my $v = MM->parse_version($file);
        $provides{$module} = {file => $file, version => $v || "0"};
      },
      no_chdir => 1
    },
    "lib"
  );
  return \%provides;
}

sub MY::postamble {
  return <<'EOF';
lint:
	perlcritic -profile .perlcriticrc lib bin

tidy:
	perltidy -b -pro=.perltidyrc Makefile.PL $$(find lib bin t xt bench -type f \( -name "*.pm" -o -name "*.t" -o -name "*.pl" -o -name "iabtcfv2" \) 2>/dev/null)

check: lint test author-test

author-test:
	AUTHOR_TESTING=1 prove -lr xt
EOF
}

