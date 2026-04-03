package DataHelper;

use strict;
use warnings;

our $VERSION = '1.33';

use Exporter 'import';

use Developer::Dashboard::JSON qw(json_decode json_encode);

our @EXPORT = qw(j je);

# j($value)
# Encodes a Perl value to canonical JSON text.
# Input: any JSON-encodable Perl value.
# Output: JSON string.
sub j {
    return json_encode( $_[0] );
}

# je($text)
# Decodes JSON text to a Perl value.
# Input: JSON string.
# Output: decoded Perl value.
sub je {
    return json_decode( $_[0] // '' );
}

1;

__END__

=head1 NAME

DataHelper - legacy JSON helper compatibility functions

=head1 SYNOPSIS

  use DataHelper qw(j je);
  my $json = j({ ok => 1 });

=head1 DESCRIPTION

This module provides the small legacy JSON helper functions used by older
bookmark code blocks.

=head1 FUNCTIONS

=head2 j, je

Encode and decode JSON values.

=cut
