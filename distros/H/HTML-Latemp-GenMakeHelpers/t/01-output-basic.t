#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use File::Temp qw/ tempdir /;
use File::Spec;

use HTML::Latemp::GenMakeHelpers;

{
my $finder = HTML::Latemp::GenMakeHelpers->new(
    'hosts' =>
    [
        {
            'id' => "src",
            'source_dir' => "t/sample-data/sample-site-1",
            'dest_dir' => "\$(HELLO)/src",
        },
    ],
);

my $host_outputs = $finder->process_host($finder->hosts()->[0]);

my $file_lists_expected = <<"EOF";
SRC_IMAGES = images/arrow-left-disabled.png images/arrow-left.png images/arrow-right-disabled.png images/arrow-right.png images/arrow-up-disabled.png images/arrow-up.png images/berlios-logo.png images/better-scm-logo.png images/get-firefox.png images/logo-wml.png images/somerights20.png images/valid-css.png images/valid-xhtml10.png images/valid-xhtml11.png print.css style.css subversion/Subversion-Win32-Installation-Guide.txt
SRC_DIRS = alternatives arch docs images irc site-map source subversion
SRC_DOCS = alternatives/index.html arch/index.html docs/index.html docs/nice_trys.html docs/shlomif-evolution.html index.html irc/index.html links.html mailing-list.html site-map/index.html source/index.html subversion/Svn-Win32-Inst-Guide.html subversion/compelling_alternative.html subversion/index.html
SRC_TTMLS =
EOF

my $rules_expected = <<'EOFGALOG';

SRC_SRC_DIR = t/sample-data/sample-site-1

SRC_DEST = $(HELLO)/src

SRC_TARGETS = $(SRC_DEST) $(SRC_DIRS_DEST) $(SRC_COMMON_DIRS_DEST) $(SRC_COMMON_IMAGES_DEST) $(SRC_COMMON_DOCS_DEST) $(SRC_COMMON_TTMLS_DEST) $(SRC_IMAGES_DEST) $(SRC_DOCS_DEST) $(SRC_TTMLS_DEST)

SRC_WML_FLAGS = $(WML_FLAGS) -DLATEMP_SERVER=src

SRC_TTML_FLAGS = $(TTML_FLAGS) -DLATEMP_SERVER=src

SRC_DOCS_DEST = $(patsubst %,$(SRC_DEST)/%,$(SRC_DOCS))

SRC_DIRS_DEST = $(patsubst %,$(SRC_DEST)/%,$(SRC_DIRS))

SRC_IMAGES_DEST = $(patsubst %,$(SRC_DEST)/%,$(SRC_IMAGES))

SRC_TTMLS_DEST = $(patsubst %,$(SRC_DEST)/%,$(SRC_TTMLS))

SRC_COMMON_IMAGES_DEST = $(patsubst %,$(SRC_DEST)/%,$(COMMON_IMAGES))

SRC_COMMON_DIRS_DEST = $(patsubst %,$(SRC_DEST)/%,$(COMMON_DIRS))

SRC_COMMON_TTMLS_DEST = $(patsubst %,$(SRC_DEST)/%,$(COMMON_TTMLS))

SRC_COMMON_DOCS_DEST = $(patsubst %,$(SRC_DEST)/%,$(COMMON_DOCS))

$(SRC_DOCS_DEST) : $(SRC_DEST)/% : $(SRC_SRC_DIR)/%.wml $(DOCS_COMMON_DEPS)
	 WML_LATEMP_PATH="$$(perl -MFile::Spec -e 'print File::Spec->rel2abs(shift)' '$@')" ; ( cd $(SRC_SRC_DIR) && wml -o "$${WML_LATEMP_PATH}" $(SRC_WML_FLAGS) -DLATEMP_FILENAME=$(patsubst $(SRC_DEST)/%,%,$(patsubst %.wml,%,$@)) $(patsubst $(SRC_SRC_DIR)/%,%,$<) )

$(SRC_TTMLS_DEST) : $(SRC_DEST)/% : $(SRC_SRC_DIR)/%.ttml $(TTMLS_COMMON_DEPS)
	ttml -o $@ $(SRC_TTML_FLAGS) -DLATEMP_FILENAME=$(patsubst $(SRC_DEST)/%,%,$(patsubst %.ttml,%,$@)) $<

$(SRC_DIRS_DEST) : $(SRC_DEST)/% :
	mkdir -p $@
	touch $@

$(SRC_IMAGES_DEST) : $(SRC_DEST)/% : $(SRC_SRC_DIR)/%
	cp -f $< $@

$(SRC_COMMON_IMAGES_DEST) : $(SRC_DEST)/% : $(COMMON_SRC_DIR)/%
	cp -f $< $@

$(SRC_COMMON_TTMLS_DEST) : $(SRC_DEST)/% : $(COMMON_SRC_DIR)/%.ttml $(TTMLS_COMMON_DEPS)
	ttml -o $@ $(SRC_TTML_FLAGS) -DLATEMP_FILENAME=$(patsubst $(SRC_DEST)/%,%,$(patsubst %.ttml,%,$@)) $<

$(SRC_COMMON_DOCS_DEST) : $(SRC_DEST)/% : $(COMMON_SRC_DIR)/%.wml $(DOCS_COMMON_DEPS)
	WML_LATEMP_PATH="$$(perl -MFile::Spec -e 'print File::Spec->rel2abs(shift)' '$@')" ; ( cd $(COMMON_SRC_DIR) && wml -o "$${WML_LATEMP_PATH}" $(SRC_WML_FLAGS) -DLATEMP_FILENAME=$(patsubst $(SRC_DEST)/%,%,$(patsubst %.wml,%,$@)) $(patsubst $(COMMON_SRC_DIR)/%,%,$<) )

$(SRC_COMMON_DIRS_DEST)  : $(SRC_DEST)/% :
	mkdir -p $@
	touch $@

$(SRC_DEST):
	mkdir -p $@
	touch $@
EOFGALOG

# TEST
is ($host_outputs->{'file_lists'}, $file_lists_expected, "File Lists");

# TEST
is_deeply ([split(/\n/, $host_outputs->{'rules'}, -1)],
    [split(/\n/, $rules_expected, -1)], "Rules");
}

{
my $finder = HTML::Latemp::GenMakeHelpers->new(
    'hosts' =>
    [
        {
            'id' => "src",
            'source_dir' => "t/sample-data/sample-site-1",
            'dest_dir' => "\$(HELLO)/src",
        },
    ],
    filename_lists_post_filter => sub {
        my ($args) = @_;
        my $filenames = $args->{filenames};
        if ($args->{host} eq 'src' and $args->{bucket} eq 'IMAGES')
        {
            return [ grep { $_ !~ m#arrow-right# } @$filenames ];
        }
        else
        {
            return $filenames;
        }
    },
);

my $host_outputs = $finder->process_host($finder->hosts()->[0]);

my $file_lists_expected = <<"EOF";
SRC_IMAGES = images/arrow-left-disabled.png images/arrow-left.png images/arrow-up-disabled.png images/arrow-up.png images/berlios-logo.png images/better-scm-logo.png images/get-firefox.png images/logo-wml.png images/somerights20.png images/valid-css.png images/valid-xhtml10.png images/valid-xhtml11.png print.css style.css subversion/Subversion-Win32-Installation-Guide.txt
SRC_DIRS = alternatives arch docs images irc site-map source subversion
SRC_DOCS = alternatives/index.html arch/index.html docs/index.html docs/nice_trys.html docs/shlomif-evolution.html index.html irc/index.html links.html mailing-list.html site-map/index.html source/index.html subversion/Svn-Win32-Inst-Guide.html subversion/compelling_alternative.html subversion/index.html
SRC_TTMLS =
EOF

my $rules_expected = <<'EOFGALOG';

SRC_SRC_DIR = t/sample-data/sample-site-1

SRC_DEST = $(HELLO)/src

SRC_TARGETS = $(SRC_DEST) $(SRC_DIRS_DEST) $(SRC_COMMON_DIRS_DEST) $(SRC_COMMON_IMAGES_DEST) $(SRC_COMMON_DOCS_DEST) $(SRC_COMMON_TTMLS_DEST) $(SRC_IMAGES_DEST) $(SRC_DOCS_DEST) $(SRC_TTMLS_DEST)

SRC_WML_FLAGS = $(WML_FLAGS) -DLATEMP_SERVER=src

SRC_TTML_FLAGS = $(TTML_FLAGS) -DLATEMP_SERVER=src

SRC_DOCS_DEST = $(patsubst %,$(SRC_DEST)/%,$(SRC_DOCS))

SRC_DIRS_DEST = $(patsubst %,$(SRC_DEST)/%,$(SRC_DIRS))

SRC_IMAGES_DEST = $(patsubst %,$(SRC_DEST)/%,$(SRC_IMAGES))

SRC_TTMLS_DEST = $(patsubst %,$(SRC_DEST)/%,$(SRC_TTMLS))

SRC_COMMON_IMAGES_DEST = $(patsubst %,$(SRC_DEST)/%,$(COMMON_IMAGES))

SRC_COMMON_DIRS_DEST = $(patsubst %,$(SRC_DEST)/%,$(COMMON_DIRS))

SRC_COMMON_TTMLS_DEST = $(patsubst %,$(SRC_DEST)/%,$(COMMON_TTMLS))

SRC_COMMON_DOCS_DEST = $(patsubst %,$(SRC_DEST)/%,$(COMMON_DOCS))

$(SRC_DOCS_DEST) : $(SRC_DEST)/% : $(SRC_SRC_DIR)/%.wml $(DOCS_COMMON_DEPS)
	 WML_LATEMP_PATH="$$(perl -MFile::Spec -e 'print File::Spec->rel2abs(shift)' '$@')" ; ( cd $(SRC_SRC_DIR) && wml -o "$${WML_LATEMP_PATH}" $(SRC_WML_FLAGS) -DLATEMP_FILENAME=$(patsubst $(SRC_DEST)/%,%,$(patsubst %.wml,%,$@)) $(patsubst $(SRC_SRC_DIR)/%,%,$<) )

$(SRC_TTMLS_DEST) : $(SRC_DEST)/% : $(SRC_SRC_DIR)/%.ttml $(TTMLS_COMMON_DEPS)
	ttml -o $@ $(SRC_TTML_FLAGS) -DLATEMP_FILENAME=$(patsubst $(SRC_DEST)/%,%,$(patsubst %.ttml,%,$@)) $<

$(SRC_DIRS_DEST) : $(SRC_DEST)/% :
	mkdir -p $@
	touch $@

$(SRC_IMAGES_DEST) : $(SRC_DEST)/% : $(SRC_SRC_DIR)/%
	cp -f $< $@

$(SRC_COMMON_IMAGES_DEST) : $(SRC_DEST)/% : $(COMMON_SRC_DIR)/%
	cp -f $< $@

$(SRC_COMMON_TTMLS_DEST) : $(SRC_DEST)/% : $(COMMON_SRC_DIR)/%.ttml $(TTMLS_COMMON_DEPS)
	ttml -o $@ $(SRC_TTML_FLAGS) -DLATEMP_FILENAME=$(patsubst $(SRC_DEST)/%,%,$(patsubst %.ttml,%,$@)) $<

$(SRC_COMMON_DOCS_DEST) : $(SRC_DEST)/% : $(COMMON_SRC_DIR)/%.wml $(DOCS_COMMON_DEPS)
	WML_LATEMP_PATH="$$(perl -MFile::Spec -e 'print File::Spec->rel2abs(shift)' '$@')" ; ( cd $(COMMON_SRC_DIR) && wml -o "$${WML_LATEMP_PATH}" $(SRC_WML_FLAGS) -DLATEMP_FILENAME=$(patsubst $(SRC_DEST)/%,%,$(patsubst %.wml,%,$@)) $(patsubst $(COMMON_SRC_DIR)/%,%,$<) )

$(SRC_COMMON_DIRS_DEST)  : $(SRC_DEST)/% :
	mkdir -p $@
	touch $@

$(SRC_DEST):
	mkdir -p $@
	touch $@
EOFGALOG

# TEST
is ($host_outputs->{'file_lists'}, $file_lists_expected, "File Lists");

# TEST
is_deeply ([split(/\n/, $host_outputs->{'rules'}, -1)],
    [split(/\n/, $rules_expected, -1)], "Rules");
}
{
    my $DIR = tempdir( CLEANUP => 1);
    my $finder = HTML::Latemp::GenMakeHelpers->new(
        'hosts' =>
        [
            {
                'id' => "common",
                'source_dir' => "t/sample-data/common-1",
                'dest_dir' => "\$(HELLO)/src",
            },
            {
                'id' => "src",
                'source_dir' => "t/sample-data/sample-site-1",
                'dest_dir' => "\$(HELLO)/src",
            },
        ],
        out_dir => $DIR,
    );
    $finder->process_all();

    # TEST
    ok (scalar (-f File::Spec->catfile($DIR, "include.mak")), "include.mak was written.");
    # TEST
    ok (scalar (-f File::Spec->catfile($DIR, "rules.mak")), "rules.mak was written.");
}
