package Egg::Log::STDERR;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: STDERR.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.01';

sub new { bless [], $_[0] }

sub error  { shift; _print('ERROR' , @_) }
sub debug  { shift; _print('DEBUG' , @_) }
sub info   { shift; _print('INFO'  , @_) }
sub notice { shift; _print('NOTICE', @_) }

sub _print {
	my $lebel= shift;
	my $msg= $_[0] ? ($_[1] ? join("\n", @_): $_[0]): 'N/A';
	$msg.= "\n" unless $msg=~m{\n$};
	print STDERR "${lebel}: $msg";
}

1;

__END__

=head1 NAME

Egg::Log::STDERR - Log message is output to STDERR.

=head1 DESCRIPTION

The log message is output to STDERR.

The object of this module can be acquired in the log method of the project object.

  my $log= $project->log;

=head1 METHODS

=head2 new

Constructor.

=head2 error ([MESSAGE_STR])

MESSAGE_STR is output putting up ERROR to the head.

=head2 debug ([MESSAGE_STR])

MESSAGE_STR is output putting up DEBUG to the head.

=head2 info ([MESSAGE_STR])

MESSAGE_STR is output putting up INFO to the head. 

=head2 notice ([MESSAGE_STR])

MESSAGE_STR is output putting up NOTES to the head.

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

