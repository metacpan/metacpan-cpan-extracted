#############################################################################
#
# A class representing an (existing) attachment.
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/25/2009 04:55:02 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::Bugzilla::Bug::Attachment;

use Moose;

use MooseX::Types::Path::Class  ':all';
use MooseX::Types::DateTimeX    'DateTime';

use MIME::Base64;

use Fedora::Bugzilla::Types     qw{ BugzillaDateTime EmailAddress };

use namespace::clean -except => 'meta';

use overload '""' => sub { shift->as_string }, fallback => 1;

our $VERSION = '0.13';

=begin inline_comment

As of Sat Jan 24 12:02:26 PST 2009, our xml attachment snippet looks like:

<attachment isobsolete="0" ispatch="0" isprivate="0">
    <attachid>320125</attachid>
    <date>2008-10-11 19:45 EDT</date>
    <desc>the great fedora-release!</desc>
    <filename>fedora-release</filename>
    <type>text/plain</type>
    <size>27</size>
    <attacher>cweyl@alumni.drew.edu</attacher>
    <data encoding="base64">RmVkb3JhIHJlbGVhc2UgOSAoU3VscGh1cikK</data>
</attachment>

FIXME -- we should deal with attachment flags, too!

=end inline_comment
=cut

# required atts
has  bug    => (is => 'ro', isa => 'Fedora::Bugzilla::Bug', required => 1);
has  number => (is => 'ro', isa => 'Int',                   required => 1);
has _twig   => (is => 'ro', isa => 'XML::Twig::Elt',        required => 1);

# atts from the comment twig

my @defaults = (is => 'ro', lazy_build => 1);

has id          => (@defaults, isa => 'Int'                    );
has date        => (@defaults, isa => DateTime, coerce => 1    );
has desc        => (@defaults, isa => 'Str'                    );
has filename    => (@defaults, isa => File, coerce => 1        );
has type        => (@defaults, isa => 'Str'                    );
has size        => (@defaults, isa => 'Int'                    );
has attacher    => (@defaults, isa => EmailAddress, coerce => 1);
has is_obsolete => (@defaults, isa => 'Bool'                   );
has is_patch    => (@defaults, isa => 'Bool'                   );
has is_private  => (@defaults, isa => 'Bool'                   );

has data     => (@defaults, isa => 'Str');
has raw_data => (@defaults, isa => 'Str');
has encoding => (@defaults, isa => 'Str');

sub _build_id       { shift->_twig->first_child('attachid')->text }
sub _build_date     { shift->_twig->first_child('date')->text     }
sub _build_desc     { shift->_twig->first_child('desc')->text     }
sub _build_filename { shift->_twig->first_child('filename')->text }
sub _build_type     { shift->_twig->first_child('type')->text     }
sub _build_size     { shift->_twig->first_child('size')->text     }
sub _build_attacher { shift->_twig->first_child('attacher')->text }

sub _build_is_obsolete { shift->_twig->att('isobsolete') }
sub _build_is_patch    { shift->_twig->att('ispatch')    }
sub _build_is_private  { shift->_twig->att('isprivate')  }

sub _build_data     { decode_base64(shift->raw_data)                    }
sub _build_raw_data { shift->_twig->first_child('data')->text            }
sub _build_encoding { shift->_twig->first_child('data')->att('encoding') }

# make sure we can get at them through their "proper" names, too
sub attachid   { shift->id(@_)         }
sub isobsolete { shift->isobsolete(@_) }
sub ispatch    { shift->ispatch(@_)    }
sub isprivate  { shift->isprivate(@_)  }

# FIXME probably not what we want, but WFN
sub as_string { shift->id }

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Fedora::Bugzilla::Bug::Attachment - A bug attachment

=head1 DESCRIPTION

This class represents a bug attachment, and provides various methods to
manipulate its data.  Right now, we don't support making any modifications to
the attachment (e.g. marking obsolete).

=head1 METHODS

=over

=item B<bug>

Our parent bug.

=item B<number>

The id of the attachment relative to the bug (e.g. this is attachment number()
of 13,000).

=item B<id>

=item B<date>

=item B<desc>

=item B<filename>


=item B<size>

=item B<type>

=item B<attacher>

=item B<is_obsolete>

=item B<is_patch>

=item B<is_private>

=item B<data>

=item B<raw_data> 

=item B<encoding>

=item B<as_string>

This class stringifies to its id().

=back

=head1 DIAGNOSTICS

We'll complain loudly and die on a non-existant attachment.

We will also complain loudly if the data decoding process fails for whatever
reason.  See L<MIME::Base64> for more details.

=head1 SEE ALSO

L<Fedora::Bugzilla::Bug>, L<Fedora::Bugzilla>.

=head1 LIMITATIONS

Right now, we don't support any methods to change an attachment (status, etc),
neither do we provide an easy way of getting at the flags that may be
associated with the attachment.

=head1 BUGS 

See L<Fedora::Bugzilla>.

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the 

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut



