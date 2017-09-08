package Devel::IPerl::Plugin::ChartClicker;
# ABSTRACT: IPerl plugin to make Chart::Clicker charts displayable
$Devel::IPerl::Plugin::ChartClicker::VERSION = '0.008';
use strict;
use warnings;

use Chart::Clicker;
use Role::Tiny;
use Devel::IPerl::Display::SVG;
use Devel::IPerl::Display::PNG;

our $IPerl_compat = 1;

our $IPerl_format_info = {
	'SVG' => { suffix => '.svg', displayable => 'Devel::IPerl::Display::SVG' },
	'PNG' => { suffix => '.png', displayable => 'Devel::IPerl::Display::PNG' },
};

sub register {
	Role::Tiny->apply_roles_to_package( 'Chart::Clicker', q(Devel::IPerl::Plugin::ChartClicker::IPerlRole) );
}

{
package
	Devel::IPerl::Plugin::ChartClicker::IPerlRole;

use Moo::Role;
use Capture::Tiny qw(capture_stderr capture_stdout);
use File::Temp;


sub iperl_data_representations {
	my ($cc) = @_;
	return unless $Devel::IPerl::Plugin::ChartClicker::IPerl_compat;

	my $format = uc($cc->format);
	my $format_info = $Devel::IPerl::Plugin::ChartClicker::IPerl_format_info;

	return unless exists($format_info->{$format});

	my $suffix = $format_info->{$format}{suffix};
	my $displayable = $format_info->{$format}{displayable};

	my $tmp = File::Temp->new( SUFFIX => $suffix );
	my $tmp_filename = $tmp->filename;
	capture_stderr( sub {
		$cc->write_output( $tmp_filename );
	});

	return $displayable->new( filename => $tmp_filename )->iperl_data_representations;
}

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::IPerl::Plugin::ChartClicker - IPerl plugin to make Chart::Clicker charts displayable

=head1 VERSION

version 0.008

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Zhenyi Zhou <zhouzhen1@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
