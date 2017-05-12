package Lingua::Verbnet::Ambiguity;

use strict;
use warnings;

# no explicit ctor, it's constructed via Lingua::Verbnet->ambiguity

sub score ($$) { $_[0]->{$_[1]}; }
sub hash ($) { %{$_[0]}; }

1;

=head1 NAME

Lingua::Verbnet::Ambiguity -- query ambiguity stats as collected by Lingua::Verbnet

=head1 SYNOPSIS

	use Lingua::Verbnet;
	my @verbnet_xml_files = ... ;
	my $verbnet = Lingua::Verbnet->new(@verbnet_xml_files);
	$verbnet->ambiguity->score('cut'); # get the ambiguity score of the verb 'cut'
	my %stats = $verbnet->ambiguity->hash; # get the full ambiguity scores hash (verb => score)

=head1 DESCRIPTION

An object to query ambiguity stats as collected by Lingua::Verbnet.

Accessed through Lingua::Verbnet.

=head1 METHODS

=over

=item score

Given a verb which is a member of a given vnclass, 
return its ambiguity score as determined
by the number of frames within the vnclass.

If a verb is not listed in the verbnet database
that had been fed to Lingua::Verbnet, then 0 is returned.

=item hash

Return the object contents in a hash format, in the form of 
	(
		verb1	=>	score1,
		verb2	=>	score2,
		...
	)

=back

=head1 SEE ALSO

L<Lingua::Verbnet>

=head1 AUTHOR

Vassilii Khachaturov <F<vassilii@tarunz.org>>

=head1 LICENSE

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>
