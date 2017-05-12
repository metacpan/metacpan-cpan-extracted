use strict;
use warnings;

package HTML::Widgets::NavMenu;

our $VERSION = '1.0703';

package HTML::Widgets::NavMenu::Error;

use base "HTML::Widgets::NavMenu::Object";

package HTML::Widgets::NavMenu::Error::Redirect;

use strict;
use vars qw(@ISA);
@ISA=("HTML::Widgets::NavMenu::Error");

sub CGIpm_perform_redirect
{
    my $self = shift;

    my $cgi = shift;

    print $cgi->redirect($cgi->script_name() . $self->{-redirect_path});
    exit;
}

package HTML::Widgets::NavMenu::NodeDescription;

use strict;

use base qw(HTML::Widgets::NavMenu::Object);

__PACKAGE__->mk_acc_ref([
    qw(host host_url title label direct_url url_type)]
    );

sub _init
{
    my ($self, $args) = @_;

    while (my ($k, $v) = each(%$args))
    {
        $self->$k($v);
    }

    return 0;
}

1;

package HTML::Widgets::NavMenu::LeadingPath::Component;

use vars qw(@ISA);

@ISA = (qw(HTML::Widgets::NavMenu::NodeDescription));

package HTML::Widgets::NavMenu::Iterator::GetCurrentlyActive;

use base 'HTML::Widgets::NavMenu::Iterator::Base';

__PACKAGE__->mk_acc_ref([qw(
    _item_found
    _leading_path_coords
    _ret_coords
    _temp_coords
    _tree
    )]);

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->SUPER::_init($args);

    $self->_tree($args->{'tree'});

    $self->_item_found(0);

    return 0;
}

sub get_initial_node
{
    my $self = shift;

    return $self->_tree;
}

sub item_matches
{
    my $self = shift;
    my $item = $self->top();
    my $url = $item->_node()->url();
    my $nav_menu = $self->nav_menu();
    return
        (
            ($item->_accum_state()->{'host'} eq $nav_menu->current_host()) &&
            (defined($url) && ($url eq $nav_menu->path_info()))
        );
}

sub does_item_expand
{
    my $self = shift;
    my $item = $self->top();
    return $item->_node()->capture_expanded();
}

sub node_start
{
    my $self = shift;

    if ($self->item_matches())
    {
        my @coords = @{$self->get_coords()};
        $self->_ret_coords([ @coords ]);
        $self->_temp_coords([ @coords, (-1) ]);
        $self->top()->_node()->mark_as_current();
        $self->_item_found(1);
    }
    elsif ($self->does_item_expand())
    {
        my @coords = @{$self->get_coords()};
        $self->_leading_path_coords([ @coords]);
    }
}

sub node_end
{
    my $self = shift;
    if ($self->_item_found())
    {
        # Skip the first node, because the coords refer
        # to the nodes below it.
        my $idx = pop(@{$self->_temp_coords()});
        if ($idx >= 0)
        {
            my $node = $self->top()->_node();
            $node->update_based_on_sub(
                $node->get_nth_sub(
                    $idx
                )
            );
        }
    }
}

sub node_should_recurse
{
    my $self = shift;
    return (! $self->_item_found());
}

sub get_final_coords
{
    my $self = shift;

    return $self->_ret_coords();
}

sub _get_leading_path_coords
{
    my $self = shift;

    return ($self->_ret_coords() || $self->_leading_path_coords());
}

package HTML::Widgets::NavMenu;

use base 'HTML::Widgets::NavMenu::Object';

use HTML::Widgets::NavMenu::Url;

require HTML::Widgets::NavMenu::Iterator::NavMenu;
require HTML::Widgets::NavMenu::Iterator::SiteMap;
require HTML::Widgets::NavMenu::Tree::Node;
require HTML::Widgets::NavMenu::Predicate;

__PACKAGE__->mk_acc_ref([qw(
    _current_coords
    current_host
    _hosts
    _no_leading_dot
    _leading_path_coords
    path_info
    _traversed_tree
    _tree_contents
    _ul_classes
    )]);

sub _init
{
    my $self = shift;

    my %args = (@_);

    $self->_register_path_info(\%args);

    $self->_hosts($args{hosts});
    $self->_tree_contents($args{tree_contents});

    $self->current_host($args{current_host})
        or die "Current host was not specified.";

    $self->_ul_classes($args{'ul_classes'} || []);

    $self->_no_leading_dot(
        exists($args{'no_leading_dot'}) ? $args{'no_leading_dot'} : 0
    );

    return 0;
}

sub _get_nav_menu_traverser_args
{
    my $self = shift;

    return
    {
        'nav_menu' => $self,
        'ul_classes' => $self->_ul_classes(),
    };
}

sub _get_nav_menu_traverser
{
    my $self = shift;

    return
        HTML::Widgets::NavMenu::Iterator::NavMenu->new(
            $self->_get_nav_menu_traverser_args()
        );
}

sub _get_current_coords
{
    my $self = shift;

    # This is to make sure $self->_current_coords() is generated.
    $self->_get_traversed_tree();

    return [ @{$self->_current_coords()} ];
}

sub _register_path_info
{
    my $self = shift;
    my $args = shift;

    my $path_info = $args->{path_info};

    my $redir_path = undef;

    if ($path_info eq "")
    {
        $redir_path = "";
    }
    elsif ($path_info =~ m/\/\/$/)
    {
        my $path = $path_info;
        $path =~ s{\/+$}{};
        $redir_path = $path;
    }

    if (defined($redir_path))
    {
        my $error = HTML::Widgets::NavMenu::Error::Redirect->new();

        $error->{'-redirect_path'} = ($redir_path."/");
        $error->{'msg'} = "Need to redirect";

        die $error;
    }

    $path_info =~ s!^\/!!;

    $self->path_info($path_info);

    return 0;
}

sub _is_slash_terminated
{
    my $string = shift;
    return (($string =~ /\/$/) ? 1 : 0);
}

sub _text_to_url_obj
{
    my $text = shift;
    my $url =
        HTML::Widgets::NavMenu::Url->new(
            $text,
            (_is_slash_terminated($text) || ($text eq "")),
            "server",
        );
    return $url;
}

sub _get_relative_url
{
    my $from_text = shift;
    my $to_text = shift(@_);
    my $no_leading_dot = shift;

    my $from_url = _text_to_url_obj($from_text);
    my $to_url = _text_to_url_obj($to_text);
    my $ret =
        $from_url->_get_relative_url(
            $to_url,
            _is_slash_terminated($from_text),
            $no_leading_dot,
        );
   return $ret;
}

sub _get_full_abs_url
{
    my ($self, $args) = @_;

    my $host = $args->{host};
    my $host_url = $args->{host_url};

    return ($self->_hosts->{$host}->{base_url} . $host_url);
}

sub get_cross_host_rel_url_ref
{
    my ($self, $args) = @_;

    my $host = $args->{host};
    my $host_url = $args->{host_url};
    my $url_type = $args->{url_type};
    my $url_is_abs = $args->{url_is_abs};

    if ($url_is_abs)
    {
        return $host_url;
    }
    elsif (($host ne $self->current_host()) || ($url_type eq "full_abs"))
    {
        return $self->_get_full_abs_url($args);
    }
    elsif ($url_type eq "rel")
    {
        # TODO : convert to a method.
        return _get_relative_url(
            $self->path_info(), $host_url, $self->_no_leading_dot()
        );
    }
    elsif ($url_type eq "site_abs")
    {
        return ($self->_hosts->{$host}->{trailing_url_base} . $host_url);
    }
    else
    {
        die "Unknown url_type \"$url_type\"!\n";
    }
}

sub get_cross_host_rel_url
{
    my $self = shift;

    return $self->get_cross_host_rel_url_ref({@_});
}

sub _get_url_to_item
{
    my $self = shift;
    my $item = shift;

    return $self->get_cross_host_rel_url_ref(
        {
            'host' => $item->_accum_state()->{'host'},
            'host_url' => ($item->_node->url() || ""),
            'url_type' => $item->get_url_type(),
            'url_is_abs' => $item->_node->url_is_abs(),
        }
    );
}

sub _gen_blank_nav_menu_tree_node
{
    my $self = shift;

    return HTML::Widgets::NavMenu::Tree::Node->new();
}

sub _create_predicate
{
    my ($self, $args) = @_;

    return
        HTML::Widgets::NavMenu::Predicate->new(
            'spec' => $args->{'spec'},
        );
}

sub _create_new_nav_menu_item
{
    my ($self, $args) = @_;

    my $sub_contents = $args->{sub_contents};

    my $new_item = $self->_gen_blank_nav_menu_tree_node();

    $new_item->set_values_from_hash_ref($sub_contents);

    if (exists($sub_contents->{'expand'}))
    {
        my $expand_val =
            $self->_create_predicate(
                {
                    'spec' => $sub_contents->{'expand'},
                }
            )->evaluate(
                'path_info' => $self->path_info(),
                'current_host' => $self->current_host(),
            )
            ;
        if ($expand_val)
        {
            $new_item->expand($expand_val);
        }
    }

    return $new_item;
}

sub _render_tree_contents
{
    my $self = shift;
    my $sub_contents = shift;

    my $path_info = $self->path_info();

    my $new_item =
        $self->_create_new_nav_menu_item(
            { sub_contents => $sub_contents },
        );

    if (exists($sub_contents->{subs}))
    {
        foreach my $sub_contents_sub (@{$sub_contents->{subs}})
        {
            $new_item->add_sub(
                $self->_render_tree_contents(
                    $sub_contents_sub,
                )
            );
        }
    }
    return $new_item;
}

sub gen_site_map
{
    my $self = shift;

    my $iterator =
        HTML::Widgets::NavMenu::Iterator::SiteMap->new(
            {
               'nav_menu' => $self,
            }
        );

    $iterator->traverse();

    return $iterator->get_results();
}

sub _get_next_coords
{
    my $self = shift;

    my @coords = @{shift || $self->_get_current_coords};

    my @branches = ($self->_get_traversed_tree());

    my @dest_coords;

    my $i;

    for($i=0;$i<scalar(@coords);$i++)
    {
        $branches[$i+1] = $branches[$i]->get_nth_sub($coords[$i]);
    }

    if ($branches[$i]->_num_subs())
    {
        @dest_coords = (@coords,0);
    }
    else
    {
        for($i--;$i>=0;$i--)
        {
            if ($branches[$i]->_num_subs() > ($coords[$i]+1))
            {
                @dest_coords = (@coords[0 .. ($i-1)], $coords[$i]+1);
                last;
            }
        }
        if ($i == -1)
        {
            return undef;
        }
    }

    return \@dest_coords;
}

sub _get_prev_coords
{
    my $self = shift;

    my @coords = @{shift || $self->_get_current_coords()};

    if (scalar(@coords) == 0)
    {
        return undef;
    }
    elsif ($coords[$#coords] > 0)
    {
        # Get the previous leaf
	    my @previous_leaf =
	        (
                @coords[0 .. ($#coords - 1) ] ,
                $coords[$#coords]-1
            );
        # Continue in this leaf to the end.
        my $new_coords = $self->_get_most_advanced_leaf(\@previous_leaf);

        return $new_coords;
    }
    else
    {
        return [ @coords[0 .. ($#coords-1)] ];
    }
}

sub _get_up_coords
{
    my $self = shift;

    my @coords = @{shift || $self->_get_current_coords};

    if (scalar(@coords) == 0)
    {
        return undef;
    }
    else
    {
        if ((@coords == 1) && ($coords[0] > 0))
        {
            return [0];
        }
        pop(@coords);
        return \@coords;
    }
}

sub _get_top_coords
{
    my $self = shift;

    my @coords = @{shift || $self->_get_current_coords()};

    if ((! @coords) || ((@coords == 1) && ($coords[0] == 0)))
    {
        return undef;
    }
    else
    {
        return [0];
    }
}

sub _is_skip
{
    my $self = shift;
    my $coords = shift;

    my $iterator = $self->_get_nav_menu_traverser();

    my $ret = $iterator->find_node_by_coords($coords);

    my $item = $ret->{item};

    return $item->_node()->skip();
}

sub _get_coords_while_skipping_skips
{
    my $self = shift;

    my $callback = shift;
    my $coords = shift(@_);
    if (!$coords)
    {
        $coords = $self->_get_current_coords();
    }

    my $do_once = 1;

    while ($do_once || $self->_is_skip($coords))
    {
        $coords = $callback->($self, $coords);
    }
    continue
    {
        $do_once = 0;
    }

    return $coords;
}

sub _get_most_advanced_leaf
{
    my $self = shift;

    # We accept as a parameter the vector of coordinates
    my $coords_ref = shift;

    my @coords = @{$coords_ref};

    # Get a reference to the contents HDS (= hierarchial data structure)
    my $branch = $self->_get_traversed_tree();

    # Get to the current branch by advancing to the offset
    foreach my $c (@coords)
    {
        # Advance to the next level which is at index $c
        $branch = $branch->get_nth_sub($c);
    }

    # As long as there is something deeper
    while (my $num_subs = $branch->_num_subs())
    {
        my $index = $num_subs-1;
        # We are going to return it, so store it
        push @coords, $index;
        # Recurse into the sub-branch
        $branch = $branch->get_nth_sub($index);
    }

    return \@coords;
}

=begin comment

sub get_rel_url_from_coords
{
    my $self = shift;
    my $coords = shift;

    my ($ptr,$host);
    my $iterator = $self->_get_nav_menu_traverser();
    my $node_ret = $iterator->find_node_by_coords($coords);
    my $item = $node_ret->{'item'};

    return $self->_get_url_to_item($item);
}

=end comment

=cut

# The traversed_tree is the tree that is calculated from the tree given
# by the user and some other parameters such as the host and path_info.
# It is passed to the NavMenu::Iterator::* classes as argument.
sub _get_traversed_tree
{
    my $self = shift;

    if (! $self->_traversed_tree())
    {
        my $gen_retval = $self->_gen_traversed_tree();
        $self->_traversed_tree($gen_retval->{'tree'});
        $self->_current_coords($gen_retval->{'current_coords'});
        $self->_leading_path_coords($gen_retval->{'leading_path_coords'});
    }
    return $self->_traversed_tree();
}

sub _gen_traversed_tree
{
    my $self = shift;

    my $tree =
        $self->_render_tree_contents(
            $self->_tree_contents(),
            );

    my $find_coords_iterator =
        HTML::Widgets::NavMenu::Iterator::GetCurrentlyActive->new(
            {
                'nav_menu' => $self,
                'tree' => $tree,
            }
        );

    $find_coords_iterator->traverse();

    my $current_coords = $find_coords_iterator->get_final_coords() || [];
    my $leading_path_coords =
        $find_coords_iterator->_get_leading_path_coords() || [];

    # The root should always be expanded because:
    # 1. If one of the leafs was marked as expanded so will its ancestors
    #    and eventually the root.
    # 2. If nothing was marked as expanded, it should still be marked as
    #    expanded so it will expand.
    $tree->expand();

    return
        {
            'tree' => $tree,
            'current_coords' => $current_coords,
            'leading_path_coords' => $leading_path_coords,
        };
}

sub _get_leading_path_of_coords
{
    my $self = shift;
    my $coords = shift;

    if (! @$coords )
    {
        $coords = [ 0 ];
    }

    my @leading_path;
    my $iterator = $self->_get_nav_menu_traverser();

    COORDS_LOOP:
    while (1)
    {
        my $ret = $iterator->find_node_by_coords(
            $coords
        );

        my $item = $ret->{item};

        my $node = $item->_node();
        # This is a workaround for the root link.
        my $host_url = (defined($node->url()) ? ($node->url()) : "");
        my $host = $item->_accum_state()->{'host'};

        my $url_type =
            ($node->url_is_abs() ?
                "full_abs" :
                $item->get_url_type()
            );

        push @leading_path,
            HTML::Widgets::NavMenu::LeadingPath::Component->new(
                {
                    'host' => $host,
                    'host_url' => $host_url,
                    'title' => $node->title(),
                    'label' => $node->text(),
                    'direct_url' => $self->_get_url_to_item($item),
                    'url_type' => $url_type,
                }
            );

        if ((scalar(@$coords) == 1) && ($coords->[0] == 0))
        {
            last COORDS_LOOP;
        }
    }
    continue
    {
        $coords = $self->_get_up_coords($coords);
    }

    return [ reverse(@leading_path) ];
}

sub _get_leading_path
{
    my $self = shift;
    return $self->_get_leading_path_of_coords(
        $self->_leading_path_coords()
    );
}

sub render
{
    my $self = shift;
    my %args = (@_);

    return $self->_render_generic(
        { %args , _iter_method => '_get_nav_menu_traverser',}
    );
}

sub _render_generic
{
    my $self = shift;
    my $args = shift;

    my $method = $args->{_iter_method};

    my $iterator = $self->$method();
    $iterator->traverse();
    my $html = $iterator->get_results();

    my %nav_links;
    my %nav_links_obj;

    my %links_proto =
        (
            'prev' => $self->_get_coords_while_skipping_skips(
                        \&_get_prev_coords),
            'next' => $self->_get_coords_while_skipping_skips(
                        \&_get_next_coords),
            'up' => $self->_get_up_coords(),
            'top' => $self->_get_top_coords(),
        );

    while (my ($link_rel, $coords) = each(%links_proto))
    {
        # This is so we would avoid coordinates that point to the
        # root ($coords == []).
        if (defined($coords) && @$coords == 0)
        {
            undef($coords);
        }
        if (defined($coords))
        {
            my $obj =
                $self->_get_leading_path_of_coords(
                    $coords
                )->[-1];

            $nav_links_obj{$link_rel} = $obj;
            $nav_links{$link_rel} = $obj->direct_url();
        }
    }

    my $js_code = "";

    return
        {
            'html' => $html,
            'leading_path' => $self->_get_leading_path(),
            'nav_links' => \%nav_links,
            'nav_links_obj' => \%nav_links_obj,
        };
}

1;

__END__

=head1 NAME

HTML::Widgets::NavMenu - A Perl Module for Generating HTML Navigation Menus

=head1 SYNOPSIS

    use HTML::Widgets::NavMenu;

    my $nav_menu =
        HTML::Widgets::NavMenu->new(
            'path_info' => "/me/",
            'current_host' => "default",
            'hosts' =>
            {
                'default' =>
                {
                    'base_url' => "http://www.hello.com/"
                },
            },
            'tree_contents' =>
            {
                'host' => "default",
                'text' => "Top 1",
                'title' => "T1 Title",
                'expand_re' => "",
                'subs' =>
                [
                    {
                        'text' => "Home",
                        'url' => "",
                    },
                    {
                        'text' => "About Me",
                        'title' => "About Myself",
                        'url' => "me/",
                    },
                ],
            },
        );

    my $results = $nav_menu->render();

    my $nav_menu_html = join("\n", @{$results->{'html'}});

=head1 DESCRIPTION

This module generates a navigation menu for a site. It can also generate
a complete site map, a path of leading components, and also keeps
track of navigation links ("Next", "Prev", "Up", etc.) You can start from the
example above and see more examples in the tests, in the C<examples/>
directory of the HTML-Widgets-NavMenu tarball, and complete working sites
in the version control repositories at
L<https://bitbucket.org/shlomif/shlomi-fish-homepage>
and L<https://bitbucket.org/shlomif/perl-begin/>.

=head1 USAGE

=head2 my $nav_menu = HTML::Widgets::NavMenu->new(@args)

To use this module call the constructor with the following named arguments:

=over 4

=item hosts

This should be a hash reference that maps host-IDs to another hash reference
that contains information about the hosts. An HTML::Widgets::NavMenu navigation
menu can spread across pages in several hosts, which will link from one to
another using relative URLs if possible and fully-qualified (i.e: C<http://>)
URLs if not.

Currently the only key required in the hash is the C<base_url> one that points
to a string containing the absolute URL to the sub-site. The base URL may
have trailing components if it does not reside on the domain's root directory.

An optional key that is required only if you wish to use the "site_abs"
url_type (see below), is C<trailing_url_base>, which denotes the component of
the site that appears after the hostname. For C<http://www.myhost.com/~myuser/>
it is C</~myuser/>.

Here's an example for a minimal hosts value:

            'hosts' =>
            {
                'default' =>
                {
                    'base_url' => "http://www.hello.com/",
                    'trailing_url_base' => "/",
                },
            },

And here's a two-hosts value from my personal site, which is spread across
two sites:

    'hosts' =>
    {
        't2' =>
        {
            'base_url' => "http://www.shlomifish.org/",
            'trailing_url_base' => "/",
        },
        'vipe' =>
        {
            'base_url' => "http://vipe.technion.ac.il/~shlomif/",
            'trailing_url_base' => "/~shlomif/",
        },
    },

=item current_host

This parameter indicate which host-ID of the hosts in C<hosts> is the
one that the page for which the navigation menu should be generated is. This
is important so cross-site and inner-site URLs will be handled correctly.

=item path_info

This is the path relative to the host's C<base_url> of the currently displayed
page. The path should start with a "/"-character, or otherwise a re-direction
excpetion will be thrown (this is done to aid in using this module from within
CGI scripts).

=item tree_contents

This item gives the complete tree for the navigation menu. It is a nested
Perl data structure, whose syntax is fully explained in the section
"The Input Tree of Contents".

=item ul_classes

This is an optional parameter whose value is a reference to an array that
indicates the values of the class="" arguments for the C<E<lt>ulE<gt>> tags
whose depthes are the indexes of the array.

For example, assigning:

    'ul_classes' => [ "FirstClass", "second myclass", "3C" ],

Will assign "FirstClass" as the class of the top-most ULs, "second myclass"
as the classes of the ULs inner to it, and "3C" as the class of the ULs inner
to the latter ULs.

If classes are undef, the UL tag will not contain a class parameter.

=item no_leading_dot

When this parameter is set to 1, the object will try to generate URLs that
do not start with "./" when possible. That way, the generated markup will
be a little more compact. This option is not enabled by default for
backwards compatibility, but is highly recommended.

=back

A complete invocation of an HTML::Widgets::NavMenu constructor can be
found in the SYNOPSIS above.

After you _init an instance of the navigation menu object, you need to
get the results using the render function.

=head2 $results = $nav_menu->render()

render() should be called after a navigation menu object is constructed
to prepare the results and return them. It returns a hash reference with the
following keys:

=over 4

=item 'html'

This key points to a reference to an array that contains the tags for the
HTML. One can join these tags to get the full HTML. It is possible to
delimit them with newlines, if one wishes the markup to be easier to read.

=item 'leading_path'

This is a reference to an array of node description objects. These indicate the
intermediate pages in the site that lead from the front page to the
current page. The methods supported by the class of these objects is described
below under "The Node Description Component Class".

=item 'nav_links_obj'

This points to a hash reference whose keys are link IDs for
the Firefox "Site Navigation Toolbar"
( L<http://www.bolwin.com/software/snb.shtml> ) and compatible programs,
and its values are Node Description objects. (see "The Node Description
Class" below). Here's a sample code that renders the links as
C<E<lt>link rel=...E<gt>> into the page header:


    my $nav_links = $results->{'nav_links_obj'};
    # Sort the keys so their order will be preserved
    my @keys = (sort { $a cmp $b } keys(%$nav_links));
    foreach my $key (@keys)
    {
        my $value = $nav_links->{$key};
        my $url = CGI::escapeHTML($value->direct_url());
        my $title = CGI::escapeHTML($value->title());
        print {$fh} "<link rel=\"$key\" href=\"$url\" title=\"$title\" />\n";
    }

=item 'nav_links'

This points to a hash reference whose keys are link IDs compatible with the
Firefox Site Navigation ( L<http://cdn.mozdev.org/linkToolbar/> ) and its
values are the URLs to these links. This key/value pair is provided for
backwards compatibility with older versions of HTML::Widgets::NavMenu. In new
code, one is recommended to use C<'nav_links_obj'> instead.

This sample code renders the links as C<E<lt>link rel=...E<gt>> into the
page header:

    my $nav_links = $results->{'nav_links'};
    # Sort the keys so their order will be preserved
    my @keys = (sort { $a cmp $b } keys(%$nav_links));
    foreach my $key (@keys)
    {
        my $url = $nav_links->{$key};
        print {$fh} "<link rel=\"$key\" href=\"" .
            CGI::escapeHTML($url) . "\" />\n";
    }

=back

=head2 $results = $nav_menu->render_jquery_treeview()

Renders a fully expanded tree suitable for input to JQuery's treeview plugin:
L<http://bassistance.de/jquery-plugins/jquery-plugin-treeview/> - otherwise
the same as render() .

=head2 $text = $nav_menu->gen_site_map()

This function can be called to generate a site map based on the tree of
contents. It returns a reference to an array containing the tags of the
site map.

=head2 $url = $nav_menu->get_cross_host_rel_url_ref({...})

This function can be called to calculate a URL to a different part of the
site. It accepts four named arguments, passed as a hash-ref:

=over 8

=item 'host'

This is the host ID

=item 'host_url'

This is URL within the host.

=item 'url_type'

C<'rel'>, C<'full_abs'> or C<'site_abs'>.

=item 'url_is_abs'

A flag that indicates if C<'host_url'> is already absolute.

=back

=head2 $url = $nav_menu->get_cross_host_rel_url(...)

This is like get_cross_host_rel_url_ref() except that the arguments
are clobbered into the arguments list. It is kept here for compatibility
sake.

=head1 The Input Tree of Contents

The input tree is a nested Perl data structure that represnets the tree
of the site. Each node is respresented as a Perl hash reference, with its
sub-nodes contained in an array reference of its C<'subs'> value. A
non-existent C<'subs'> means that the node is a leaf and has no sub-nodes.

The top-most node is mostly a dummy node, that just serves as the father
of all other nodes.

Following is a listing of the possible values inside a node hash and what
their respective values mean.

=over 4

=item 'host'

This is the host-ID of the host as found in the C<'hosts'> key to the
navigation menu object constructor. It implicitly propagates downwards in the
tree. (i.e: all nodes of the sub-tree spanning from the node will implicitly
have it as their value by default.)

Generally, a host must always be specified and so the first node should
specify it.

=item 'url'

This contains the URL of the node within the host. The URL should not
contain a leading slash. This value does not propagate further.

The URL should be specified for every nodes except separators and the such.

=item 'text'

This is the text that will be presented to the user as the text of the
link inside the navigation bar. E.g.: if C<'text'> is "Hi There", then the
link will look something like this:

    <a href="my-url/">Hi There</a>

Or

    <b>Hi There</b>

if it's the current page. Not that this text is rendered into HTML
as is, and so should be escaped to prevent HTML-injection attacks.

=item 'title'

This is the text of the link tag's title attribute. It is also not
processed and so the user of the module should make sure it is escaped
if needed, to prevent HTML-injection attacks. It is optional, and if not
specified, no title will be presented.

=item 'subs'

This item, if specified, should point to an array reference containing the
sub-nodes of this item, in order.

=item 'separator'

This key if specified and true indicate that the item is a separator, which
should just leave a blank line in the HTML. It is best to accompany it with
C<'skip'> (see below).

If C<'separator'> is specified, it is usually meaningless to specify all
other node keys except C<'skip'>.

=item 'skip'

This key if true, indicates that the node should be skipped when traversing
site using the Mozilla navigation links. Instead the navigation will move
to the next or previous nodes.

=item 'hide'

This key if true indicates that the item should be part of the site's flow
and site map, but not displayed in the navigation menu.

=item 'role'

This indicates a role of an item. It is similar to a CSS class, or to
DocBook's "role" attribute, only induces different HTML markup. The vanilla
HTML::Widgets::NavMenu does not distinguish between any roles, but see
L<HTML::Widgets::NavMenu::HeaderRole>.

=item 'expand'

This specifies a predicate (a Perl value that is evaluated to a boolean
value, see "Predicate Values" below.) to be matched against the path and
current host to determine if the navigation menu should be expanded at this
node. If it does, all of the nodes up to it will expand as well.

=item 'show_always'

This value if true, indicates that the node and all nodes below it (until
'show_always' is explicitly set to false) must be always displayed. Its
function is similar to C<'expand_re'> but its propagation semantics the
opposite.

=item 'url_type'

This specifies the URL type to use to render this item. It can be:

1. C<"rel"> - the default. This means a fully relative URL (if possible), like
C<"../../me/about.html">.

2. C<"site_abs"> - this uses a URL absolute to the site, using a slash at
the beginning. Like C<"/~shlomif/me/about.html">. For this to work the current
host needs to have a C<'trailing_url_base'> value set.

3. C<"full_abs"> - this uses a fully qualified URL (e.g: with C<http://> at
the beginning, even if both the current path and the pointed path belong
to the same host. Something like C<http://www.shlomifish.org/me/about.html>.

=item 'rec_url_type'

This is similar to C<'url_type'> only it recurses, to the sub-tree of the
node. If both C<'url_type'> and C<'rec_url_type'> are specified for a node,
then the value of C<'url_type'> will hold.

=item 'url_is_abs'

This flag, if true, indicates that the URL specified by the C<'url'> key
is an absolute URL like C<http://www.myhost.com/> and should not be
treated as a path within the site. All links to the page associated with
this node will contain the URL verbatim.

Note that using absolute URLs as part of the site flow is discouraged
because once they are accessed, the navigation within the primary site
is lost. A better idea would be to create a separate page within the
site, that will link to the external URL.

=item li_id

This is the HTML ID attribute that will be assigned to the specific
C<< <li> >> tag of the navigation menu. So if you have:

    'tree_contents' =>
    {
        'host' => "default",
        'text' => "Top 1",
        'title' => "T1 Title",
        'expand_re' => "",
        'subs' =>
        [
            {
                'text' => "Home",
                'url' => "",
            },
            {
                'text' => "About Me",
                'title' => "About Myself",
                'url' => "me/",
                'li_id' => 'about_me',
            },
        ],
    },

Then the HTML for the About me will look something like:

    <li id="about_me">
    <a href="me/ title="About Myself">About Me</a>
    </li>

=back

=head1 Predicate Values

An explicitly specified predicate value is a hash reference that contains
one of the following three keys with their appropriate values:

=over 4

=item 'cb' => \&predicate_func

This specifies a sub-routine reference (or "callback" or "cb"), that will be
called to determine the result of the predicate. It accepts two named arguments
- C<'path_info'> which is the path of the current page (without the leading
slash) and C<'current_host'> which is the ID of the current host.

Here is an example for such a callback:

    sub predicate_cb1
    {
        my %args = (@_);
        my $host = $args{'current_host'};
        my $path = $args{'path_info'};
        return (($host eq "true") && ($path eq "mypath/"));
    }

=item 're' => $regexp_string

This specifies a regular expression to be matched against the path_info
(regardless of what current_host is), to determine the result of the
predicate.

=item 'bool' => [ 0 | 1 ]

This specifies the constant boolean value of the predicate.

=back

Note that if C<'cb'> is specified then both C<'re'> and C<'bool'> will
be ignored, and C<'re'> over-rides C<'bool'>.

Orthogonal to these keys is the C<'capt'> key which specifies whether this
expansion "captures" or not. This is relevant to the behaviour in the
breadcrumbs' trails, if one wants the item to appear there or not. The
default value is true.

If the predicate is not a hash reference, then HTML::Widgets::NavMenu will
try to guess what it is. If it's a sub-routine reference, it will be an
implicit callback. If it's one of the values C<"0">, C<"1">, C<"yes">,
C<"no">, C<"true">, C<"false">, C<"True">, C<"False"> it will be considered
a boolean. If it's a different string, a regular expression match will
be attempted. Else, an excpetion will be thrown.

Here are some examples for predicates:

    # Always expand.
    'expand' => { 'bool' => 1, };

    # Never expand.
    'expand' => { 'bool' => 0, };

    # Expand under home/
    'expand' => { 're' => "^home/" },

    # Expand under home/ when the current host is "foo"
    sub expand_path_home_host_foo
    {
        my %args = (@_);
        my $host = $args{'current_host'};
        my $path = $args{'path_info'};
        return (($host eq "foo") && ($path =~ m!^home/!));
    }

    'expand' => { 'cb' => \&expand_path_home_host_foo, },

=head1 The Node Description Class

When retrieving the leading path or the C<nav_links_obj>, an array of objects
is returned. This section describes the class of these objects, so one will
know how to use them.

Basically, it is an object that has several accessors. The accessors are:

=over 4

=item host

The host ID of this node.

=item host_url

The URL of the node within the host. (one given in its 'url' key).

=item label

The label of the node. (one given in its 'text' key). This is not
SGML-escaped.

=item title

The title of the node. (that can be assigned to the URL 'title' attribute).
This is not SGML-escaped.

=item direct_url

A direct URL (usable for inclusion in an A tag ) from the current page to this
page.

=item url_type

This is the C<url_type> (see above) that holds for this node.

=back

=head1 SEE ALSO

See the article Shlomi Fish wrote for Perl.com for a gentle introduction to
HTML-Widgets-NavMenu:

L<http://www.perl.com/pub/a/2005/07/07/navwidgets.html>

=over 4

=item L<HTML::Widgets::NavMenu::HeaderRole>

An HTML::Widgets::NavMenu sub-class that contains support for another
role. Used for the navigation menu in L<http://perl-begin.org/>.

=item L<HTML::Widget::SideBar>

A module written by Yosef Meller for maintaining a navigation menu.
HTML::Widgets::NavMenu originally utilized it, but no longer does. This module
does not makes links relative on its own, and tends to generate a lot of
JavaScript code by default. It also does not have too many automated test
scripts.

=item L<HTML::Menu::Hierarchical>

A module by Don Owens for generating hierarchical HTML menus. I could not
quite understand its tree traversal semantics, so I ended up not using it. Also
seems to require that each of the tree node will have a unique ID.

=item L<HTML::Widgets::Menu>

This module also generates a navigation menu. The CPAN version is relatively
old, and the author sent me a newer version. After playing with it a bit, I
realized that I could not get it to do what I want (but I cannot recall
why), so I abandoned it.

=back

=head1 AUTHORS

Shlomi Fish, E<lt>shlomif@cpan.orgE<gt>, L<http://www.shlomifish.org/> .

=head1 THANKS

Thanks to Yosef Meller (L<http://search.cpan.org/~yosefm/>) for writing
the module HTML::Widget::SideBar on which initial versions of this modules
were based. (albeit his code is no longer used here).

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Shlomi Fish. All rights reserved.

You can use, modify and distribute this module under the terms of the MIT X11
license. ( L<http://www.opensource.org/licenses/mit-license.php> ).

=cut
