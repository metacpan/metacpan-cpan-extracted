package EBook::Gutenberg;
use 5.016;
our $VERSION = '1.00';
use strict;
use warnings;

use Getopt::Long;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempfile);
use JSON::PP;
use List::Util qw(all first max);

use EBook::Gutenberg::Catalog;
use EBook::Gutenberg::Dialog qw(:codes);
use EBook::Gutenberg::Get;
use EBook::Gutenberg::Home;

my $PRGNAM = 'gutenberg';
my $PRGVER = $VERSION;

my $HELP = <<"HERE";
$PRGNAM - $PRGVER

Usage: $0 [options] command [command options] [args]

Commands:
  update            Update local Project Gutenberg catalog
  get <target>      Download ebook matching target
  search <target>   Search for ebooks matching target
  meta <id>         Dump ebook metadata
  menu              Launch gutenberg ncurses interface

Options:
  -d|--data=<dir>   gutenberg data directory
  -y|--no-prompt    Disable prompts for user input
  -q|--quiet        Disable informative output
  -h|--help         Print this help message
  -v|--version      Print gutenberg version

Consult the gutenberg(1) manual for documentation on command-specific options.
HERE

my $VER_MSG = <<"HERE";
$PRGNAM - $PRGVER

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
HERE

my %COMMANDS = (
    'update' => \&update,
    'search' => \&search,
    'get'    => \&get,
    'meta'   => \&meta,
    'menu'   => \&menu,
);

my $OLD_DEFAULT_DATA = File::Spec->catfile(home, '.gutenberg');
my $DOT_LOCAL = File::Spec->catfile(home, '.local/share');

my $ARG_MAX = 4096;

sub _default_data {

    # The default prior to 0.03
    if (-d $OLD_DEFAULT_DATA) {
        return $OLD_DEFAULT_DATA;
    }

    if (exists $ENV{ XDG_DATA_HOME } and -d $ENV{ XDG_DATA_HOME }) {
        return File::Spec->catfile($ENV{ XDG_DATA_HOME }, 'gutenberg');
    }

    if (-d $DOT_LOCAL) {
        return File::Spec->catfile($DOT_LOCAL, 'gutenberg');
    }

    return $OLD_DEFAULT_DATA;

}

sub _prompt {

    my $prompt = shift;

    while (1) {
        print "$prompt [y/N] ";
        my $in = readline STDIN;
        chomp $in;
        if (fc $in eq fc 'y') {
            return 1;
        } elsif ($in eq '' or fc $in eq fc 'n') {
            return 0;
        } else {
            warn "'$in' is an invalid reponse\n";
        }
    }

}

# Ask user to select a number out of a given list valid numbers
sub _nprompt {

    my $prompt = shift;
    my %n = map { $_ => 1 } @_;

    while (1) {
        print "$prompt ";
        my $in = readline STDIN;
        chomp $in;
        if ($in eq '' or fc $in eq fc 'n') {
            return undef;
        } elsif ($in =~ /^\d+$/ and exists $n{ $in }) {
            return $in;
        } else {
            warn "'$in' is an invalid reponse\n";
        }
    }

}

sub _title2rx {

    my $title = shift;

    my $rx;

    if ($title =~ /^\/(.*)\/$/) {
        $rx = qr/$1/i;
    # treat as literal string
    } else {
        $rx = qr/\Q$title\E/i;
    }

    return $rx;

}

sub _target2param {

    my $targ = shift;

    if ($targ =~ /^\d+$/) {
        return id => $targ;
    } else {
        return title => _title2rx($targ);
    }

}

sub _book_meta_str {

    my $book = shift;

    return <<"HERE";
ID:       $book->{ 'Text#'     }
Title:    $book->{ Title       }
Type:     $book->{ Type        }
Issued:   $book->{ Issued      }
Authors:  $book->{ Authors     }
Language: $book->{ Language    }
Subjects: $book->{ Subjects    }
Shelves:  $book->{ Bookshelves }
LoCC:     $book->{ LoCC        }
HERE

}

sub _book_meta_json {

    my $book = shift;

    my %copy = %$book;;

    for my $k (qw(Authors Subjects Bookshelves LoCC)) {
        $copy{ $k } = [ split /\s*;\s*/, $copy{ $k } ];
    }

    my $json = JSON::PP->new->pretty(1)->canonical(1);

    return $json->encode(\%copy);

}

sub _touch_get {

    my $self = shift;

    # touch file
    if (-f $self->{ GetFile }) {
        utime undef, undef, $self->{ GetFile };
    # create file if it doesn't exist
    } else {
        my $fh;
        open $fh, '>', $self->{ GetFile } and close $fh
            or die "Failed to open $self->{ GetFile } for writing: $!\n";
    }

    return 1;

}

# Wait at least 5 seconds between multiple Project Gutenberg network
# operations (update, get)
sub _get_ok {

    my $self = shift;

    return time - ((stat($self->{ GetFile }))[9] // 0) > 5;

}

sub _gen_search_params {

    my $self = shift;

    my %search;

    if (@{ $self->{ Args } }) {
       my ($k, $v) = _target2param($self->{ Args }->[0]);
        $search{ $k } = $v;
    }

    if (@{ $self->{ Authors } }) {
        $search{ authors } = $self->{ Authors };
    }

    if (@{ $self->{ Subjects } }) {
        $search{ subjects } = $self->{ Subjects };
    }

    if (defined $self->{ Language }) {
        $search{ language } = $self->{ Language };
    }

    if (@{ $self->{ Shelves } }) {
        $search{ shelves } = $self->{ Shelves };
    }

    return %search;

}

sub _search {

    my $self   = shift;
    my %params = @_;

    my $catalog = EBook::Gutenberg::Catalog->new($self->{ Catalog });

    my $filter = {
        Type => sub { $_ eq 'Text' },
    };

    if (defined $params{ title }) {
        $filter->{ Title } = sub { m/$params{ title }/i };
    }

    if (defined $params{ id }) {
        $filter->{ 'Text#' } = sub { $_ == $params{ id } };
    }

    # Get a list words from each supplied author parameter, with non-word
    # characters stripped out. Then filter out books that do not contain every
    # word from that list in their author entries. This seems to be the simplest
    # and DWIMest way of going about this that I could find.
    if (defined $params{ authors } and @{ $params{ authors } }) {
        my @words =
            map { split /\s+/ }
            map { s/\W+/ /gr }
            @{ $params{ authors } };
        $filter->{ Authors } = sub {
            my $a = $_;
            all { $a =~ m/(^|\W)\Q$_\E(\W|$)/i } @words;
        };
    }

    # Same as authors
    if (defined $params{ subjects } and @{ $params{ subjects } }) {
        my @words =
            map { split /\s+/ }
            map { s/\W+/ /gr }
            @{ $params{ subjects } };
        $filter->{ Subjects } = sub {
            my $a = $_;
            all { $a =~ m/(^|\W)\Q$_\E(\W|$)/i } @words;
        };
    }

    # Same as authors
    if (defined $params{ shelves } and @{ $params{ shelves } }) {
        my @words =
            map { split /\s+/ }
            map { s/\W+/ /gr }
            @{ $params{ shelves } };
        $filter->{ Bookshelves } = sub {
            my $a = $_;
            all { $a =~ m/(^|\W)\Q$_\E(\W|$)/i } @words;
        };
    }

    if (defined $params{ language }) {
        $filter->{ Language } = sub { $_ eq $params{ language } };
    }

    my @books = @{ $catalog->books($filter) };

    return @books;

}

sub _print_list {

    my @books = @_;

    # ugly :-(
    my $idlen = max (length('ID'), map { length $_->{ 'Text#' } } @books);
    printf "%-*s  %s\n", $idlen, 'ID', 'Title';
    printf "%s\n", '-' x 25;
    for my $b (@books) {
        printf "%-*s  %s\n", $idlen, $b->{ 'Text#' }, $b->{ Title };
    }

}

sub _dialog_search {

    my $self = shift;

    state $ltitl = '';
    state $lauth = '';
    state $lsubj = '';
    state $llang = '';
    state $lshlf = '';
    state $lebid = '';

    while (1) {

        my ($rv, $form) = $self->{ Dialog }->form(
           <<'HERE',
Search for an ebook using the parameter fields below. Fields left blank will be
ignored. The "Title" field can be given a Perl regex if the input starts and
ends with a slash (/) character.
HERE
            17, 45, 6,
            'Title',    1, 0, $ltitl, 1, 10, 36, 255,
            'Author',   2, 0, $lauth, 2, 10, 36, 255,
            'Subject',  3, 0, $lsubj, 3, 10, 36, 255,
            'Language', 4, 0, $llang, 4, 10, 36, 255,
            'Shelf',    5, 0, $lshlf, 5, 10, 36, 255,
            'ID',       6, 0, $lebid, 6, 10, 36, 255,
            {
                title => 'Search',
                ok_label => 'Search',
                extra_button => 1,
                extra_label => 'Update',
                erase_on_exit => 1,
            },
        );

        last if $rv == DIALOG_CANCEL or $rv == DIALOG_ESC;

        $self->{ Dialog }->infobox('Searching...', 0, 0);

        ($ltitl, $lauth, $lsubj, $llang, $lshlf, $lebid) = @$form;

        if ($rv == DIALOG_EXTRA) {
            $rv = $self->{ Dialog }->yesno(
                'Would you like to update your local gutenberg catalog?', 0, 0
            );
            next if $rv != DIALOG_OK;
            $self->{ Dialog }->infobox('Updating gutenberg catalog...', 0, 0);
            my $catalog = EBook::Gutenberg::Catalog->new($self->{ Catalog });
            sleep 5 unless $self->_get_ok;
            $self->_touch_get;
            eval { $catalog->fetch };
            if ($@ ne '') {
                $self->{ Dialog }->msgbox("Failed to fetch catalog: $@", 0, 0);
                next;
            }
            $self->{ Dialog }->msgbox(
                "Successfully updated gutenberg catalog", 0, 0
            );
        } elsif ($rv == DIALOG_OK) {

            unless (-s $self->{ Catalog }) {
                $self->{ Dialog }->msgbox(
                    <<'HERE', 0, 0
No existing Project Gutenberg catalog found. Please run a catalog update before
searching.
HERE
                );
                next;
            }

            my %param;

            if ($ltitl ne '') {
               $param{ title } = _title2rx($ltitl);
            }

            if ($lauth ne '') {
                $param{ authors } = [ $lauth ];
            }

            if ($lsubj ne '') {
                $param{ subjects } = [ $lsubj ];
            }

            if ($llang ne '') {
                $param{ language } = $llang;
            }

            if ($lshlf ne '') {
                $param{ shelves } = [ $lshlf ];
            }

            if ($lebid ne '') {
                unless ($lebid =~ /^\d+$/) {
                    $self->{ Dialog }->msgbox(
                        "'ID' must be an integar", 0, 0
                    );
                    next;
                }
                $param{ id } = $lebid;
            }

            unless (%param) {
                $self->{ Dialog }->msgbox(
                    'No search parameters provided.', 0, 0
                );
                next;
            }

            my @books = $self->_search(%param);

            if (@books > $ARG_MAX) {
                $self->{ Dialog }->msgbox(
                    'Too many search results. Please narrow your search parameters.',
                    0, 0
                );
                next;
            } elsif (@books == 0) {
                $self->{ Dialog }->msgbox(
                    'Found no ebooks matching the given search parameters.', 0, 0
                );
            } else {
                $self->_dialog_download_select(\@books);
            }
        }
    }

    return 1;

}

sub _dialog_download_select {

    my $self  = shift;
    my $books = shift;

    my @iter = map { $_->{ 'Text#' } => $_->{ Title } } @$books;

    while (1) {

        my ($rv, $sel) = $self->{ Dialog }->menu(
            '', 0, 0, 0,
            @iter,
            {
                title => 'Search Results',
                ok_label => 'View',
            },
        );

        last if $rv == DIALOG_CANCEL or $rv == DIALOG_ESC;

        my $book = first { $_->{ 'Text#' } == $sel } @$books;

        $self->_dialog_ebook($book);

    }

    return 1;

}

sub _dialog_ebook {

    my $self = shift;
    my $book = shift;

    while (1) {

        my $rv = $self->{ Dialog }->yesno(
            _book_meta_str($book), 0, 0,
            {
                title => $book->{ Title },
                yes_label => 'Download',
                extra_button => 1,
                extra_label => 'Read',
                no_label => 'Cancel',
            },
        );

        if ($rv == DIALOG_OK) {
            $self->_dialog_download_format($book);
        } elsif ($rv == DIALOG_EXTRA) {
            $self->_dialog_read($book);
        } elsif ($rv == DIALOG_CANCEL or $rv == DIALOG_ESC) {
            last;
        }

    }

    return 1;

}

sub _dialog_download_format {

    my $self = shift;
    my $book = shift;

    while (1) {

        my ($rv, $sel) = $self->{ Dialog }->menu(
            '', 0, 0, 0,
            'epub3', 'Newer style EPUB. May not be compatible with older e-readers.',
            'epub', 'Older style EPUB. Better compatibility with older e-readers.',
            'epub-noimages', 'Same as "epub" but with no images.',
            'kindle', 'KF8 ebook, an Amazon-proprietary format used by newer Kindle devices.',
            'mobi', 'Ebook format commonly used by older Kindle devices.',
            'text', 'Plain text file.',
            'zip', 'Zip archive of HTML and images.',
            'html', 'Single HTML page.',
            {
                title => 'Format Selection',
            },
        );

        last if $rv == DIALOG_CANCEL or $rv == DIALOG_ESC;

        $self->_dialog_download($book, $sel);

    }

}

sub _dialog_download {

    my $self = shift;
    my $book = shift;
    my $fmt  = shift;

    my $default = sprintf "%s.%s",
        $book->{ Title },
        $EBook::Gutenberg::Get::FORMATS{ $fmt }->{ suffix };


    my ($rv, $path) = $self->{ Dialog }->inputbox(
        'Please input the path to write the downloaded ebook to.', 0, 0,
        $default,
    );

    return 1 if $rv == DIALOG_CANCEL or $rv == DIALOG_ESC;

    $self->{ Dialog }->infobox('Fetching ebook...', 0, 0);

    my $p = eval {
        sleep 5 unless $self->_get_ok;
        $self->_touch_get;
        gutenberg_get(
            $book->{ 'Text#' },
            { fmt => $fmt, to => $path }
        );
    };

    if ($@ ne '') {
        $self->{ Dialog }->msgbox(
            "Failed to fetch ebook: $@", 0, 0
        );
        return 1;
    }

    $self->{ Dialog }->msgbox(
        "Successfully fetched $p", 0, 0
    );

    return 1;

}

sub _dialog_read {

    my $self = shift;
    my $book = shift;

    $self->{ Dialog }->infobox(
        'Fetching text...', 0, 0
    );

    my $file = $self->{ TxtCache }{ $book->{ 'Text#' } } // do {

        my $p = eval {
            my $tmp = do {
                my ($fh, $fn) = tempfile;
                close $fh;
                $fn;
            };
            # TODO: Sleep less?
            sleep 5 unless $self->_get_ok;
            $self->_touch_get;
            gutenberg_get(
                $book->{ 'Text#' },
                { fmt => 'text', to => $tmp },
            );
        };

        if ($@ ne '') {
            $self->{ Dialog }->msgbox(
                "Failed to fetch ebook: $@", 0, 0
            );
            return 1;
        }

        $self->{ TxtCache }{ $book->{ 'Text#' } } = $p;

    };

    # dialog does have a textbox widget, but it doesn't display large text files
    # like Gutenberg's text ebooks correctly, so we'll just use a pager instead.
    $self->{ Dialog }->pager($file);

    return 1;

}

sub help {

    my $self = shift;
    my $exit = shift;

    print $HELP;

    exit $exit if defined $exit;

    return 1;

}

sub update {

    my $self = shift;

    my $catalog = EBook::Gutenberg::Catalog->new($self->{ Catalog });

    unless ($self->_get_ok) {
        die "Please wait at least 5 seconds before performing another " .
            "network operation with Project Gutenberg\n";
    }

    unless ($self->{ Quiet }) {
        say "Fetching Project Gutenberg catalog, please be patient";
    }

    $catalog->fetch;

    $self->_touch_get;

    unless ($self->{ Quiet }) {
        say "Updated $self->{ Catalog }";
    }

    return 1;

}

sub search {

    my $self = shift;

    unless (-f $self->{ Catalog }) {
        die "Could not find an existing Project Gutenberg catalog, please " .
            "run 'update' to fetch a catalog before running 'search'\n";
    }

    my %search = $self->_gen_search_params;

    unless (%search) {
        $self->help(1);
    }

    my @books = $self->_search(%search);

    if (@books == 0) {
        die "Could not find any ebooks matching the given parameters\n";
    } else {
        _print_list(@books);
    }

    return 1;

}

sub get {

    my $self = shift;

    unless (-f $self->{ Catalog }) {
        die "Could not find an existing Project Gutenberg catalog, please " .
            "run 'update' to fetch a catalog before running 'get'\n";
    }

    unless ($self->_get_ok) {
        die "Please wait at least 5 seconds before performing another " .
            "network operation with Project Gutenberg\n";
    }

    my %search = $self->_gen_search_params;

    unless (%search) {
        $self->help(1);
    }

    my @books = $self->_search(%search);

    my $sel;

    if (@books == 0) {
        die "Could not find any ebooks matching the given parameters\n";
    } elsif (@books == 1 or $self->{ NoPrompt }) {
        $sel = $books[0];
    } else {

        my %nmap = map { $books[$_]->{ 'Text#' } => $_ } 0 .. $#books;

        _print_list(@books);

        if (@books >= 100 and !$self->{ Quiet }) {
            say "You might consider narrowing your search parameters";
        }

        my $n = _nprompt("Please select an ebook ID:", keys %nmap);

        unless (defined $n) {
            say "Doing nothing" unless $self->{ Quiet };
            return 1;
        }

        $sel = $books[$nmap{ $n }];

    }

    unless ($sel->{ Type } eq 'Text') {
        die "gutenberg does not currently support fetching non-text ebooks\n";
    }

    my $ok = $self->{ NoPrompt } ? 1 : do {
        print _book_meta_str($sel);
        _prompt("Would you like to download this ebook?");
    };

    unless ($ok) {
        say "Doing nothing" unless $self->{ Quiet };
        return 1;
    }

    my $link = gutenberg_link($sel->{ 'Text#' }, $self->{ Format });

    unless ($self->{ Quiet }) {
        say "Fetching $link, please be patient.";
    }

    my $fetch = gutenberg_get(
        $sel->{ 'Text#' },
        {
            fmt => $self->{ Format },
            to  => $self->{ To } // "$sel->{ Title }.*",
        }
    );

    $self->_touch_get;

    unless ($self->{ Quiet }) {
        say "Downloaded ebook to $fetch";
    }

    return 1;

}

sub meta {

    my $self = shift;

    unless (-f $self->{ Catalog }) {
        die "Could not find an existing Project Gutenberg catalog, please " .
            "run 'update' to fetch a catalog before running 'meta'\n";
    }

    my $id = shift @{ $self->{ Args } }
        or $self->help(1);

    unless ($id =~ /^\d+$/) {
        die "'meta' must be given an ebook ID as argument\n";
    }

    my $catalog = EBook::Gutenberg::Catalog->new($self->{ Catalog });

    my $book = $catalog->book($id);

    unless (defined $book) {
        die "Could not find an ebook with an ID of $id\n";
    }

    if ($self->{ MetaJSON }) {
        print _book_meta_json($book);
    } else {
        print _book_meta_str($book);
    }

    return 1;

}

sub menu {

    my $self = shift;

    my $dialog;
    my ($rv, $sel);

    $self->{ Dialog } = EBook::Gutenberg::Dialog->new(
        backtitle => "$PRGNAM $PRGVER"
    );

    $self->_dialog_search;

    return 1;

}

sub init {

    my $class = shift;

    my $self = {
        Command  => undef,
        Data     => undef,
        To       => undef,
        Format   => undef,
        Authors  => [],
        Subjects => [],
        Language => undef,
        Shelves  => [],
        NoPrompt => 0,
        Quiet    => 0,
        MetaJSON => 0,
        Args     => [],
        # Not set by any option
        Catalog  => undef,
        GetFile  => undef,
        Dialog   => undef,
        TxtCache => {},
    };

    bless $self, $class;

    Getopt::Long::config('bundling');
    GetOptions(
        'data|d=s'     => \$self->{ Data     },
        'to|t=s'       => \$self->{ To       },
        'format|f=s'   => \$self->{ Format   },
        'author|a=s'   =>  $self->{ Authors  },
        'subject|s=s'  =>  $self->{ Subjects },
        'language|l=s' => \$self->{ Language },
        'shelf|H=s'    =>  $self->{ Shelves  },
        'no-prompt|y'  => \$self->{ NoPrompt },
        'quiet|q'      => \$self->{ Quiet    },
        'json|j'       => \$self->{ MetaJSON },
        'help|h'    => sub { $self->help(0);         },
        'version|v' => sub { print $VER_MSG; exit 0; },
    ) or die "Invalid command line arguments\n";

    $self->{ Command } = shift @ARGV or $self->help(1);
    $self->{ Args } = [ @ARGV ];

    unless (exists $COMMANDS{ $self->{ Command } }) {
        die "'$self->{ Command }' is not a valid command\n";
    }

    $self->{ Data } //= $ENV{ GUTENBERG_DATA };
    $self->{ Data } //= _default_data;
    unless (-d $self->{ Data }) {
        make_path($self->{ Data });
    }
    $self->{ Catalog } = File::Spec->catfile(
        $self->{ Data },
        'pg_catalog.csv'
    );
    # GetFile is used to keep track of the last time we fetched something from
    # Project Gutenberg. gutenberg tries to wait at least 5 seconds between
    # Project Gutenberg network operations.
    $self->{ GetFile } = File::Spec->catfile(
        $self->{ Data },
        'get'
    );

    $self->{ Format } //= 'epub3';
    $self->{ Format } = lc $self->{ Format };
    unless (exists $EBook::Gutenberg::Get::FORMATS{ $self->{ Format } }) {
        die "'$self->{ Format }' is not a valid ebook format\n";
    }

    if (defined $self->{ Language }) {
        unless (length $self->{ Language } == 2) {
            die "-l|--language takes a two-character language code as argument\n";
        }
        $self->{ Language } = lc $self->{ Language };
    }

    binmode *STDOUT, ':utf8';

    return $self;

}

sub run {

    my $self = shift;

    $COMMANDS{ $self->{ Command } }($self);

    return 1;

}

DESTROY {

    my $self = shift;

    for my $f (keys %{ $self->{ TxtCache } }) {
        unlink $f if -e $f;
    }

}

1;

=head1 NAME

EBook::Gutenberg - Fetch ebooks from Project Gutenberg

=head1 SYNOPSIS

  use EBook::Gutenberg;

  my $gutenberg = EBook::Gutenberg->init;
  $gutenberg->run;

=head1 DESCRIPTION

B<EBook::Gutenberg> is a module that provides the core functionality for the
L<gutenberg> utility. This is developer documentation, for L<gutenberg> user
documentation you should consult its manual.

=head1 METHODS

=over 4

=item $gut = EBook::Gutenberg->init()

Reads C<@ARGV> and returns a blessed C<EBook::Gutenberg> object.

=item $gut->run()

Runs L<gutenberg> based on the parameters processed in C<init()>.

=item $gut->update

Update local Project Gutenberg catalog; the C<update> command.

=item $gut->search

Search for ebooks; the C<search> command.

=item $gut->get

Download an ebook; the C<get> command.

=item $gut->meta

Print ebook metadata; the C<meta> command.

=item $gut->menu

Launch the L<dialog(1)>-based menu interface.

=item $gut->help([$exit])

Print L<gutenberg> manual. Exit with code C<$exit> if provided.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/gutenberg>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<gutenberg>

=cut

# vim: expandtab shiftwidth=4
