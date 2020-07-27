package Gtk3::WebKit2;
{
  $Gtk3::WebKit2::VERSION = '0.012';
}

=head1 NAME

Gtk3::WebKit2 - WebKit2 bindings for Perl

=head1 SYNOPSIS

	use Gtk3 -init;
	use Gtk3::WebKit2;

	my ($url) = shift @ARGV || 'http://search.cpan.org/';

	my $window = Gtk3::Window->new('toplevel');
	$window->set_default_size(800, 600);
	$window->signal_connect(destroy => sub { Gtk3->main_quit() });

	# Create a WebKit2 widget
	my $view = Gtk3::WebKit2::WebView->new();

	# Load a page
	$view->load_uri($url);

	# Pack the widgets together
	my $scrolls = Gtk3::ScrolledWindow->new();
	$scrolls->add($view);
	$window->add($scrolls);
	$window->show_all();

	Gtk3->main();

=head1 DESCRIPTION

This module provides the Perl bindings for the Gtk3 port of WebKit2.

=cut

use warnings;
use strict;
use base 'Exporter';

use Glib::Object::Introspection;


use constant {
    # XPath result types
    ANY_TYPE                       => 0,
    NUMBER_TYPE                    => 1,
    STRING_TYPE                    => 2,
    BOOLEAN_TYPE                   => 3,
    UNORDERED_NODE_ITERATOR_TYPE   => 4,
    ORDERED_NODE_ITERATOR_TYPE     => 5,
    UNORDERED_NODE_SNAPSHOT_TYPE   => 6,
    ORDERED_NODE_SNAPSHOT_TYPE     => 7,
    ANY_UNORDERED_NODE_TYPE        => 8,
    FIRST_ORDERED_NODE_TYPE        => 9,

    # Node type
    ELEMENT_NODE                   => 1,
    ATTRIBUTE_NODE                 => 2,
    TEXT_NODE                      => 3,
    CDATA_SECTION_NODE             => 4,
    ENTITY_REFERENCE_NODE          => 5,
    ENTITY_NODE                    => 6,
    PROCESSING_INSTRUCTION_NODE    => 7,
    COMMENT_NODE                   => 8,
    DOCUMENT_NODE                  => 9,
    DOCUMENT_TYPE_NODE             => 10,
    DOCUMENT_FRAGMENT_NODE         => 11,
    NOTATION_NODE                  => 12,

    # Document position
    DOCUMENT_POSITION_DISCONNECTED => 0x01,
    DOCUMENT_POSITION_PRECEDING    => 0x02,
    DOCUMENT_POSITION_FOLLOWING    => 0x04,
    DOCUMENT_POSITION_CONTAINS     => 0x08,
    DOCUMENT_POSITION_CONTAINED_BY => 0x10,
    DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC => 0x20,

    # Event - DOM PhaseType
    CAPTURING_PHASE     =>1,
    AT_TARGET           =>2,
    BUBBLING_PHASE      =>3,

    # Event - Reverse-engineered from Netscape
    MOUSEDOWN           =>1,
    MOUSEUP             =>2,
    MOUSEOVER           =>4,
    MOUSEOUT            =>8,
    MOUSEMOVE           =>16,
    MOUSEDRAG           =>32,
    CLICK               =>64,
    DBLCLICK            =>128,
    KEYDOWN             =>256,
    KEYUP               =>512,
    KEYPRESS            =>1024,
    DRAGDROP            =>2048,
    FOCUS               =>4096,
    BLUR                =>8192,
    SELECT              =>16384,
    CHANGE              =>32768,

    # Full screen api
    ALLOW_KEYBOARD_INPUT => 1,


    # ExceptionCode
    INDEX_SIZE_ERR                 =>1,
    DOMSTRING_SIZE_ERR             =>2,
    HIERARCHY_REQUEST_ERR          =>3,
    WRONG_DOCUMENT_ERR             =>4,
    INVALID_CHARACTER_ERR          =>5,
    NO_DATA_ALLOWED_ERR            =>6,
    NO_MODIFICATION_ALLOWED_ERR    =>7,
    NOT_FOUND_ERR                  =>8,
    NOT_SUPPORTED_ERR              =>9,
    INUSE_ATTRIBUTE_ERR            =>10,
    # Introduced in DOM Level 2:
    INVALID_STATE_ERR              =>11,
    # Introduced in DOM Level 2:
    SYNTAX_ERR                     =>12,
    # Introduced in DOM Level 2:
    INVALID_MODIFICATION_ERR       =>13,
    # Introduced in DOM Level 2:
    NAMESPACE_ERR                  =>14,
    # Introduced in DOM Level 2:
    INVALID_ACCESS_ERR             =>15,
    # Introduced in DOM Level 3:
    VALIDATION_ERR                 =>16,
    # Introduced in DOM Level 3:
    TYPE_MISMATCH_ERR              =>17,
    # Introduced as an XHR extension:
    SECURITY_ERR                   =>18,
    # Introduced in HTML5:
    NETWORK_ERR                    =>19,
    ABORT_ERR                      =>20,
    URL_MISMATCH_ERR               =>21,
    QUOTA_EXCEEDED_ERR             =>22,
    # TIMEOUT_ERR is currently unused but was added for completeness.
    TIMEOUT_ERR                    =>23,
    # INVALID_NODE_TYPE_ERR is currently unused but was added for completeness.
    INVALID_NODE_TYPE_ERR          =>24,
    DATA_CLONE_ERR                 =>25,

    # EventExceptionCode
    UNSPECIFIED_EVENT_TYPE_ERR => 0,
    DISPATCH_REQUEST_ERR       => 1,

    # KeyLocationCode
    KEY_LOCATION_STANDARD      => 0x00,
    KEY_LOCATION_LEFT          => 0x01,
    KEY_LOCATION_RIGHT         => 0x02,
    KEY_LOCATION_NUMPAD        => 0x03,


    # Range compare how
    START_TO_START => 0,
    START_TO_END   => 1,
    END_TO_END     => 2,
    END_TO_START   => 3,

    # Range compare results
    NODE_BEFORE           => 0,
    NODE_AFTER            => 1,
    NODE_BEFORE_AND_AFTER => 2,
    NODE_INSIDE           => 3,

    # Range exceptions
    BAD_BOUNDARYPOINTS_ERR => 1,
    INVALID_NODE_TYPE_ERR  => 2,

    # Overflow event
    HORIZONTAL => 0,
    VERTICAL   => 1,
    BOTH       => 2,

    # NodeFilter acceptNode return values
    FILTER_ACCEPT                  => 1,
    FILTER_REJECT                  => 2,
    FILTER_SKIP                    => 3,

    # NodeFilter whatToShow
    SHOW_ALL                       => 0xFFFFFFFF,
    SHOW_ELEMENT                   => 0x00000001,
    SHOW_ATTRIBUTE                 => 0x00000002,
    SHOW_TEXT                      => 0x00000004,
    SHOW_CDATA_SECTION             => 0x00000008,
    SHOW_ENTITY_REFERENCE          => 0x00000010,
    SHOW_ENTITY                    => 0x00000020,
    SHOW_PROCESSING_INSTRUCTION    => 0x00000040,
    SHOW_COMMENT                   => 0x00000080,
    SHOW_DOCUMENT                  => 0x00000100,
    SHOW_DOCUMENT_TYPE             => 0x00000200,
    SHOW_DOCUMENT_FRAGMENT         => 0x00000400,
    SHOW_NOTATION                  => 0x00000800,


    # Attr change types
    MODIFICATION =>1,
    ADDITION     =>2,
    REMOVAL      =>3,


    # Media stream
    LIVE  => 1,
    ENDED => 2,
};

# export nothing by default.
# export functions and constants by request.
our %EXPORT_TAGS = (
    xpath_results => [qw{
        ANY_TYPE
        NUMBER_TYPE
        STRING_TYPE
        BOOLEAN_TYPE
        UNORDERED_NODE_ITERATOR_TYPE
        ORDERED_NODE_ITERATOR_TYPE
        UNORDERED_NODE_SNAPSHOT_TYPE
        ORDERED_NODE_SNAPSHOT_TYPE
        ANY_UNORDERED_NODE_TYPE
        FIRST_ORDERED_NODE_TYPE
    }],

    node_types => [qw{
        ELEMENT_NODE
        ATTRIBUTE_NODE
        TEXT_NODE
        CDATA_SECTION_NODE
        ENTITY_REFERENCE_NODE
        ENTITY_NODE
        PROCESSING_INSTRUCTION_NODE
        COMMENT_NODE
        DOCUMENT_NODE
        DOCUMENT_TYPE_NODE
        DOCUMENT_FRAGMENT_NODE
        NOTATION_NODE
    }],

    document_positions => [qw{
        DOCUMENT_POSITION_DISCONNECTED
        DOCUMENT_POSITION_PRECEDING
        DOCUMENT_POSITION_FOLLOWING
        DOCUMENT_POSITION_CONTAINS
        DOCUMENT_POSITION_CONTAINED_BY
        DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC
    }],

    event_phase_types => [qw{
        CAPTURING_PHASE
        AT_TARGET
        BUBBLING_PHASE
    }],

    event_types => [qw{
        MOUSEDOWN
        MOUSEUP
        MOUSEOVER
        MOUSEOUT
        MOUSEMOVE
        MOUSEDRAG
        CLICK
        DBLCLICK
        KEYDOWN
        KEYUP
        KEYPRESS
        DRAGDROP
        FOCUS
        BLUR
        SELECT
        CHANGE
    }],

    full_screen_api => [qw{
        ALLOW_KEYBOARD_INPUT
    }],

    dom_core_exceptions => [qw{
        INDEX_SIZE_ERR
        DOMSTRING_SIZE_ERR
        HIERARCHY_REQUEST_ERR
        WRONG_DOCUMENT_ERR
        INVALID_CHARACTER_ERR
        NO_DATA_ALLOWED_ERR
        NO_MODIFICATION_ALLOWED_ERR
        NOT_FOUND_ERR
        NOT_SUPPORTED_ERR
        INUSE_ATTRIBUTE_ERR
        INVALID_STATE_ERR
        SYNTAX_ERR
        INVALID_MODIFICATION_ERR
        NAMESPACE_ERR
        INVALID_ACCESS_ERR
        VALIDATION_ERR
        TYPE_MISMATCH_ERR
        SECURITY_ERR
        NETWORK_ERR
        ABORT_ERR
        URL_MISMATCH_ERR
        QUOTA_EXCEEDED_ERR
        TIMEOUT_ERR
        INVALID_NODE_TYPE_ERR
        DATA_CLONE_ERR
    }],

    event_exception_codes => [qw{
        UNSPECIFIED_EVENT_TYPE_ERR
        DISPATCH_REQUEST_ERR
    }],

    key_location_codes => [qw{
        KEY_LOCATION_STANDARD
        KEY_LOCATION_LEFT
        KEY_LOCATION_RIGHT
        KEY_LOCATION_NUMPAD
    }],

    range_compare_how => [qw{
        START_TO_START
        START_TO_END
        END_TO_END
        END_TO_START
    }],

    range_compare_results => [qw{
        NODE_BEFORE
        NODE_AFTER
        NODE_BEFORE_AND_AFTER
        NODE_INSIDE
    }],

    range_exceptions => [qw{
        BAD_BOUNDARYPOINTS_ERR
        INVALID_NODE_TYPE_ERR
    }],


    # Overflow event
    overflow_event => [qw{
        HORIZONTAL
        VERTICAL
        BOTH
    }],

    node_filter => [qw{
        FILTER_ACCEPT
        FILTER_REJECT
        FILTER_SKIP

        SHOW_ALL
        SHOW_ELEMENT
        SHOW_ATTRIBUTE
        SHOW_TEXT
        SHOW_CDATA_SECTION
        SHOW_ENTITY_REFERENCE
        SHOW_ENTITY
        SHOW_PROCESSING_INSTRUCTION
        SHOW_COMMENT
        SHOW_DOCUMENT
        SHOW_DOCUMENT_TYPE
        SHOW_DOCUMENT_FRAGMENT
        SHOW_NOTATION
    }],

    attr_change_types => [qw{
        MODIFICATION
        ADDITION
        REMOVAL
    }],

    media_stream => [qw{
        LIVE
        ENDED
    }],
);
our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;


sub import {
    my %setup = (
        basename  => 'WebKit2',
        version   => '4.0',
        package   => __PACKAGE__,
    );

    my @args;
    for (my $i = 0; $i < @_; ++$i) {
        my $arg = $_[$i];
        if (exists $setup{$arg}) {
            $setup{$arg} = $_[++$i];
        }
        else {
            push @args, $arg;
        }
    }

    Glib::Object::Introspection->setup(%setup);

    # Pretend that we're calling Exporter's import
    @_ = @args;
    goto &Exporter::import;
}

# # TODO call me from the extension
# sub on_page_created {
#     my ($self, $callback) = @_;
#     return $callback->();
# }

use FindBin qw($Bin);

sub add_extension_to {
    my ($class, $context) = @_;

    $context->set_web_extensions_directory("$Bin/../../extensions");

    return;
}


1;

=head1 INSTALLATION

=head2 "Headless" Debian based systems (inc Ubuntu)

If you are running an X Server (desktop environment) then you should be fine.
If you are trying to install this on a "headless" server, then you will need a
framebuffer display to take the place of the X server.

The xvfb-run command can do this for you.

=head2 Other

You will need to have GTK3 and Webkit2 installed to use this.
A key package you will need is webkit2-gtk-devel.


=head1 BUGS

For any kind of help or support simply send a mail to the gtk-perl mailing
list (gtk-perl-list@gnome.org).

=head1 AUTHORS

Jason Shaun Carty <jc@atikon.com>,
Philipp Voglhofer <pv@atikon.com>,
Philipp A. Lehner <pl@atikon.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Jason Shaun Carty, Philipp Voglhofer and Philipp A. Lehner

This library is free software; you can redistribute it and/or modify
it under the same terms of:

=over 4

=item the GNU Lesser General Public License, version 2.1; or

=item the Artistic License, version 2.0.

=back

This module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the GNU Library General Public
License along with this module; if not, see L<http://www.gnu.org/licenses/>.

For the terms of The Artistic License, see L<perlartistic>.

=cut
