#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Find;

my $do_xs = can_cc();
for (@ARGV) {
    /^-pm/ and $do_xs = 0;
    /^-xs/ and $do_xs = 1;
}

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my %test_requires = (
    'Test::DBGp'                => '0.07',
    'DBGp::Client'              => '0.10',
);

my %pm = (
    'perl5db.pl'    => 'blib/lib/dbgp-helper/perl5db.pl',
);

{
    open my $fh, '>', 'DB/DbgrXS.pm' or die "Unable to open 'DB/DbgrXS.pm: $!";
    printf $fh <<'EOT', ($do_xs ? 1 : 0);
# generated file, don't edit

package DB::DbgrXS;

sub HAS_XS() { %s }

1;
EOT
}

sub _fill_dbgp {
    return unless -f $_ && /\.pm$/;
    $pm{$_} = "blib/lib/dbgp-helper/$_";
}

sub _fill_lib {
    return unless -f $_ && /\.pm$/;
    $pm{$_} = "blib/lib/$_";
}

find({ wanted => \&_fill_dbgp, no_chdir => 1 }, 'DB');
find({ wanted => \&_fill_lib,  no_chdir => 1 }, 'Devel');

WriteMakefile(
    NAME              => "Devel::Debug::DBGp",
    PM                => \%pm,
    VERSION_FROM      => "Devel/Debug/DBGp.pm",
    ABSTRACT_FROM     => "Devel/Debug/DBGp.pm",
    AUTHOR            => 'Mattia Barbon <mbarbon@cpan.org>',
    MAN3PODS          => {
        # do not generate manpages for all internal POD
        'Devel/Debug/DBGp.pm'   =>
            'blib/man3/Devel::Debug::DBGp.3',
    },
    clean             => { FILES => 'DB/DbgrXS.pm' },
    $do_xs ? (
        XS                => { 'perl5db.xs' => undef },
        OBJECT            => 'perl5db.o',
    ) : (
        XS                => { },
        OBJECT            => '',
        C                 => [ ],
    ),
    ( $mm_ver >= 6.48 ?     ( MIN_PERL_VERSION  => 5.008 ) :
                            () ),
    ( $mm_ver >= 6.64 ?     ( TEST_REQUIRES     => \%test_requires ) :
      $mm_ver >= 6.5503 ?   ( BUILD_REQUIRES    => \%test_requires ) :
                            ( PREREQ_PM         => \%test_requires ) ),
    ( $mm_ver >= 6.31 ?     ( LICENSE           => 'artistic' ) :
                            () ),
    ( $mm_ver >= 6.46 ?
      ( META_MERGE  => {
          "meta-spec" => { version => 2 },
          no_index    => {
              file      => [ 'perl5db.pl' ],
              directory => [ 'DB' ],
          },
          resources   => {
              license     => [ 'http://dev.perl.org/licenses/artistic.html' ],
#              homepage    => 'https://github.com/mbarbon/perl-remote-debugging-client',
              bugtracker  => {
                  web    => 'https://github.com/mbarbon/perl-remote-debugging-client/issues',
              },
              repository  => {
                  url  => 'git@github.com:mbarbon/perl-remote-debugging-client.git',
                  web  => 'https://github.com/mbarbon/perl-remote-debugging-client',
                  type => 'git',
              },
          },
        },
      ) : () ),
);

# stolen from an old Scalar-List-Utils version
sub can_cc {
    foreach my $cmd (split(/ /, $Config::Config{cc})) {
        my $_cmd = $cmd;
        return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));

        for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
            my $abs = File::Spec->catfile($dir, $cmd);
            return $abs if (-x $abs or $abs = MM->maybe_command($abs));
        }
    }

    return;
}

package MY;

sub init_PM {
    my $self = shift;

    # without this, MakeMaker defaults to building Devel/Debug/DBGp.so,
    # which works, but I prefer the consistency
    $self->{PARENT_NAME} = '';
    $self->{BASEEXT} = 'perl5db';
    $self->{FULLEXT} = 'dbgp-helper/perl5db';

    return $self->SUPER::init_PM(@_);
}

# run tests twice, once for the XS version, once for the pure-Perl one
sub test_via_harness {
    my ($self, $perl, $tests) = @_;
    my $cmd = $self->SUPER::test_via_harness($perl, $tests);

    # use our own test harness wrapper
    $cmd =~ s{-MExtUtils::Command::MM}{-Mt::lib::Harness};
    $cmd =~ s{(test_harness\s*\()}{${1}DBGP_RUN_PP, };

    (my $cmd_pp = $cmd) =~ s{DBGP_RUN_PP}{q[perl]};
    (my $cmd_xs = $cmd) =~ s{DBGP_RUN_PP}{q[xs]};

    return ($cmd_pp, $cmd_xs);
}
