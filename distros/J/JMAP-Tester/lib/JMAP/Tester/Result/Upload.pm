use v5.14.0;

package JMAP::Tester::Result::Upload 0.104;
# ABSTRACT: what you get when you upload a blob

use Moo;
with 'JMAP::Tester::Role::HTTPResult';

use namespace::clean;

#pod =head1 OVERVIEW
#pod
#pod This is what you get when you upload!  It's got an C<is_success> method.  It
#pod returns true. It also has:
#pod
#pod =method blob_id
#pod
#pod The blobId of the blob from the JMAP server.
#pod
#pod =method blobId
#pod
#pod An alias for C<blob_id> above.
#pod
#pod =method type
#pod
#pod The media type of the file (as specified in RFC6838, section 4.2) as set in the
#pod Content-Type header of the upload HTTP request.
#pod
#pod =method size
#pod
#pod The size of the file in octets.
#pod
#pod =cut

sub is_success { 1 }

has payload => (
  is => 'ro',
);

sub blob_id { $_[0]->payload->{blobId}  }
sub blobId  { $_[0]->payload->{blobId}  }
sub type    { $_[0]->payload->{type}    }
sub size    { $_[0]->payload->{size}    }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::Result::Upload - what you get when you upload a blob

=head1 VERSION

version 0.104

=head1 OVERVIEW

This is what you get when you upload!  It's got an C<is_success> method.  It
returns true. It also has:

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 blob_id

The blobId of the blob from the JMAP server.

=head2 blobId

An alias for C<blob_id> above.

=head2 type

The media type of the file (as specified in RFC6838, section 4.2) as set in the
Content-Type header of the upload HTTP request.

=head2 size

The size of the file in octets.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Fastmail Pty. Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
