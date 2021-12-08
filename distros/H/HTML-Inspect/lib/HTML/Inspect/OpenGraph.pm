# Copyrights 2021 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution HTML::Inspect.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

### This module handles the extraction of OpenGraph data.

use strict;
use warnings;
use utf8;

package HTML::Inspect;
use vars '$VERSION';
$VERSION = '1.00';
    # role OpenGraph

use Log::Report 'html-inspect';
use HTML::Inspect::Util qw(trim_attr xpc_find);

my @sub_types = qw/article book fb music profile video website/;

my %default_prefixes = (
    og => 'https://ogp.me/ns#',
    (map +($_ => "https://ogp.me/ns/$_#"), @sub_types),
);

my %namespace2prefix = reverse %default_prefixes;

# When the property itself does not contain an attribute, but we know
# that it may have attributes ("structured properties"), we need to create
# a HASH which stores this content.  We want consistent output, whether
# the attributes are actually present or not.
my %is_structural = (
    'og:image'    => 'url',
    'og:video'    => 'url',
    'og:audio'    => 'url',
    'og:locale'   => 'this',
    'music:album' => 'location',       # not sure about this one
    'music:song'  => 'description',    # not sure about this one
    'video:actor' => 'profile',
);

# Some properties or attributes can appear more than once.  They will always
# be collected as ARRAY, even if there is only one presence: this helps
# implementors.
my %is_array = map +($_ => 1), qw/
    article:author
    article:tag
    book:author
    book:tag
    music:album
    music:musician
    music:song
    og:audio
    og:image
    og:locale:alternate
    og:video
    video:actor
    video:director
    video:tag
    video:writer
/;

my $find_prefix_decls  = xpc_find '//*[@prefix]';
my $find_meta_property = xpc_find '//meta[@property]';

sub collectOpenGraph(%) {
    my ($self, %args) = @_;
    return $self->{HIO_og} if $self->{HIO_og};

    # Create a map which translates the used prefix in the HTML, to the prefered
    # prefix from the OGP specification, so we can normalize prefix.
    my %prefer;
    foreach my $def (map $_->getAttribute('prefix'), $find_prefix_decls->($self)) {
        while ($def =~ m!(\w+)\:\s*(\S+)!g) {
            $prefer{$1} = $namespace2prefix{$2};    # only known namespaces!
        }
    }

    my $data = $self->{HIO_og} = {};
    foreach my $meta ($find_meta_property->($self)) {
        my ($used_prefix, $name, $attr) = split /\:/, lc $meta->getAttribute('property');
        (defined $name && length $name) or next;

        # The required prefix declarations are often missing or incorrectly
        # formatted, so we are kind for things we recognize.  But do not
        # take stuff which is probably not part of OpenGraph.
        my $prefix = $prefer{$used_prefix}
            || (exists $default_prefixes{$used_prefix} ? $used_prefix : next);

        my $content  = trim_attr $meta->getAttribute('content');
        my $table    = $data->{$prefix} ||= {};
        my $property = "$prefix:$name";

        # The spec is not clear.  Some structures may start with an $property:url,
        # is what examples tell us.  Not documented on ogp.me
        undef $attr
            if defined $attr && $attr eq 'url' && $is_structural{$property};

        if($attr) {
            if(!$is_structural{$property}) {
                # Found attribute, but used on something which is not structural.
                # People who did not understand the spec, broken order, or unknown extension.
            }
            elsif(my $structure = $is_array{$property} ? $table->{$name}[-1] : $table->{$name}) {
                # Attribute added to current structure
                if($is_array{"$property:$attr"}) {
                    push @{ $structure->{$attr} }, $content;
                }
                else {
                    $structure->{$attr} = $content;
                }
            }
            # ignore attributes without starting property
        }
        elsif(my $default_attr = $is_structural{$property}) {
            # Start of new structure.
            if($is_array{$property}) {
                push @{$table->{$name}}, +{ $default_attr => $content };
            }
            else {
                $table->{$name} = +{ $default_attr => $content };
            }
        }
        elsif($is_array{$property}) {
            # Top-level non-structures: simple value(s)
            push @{$table->{$name}}, $content;
        }
        else {
            $table->{$name} = $content;
        }
    }

    keys %$data ? $data : undef;
}

1;
