package Dist::Build::XS::WriteConstants;
$Dist::Build::XS::WriteConstants::VERSION = '0.023';
use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec::Functions 'catfile';

use parent 'ExtUtils::Builder::Planner::Extension';

sub add_methods {
	my ($self, $planner, %args) = @_;

	my $parse_xs = $planner->can('parse_xs') // do {
		$planner->load_extension('ExtUtils::Builder::ParseXS', 0.016, config => $args{config});
		$planner->can('parse_xs');
	};

	$planner->add_delegate('parse_xs', sub {
		my ($planner, $xs_file, $c_file, %args) = @_;

		my @xs_dependencies = @{ $args{dependencies} // [] };
		if (my $write_constants = delete $args{write_constants}) {
			my $xs_dir = dirname($xs_file);
			my $basename = delete $write_constants->{CONST_BASENAME} // 'const';
			$write_constants->{NAME}    //= $args{module_name} // $planner->main_module;
			$write_constants->{C_FILE}  //= catfile($xs_dir, "$basename-c.inc");
			$write_constants->{XS_FILE} //= catfile($xs_dir, "$basename-xs.inc");

			$planner->create_node(
				target => $_,
				actions => [
					ExtUtils::Builder::Action::Function->new(
						module    => 'ExtUtils::Constant',
						function  => 'WriteConstants',
						export    => 1,
						arguments => [ %{$write_constants} ],
						message   => "write_constants $write_constants->{NAME}",
					)
				]
			) for @{$write_constants}{qw/C_FILE XS_FILE/};

			push @xs_dependencies, $write_constants->{C_FILE};
		}

		$planner->$parse_xs($xs_file, $c_file, %args, dependencies => \@xs_dependencies);
	});
}

1;

# ABSTRACT: Dist::Build extension integrating ExtUtils::Constant

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Build::XS::WriteConstants - Dist::Build extension integrating ExtUtils::Constant

=head1 VERSION

version 0.023

=head1 SYNOPSIS

 load_extension('Dist::Build::XS');
 load_extension('Dist::Build::XS::WriteConstants');

 add_xs(
     module          => 'Foo::Bar',
     write_constants => {
         NAMES => [ qw/FOO BAR BAZ/ ],
     },
 );

=head1 DESCRIPTION

This module is an extension of L<Dist::Build::XS|Dist::Build::XS>, adding an additional argument to the C<add_xs> function: C<write_constants>. This hash will take the same members as the C<WriteConstants> function of L<ExtUtils::Constant|ExtUtils::Constant>, except that it will set sensible default values for the C<NAME> (based on the module's name), C<C_FILE> and C<XS_FILE> (based on the XS file's directory and C<CONST_BASENAME> defaulting to C<'const'>) members so usually those will not need to be passed. So the above example is equivalent to

  {
    NAME    => 'Foo::Bar',
    NAMES   => [ qw/FOO BAR BAZ/ ],
    C_FILE  => 'lib/Foo/const-c.inc',
    XS_FILE => 'lib/Foo/const-xs.inc',
  }

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
