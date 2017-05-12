use 5.006002;

use strict;
use warnings;

$^O eq 'darwin'
    or die "OS unsupported\n";

use lib qw{ inc };

use Config;
use ExtUtils::MakeMaker;
use Getopt::Std;
use My::Module::Meta;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opt;
getopts ('ny', \%opt) or die <<'EOD';
The only legal options are
  -n = answer all questions 'no'.
  -y = answer all questions 'yes'.
You may not assert both of these at once - it is too confusing.
EOD

my $meta = My::Module::Meta->new();

my @exe_files;
my @clean_files;

$meta->want_pbtool( \%opt )
    and push @exe_files, 'script/pbtool';

push @clean_files, 'pbl';	# Just in case we built it.

(my $mmv = ExtUtils::MakeMaker->VERSION) =~ s/_//g;

my @ccflags = $meta->ccflags();

my %attr = (
    NAME              => 'Mac::Pasteboard',
    VERSION_FROM      => 'lib/Mac/Pasteboard.pm', # finds $VERSION
    PREREQ_PM         => $meta->requires(),
    ABSTRACT_FROM  => 'lib/Mac/Pasteboard.pm', # retrieve abstract from module
    AUTHOR         => 'Tom Wyant (wyant at cpan dot org)',
    LIBS              => [''], # e.g., '-lm'
    LDDLFLAGS	=> $Config{lddlflags} . ' -framework ApplicationServices',
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES)', # link all the C files too
    PL_FILES	=> {},	# Prevent old MakeMaker from running Build.PL
    EXE_FILES	=> \@exe_files,
    clean	=> {FILES => join ' ', @clean_files},	# Clean up executables.
    realclean	=> { FILES => 'cover_db *.gcov *.gcda *.gcno' },
    (@ccflags ? (CCFLAGS => join ' ', @ccflags) : ()),
);

$mmv >= 6.31 and $attr{LICENSE} = 'perl';

$mmv >= 6.4501
    and $attr{META_MERGE} = $meta->meta_merge();

$mmv >= 6.4701 and $attr{MIN_PERL_VERSION} = $meta->requires_perl();

$mmv >= 6.5501
    and $attr{BUILD_REQUIRES} = $meta->build_requires()
    or $mmv >= 6.4501
    and $attr{META_MERGE}{build_requires} = $meta->build_requires();

WriteMakefile(%attr);

sub MY::postamble {
    my ( $self, @args ) = @_;

    my $authortest = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(AUTHORTEST_FILES)' );
    $authortest =~ s/ \s+ \z //smx;
    $authortest =~ s/ \A \s+ //smx;
    chomp $authortest;

    return <<"EOD";

AUTHORTEST_FILES = t/*.t xt/author/*.t

authortest :: pure_all
	AUTHOR_TESTING=1 $authortest

testcover :: pure_all
	cover -test -ignore_re=inc/ -ignore_re=/System
EOD
}

=begin comment

sub MY::postamble {
    <<'eod';

pbl : pbl.c
	$(CC) -o pbl -DTEST $(PBL_FLAGS) pbl.c -framework ApplicationServices
eod
}

=end comment

=cut

# ex: set textwidth=72 :
