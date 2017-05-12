package File::Wildcard::Find;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $finder);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    @EXPORT      = qw(findbegin findnext findall);
    @EXPORT_OK   = qw(findbegin findnext findall $finder);
    %EXPORT_TAGS = ( all => \@EXPORT_OK );
}

use File::Wildcard;

sub findbegin {
    $finder = File::Wildcard->new( path => shift );
}

sub findnext {
    $finder->next;
}

sub findall {
    my $allfinder = File::Wildcard->new( path => shift );
    $allfinder->all;
}

1;
__END__

=head1 NAME

File::Wildcard::Find - Simple interface to File::Wildcard

=head1 SYNOPSIS

  use File::Wildcard::Find;
  findbegin( "/home/me///core");
  while (my $file = findnext()) {
     unlink $file;
  }
  
=head1 DESCRIPTION

L<File::Wildcard> provides a comprehensive object interface that allows you
to do powerful processing with wildcards. Some consider this too unwieldy for
simple tasks.

The module File::Wildcard::Find provides a straightforward interface. Only a
single wildcard stream is accessible, but this should be sufficient for
one liners and simple applications.

=head1 FUNCTIONS

=head2 findbegin

This takes 1 parameter, a path with wildcards as a string. See 
L<File::Wildcard> for details of what can be passed.

=head2 findnext

Iterator that returns successive matches, then undef.

=head2 findall

Returns a list of all matches
