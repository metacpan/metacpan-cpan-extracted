# vi: set autoindent shiftwidth=4 tabstop=8 softtabstop=4 expandtab:
package Devel::PDB::Dialog::FileBrowser;
use strict;
use warnings;

use Curses;
use Curses::UI::Window;
use Curses::UI::Common;

use vars qw(
  $VERSION
  @ISA
  );

@ISA = qw(
  Curses::UI::Window
  Curses::UI::Common
  );

$VERSION = '1.1';

my $file_label   = 'File:';
my $filter_label = 'Filter:';
my $dialog_title = 'File(s)';

sub new {
    my $class    = shift;
    my %userargs = @_;

    keys_to_lowercase(\%userargs);

    my %args = (
        -title => $dialog_title,
        -bg    => -1,
        -fg    => -1,

        %userargs,

        -border       => 1,
        -centered     => 1,
        -titleinverse => 0,
    );

    my $this = $class->SUPER::new(%args);
    $this->root->error('No files array is given') if !defined $this->{-files};
    $this->layout();

    my $filebrowser = $this->add(
        'filebrowser', 'Listbox',
        -y           => 0,
        -border      => 1,
        -width       => $this->canvaswidth,
        -padtop      => 1,
        -padbottom   => 4,
        -values      => [],
        -vscrollbar  => 1,
        -bg          => $this->{-bg},
        -fg          => $this->{-fg},
        -bbg         => $this->{-bg},
        -bfg         => $this->{-fg},
        -onselchange => \&on_file_active,
    );

    $filebrowser->set_routine('option-select', \&on_file_sel);

    $this->add(
        'filterlabel', 'Label',
        -x    => 1,
        -y    => $this->canvasheight - 4,
        -text => $filter_label,
        -bg   => $this->{-bg},
        -fg   => $this->{-fg},
    );

    my $filter = $this->add(
        'filter', 'TextEntry',
        -x         => 10,
        -y         => $this->canvasheight - 4,
        -text      => '',
        -width     => $this->canvaswidth - 11,
        -showlines => 1,
        -bg        => $this->{-bg},
        -fg        => $this->{-fg},
    );

    $this->add(
        'filelabel', 'Label',
        -x    => 1,
        -y    => $this->canvasheight - 3,
        -text => $file_label,
        -bg   => $this->{-bg},
        -fg   => $this->{-fg},
    );

    $this->add(
        'file', 'Label',
        -x      => 10,
        -y      => $this->canvasheight - 3,
        -width  => $this->canvaswidth - 11,
        -height => 2,
        -text   => '',
        -bg     => $this->{-bg},
        -fg     => $this->{-fg},
    );

    $this->set_binding(
        sub {
            ($this->getfocusobj == $filter ? $filebrowser : $filter)->focus;
        },
        CUI_TAB
    );

    $filter->onChange(
        sub {
            $this->refresh_list;
        });

    $this->set_binding(
        sub {
            shift->loose_focus;
        },
        CUI_ESCAPE,
        KEY_F(10));

    my @a_help = ("ESC,F10 - Exit", "Return - Choose", "Tab - switch to filter");
    if ($this->{-its_breakpoints}) {
        push(@a_help, "Del,F2 - Delete breakpoint");
        $this->set_binding(
            sub {
                my $this    = shift;
                my $browser = $this->getobj('filebrowser');
                my $id      = $browser->get_active_value();
                my $i       = 0;
                foreach my $f (@{$this->{-files}}) {
                    if ($id eq $f) {
                        splice(@{$this->{-files}}, $i, 1);
                        last;
                    }
                    $i++;
                }
                $this->refresh_list;
            },
            KEY_DC,
            KEY_F(2));
    }

    $this->add(
        'helplabel', 'Label',
        -y       => -1,
        -reverse => 1,
        -text    => join("  |  ", @a_help));

    $this->layout();
    $this->refresh_list;

    return bless $this, $class;
}

sub layout {
    my $this = shift;

    $this->{-width}  = $this->root->{-width} - 10;
    $this->{-height} = $this->root->{-height} - 10;

    $this->SUPER::layout() or return;

    return $this;
}

sub refresh_list {
    my $this = shift;

    my $file    = $this->getobj('file');
    my $browser = $this->getobj('filebrowser');
    my $filter  = $this->getobj('filter');

    my @visible_files = sort @{$this->{-files}};
    my $regexp        = $filter->text;
    eval { @visible_files = grep /$regexp/i, @visible_files if $regexp; };

    $browser->values(\@visible_files);
    $browser->{-ypos}     = 0;
    $browser->{-selected} = undef;
    $browser->layout_content->draw(1);

    return $this;
}

sub on_file_active {
    my $browser = shift;
    my $this    = $browser->parent;
    my $file    = $this->getobj('file');
    my $active  = $browser->get_active_value;
    my $width   = $file->{-width};

    my $show = '';
    if (defined $active) {
        my $ptr = 0;
        my $len = length($active);
        for ($ptr = 0; $ptr < $len; $ptr += $width) {
            $show .= substr($active, $ptr, $width) . "\n";
        }
        $show .= substr $active, $ptr if $ptr < $len;
    }

    $file->text($show);
}

sub on_file_sel {
    my $browser = shift;
    my $this    = $browser->parent;

    $this->{-file} = $browser->get_active_value;
    $this->loose_focus;
}

sub draw(;$) {
    my $this = shift;
    my $no_doupdate = shift || 0;

    # Draw Window
    $this->SUPER::draw(1) or return $this;

    $this->{-canvasscr}->noutrefresh();
    doupdate() unless $no_doupdate;

    return $this;
}

sub get() {
    return shift->{-file};
}

1;
