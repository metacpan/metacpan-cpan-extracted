package Mail::LMLM;

use strict;
use warnings;

use 5.008;

use Mail::LMLM::Object;

use vars qw($VERSION);

$VERSION = '0.6804';

use vars qw(@ISA);

@ISA=qw(Mail::LMLM::Object);

use Mail::LMLM::Render::HTML;

use Mail::LMLM::Types::Ezmlm;
use Mail::LMLM::Types::Egroups;
use Mail::LMLM::Types::Listar;
use Mail::LMLM::Types::Majordomo;
use Mail::LMLM::Types::Listserv;
use Mail::LMLM::Types::Mailman;
use Mail::LMLM::Types::GoogleGroups;

use vars qw(%mailing_list_classes);

my $prefix = "Mail::LMLM::Types::";

sub _pref
{
    my $name = shift;

    return $prefix . $name;
}

%mailing_list_classes =
(
    (
        map { $_ => _pref(ucfirst($_)) }
        ('egroups', 'ezmlm', 'listar', 'majordomo', 'listserv', 'mailman')
    ),
    "google" => _pref("GoogleGroups"),
);

use vars qw(@render_what);

@render_what =
(
    {
        'title' => "Description",
        'func' => "render_description",
        'id' => "desc",
    },
    {
        'title' => "Posting Guidelines",
        'func' => "render_guidelines",
        'id' => "post_guidelines",
    },
    {
        'title' => "Subscribing to the Mailing-List",
        'func' => "render_subscribe",
        'id' => "subscribe",
    },
    {
        'title' => "Unsubscribing from the Mailing-List",
        'func' => "render_unsubscribe",
        'id' => "unsubscribe",
    },
    {
        'title' => "Posting Messages to the Mailing-List",
        'func' => "render_post",
        'id' => "posting",
    },
    {
        'title' => "Contacting the Mailing-List's Owner",
        'func' => "render_owner",
        'id' => "owner",
    },
    {
        'title' => "The Mailing-List's Homepage",
        'func' => "render_homepage",
        'id' => "homepage",
    },
    {
        'title' => "Online Messages Archive",
        'func' => "render_online_archive",
        'id' => "archive",
    },
);

sub _do_nothing
{
}

sub initialize
{
    my $self = shift;

    my ($key, $value);
    $self->{'title'} = "List of Mailing Lists";
    $self->{'headline'} = "List of Mailing Lists";
    $self->{'prolog'} = $self->{'epilog'} = \&_do_nothing;
    $self->{'extra_classes'} = {};
    while(scalar(@_))
    {
        $key = shift;
        $value = shift;
        if ($key =~ /^-?lists$/)
        {
            $self->{'lists'} = $value;
        }
        elsif ($key =~ /^-?title$/)
        {
            $self->{'title'} = $value;
        }
        elsif ($key =~ /^-?headline$/)
        {
            $self->{'headline'} = $value;
        }
        elsif ($key =~ /^-?extra-classes$/)
        {
            $self->{'extra_classes'} = $value;
        }
        elsif ($key =~ /^-?prolog$/)
        {
            $self->{'prolog'} = $value;
        }
        elsif ($key =~ /^-?epilog$/)
        {
            $self->{'epilog'} = $value;
        }
    }

    if (!exists($self->{'lists'}))
    {
        die "The lists were not defined for Mail::LMLM!";
    }
    return 0;
}

sub render
{
    my $self = shift;

    my ($mail_lister, $mailing_list, $o, $r, $main_o, $main_r, $filename);

    local(*INDEX);

    open INDEX, ">index.html";
    $main_r = Mail::LMLM::Render::HTML->new(\*INDEX);

    $main_r->start_document(
        $self->{'title'},
        $self->{'headline'},
        );

    $self->{'prolog'}->($self, $main_r);

    local(*O);

    foreach $mailing_list (@{$self->{'lists'}})
    {
        $filename = $mailing_list->{'id'}.".html";
        open O, ">".$filename;
        $r = Mail::LMLM::Render::HTML->new(\*O);

        my $class_name = $mailing_list->{'class'};
        my $class = $mailing_list_classes{$class_name} || $self->{'extra_classes'}->{$class_name} || die "Mail::LMLM: Unknown Class \"$class_name\"";
        if (ref($class) eq "CODE")
        {
            $mail_lister = $class->(%$mailing_list);
        }
        else
        {
            $mail_lister = $class->new(%$mailing_list);
        }

        my $title = exists($mailing_list->{'title'}) ?
            $mailing_list->{'title'} :
            $mailing_list->{'id'};

        $r->start_document($title, $title);

        foreach my $what (@render_what)
        {
            my $func = $what->{'func'};
            $r->start_section($what->{'title'}, +{'id' => $what->{'id'}});
            $mail_lister->$func($r);
            $r->end_section();
        }

        $main_r->start_section($title, {'title_url' => $filename});
        $mail_lister->render_description($main_r);
        $main_r->end_section();

        $r->end_document();

        close(O);
    }

    $self->{'epilog'}->($self, $main_r);

    $main_r->end_document();
    close(INDEX);

    local(*STYLE);
    open STYLE, ">style.css";
    print STYLE <<"EOF";
a:hover { background-color : LightGreen }
div.indent { margin-left : 3em }
EOF

    close(STYLE);
}

#### Documentation

=head1 NAME

Mail::LMLM - List of Mailing Lists Manager

=head1 SYNOPSIS

    use Mail::LMLM;

    my $renderer =
        Mail::LMLM->new(
            'extra-classes' => \%extra_mailing_list_classes,
            title => "List of the Foo Mailing Lists",
            headline => "Foo Mailing Lists",
            lists => \@lists,
            prolog =>  \&prolog,
            epilog => \&epilog,
        );

    $renderer->render();

=head1 DESCRIPTION

The Mail::LMLM module allows users to easily manage HTML directories of
mailing lists of various mailing list managers and hosts.

To use it create a new module of type Mail::LMLM with a new method, while
initializing it with the list of mailing lists (in order of listing), and
other parameters. Then, invoke the render() function to create the HTML
files within the current directory.

Following is a listing of the parameters

=head2 title and headline

title is what will be displayed in the document inside the E<lt>titleE<gt>
tag. headline is the headline of the main page.

=head2 prolog and epilog

prolog is a callback for a function that will be called with the Mail::LMLM
handle and its appropriate rendering back-end when the main's page prologue
(that comes before the listing itself) is to be displayed. epilog is the
same for the text after the listing itself. Here is an example for it:

    sub prolog
    {
        my $self = shift;
        my $main_r = shift;

        $main_r->para( "This is a list of the mailing-lists which are affiliated " .
            "with the Israeli Group of Linux Users (IGLU). It includes such " .
            "information as how to subscribe/unsubscribe, posting address, " .
            "posting guidelines, the address of the mailing-list owner, the " .
            "mailing-list's homepage and the online messages archive."
        );

        $main_r->start_para();
        $main_r->text("If you have any comments, suggestions or additions " .
            "regarding the information contained here, don't hesitate to " .
            "contact the maintainer of these pages at the following e-mail: ");

        $main_r->email_address("shlomif", "shlomifish.org");
        $main_r->end_para();
    }

For more information on how to interface with the renderer consult
the L<HTML::LMLM::Render> reference page.

=head2 extra-classes

This is a reference to a hash whose keys are extra IDs for mailing lists
classes, and its values are either the namespace of the Perl module that
implements this class, or a subroutine that creates a new class like that.

This class would be better be sub-classed from one of the classes that
ship with Mail::LMLM. To see examples of how to sub-class, consult the examples
section of the Mail::LMLM distribution.

=head2 lists

This is a reference to an array of hash references that contain the
information for the mailing lists. The fields available here are:

=over 8

=item id

The identifier of the mailing list that will be used as the base name
for its HTML page.

=item class

The class of the mailing list that determines its type. Available built-in
classes are: B<egroups> (A Yahoo-Groups mailing list), B<ezmlm> (an Ezmlm-based
mailing list), B<listar> (a Listar-based mailing list), B<listserv> (
a Listserv-based mailing list), B<mailman> (a mailman based mailing list),
B<majordomo> (a majordomo-based mailing list).

=item group_base

The group base that appears before the host.

=item title

The title that will be displayed at the head of the page.

=item hostname

The hostname of the mailing list address.

=item homepage

The homepage URL of the mailing list.

=item description

The description of the mailing list, to be presented in its page.

This can be an handle/Mail::LMLM::Render callback.

=item guidelines

The posting guidelines for the mailing list.

=item online_archive

A URL or a Mail::LMLM::Render callback for displaying the online archive of
the mailing list.

=back

=head1 FUNCTIONS

=head2 initialize()

Called on behalf of the constructor to initialize the module. For internal
use only.

=head2 my $lmlm = Mail::LMLM->new(%params)

Initializes a new module with %params.

=head2 $lmlm->render()

Renders the pages.

=head1 SEE ALSO

L<Mail::LMLM::Render,1>

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 LICENSE

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

(This is the MIT X11 License).

=cut

