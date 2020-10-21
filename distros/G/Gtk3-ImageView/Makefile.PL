use ExtUtils::MakeMaker;

my $path = 'lib/Gtk3/ImageView.pm';
my $year = (localtime)[5] + 1900;

# Slurp the program source and dig out the version number.
my $text = do { local ( @ARGV, $/ ) = $path; <> };
my $version = $2 if ( $text =~ /^(my|our) \$VERSION\s*=\s*'?(.*)'?/m );

WriteMakefile(
    NAME      => 'Gtk3::ImageView',
    VERSION   => $version,
    PREREQ_PM => {
        Glib     => 1.210,
        Gtk3     => 0,
        Readonly => 0,
    },
    TEST_REQUIRES => {
        Test::More        => 0,
        Test::Differences => 0,
        Image::Magick     => 0,
        Try::Tiny         => 0,
        Test::MockObject  => 0,
        Carp::Always      => 0,
    },
    clean => { FILES => '$(SOURCE_TIDY)' },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => $path,    # retrieve abstract from module
            AUTHOR        => [
                'Jeffrey Ratcliffe <jffry@posteo.net>',
                'Alexey Sokolov <sokolov@google.com>',
            ]
          )
        : ()
    ),
);

sub MY::postamble {
    my $postamble = <<'END';
SHELL = bash
NAME = Gtk3-ImageView
MANIFEST = $(shell cat MANIFEST)
SOURCE = $(filter %.pm %.PL %.pl %.t,$(MANIFEST))
SOURCE_TIDY = $(foreach file,$(SOURCE),$(file).tdy)
TLD = net
VENDOR = sourceforge

htdocs/index.html : lib/Gtk3/ImageView.pm
	[ -d htdocs ] || mkdir htdocs
	pod2html --noindex --title=$(NAME)-$(VERSION) $* > $@

remote-html : htdocs/index.html
	scp htdocs/index.html ra28145,$(NAME)@web.sf.net:/home/groups/g/gs/$(NAME)/htdocs/

signed_tardist : tardist
	gpg --armor --detach-sign $(NAME)-$(VERSION).tar.gz

file_releases : signed_tardist
	scp $(NAME)-$(VERSION).tar.gz $(NAME)-$(VERSION).tar.gz.asc $< \
	  ra28145,$(NAME)@frs.sf.net:/home/frs/project/g/gs/$(NAME)/$(NAME)/$(VERSION)/

MANIFEST : $(SOURCE)
	git ls-files | egrep -v '^\.git' > $@

tidy : MANIFEST $(SOURCE_TIDY)

%.tdy : %
	perltidy $* && if ! diff -q $@ $* > /dev/null; then cp $@ $*; fi
END
    $postamble;
}
