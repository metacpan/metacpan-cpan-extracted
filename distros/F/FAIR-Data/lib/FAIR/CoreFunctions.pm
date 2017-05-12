package FAIR::CoreFunctions;
$FAIR::CoreFunctions::VERSION = '1.001';




use strict;
use Moose::Role;

sub statement {
	my ($s, $p, $o) = @_;
	unless (ref($s) =~ /Trine/){
		$s =~ s/[\<\>]//g;
		$s = RDF::Trine::Node::Resource->new($s);
	}
	unless (ref($p) =~ /Trine/){
		$p =~ s/[\<\>]//g;
		$p = RDF::Trine::Node::Resource->new($p);
	}
	unless (ref($o) =~ /Trine/){

		if ($o =~ /^http\:\/\// || $o =~ /^https\:\/\//){
			$o = RDF::Trine::Node::Resource->new($o);
		} elsif ($o =~ /^<http\:\/\//){
			$o =~ s/[\<\>]//g;
			$o = RDF::Trine::Node::Resource->new($o);
		} elsif ($o =~ /"(.*?)"\^\^\<http\:/) {
			$o = RDF::Trine::Node::Literal->new($1);
		} else {
			$o = RDF::Trine::Node::Literal->new($o);				
		}
	}
	my $statement = RDF::Trine::Statement->new($s, $p, $o);
	return $statement;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FAIR::CoreFunctions

=head1 VERSION

version 1.001

=head1 Name  FAIR::CoreFunctions

=head1 Description 

a Moose Role that contains things that various modules need to do

=head1 AUTHOR

Mark Denis Wilkinson (markw [at] illuminae [dot] com)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Mark Denis Wilkinson.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
