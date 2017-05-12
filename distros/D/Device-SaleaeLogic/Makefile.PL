use 5.010001;
use Config qw/%Config/;

die 'No support for OS' unless $^O =~ /linux|darwin|mswin32/i;

die 'No support for OS' if ($Config{archname} =~ /x64|x86_64/ and $^O =~ /darwin|mswin32/i);
die 'No support for OS' if ($Config{ptrsize} eq 8 and $^O =~ /darwin|mswin32/i);

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $SUFF = '';
$SUFF = 'lib' if $^O =~ /linux|darwin/i;
my $otherldflags = '';
$otherldflags = '-m32' if $^O =~ /darwin|mswin32/i;
WriteMakefile(
    NAME              => 'Device::SaleaeLogic',
    VERSION_FROM      => 'lib/Device/SaleaeLogic.pm', # finds $VERSION
    LICENSE           => 'mit',
    PREREQ_PM         => {
        'LWP::Simple'   => 0,
        'Archive::Zip'  => 0,
    }, # e.g., Module::Name => 1.1
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker'     => 0,
      'File::ShareDir::Install' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'  => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/SaleaeLogic.pm', # retrieve abstract from module
       AUTHOR         => 'Vikas Kumar <vikas@selectiveintellect.com>') : ()),
    LIBS              => ['-L. -lSaleaeDevice'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    CCFLAGS           => $otherldflags,
	# Un-comment this if you add C files to link with later:
    OBJECT            => 'SaleaeLogic.o saleaeinterface.o', # link all the C files too
    ### we are doing this so that the header files needed are downloaded first
    #and the make file dependencies are managed appropriately
    PL_FILES          => { 'getSDK.PL' => '$(H_FILES)' },
    dynamic_lib       => { OTHERLDFLAGS => $otherldflags , INST_DYNAMIC_DEP => "${SUFF}SaleaeDevice.\$(SO)" },
);

package MY;
use File::ShareDir::Install;

sub postamble {
    my $self = shift;
    my @ret = File::ShareDir::Install::postamble($self);
    my $code = << "SDK_INST";
SaleaeDeviceApi.h :: pm_to_blib
\tcp -v \$(INST_DYNAMIC_DEP) \$(INST_ARCHAUTODIR)
\tcp -v \$(INST_DYNAMIC_DEP) \$(INST_LIB)
SDK_INST
    push @ret, $code if $^O =~ /linux|darwin/i;
    return join "\n", @ret;
}

sub const_loadlibs {
    my $self = shift;
    my @ret = $self->SUPER::const_loadlibs();
    push @ret, 'BSLOADLIBS = -L$(INST_LIBDIR) -L$(INST_ARCHLIBDIR) -L$(INST_AUTODIR) -L$(INST_ARCHAUTODIR) -lSaleaeDevice';
    return join "\n", @ret;
}

sub post_constants {
    my $self = shift;
    my @ret = $self->SUPER::post_constants();
    push @ret, '$(H_FILES) = $(H_FILES) SaleaeDeviceApi.h';
    return join "\n", @ret;
}

__END__
