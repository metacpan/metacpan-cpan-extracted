package ExtUtils::Builder::Planner::Extension;
$ExtUtils::Builder::Planner::Extension::VERSION = '0.019';
use strict;
use warnings;

sub add_delegate {
	my ($self, $planner, $as, $make_node) = @_;
	my $delegate = sub {
		my ($self, @args) = @_;
		for my $node ($make_node->(@args)) {
			$planner->add_node($node);
		}
	};
	$planner->add_delegate($as, $delegate);
	return;
}

sub add_helper {
	my ($self, $planner, $as, $helper) = @_;
	$planner->add_delegate($as, sub {
		my ($self, @args) = @_;
		return $helper->(@args);
	});
	return;
}

1;

#ABSTRACT: a base class for Planner extensions

__END__

=pod

=encoding UTF-8

=head1 NAME

ExtUtils::Builder::Planner::Extension - a base class for Planner extensions

=head1 VERSION

version 0.019

=head1 METHODS

=head2 add_delegate($planner, $as, $make_node)

This adds a delegate function to C<$planner> with name C<$as>. The function must return zero or more L<node|ExtUtils::Builder::Node> objects that will be added to the plan.

=head2 add_helper($helper, $as, $sub)

This adds a helper function to C<$planner> with name <$as>. It will return whatever C<$sub> returns, but will not affect the build tree in any way.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
