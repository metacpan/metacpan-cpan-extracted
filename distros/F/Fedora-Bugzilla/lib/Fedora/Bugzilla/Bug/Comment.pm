#############################################################################
#
# A class representing a bug comment in Fedora's bugzilla 
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 12/30/2008 10:03:33 AM PST
#
# Copyright (c) 2008 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::Bugzilla::Bug::Comment;

use Moose;

use Fedora::Bugzilla::Types  qw{ BugzillaDateTime EmailAddress };
use MooseX::Types::DateTimeX 'DateTime';

use namespace::clean -except => 'meta';

use overload '""' => sub { shift->as_string }, fallback => 1;

our $VERSION = '0.13';

=begin for_author

As of Tue Dec 30 10:08:19 PST 2008, our xml comment snippet looks like:

<long_desc isprivate="0">
    <who name="Chitlesh GOORAH">cgoorah@yahoo.com.au</who>
    <bug_when>2008-12-21 08:53:23 EDT</bug_when>
    <thetext>
Spec URL: http://chitlesh.fedorapeople.org/RPMS/perl-Hardware-Vhdl-Lexer.spec
SRPM URL:
http://chitlesh.fedorapeople.org/RPMS/perl-Hardware-Vhdl-Lexer-1.00-1.fc10.src.rpm
Description:
Hardware::Vhdl::Lexer splits VHDL code into lexical tokens. To use it, you
need to first create a lexer object, passing in something which will supply
chunks of VHDL code to the lexer. Repeated calls to the get_next_token
method of the lexer will then return VHDL tokens (in scalar context) or a
token type code and the token (in list context). get_next_token returns
undef when there are no more tokens to be read.
    </thetext>
</long_desc>

=end for_author
=cut

# required atts
has bug    => (is => 'ro', isa => 'Fedora::Bugzilla::Bug', required => 1);
has number => (is => 'ro', isa => 'Int',                   required => 1);
has twig   => (is => 'ro', isa => 'XML::Twig::Elt',        required => 1);

# atts from the comment twig

my @defaults = (is => 'ro', lazy_build => 1);

has is_private => (@defaults, isa => 'Bool'                   );
has who        => (@defaults, isa => EmailAddress, coerce => 1);
has date       => (@defaults, isa => DateTime,     coerce => 1);
has text       => (@defaults, isa => 'Str'                    );

sub _build_is_private { shift->twig->att('isprivate')               }
sub _build_date       { shift->twig->first_child('bug_when')->text  }
sub _build_text       { shift->twig->first_child('thetext')->text   }

sub _build_who { 
    my $elt = shift->twig->first_child('who');
    return Email::Address->new($elt->att('name') => $elt->text);
}

has title => (is => 'ro', isa => 'Str', lazy_build => 1);

sub as_string { shift->text }

sub _build_title {
    my $self = shift @_;
    my $bug  = $self->bug;

    return "Bug #$bug Comment #" . $self->number;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Fedora::Bugzilla::Bug::Comment - A bug comment

=head1 SYNOPSIS

	use <Module::Name>;
	# Brief but working code example(s) here showing the most common usage(s)

	# This section will be as far as many users bother reading
	# so make it as educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head3, etc.)


=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.
These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module provides.
Name the section accordingly.

In an object-oriented module, this section should begin with a sentence of the
form "An object of this class represents...", to give the reader a high-level
context to help them understand the methods that are subsequently described.


=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies.


=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.


=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication whether these required modules are
part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.


=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for
system or program resources, or due to internal limitations of Perl
(for example, many modules that use source code filters are mutually
incompatible).

=head1 SEE ALSO

L<...>

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication
whether they are likely to be fixed in an upcoming release.

Also a list of restrictions on the features the module does provide:
data types that cannot be handled, performance issues and the circumstances
in which they may arise, practical limitations on the size of data sets,
special cases that are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to Chris Weyl <cweyl@alumni.drew.edu>, or (preferred) 
to this package's RT tracker at <bug-Fedora-Bugzilla@rt.cpan.org>.

Patches are welcome.

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Chris Weyl <cweyl@alumni.drew.edu>

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



