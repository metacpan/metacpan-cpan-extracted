package Gruntmaster::App::Command;

use 5.014000;
use strict;
use warnings;
use re '/s';

our $VERSION = '6000.001';

use parent qw/App::Cmd::Command/;
use Pod::Usage;

sub description {
	my ($self) = @_;
	my ($file) = (ref $self) =~ s,::,/,gr;
	my $usage;
	open my $fh, '>', \$usage; ## no critic (RequireCheckedOpen)
	pod2usage(-input => $INC{"$file.pm"}, -output => $fh, -exitval => 'NOEXIT', -verbose => 99, -sections => [qw/SYNOPSIS DESCRIPTION/]);
	close $fh; ## no critic (RequireCheckedClose)
	$usage =~ s/Usage:/Usage examples:/;
	1 while chomp $usage;
	$usage
}

1;
__END__

=encoding utf-8

=head1 NAME

Gruntmaster::App::Command - Base class for gm commands

=head1 SYNOPSIS

  package Gruntmaster::App::Command::foo;
  use Gruntmaster::App '-command';

=head1 DESCRIPTION

Gruntmaster::App::Command is the base class of all gm commands. Its
only role is to extract a command's documentation from its POD by
overriding the description method to use L<Pod::Usage>.

=head1 SEE ALSO

L<Gruntmaster::App>, L<gm>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
