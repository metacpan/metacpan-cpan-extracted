#line 1
package Module::Install::TrustMetaYml;

use 5.008;
use constant { FALSE => 0, TRUE => 1 };
use strict;
use utf8;

BEGIN {
	$Module::Install::TrustMetaYml::AUTHORITY = 'cpan:TOBYINK';
}
BEGIN {
	$Module::Install::TrustMetaYml::VERSION   = '0.001';
}

use base qw(Module::Install::Base);

sub trust_meta_yml
{
	my ($self, $where) = @_;
	$where ||= 'META.yml';

	$self->perl_version('5.006') unless defined $self->perl_version;
	
	$self->include_deps('YAML::Tiny', 0);
	return $self if $self->is_admin;

	require YAML::Tiny;
	my $data = YAML::Tiny::LoadFile($where);

	$self->perl_version($data->{requires}{perl} || '5.006');
	
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

TRUE;

__END__

