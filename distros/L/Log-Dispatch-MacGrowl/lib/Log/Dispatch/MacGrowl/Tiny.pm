# 

package Log::Dispatch::MacGrowl::Tiny;

use strict;
use vars qw($VERSION);
use Growl::Tiny ();

$VERSION = '0.01';

sub log_message {
    my $self = shift;
    my %p = @_;

    Growl::Tiny::notify( {
	subject => $p{message},
	title => $self->{title},
	priority =>  $self->{priority},
	sticky => $self->{sticky},
	image => $self->{icon_file},
    } );
}

1;

__END__

=head1 NAME

Log::Dispatch::MacGrowl::Tiny - Growl::Tiny backend for L::D::MacGrowl

=head1 DEPENDENCY

Growl::Tiny, growlnotify(1)

=head1 SEE ALSO

http://growl.info/extras.php#growlnotify

=head1 AUTHOR

Ryo Okamoto C<< <ryo at aquahill dot net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2011 Ryo Okamoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
