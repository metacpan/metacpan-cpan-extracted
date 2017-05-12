package Lingua::EN::Semtags::Sentence;

use strict;
use warnings;
use constant TRUE  => 1;
use constant FALSE => 0;

our $VERSION = '0.01';

#============================================================	
sub new {
#============================================================
	my ($invocant, %args) = @_;
	my $self = bless ({}, ref $invocant || $invocant);
	$self->_init(%args);
	return $self;
}

#============================================================
sub _init {
#============================================================
	my ($self, %args) = @_;
	
	# Initialize attributes
	$self->{string} = undef;
	$self->{word_tokens} = {}; # $token => $pos
	$self->{phrase_tokens} = {}; # $token => TRUE
	$self->{lunits} = [];
	
	# Set the args that came from the constructor
	foreach my $arg (sort keys %args) {
		die "Unknown argument: $arg!" unless exists $self->{$arg};
		$self->{$arg} = $args{$arg};
	}
}

#============================================================
sub string { defined $_[1] ? $_[0]->{string} = $_[1] : $_[0]->{string}; }
sub word_tokens { $_[0]->{word_tokens}; }
sub phrase_tokens { $_[0]->{phrase_tokens}; }
sub lunits { @{$_[0]->{lunits}}; }
sub add_lunit { push @{$_[0]->{lunits}}, $_[1]; }
#============================================================

TRUE;

__END__

=head1 NAME

Lingua::EN::Semtags::Sentence - a DTO used by C<Lingua::EN::Semtags::Engine> 

=head1 SYNOPSIS

  use Lingua::EN::Semtags::Sentence;

=head1 DESCRIPTION

A DTO used by C<Lingua::EN::Semtags::Engine>.  Aggregates instances of 
C<Lingua::EN::Semtags::LangUnit>s.

=head2 METHODS

=over 4

=item B<add_lunit($lunit)> 

Adds C<$lunit> to C<$self-E<gt>{lunits}>.

=item B<lunits()>

Returns C<$self-E<gt>{lunits}>.

=item B<phrase_tokens()>

Returns C<$self-E<gt>{phrase_tokens}>. Returns a hash ref. The hash is of the 
following format: C<{$phrase_token =E<gt> 1}>.

=item B<string([$string])>

Returns/sets C<$self-E<gt>{string}>.

=item B<word_tokens()>

Returns C<$self-E<gt>{word_tokens}> (a hash ref). The hash is of the 
following format: C<{$word_token =E<gt> $pos}>.    

=back

=head1 SEE ALSO

L<Lingua::EN::Semtags::Engine>

=head1 AUTHOR

Igor Myroshnichenko E<lt>igorm@cpan.orgE<gt>

Copyright (c) 2008, All Rights Reserved.

This software is free software and may be redistributed and/or
modified under the same terms as Perl itself.

=cut