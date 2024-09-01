package Dist::Build::XS::Conf;
$Dist::Build::XS::Conf::VERSION = '0.012';
use strict;
use warnings;

use parent 'ExtUtils::Builder::Planner::Extension';

sub add_methods {
	my ($self, $planner, %args) = @_;

	my $add_xs = $planner->can('add_xs') or die "XS must be loaded before imports can be done";

	$planner->load_module('ExtUtils::Builder::Conf');

	$planner->add_delegate('add_xs', sub {
		my ($planner, %args) = @_;

		for my $key (qw/include_dirs library_dirs libraries extra_compiler_flags extra_linker_flags/) {
			push @{ $args{$key} }, $planner->$key;
		}

		my %defines = $planner->defines;
		for my $key (keys %defines) {
			$args{defines}{$key} //= $defines{$key};
		}

		$planner->$add_xs(%args);
	});
}

# ABSTRACT: Configure-time utilities for Dist::Build for using C headers, libraries, or OS features

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Build::XS::Conf - Configure-time utilities for Dist::Build for using C headers, libraries, or OS features

=head1 VERSION

version 0.012

=head1 SYNOPSIS

 load_module("Dist::Build::XS");
 
 find_libs_for(source => <<'EOF', libs => [ ['socket'], ['moonlaser'] ]);
 #include <stdio.h>
 #include <sys/socket.h>
 int main(int argc, char *argv[]) {
   printf("PF_MOONLASER is %d\n", PF_MOONLASER);
   return 0;
 }
 EOF

 add_xs(module_name => 'Socket::MoonLaser');

=head2 DESCRIPTION

This module integrates L<ExtUtils::Builder::Conf|ExtUtils::Builder::Conf> into L<Dist::Build::XS|Dist::Build::XS>. Any arguments found with any of the C<find_*> or C<try_find_*> functions will be automatically added to the build when calling C<add_xs>.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
