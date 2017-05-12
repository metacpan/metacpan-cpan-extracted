package Git::Version;
$Git::Version::VERSION = '1.000';
use strict;
use warnings;
use Carp;

use Git::Version::Compare ();

use overload
  '""'  => sub { ${ $_[0] } },
  'cmp' => sub {
    my ( $v1, $v2, $swap ) = @_;
    return $swap
      ? Git::Version::Compare::cmp_git( $v2, $v1 )
      : Git::Version::Compare::cmp_git( $v1, $v2 );
  };

sub new {
    my ( $class, $v ) = @_;
    croak "$v does not look like a Git version"
      if !Git::Version::Compare::looks_like_git($v);
    return bless \$v, $class;
}

1;

__END__

=head1 NAME

Git::Version - Git version objects

=head1 SYNOPSIS

    use Git::Version;

    my $v = Git::Version->new( `git --version` );
    print "You've got an old git" if $v lt '1.6.5';

=head1 DESCRIPTION

C<Git::Version> offers specialized version objects that can compare
strings corresponding to a Git version number.

The actual comparison is handled by L<Git::Version::Compare>, so the
strings can be version numbers, tags from C<git.git> or the output of
C<git version> or C<git describe>.

=head1 METHODS

=head2 new

    my $v = Git::Version->new(`git --version`);

Creates a new C<Git::Version> object from a string.

=head1 SEE ALSO

L<Git::Version::Compare>.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2016 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
