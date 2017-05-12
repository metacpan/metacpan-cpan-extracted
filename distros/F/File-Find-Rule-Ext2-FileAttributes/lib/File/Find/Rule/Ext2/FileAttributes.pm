package File::Find::Rule::Ext2::FileAttributes;
use strict;
use warnings;
use File::Find::Rule;
use Linux::Ext2::FileAttributes;

use base qw( File::Find::Rule );
use vars qw( $VERSION @EXPORT );

@EXPORT  = @File::Find::Rule::EXPORT;
$VERSION = '0.02';

=head1 NAME

File::Find::Rule::Ext2::FileAttributes - rules to match on Ext2::FileAttributes

=head1 SYNOPSIS

use File::Find::Rule::Ext2::FileAttributes;

my @immutable = File::Find::Rule->immutable->in( '.' );
print "@immutable\n";

my @appendable = File::Find::Rule->appendable->in( '.' );
print "@appendable\n";

=head1 DESCRIPTION

File::Find::Rule::Ext2::FileAttributes wraps the
Linux::Ext2::FileAttributes module and allows you to filter files by the
immutable or appendable extended attributes using File::Find::Rule.

=head1 METHODS

=over

=item immutable

This method filters on the immutable flag. If this flag is set on a file
even root cannot change the files content or unlink it without first
removing the flag.

=item appendable

This method filters on the append only flag. If this flag is set on a
file then its contents can be added to but not removed unless the flag is
first removed.

=back

=cut


sub File::Find::Rule::immutable () {
  my $self = shift()->_force_object;
  $self->exec( sub { is_immutable( $_ ) } );
}

sub File::Find::Rule::appendable () {
  my $self = shift()->_force_object;
  $self->exec( sub { is_append_only( $_ ) } );
}


1;


__END__

=head1 AUTHOR

Dean Wilson <dean.wilson@gmail.com> L<http://www.unixdaemon.net>

=head1 LICENCE AND COPYRIGHT

Copyright 2008 Dean Wilson. All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Find::Rule>, L<Linux::Ext2::FileAttributes>

=cut
