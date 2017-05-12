#line 1
package Module::Install::TrustMetaYml;

use 5.005;
use strict;

BEGIN {
	$Module::Install::TrustMetaYml::AUTHORITY = 'cpan:TOBYINK';
	$Module::Install::TrustMetaYml::VERSION   = '0.002';
}

use base qw(Module::Install::Base);

sub trust_meta_yml
{
	my ($self, $where) = @_;
	$where ||= 'META.yml';

	$self->perl_version('5.005') unless defined $self->perl_version;
	
	$self->include_deps('YAML::Tiny', 0);
	return $self if $self->is_admin;

	require YAML::Tiny;
	my $data = YAML::Tiny::LoadFile($where);

	$self->perl_version($data->{requires}{perl} || '5.005');
	
	KEY: foreach my $key (qw(requires recommends build_requires))
	{
		next KEY unless ref $data->{$key} eq 'HASH';
		my %deps = %{$data->{$key}};
		DEP: while (my ($pkg, $ver) = each %deps)
		{
			next if $pkg eq 'perl';
			$self->$key($pkg, $ver);
		}
	}
	
	return $self;
}

*trust_meta_yaml = \&trust_meta_yml;

1;

__END__

=encoding utf8

