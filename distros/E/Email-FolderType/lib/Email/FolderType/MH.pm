use strict;
use warnings;
package Email::FolderType::MH;
{
  $Email::FolderType::MH::VERSION = '0.814';
}
# ABSTRACT: class to help Email::FolderType recognise MH mail directories

sub match { @_ || return 0; $_[0] =~ m{/\.$}  }

1;

__END__

=pod

=head1 NAME

Email::FolderType::MH - class to help Email::FolderType recognise MH mail directories

=head1 VERSION

version 0.814

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Simon Wistow.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
